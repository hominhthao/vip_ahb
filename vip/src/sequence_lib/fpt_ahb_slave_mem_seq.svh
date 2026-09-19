`ifndef FPT_AHB_SLAVE_MEM_SEQ_SVH
`define FPT_AHB_SLAVE_MEM_SEQ_SVH

class fpt_ahb_slave_mem_seq extends fpt_ahb_slave_base_seq;
    `uvm_object_utils(fpt_ahb_slave_mem_seq)

    fpt_ahb_slave_agent_cfg cfg;

    extern function new(string name = "fpt_ahb_slave_mem_seq");
    extern virtual task body();
    extern virtual function bit resolve_wait_cycles(
                                                        fpt_ahb_slave_transaction req
                                                        );
endclass

function fpt_ahb_slave_mem_seq::new(string name = "fpt_ahb_slave_mem_seq");
    super.new(name);
endfunction

function bit fpt_ahb_slave_mem_seq::resolve_wait_cycles(
                                                           fpt_ahb_slave_transaction req
                                                           );
    int unsigned resolved_wait_cycles;
    int unsigned min_wait_cycles;
    int unsigned max_wait_cycles;

    case (cfg.wait_mode)
        FPT_AHB_ZERO_WAIT: begin
            resolved_wait_cycles = 0;
        end
        FPT_AHB_FIXED_WAIT: begin
            resolved_wait_cycles = cfg.fixed_wait_cycles;
        end
        FPT_AHB_RANDOM_WAIT: begin
            min_wait_cycles = cfg.min_wait_cycles;
            max_wait_cycles = cfg.max_wait_cycles;
            if (!std::randomize(resolved_wait_cycles) with {
                    resolved_wait_cycles >= min_wait_cycles;
                    resolved_wait_cycles <= max_wait_cycles;
                }) begin
                `uvm_error("SEQ_WAIT_RAND", "WAIT-cycle randomization failed")
                return 0;
            end
        end
        default: begin
            `uvm_fatal("SEQ_WAIT_MODE", "Slave sequence received an invalid WAIT mode")
            return 0;
        end
    endcase

    req.wait_cycles = resolved_wait_cycles;
    `uvm_info("SLV_WAIT",
              $sformatf("Resolved %s to wait_cycles=%0d for addr='h%0h",
                        cfg.wait_mode.name(), req.wait_cycles, req.addr),
              UVM_HIGH)
    return 1;
endfunction : resolve_wait_cycles

task fpt_ahb_slave_mem_seq::body();
    fpt_ahb_slave_transaction req;
    bit randomize_ok;

    if (!uvm_config_db#(fpt_ahb_slave_agent_cfg)::get(m_sequencer, "", "cfg", cfg) ||
        cfg == null) begin
        `uvm_fatal("NO_CFG", "Slave response sequence requires the Slave Agent Config")
        return;
    end

    // 0. Handshake ban đầu: Ném cho Driver 1 gói tin trống để nó học được ID của Sequence này
    req = fpt_ahb_slave_transaction::type_id::create("req");
    start_item(req);
    req.c_v0_0_context.constraint_mode(0); // Tạm tắt constraint vì chưa có data
    finish_item(req);

    forever begin
        // 1. Chờ Driver báo cáo Address Phase
        get_response(req);

        // 2. Nhận lệnh, Randomize và chuẩn bị phản hồi
        start_item(req);
        req.c_v0_0_context.constraint_mode(0); // Bật constraint lại vì req đã có addr chuẩn

        // This sequence owns response selection, but Common Memory/Driver owns
        // READ data and the configured WAIT policy owns response latency.
        req.wait_cycles = 0;
        req.read_data.rand_mode(0);
        req.wait_cycles.rand_mode(0);
        randomize_ok = req.randomize();
        req.read_data.rand_mode(1);
        req.wait_cycles.rand_mode(1);
        if (!randomize_ok) begin
            `uvm_error("SEQ_RAND", "Randomization failed")
        end
        if (!resolve_wait_cycles(req)) begin
            return;
        end

        finish_item(req);

        // 3. Chờ Driver báo cáo Data Phase hoàn tất
        get_response(req);
    end
endtask

`endif // FPT_AHB_SLAVE_MEM_SEQ_SVH
