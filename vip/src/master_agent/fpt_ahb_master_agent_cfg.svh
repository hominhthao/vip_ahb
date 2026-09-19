`ifndef FPT_AHB_MASTER_AGENT_CFG_SVH
`define FPT_AHB_MASTER_AGENT_CFG_SVH

class fpt_ahb_master_agent_cfg extends uvm_object;
    `uvm_object_utils(fpt_ahb_master_agent_cfg)

    uvm_active_passive_enum is_active = UVM_ACTIVE;
    bit has_coverage = 1;
    bit has_checks   = 1;
    int wait_timeout_cycles = 1000;
    
    fpt_ahb_wait_mode_e wait_mode = FPT_AHB_ZERO_WAIT;
    int unsigned min_delay = 0;
    int unsigned max_delay = 0;

    virtual fpt_ahb_if vif;

    extern function new(string name = "fpt_ahb_master_agent_cfg");
    extern function bit validate();
endclass

//------------------------------------------------------------------------------
// Constructor: Initializes the agent configuration object
//------------------------------------------------------------------------------
function fpt_ahb_master_agent_cfg::new(string name = "fpt_ahb_master_agent_cfg");
    super.new(name);
endfunction

function bit fpt_ahb_master_agent_cfg::validate();
    if (wait_mode == FPT_AHB_RANDOM_WAIT && min_delay > max_delay) begin
        `uvm_fatal("FPT_AHB_MASTER_CFG_WAIT_RANGE",
                   $sformatf("RANDOM_WAIT requires min_delay <= max_delay; configured min=%0d max=%0d",
                             min_delay, max_delay))
        return 0;
    end
    return 1;
endfunction

`endif // FPT_AHB_MASTER_AGENT_CFG_SVH
