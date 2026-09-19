`ifndef FPT_AHB_SYSTEM_CHECKER_SVH
`define FPT_AHB_SYSTEM_CHECKER_SVH

class fpt_ahb_system_checker extends uvm_scoreboard;
    `uvm_component_utils(fpt_ahb_system_checker)

    // New Multi-Master Input Ports
    uvm_tlm_analysis_fifo #(fpt_ahb_system_transaction) sys_master_fifo;
    uvm_tlm_analysis_fifo #(fpt_ahb_system_transaction) sys_slave_fifo;
    uvm_tlm_analysis_fifo #(bit [`FPT_AHB_VIP_DATA_WIDTH-1:0]) expected_fifo;

    bit has_predictor = 1;

    typedef fpt_ahb_system_transaction sys_tr_q_t[$];
    sys_tr_q_t pending_tx_q[16];

    // Stats
    int expected_count = -1;
    int checked_count = 0;
    int mismatch_count = 0;
    int passed_count = 0;

    // Multi-Master Burst Tracking States
    fpt_ahb_burst_e active_burst[16];
    fpt_ahb_size_e active_hsize[16];
    int unsigned expected_burst_length[16];
    int unsigned current_beat_count[16];
    logic [31:0] expected_next_addr[16];

    extern function new(string name = "fpt_ahb_system_checker", uvm_component parent = null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
    extern virtual function void check_transfer(fpt_ahb_system_transaction m_tx, fpt_ahb_system_transaction s_tx, bit [`FPT_AHB_VIP_DATA_WIDTH-1:0] exp_data);
    extern virtual function void report_mismatch(string message);
    extern virtual function void report_phase(uvm_phase phase);
    extern virtual function int unsigned get_burst_length(fpt_ahb_burst_e b);
endclass

function fpt_ahb_system_checker::new(string name, uvm_component parent);
    super.new(name, parent);
    // Init states
    for (int i=0; i<16; i++) begin
        expected_burst_length[i] = 0;
        current_beat_count[i] = 0;
    end
endfunction

function void fpt_ahb_system_checker::build_phase(uvm_phase phase);
    super.build_phase(phase);
    sys_master_fifo = new("sys_master_fifo", this);
    sys_slave_fifo  = new("sys_slave_fifo", this);
    expected_fifo   = new("expected_fifo", this);
endfunction

task fpt_ahb_system_checker::run_phase(uvm_phase phase);
    fork
        // Thread 1: Nhận Master Requests và nhét vào hàng đợi
        forever begin
            fpt_ahb_system_transaction m_tx;
            sys_master_fifo.get(m_tx);
            if (m_tx.master_id >= 0 && m_tx.master_id < 16) begin
                pending_tx_q[m_tx.master_id].push_back(m_tx);
            end else begin
                `uvm_error("FPT_AHB_CHK", "Master ID out of bounds")
            end
        end

        // Thread 2: Nhận Slave Responses, Truy vết Master và Chấm điểm
        forever begin
            fpt_ahb_system_transaction s_tx;
            sys_slave_fifo.get(s_tx);
            
            fork
                automatic fpt_ahb_system_transaction s_tx_auto = s_tx;
                begin
                    bit [`FPT_AHB_VIP_DATA_WIDTH-1:0] exp_data;
                    int found_master = -1;
                    #1ps; // Đợi 1ps để đảm bảo Master request đã được push

                    for (int i=0; i<16; i++) begin
                        if (pending_tx_q[i].size() > 0) begin
                            if (pending_tx_q[i][0].slave_id == s_tx_auto.slave_id) begin
                                found_master = i;
                                break;
                            end
                        end
                    end

                    if (found_master != -1) begin
                        fpt_ahb_system_transaction m_tx = pending_tx_q[found_master].pop_front();
                        
                        if (has_predictor && m_tx.beat_tx.direction == FPT_AHB_READ && m_tx.beat_tx.response == FPT_AHB_OKAY) begin
                             expected_fifo.try_get(exp_data);
                        end

                        check_transfer(m_tx, s_tx_auto, exp_data);
                    end else begin
                        `uvm_error("FPT_AHB_CHK", $sformatf("Received response from S%0d but no Master was waiting!", s_tx_auto.slave_id))
                    end
                end
            join_none
        end
    join_none
endtask

function void fpt_ahb_system_checker::check_transfer(fpt_ahb_system_transaction m_tx, fpt_ahb_system_transaction s_tx, bit [`FPT_AHB_VIP_DATA_WIDTH-1:0] exp_data);
    fpt_ahb_beat_transaction master_tx = m_tx.beat_tx;
    fpt_ahb_beat_transaction slave_tx = s_tx.beat_tx;
    int m_id = m_tx.master_id;
    int mismatch_before = mismatch_count;

    // 1. Multi-Master Burst Protocol & Address Progression Check
    if (master_tx.trans == FPT_AHB_NONSEQ) begin
        if (expected_burst_length[m_id] > 0 && current_beat_count[m_id] > 0 && current_beat_count[m_id] != expected_burst_length[m_id]) begin
            report_mismatch($sformatf("[M%0d] Burst terminated early! Expected %0d beats, got %0d", m_id, expected_burst_length[m_id], current_beat_count[m_id]));
        end
        active_burst[m_id] = master_tx.burst;
        active_hsize[m_id] = master_tx.size;
        expected_burst_length[m_id] = get_burst_length(master_tx.burst);
        current_beat_count[m_id] = 1;
        expected_next_addr[m_id] = fpt_ahb_utilities::get_next_beat_addr(master_tx.addr, master_tx.size, master_tx.burst, expected_burst_length[m_id]);
    end else if (master_tx.trans == FPT_AHB_SEQ) begin
        if (current_beat_count[m_id] == 0) begin
            report_mismatch($sformatf("[M%0d] SEQ beat observed without a preceding NONSEQ burst start!", m_id));
        end else if (expected_burst_length[m_id] > 0 && current_beat_count[m_id] >= expected_burst_length[m_id]) begin
            report_mismatch($sformatf("[M%0d] Burst length exceeded! Expected %0d beats", m_id, expected_burst_length[m_id]));
        end
        
        if (master_tx.addr !== expected_next_addr[m_id]) begin
            report_mismatch($sformatf("[M%0d] Address progression mismatch! Expected 0x%0h but got 0x%0h", m_id, expected_next_addr[m_id], master_tx.addr));
        end
        
        current_beat_count[m_id]++;
        expected_next_addr[m_id] = fpt_ahb_utilities::get_next_beat_addr(master_tx.addr, master_tx.size, master_tx.burst, expected_burst_length[m_id]);
    end

    // 2. Transaction Integrity Check
    if (master_tx.addr !== slave_tx.addr) begin
        report_mismatch($sformatf("Address mismatch: master=0x%0h slave=0x%0h", master_tx.addr, slave_tx.addr));
    end
    if (master_tx.direction !== slave_tx.direction) begin
        report_mismatch("Direction mismatch");
    end
    if (master_tx.size !== slave_tx.size) begin
        report_mismatch("Size mismatch");
    end
    if (master_tx.burst !== slave_tx.burst) begin
        report_mismatch("Burst mismatch");
    end
    if (master_tx.direction == FPT_AHB_WRITE && master_tx.write_data !== slave_tx.write_data) begin
        report_mismatch("Write data mismatch");
    end
    if (master_tx.response !== slave_tx.response) begin
        report_mismatch("Response mismatch");
    end

    if (master_tx.direction == FPT_AHB_READ && master_tx.response == FPT_AHB_OKAY) begin
        if (master_tx.read_data !== slave_tx.read_data) begin
            report_mismatch("Read data mismatch");
        end
        if (has_predictor) begin
            if (master_tx.read_data !== exp_data) begin
                report_mismatch($sformatf("Predictor Read mismatch: expected=0x%0h actual=0x%0h", exp_data, master_tx.read_data));
            end
        end
    end

    checked_count++;
    if (mismatch_count == mismatch_before) begin
        passed_count++;
        `uvm_info("FPT_AHB_CHK_PASS", $sformatf("PASS transfer #%0d [M%0d->S%0d]: %s addr=0x%0h", checked_count, m_tx.master_id, m_tx.slave_id, master_tx.direction.name(), master_tx.addr), UVM_LOW)
    end
endfunction

function int unsigned fpt_ahb_system_checker::get_burst_length(fpt_ahb_burst_e b);
    case (b)
        FPT_AHB_SINGLE: return 1;
        FPT_AHB_INCR4, FPT_AHB_WRAP4: return 4;
        FPT_AHB_INCR8, FPT_AHB_WRAP8: return 8;
        FPT_AHB_INCR16, FPT_AHB_WRAP16: return 16;
        default: return 0; // INCR
    endcase
endfunction

function void fpt_ahb_system_checker::report_mismatch(string message);
    mismatch_count++;
    `uvm_error("FPT_AHB_CHK", message)
endfunction

function void fpt_ahb_system_checker::report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("FPT_AHB_CHK_SUMMARY", $sformatf("checked=%0d passed=%0d mismatches=%0d", checked_count, passed_count, mismatch_count), UVM_LOW)
endfunction

`endif
