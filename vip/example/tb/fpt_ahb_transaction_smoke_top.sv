module fpt_ahb_transaction_smoke_top;
    import uvm_pkg::*;
    import fpt_ahb_package::*;

    function automatic void log_transaction(string label, fpt_ahb_transaction tr);
        $display("%s direction=%s addr=0x%h write_data=0x%h size=%s burst=%s read_data=0x%h response=%s",
                 label, tr.direction.name(), tr.addr, tr.write_data,
                 tr.size.name(), tr.burst.name(), tr.read_data, tr.response.name());
    endfunction : log_transaction

    function automatic void expect_text(string text, string expected);
        for (int i = 0; i + expected.len() <= text.len(); i++) begin
            if (text.substr(i, i + expected.len() - 1) == expected)
                return;
        end
        $fatal(1, "Print output missing '%s': %s", expected, text);
    endfunction : expect_text

    function automatic void check_compare(string label, fpt_ahb_transaction lhs,
                                          fpt_ahb_transaction rhs, bit expected);
        string lhs_before;
        string rhs_before;
        lhs_before = lhs.sprint();
        rhs_before = rhs.sprint();
        $display("COMPARE: %s (expected equal=%0b)", label, expected);
        if (lhs.compare(rhs) != expected || rhs.compare(lhs) != expected)
            $fatal(1, "Compare result mismatch: %s", label);
        if (lhs.sprint() != lhs_before || rhs.sprint() != rhs_before)
            $fatal(1, "Compare changed object fields: %s", label);
    endfunction : check_compare

    task automatic check_utilities();
        fpt_ahb_transaction lhs;
        fpt_ahb_transaction rhs;
        uvm_sequence_item unrelated;
        string printed;
        lhs = fpt_ahb_transaction::type_id::create("lhs");
        rhs = fpt_ahb_transaction::type_id::create("rhs");
        unrelated = new("unrelated");

        lhs.addr = 'h100;
        rhs.addr = 'h100;
        lhs.direction = FPT_AHB_WRITE;
        rhs.direction = FPT_AHB_WRITE;
        lhs.write_data = 'h12345678;
        rhs.write_data = 'h12345678;
        lhs.read_data = 'hA5A55A5A;
        rhs.read_data = 'hA5A55A5A;
        lhs.response = FPT_AHB_OKAY;
        rhs.response = FPT_AHB_OKAY;
        check_compare("equal WRITE requests", lhs, rhs, 1);
        rhs.addr = 'h104;
        check_compare("different address", lhs, rhs, 0);
        rhs.addr = lhs.addr;
        rhs.direction = FPT_AHB_READ;
        check_compare("different direction", lhs, rhs, 0);
        rhs.direction = lhs.direction;
        rhs.size = fpt_ahb_size_e'(3'b000);
        check_compare("different size", lhs, rhs, 0);
        rhs.size = lhs.size;
        rhs.burst = fpt_ahb_burst_e'(3'b001);
        check_compare("different burst", lhs, rhs, 0);
        rhs.burst = lhs.burst;
        rhs.write_data = 'h87654321;
        check_compare("different WRITE payload", lhs, rhs, 0);
        rhs.write_data = lhs.write_data;
        rhs.read_data = 'x;
        check_compare("WRITE ignores read_data", lhs, rhs, 1);
        rhs.response = FPT_AHB_ERROR;
        check_compare("WRITE ignores response", lhs, rhs, 1);
        lhs.direction = FPT_AHB_READ;
        rhs.direction = FPT_AHB_READ;
        rhs.read_data = lhs.read_data;
        rhs.response = lhs.response;
        check_compare("equal READ requests", lhs, rhs, 1);
        rhs.write_data = '1;
        check_compare("READ ignores write_data", lhs, rhs, 1);
        rhs.read_data = 'z;
        check_compare("READ ignores read_data", lhs, rhs, 1);
        rhs.response = FPT_AHB_ERROR;
        check_compare("READ ignores response", lhs, rhs, 1);
        if (lhs.compare(null) || lhs.compare(unrelated))
            $fatal(1, "Compare accepted null or unrelated object");

        // All fields must be visible through the public UVM print APIs.
        printed = lhs.sprint();
        expect_text(printed, "addr");
        expect_text(printed, "100");
        expect_text(printed, "write_data");
        expect_text(printed, "12345678");
        expect_text(printed, "direction");
        expect_text(printed, "FPT_AHB_READ");
        expect_text(printed, "size");
        expect_text(printed, "FPT_AHB_WORD");
        expect_text(printed, "burst");
        expect_text(printed, "FPT_AHB_SINGLE");
        expect_text(printed, "read_data");
        expect_text(printed, "a5a55a5a");
        expect_text(printed, "response");
        expect_text(printed, "FPT_AHB_OKAY");
        $display("PRINT: request with manually assigned result fields");
        lhs.print();
        lhs.direction = FPT_AHB_WRITE;
        lhs.response = FPT_AHB_ERROR;
        printed = lhs.sprint();
        expect_text(printed, "FPT_AHB_WRITE");
        expect_text(printed, "FPT_AHB_ERROR");
        lhs.read_data = 'x;
        lhs.response = fpt_ahb_response_e'(1'bx);
        printed = lhs.sprint();
        expect_text(printed, "'hx");
        expect_text(printed, "'bx");
        $display("PRINT: unknown result fields\n%s", printed);
        if (lhs.read_data !== 'x || lhs.response !== 1'bx)
            $fatal(1, "Print changed unknown result fields");
        lhs.read_data = 'z;
        lhs.response = fpt_ahb_response_e'(1'bz);
        printed = lhs.sprint();
        expect_text(printed, "'hz");
        expect_text(printed, "'bz");
        $display("PRINT: high-impedance result fields\n%s", printed);
        if (lhs.read_data !== 'z || lhs.response !== 1'bz)
            $fatal(1, "Print changed high-impedance result fields");
        $display("PASS: request compare and full-field print checks");
    endtask : check_utilities

    initial begin
        fpt_ahb_transaction tr;
        int read_count = 0;
        int write_count = 0;

        tr = fpt_ahb_transaction::type_id::create("tr");
        if (tr == null)
            $fatal(1, "Factory returned null");
        if (tr.size !== FPT_AHB_WORD || tr.burst !== FPT_AHB_SINGLE)
            $fatal(1, "Incorrect constructor defaults");

        // Sentinels detect unintended changes to non-random result fields.
        tr.read_data = 'hA5A55A5A;
        tr.response = FPT_AHB_ERROR;
        $display("NOTE: read_data/response are test sentinels, not DUT results.");
        for (int i = 0; i < 100; i++) begin
            if (!tr.randomize())
                $fatal(1, "Legal transaction randomization failed");
            log_transaction($sformatf("RANDOM[%0d]", i), tr);
            if (tr.addr[1:0] !== 2'b00)
                $fatal(1, "Random address is not word-aligned");
            if (tr.size !== FPT_AHB_WORD || tr.burst !== FPT_AHB_SINGLE)
                $fatal(1, "Unsupported transfer generated");
            if (tr.read_data !== 'hA5A55A5A || tr.response !== FPT_AHB_ERROR)
                $fatal(1, "Randomization changed result fields");
            case (tr.direction)
                FPT_AHB_READ: read_count++;
                FPT_AHB_WRITE: write_count++;
                default: $fatal(1, "Invalid direction generated");
            endcase
        end

        // Force each direction so both are tested independently of the seed.
        // A READ may retain a nonzero write payload.
        tr.read_data = 'x;
        tr.response = FPT_AHB_OKAY;
        if (!tr.randomize() with {
            direction == FPT_AHB_READ;
            write_data == '1;
        })
            $fatal(1, "READ with nonzero write_data was rejected");
        log_transaction("FORCED_READ", tr);
        if (tr.direction !== FPT_AHB_READ || tr.write_data !== '1)
            $fatal(1, "READ request mismatch");
        if (tr.read_data !== 'x || tr.response !== FPT_AHB_OKAY)
            $fatal(1, "READ randomization changed result fields");
        if (!tr.randomize() with { direction == FPT_AHB_WRITE; })
            $fatal(1, "WRITE was rejected");
        log_transaction("FORCED_WRITE", tr);
        if (tr.direction !== FPT_AHB_WRITE)
            $fatal(1, "WRITE request mismatch");
        if (tr.read_data !== 'x || tr.response !== FPT_AHB_OKAY)
            $fatal(1, "WRITE randomization changed result fields");

        // VCS CNST-CIF diagnostics are expected for these deliberate conflicts.
        $display("EXPECT REJECTION: misaligned address");
        if (tr.randomize() with { addr[1:0] == 2'b01; })
            $fatal(1, "Misaligned address was accepted");

        $display("EXPECT REJECTION: unsupported size");
        tr.size = fpt_ahb_size_e'(3'b000);
        if (tr.randomize())
            $fatal(1, "Unsupported size was accepted");
        if (tr.size !== fpt_ahb_size_e'(3'b000))
            $fatal(1, "Randomization repaired non-random size");
        tr.size = FPT_AHB_WORD;

        $display("EXPECT REJECTION: unsupported burst");
        tr.burst = fpt_ahb_burst_e'(3'b001);
        if (tr.randomize())
            $fatal(1, "Unsupported burst was accepted");
        if (tr.burst !== fpt_ahb_burst_e'(3'b001))
            $fatal(1, "Randomization repaired non-random burst");
        tr.burst = FPT_AHB_SINGLE;

        if (!tr.randomize())
            $fatal(1, "Randomization failed after restoring legal state");
        log_transaction("RESTORED", tr);

        check_utilities();
        $display("PASS: transaction smoke test (100 random items: READ=%0d WRITE=%0d; forced READ/WRITE; 3 expected rejections)",
                 read_count, write_count);
        $finish;
    end
endmodule : fpt_ahb_transaction_smoke_top
