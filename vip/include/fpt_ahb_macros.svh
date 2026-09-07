`ifndef FPT_AHB_MACROS_SVH
`define FPT_AHB_MACROS_SVH

// Overrideable defaults; v0.0 support is limited to 32-bit address/data buses.
`ifndef FPT_AHB_VIP_ADDR_WIDTH
    `define FPT_AHB_VIP_ADDR_WIDTH 32
`endif

`ifndef FPT_AHB_VIP_DATA_WIDTH
    `define FPT_AHB_VIP_DATA_WIDTH 32
`endif

`endif
