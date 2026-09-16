`ifndef FPT_AHB_SYSTEM_CHECKER_SVH
`define FPT_AHB_SYSTEM_CHECKER_SVH

class fpt_ahb_system_checker extends uvm_scoreboard;
    `uvm_component_utils(fpt_ahb_system_checker)

    typedef bit [`FPT_AHB_VIP_ADDR_WIDTH-1:0] addr_t;
    typedef bit [`FPT_AHB_VIP_DATA_WIDTH-1:0] data_t;

    uvm_tlm_analysis_fifo #(fpt_ahb_master_transaction) master_fifo;
    uvm_tlm_analysis_fifo #(fpt_ahb_slave_transaction)  slave_fifo;
    uvm_tlm_analysis_fifo #(data_t)                     expected_fifo;

    bit has_predictor = 1;
    
    int expected_count = -1;
    int unsigned checked_count;
    int unsigned passed_count;
    int unsigned mismatch_count;
    protected bit          waiting_for_slave;

    extern function new(string name = "fpt_ahb_system_checker",
                        uvm_component parent = null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
    extern virtual function void check_phase(uvm_phase phase);
    extern virtual function void report_phase(uvm_phase phase);
    extern function void check_transfer(
                                        fpt_ahb_master_transaction master_tx,
                                        fpt_ahb_slave_transaction slave_tx,
                                        bit has_expected_data,
                                        data_t expected_data
                                        );
    extern function void report_mismatch(string message);
endclass : fpt_ahb_system_checker

//---------------
// Description: Implementation of new
//---------------
function fpt_ahb_system_checker::new(string name = "fpt_ahb_system_checker",
                                     uvm_component parent = null);
    super.new(name, parent);
endfunction : new

//---------------
// Description: Implementation of build_phase
//---------------
function void fpt_ahb_system_checker::build_phase(uvm_phase phase);
    super.build_phase(phase);
    master_fifo = new("master_fifo", this);
    slave_fifo  = new("slave_fifo", this);
    expected_fifo = new("expected_fifo", this);
endfunction : build_phase

//---------------
// Description: Implementation of run_phase
//---------------
task fpt_ahb_system_checker::run_phase(uvm_phase phase);
    fpt_ahb_master_transaction master_tx;
    fpt_ahb_slave_transaction  slave_tx;
    data_t expected_data;
    bit    has_expected_data;

    forever begin
        has_expected_data = 1'b0;
        master_fifo.get(master_tx);
        
        waiting_for_slave = 1'b1;
        slave_fifo.get(slave_tx);
        waiting_for_slave = 1'b0;
        
        if (has_predictor && master_tx != null && master_tx.direction == FPT_AHB_READ && master_tx.response === FPT_AHB_OKAY) begin
            expected_fifo.get(expected_data);
            has_expected_data = 1'b1;
        end
        
        check_transfer(master_tx, slave_tx, has_expected_data, expected_data);
    end
endtask : run_phase

//---------------
// Description: Implementation of check_transfer
//---------------
function void fpt_ahb_system_checker::check_transfer(
                                                     fpt_ahb_master_transaction master_tx,
                                                     fpt_ahb_slave_transaction slave_tx,
                                                     bit has_expected_data,
                                                     data_t expected_data
                                                     );
    int unsigned mismatch_count_before;
    bit          request_matches;

    mismatch_count_before = mismatch_count;
    request_matches = 1'b1;

    if (master_tx == null || slave_tx == null) begin
        report_mismatch("Received a null transaction");
        checked_count++;
        return;
    end

    `uvm_info("FPT_AHB_CHK_COMPARE",
              $sformatf(
                        {"BEGIN transfer #%0d\n",
                         "  MASTER: addr=0x%0h direction=%s size=%s burst=%s ",
                         "write_data=0x%0h read_data=0x%0h response=%s\n",
                         "  SLAVE : addr=0x%0h direction=%s size=%s burst=%s ",
                         "write_data=0x%0h read_data=0x%0h response=%s wait_cycles=%0d"},
                        checked_count + 1,
                        master_tx.addr, master_tx.direction.name(), master_tx.size.name(),
                        master_tx.burst.name(), master_tx.write_data, master_tx.read_data,
                        master_tx.response.name(),
                        slave_tx.addr, slave_tx.direction.name(), slave_tx.size.name(),
                        slave_tx.burst.name(), slave_tx.write_data, slave_tx.read_data,
                        slave_tx.response.name(), slave_tx.wait_cycles), UVM_LOW)

    // 1. Transaction/Bus Integrity Check
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

    if (master_tx.response !== slave_tx.response) begin
        report_mismatch($sformatf("Response mismatch at 0x%0h: master=%0b slave=%0b",
                                  master_tx.addr, master_tx.response,
                                  slave_tx.response));
        request_matches = 1'b0;
    end
    
    if (request_matches && master_tx.direction == FPT_AHB_READ && 
        master_tx.response === FPT_AHB_OKAY && slave_tx.response === FPT_AHB_OKAY) begin
        
        if (master_tx.read_data !== slave_tx.read_data) begin
            report_mismatch($sformatf("Observed read data mismatch at 0x%0h: master=0x%0h slave=0x%0h",
                                      master_tx.addr, master_tx.read_data, slave_tx.read_data));
        end

        // 2. Optional Predictor Check
        if (has_expected_data) begin
            if (master_tx.read_data !== expected_data)
                report_mismatch($sformatf("Master read mismatch at 0x%0h: expected=0x%0h actual=0x%0h",
                                          master_tx.addr, expected_data, master_tx.read_data));
            if (slave_tx.read_data !== expected_data)
                report_mismatch($sformatf("Slave read mismatch at 0x%0h: expected=0x%0h actual=0x%0h",
                                          master_tx.addr, expected_data, slave_tx.read_data));
        end
    end

    checked_count++;
    if (mismatch_count == mismatch_count_before) begin
        passed_count++;
        `uvm_info("FPT_AHB_CHK_PASS",
                  $sformatf("PASS transfer #%0d: %s addr=0x%0h",
                            checked_count, master_tx.direction.name(), master_tx.addr),
                  UVM_LOW)
    end else begin
        `uvm_info("FPT_AHB_CHK_RESULT",
                  $sformatf("FAIL transfer #%0d: %0d mismatch(es)",
                            checked_count, mismatch_count - mismatch_count_before),
                  UVM_LOW)
    end
endfunction : check_transfer

//---------------
// Description: Implementation of report_mismatch
//---------------
function void fpt_ahb_system_checker::report_mismatch(string message);
    mismatch_count++;
    `uvm_error("FPT_AHB_CHK", message)
endfunction : report_mismatch

//---------------
// Description: Implementation of check_phase
//---------------
function void fpt_ahb_system_checker::check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (expected_count < 0)
        `uvm_error("FPT_AHB_CHK_COUNT", "Expected transfer count was not configured")
    else if (checked_count != expected_count)
        `uvm_error("FPT_AHB_CHK_COUNT",
                   $sformatf("Completed transfer count mismatch: expected=%0d checked=%0d",
                             expected_count, checked_count))
    if (waiting_for_slave || master_fifo.used() != 0 || slave_fifo.used() != 0 || (has_predictor && expected_fifo.used() != 0))
        `uvm_error("FPT_AHB_CHK_PENDING",
                   $sformatf(
                             "Unpaired observations remain: waiting_for_slave=%0b master=%0d slave=%0d expected=%0d",
                             waiting_for_slave, master_fifo.used(), slave_fifo.used(), expected_fifo.used()))
endfunction : check_phase

//---------------
// Description: Implementation of report_phase
//---------------
function void fpt_ahb_system_checker::report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("FPT_AHB_CHK_SUMMARY",
              $sformatf("expected=%0d checked=%0d passed=%0d mismatches=%0d",
                        expected_count, checked_count, passed_count, mismatch_count), UVM_LOW)
endfunction : report_phase

`endif
