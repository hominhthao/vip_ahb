module fpt_ahb_common_memory_smoke_top;
    import uvm_pkg::*;
    import fpt_ahb_package::*;

    typedef fpt_ahb_common_memory::addr_t addr_t;
    typedef fpt_ahb_common_memory::data_t data_t;

    initial begin
        fpt_ahb_common_memory handle_a;
        fpt_ahb_common_memory handle_b;
        addr_t addr_a;
        addr_t addr_b;
        data_t value_a;
        data_t value_b;
        int entries;

        // One allocation only; both variables must refer to this same object.
        handle_a = fpt_ahb_common_memory::type_id::create("common_memory");
        handle_b = handle_a;
        if (handle_a == null || handle_b != handle_a)
            $fatal(1, "Shared handle setup failed");

        addr_a = addr_t'('h100);
        addr_b = ($bits(addr_t) >= 32) ? addr_t'(32'hFFFF_FFFC) : addr_t'('h200);
        value_a = data_t'('hA5A55A5A);
        value_b = data_t'('h12345678);
        entries = handle_a.storage.num();
        if (handle_b.read(addr_a) !== '0 || handle_a.storage.num() != entries)
            $fatal(1, "Unwritten read must return zero without allocating");
        $display("PASS: unwritten read returns zero without allocation");

        handle_a.write(addr_a, value_a);
        if (handle_b.read(addr_a) !== value_a)
            $fatal(1, "Same-address/shared-handle read failed");
        handle_a.write(addr_b, value_b);
        entries = handle_a.storage.num();
        // Reverse read order proves address-keyed rather than FIFO storage.
        if (handle_b.read(addr_b) !== value_b || handle_b.read(addr_a) !== value_a ||
            handle_a.storage.num() != entries || entries != 2)
            $fatal(1, "Independent/reverse-order reads failed");
        $display("PASS: shared handles, independent addresses, reverse order; A=%h B=%h",
                 addr_a, addr_b);

        handle_b.write(addr_a, '1);
        if (handle_a.read(addr_a) !== data_t'('1) ||
            handle_a.read(addr_b) !== value_b || handle_a.storage.num() != 2)
            $fatal(1, "Overwrite failed");
        $display("PASS: overwrite preserves other address");

        // Adjacent byte keys must remain distinct: no alignment/word conversion.
        handle_a.write(addr_a + addr_t'(1), '0);
        if (handle_b.read(addr_a) !== data_t'('1) ||
            handle_b.read(addr_a + addr_t'(1)) !== '0 || handle_a.storage.num() != 3)
            $fatal(1, "Full byte address keys were not preserved");
        $display("PASS: exact byte address keys");

        handle_b.clear();
        if (handle_a.storage.num() != 0 || handle_a.read(addr_a) !== '0 ||
            handle_a.read(addr_b) !== '0 || handle_a.storage.num() != 0)
            $fatal(1, "Shared clear failed");
        handle_a.clear();
        if (handle_a != handle_b || handle_a.storage.num() != 0)
            $fatal(1, "Repeated clear changed object/state");
        handle_b.write(addr_b, value_a);
        if (handle_a.read(addr_b) !== value_a)
            $fatal(1, "Write/read after clear failed");
        $display("PASS: shared clear, repeated clear, reuse after clear");
        $display("PASS: common memory smoke test");
        $finish;
    end
endmodule : fpt_ahb_common_memory_smoke_top
