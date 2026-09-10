`include "fpt_ahb_macros.svh"
`include "uvm_macros.svh"

package fpt_ahb_package;

    import uvm_pkg::*;

    typedef enum logic {
        FPT_AHB_READ  = 1'b0,
        FPT_AHB_WRITE = 1'b1
    } fpt_ahb_direction_e;

    typedef enum logic [2:0] {
        FPT_AHB_WORD = 3'b010
    } fpt_ahb_size_e;

    typedef enum logic [2:0] {
        FPT_AHB_SINGLE = 3'b000
    } fpt_ahb_burst_e;

    typedef enum logic {
        FPT_AHB_OKAY  = 1'b0,
        FPT_AHB_ERROR = 1'b1
    } fpt_ahb_response_e;

    `include "fpt_ahb_common_memory.svh"
    `include "fpt_ahb_master_transaction.svh"
    `include "fpt_ahb_slave_transaction.svh"

    `include "fpt_ahb_scoreboard.svh"

    `include "fpt_ahb_master_agent_cfg.svh"
    `include "fpt_ahb_master_driver.svh"
    `include "fpt_ahb_master_monitor.svh"
    `include "fpt_ahb_master_agent.svh"

    `include "fpt_ahb_slave_agent_cfg.svh"
    `include "fpt_ahb_slave_driver.svh"
    `include "fpt_ahb_slave_monitor.svh"
    `include "fpt_ahb_slave_agent.svh"

    `include "fpt_ahb_master_base_seq.svh"
    `include "fpt_ahb_slave_base_seq.svh"
    `include "fpt_ahb_slave_mem_seq.svh"

    `include "fpt_ahb_env.svh"
    `include "fpt_ahb_base_test.svh"

    `include "fpt_ahb_read_after_write_seq.svh"
    `include "fpt_ahb_single_write_seq.svh"
    
    `include "fpt_ahb_read_after_write_test.svh"
    `include "fpt_ahb_single_write_test.svh"

endpackage : fpt_ahb_package
