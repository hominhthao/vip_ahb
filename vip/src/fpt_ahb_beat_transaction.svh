`ifndef FPT_AHB_BEAT_TRANSACTION_SVH
`define FPT_AHB_BEAT_TRANSACTION_SVH

// One accepted NONSEQ/SEQ transfer after its data phase completes on HREADY.
// This is an observed bus event, not a Master request or Slave response plan.
class fpt_ahb_beat_transaction extends uvm_sequence_item;
    `uvm_object_utils(fpt_ahb_beat_transaction)

    logic [`FPT_AHB_VIP_ADDR_WIDTH-1:0] addr;
    fpt_ahb_direction_e direction;
    fpt_ahb_size_e size;
    fpt_ahb_burst_e burst;
    // Actual address-phase HTRANS captured by a Monitor, never stimulus intent.
    fpt_ahb_trans_e trans;
    logic [`FPT_AHB_VIP_DATA_WIDTH-1:0] write_data;
    logic [`FPT_AHB_VIP_DATA_WIDTH-1:0] read_data;
    fpt_ahb_response_e response;
    int unsigned wait_cycles;

    extern function new(string name = "fpt_ahb_beat_transaction");
    extern virtual function void do_copy(uvm_object rhs);
    extern virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    extern virtual function void do_print(uvm_printer printer);
endclass : fpt_ahb_beat_transaction

function fpt_ahb_beat_transaction::new(string name = "fpt_ahb_beat_transaction");
    super.new(name);
    write_data = 'x;
    read_data = 'x;
endfunction : new

function void fpt_ahb_beat_transaction::do_copy(uvm_object rhs);
    fpt_ahb_beat_transaction rhs_tr;

    if (!$cast(rhs_tr, rhs) || rhs_tr == null) begin
        `uvm_fatal("FPT_AHB_COPY", "Expected a non-null fpt_ahb_beat_transaction")
        return;
    end
    super.do_copy(rhs);
    addr = rhs_tr.addr;
    direction = rhs_tr.direction;
    size = rhs_tr.size;
    burst = rhs_tr.burst;
    trans = rhs_tr.trans;
    write_data = rhs_tr.write_data;
    read_data = rhs_tr.read_data;
    response = rhs_tr.response;
    wait_cycles = rhs_tr.wait_cycles;
endfunction : do_copy

function bit fpt_ahb_beat_transaction::do_compare(uvm_object rhs,
                                                   uvm_comparer comparer);
    fpt_ahb_beat_transaction rhs_tr;
    bit same;

    if (!$cast(rhs_tr, rhs) || rhs_tr == null) begin
        comparer.print_msg("rhs is not a non-null fpt_ahb_beat_transaction");
        return 0;
    end
    same = super.do_compare(rhs, comparer);
    same &= comparer.compare_field("addr", addr, rhs_tr.addr, $bits(addr), UVM_HEX);
    same &= comparer.compare_field("direction", direction, rhs_tr.direction, $bits(direction));
    same &= comparer.compare_field("size", size, rhs_tr.size, $bits(size));
    same &= comparer.compare_field("burst", burst, rhs_tr.burst, $bits(burst));
    same &= comparer.compare_field("trans", trans, rhs_tr.trans, $bits(trans));
    same &= comparer.compare_field("response", response, rhs_tr.response, $bits(response));
    same &= comparer.compare_field("wait_cycles", wait_cycles, rhs_tr.wait_cycles,
                                   $bits(wait_cycles), UVM_DEC);
    if (direction == FPT_AHB_WRITE && rhs_tr.direction == FPT_AHB_WRITE)
        same &= comparer.compare_field("write_data", write_data, rhs_tr.write_data,
                                       $bits(write_data), UVM_HEX);
    if (direction == FPT_AHB_READ && rhs_tr.direction == FPT_AHB_READ &&
        response == FPT_AHB_OKAY && rhs_tr.response == FPT_AHB_OKAY)
        same &= comparer.compare_field("read_data", read_data, rhs_tr.read_data,
                                       $bits(read_data), UVM_HEX);
    return same;
endfunction : do_compare

function void fpt_ahb_beat_transaction::do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field("addr", addr, $bits(addr), UVM_HEX);
    printer.print_string("direction", direction.name());
    printer.print_string("size", size.name());
    printer.print_string("burst", burst.name());
    if (trans.name() != "")
        printer.print_string("trans", trans.name());
    else
        printer.print_field("trans", trans, $bits(trans), UVM_BIN);
    printer.print_field("write_data", write_data, $bits(write_data), UVM_HEX);
    printer.print_field("read_data", read_data, $bits(read_data), UVM_HEX);
    printer.print_string("response", response.name());
    printer.print_field("wait_cycles", wait_cycles, $bits(wait_cycles), UVM_DEC);
endfunction : do_print

`endif // FPT_AHB_BEAT_TRANSACTION_SVH
