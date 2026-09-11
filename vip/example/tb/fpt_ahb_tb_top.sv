`ifndef FPT_AHB_TB_TOP_SV
`define FPT_AHB_TB_TOP_SV

`include "uvm_macros.svh"
`include "fpt_ahb_sva.svh"

module fpt_ahb_tb_top;
    import uvm_pkg::*;
    import fpt_ahb_package::*;
    import fpt_ahb_example_package::*;

    logic hclk;
    logic hresetn;

    initial begin
        hclk = 0;
        forever #5ns hclk = ~hclk;
    end

    initial begin
        hresetn = 0;
        #25ns;
        hresetn = 1;
    end

    fpt_ahb_if ahb_if(
                      .hclk(hclk),
                      .hresetn(hresetn)
                      );

    assign ahb_if.hready = ahb_if.hreadyout;

    initial begin
        uvm_config_db#(virtual fpt_ahb_if)::set(null, "*", "vif", ahb_if);
        run_test();
    end

`ifdef FPT_AHB_ENABLE_FSDB
    initial begin
        $fsdbDumpfile("ahb_vip.fsdb");
        $fsdbDumpvars(0, fpt_ahb_tb_top);
    end
`endif

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

`endif // FPT_AHB_TB_TOP_SV
