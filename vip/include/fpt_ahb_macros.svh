`ifndef FPT_AHB_MACROS_SVH
`define FPT_AHB_MACROS_SVH

// Overrideable defaults; v0.0 support is limited to 32-bit address/data buses.
`ifndef FPT_AHB_VIP_ADDR_WIDTH
    `define FPT_AHB_VIP_ADDR_WIDTH 32
`endif

`ifndef FPT_AHB_VIP_DATA_WIDTH
    `define FPT_AHB_VIP_DATA_WIDTH 32
`endif

`ifndef FPT_AHB_VIP_NO_OF_SLAVES
    `define FPT_AHB_VIP_NO_OF_SLAVES 1
`endif

`ifndef FPT_AHB_VIP_HPROT_WIDTH
    `define FPT_AHB_VIP_HPROT_WIDTH 4
`endif

`ifndef FPT_AHB_VIP_HMASTER_WIDTH
    `define FPT_AHB_VIP_HMASTER_WIDTH 4
`endif

`define FPT_AHB_TR_IDLE    2'b00
`define FPT_AHB_TR_BUSY    2'b01
`define FPT_AHB_TR_NONSEQ  2'b10
`define FPT_AHB_TR_SEQ     2'b11
  
`define FPT_AHB_RESP_OKAY  1'b0
`define FPT_AHB_RESP_ERROR 1'b1


`endif // FPT_AHB_MACROS_SVH