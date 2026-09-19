`ifndef FPT_AHB_TH_SV
`define FPT_AHB_TH_SV

`include "uvm_macros.svh"
`include "fpt_ahb_sva.svh"
`include "fpt_ahb_dummy_interconnect.sv"

module fpt_ahb_th (
    input logic hclk,
    input logic hresetn
);
    import uvm_pkg::*;
    import fpt_ahb_package::*;

    // 1. Declare 4 physical cables
    fpt_ahb_if vif_m0(.hclk(hclk), .hresetn(hresetn));
    fpt_ahb_if vif_m1(.hclk(hclk), .hresetn(hresetn));
    fpt_ahb_if vif_s0(.hclk(hclk), .hresetn(hresetn));
    fpt_ahb_if vif_s1(.hclk(hclk), .hresetn(hresetn));

    assign vif_m0.hselx = 1'b1;
    assign vif_m1.hselx = 1'b1;

    // 2. Instantiate Dummy Interconnect RTL
    fpt_ahb_dummy_interconnect bus_matrix(
        .hclk(hclk),
        .hresetn(hresetn),
        .m0(vif_m0),
        .m1(vif_m1),
        .s0(vif_s0),
        .s1(vif_s1)
    );

    // 3. Register with UVM config db
    initial begin
        uvm_config_db#(virtual fpt_ahb_if)::set(null, "*master_agents\\[0\\]*", "vif", vif_m0);
        uvm_config_db#(virtual fpt_ahb_if)::set(null, "*master_agents\\[1\\]*", "vif", vif_m1);
        uvm_config_db#(virtual fpt_ahb_if)::set(null, "*slave_agents\\[0\\]*", "vif", vif_s0);
        uvm_config_db#(virtual fpt_ahb_if)::set(null, "*slave_agents\\[1\\]*", "vif", vif_s1);
        
        uvm_config_db#(virtual fpt_ahb_if)::set(null, "uvm_test_top", "vif_m0", vif_m0);
        uvm_config_db#(virtual fpt_ahb_if)::set(null, "uvm_test_top", "vif_m1", vif_m1);
        uvm_config_db#(virtual fpt_ahb_if)::set(null, "uvm_test_top", "vif_s0", vif_s0);
        uvm_config_db#(virtual fpt_ahb_if)::set(null, "uvm_test_top", "vif_s1", vif_s1);
    end

    // 4. Instantiate Assertions
    fpt_ahb_sva ahb_sva_m0 (
        .hclk     (vif_m0.hclk),
        .hresetn  (vif_m0.hresetn),
        .hready   (vif_m0.hready),
        .haddr    (vif_m0.haddr),
        .htrans   (vif_m0.htrans),
        .hwrite   (vif_m0.hwrite),
        .hsize    (vif_m0.hsize),
        .hburst   (vif_m0.hburst),
        .hprot    (vif_m0.hprot),
        .hmaster  (vif_m0.hmaster),
        .hmastlock(vif_m0.hmastlock),
        .hwdata   (vif_m0.hwdata),
        .hresp    (vif_m0.hresp),
        .hexcl    (vif_m0.hexcl),
        .hselx    (1'b1), // Masters don't have hsel
        .hwstrb   (vif_m0.hwstrb),
        .hexokay  (vif_m0.hexokay)
    );

endmodule
`endif // FPT_AHB_TH_SV
