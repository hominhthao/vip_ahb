`ifndef FPT_AHB_SINGLE_WRITE_TEST_SVH
`define FPT_AHB_SINGLE_WRITE_TEST_SVH

class fpt_ahb_single_write_test extends fpt_ahb_base_test;
  `uvm_component_utils(fpt_ahb_single_write_test)

  extern function new(string name = "fpt_ahb_single_write_test", uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);
endclass

//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
function fpt_ahb_single_write_test::new(string name = "fpt_ahb_single_write_test", uvm_component parent = null);
  super.new(name, parent);
endfunction

//------------------------------------------------------------------------------
// Run Phase
//------------------------------------------------------------------------------
task fpt_ahb_single_write_test::run_phase(uvm_phase phase);
  fpt_ahb_single_write_seq seq;
  seq = fpt_ahb_single_write_seq::type_id::create("seq");
  
  phase.raise_objection(this);
  `uvm_info("TEST", "Starting Single Write Sequence...", UVM_NONE)
  
  seq.start(env.master_agent.sequencer);
  
  // Dư dả thời gian để xem sóng sau khi chạy xong
  #50ns;
  
  `uvm_info("TEST", "Single Write Sequence Completed.", UVM_NONE)
  phase.drop_objection(this);
endtask

`endif // FPT_AHB_SINGLE_WRITE_TEST_SVH
