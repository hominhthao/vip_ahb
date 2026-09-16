`ifndef FPT_AHB_BASE_TEST_SVH
`define FPT_AHB_BASE_TEST_SVH

class fpt_ahb_base_test extends uvm_test;
    `uvm_component_utils(fpt_ahb_base_test)

    fpt_ahb_env env;
    fpt_ahb_env_cfg env_cfg;
    // Compatibility aliases; Env Config owns these Agent Config handles.
    fpt_ahb_master_agent_cfg master_cfg;
    fpt_ahb_slave_agent_cfg  slave_cfg;

    extern function new(string name = "fpt_ahb_base_test", uvm_component parent = null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void end_of_elaboration_phase(uvm_phase phase);
    // Test completion budget in clocks; not a Slave wait-state policy.
    int unsigned completion_timeout_cycles = 100;
    extern task run_sequence_and_wait(uvm_sequence_base seq, int expected_count);
endclass

//------------------------------------------------------------------------------
// Constructor: Initializes the base test component
//------------------------------------------------------------------------------
function fpt_ahb_base_test::new(string name = "fpt_ahb_base_test", uvm_component parent = null);
    super.new(name, parent);
endfunction

//------------------------------------------------------------------------------
// Build Phase: Creates environment, configs and sets up default sequences
//------------------------------------------------------------------------------
function void fpt_ahb_base_test::build_phase(uvm_phase phase);
    virtual fpt_ahb_if vif;

    super.build_phase(phase);

    if (!uvm_config_db#(virtual fpt_ahb_if)::get(this, "", "vif", vif)) begin
        `uvm_fatal("NO_VIF", "Virtual interface not found in config_db. Did you set it in Top?")
    end

    env_cfg = fpt_ahb_env_cfg::type_id::create("env_cfg");
    env_cfg.num_masters = 1;
    env_cfg.num_slaves = 1;
    env_cfg.create_agent_cfgs();

    master_cfg = env_cfg.master_cfgs[0];
    slave_cfg = env_cfg.slave_cfgs[0];
    master_cfg.vif = vif;
    slave_cfg.vif = vif;

    uvm_config_db#(fpt_ahb_env_cfg)::set(this, "env", "cfg", env_cfg);

    // Preserve the existing default Slave response sequence and component path.
    uvm_config_db#(uvm_object_wrapper)::set(this,
                                            "env.slave_agent.sequencer.run_phase",
                                            "default_sequence",
                                            fpt_ahb_slave_mem_seq::type_id::get());

    // Create the Environment only after its configuration is complete.
    env = fpt_ahb_env::type_id::create("env", this);
endfunction

//------------------------------------------------------------------------------
// End of Elaboration Phase: Prints the UVM topology tree
//------------------------------------------------------------------------------
function void fpt_ahb_base_test::end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    // In ra cây cấu trúc gia phả của toàn bộ hệ thống VIP để dễ Debug
    uvm_top.print_topology();
endfunction

// Bound both sequence execution and Monitor/Scoreboard completion.
task fpt_ahb_base_test::run_sequence_and_wait(uvm_sequence_base seq, int expected_count);
    bit completed;

    if (expected_count <= 0)
        `uvm_fatal("FPT_AHB_TEST_COUNT", "Integration tests require a positive expected count")
    env.scoreboard.expected_count = expected_count;
    fork
        begin
            seq.start(env.master_agent.sequencer);
            wait (env.scoreboard.checked_count >= expected_count);
            completed = 1'b1;
        end
        begin
            repeat (completion_timeout_cycles) @(master_cfg.vif.cb_monitor);
        end
    join_any
    disable fork;

    if (!completed)
        `uvm_error("FPT_AHB_TEST_TIMEOUT",
                   $sformatf("Completion timeout after %0d clocks: expected=%0d checked=%0d",
                             completion_timeout_cycles, expected_count,
                             env.scoreboard.checked_count))
endtask : run_sequence_and_wait

`endif // FPT_AHB_BASE_TEST_SVH
