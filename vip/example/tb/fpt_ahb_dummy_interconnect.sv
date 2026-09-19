`ifndef FPT_AHB_DUMMY_INTERCONNECT_SV
`define FPT_AHB_DUMMY_INTERCONNECT_SV

module fpt_ahb_dummy_interconnect (
    input logic hclk,
    input logic hresetn,
    fpt_ahb_if m0,
    fpt_ahb_if m1,
    fpt_ahb_if s0,
    fpt_ahb_if s1
);
    import fpt_ahb_package::*;

    // Address Map Parameters (Must match uvm config)
    localparam logic [31:0] S0_START = 32'h0000_0000;
    localparam logic [31:0] S0_END   = 32'h0000_0FFF;
    localparam logic [31:0] S1_START = 32'h0000_1000;
    localparam logic [31:0] S1_END   = 32'h0000_1FFF;

    // 1. Decoder
    logic m0_req_s0, m0_req_s1;
    logic m1_req_s0, m1_req_s1;

    assign m0_req_s0 = (m0.htrans != FPT_AHB_IDLE) && (m0.haddr >= S0_START && m0.haddr <= S0_END);
    assign m0_req_s1 = (m0.htrans != FPT_AHB_IDLE) && (m0.haddr >= S1_START && m0.haddr <= S1_END);
    
    assign m1_req_s0 = (m1.htrans != FPT_AHB_IDLE) && (m1.haddr >= S0_START && m1.haddr <= S0_END);
    assign m1_req_s1 = (m1.htrans != FPT_AHB_IDLE) && (m1.haddr >= S1_START && m1.haddr <= S1_END);

    // 2. Arbiter (Static Priority: M0 > M1)
    logic [1:0] s0_grant_addr_phase; // 0=M0, 1=M1, 2=None
    logic [1:0] s1_grant_addr_phase;

    always_comb begin
        if (m0_req_s0) s0_grant_addr_phase = 0;
        else if (m1_req_s0) s0_grant_addr_phase = 1;
        else s0_grant_addr_phase = 2;
    end

    always_comb begin
        if (m0_req_s1) s1_grant_addr_phase = 0;
        else if (m1_req_s1) s1_grant_addr_phase = 1;
        else s1_grant_addr_phase = 2;
    end

    // Data phase tracking (pipelined)
    logic [1:0] s0_grant_data_phase;
    logic [1:0] s1_grant_data_phase;

    always_ff @(posedge hclk or negedge hresetn) begin
        if (!hresetn) begin
            s0_grant_data_phase <= 2;
            s1_grant_data_phase <= 2;
        end else begin
            if (s0.hready) s0_grant_data_phase <= s0_grant_addr_phase;
            if (s1.hready) s1_grant_data_phase <= s1_grant_addr_phase;
        end
    end

    // 3. Mux (Master -> Slave Address Phase)
    // S0
    assign s0.haddr     = (s0_grant_addr_phase == 0) ? m0.haddr     : ((s0_grant_addr_phase == 1) ? m1.haddr     : 32'h0);
    assign s0.htrans    = (s0_grant_addr_phase == 0) ? m0.htrans    : ((s0_grant_addr_phase == 1) ? m1.htrans    : 2'b00);
    assign s0.hwrite    = (s0_grant_addr_phase == 0) ? m0.hwrite    : ((s0_grant_addr_phase == 1) ? m1.hwrite    : 1'b0);
    assign s0.hsize     = (s0_grant_addr_phase == 0) ? m0.hsize     : ((s0_grant_addr_phase == 1) ? m1.hsize     : 3'b0);
    assign s0.hburst    = (s0_grant_addr_phase == 0) ? m0.hburst    : ((s0_grant_addr_phase == 1) ? m1.hburst    : 3'b0);
    assign s0.hselx     = (s0_grant_addr_phase != 2);
    // S0 Data Phase
    assign s0.hwdata    = (s0_grant_data_phase == 0) ? m0.hwdata    : ((s0_grant_data_phase == 1) ? m1.hwdata    : 32'h0);

    // S1
    assign s1.haddr     = (s1_grant_addr_phase == 0) ? m0.haddr     : ((s1_grant_addr_phase == 1) ? m1.haddr     : 32'h0);
    assign s1.htrans    = (s1_grant_addr_phase == 0) ? m0.htrans    : ((s1_grant_addr_phase == 1) ? m1.htrans    : 2'b00);
    assign s1.hwrite    = (s1_grant_addr_phase == 0) ? m0.hwrite    : ((s1_grant_addr_phase == 1) ? m1.hwrite    : 1'b0);
    assign s1.hsize     = (s1_grant_addr_phase == 0) ? m0.hsize     : ((s1_grant_addr_phase == 1) ? m1.hsize     : 3'b0);
    assign s1.hburst    = (s1_grant_addr_phase == 0) ? m0.hburst    : ((s1_grant_addr_phase == 1) ? m1.hburst    : 3'b0);
    assign s1.hselx     = (s1_grant_addr_phase != 2);
    // S1 Data Phase
    assign s1.hwdata    = (s1_grant_data_phase == 0) ? m0.hwdata    : ((s1_grant_data_phase == 1) ? m1.hwdata    : 32'h0);


    // Route slave's own readyout back to its ready input (Simple isolated mode)
    assign s0.hready = s0.hreadyout;
    assign s1.hready = s1.hreadyout;

    // 4. Demux (Slave -> Master Data Phase)
    // M0
    assign m0.hrdata = (s0_grant_data_phase == 0) ? s0.hrdata : 
                       (s1_grant_data_phase == 0) ? s1.hrdata : 32'h0;
    assign m0.hresp  = (s0_grant_data_phase == 0) ? s0.hresp : 
                       (s1_grant_data_phase == 0) ? s1.hresp : 1'b0;
    
    // M1
    assign m1.hrdata = (s0_grant_data_phase == 1) ? s0.hrdata : 
                       (s1_grant_data_phase == 1) ? s1.hrdata : 32'h0;
    assign m1.hresp  = (s0_grant_data_phase == 1) ? s0.hresp : 
                       (s1_grant_data_phase == 1) ? s1.hresp : 1'b0;

    // HREADY Routing logic is tricky!
    // A master is ready if the slave it's currently talking to (in data phase) is ready,
    // AND if it is requesting a new slave, it has been granted the address phase.
    logic m0_ready_from_slave, m1_ready_from_slave;
    
    assign m0_ready_from_slave = (s0_grant_data_phase == 0) ? s0.hreadyout : 
                                 (s1_grant_data_phase == 0) ? s1.hreadyout : 1'b1;
                                 
    assign m1_ready_from_slave = (s0_grant_data_phase == 1) ? s0.hreadyout : 
                                 (s1_grant_data_phase == 1) ? s1.hreadyout : 1'b1;

    // Stall a master if it is requesting a slave but wasn't granted the address phase
    logic m0_stall_addr, m1_stall_addr;
    assign m0_stall_addr = (m0_req_s0 && s0_grant_addr_phase != 0) || (m0_req_s1 && s1_grant_addr_phase != 0);
    assign m1_stall_addr = (m1_req_s0 && s0_grant_addr_phase != 1) || (m1_req_s1 && s1_grant_addr_phase != 1);

    logic m0_addr_phase_ready, m1_addr_phase_ready;
    assign m0_addr_phase_ready = (s0_grant_addr_phase == 0) ? s0.hreadyout : (s1_grant_addr_phase == 0) ? s1.hreadyout : 1'b1;
    assign m1_addr_phase_ready = (s0_grant_addr_phase == 1) ? s0.hreadyout : (s1_grant_addr_phase == 1) ? s1.hreadyout : 1'b1;

    assign m0.hready = m0_ready_from_slave & m0_addr_phase_ready & !m0_stall_addr;
    assign m1.hready = m1_ready_from_slave & m1_addr_phase_ready & !m1_stall_addr;

endmodule

`endif // FPT_AHB_DUMMY_INTERCONNECT_SV
