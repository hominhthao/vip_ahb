`ifndef FPT_AHB_RANDOM_RW_SEQ_SVH
`define FPT_AHB_RANDOM_RW_SEQ_SVH

class fpt_ahb_random_rw_seq extends fpt_ahb_master_base_seq;
    `uvm_object_utils(fpt_ahb_random_rw_seq)

    rand int num_trans;

    constraint c_num_trans {
        num_trans inside {[100:1000]};
    }

    extern function new(string name = "fpt_ahb_random_rw_seq");
    extern virtual task body();
    extern virtual function void process_response(fpt_ahb_master_transaction rsp);
endclass

//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
function fpt_ahb_random_rw_seq::new(string name = "fpt_ahb_random_rw_seq");
    super.new(name);
endfunction

//------------------------------------------------------------------------------
// Response Handler
//------------------------------------------------------------------------------
function void fpt_ahb_random_rw_seq::process_response(fpt_ahb_master_transaction rsp);
    if (rsp.direction == FPT_AHB_WRITE) begin
        `uvm_info("SEQ_RW", $sformatf("Wrote data 'h%0h to address 'h%0h (response=%s)", 
                                         rsp.write_data, rsp.addr, rsp.response.name()), UVM_HIGH)
    end else begin
        `uvm_info("SEQ_RW", $sformatf("Read data 'h%0h from address 'h%0h (response=%s)", 
                                         rsp.read_data, rsp.addr, rsp.response.name()), UVM_HIGH)
    end
endfunction

//------------------------------------------------------------------------------
// Body: Random R/W Transactions
//------------------------------------------------------------------------------
task fpt_ahb_random_rw_seq::body();
    fpt_ahb_master_transaction req;

    `uvm_info("SEQ", $sformatf("Starting Random R/W Sequence with %0d transactions", num_trans), UVM_NONE)

    for (int i = 0; i < num_trans; i++) begin
        req = fpt_ahb_master_transaction::type_id::create("req");
        start_item(req);
        if (!req.randomize()) begin
            `uvm_error("SEQ", "Randomize failed")
        end
        finish_item(req);
    end

    `uvm_info("SEQ", "Random R/W Sequence Completed.", UVM_LOW)
endtask

`endif // FPT_AHB_RANDOM_RW_SEQ_SVH
