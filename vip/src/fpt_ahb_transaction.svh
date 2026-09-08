`ifndef FPT_AHB_TRANSACTION_SVH
`define FPT_AHB_TRANSACTION_SVH

// One item requests one AHB-Lite SINGLE, WORD-sized transfer.
class fpt_ahb_transaction extends uvm_sequence_item;

    `uvm_object_utils(fpt_ahb_transaction)

    rand bit [`FPT_AHB_VIP_ADDR_WIDTH-1:0] addr;

    // Used only for WRITE; READ does not constrain this unused payload.
    rand bit [`FPT_AHB_VIP_DATA_WIDTH-1:0] write_data;
    rand fpt_ahb_direction_e direction;

    fpt_ahb_size_e size = FPT_AHB_WORD;
    fpt_ahb_burst_e burst = FPT_AHB_SINGLE;

    // Results are populated by the response/observation path, not randomization.
    // Interpret them only after transfer completion; read_data is for READ only.
    logic [`FPT_AHB_VIP_DATA_WIDTH-1:0] read_data;
    fpt_ahb_response_e response;

    constraint c_word_alignment {
        addr[1:0] == 2'b00;
    }

    // Non-random state is checked, not repaired, by randomize().
    constraint c_v0_0_transfer {
        size == FPT_AHB_WORD;
        burst == FPT_AHB_SINGLE;
    }

    extern function new(string name = "fpt_ahb_transaction");
    extern virtual function void do_print(uvm_printer printer);
    extern virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);

endclass : fpt_ahb_transaction

function fpt_ahb_transaction::new(string name = "fpt_ahb_transaction");
    super.new(name);
endfunction : new

function void fpt_ahb_transaction::do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field("addr", addr, $bits(addr), UVM_HEX);
    printer.print_field("write_data", write_data, $bits(write_data), UVM_HEX);
    printer.print_string("direction", direction.name());
    printer.print_string("size", size.name());
    printer.print_string("burst", burst.name());
    // These are stored values; printing does not imply transfer completion.
    printer.print_field("read_data", read_data, $bits(read_data), UVM_HEX);
    if ($isunknown(response))
        printer.print_field("response", response, $bits(response), UVM_BIN);
    else
        printer.print_string("response", response.name());
endfunction : do_print

function bit fpt_ahb_transaction::do_compare(uvm_object rhs, uvm_comparer comparer);
    fpt_ahb_transaction rhs_tr;
    bit same;

    if (!$cast(rhs_tr, rhs) || rhs_tr == null) begin
        comparer.print_msg("rhs is not a non-null fpt_ahb_transaction");
        return 0;
    end

    // Request equality only: results and unused READ payloads are ignored.
    same = super.do_compare(rhs, comparer);
    same &= comparer.compare_field("direction", direction, rhs_tr.direction, $bits(direction));
    same &= comparer.compare_field("addr", addr, rhs_tr.addr, $bits(addr), UVM_HEX);
    same &= comparer.compare_field("size", size, rhs_tr.size, $bits(size));
    same &= comparer.compare_field("burst", burst, rhs_tr.burst, $bits(burst));
    if (direction == FPT_AHB_WRITE && rhs_tr.direction == FPT_AHB_WRITE)
        same &= comparer.compare_field("write_data", write_data, rhs_tr.write_data,
                                       $bits(write_data), UVM_HEX);
    return same;
endfunction : do_compare

`endif
