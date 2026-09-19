`ifndef FPT_AHB_PACKAGE_SV
`define FPT_AHB_PACKAGE_SV

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
        FPT_AHB_SINGLE = 3'b000,
        FPT_AHB_INCR   = 3'b001,
        FPT_AHB_WRAP4  = 3'b010,
        FPT_AHB_INCR4  = 3'b011,
        FPT_AHB_WRAP8  = 3'b100,
        FPT_AHB_INCR8  = 3'b101,
        FPT_AHB_WRAP16 = 3'b110,
        FPT_AHB_INCR16 = 3'b111
    } fpt_ahb_burst_e;

    typedef enum logic [1:0] {
        FPT_AHB_IDLE   = 2'b00,
        FPT_AHB_BUSY   = 2'b01,
        FPT_AHB_NONSEQ = 2'b10,
        FPT_AHB_SEQ    = 2'b11
    } fpt_ahb_trans_e;

    typedef enum logic {
        FPT_AHB_OKAY  = 1'b0,
        FPT_AHB_ERROR = 1'b1
    } fpt_ahb_response_e;

    typedef enum logic [1:0] {
        FPT_AHB_ZERO_WAIT,
        FPT_AHB_FIXED_WAIT,
        FPT_AHB_RANDOM_WAIT
    } fpt_ahb_wait_mode_e;

    `include "fpt_ahb_common_memory.svh"
    `include "fpt_ahb_master_transaction.svh"
    `include "fpt_ahb_slave_transaction.svh"
    `include "fpt_ahb_beat_transaction.svh"
    `include "fpt_ahb_utilities.svh"

    `include "master_agent/fpt_ahb_master_agent_cfg.svh"
    `include "master_agent/fpt_ahb_master_driver.svh"
    `include "master_agent/fpt_ahb_master_monitor.svh"
    `include "master_agent/fpt_ahb_master_agent.svh"

    `include "slave_agent/fpt_ahb_slave_agent_cfg.svh"
    `include "fpt_ahb_env_cfg.svh"
    `include "slave_agent/fpt_ahb_slave_driver.svh"
    `include "slave_agent/fpt_ahb_slave_monitor.svh"
    `include "slave_agent/fpt_ahb_slave_agent.svh"
    `include "fpt_ahb_predictor.svh"

    `include "sequence_lib/fpt_ahb_master_base_seq.svh"
    `include "sequence_lib/fpt_ahb_slave_base_seq.svh"
    `include "sequence_lib/fpt_ahb_slave_mem_seq.svh"

endpackage : fpt_ahb_package

`endif // FPT_AHB_PACKAGE_SV
