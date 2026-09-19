`ifndef FPT_AHB_SINGLE_WRITE_SEQ_SVH
`define FPT_AHB_SINGLE_WRITE_SEQ_SVH

class fpt_ahb_single_write_seq extends fpt_ahb_master_base_seq;
    `uvm_object_utils(fpt_ahb_single_write_seq)

    rand int num_trans;

    constraint c_num_trans {
        num_trans inside {[100:1000]};
    }

    extern function new(string name = "fpt_ahb_single_write_seq");
    extern virtual task body();
    extern virtual function void process_response(fpt_ahb_master_transaction rsp);
endclass

//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
function fpt_ahb_single_write_seq::new(string name = "fpt_ahb_single_write_seq");
    super.new(name);
endfunction

//------------------------------------------------------------------------------
// Response Handler
//------------------------------------------------------------------------------
function void fpt_ahb_single_write_seq::process_response(fpt_ahb_master_transaction rsp);
    `uvm_info("SEQ_WRITE", $sformatf("Wrote data 'h%0h to address 'h%0h (response=%s)", 
                                     rsp.write_data[0], rsp.addr, rsp.response.name()), UVM_HIGH)
endfunction

//------------------------------------------------------------------------------
// Body: Random Write Transactions
//------------------------------------------------------------------------------
task fpt_ahb_single_write_seq::body();
    fpt_ahb_master_transaction req;

    `uvm_info("SEQ", $sformatf("Starting Random Write Sequence with %0d transactions", num_trans), UVM_NONE)

    for (int i = 0; i < num_trans; i++) begin
        req = fpt_ahb_master_transaction::type_id::create("req");
        start_item(req);
        if (!req.randomize() with { direction == FPT_AHB_WRITE; }) begin
            `uvm_error("SEQ", "Randomize write failed")
        end
        finish_item(req);
    end
endtask

`endif // FPT_AHB_SINGLE_WRITE_SEQ_SVH
