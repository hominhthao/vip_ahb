`ifndef FPT_AHB_ENV_SVH
`define FPT_AHB_ENV_SVH

class fpt_ahb_env extends uvm_env;
  `uvm_component_utils(fpt_ahb_env)

  fpt_ahb_master_agent master_agent;
  fpt_ahb_slave_agent  slave_agent;

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
  
  // Khởi tạo cụm Master
  master_agent = fpt_ahb_master_agent::type_id::create("master_agent", this);
  
  // Khởi tạo cụm Slave
  slave_agent  = fpt_ahb_slave_agent::type_id::create("slave_agent", this);
endfunction

//------------------------------------------------------------------------------
// Connect Phase: Reserved for connecting scoreboards or coverage modules
//------------------------------------------------------------------------------
function void fpt_ahb_env::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  
  // (Dành cho tương lai)
  // Nếu có Scoreboard, bạn sẽ nối dây từ master_agent.ap và slave_agent.ap vào đây
endfunction

`endif // FPT_AHB_ENV_SVH
