`ifndef FPT_AHB_DIRECTED_BURST_TEST_SVH
`define FPT_AHB_DIRECTED_BURST_TEST_SVH

class fpt_ahb_directed_burst_test extends fpt_ahb_base_test;
    `uvm_component_utils(fpt_ahb_directed_burst_test)

    extern function new(string name = "fpt_ahb_directed_burst_test", uvm_component parent = null);
    extern virtual task run_phase(uvm_phase phase);
endclass

function fpt_ahb_directed_burst_test::new(string name = "fpt_ahb_directed_burst_test", uvm_component parent = null);
    super.new(name, parent);
endfunction

task fpt_ahb_directed_burst_test::run_phase(uvm_phase phase);
    fpt_ahb_directed_burst_seq seq;
    seq = fpt_ahb_directed_burst_seq::type_id::create("seq");

    if (!seq.randomize()) begin
        `uvm_error("TEST", "Failed to randomize sequence")
    end

    phase.raise_objection(this);
    `uvm_info("TEST", "Starting Directed Burst Test...", UVM_NONE)

    run_sequence_and_wait(seq, seq.total_beats);

    `uvm_info("TEST", "Directed Burst Test Completed.", UVM_NONE)
    phase.drop_objection(this);
endtask

`endif // FPT_AHB_DIRECTED_BURST_TEST_SVH
