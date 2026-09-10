`ifndef FPT_AHB_RANDOM_RW_SEQ_SVH
`define FPT_AHB_RANDOM_RW_SEQ_SVH

class fpt_ahb_random_rw_seq extends fpt_ahb_master_base_seq;
  `uvm_object_utils(fpt_ahb_random_rw_seq)

  rand int num_trans;
  
  constraint c_num_trans {
    num_trans inside {[5:15]};
  }

  extern function new(string name = "fpt_ahb_random_rw_seq");
  extern virtual task body();
endclass

function fpt_ahb_random_rw_seq::new(string name = "fpt_ahb_random_rw_seq");
  super.new(name);
endfunction

task fpt_ahb_random_rw_seq::body();
  fpt_ahb_master_transaction req;
  
  `uvm_info("SEQ", $sformatf("Starting Random R/W Sequence with %0d transactions", num_trans), UVM_NONE)
  
  for (int i = 0; i < num_trans; i++) begin
    req = fpt_ahb_master_transaction::type_id::create("req");
    start_item(req);
    // Tự động random địa chỉ (align 4 bytes), dữ liệu và chiều (READ/WRITE)
    if (!req.randomize()) begin
      `uvm_error("SEQ", "Randomize failed")
    end
    finish_item(req);
    
    // Đợi kết thúc giao dịch
    get_response(req);
    
    `uvm_info("SEQ_ITEM", $sformatf("Trans %0d/%0d: %s addr='h%0h data='h%0h", 
      i+1, num_trans, req.direction.name(), req.addr, 
      (req.direction == FPT_AHB_WRITE) ? req.write_data : req.read_data), UVM_NONE)
  end
  
  `uvm_info("SEQ", "Random R/W Sequence Completed.", UVM_NONE)
endtask

`endif // FPT_AHB_RANDOM_RW_SEQ_SVH
