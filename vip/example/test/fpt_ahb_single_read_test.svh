`ifndef FPT_AHB_SINGLE_READ_TEST_SVH
`define FPT_AHB_SINGLE_READ_TEST_SVH

class fpt_ahb_single_read_test extends fpt_ahb_base_test;
    `uvm_component_utils(fpt_ahb_single_read_test)

    extern function new(string name = "fpt_ahb_single_read_test", uvm_component parent = null);
    extern virtual task run_phase(uvm_phase phase);
endclass

//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
function fpt_ahb_single_read_test::new(string name = "fpt_ahb_single_read_test", uvm_component parent = null);
    super.new(name, parent);
endfunction

//------------------------------------------------------------------------------
// Run Phase
//------------------------------------------------------------------------------
task fpt_ahb_single_read_test::run_phase(uvm_phase phase);
    fpt_ahb_single_read_seq seq;
    seq = fpt_ahb_single_read_seq::type_id::create("seq");

    if (!seq.randomize()) begin
        `uvm_error("TEST", "Failed to randomize sequence")
    end

    phase.raise_objection(this);
    `uvm_info("TEST", "Starting Random Write Sequence...", UVM_NONE)

    run_sequence_and_wait(seq, seq.num_trans);

    `uvm_info("TEST", "Single Write Sequence Completed.", UVM_NONE)
    phase.drop_objection(this);
endtask

`endif // FPT_AHB_SINGLE_READ_TEST_SVH
