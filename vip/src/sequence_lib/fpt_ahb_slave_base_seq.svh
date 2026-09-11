`ifndef FPT_AHB_SLAVE_BASE_SEQ_SVH
`define FPT_AHB_SLAVE_BASE_SEQ_SVH

class fpt_ahb_slave_base_seq extends uvm_sequence #(fpt_ahb_slave_transaction);
    `uvm_object_utils(fpt_ahb_slave_base_seq)

    extern function new(string name = "fpt_ahb_slave_base_seq");
endclass

//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
function fpt_ahb_slave_base_seq::new(string name = "fpt_ahb_slave_base_seq");
    super.new(name);
endfunction

`endif // FPT_AHB_SLAVE_BASE_SEQ_SVH
