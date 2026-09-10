`ifndef FPT_AHB_EXAMPLE_PACKAGE_SV
`define FPT_AHB_EXAMPLE_PACKAGE_SV

`include "uvm_macros.svh"

package fpt_ahb_example_package;

    import uvm_pkg::*;
    import fpt_ahb_package::*;

    `include "env/scoreboard/fpt_ahb_scoreboard.svh"
    `include "env/fpt_ahb_env.svh"

    `include "seq/fpt_ahb_read_after_write_seq.svh"
    `include "seq/fpt_ahb_single_write_seq.svh"
    `include "seq/fpt_ahb_random_rw_seq.svh"

    `include "test/fpt_ahb_base_test.svh"
    `include "test/fpt_ahb_read_after_write_test.svh"
    `include "test/fpt_ahb_single_write_test.svh"
    `include "test/fpt_ahb_random_rw_test.svh"

endpackage : fpt_ahb_example_package

`endif
