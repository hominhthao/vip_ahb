`ifndef FPT_AHB_MASTER_TRANSACTION_SVH
`define FPT_AHB_MASTER_TRANSACTION_SVH

// One item represents one complete Master burst request. The currently
// verified contract remains a one-beat, WORD-sized SINGLE request.
class fpt_ahb_master_transaction extends uvm_sequence_item;

    `uvm_object_utils(fpt_ahb_master_transaction)

    // Burst start address. Per-beat address generation is owned elsewhere.
    rand bit [`FPT_AHB_VIP_ADDR_WIDTH-1:0] addr;

    // One payload element per requested WRITE beat.
    rand bit [`FPT_AHB_VIP_DATA_WIDTH-1:0] write_data[];
    rand fpt_ahb_direction_e direction;

    rand fpt_ahb_size_e size = FPT_AHB_WORD;
    rand fpt_ahb_burst_e burst = FPT_AHB_SINGLE;

    // One runtime-derived result per completed READ beat; never randomized.
    logic [`FPT_AHB_VIP_DATA_WIDTH-1:0] read_data[];
    fpt_ahb_response_e response;

    constraint c_word_alignment {
        addr[1:0] == 2'b00;
    }

    // Declarative constraints preserve the currently verified WORD/SINGLE scope.
    constraint c_v0_0_transfer {
        write_data.size() == 1;
        size == FPT_AHB_WORD;
        burst == FPT_AHB_SINGLE;
    }

    extern function new(string name = "fpt_ahb_master_transaction");
    extern virtual function void do_copy(uvm_object rhs);
    extern virtual function void do_print(uvm_printer printer);
    extern virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);

endclass : fpt_ahb_master_transaction

function fpt_ahb_master_transaction::new(string name = "fpt_ahb_master_transaction");
    super.new(name);
endfunction : new

function void fpt_ahb_master_transaction::do_copy(uvm_object rhs);
    fpt_ahb_master_transaction rhs_tr;

    if (!$cast(rhs_tr, rhs) || rhs_tr == null) begin
        `uvm_fatal("FPT_AHB_COPY", "Expected a non-null fpt_ahb_master_transaction")
        return;
    end
    super.do_copy(rhs);
    // Copy all stored fields, including data ignored by compare().
    addr = rhs_tr.addr;
    direction = rhs_tr.direction;
    write_data = rhs_tr.write_data;
    size = rhs_tr.size;
    burst = rhs_tr.burst;
    read_data = rhs_tr.read_data;
    response = rhs_tr.response;
endfunction : do_copy

function void fpt_ahb_master_transaction::do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field("addr", addr, $bits(addr), UVM_HEX);
    printer.print_field("write_data_count", write_data.size(), 32, UVM_DEC);
    foreach (write_data[i])
        printer.print_field($sformatf("write_data[%0d]", i), write_data[i],
                            $bits(write_data[i]), UVM_HEX);
    printer.print_string("direction", direction.name());
    printer.print_string("size", size.name());
    printer.print_string("burst", burst.name());
    printer.print_field("read_data_count", read_data.size(), 32, UVM_DEC);
    foreach (read_data[i])
        printer.print_field($sformatf("read_data[%0d]", i), read_data[i],
                            $bits(read_data[i]), UVM_HEX);
    if ($isunknown(response))
        printer.print_field("response", response, $bits(response), UVM_BIN);
    else
        printer.print_string("response", response.name());
endfunction : do_print

function bit fpt_ahb_master_transaction::do_compare(uvm_object rhs, uvm_comparer comparer);
    fpt_ahb_master_transaction rhs_tr;
    bit same;

    if (!$cast(rhs_tr, rhs) || rhs_tr == null) begin
        comparer.print_msg("rhs is not a non-null fpt_ahb_master_transaction");
        return 0;
    end

    // Request equality only: results and unused READ payloads are ignored.
    same = super.do_compare(rhs, comparer);
    same &= comparer.compare_field("direction", direction, rhs_tr.direction, $bits(direction));
    same &= comparer.compare_field("addr", addr, rhs_tr.addr, $bits(addr), UVM_HEX);
    same &= comparer.compare_field("size", size, rhs_tr.size, $bits(size));
    same &= comparer.compare_field("burst", burst, rhs_tr.burst, $bits(burst));
    if (direction == FPT_AHB_WRITE && rhs_tr.direction == FPT_AHB_WRITE) begin
        same &= comparer.compare_field("write_data.size", write_data.size(),
                                       rhs_tr.write_data.size(), 32, UVM_DEC);
        for (int unsigned i = 0;
             i < write_data.size() && i < rhs_tr.write_data.size(); i++) begin
            same &= comparer.compare_field($sformatf("write_data[%0d]", i),
                                           write_data[i], rhs_tr.write_data[i],
                                           $bits(write_data[i]), UVM_HEX);
        end
    end
    return same;
endfunction : do_compare

`endif
