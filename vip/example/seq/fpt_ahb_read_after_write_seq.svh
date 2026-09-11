`ifndef FPT_AHB_READ_AFTER_WRITE_SEQ_SVH
`define FPT_AHB_READ_AFTER_WRITE_SEQ_SVH

class fpt_ahb_read_after_write_seq extends fpt_ahb_master_base_seq;
    `uvm_object_utils(fpt_ahb_read_after_write_seq)

    extern function new(string name = "fpt_ahb_read_after_write_seq");
    extern virtual task body();
endclass

//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
function fpt_ahb_read_after_write_seq::new(string name = "fpt_ahb_read_after_write_seq");
    super.new(name);
endfunction

//------------------------------------------------------------------------------
// Body: Demonstrates AHB Pipelined Sequence Execution
//------------------------------------------------------------------------------
task fpt_ahb_read_after_write_seq::body();
    fpt_ahb_master_transaction req_write;
    fpt_ahb_master_transaction req_read;
    bit [`FPT_AHB_VIP_ADDR_WIDTH-1:0] target_addr;

    req_write = fpt_ahb_master_transaction::type_id::create("req_write");
    start_item(req_write);
    if (!req_write.randomize() with { direction == FPT_AHB_WRITE; }) begin
        `uvm_error("SEQ", "Randomize write failed")
    end
    target_addr = req_write.addr;
    finish_item(req_write);

    req_read = fpt_ahb_master_transaction::type_id::create("req_read");
    start_item(req_read);
    if (!req_read.randomize() with { direction == FPT_AHB_READ; addr == target_addr; }) begin
        `uvm_error("SEQ", "Randomize read failed")
    end
    finish_item(req_read);

    get_response(req_write);
    `uvm_info("SEQ_WRITE", $sformatf("Wrote data 'h%0h to address 'h%0h", req_write.write_data, req_write.addr), UVM_NONE)

    get_response(req_read);
    `uvm_info("SEQ_READ", $sformatf("Read data 'h%0h from address 'h%0h", req_read.read_data, req_read.addr), UVM_NONE)

endtask

`endif // FPT_AHB_READ_AFTER_WRITE_SEQ_SVH
