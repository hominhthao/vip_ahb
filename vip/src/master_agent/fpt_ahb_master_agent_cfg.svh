`ifndef FPT_AHB_MASTER_AGENT_CFG_SVH
`define FPT_AHB_MASTER_AGENT_CFG_SVH

class fpt_ahb_master_agent_cfg extends uvm_object;
  `uvm_object_utils(fpt_ahb_master_agent_cfg)

  uvm_active_passive_enum is_active = UVM_ACTIVE;
  bit has_coverage = 1;
  bit has_checks   = 1;
  int wait_timeout_cycles = 1000;
  virtual fpt_ahb_if vif;

  extern function new(string name = "fpt_ahb_master_agent_cfg");
endclass

//------------------------------------------------------------------------------
// Constructor: Initializes the agent configuration object
//------------------------------------------------------------------------------
function fpt_ahb_master_agent_cfg::new(string name = "fpt_ahb_master_agent_cfg");
  super.new(name);
endfunction

`endif // FPT_AHB_MASTER_AGENT_CFG_SVH
