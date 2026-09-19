`ifndef FPT_AHB_SYSTEM_TRANSACTION_SVH
`define FPT_AHB_SYSTEM_TRANSACTION_SVH

class fpt_ahb_system_transaction extends uvm_object;
    `uvm_object_utils(fpt_ahb_system_transaction)

    int master_id = -1;
    int slave_id  = -1;
    fpt_ahb_beat_transaction beat_tx;

    extern function new(string name = "fpt_ahb_system_transaction");
    extern virtual function void do_print(uvm_printer printer);
endclass : fpt_ahb_system_transaction

function fpt_ahb_system_transaction::new(string name = "fpt_ahb_system_transaction");
    super.new(name);
endfunction : new

function void fpt_ahb_system_transaction::do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field("master_id", master_id, 32, UVM_DEC);
    printer.print_field("slave_id", slave_id, 32, UVM_DEC);
    if (beat_tx != null) begin
        printer.print_object("beat_tx", beat_tx);
    end
endfunction : do_print

`endif // FPT_AHB_SYSTEM_TRANSACTION_SVH
