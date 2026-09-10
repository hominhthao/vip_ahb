`ifndef FPT_AHB_SLAVE_MEM_SEQ_SVH
`define FPT_AHB_SLAVE_MEM_SEQ_SVH

class fpt_ahb_slave_mem_seq extends fpt_ahb_slave_base_seq;
  `uvm_object_utils(fpt_ahb_slave_mem_seq)

  extern function new(string name = "fpt_ahb_slave_mem_seq");
  extern virtual task body();
endclass

function fpt_ahb_slave_mem_seq::new(string name = "fpt_ahb_slave_mem_seq");
  super.new(name);
endfunction

task fpt_ahb_slave_mem_seq::body();
  fpt_ahb_slave_transaction req;
  
  // 0. Handshake ban đầu: Ném cho Driver 1 gói tin trống để nó học được ID của Sequence này
  req = fpt_ahb_slave_transaction::type_id::create("req");
  start_item(req);
  req.c_v0_0_context.constraint_mode(0); // Tạm tắt constraint vì chưa có data
  finish_item(req);
  
  forever begin
    // 1. Chờ Driver báo cáo Address Phase
    get_response(req);
    
    // 2. Nhận lệnh, Randomize và chuẩn bị phản hồi
    start_item(req);
    req.c_v0_0_context.constraint_mode(1); // Bật constraint lại vì req đã có addr chuẩn
    
    if (!req.randomize()) begin
      `uvm_error("SEQ_RAND", "Randomization failed")
    end
    
    if (req.direction == FPT_AHB_READ) begin
      req.read_data = mem.read(req.addr);
      `uvm_info("SLV_MEM", $sformatf("Reading 'h%0h from memory at 'h%0h", req.read_data, req.addr), UVM_HIGH)
    end
    
    finish_item(req);
    
    // 3. Chờ Driver báo cáo Data Phase hoàn tất
    get_response(req);
    
    if (req.direction == FPT_AHB_WRITE) begin
      `uvm_info("SLV_MEM", $sformatf("Writing 'h%0h to memory at 'h%0h", req.write_data, req.addr), UVM_HIGH)
      mem.write(req.addr, req.write_data);
    end
  end
endtask

`endif // FPT_AHB_SLAVE_MEM_SEQ_SVH
