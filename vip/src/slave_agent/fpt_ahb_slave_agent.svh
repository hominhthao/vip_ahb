`ifndef FPT_AHB_SLAVE_AGENT_SVH
`define FPT_AHB_SLAVE_AGENT_SVH

class fpt_ahb_slave_agent extends uvm_agent;
    `uvm_component_utils(fpt_ahb_slave_agent)

    fpt_ahb_slave_driver    driver;
    uvm_sequencer #(fpt_ahb_slave_transaction) sequencer;
    fpt_ahb_slave_monitor   monitor;

    fpt_ahb_slave_agent_cfg cfg;
    fpt_ahb_common_memory mem;
    uvm_analysis_port #(fpt_ahb_slave_transaction) ap;

    extern function new(string name = "fpt_ahb_slave_agent", uvm_component parent = null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);
endclass

//------------------------------------------------------------------------------
// Constructor: Initializes the slave agent component
//------------------------------------------------------------------------------
function fpt_ahb_slave_agent::new(string name = "fpt_ahb_slave_agent", uvm_component parent = null);
    super.new(name, parent);
endfunction

//------------------------------------------------------------------------------
// Build Phase: Retrieves config and instantiates sub-components based on is_active
//------------------------------------------------------------------------------
function void fpt_ahb_slave_agent::build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(fpt_ahb_slave_agent_cfg)::get(this, "", "cfg", cfg)) begin
        `uvm_fatal("NO_CFG", {"Configuration must be set for: ", get_full_name(), ".cfg"})
    end

    ap = new("ap", this);
    monitor = fpt_ahb_slave_monitor::type_id::create("monitor", this);

    if (cfg.is_active == UVM_ACTIVE) begin
        if (!uvm_config_db#(fpt_ahb_common_memory)::get(this, "", "mem", mem) || mem == null) begin
            `uvm_fatal("NO_MEM", "Slave Agent requires the Environment common-memory handle")
        end
        uvm_config_db#(fpt_ahb_common_memory)::set(this, "driver", "mem", mem);
        sequencer = uvm_sequencer#(fpt_ahb_slave_transaction)::type_id::create("sequencer", this);
        driver    = fpt_ahb_slave_driver::type_id::create("driver", this);
    end
endfunction

//------------------------------------------------------------------------------
// Connect Phase: Connects the monitor AP and driver to sequencer
//------------------------------------------------------------------------------
function void fpt_ahb_slave_agent::connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    monitor.ap.connect(this.ap);
    if (cfg.is_active == UVM_ACTIVE) begin
        driver.seq_item_port.connect(sequencer.seq_item_export);
    end
endfunction

`endif // FPT_AHB_SLAVE_AGENT_SVH
