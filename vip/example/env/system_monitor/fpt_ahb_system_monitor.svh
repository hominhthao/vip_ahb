`ifndef FPT_AHB_SYSTEM_MONITOR_SVH
`define FPT_AHB_SYSTEM_MONITOR_SVH

class fpt_ahb_system_monitor extends uvm_monitor;
    `uvm_component_utils(fpt_ahb_system_monitor)

    extern function new(string name = "fpt_ahb_system_monitor", uvm_component parent = null);
    extern virtual function void build_phase(uvm_phase phase);
endclass : fpt_ahb_system_monitor

function fpt_ahb_system_monitor::new(string name = "fpt_ahb_system_monitor", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

function void fpt_ahb_system_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);
    // V0.1: Foundation for future source, destination, and system-level context.
endfunction : build_phase

`endif
