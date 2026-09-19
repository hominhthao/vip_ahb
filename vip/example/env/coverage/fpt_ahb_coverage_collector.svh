`ifndef FPT_AHB_COVERAGE_COLLECTOR_SVH
`define FPT_AHB_COVERAGE_COLLECTOR_SVH

class fpt_ahb_coverage_collector extends uvm_subscriber #(fpt_ahb_system_transaction);
    `uvm_component_utils(fpt_ahb_coverage_collector)

    fpt_ahb_beat_transaction tx;

    covergroup ahb_cg;
        option.per_instance = 1;
        option.name = "ahb_cg";

        cp_direction: coverpoint tx.direction {
            bins write = {FPT_AHB_WRITE};
            bins read  = {FPT_AHB_READ};
        }

        cp_burst: coverpoint tx.burst {
            bins single = {FPT_AHB_SINGLE};
            bins incr   = {FPT_AHB_INCR};
            bins wrap4  = {FPT_AHB_WRAP4};
            bins incr4  = {FPT_AHB_INCR4};
            bins wrap8  = {FPT_AHB_WRAP8};
            bins incr8  = {FPT_AHB_INCR8};
            bins wrap16 = {FPT_AHB_WRAP16};
            bins incr16 = {FPT_AHB_INCR16};
        }

        cp_trans: coverpoint tx.trans {
            bins idle   = {FPT_AHB_IDLE};
            bins busy   = {FPT_AHB_BUSY};
            bins nonseq = {FPT_AHB_NONSEQ};
            bins seq    = {FPT_AHB_SEQ};
        }

        cp_wait_cycles: coverpoint tx.wait_cycles {
            bins zero_wait  = {0};
            bins one_wait   = {1};
            bins multi_wait = {[2:15]};
            bins long_wait  = {[16:$]};
        }

        // Cross Coverages
        cross_burst_dir: cross cp_burst, cp_direction;
        cross_burst_wait: cross cp_burst, cp_wait_cycles;
        cross_trans_wait: cross cp_trans, cp_wait_cycles;

    endgroup

    extern function new(string name = "fpt_ahb_coverage_collector", uvm_component parent = null);
    extern virtual function void write(fpt_ahb_system_transaction t);
endclass : fpt_ahb_coverage_collector

function fpt_ahb_coverage_collector::new(string name = "fpt_ahb_coverage_collector", uvm_component parent = null);
    super.new(name, parent);
    ahb_cg = new();
endfunction : new

function void fpt_ahb_coverage_collector::write(fpt_ahb_system_transaction t);
    if (t != null && t.beat_tx != null) begin
        tx = t.beat_tx;
        ahb_cg.sample();
    end
endfunction : write

`endif // FPT_AHB_COVERAGE_COLLECTOR_SVH
