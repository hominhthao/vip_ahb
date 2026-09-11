module fpt_ahb_slave_transaction_smoke_top;
    import uvm_pkg::*;
    import fpt_ahb_package::*;

    function automatic void check_context(fpt_ahb_master_transaction request,
                                          fpt_ahb_slave_transaction reply);
        if (reply.addr !== request.addr || reply.direction !== request.direction ||
            reply.write_data !== request.write_data || reply.size !== request.size ||
            reply.burst !== request.burst)
            $fatal(1, "Slave randomization changed captured request context");
    endfunction : check_context

    function automatic string snapshot(fpt_ahb_slave_transaction tr);
        return $sformatf("%h %b %h %b %b %h %b %h", tr.addr, tr.direction,
                         tr.write_data, tr.size, tr.burst, tr.read_data,
                         tr.response, tr.wait_cycles);
    endfunction : snapshot

    function automatic void expect_print_field(string printed, string field_name,
                                               string expected_value);
        string row_name;
        string row_type;
        string row_size;
        string row_value;
        int    start = 0;
        for (int i = 0; i < printed.len(); i++) begin
            if (printed.getc(i) == 10 || i == printed.len() - 1) begin
                if ($sscanf(printed.substr(start, i), "%s %s %s %s",
                            row_name, row_type, row_size, row_value) == 4 &&
                    row_name == field_name) begin
                    if (row_value != expected_value)
                        $fatal(1, "Print %s: expected %s, got %s",
                               field_name, expected_value, row_value);
                    return;
                end
                start = i + 1;
            end
        end
        $fatal(1, "Print field missing: %s", field_name);
    endfunction : expect_print_field

    task automatic check_print();
        fpt_ahb_slave_transaction tr;
        uvm_table_printer printer;
        string before_print;
        string printed;
        tr = fpt_ahb_slave_transaction::type_id::create("print_slave");
        printer = new();
        // Remove radix prefixes only in this test's printer for exact row checks.
        printer.knobs.show_radix = 0;
        tr.addr = 'h1abc;
        tr.direction = FPT_AHB_READ;
        tr.write_data = 'h1234abcd;
        tr.size = FPT_AHB_WORD;
        tr.burst = FPT_AHB_SINGLE;
        tr.read_data = 'hdeadbeef;
        tr.response = FPT_AHB_OKAY;
        // A small value whose decimal and hex representations differ.
        tr.wait_cycles = 12;
        before_print = snapshot(tr);
        printed = tr.sprint(printer);
        expect_print_field(printed, "addr", "1abc");
        expect_print_field(printed, "direction", "FPT_AHB_READ");
        expect_print_field(printed, "write_data", "1234abcd");
        expect_print_field(printed, "size", "FPT_AHB_WORD");
        expect_print_field(printed, "burst", "FPT_AHB_SINGLE");
        expect_print_field(printed, "read_data", "deadbeef");
        expect_print_field(printed, "response", "FPT_AHB_OKAY");
        expect_print_field(printed, "wait_cycles", "12");
        if (snapshot(tr) != before_print)
            $fatal(1, "Slave sprint changed a stored field");
        $display("SLAVE PRINT: stored request and response plan");
        tr.print(printer);
        if (snapshot(tr) != before_print)
            $fatal(1, "Slave print changed a stored field");

        tr.direction = FPT_AHB_WRITE;
        tr.response = FPT_AHB_ERROR;
        before_print = snapshot(tr);
        printed = tr.sprint(printer);
        expect_print_field(printed, "direction", "FPT_AHB_WRITE");
        expect_print_field(printed, "response", "FPT_AHB_ERROR");
        expect_print_field(printed, "read_data", "deadbeef");
        if (snapshot(tr) != before_print)
            $fatal(1, "Slave WRITE sprint changed a stored field");

        // Unnamed enum state must remain visible without being repaired.
        tr.direction = fpt_ahb_direction_e'(1'bx);
        tr.size = fpt_ahb_size_e'(3'b111);
        tr.burst = fpt_ahb_burst_e'(3'b111);
        tr.response = fpt_ahb_response_e'(1'bz);
        before_print = snapshot(tr);
        printed = tr.sprint(printer);
        expect_print_field(printed, "direction", "x");
        expect_print_field(printed, "size", "111");
        expect_print_field(printed, "burst", "111");
        expect_print_field(printed, "response", "z");
        tr.print(printer);
        if (snapshot(tr) != before_print)
            $fatal(1, "Slave print/sprint changed unnamed enum state");
        $display("PASS: slave print/sprint all 8 fields and state preservation");
    endtask : check_print

    function automatic void check_compare(string label, fpt_ahb_slave_transaction lhs,
                                          fpt_ahb_slave_transaction rhs, bit expected);
        string lhs_before;
        string rhs_before;
        lhs_before = snapshot(lhs);
        rhs_before = snapshot(rhs);
        $display("SLAVE COMPARE: %s (expected equal=%0b)", label, expected);
        if (lhs.compare(rhs) != expected || rhs.compare(lhs) != expected)
            $fatal(1, "Slave compare mismatch: %s", label);
        if (snapshot(lhs) != lhs_before || snapshot(rhs) != rhs_before)
            $fatal(1, "Slave compare modified a field: %s", label);
    endfunction : check_compare

    task automatic check_compare_cases();
        fpt_ahb_slave_transaction lhs;
        fpt_ahb_slave_transaction rhs;
        uvm_sequence_item unrelated;
        lhs = fpt_ahb_slave_transaction::type_id::create("lhs");
        rhs = fpt_ahb_slave_transaction::type_id::create("rhs");
        unrelated = new("unrelated");
        lhs.addr = 'h100;
        rhs.addr = 'h100;
        lhs.direction = FPT_AHB_WRITE;
        rhs.direction = FPT_AHB_WRITE;
        lhs.write_data = 'h12345678;
        rhs.write_data = 'h12345678;
        lhs.read_data = 'h87654321;
        rhs.read_data = 'h87654321;
        lhs.response = FPT_AHB_OKAY;
        rhs.response = FPT_AHB_OKAY;
        lhs.wait_cycles = 0;
        rhs.wait_cycles = 0;
        check_compare("equal WRITE", lhs, rhs, 1);
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
        rhs.response = FPT_AHB_ERROR;
        check_compare("different response", lhs, rhs, 0);
        rhs.response = lhs.response;
        rhs.wait_cycles = 3;
        check_compare("different wait count", lhs, rhs, 0);
        rhs.wait_cycles = lhs.wait_cycles;
        rhs.write_data = '0;
        check_compare("WRITE payload mismatch", lhs, rhs, 0);
        lhs.response = FPT_AHB_ERROR;
        rhs.response = FPT_AHB_ERROR;
        check_compare("ERROR WRITE still checks write_data", lhs, rhs, 0);
        rhs.write_data = lhs.write_data;
        rhs.read_data = '0;
        check_compare("WRITE ignores read_data", lhs, rhs, 1);

        lhs.direction = FPT_AHB_READ;
        rhs.direction = FPT_AHB_READ;
        check_compare("ERROR READ ignores read_data", lhs, rhs, 1);
        rhs.write_data = '0;
        check_compare("READ ignores write_data", lhs, rhs, 1);
        lhs.response = FPT_AHB_OKAY;
        check_compare("READ response mismatch", lhs, rhs, 0);
        rhs.response = FPT_AHB_OKAY;
        check_compare("OKAY READ checks read_data", lhs, rhs, 0);
        rhs.read_data = lhs.read_data;
        check_compare("equal OKAY READ despite different write_data", lhs, rhs, 1);
        rhs.wait_cycles = 8;
        check_compare("READ wait mismatch", lhs, rhs, 0);
        $display("SLAVE COMPARE: null and unrelated type (expected unequal)");
        if (lhs.compare(null) || lhs.compare(unrelated))
            $fatal(1, "Slave compare accepted null or unrelated type");
        $display("PASS: slave response-plan compare checks");
    endtask : check_compare_cases

    function automatic void check_all_fields(string label, fpt_ahb_slave_transaction actual,
                                             fpt_ahb_slave_transaction expected);
        if (actual.addr !== expected.addr)
            $fatal(1, "%s: addr was not preserved", label);
        if (actual.direction !== expected.direction)
            $fatal(1, "%s: direction was not preserved", label);
        if (actual.write_data !== expected.write_data)
            $fatal(1, "%s: write_data was not preserved", label);
        if (actual.size !== expected.size)
            $fatal(1, "%s: size was not preserved", label);
        if (actual.burst !== expected.burst)
            $fatal(1, "%s: burst was not preserved", label);
        if (actual.read_data !== expected.read_data)
            $fatal(1, "%s: read_data was not preserved", label);
        if (actual.response !== expected.response)
            $fatal(1, "%s: response was not preserved", label);
        if (actual.wait_cycles !== expected.wait_cycles)
            $fatal(1, "%s: wait_cycles was not preserved", label);
    endfunction : check_all_fields

    task automatic check_copy_clone();
        fpt_ahb_slave_transaction src;
        fpt_ahb_slave_transaction dst;
        fpt_ahb_slave_transaction cloned;
        uvm_object clone_object;
        src = fpt_ahb_slave_transaction::type_id::create("copy_src");
        dst = fpt_ahb_slave_transaction::type_id::create("copy_dst");
        if (src == null || dst == null || src == dst)
            $fatal(1, "Copy requires distinct non-null objects");

        for (int i = 0; i < 2; i++) begin
            src.addr = (i == 0) ? 'h100 : 'h204;
            src.direction = (i == 0) ? FPT_AHB_READ : FPT_AHB_WRITE;
            src.write_data = (i == 0) ? 'h12345678 : 'h87654321;
            // Invalid enum state is deliberate: copying is not randomization
            // and must preserve stored values, not repair them to defaults.
            src.size = (i == 0) ? FPT_AHB_WORD : fpt_ahb_size_e'(3'b000);
            src.burst = (i == 0) ? FPT_AHB_SINGLE : fpt_ahb_burst_e'(3'b001);
            src.read_data = (i == 0) ? 'hA5A55A5A : 'h5A5AA5A5;
            src.response = (i == 0) ? FPT_AHB_ERROR : FPT_AHB_OKAY;
            src.wait_cycles = (i == 0) ? 3 : 8;
            dst.addr = 'h300;
            dst.direction = (i == 0) ? FPT_AHB_WRITE : FPT_AHB_READ;
            dst.write_data = '0;
            dst.size = (i == 0) ? fpt_ahb_size_e'(3'b000) : FPT_AHB_WORD;
            dst.burst = (i == 0) ? fpt_ahb_burst_e'(3'b001) : FPT_AHB_SINGLE;
            dst.read_data = '0;
            dst.response = (i == 0) ? FPT_AHB_OKAY : FPT_AHB_ERROR;
            dst.wait_cycles = 0;

            dst.copy(src);
            check_all_fields("copy", dst, src);
            $display("PASS: slave copy all fields case %0d", i);

            clone_object = src.clone();
            if (!$cast(cloned, clone_object) || cloned == null)
                $fatal(1, "Clone returned null or incorrect type");
            if (cloned == src || cloned == dst)
                $fatal(1, "Clone did not create a distinct object");
            check_all_fields("clone", cloned, src);
            cloned.addr = 'h400;
            cloned.direction = dst.direction == FPT_AHB_READ ? FPT_AHB_WRITE : FPT_AHB_READ;
            cloned.write_data = '1;
            cloned.size = fpt_ahb_size_e'(3'b111);
            cloned.burst = fpt_ahb_burst_e'(3'b111);
            cloned.read_data = '0;
            cloned.response = dst.response == FPT_AHB_OKAY ? FPT_AHB_ERROR : FPT_AHB_OKAY;
            cloned.wait_cycles = 1;
            check_all_fields("original after clone mutation", src, dst);
            $display("PASS: slave clone all fields and independence case %0d", i);
        end
    endtask : check_copy_clone

    initial begin
        fpt_ahb_master_transaction request;
        fpt_ahb_slave_transaction reply;
        int okay_count = 0;
        int error_count = 0;

        request = fpt_ahb_master_transaction::type_id::create("request");
        reply = fpt_ahb_slave_transaction::type_id::create("reply");
        if (request == null || reply == null)
            $fatal(1, "Factory returned null");
        if (reply.size !== FPT_AHB_WORD || reply.burst !== FPT_AHB_SINGLE)
            $fatal(1, "Incorrect slave WORD/SINGLE defaults");

        // This copies fields for an object-level test, not a bus or Driver flow.
        // Alternate request directions to exercise response generation for both.
        for (int i = 0; i < 100; i++) begin
            if (!request.randomize())
                $fatal(1, "Master context generation failed");
            request.direction = (i % 2 == 0) ? FPT_AHB_READ : FPT_AHB_WRITE;
            reply.addr = request.addr;
            reply.direction = request.direction;
            reply.write_data = request.write_data;
            reply.size = request.size;
            reply.burst = request.burst;
            if (!reply.randomize())
                $fatal(1, "Slave response randomization failed");
            check_context(request, reply);
            if (reply.wait_cycles != 0 || reply.response !== FPT_AHB_OKAY)
                $fatal(1, "Slave soft defaults were not applied");
            case (reply.response)
                FPT_AHB_OKAY: okay_count++;
                FPT_AHB_ERROR: error_count++;
                default: $fatal(1, "Invalid slave response");
            endcase
            $display("SLAVE[%0d] context: direction=%s addr=0x%h write_data=0x%h; generated: read_data=0x%h response=%s wait_cycles=%0d",
                     i, reply.direction.name(), reply.addr, reply.write_data,
                     reply.read_data, reply.response.name(), reply.wait_cycles);

            // Directed controls prove each rand field can be requested explicitly.
            // 8 is a test value, not a transaction-level maximum. No cycles elapse.
            if (!reply.randomize() with {
                read_data == '0; response == FPT_AHB_OKAY; wait_cycles == 0;
            })
                $fatal(1, "Zero-wait OKAY response rejected");
            check_context(request, reply);
            if (reply.read_data !== '0 || reply.response !== FPT_AHB_OKAY ||
                reply.wait_cycles != 0)
                $fatal(1, "Zero-wait response mismatch");
            if (!reply.randomize() with {
                read_data == '1; response == FPT_AHB_ERROR; wait_cycles == 8;
            })
                $fatal(1, "Nonzero-wait ERROR response rejected");
            check_context(request, reply);
            if (reply.read_data !== '1 || reply.response !== FPT_AHB_ERROR ||
                reply.wait_cycles != 8)
                $fatal(1, "Nonzero-wait response mismatch");
        end

        $display("EXPECT REJECTION: slave context cannot be randomized to another address");
        if (reply.randomize() with { addr != local::request.addr; })
            $fatal(1, "Slave accepted an address change during randomization");
        check_context(request, reply);

        $display("EXPECT REJECTION: slave misaligned context");
        reply.addr[1:0] = 2'b01;
        if (reply.randomize())
            $fatal(1, "Slave accepted misaligned context");
        if (reply.addr[1:0] !== 2'b01)
            $fatal(1, "Slave repaired captured address");
        reply.addr = request.addr;

        $display("EXPECT REJECTION: slave unsupported size");
        reply.size = fpt_ahb_size_e'(3'b000);
        if (reply.randomize())
            $fatal(1, "Slave accepted unsupported size");
        if (reply.size !== fpt_ahb_size_e'(3'b000))
            $fatal(1, "Slave repaired captured size");
        reply.size = request.size;

        $display("EXPECT REJECTION: slave unsupported burst");
        reply.burst = fpt_ahb_burst_e'(3'b001);
        if (reply.randomize())
            $fatal(1, "Slave accepted unsupported burst");
        if (reply.burst !== fpt_ahb_burst_e'(3'b001))
            $fatal(1, "Slave repaired captured burst");
        reply.burst = request.burst;

        if (!reply.randomize())
            $fatal(1, "Slave randomization failed after context restore");
        check_context(request, reply);
        if (reply.wait_cycles != 0 || reply.response !== FPT_AHB_OKAY)
            $fatal(1, "Slave defaults were not restored after overrides");
        check_compare_cases();
        check_copy_clone();
        check_print();
        $display("PASS: slave transaction smoke test (100 default responses: OKAY=%0d ERROR=%0d; READ/WRITE context preserved; soft overrides; compare; 4 expected rejections)",
                 okay_count, error_count);
        $finish;
    end
endmodule : fpt_ahb_slave_transaction_smoke_top
