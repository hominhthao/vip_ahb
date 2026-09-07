`ifndef FPT_AHB_IF_SVH
`define FPT_AHB_IF_SVH



interface ahb_if (input logic hclk, input logic hresetn);

	logic [AHB_ADDR_WIDTH-1:0]     haddr;
    logic [AHB_NO_OF_SLAVES-1:0]   hselx;
    logic [2:0]                    hburst;
    logic                          hmastlock;
    logic [HPROT_WIDTH-1:0]        hprot; 
    logic [2:0]                    hsize;
    logic                          hnonsec;
    logic                          hexcl;
    logic [HMASTER_WIDTH-1:0]      hmaster;
    logic [1:0]                    htrans;
    logic [AHB_DATA_WIDTH-1:0]     hwdata;
    logic [(AHB_DATA_WIDTH/8)-1:0] hwstrb;
    logic                          hwrite;
    logic [AHB_DATA_WIDTH-1:0]     hrdata;
    logic                          hreadyout;
    logic                          hresp;
    logic                          hexokay;
    logic                          hready;

	clocking cb_master @(posedge hclk);
        default input #1step output #1step;
		input  hrdata, hready, hresp, hexokay, hreadyout;
		output haddr, htrans, hwrite, hsize, hburst, hprot, hwdata, hselx, hmastlock, hexcl, hwstrb, hmaster, hnonsec;
	endclocking

	clocking cb_slave @(posedge hclk);
        default input #1step output #1step;
		input  haddr, htrans, hwrite, hsize, hburst, hprot, hwdata, hselx, hmastlock, hexcl, hwstrb, hmaster, hnonsec;
		output hrdata, hready, hresp, hexokay, hreadyout;
	endclocking

	modport master (
		input hclk, hresetn,
		import cb_master
	);

	modport slave (
		input hclk, hresetn,
		import cb_slave
	);
endinterface

module ahb_sva (ahb_if vif);

    localparam TR_IDLE   = 2'b00;
    localparam TR_BUSY   = 2'b01;
    localparam TR_NONSEQ = 2'b10;
    localparam TR_SEQ    = 2'b11;

    localparam RESP_OKAY  = 1'b0;
    localparam RESP_ERROR = 1'b1;

    wire any_hsel = (|vif.hselx);

    assert_htrans_not_x: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        any_hsel |-> !$isunknown(vif.htrans)
    ) else $error("[AHB_SVA] htrans contains X when hselx is HIGH");

    assert_hwrite_not_x: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        any_hsel |-> !$isunknown(vif.hwrite)
    ) else $error("[AHB_SVA] hwrite contains X when hselx is HIGH");

    assert_hsize_not_x: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        any_hsel |-> !$isunknown(vif.hsize)
    ) else $error("[AHB_SVA] hsize contains X when hselx is HIGH");

    assert_hburst_not_x: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        any_hsel |-> !$isunknown(vif.hburst)
    ) else $error("[AHB_SVA] hburst contains X when hselx is HIGH");

    assert_haddr_not_x: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        any_hsel |-> !$isunknown(vif.haddr)
    ) else $error("[AHB_SVA] haddr contains X when hselx is HIGH");

    assert_haddr_stable_during_wait: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (any_hsel && !vif.hready && (vif.htrans inside {TR_NONSEQ, TR_SEQ})) |=> $stable(vif.haddr)
    ) else $error("[AHB_SVA] haddr unstable during wait state");

    assert_htrans_stable_during_wait: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (any_hsel && !vif.hready && (vif.htrans inside {TR_NONSEQ, TR_SEQ})) |=> $stable(vif.htrans)
    ) else $error("[AHB_SVA] htrans unstable during wait state");

    assert_hwrite_stable_during_wait: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (any_hsel && !vif.hready && (vif.htrans inside {TR_NONSEQ, TR_SEQ})) |=> $stable(vif.hwrite)
    ) else $error("[AHB_SVA] hwrite unstable during wait state");

    assert_hsize_stable_during_wait: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (any_hsel && !vif.hready && (vif.htrans inside {TR_NONSEQ, TR_SEQ})) |=> $stable(vif.hsize)
    ) else $error("[AHB_SVA] hsize unstable during wait state");

    assert_hburst_stable_during_wait: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (any_hsel && !vif.hready && (vif.htrans inside {TR_NONSEQ, TR_SEQ})) |=> $stable(vif.hburst)
    ) else $error("[AHB_SVA] hburst unstable during wait state");
    
    assert_haddr_aligned_halfword: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (any_hsel && vif.hready && (vif.htrans inside {TR_NONSEQ, TR_SEQ}) && vif.hsize == 3'b001) |-> 
        (vif.haddr & 32'h0000_0001) == 0
    ) else $error("[AHB_SVA] haddr misaligned for HALFWORD");

    assert_haddr_aligned_word: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (any_hsel && vif.hready && (vif.htrans inside {TR_NONSEQ, TR_SEQ}) && vif.hsize == 3'b010) |-> 
        (vif.haddr & 32'h0000_0003) == 0
    ) else $error("[AHB_SVA] haddr misaligned for WORD");

    assert_haddr_aligned_doubleword: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (any_hsel && vif.hready && (vif.htrans inside {TR_NONSEQ, TR_SEQ}) && vif.hsize == 3'b011) |-> 
        (vif.haddr & 32'h0000_0007) == 0
    ) else $error("[AHB_SVA] haddr misaligned for DOUBLEWORD");

    assert_haddr_aligned_128bit: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (any_hsel && vif.hready && (vif.htrans inside {TR_NONSEQ, TR_SEQ}) && vif.hsize == 3'b100) |-> 
        (vif.haddr & 32'h0000_000F) == 0
    ) else $error("[AHB_SVA] haddr misaligned for 128-BIT");

    sequence s_write_addr_phase;
        (any_hsel && vif.hready && (vif.htrans inside {TR_NONSEQ, TR_SEQ}) && vif.hwrite);
    endsequence

    assert_hwdata_valid_during_write: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        s_write_addr_phase ##1 (vif.hready [->1]) |-> !($isunknown(vif.hwdata))
    ) else $error("[AHB_SVA] hwdata contains X during write data phase");

    CheckTransBusyToSeqAssertion: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (vif.hready && $past(vif.htrans) == TR_BUSY && vif.htrans == TR_SEQ) |->
            (vif.haddr == $past(vif.haddr)) && 
            (vif.hsize == $past(vif.hsize)) && 
            (vif.hburst == $past(vif.hburst))
    ) else $error("[AHB_SVA] BUSY to SEQ transition violated address/control stability");

    CheckTransBusyToNonSeqAssertion: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (vif.hready && $past(vif.htrans) == TR_BUSY && vif.htrans == TR_NONSEQ) |->
            (vif.haddr & ((1 << vif.hsize) - 1)) == 0
    ) else $error("[AHB_SVA] BUSY to NONSEQ transition produced misaligned address");

    CheckTransIdleToNonSeqAssertion: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (vif.hready && $past(vif.htrans) == TR_IDLE && vif.htrans == TR_NONSEQ) |->
            (vif.haddr & ((1 << vif.hsize) - 1)) == 0
    ) else $error("[AHB_SVA] IDLE to NONSEQ transition produced misaligned address");

    CheckTransIdleToSeqNotAllowedAssertion: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (vif.hready && $past(vif.htrans) == TR_IDLE) |-> (vif.htrans != TR_SEQ)
    ) else $error("[AHB_SVA] IDLE cannot transition directly to SEQ");

    assert_hresp_error_two_cycle: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (vif.hresp == RESP_ERROR && !vif.hready) |=> (vif.hresp == RESP_ERROR && vif.hready)
    ) else $error("[AHB_SVA] ERROR response must last exactly 2 cycles");

    assert_hresp_okay_for_idle: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (vif.hready && vif.htrans == TR_IDLE && $past(vif.htrans) == TR_IDLE) |=> 
        (vif.hresp == RESP_OKAY)
    ) else $error("[AHB_SVA] hresp ERROR is illegal during IDLE state");

    assert_hresp_okay_for_valid_trans: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (any_hsel && vif.hready && (vif.htrans inside {TR_NONSEQ, TR_SEQ})) |=> 
        (vif.hresp == RESP_OKAY)
    ) else $info("[AHB_SVA] Transfer did not receive OKAY response (Negative Test Scenario)");

    assert_incr_undef_address_step: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (any_hsel && vif.hready && (vif.htrans == TR_SEQ) && (vif.hburst == 3'b001)) |->
            (vif.haddr == ($past(vif.haddr) + (1 << $past(vif.hsize))))
    ) else $error("[AHB_SVA] INCR (undef) address increment logic violated");

    assert_incr4_address_step: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (any_hsel && vif.hready && (vif.htrans == TR_SEQ) && (vif.hburst == 3'b011)) |->
            (vif.haddr == ($past(vif.haddr) + (1 << $past(vif.hsize))))
    ) else $error("[AHB_SVA] INCR4 address increment logic violated");

    assert_incr8_address_step: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (any_hsel && vif.hready && (vif.htrans == TR_SEQ) && (vif.hburst == 3'b101)) |->
            (vif.haddr == ($past(vif.haddr) + (1 << $past(vif.hsize))))
    ) else $error("[AHB_SVA] INCR8 address increment logic violated");

    assert_incr16_address_step: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (any_hsel && vif.hready && (vif.htrans == TR_SEQ) && (vif.hburst == 3'b111)) |->
            (vif.haddr == ($past(vif.haddr) + (1 << $past(vif.hsize))))
    ) else $error("[AHB_SVA] INCR16 address increment logic violated");

    assert_wrap4_address_step: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (any_hsel && vif.hready && (vif.htrans == TR_SEQ) && (vif.hburst == 3'b010)) |->
            vif.haddr == ( ($past(vif.haddr) & ~((1 << ($past(vif.hsize) + 2)) - 1)) |
                           (($past(vif.haddr) + (1 << $past(vif.hsize))) & ((1 << ($past(vif.hsize) + 2)) - 1)) )
    ) else $error("[AHB_SVA] WRAP4 address wrap logic violated");

    assert_wrap8_address_step: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (any_hsel && vif.hready && (vif.htrans == TR_SEQ) && (vif.hburst == 3'b100)) |->
            vif.haddr == ( ($past(vif.haddr) & ~((1 << ($past(vif.hsize) + 3)) - 1)) |
                           (($past(vif.haddr) + (1 << $past(vif.hsize))) & ((1 << ($past(vif.hsize) + 3)) - 1)) )
    ) else $error("[AHB_SVA] WRAP8 address wrap logic violated");

    assert_wrap16_address_step: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (any_hsel && vif.hready && (vif.htrans == TR_SEQ) && (vif.hburst == 3'b110)) |->
            vif.haddr == ( ($past(vif.haddr) & ~((1 << ($past(vif.hsize) + 4)) - 1)) |
                           (($past(vif.haddr) + (1 << $past(vif.hsize))) & ((1 << ($past(vif.hsize) + 4)) - 1)) )
    ) else $error("[AHB_SVA] WRAP16 address wrap logic violated");

    assert_hsize_le_buswidth: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (any_hsel && vif.hready && (vif.htrans != TR_IDLE)) |-> ((1 << vif.hsize) * 8 <= $bits(vif.hwdata))
    ) else $error("[AHB_SVA] hsize exceeds AHB_DATA_WIDTH");

    assert_burst_1kb_boundary: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (any_hsel && vif.hready && (vif.htrans == TR_SEQ)) |-> (vif.haddr[9:0] != 10'h000)
    ) else $error("[AHB_SVA] Burst crossed 1KB address boundary!");

    assert_hmastlock_stable_during_wait: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (any_hsel && !vif.hready) |=> ($stable(vif.hmastlock))
    ) else $error("[AHB_SVA] hmastlock must remain stable when hready is low");

    assert_hwstrb_zero_on_read: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (any_hsel && vif.hready && (vif.htrans inside {TR_NONSEQ, TR_SEQ}) && !vif.hwrite) ##1 (vif.hready [->1]) |-> (vif.hwstrb == 0)
    ) else $error("[AHB5_SVA] hwstrb must be 0 during a READ data phase");

    assert_hwstrb_zero_on_idle_busy: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (vif.hready && (vif.htrans inside {TR_IDLE, TR_BUSY})) |=> (vif.hwstrb == 0)
    ) else $error("[AHB5_SVA] hwstrb must be 0 during data phase of IDLE or BUSY");

    assert_hexcl_only_nonseq: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (any_hsel && vif.hexcl && vif.htrans != TR_IDLE) |-> (vif.htrans == TR_NONSEQ)
    ) else $error("[AHB5_SVA] Exclusive access must be a NONSEQ transfer");

    assert_hexokay_requires_hresp_okay: assert property (
        @(posedge vif.hclk) disable iff (!vif.hresetn)
        (vif.hready && vif.hexokay) |-> (vif.hresp == RESP_OKAY)
    ) else $error("[AHB5_SVA] hexokay cannot be asserted when hresp is ERROR");

endmodule

`endif 
