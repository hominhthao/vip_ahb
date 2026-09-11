`ifndef FPT_AHB_ENV_SVH
`define FPT_AHB_ENV_SVH

class fpt_ahb_env extends uvm_env;
    `uvm_component_utils(fpt_ahb_env)

    fpt_ahb_master_agent master_agent;
    fpt_ahb_slave_agent  slave_agent;
    fpt_ahb_scoreboard   scoreboard;
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

    // One runtime memory; Slave consumers receive this same handle.
    mem = fpt_ahb_common_memory::type_id::create("mem");
    uvm_config_db#(fpt_ahb_common_memory)::set(this, "slave_agent", "mem", mem);

    master_agent = fpt_ahb_master_agent::type_id::create("master_agent", this);
    slave_agent = fpt_ahb_slave_agent::type_id::create("slave_agent", this);
    scoreboard = fpt_ahb_scoreboard::type_id::create("scoreboard", this);
endfunction

//------------------------------------------------------------------------------
// Connect Phase: Routes completed Master and Slave observations to the Scoreboard
//------------------------------------------------------------------------------
function void fpt_ahb_env::connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    master_agent.ap.connect(scoreboard.master_fifo.analysis_export);
    slave_agent.ap.connect(scoreboard.slave_fifo.analysis_export);
endfunction

`endif // FPT_AHB_ENV_SVH
