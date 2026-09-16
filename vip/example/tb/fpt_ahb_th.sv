`ifndef FPT_AHB_TH_SV
`define FPT_AHB_TH_SV

`include "uvm_macros.svh"
`include "fpt_ahb_sva.svh"

module fpt_ahb_th (
    input logic hclk,
    input logic hresetn
);
    import uvm_pkg::*;
    import fpt_ahb_package::*;

    fpt_ahb_if ahb_if(
        .hclk(hclk),
        .hresetn(hresetn)
    );

    // Phase 1: Simple TB/top-level selection policy for verified point-to-point configuration
    assign ahb_if.hready = ahb_if.hreadyout;
    assign ahb_if.hselx = 1'b1;

    initial begin
        uvm_config_db#(virtual fpt_ahb_if)::set(null, "*", "vif", ahb_if);
    end

    fpt_ahb_sva ahb_sva_inst (
        .hclk     (ahb_if.hclk),
        .hresetn  (ahb_if.hresetn),
        .hready   (ahb_if.hready),
        .haddr    (ahb_if.haddr),
        .htrans   (ahb_if.htrans),
        .hwrite   (ahb_if.hwrite),
        .hsize    (ahb_if.hsize),
        .hburst   (ahb_if.hburst),
        .hprot    (ahb_if.hprot),
        .hmaster  (ahb_if.hmaster),
        .hmastlock(ahb_if.hmastlock),
        .hwdata   (ahb_if.hwdata),
        .hresp    (ahb_if.hresp),
        .hexcl    (ahb_if.hexcl),
        .hselx    (ahb_if.hselx),
        .hwstrb   (ahb_if.hwstrb),
        .hexokay  (ahb_if.hexokay)
    );

endmodule

`endif // FPT_AHB_TH_SV
