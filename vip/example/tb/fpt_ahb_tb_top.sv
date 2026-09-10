`ifndef FPT_AHB_TB_TOP_SV
`define FPT_AHB_TB_TOP_SV

`include "uvm_macros.svh"

module fpt_ahb_tb_top;
  import uvm_pkg::*;
  import fpt_ahb_package::*;

  logic hclk;
  logic hresetn;

  initial begin
    hclk = 0;
    forever #5 hclk = ~hclk; 
  end

  initial begin
    hresetn = 0;
    #25;
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

  initial begin
    $fsdbDumpfile("ahb_vip.fsdb");
    $fsdbDumpvars(0, fpt_ahb_tb_top);
  end

endmodule

`endif // FPT_AHB_TB_TOP_SV
