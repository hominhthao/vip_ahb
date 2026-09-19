`ifndef FPT_AHB_EXAMPLE_PACKAGE_SV
`define FPT_AHB_EXAMPLE_PACKAGE_SV

`include "uvm_macros.svh"

package fpt_ahb_example_package;

    import uvm_pkg::*;
    import fpt_ahb_package::*;

    `include "env/system_monitor/fpt_ahb_system_transaction.svh"
    `include "env/system_checker/fpt_ahb_system_checker.svh"
    `include "env/coverage/fpt_ahb_coverage_collector.svh"
    `include "env/system_monitor/fpt_ahb_system_monitor.svh"
    `include "env/fpt_ahb_env.svh"

    `include "seq/fpt_ahb_read_after_write_seq.svh"
    `include "seq/fpt_ahb_single_write_seq.svh"
    `include "seq/fpt_ahb_single_read_seq.svh"
    `include "seq/fpt_ahb_random_rw_seq.svh"
    `include "seq/fpt_ahb_directed_wait_seq.svh"
    `include "seq/fpt_ahb_directed_burst_seq.svh"
    `include "seq/fpt_ahb_multi_collision_vseq.svh"

    `include "test/fpt_ahb_base_test.svh"
    `include "test/fpt_ahb_read_after_write_test.svh"
    `include "test/fpt_ahb_single_write_test.svh"
    `include "test/fpt_ahb_single_read_test.svh"
    `include "test/fpt_ahb_random_rw_test.svh"
    `include "test/fpt_ahb_directed_wait_test.svh"
    `include "test/fpt_ahb_directed_burst_test.svh"
    `include "test/fpt_ahb_multi_collision_test.svh"

endpackage : fpt_ahb_example_package

`endif
