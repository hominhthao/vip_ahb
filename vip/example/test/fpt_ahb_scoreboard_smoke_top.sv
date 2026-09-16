`ifndef FPT_AHB_SCOREBOARD_SMOKE_TOP_SV
`define FPT_AHB_SCOREBOARD_SMOKE_TOP_SV

`include "uvm_macros.svh"

module fpt_ahb_scoreboard_smoke_top;
    import uvm_pkg::*;
    import fpt_ahb_package::*;
    import fpt_ahb_example_package::*;

    class fpt_ahb_scoreboard_expected_error_catcher extends uvm_report_catcher;
        int unsigned caught_count;

        extern virtual function action_e catch();
    endclass

    function action_e fpt_ahb_scoreboard_expected_error_catcher::catch();
        if (get_severity() == UVM_ERROR && (get_id() == "FPT_AHB_CHK" || get_id() == "FPT_AHB_SCB")) begin
            caught_count++;
            set_severity(UVM_INFO);
        end
        return THROW;
    endfunction

    class fpt_ahb_scoreboard_smoke_test extends uvm_test;
        `uvm_component_utils(fpt_ahb_scoreboard_smoke_test)

        fpt_ahb_system_checker system_checker;
        fpt_ahb_predictor predictor;
        fpt_ahb_scoreboard_expected_error_catcher error_catcher;

        extern function new(string name = "fpt_ahb_scoreboard_smoke_test",
                            uvm_component parent = null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task run_phase(uvm_phase phase);
    extern task submit_pair(
                            fpt_ahb_beat_transaction master_tx,
                            fpt_ahb_beat_transaction slave_tx,
                            input bit expect_match,
                            input string label
                            );
    extern function fpt_ahb_beat_transaction make_master(
                                                           input bit [`FPT_AHB_VIP_ADDR_WIDTH-1:0]   addr,
                                                           input                                     fpt_ahb_direction_e direction,
                                                           input bit [`FPT_AHB_VIP_DATA_WIDTH-1:0]   write_data,
                                                           input logic [`FPT_AHB_VIP_DATA_WIDTH-1:0] read_data,
                                                           input                                     fpt_ahb_response_e response
                                                           );
    extern function fpt_ahb_beat_transaction make_slave(
                                                         input bit [`FPT_AHB_VIP_ADDR_WIDTH-1:0] addr,
                                                         input                                   fpt_ahb_direction_e direction,
                                                         input bit [`FPT_AHB_VIP_DATA_WIDTH-1:0] write_data,
                                                         input bit [`FPT_AHB_VIP_DATA_WIDTH-1:0] read_data,
                                                         input                                   fpt_ahb_response_e response
                                                         );
endclass

    function fpt_ahb_scoreboard_smoke_test::new(
                                                string name = "fpt_ahb_scoreboard_smoke_test",
                                                uvm_component parent = null
                                                );
        super.new(name, parent);
    endfunction : new

    function void fpt_ahb_scoreboard_smoke_test::build_phase(uvm_phase phase);
        super.build_phase(phase);
        system_checker = fpt_ahb_system_checker::type_id::create("system_checker", this);
        predictor = fpt_ahb_predictor::type_id::create("predictor", this);
        predictor.expected_ap.connect(system_checker.expected_fifo.analysis_export);
        error_catcher = new();
        uvm_report_cb::add(system_checker, error_catcher);
    endfunction : build_phase

    function fpt_ahb_beat_transaction fpt_ahb_scoreboard_smoke_test::make_master(
                                                                                   input bit [`FPT_AHB_VIP_ADDR_WIDTH-1:0]   addr,
                                                                                   input                                     fpt_ahb_direction_e direction,
                                                                                   input bit [`FPT_AHB_VIP_DATA_WIDTH-1:0]   write_data,
                                                                                   input logic [`FPT_AHB_VIP_DATA_WIDTH-1:0] read_data,
                                                                                   input                                     fpt_ahb_response_e response
                                                                                   );
        fpt_ahb_beat_transaction tx;

        tx = fpt_ahb_beat_transaction::type_id::create("master_observation");
        tx.addr = addr;
        tx.direction = direction;
        tx.write_data = write_data;
        tx.read_data = read_data;
        tx.size = FPT_AHB_WORD;
        tx.burst = FPT_AHB_SINGLE;
        tx.trans = FPT_AHB_NONSEQ;
        tx.response = response;
        return tx;
    endfunction : make_master

    function fpt_ahb_beat_transaction fpt_ahb_scoreboard_smoke_test::make_slave(
                                                                                 input bit [`FPT_AHB_VIP_ADDR_WIDTH-1:0] addr,
                                                                                 input                                   fpt_ahb_direction_e direction,
                                                                                 input bit [`FPT_AHB_VIP_DATA_WIDTH-1:0] write_data,
                                                                                 input bit [`FPT_AHB_VIP_DATA_WIDTH-1:0] read_data,
                                                                                 input                                   fpt_ahb_response_e response
                                                                                 );
        fpt_ahb_beat_transaction tx;

        tx = fpt_ahb_beat_transaction::type_id::create("slave_observation");
        tx.addr = addr;
        tx.direction = direction;
        tx.write_data = write_data;
        tx.read_data = read_data;
        tx.size = FPT_AHB_WORD;
        tx.burst = FPT_AHB_SINGLE;
        tx.trans = FPT_AHB_NONSEQ;
        tx.response = response;
        tx.wait_cycles = 0;
        return tx;
    endfunction : make_slave

    task fpt_ahb_scoreboard_smoke_test::submit_pair(
                                                    fpt_ahb_beat_transaction master_tx,
                                                    fpt_ahb_beat_transaction slave_tx,
                                                    input bit expect_match,
                                                    input string label
                                                    );
        int unsigned checked_before;
        int unsigned mismatch_before;

        checked_before = system_checker.checked_count;
        mismatch_before = system_checker.mismatch_count;
        predictor.write(master_tx);
        system_checker.master_fifo.write(master_tx);
        system_checker.slave_fifo.write(slave_tx);
        wait (system_checker.checked_count == checked_before + 1);

        if (expect_match && system_checker.mismatch_count != mismatch_before)
            $fatal(1, "%s unexpectedly mismatched", label);
        if (!expect_match && system_checker.mismatch_count == mismatch_before)
            $fatal(1, "%s did not detect the expected mismatch", label);
        $display("PASS: %s", label);
    endtask : submit_pair

    task fpt_ahb_scoreboard_smoke_test::run_phase(uvm_phase phase);
        fpt_ahb_beat_transaction master_tx;
        fpt_ahb_beat_transaction slave_tx;
        fpt_ahb_common_memory common_memory;

        phase.raise_objection(this);
        system_checker.expected_count = 14;

        // A different common-memory value must not influence the Scoreboard.
        common_memory = fpt_ahb_common_memory::type_id::create("common_memory");
        common_memory.write('h300, 'hDEAD_BEEF);
        master_tx = make_master('h300, FPT_AHB_READ, '0, '0, FPT_AHB_OKAY);
        slave_tx = make_slave('h300, FPT_AHB_READ, '0, '0, FPT_AHB_OKAY);
        submit_pair(master_tx, slave_tx, 1'b1,
                    "unwritten READ expects zero independently of common memory");

        master_tx = make_master('h100, FPT_AHB_WRITE, 'h1111_2222, '0,
                                FPT_AHB_OKAY);
        slave_tx = make_slave('h100, FPT_AHB_WRITE, 'h1111_2222, '0,
                              FPT_AHB_OKAY);
        submit_pair(master_tx, slave_tx, 1'b1, "successful WRITE A");

        master_tx = make_master('h200, FPT_AHB_WRITE, 'h3333_4444, '0,
                                FPT_AHB_OKAY);
        slave_tx = make_slave('h200, FPT_AHB_WRITE, 'h3333_4444, '0,
                              FPT_AHB_OKAY);
        submit_pair(master_tx, slave_tx, 1'b1, "successful WRITE B");

        master_tx = make_master('h200, FPT_AHB_READ, '0, 'h3333_4444,
                                FPT_AHB_OKAY);
        slave_tx = make_slave('h200, FPT_AHB_READ, '0, 'h3333_4444,
                              FPT_AHB_OKAY);
        submit_pair(master_tx, slave_tx, 1'b1, "reverse-order READ B");

        master_tx = make_master('h100, FPT_AHB_READ, '0, 'h1111_2222,
                                FPT_AHB_OKAY);
        slave_tx = make_slave('h100, FPT_AHB_READ, '0, 'h1111_2222,
                              FPT_AHB_OKAY);
        submit_pair(master_tx, slave_tx, 1'b1, "reverse-order READ A");

        master_tx = make_master('h100, FPT_AHB_WRITE, 'h5555_6666, '0,
                                FPT_AHB_OKAY);
        slave_tx = make_slave('h100, FPT_AHB_WRITE, 'h5555_6666, '0,
                              FPT_AHB_OKAY);
        submit_pair(master_tx, slave_tx, 1'b1, "overwrite A");

        master_tx = make_master('h100, FPT_AHB_READ, '0, 'h5555_6666,
                                FPT_AHB_OKAY);
        slave_tx = make_slave('h100, FPT_AHB_READ, '0, 'h5555_6666,
                              FPT_AHB_OKAY);
        submit_pair(master_tx, slave_tx, 1'b1, "READ overwritten A");

        master_tx = make_master('h400, FPT_AHB_WRITE, 'h7777_8888, '0,
                                FPT_AHB_ERROR);
        slave_tx = make_slave('h400, FPT_AHB_WRITE, 'h7777_8888, '0,
                              FPT_AHB_ERROR);
        submit_pair(master_tx, slave_tx, 1'b1, "ERROR WRITE does not update model");

        master_tx = make_master('h400, FPT_AHB_READ, '0, '0, FPT_AHB_OKAY);
        slave_tx = make_slave('h400, FPT_AHB_READ, '0, '0, FPT_AHB_OKAY);
        submit_pair(master_tx, slave_tx, 1'b1, "READ after ERROR WRITE remains zero");

        master_tx = make_master('h500, FPT_AHB_READ, '0, 'hAAAA_AAAA,
                                FPT_AHB_ERROR);
        slave_tx = make_slave('h500, FPT_AHB_READ, '0, 'hBBBB_BBBB,
                              FPT_AHB_ERROR);
        submit_pair(master_tx, slave_tx, 1'b1, "ERROR READ ignores data");

        master_tx = make_master('h600, FPT_AHB_WRITE, 'h1234_5678, '0,
                                FPT_AHB_OKAY);
        slave_tx = make_slave('h604, FPT_AHB_WRITE, 'h1234_5678, '0,
                              FPT_AHB_OKAY);
        submit_pair(master_tx, slave_tx, 1'b0, "address mismatch detection");

        master_tx = make_master('h700, FPT_AHB_WRITE, 'h1234_5678, '0,
                                FPT_AHB_OKAY);
        slave_tx = make_slave('h700, FPT_AHB_WRITE, 'h8765_4321, '0,
                              FPT_AHB_OKAY);
        submit_pair(master_tx, slave_tx, 1'b0, "write-data mismatch detection");

        master_tx = make_master('h100, FPT_AHB_READ, '0, 'hBAD0_BAD0,
                                FPT_AHB_OKAY);
        slave_tx = make_slave('h100, FPT_AHB_READ, '0, 'hBAD0_BAD0,
                              FPT_AHB_OKAY);
        submit_pair(master_tx, slave_tx, 1'b0, "reference read mismatch detection");

        master_tx = make_master('h800, FPT_AHB_READ, '0, '0, FPT_AHB_OKAY);
        slave_tx = make_slave('h800, FPT_AHB_READ, '0, '0, FPT_AHB_ERROR);
        submit_pair(master_tx, slave_tx, 1'b0, "response mismatch detection");

        if (error_catcher.caught_count != system_checker.mismatch_count)
            $fatal(1, "Expected mismatch catcher count mismatch");
        if (system_checker.checked_count != 14 || system_checker.passed_count != 10)
            $fatal(1, "Scoreboard count mismatch: checked=%0d passed=%0d mismatches=%0d",
                   system_checker.checked_count, system_checker.passed_count,
                   system_checker.mismatch_count);

        $display("PASS: scoreboard smoke test (checked=%0d passed=%0d mismatches=%0d)",
                 system_checker.checked_count, system_checker.passed_count,
                 system_checker.mismatch_count);
        $display("PASS: system_checker smoke test (checked=%0d passed=%0d mismatches=%0d)",
                 system_checker.checked_count, system_checker.passed_count,
                 system_checker.mismatch_count);
        phase.drop_objection(this);
    endtask : run_phase

    initial begin
        run_test("fpt_ahb_scoreboard_smoke_test");
    end
endmodule : fpt_ahb_scoreboard_smoke_top

`endif // FPT_AHB_SCOREBOARD_SMOKE_TOP_SV
