`ifndef FPT_AHB_READ_AFTER_WRITE_TEST_SVH
`define FPT_AHB_READ_AFTER_WRITE_TEST_SVH

class fpt_ahb_read_after_write_test extends fpt_ahb_base_test;
    `uvm_component_utils(fpt_ahb_read_after_write_test)

    extern function new(string name = "fpt_ahb_read_after_write_test", uvm_component parent = null);
    extern virtual task run_phase(uvm_phase phase);
endclass

//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
function fpt_ahb_read_after_write_test::new(string name = "fpt_ahb_read_after_write_test", uvm_component parent = null);
    super.new(name, parent);
endfunction

//------------------------------------------------------------------------------
// Run Phase: Executes the sequence and controls simulation time
//------------------------------------------------------------------------------
task fpt_ahb_read_after_write_test::run_phase(uvm_phase phase);
    fpt_ahb_read_after_write_seq seq;

    phase.raise_objection(this);

    seq = fpt_ahb_read_after_write_seq::type_id::create("seq");

    `uvm_info("TEST", "Starting Read After Write Sequence...", UVM_LOW)

    run_sequence_and_wait(seq, 2);

    `uvm_info("TEST", "Read After Write Sequence Completed.", UVM_LOW)

    phase.drop_objection(this);
endtask

`endif // FPT_AHB_READ_AFTER_WRITE_TEST_SVH
