`ifndef FPT_AHB_MASTER_DRIVER_SVH
`define FPT_AHB_MASTER_DRIVER_SVH

class fpt_ahb_master_driver extends uvm_driver #(fpt_ahb_master_transaction);
    `uvm_component_utils(fpt_ahb_master_driver)

    fpt_ahb_master_agent_cfg cfg;
    typedef struct {
        fpt_ahb_master_transaction req;
        int unsigned beat_index;
    } pipeline_item_t;
    pipeline_item_t pipeline_q[$];

    extern function new(string name = "fpt_ahb_master_driver", uvm_component parent = null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
    extern virtual task reset_signals();
    extern virtual task address_phase_thread();
    extern virtual task data_phase_thread();
endclass

function fpt_ahb_master_driver::new(string name = "fpt_ahb_master_driver", uvm_component parent = null);
    super.new(name, parent);
endfunction

function void fpt_ahb_master_driver::build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (cfg == null) begin
        if (!uvm_config_db#(fpt_ahb_master_agent_cfg)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal("NO_CFG", {"Configuration must be set for: ", get_full_name(), ".cfg"})
        end
    end
endfunction

task fpt_ahb_master_driver::run_phase(uvm_phase phase);
    reset_signals();
    fork
        address_phase_thread();
        data_phase_thread();
    join_none
endtask

task fpt_ahb_master_driver::reset_signals();
    wait (cfg.vif.hresetn === 1'b0);
    cfg.vif.cb_master.htrans <= FPT_AHB_IDLE;
    pipeline_q.delete();
    wait (cfg.vif.hresetn === 1'b1);
endtask

task fpt_ahb_master_driver::address_phase_thread();
    fpt_ahb_master_transaction req;
    bit [`FPT_AHB_VIP_ADDR_WIDTH-1:0] current_haddr;
    pipeline_item_t p_item;

    forever begin
        @(cfg.vif.cb_master);
        if (cfg.vif.cb_master.hready === 1'b0) continue;

        seq_item_port.try_next_item(req);

        if (req != null) begin
            if (req.master_delay > 0) begin
                repeat (req.master_delay) begin
                    cfg.vif.cb_master.htrans <= FPT_AHB_IDLE;
                    @(cfg.vif.cb_master);
                    while (cfg.vif.cb_master.hready === 1'b0) @(cfg.vif.cb_master);
                end
            end
            
            current_haddr = req.addr;

            for (int i = 0; i < req.num_beats; i++) begin
                cfg.vif.cb_master.haddr  <= current_haddr;
                cfg.vif.cb_master.hwrite <= (req.direction == FPT_AHB_WRITE) ? 1'b1 : 1'b0;
                cfg.vif.cb_master.hsize  <= req.size;
                cfg.vif.cb_master.hburst <= req.burst;
                cfg.vif.cb_master.hprot  <= 4'b0011;
                
                // BUSY injection for beats > 0 (inside burst)
                if (i > 0 && cfg.wait_mode == FPT_AHB_RANDOM_WAIT) begin
                    int busy_cycles = $urandom_range(0, cfg.max_delay);
                    if (busy_cycles > 0) begin
                        repeat (busy_cycles) begin
                            cfg.vif.cb_master.haddr  <= current_haddr;
                            cfg.vif.cb_master.hwrite <= (req.direction == FPT_AHB_WRITE) ? 1'b1 : 1'b0;
                            cfg.vif.cb_master.hsize  <= req.size;
                            cfg.vif.cb_master.hburst <= req.burst;
                            cfg.vif.cb_master.hprot  <= 4'b0011;
                            cfg.vif.cb_master.htrans <= FPT_AHB_BUSY;
                            @(cfg.vif.cb_master);
                            while (cfg.vif.cb_master.hready === 1'b0) @(cfg.vif.cb_master);
                        end
                    end
                end

                // Now drive the actual NONSEQ/SEQ beat
                cfg.vif.cb_master.haddr  <= current_haddr;
                cfg.vif.cb_master.hwrite <= (req.direction == FPT_AHB_WRITE) ? 1'b1 : 1'b0;
                cfg.vif.cb_master.hsize  <= req.size;
                cfg.vif.cb_master.hburst <= req.burst;
                cfg.vif.cb_master.hprot  <= 4'b0011;
                if (i == 0) cfg.vif.cb_master.htrans <= FPT_AHB_NONSEQ;
                else        cfg.vif.cb_master.htrans <= FPT_AHB_SEQ;
                
                p_item.req = req;
                p_item.beat_index = i;
                pipeline_q.push_back(p_item);

                // Only wait for next clock if there are more beats to drive in THIS burst!
                // For the last beat, we let the outer forever loop's @(cb_master) advance time
                // so we can seamlessly transition to the next transaction or IDLE.
                if (i < req.num_beats - 1) begin
                    @(cfg.vif.cb_master);
                    while (cfg.vif.cb_master.hready === 1'b0) begin
                        @(cfg.vif.cb_master);
                    end
                    current_haddr = fpt_ahb_utilities::get_next_beat_addr(current_haddr, req.size, req.burst, req.num_beats);
                end
            end
            
            seq_item_port.item_done();
        end else begin
            cfg.vif.cb_master.htrans <= FPT_AHB_IDLE;
        end
    end
endtask

task fpt_ahb_master_driver::data_phase_thread();
    pipeline_item_t current_item;
    fpt_ahb_master_transaction current_tx;
    int beat_idx;
    int timeout_cnt;

    forever begin
        if (pipeline_q.size() == 0) begin
            wait (pipeline_q.size() > 0);
            current_item = pipeline_q.pop_front();
            @(cfg.vif.cb_master);
            while (cfg.vif.cb_master.hready === 1'b0) @(cfg.vif.cb_master);
        end else begin
            current_item = pipeline_q.pop_front();
        end

        current_tx = current_item.req;
        beat_idx   = current_item.beat_index;

        timeout_cnt = 0;

        // --- Data Phase ---
        if (current_tx.direction == FPT_AHB_WRITE) begin
            cfg.vif.cb_master.hwdata <= current_tx.write_data[beat_idx];
        end

        do begin
            @(cfg.vif.cb_master);
            if (cfg.vif.cb_master.hready === 1'b0) begin
                timeout_cnt++;
                if (timeout_cnt >= cfg.wait_timeout_cycles) begin
                    `uvm_error("DRV_TIMEOUT", "Slave Timeout! hready stuck at 0")
                    break;
                end
            end
        end while (cfg.vif.cb_master.hready === 1'b0);

        if (current_tx.direction == FPT_AHB_READ) begin
            if (current_tx.read_data.size() != current_tx.num_beats) begin
                current_tx.read_data = new[current_tx.num_beats];
            end
            current_tx.read_data[beat_idx] = cfg.vif.cb_master.hrdata;
        end
        
        // Finalize transaction only on the last beat
        if (beat_idx == current_tx.num_beats - 1) begin
            current_tx.response = (cfg.vif.cb_master.hresp == 1'b1) ? FPT_AHB_ERROR : FPT_AHB_OKAY;
            seq_item_port.put_response(current_tx);
        end
    end
endtask

`endif // FPT_AHB_MASTER_DRIVER_SVH
