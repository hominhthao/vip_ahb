`ifndef FPT_AHB_MASTER_MONITOR_SVH
`define FPT_AHB_MASTER_MONITOR_SVH

class fpt_ahb_master_monitor extends uvm_monitor;
    `uvm_component_utils(fpt_ahb_master_monitor)

    fpt_ahb_master_agent_cfg cfg;
    uvm_analysis_port #(fpt_ahb_master_transaction) ap;

    extern function new(string name = "fpt_ahb_master_monitor", uvm_component parent = null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
    extern virtual task collect_transactions();
endclass

//------------------------------------------------------------------------------
// Constructor: Initializes the monitor component
//------------------------------------------------------------------------------
function fpt_ahb_master_monitor::new(string name = "fpt_ahb_master_monitor", uvm_component parent = null);
    super.new(name, parent);
endfunction

//------------------------------------------------------------------------------
// Build Phase: Retrieves config and initializes the analysis port
//------------------------------------------------------------------------------
function void fpt_ahb_master_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (cfg == null) begin
        if (!uvm_config_db#(fpt_ahb_master_agent_cfg)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal("NO_CFG", {"Configuration must be set for: ", get_full_name(), ".cfg"})
        end
    end
    ap = new("ap", this);
endfunction

//------------------------------------------------------------------------------
// Run Phase: Waits for reset to complete then starts collecting transactions
//------------------------------------------------------------------------------
task fpt_ahb_master_monitor::run_phase(uvm_phase phase);
    wait (cfg.vif.hresetn === 1'b0);
    wait (cfg.vif.hresetn === 1'b1);
    collect_transactions();
endtask

//------------------------------------------------------------------------------
// Collect Transactions: Observes the AHB bus pipelined phases and builds transactions
//------------------------------------------------------------------------------
task fpt_ahb_master_monitor::collect_transactions();
    fpt_ahb_master_transaction data_phase_tx;
    fpt_ahb_master_transaction addr_phase_tx;

    forever begin
        @(cfg.vif.cb_monitor);

        if (cfg.vif.cb_monitor.hready === 1'b1 && data_phase_tx != null) begin
            if (data_phase_tx.direction == FPT_AHB_WRITE) begin
                data_phase_tx.write_data = cfg.vif.cb_monitor.hwdata;
            end else begin
                data_phase_tx.read_data = cfg.vif.cb_monitor.hrdata;
            end

            data_phase_tx.response = (cfg.vif.cb_monitor.hresp == 1'b1) ? FPT_AHB_ERROR : FPT_AHB_OKAY;

            ap.write(data_phase_tx);
            data_phase_tx = null;
        end

        if (cfg.vif.cb_monitor.hready === 1'b1 &&
            cfg.vif.cb_monitor.hselx === 1'b1 &&
            (cfg.vif.cb_monitor.htrans == 2'b10 || cfg.vif.cb_monitor.htrans == 2'b11)) begin

            addr_phase_tx = fpt_ahb_master_transaction::type_id::create("addr_phase_tx");

            addr_phase_tx.addr      = cfg.vif.cb_monitor.haddr;
            addr_phase_tx.direction = (cfg.vif.cb_monitor.hwrite == 1'b1) ? FPT_AHB_WRITE : FPT_AHB_READ;

            $cast(addr_phase_tx.size, cfg.vif.cb_monitor.hsize);
            $cast(addr_phase_tx.burst, cfg.vif.cb_monitor.hburst);

            data_phase_tx = addr_phase_tx;
        end
    end
endtask

`endif // FPT_AHB_MASTER_MONITOR_SVH
