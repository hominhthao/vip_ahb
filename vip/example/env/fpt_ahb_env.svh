`ifndef FPT_AHB_ENV_SVH
`define FPT_AHB_ENV_SVH

class fpt_ahb_env extends uvm_env;
    `uvm_component_utils(fpt_ahb_env)

    fpt_ahb_env_cfg cfg;
    fpt_ahb_master_agent master_agents[];
    fpt_ahb_slave_agent  slave_agents[];
    fpt_ahb_system_monitor system_monitor;
    fpt_ahb_system_checker system_checker;
    fpt_ahb_coverage_collector coverage_collector;
    fpt_ahb_predictor    predictor;
    fpt_ahb_common_memory mem;

    extern function new(string name = "fpt_ahb_env", uvm_component parent = null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);
endclass

//------------------------------------------------------------------------------
// Constructor: Initializes the UVM environment
//------------------------------------------------------------------------------
function fpt_ahb_env::new(string name = "fpt_ahb_env", uvm_component parent = null);
    super.new(name, parent);
endfunction

//------------------------------------------------------------------------------
// Build Phase: Instantiates master and slave agents
//------------------------------------------------------------------------------
function void fpt_ahb_env::build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(fpt_ahb_env_cfg)::get(this, "", "cfg", cfg)) begin
        `uvm_fatal("NO_ENV_CFG", {"Environment configuration must be set for: ",
                                   get_full_name(), ".cfg"})
        return;
    end
    if (!cfg.validate()) begin
        return;
    end

    master_agents = new[cfg.num_masters];
    slave_agents  = new[cfg.num_slaves];

    // One runtime memory; Slave consumers receive this same handle.
    mem = fpt_ahb_common_memory::type_id::create("mem");

    foreach (cfg.master_cfgs[i]) begin
        uvm_config_db#(fpt_ahb_master_agent_cfg)::set(
            this, $sformatf("master_agents[%0d]*", i), "cfg", cfg.master_cfgs[i]);
        master_agents[i] = fpt_ahb_master_agent::type_id::create($sformatf("master_agents[%0d]", i), this);
    end

    foreach (cfg.slave_cfgs[i]) begin
        uvm_config_db#(fpt_ahb_slave_agent_cfg)::set(
            this, $sformatf("slave_agents[%0d]*", i), "cfg", cfg.slave_cfgs[i]);
        uvm_config_db#(fpt_ahb_common_memory)::set(
            this, $sformatf("slave_agents[%0d]*", i), "mem", mem);
        slave_agents[i] = fpt_ahb_slave_agent::type_id::create($sformatf("slave_agents[%0d]", i), this);
    end
    
    system_monitor = fpt_ahb_system_monitor::type_id::create("system_monitor", this);
    uvm_config_db#(fpt_ahb_env_cfg)::set(this, "system_monitor", "cfg", cfg);

    // v0.1 System Checker and optional Predictor
    system_checker = fpt_ahb_system_checker::type_id::create("system_checker", this);
    coverage_collector = fpt_ahb_coverage_collector::type_id::create("coverage_collector", this);
    system_checker.has_predictor = cfg.has_predictor;
    
    if (cfg.has_predictor) begin
        predictor = fpt_ahb_predictor::type_id::create("predictor", this);
    end
endfunction

//------------------------------------------------------------------------------
// Connect Phase: Routes completed Master and Slave observations to the System Checker
//------------------------------------------------------------------------------
function void fpt_ahb_env::connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // 1. All Local Agents connect ONLY to System Monitor
    foreach (master_agents[i]) begin
        master_agents[i].ap.connect(system_monitor.master_fifos[i].analysis_export);
        if (cfg.has_predictor) begin
            master_agents[i].ap.connect(predictor.analysis_export);
        end
    end

    foreach (slave_agents[i]) begin
        slave_agents[i].ap.connect(system_monitor.slave_fifos[i].analysis_export);
    end

    // 2. System Monitor broadcasts fully routed sys_tr to System Checker
    if (cfg.has_system_checker) begin
        system_monitor.sys_ap.connect(system_checker.sys_master_fifo.analysis_export);
        system_monitor.sys_ap.connect(coverage_collector.analysis_export);
        system_monitor.sys_slave_ap.connect(system_checker.sys_slave_fifo.analysis_export);
        
        if (cfg.has_predictor) begin
            predictor.expected_ap.connect(system_checker.expected_fifo.analysis_export);
        end
    end
endfunction

`endif // FPT_AHB_ENV_SVH
