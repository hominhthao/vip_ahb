`ifndef FPT_AHB_RANDOM_RW_TEST_SVH
`define FPT_AHB_RANDOM_RW_TEST_SVH

class fpt_ahb_random_rw_test extends fpt_ahb_base_test;
    `uvm_component_utils(fpt_ahb_random_rw_test)

    extern function new(string name = "fpt_ahb_random_rw_test", uvm_component parent = null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
endclass

function fpt_ahb_random_rw_test::new(string name = "fpt_ahb_random_rw_test", uvm_component parent = null);
    super.new(name, parent);
endfunction

function void fpt_ahb_random_rw_test::build_phase(uvm_phase phase);
    super.build_phase(phase);
    uvm_config_db#(uvm_object_wrapper)::set(this,
                                            "env.slave_agent.sequencer.run_phase",
                                            "default_sequence",
                                            fpt_ahb_slave_wait_mem_seq::type_id::get());
endfunction

task fpt_ahb_random_rw_test::run_phase(uvm_phase phase);
    fpt_ahb_random_rw_seq seq;
    seq = fpt_ahb_random_rw_seq::type_id::create("seq");

    // Randomize the sequence itself to get a random num_trans
    if (!seq.randomize()) begin
        `uvm_error("TEST", "Failed to randomize sequence")
    end

    phase.raise_objection(this);
    `uvm_info("TEST", "Starting Random R/W Sequence...", UVM_NONE)

    run_sequence_and_wait(seq, seq.num_trans);
    `uvm_info("TEST", "Random R/W Sequence Completed.", UVM_NONE)
    phase.drop_objection(this);
endtask

`endif // FPT_AHB_RANDOM_RW_TEST_SVH
