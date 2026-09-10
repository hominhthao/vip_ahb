`ifndef FPT_AHB_SCOREBOARD_SVH
`define FPT_AHB_SCOREBOARD_SVH

// Checks completed bus observations from both Monitors against an independent
// model. The Slave input is observed bus behavior, not the Driver response plan.
class fpt_ahb_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(fpt_ahb_scoreboard)

    typedef bit [`FPT_AHB_VIP_ADDR_WIDTH-1:0] addr_t;
    typedef bit [`FPT_AHB_VIP_DATA_WIDTH-1:0] data_t;

    uvm_tlm_analysis_fifo #(fpt_ahb_master_transaction) master_fifo;
    uvm_tlm_analysis_fifo #(fpt_ahb_slave_transaction) slave_fifo;

    // This expected state is intentionally independent of common memory.
    data_t reference_memory[addr_t];
    int unsigned checked_count;
    int unsigned passed_count;
    int unsigned mismatch_count;
    bit waiting_for_slave;

    extern function new(string name = "fpt_ahb_scoreboard",
                        uvm_component parent = null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
    extern virtual function void check_phase(uvm_phase phase);
    extern function void check_transfer(
        fpt_ahb_master_transaction master_tx,
        fpt_ahb_slave_transaction slave_tx
    );
    extern function void report_mismatch(string message);
endclass : fpt_ahb_scoreboard

function fpt_ahb_scoreboard::new(string name = "fpt_ahb_scoreboard",
                                 uvm_component parent = null);
    super.new(name, parent);
endfunction : new

function void fpt_ahb_scoreboard::build_phase(uvm_phase phase);
    super.build_phase(phase);
    master_fifo = new("master_fifo", this);
    slave_fifo = new("slave_fifo", this);
endfunction : build_phase

task fpt_ahb_scoreboard::run_phase(uvm_phase phase);
    fpt_ahb_master_transaction master_tx;
    fpt_ahb_slave_transaction slave_tx;

    forever begin
        // v0.0 has one in-order Master and one in-order Slave.
        master_fifo.get(master_tx);
        waiting_for_slave = 1'b1;
        slave_fifo.get(slave_tx);
        waiting_for_slave = 1'b0;
        check_transfer(master_tx, slave_tx);
    end
endtask : run_phase

function void fpt_ahb_scoreboard::check_transfer(
    fpt_ahb_master_transaction master_tx,
    fpt_ahb_slave_transaction slave_tx
);
    int unsigned mismatch_count_before;
    bit request_matches;
    data_t expected_data;

    mismatch_count_before = mismatch_count;
    request_matches = 1'b1;

    if (master_tx == null || slave_tx == null) begin
        report_mismatch("Received a null transaction");
        checked_count++;
        return;
    end

    if (master_tx.addr !== slave_tx.addr) begin
        report_mismatch($sformatf("Address mismatch: master=0x%0h slave=0x%0h",
                                  master_tx.addr, slave_tx.addr));
        request_matches = 1'b0;
    end
    if (master_tx.direction !== slave_tx.direction) begin
        report_mismatch($sformatf("Direction mismatch: master=%s slave=%s",
                                  master_tx.direction.name(), slave_tx.direction.name()));
        request_matches = 1'b0;
    end
    if (master_tx.size !== slave_tx.size) begin
        report_mismatch($sformatf("Size mismatch: master=%0b slave=%0b",
                                  master_tx.size, slave_tx.size));
        request_matches = 1'b0;
    end
    if (master_tx.burst !== slave_tx.burst) begin
        report_mismatch($sformatf("Burst mismatch: master=%0b slave=%0b",
                                  master_tx.burst, slave_tx.burst));
        request_matches = 1'b0;
    end
    if (master_tx.direction == FPT_AHB_WRITE &&
        slave_tx.direction == FPT_AHB_WRITE &&
        master_tx.write_data !== slave_tx.write_data) begin
        report_mismatch($sformatf("Write data mismatch at 0x%0h: master=0x%0h slave=0x%0h",
                                  master_tx.addr, master_tx.write_data,
                                  slave_tx.write_data));
        request_matches = 1'b0;
    end

    if (master_tx.response !== slave_tx.response)
        report_mismatch($sformatf("Response mismatch at 0x%0h: master=%0b slave=%0b",
                                  master_tx.addr, master_tx.response,
                                  slave_tx.response));

    if (request_matches &&
        master_tx.response === FPT_AHB_OKAY &&
        slave_tx.response === FPT_AHB_OKAY) begin
        if (master_tx.direction == FPT_AHB_WRITE) begin
            reference_memory[master_tx.addr] = master_tx.write_data;
        end else if (master_tx.direction == FPT_AHB_READ) begin
            if (reference_memory.exists(master_tx.addr))
                expected_data = reference_memory[master_tx.addr];
            else
                expected_data = '0;

            if (master_tx.read_data !== slave_tx.read_data)
                report_mismatch($sformatf(
                    "Observed read data mismatch at 0x%0h: master=0x%0h slave=0x%0h",
                    master_tx.addr, master_tx.read_data, slave_tx.read_data));
            if (master_tx.read_data !== expected_data)
                report_mismatch($sformatf(
                    "Master read mismatch at 0x%0h: expected=0x%0h actual=0x%0h",
                    master_tx.addr, expected_data, master_tx.read_data));
            if (slave_tx.read_data !== expected_data)
                report_mismatch($sformatf(
                    "Slave read mismatch at 0x%0h: expected=0x%0h actual=0x%0h",
                    master_tx.addr, expected_data, slave_tx.read_data));
        end
    end

    checked_count++;
    if (mismatch_count == mismatch_count_before) begin
        passed_count++;
        `uvm_info("FPT_AHB_SCB_PASS",
                  $sformatf("Checked %s transfer at 0x%0h",
                            master_tx.direction.name(), master_tx.addr), UVM_HIGH)
    end
endfunction : check_transfer

function void fpt_ahb_scoreboard::report_mismatch(string message);
    mismatch_count++;
    `uvm_error("FPT_AHB_SCB", message)
endfunction : report_mismatch

function void fpt_ahb_scoreboard::check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (waiting_for_slave || master_fifo.used() != 0 || slave_fifo.used() != 0)
        `uvm_error("FPT_AHB_SCB_PENDING",
                   $sformatf(
                       "Unpaired observations remain: waiting_for_slave=%0b master=%0d slave=%0d",
                       waiting_for_slave, master_fifo.used(), slave_fifo.used()))
endfunction : check_phase

`endif
