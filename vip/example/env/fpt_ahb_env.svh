`ifndef FPT_AHB_ENV_SVH
`define FPT_AHB_ENV_SVH

class fpt_ahb_env extends uvm_env;
    `uvm_component_utils(fpt_ahb_env)

    fpt_ahb_env_cfg cfg;
    fpt_ahb_master_agent master_agents[];
    fpt_ahb_slave_agent  slave_agents[];
    fpt_ahb_system_monitor system_monitor;
    fpt_ahb_system_checker system_checker;
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

    // v0.1 System Checker and optional Predictor
    system_checker = fpt_ahb_system_checker::type_id::create("system_checker", this);
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

    // V0.1 architecture supports checking 1M/1S topology
    if (master_agents.size() > 0) begin
        master_agents[0].ap.connect(system_checker.master_fifo.analysis_export);
        if (cfg.has_predictor) begin
            master_agents[0].ap.connect(predictor.analysis_export);
        end
    end

    if (slave_agents.size() > 0) begin
        slave_agents[0].ap.connect(system_checker.slave_fifo.analysis_export);
    end
    
    if (cfg.has_predictor) begin
        predictor.expected_ap.connect(system_checker.expected_fifo.analysis_export);
    end
endfunction

`endif // FPT_AHB_ENV_SVH
