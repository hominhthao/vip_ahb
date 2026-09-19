`ifndef FPT_AHB_TB_TOP_SV
`define FPT_AHB_TB_TOP_SV

`include "uvm_macros.svh"
`include "fpt_ahb_th.sv"

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

    // Instantiate the configurable Test Harness
    fpt_ahb_th th(
        .hclk(hclk),
        .hresetn(hresetn)
    );

    initial begin
        run_test();
    end

`ifdef FPT_AHB_ENABLE_FSDB
    initial begin
        $fsdbDumpfile("ahb_vip.fsdb");
        $fsdbDumpvars(0, fpt_ahb_tb_top);
    end
`endif

endmodule

`endif // FPT_AHB_TB_TOP_SV
