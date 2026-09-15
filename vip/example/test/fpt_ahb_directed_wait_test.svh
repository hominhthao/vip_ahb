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
        `uvm_fatal("NO_WAIT_CYCLES", "Use +FPT_AHB_WAIT_CYCLES=<count>")
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

    if (wait_cycles == 0) begin
        env_cfg.slave_cfgs[0].wait_mode = FPT_AHB_ZERO_WAIT;
    end else begin
        env_cfg.slave_cfgs[0].wait_mode = FPT_AHB_FIXED_WAIT;
        env_cfg.slave_cfgs[0].fixed_wait_cycles = wait_cycles;
    end
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

class fpt_ahb_invalid_random_wait_cfg_test extends fpt_ahb_base_test;
    `uvm_component_utils(fpt_ahb_invalid_random_wait_cfg_test)

    extern function new(string name = "fpt_ahb_invalid_random_wait_cfg_test",
                        uvm_component parent = null);
    extern virtual function void build_phase(uvm_phase phase);
endclass

function fpt_ahb_invalid_random_wait_cfg_test::new(
                                                       string name = "fpt_ahb_invalid_random_wait_cfg_test",
                                                       uvm_component parent = null
                                                       );
    super.new(name, parent);
endfunction

function void fpt_ahb_invalid_random_wait_cfg_test::build_phase(uvm_phase phase);
    super.build_phase(phase);
    env_cfg.slave_cfgs[0].wait_mode = FPT_AHB_RANDOM_WAIT;
    env_cfg.slave_cfgs[0].min_wait_cycles = 4;
    env_cfg.slave_cfgs[0].max_wait_cycles = 3;
endfunction

`endif // FPT_AHB_DIRECTED_WAIT_TEST_SVH
