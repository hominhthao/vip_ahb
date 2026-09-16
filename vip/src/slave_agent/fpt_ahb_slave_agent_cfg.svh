`ifndef FPT_AHB_SLAVE_AGENT_CFG_SVH
`define FPT_AHB_SLAVE_AGENT_CFG_SVH

class fpt_ahb_slave_agent_cfg extends uvm_object;
    `uvm_object_utils(fpt_ahb_slave_agent_cfg)

    uvm_active_passive_enum is_active = UVM_ACTIVE;
    bit has_coverage = 1;
    bit has_checks   = 1;

    fpt_ahb_wait_mode_e wait_mode = FPT_AHB_ZERO_WAIT;
    int unsigned fixed_wait_cycles = 0;
    int unsigned min_wait_cycles   = 0;
    int unsigned max_wait_cycles   = 0;

    virtual fpt_ahb_if vif;

    extern function new(string name = "fpt_ahb_slave_agent_cfg");
    extern function bit validate();
endclass

//------------------------------------------------------------------------------
// Constructor: Initializes the slave agent configuration object
//------------------------------------------------------------------------------
function fpt_ahb_slave_agent_cfg::new(string name = "fpt_ahb_slave_agent_cfg");
    super.new(name);
endfunction

function bit fpt_ahb_slave_agent_cfg::validate();
    case (wait_mode)
        FPT_AHB_ZERO_WAIT,
        FPT_AHB_FIXED_WAIT: begin
        end
        FPT_AHB_RANDOM_WAIT: begin
            if (min_wait_cycles > max_wait_cycles) begin
                `uvm_fatal("FPT_AHB_SLAVE_CFG_WAIT_RANGE",
                           $sformatf({"RANDOM_WAIT requires min_wait_cycles <= max_wait_cycles; ",
                                      "configured min=%0d max=%0d"},
                                     min_wait_cycles, max_wait_cycles))
                return 0;
            end
        end
        default: begin
            `uvm_fatal("FPT_AHB_SLAVE_CFG_WAIT_MODE",
                       $sformatf("Unsupported Slave WAIT mode value: %0d", wait_mode))
            return 0;
        end
    endcase

    return 1;
endfunction : validate

`endif // FPT_AHB_SLAVE_AGENT_CFG_SVH
