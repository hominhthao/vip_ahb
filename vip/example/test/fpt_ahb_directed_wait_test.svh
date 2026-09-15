`ifndef FPT_AHB_DIRECTED_WAIT_TEST_SVH
`define FPT_AHB_DIRECTED_WAIT_TEST_SVH

class fpt_ahb_directed_wait_test extends fpt_ahb_base_test;
    `uvm_component_utils(fpt_ahb_directed_wait_test)

    int unsigned wait_cycles;
    int unsigned write_transfer;

    extern function new(string name = "fpt_ahb_directed_wait_test",
                        uvm_component parent = null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
endclass

function fpt_ahb_directed_wait_test::new(string name = "fpt_ahb_directed_wait_test",
                                         uvm_component parent = null);
    super.new(name, parent);
endfunction

function void fpt_ahb_directed_wait_test::build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!$value$plusargs("FPT_AHB_WAIT_CYCLES=%d", wait_cycles)) begin
        `uvm_fatal("NO_WAIT_CYCLES", "Use +FPT_AHB_WAIT_CYCLES=<0|1|2>")
        return;
    end
    if (wait_cycles > 2) begin
        `uvm_fatal("BAD_WAIT_CYCLES", "Directed WAIT test supports only 0, 1, or 2")
        return;
    end
    if (!$value$plusargs("FPT_AHB_WRITE=%d", write_transfer)) begin
        `uvm_fatal("NO_DIRECTION", "Use +FPT_AHB_WRITE=<0|1>")
        return;
    end
    if (write_transfer > 1) begin
        `uvm_fatal("BAD_DIRECTION", "FPT_AHB_WRITE must be 0 or 1")
        return;
    end

    uvm_config_db#(int unsigned)::set(this,
                                       "env.slave_agent.sequencer",
                                       "directed_wait_cycles",
                                       wait_cycles);
    uvm_config_db#(uvm_object_wrapper)::set(this,
                                            "env.slave_agent.sequencer.run_phase",
                                            "default_sequence",
                                            fpt_ahb_directed_wait_slave_seq::type_id::get());
endfunction

task fpt_ahb_directed_wait_test::run_phase(uvm_phase phase);
    fpt_ahb_directed_wait_master_seq seq;

    seq = fpt_ahb_directed_wait_master_seq::type_id::create("seq");
    seq.direction = write_transfer ? FPT_AHB_WRITE : FPT_AHB_READ;

    phase.raise_objection(this);
    `uvm_info("DIRECTED_WAIT",
              $sformatf("Starting %s with wait_cycles=%0d",
                        seq.direction.name(), wait_cycles),
              UVM_NONE)
    run_sequence_and_wait(seq, 1);
    phase.drop_objection(this);
endtask

`endif // FPT_AHB_DIRECTED_WAIT_TEST_SVH
