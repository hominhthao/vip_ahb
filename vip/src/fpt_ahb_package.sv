`include "fpt_ahb_macros.svh"
`include "uvm_macros.svh"

package fpt_ahb_package;

    import uvm_pkg::*;

    // Direction values match the HWRITE signal encoding.
    typedef enum logic {
        FPT_AHB_READ  = 1'b0,
        FPT_AHB_WRITE = 1'b1
    } fpt_ahb_direction_e;

    // Preserve the HSIZE encoding width; v0.0 supports WORD only.
    typedef enum logic [2:0] {
        FPT_AHB_WORD = 3'b010
    } fpt_ahb_size_e;

    // Preserve the HBURST encoding width; v0.0 supports SINGLE only.
    typedef enum logic [2:0] {
        FPT_AHB_SINGLE = 3'b000
    } fpt_ahb_burst_e;

    // AHB-Lite uses a one-bit HRESP signal.
    typedef enum logic {
        FPT_AHB_OKAY  = 1'b0,
        FPT_AHB_ERROR = 1'b1
    } fpt_ahb_response_e;

    `include "fpt_ahb_master_transaction.svh"
    `include "fpt_ahb_slave_transaction.svh"

endpackage : fpt_ahb_package
