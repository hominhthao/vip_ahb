`ifndef FPT_AHB_SLAVE_BASE_SEQ_SVH
`define FPT_AHB_SLAVE_BASE_SEQ_SVH

class fpt_ahb_slave_base_seq extends uvm_sequence #(fpt_ahb_slave_transaction);
  `uvm_object_utils(fpt_ahb_slave_base_seq)

  fpt_ahb_common_memory mem;

  extern function new(string name = "fpt_ahb_slave_base_seq");
  extern virtual task pre_body();
endclass

//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
function fpt_ahb_slave_base_seq::new(string name = "fpt_ahb_slave_base_seq");
  super.new(name);
endfunction

//------------------------------------------------------------------------------
// Pre-Body: Retrieves the common memory handle from the config DB
//------------------------------------------------------------------------------
task fpt_ahb_slave_base_seq::pre_body();
  super.pre_body();
  if (!uvm_config_db#(fpt_ahb_common_memory)::get(m_sequencer, "", "mem", mem)) begin
    `uvm_fatal("NO_MEM", "Could not find fpt_ahb_common_memory in config_db")
  end
endtask

`endif // FPT_AHB_SLAVE_BASE_SEQ_SVH
