`ifndef FPT_AHB_SINGLE_READ_SEQ_SVH
`define FPT_AHB_SINGLE_READ_SEQ_SVH

class fpt_ahb_single_read_seq extends fpt_ahb_master_base_seq;
    `uvm_object_utils(fpt_ahb_single_read_seq)

    rand int num_trans;

    constraint c_num_trans {
        num_trans inside {[100:1000]};
    }

    extern function new(string name = "fpt_ahb_single_read_seq");
    extern virtual task body();
    extern virtual function void process_response(fpt_ahb_master_transaction rsp);
endclass

//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
function fpt_ahb_single_read_seq::new(string name = "fpt_ahb_single_read_seq");
    super.new(name);
endfunction

//------------------------------------------------------------------------------
// Response Handler
//------------------------------------------------------------------------------
function void fpt_ahb_single_read_seq::process_response(fpt_ahb_master_transaction rsp);
    `uvm_info("SEQ_READ", $sformatf("Read data 'h%0h from address 'h%0h (response=%s)", 
                                     rsp.read_data, rsp.addr, rsp.response.name()), UVM_HIGH)
endfunction

//------------------------------------------------------------------------------
// Body: Random Read Transactions
//------------------------------------------------------------------------------
task fpt_ahb_single_read_seq::body();
    fpt_ahb_master_transaction req;

    `uvm_info("SEQ", $sformatf("Starting Random Read Sequence with %0d transactions", num_trans), UVM_NONE)

    for (int i = 0; i < num_trans; i++) begin
        req = fpt_ahb_master_transaction::type_id::create("req");
        start_item(req);
        if (!req.randomize() with { direction == FPT_AHB_READ; }) begin
            `uvm_error("SEQ", "Randomize read failed")
        end
        finish_item(req);
    end
endtask

`endif // FPT_AHB_SINGLE_READ_SEQ_SVH
