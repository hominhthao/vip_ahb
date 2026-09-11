`ifndef FPT_AHB_IF_SVH
`define FPT_AHB_IF_SVH

`include "fpt_ahb_macros.svh"

interface fpt_ahb_if (input hclk, input hresetn);

    logic [`FPT_AHB_VIP_ADDR_WIDTH-1:0] haddr;
    logic [`FPT_AHB_VIP_NO_OF_SLAVES-1:0] hselx;
    logic [2:0]                           hburst;
    logic                                 hmastlock;
    logic [`FPT_AHB_VIP_HPROT_WIDTH-1:0]  hprot;
    logic [2:0]                           hsize;
    logic                                 hnonsec;
    logic                                 hexcl;
    logic [`FPT_AHB_VIP_HMASTER_WIDTH-1:0] hmaster;
    logic [1:0]                            htrans;
    logic [`FPT_AHB_VIP_DATA_WIDTH-1:0]    hwdata;
    logic [(`FPT_AHB_VIP_DATA_WIDTH/8)-1:0] hwstrb;
    logic                                   hwrite;
    logic [`FPT_AHB_VIP_DATA_WIDTH-1:0]     hrdata;
    logic                                   hreadyout;
    logic                                   hresp;
    logic                                   hexokay;
    logic                                   hready;

    clocking cb_master @(posedge hclk);
        default input #1step output #1step;
        input  hrdata, hready, hresp, hexokay, hreadyout;
        output haddr, htrans, hwrite, hsize, hburst, hprot, hwdata, hselx, hmastlock, hexcl, hwstrb, hmaster, hnonsec;
    endclocking

    clocking cb_slave @(posedge hclk);
        default input #1step output #1step;
        input  haddr, hready, htrans, hwrite, hsize, hburst, hprot, hwdata, hselx, hmastlock, hexcl, hwstrb, hmaster, hnonsec;
        output hrdata, hresp, hexokay, hreadyout;
    endclocking

    clocking cb_monitor @(posedge hclk);
        default input #1step;
        input haddr, hselx, hburst, hmastlock, hprot, hsize, hnonsec, hexcl, hmaster, htrans, hwdata, hwstrb, hwrite, hrdata, hreadyout, hresp, hexokay, hready;
    endclocking

    modport master (
                    input hclk, hresetn,
                    import cb_master
                    );

    modport slave (
                   input hclk, hresetn,
                   import cb_slave
                   );

    modport monitor (
                     input hclk, hresetn,
                     import cb_monitor
                     );

endinterface

`endif // FPT_AHB_IF_SVH
