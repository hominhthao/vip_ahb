`ifndef FPT_AHB_SYSTEM_MONITOR_SVH
`define FPT_AHB_SYSTEM_MONITOR_SVH

class fpt_ahb_system_monitor extends uvm_monitor;
    `uvm_component_utils(fpt_ahb_system_monitor)

    fpt_ahb_env_cfg cfg;

    // Dynamic arrays of FIFOs for incoming beat transactions
    uvm_tlm_analysis_fifo #(fpt_ahb_beat_transaction) master_fifos[];
    uvm_tlm_analysis_fifo #(fpt_ahb_beat_transaction) slave_fifos[];

    uvm_analysis_port #(fpt_ahb_system_transaction) sys_ap;
    uvm_analysis_port #(fpt_ahb_system_transaction) sys_slave_ap;

    extern function new(string name = "fpt_ahb_system_monitor", uvm_component parent = null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
    extern virtual function void process_master_tx(int port_idx, fpt_ahb_beat_transaction tr);
    extern virtual function void process_slave_tx(int port_idx, fpt_ahb_beat_transaction tr);
endclass : fpt_ahb_system_monitor

function fpt_ahb_system_monitor::new(string name = "fpt_ahb_system_monitor", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

function void fpt_ahb_system_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if (!uvm_config_db#(fpt_ahb_env_cfg)::get(this, "", "cfg", cfg)) begin
        `uvm_fatal("SYS_MON_CFG", "Missing fpt_ahb_env_cfg in System Monitor")
    end

    // Allocate FIFOs based on physical topology
    sys_ap = new("sys_ap", this);
    sys_slave_ap = new("sys_slave_ap", this);
    master_fifos = new[cfg.num_masters];
    slave_fifos  = new[cfg.num_slaves];

    foreach (master_fifos[i]) begin
        master_fifos[i] = new($sformatf("master_fifo_%0d", i), this);
    end
    foreach (slave_fifos[i]) begin
        slave_fifos[i] = new($sformatf("slave_fifo_%0d", i), this);
    end
endfunction : build_phase

task fpt_ahb_system_monitor::run_phase(uvm_phase phase);
    // Spawn threads to monitor all Master ports
    foreach (master_fifos[i]) begin
        automatic int port_idx = i;
        fork
            forever begin
                fpt_ahb_beat_transaction tr;
                master_fifos[port_idx].get(tr);
                process_master_tx(port_idx, tr);
            end
        join_none
    end

    // Spawn threads to monitor all Slave ports
    foreach (slave_fifos[i]) begin
        automatic int port_idx = i;
        fork
            forever begin
                fpt_ahb_beat_transaction tr;
                slave_fifos[port_idx].get(tr);
                process_slave_tx(port_idx, tr);
            end
        join_none
    end
endtask : run_phase

function void fpt_ahb_system_monitor::process_master_tx(int port_idx, fpt_ahb_beat_transaction tr);
    int target_slave = -1;
    fpt_ahb_system_transaction sys_tr;

    // Address Decoding Logic
    foreach (cfg.slave_cfgs[i]) begin
        if (tr.addr >= cfg.slave_cfgs[i].addr_start && tr.addr <= cfg.slave_cfgs[i].addr_end) begin
            target_slave = i;
            break;
        end
    end

    if (target_slave == -1) begin
        `uvm_warning("SYS_MON_DECODE", $sformatf("Address 0x%0h does not map to any configured slave!", tr.addr))
    end else begin
        `uvm_info("SYS_MON", $sformatf("[M_PORT_%0d] Decoded addr 0x%0h to Slave %0d", port_idx, tr.addr, target_slave), UVM_HIGH)
    end

    // Pack and broadcast
    sys_tr = fpt_ahb_system_transaction::type_id::create("sys_tr");
    sys_tr.master_id = port_idx;
    sys_tr.slave_id  = target_slave;
    sys_tr.beat_tx   = tr;
    sys_ap.write(sys_tr);
endfunction

function void fpt_ahb_system_monitor::process_slave_tx(int port_idx, fpt_ahb_beat_transaction tr);
    fpt_ahb_system_transaction sys_tr;
    `uvm_info("SYS_MON", $sformatf("[S_PORT_%0d] Captured response at addr 0x%0h", port_idx, tr.addr), UVM_HIGH)
    
    sys_tr = fpt_ahb_system_transaction::type_id::create("sys_tr");
    sys_tr.slave_id  = port_idx;
    sys_tr.beat_tx   = tr;
    sys_slave_ap.write(sys_tr);
endfunction

`endif // FPT_AHB_SYSTEM_MONITOR_SVH
