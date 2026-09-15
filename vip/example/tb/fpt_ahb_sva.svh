`ifndef FPT_AHB_SVA_SVH
`define FPT_AHB_SVA_SVH

`include "fpt_ahb_macros.svh"

interface fpt_ahb_sva #(
                        )(
                          input logic                                   hclk,
                          input logic                                   hresetn,
                          input logic                                   hready,
                          input logic [`FPT_AHB_VIP_ADDR_WIDTH-1:0]     haddr,
                          input logic [1:0]                             htrans,
                          input logic                                   hwrite,
                          input logic [2:0]                             hsize,
                          input logic [2:0]                             hburst,
                          input logic [`FPT_AHB_VIP_HPROT_WIDTH-1:0]    hprot,
                          input logic [`FPT_AHB_VIP_HMASTER_WIDTH-1:0]  hmaster,
                          input logic                                   hmastlock,
                          input logic [`FPT_AHB_VIP_DATA_WIDTH-1:0]     hwdata,
                          input logic                                   hresp,
                          input logic                                   hexcl,
                          input logic                                   hselx,
                          input logic [(`FPT_AHB_VIP_DATA_WIDTH/8)-1:0] hwstrb,
                          input logic                                   hexokay
                          );

    import uvm_pkg::*;
`include "uvm_macros.svh"


    // =========================================================================
    // 1. ASSERTION COVERAGE (SHARED PROPERTIES)
    // =========================================================================

    sequence s_active_transfer;
        hselx && (htrans inside {`FPT_AHB_TR_NONSEQ, `FPT_AHB_TR_SEQ});
    endsequence

    sequence s_accepted_transfer;
        hselx && hready &&
        (htrans inside {`FPT_AHB_TR_NONSEQ, `FPT_AHB_TR_SEQ});
    endsequence

    sequence s_accepted_write;
        hselx && hready && hwrite &&
        (htrans inside {`FPT_AHB_TR_NONSEQ, `FPT_AHB_TR_SEQ});
    endsequence

    // --- Control signals validity ---
    property p_htrans_not_x;  @(posedge hclk) disable iff (!hresetn) hselx |-> !$isunknown(htrans); endproperty
    property p_hwrite_not_x;  @(posedge hclk) disable iff (!hresetn) s_active_transfer |-> !$isunknown(hwrite); endproperty
    property p_hsize_not_x;   @(posedge hclk) disable iff (!hresetn) s_active_transfer |-> !$isunknown(hsize);  endproperty
    property p_hburst_not_x;  @(posedge hclk) disable iff (!hresetn) s_active_transfer |-> !$isunknown(hburst); endproperty
    property p_haddr_not_x;   @(posedge hclk) disable iff (!hresetn) s_active_transfer |-> !$isunknown(haddr);  endproperty

    assert_htrans_not_x: assert property (p_htrans_not_x) else `uvm_error("AHB_SVA", "htrans contains X");
    cover_htrans_not_x:  cover property (p_htrans_not_x);

    assert_hwrite_not_x: assert property (p_hwrite_not_x) else `uvm_error("AHB_SVA", "hwrite contains X");
    cover_hwrite_not_x:  cover property (p_hwrite_not_x);

    assert_hsize_not_x:  assert property (p_hsize_not_x)  else `uvm_error("AHB_SVA", "hsize contains X");
    cover_hsize_not_x:   cover property (p_hsize_not_x);

    assert_hburst_not_x: assert property (p_hburst_not_x) else `uvm_error("AHB_SVA", "hburst contains X");
    cover_hburst_not_x:  cover property (p_hburst_not_x);

    assert_haddr_not_x:  assert property (p_haddr_not_x)  else `uvm_error("AHB_SVA", "haddr contains X");
    cover_haddr_not_x:   cover property (p_haddr_not_x);

    // --- Stability during wait ---
    // A LOW HREADY holds the address/control phase visible in that cycle. The
    // non-overlapped check permits a pipelined next phase to appear before the
    // first LOW sample, then holds that phase through the accepting HIGH edge.
    property p_haddr_stable;  @(posedge hclk) disable iff (!hresetn) !hready |=> $stable(haddr);  endproperty
    property p_htrans_stable; @(posedge hclk) disable iff (!hresetn) !hready |=> $stable(htrans); endproperty
    property p_hwrite_stable; @(posedge hclk) disable iff (!hresetn) !hready |=> $stable(hwrite); endproperty
    property p_hsize_stable;  @(posedge hclk) disable iff (!hresetn) !hready |=> $stable(hsize);  endproperty
    property p_hburst_stable; @(posedge hclk) disable iff (!hresetn) !hready |=> $stable(hburst); endproperty
    property p_hprot_stable;  @(posedge hclk) disable iff (!hresetn) !hready |=> $stable(hprot);  endproperty

    assert_haddr_stable:  assert property (p_haddr_stable)  else `uvm_error("AHB_WAIT_STABILITY", "haddr changed while HREADY was LOW");
    cover_haddr_stable:   cover property (p_haddr_stable);
    assert_htrans_stable: assert property (p_htrans_stable) else `uvm_error("AHB_WAIT_STABILITY", "htrans changed while HREADY was LOW");
    cover_htrans_stable:  cover property (p_htrans_stable);
    assert_hwrite_stable: assert property (p_hwrite_stable) else `uvm_error("AHB_WAIT_STABILITY", "hwrite changed while HREADY was LOW");
    cover_hwrite_stable:  cover property (p_hwrite_stable);
    assert_hsize_stable:  assert property (p_hsize_stable)  else `uvm_error("AHB_WAIT_STABILITY", "hsize changed while HREADY was LOW");
    cover_hsize_stable:   cover property (p_hsize_stable);
    assert_hburst_stable: assert property (p_hburst_stable) else `uvm_error("AHB_WAIT_STABILITY", "hburst changed while HREADY was LOW");
    cover_hburst_stable:  cover property (p_hburst_stable);
    assert_hprot_stable:  assert property (p_hprot_stable)  else `uvm_error("AHB_WAIT_STABILITY", "hprot changed while HREADY was LOW");
    cover_hprot_stable:   cover property (p_hprot_stable);

    // --- Write Data valid ---
    property p_hwdata_valid; @(posedge hclk) disable iff (!hresetn) s_accepted_write ##1 (hready [->1]) |-> !($isunknown(hwdata)); endproperty
    property p_hwdata_stable; @(posedge hclk) disable iff (!hresetn) s_accepted_write ##1 !hready |=> $stable(hwdata) until_with hready; endproperty

    assert_hwdata_valid: assert property (p_hwdata_valid) else `uvm_error("AHB_SVA", "hwdata contains X during write");
    cover_hwdata_valid:  cover property (p_hwdata_valid);
    assert_hwdata_stable: assert property (p_hwdata_stable) else `uvm_error("AHB_WAIT_HWDATA", "hwdata changed while its WRITE data phase was stalled");
    cover_hwdata_stable:  cover property (p_hwdata_stable);

    // --- FSM transitions ---
    property p_trans_busy_seq;   @(posedge hclk) disable iff (!hresetn) (hready && $past(htrans) == `FPT_AHB_TR_BUSY && htrans == `FPT_AHB_TR_SEQ) |-> (haddr == $past(haddr)) && (hsize == $past(hsize)) && (hburst == $past(hburst)); endproperty
    property p_trans_busy_nonseq;@(posedge hclk) disable iff (!hresetn) (hready && $past(htrans) == `FPT_AHB_TR_BUSY && htrans == `FPT_AHB_TR_NONSEQ) |-> (haddr & ((1 << hsize) - 1)) == 0; endproperty
    property p_trans_idle_nonseq;@(posedge hclk) disable iff (!hresetn) (hready && $past(htrans) == `FPT_AHB_TR_IDLE && htrans == `FPT_AHB_TR_NONSEQ) |-> (haddr & ((1 << hsize) - 1)) == 0; endproperty
    property p_trans_idle_seq;   @(posedge hclk) disable iff (!hresetn) (hready && $past(htrans) == `FPT_AHB_TR_IDLE) |-> (htrans != `FPT_AHB_TR_SEQ); endproperty

    assert_trans_busy_seq:   assert property (p_trans_busy_seq)   else `uvm_error("AHB_SVA", "BUSY to SEQ violated stability");
    cover_trans_busy_seq:    cover property (p_trans_busy_seq);
    assert_trans_busy_nonseq:assert property (p_trans_busy_nonseq)else `uvm_error("AHB_SVA", "BUSY to NONSEQ misaligned");
    cover_trans_busy_nonseq: cover property (p_trans_busy_nonseq);
    assert_trans_idle_nonseq:assert property (p_trans_idle_nonseq)else `uvm_error("AHB_SVA", "IDLE to NONSEQ misaligned");
    cover_trans_idle_nonseq: cover property (p_trans_idle_nonseq);
    assert_trans_idle_seq:   assert property (p_trans_idle_seq)   else `uvm_error("AHB_SVA", "IDLE to SEQ not allowed");
    cover_trans_idle_seq:    cover property (p_trans_idle_seq);

    // --- Responses ---
    property p_hresp_err_2cycle; @(posedge hclk) disable iff (!hresetn) (hresp == `FPT_AHB_RESP_ERROR && !hready) |=> (hresp == `FPT_AHB_RESP_ERROR && hready); endproperty
    property p_hresp_okay_idle;  @(posedge hclk) disable iff (!hresetn) (hready && htrans == `FPT_AHB_TR_IDLE && $past(htrans) == `FPT_AHB_TR_IDLE) |=> (hresp == `FPT_AHB_RESP_OKAY); endproperty

    assert_hresp_err_2cycle: assert property (p_hresp_err_2cycle) else `uvm_error("AHB_SVA", "ERROR must last 2 cycles");
    cover_hresp_err_2cycle:  cover property (p_hresp_err_2cycle);
    assert_hresp_okay_idle:  assert property (p_hresp_okay_idle)  else `uvm_error("AHB_SVA", "ERROR illegal in IDLE");
    cover_hresp_okay_idle:   cover property (p_hresp_okay_idle);

    // =========================================================================
    // 2. FUNCTIONAL COVERAGE (SCENARIO TRACKING ONLY)
    // =========================================================================

    cover_accepted_transfer: cover property (@(posedge hclk) disable iff (!hresetn) s_accepted_transfer);
    cover_presented_during_wait: cover property (@(posedge hclk) disable iff (!hresetn) hselx && !hready && (htrans inside {`FPT_AHB_TR_NONSEQ, `FPT_AHB_TR_SEQ}));

    cover_htrans_idle:   cover property (@(posedge hclk) disable iff (!hresetn) hready && htrans == 2'b00);
    cover_htrans_busy:   cover property (@(posedge hclk) disable iff (!hresetn) hselx && hready && htrans == 2'b01);
    cover_htrans_nonseq: cover property (@(posedge hclk) disable iff (!hresetn) hselx && hready && htrans == 2'b10);
    cover_htrans_seq:    cover property (@(posedge hclk) disable iff (!hresetn) hselx && hready && htrans == 2'b11);

    cover_write_transfer: cover property (@(posedge hclk) disable iff (!hresetn) hselx && hready && htrans inside {2'b10, 2'b11} && hwrite);
    cover_read_transfer:  cover property (@(posedge hclk) disable iff (!hresetn) hselx && hready && htrans inside {2'b10, 2'b11} && !hwrite);

    cover_burst_single: cover property (@(posedge hclk) disable iff (!hresetn) hselx && hready && htrans == 2'b10 && hburst == 3'b000);
    cover_burst_incr4:  cover property (@(posedge hclk) disable iff (!hresetn) hselx && hready && htrans == 2'b10 && hburst == 3'b011);
    cover_burst_wrap4:  cover property (@(posedge hclk) disable iff (!hresetn) hselx && hready && htrans == 2'b10 && hburst == 3'b010);

    cover_size_byte:   cover property (@(posedge hclk) disable iff (!hresetn) hselx && hready && htrans inside {2'b10, 2'b11} && hsize == 3'b000);
    cover_size_word:   cover property (@(posedge hclk) disable iff (!hresetn) hselx && hready && htrans inside {2'b10, 2'b11} && hsize == 3'b010);

    cover_multi_wait:  cover property (@(posedge hclk) disable iff (!hresetn) s_accepted_transfer ##1 (!hready)[*2:$] ##1 hready);


endinterface

`endif // FPT_AHB_SVA_SVH
