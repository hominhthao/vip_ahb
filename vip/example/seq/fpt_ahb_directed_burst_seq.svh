`ifndef FPT_AHB_DIRECTED_BURST_SEQ_SVH
`define FPT_AHB_DIRECTED_BURST_SEQ_SVH

class fpt_ahb_directed_burst_seq extends fpt_ahb_master_base_seq;
    `uvm_object_utils(fpt_ahb_directed_burst_seq)
    
    rand int num_trans;
    rand fpt_ahb_burst_e burst_types[];
    
    int unsigned total_beats = 0;
    int unsigned responses_received = 0;
    
    constraint c_num_trans {
        num_trans inside {[10:20]};
        burst_types.size() == num_trans;
    }
    
    constraint c_burst_types {
        foreach(burst_types[i]) {
            burst_types[i] inside {FPT_AHB_INCR4, FPT_AHB_WRAP4, 
                                   FPT_AHB_INCR8, FPT_AHB_WRAP8,
                                   FPT_AHB_INCR16, FPT_AHB_WRAP16, FPT_AHB_INCR};
        }
    }

    extern function new(string name = "fpt_ahb_directed_burst_seq");
    extern function void post_randomize();
    extern virtual task body();
    extern virtual function void process_response(fpt_ahb_master_transaction rsp);
endclass

function fpt_ahb_directed_burst_seq::new(string name = "fpt_ahb_directed_burst_seq");
    super.new(name);
endfunction

function void fpt_ahb_directed_burst_seq::post_randomize();
    total_beats = 0;
    foreach(burst_types[i]) begin
        if (burst_types[i] inside {FPT_AHB_INCR4, FPT_AHB_WRAP4}) total_beats += 4;
        else if (burst_types[i] inside {FPT_AHB_INCR8, FPT_AHB_WRAP8}) total_beats += 8;
        else if (burst_types[i] inside {FPT_AHB_INCR16, FPT_AHB_WRAP16}) total_beats += 16;
        else total_beats += 1;
    end
endfunction

function void fpt_ahb_directed_burst_seq::process_response(fpt_ahb_master_transaction rsp);
    responses_received++;
    `uvm_info("SEQ_BURST", $sformatf("Completed Burst %s to addr 'h%0h (response=%s)", 
                                     rsp.burst.name(), rsp.addr, rsp.response.name()), UVM_HIGH)
endfunction

task fpt_ahb_directed_burst_seq::body();
    fpt_ahb_master_transaction req;

    `uvm_info("SEQ", $sformatf("Starting Directed Burst Sequence with %0d bursts (%0d beats)...", num_trans, total_beats), UVM_NONE)

    for (int i = 0; i < num_trans; i++) begin
        req = fpt_ahb_master_transaction::type_id::create("req");
        
        req.c_v0_0_transfer.constraint_mode(0);

        start_item(req);
        if (!req.randomize() with {
            burst == burst_types[i];
            if (burst == FPT_AHB_INCR) num_beats inside {[2:10]};
            size  == FPT_AHB_WORD;
            addr >= 32'h0000_0000; addr <= 32'h0000_1F00;
        }) begin
            `uvm_error("SEQ", "Randomize failed")
        end

        // Ensure write data is sized correctly for the burst length
        req.write_data = new[req.num_beats];
        foreach(req.write_data[j]) req.write_data[j] = $urandom();

        `uvm_info("SEQ", $sformatf("Driving %s, Addr: 0x%0h, Beats: %0d", 
                                   req.burst.name(), req.addr, req.num_beats), UVM_LOW)
        finish_item(req);
    end
    
    // Wait for the pipeline to drain before ending sequence
    wait(responses_received == num_trans);
endtask

`endif // FPT_AHB_DIRECTED_BURST_SEQ_SVH
