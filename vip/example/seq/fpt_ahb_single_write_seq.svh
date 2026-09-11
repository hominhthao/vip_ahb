`ifndef FPT_AHB_SINGLE_WRITE_SEQ_SVH
`define FPT_AHB_SINGLE_WRITE_SEQ_SVH

class fpt_ahb_single_write_seq extends fpt_ahb_master_base_seq;
    `uvm_object_utils(fpt_ahb_single_write_seq)

    extern function new(string name = "fpt_ahb_single_write_seq");
    extern virtual task body();
endclass

//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
function fpt_ahb_single_write_seq::new(string name = "fpt_ahb_single_write_seq");
    super.new(name);
endfunction

//------------------------------------------------------------------------------
// Body: Single Write Transaction
//------------------------------------------------------------------------------
task fpt_ahb_single_write_seq::body();
    fpt_ahb_master_transaction req;

    req = fpt_ahb_master_transaction::type_id::create("req");
    start_item(req);
    if (!req.randomize() with { direction == FPT_AHB_WRITE; }) begin
        `uvm_error("SEQ", "Randomize write failed")
    end
    finish_item(req);

    // Đợi Driver thực thi xong pha dữ liệu
    get_response(req);

    `uvm_info("SEQ_WRITE", $sformatf("Single Write Completed: Wrote data 'h%0h to address 'h%0h", req.write_data, req.addr), UVM_NONE)
endtask

`endif // FPT_AHB_SINGLE_WRITE_SEQ_SVH
