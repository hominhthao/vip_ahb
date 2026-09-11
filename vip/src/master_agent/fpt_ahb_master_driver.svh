`ifndef FPT_AHB_MASTER_DRIVER_SVH
`define FPT_AHB_MASTER_DRIVER_SVH

class fpt_ahb_master_driver extends uvm_driver #(fpt_ahb_master_transaction);
    `uvm_component_utils(fpt_ahb_master_driver)

    fpt_ahb_master_agent_cfg cfg;
    fpt_ahb_master_transaction pipeline_q[$];

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
    cfg.vif.cb_master.htrans <= 2'b00;
    cfg.vif.cb_master.hselx  <= 0;
    pipeline_q.delete();
    wait (cfg.vif.hresetn === 1'b1);
endtask

task fpt_ahb_master_driver::address_phase_thread();
    fpt_ahb_master_transaction req;

    forever begin
        @(cfg.vif.cb_master);
        if (cfg.vif.cb_master.hready === 1'b0) continue;

        seq_item_port.try_next_item(req);

        if (req != null) begin
            cfg.vif.cb_master.haddr  <= req.addr;
            cfg.vif.cb_master.hwrite <= (req.direction == FPT_AHB_WRITE) ? 1'b1 : 1'b0;
            cfg.vif.cb_master.hsize  <= req.size;
            cfg.vif.cb_master.hburst <= req.burst;
            cfg.vif.cb_master.hprot  <= 4'b0011;
            cfg.vif.cb_master.htrans <= 2'b10;
            cfg.vif.cb_master.hselx  <= 1'b1;

            pipeline_q.push_back(req);
            seq_item_port.item_done();
        end else begin
            cfg.vif.cb_master.htrans <= 2'b00;
            cfg.vif.cb_master.hselx  <= 1'b0;
        end
    end
endtask

task fpt_ahb_master_driver::data_phase_thread();
    fpt_ahb_master_transaction current_tx;
    int timeout_cnt;

    forever begin
        wait (pipeline_q.size() > 0);
        current_tx = pipeline_q.pop_front();
        timeout_cnt = 0;

        // BẮT BUỘC: Phải đợi 1 chu kỳ để Pha Địa Chỉ kết thúc trên Bus,
        // vì Address mới chỉ được chích lên ở ngay delta cycle hiện tại!
        @(cfg.vif.cb_master);
        while (cfg.vif.cb_master.hready === 1'b0) @(cfg.vif.cb_master);

        // --- Bắt đầu Data Phase ---
        if (current_tx.direction == FPT_AHB_WRITE) begin
            cfg.vif.cb_master.hwdata <= current_tx.write_data;
        end

        // Chờ Slave phản hồi Data Phase
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
            current_tx.read_data = cfg.vif.cb_master.hrdata;
        end
        current_tx.response = (cfg.vif.cb_master.hresp == 1'b1) ? FPT_AHB_ERROR : FPT_AHB_OKAY;

        seq_item_port.put_response(current_tx);
    end
endtask

`endif // FPT_AHB_MASTER_DRIVER_SVH
