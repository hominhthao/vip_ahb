`ifndef FPT_AHB_SLAVE_DRIVER_SVH
`define FPT_AHB_SLAVE_DRIVER_SVH

class fpt_ahb_slave_driver extends uvm_driver #(fpt_ahb_slave_transaction);
  `uvm_component_utils(fpt_ahb_slave_driver)

  fpt_ahb_slave_agent_cfg cfg;
  fpt_ahb_slave_transaction request_q[$];

  extern function new(string name = "fpt_ahb_slave_driver", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task reset_signals();
  extern virtual task address_phase_thread();
  extern virtual task data_phase_thread();
endclass

function fpt_ahb_slave_driver::new(string name = "fpt_ahb_slave_driver", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void fpt_ahb_slave_driver::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (cfg == null) begin
    if (!uvm_config_db#(fpt_ahb_slave_agent_cfg)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal("NO_CFG", {"Configuration must be set for: ", get_full_name(), ".cfg"})
    end
  end
endfunction

task fpt_ahb_slave_driver::run_phase(uvm_phase phase);
  reset_signals();
  fork
    address_phase_thread();
    data_phase_thread();
  join_none
endtask

task fpt_ahb_slave_driver::reset_signals();
  wait (cfg.vif.hresetn === 1'b0);
  cfg.vif.cb_slave.hreadyout <= 1'b1; 
  cfg.vif.cb_slave.hresp     <= 1'b0; 
  cfg.vif.cb_slave.hrdata    <= 0;
  request_q.delete();
  wait (cfg.vif.hresetn === 1'b1);
endtask

task fpt_ahb_slave_driver::address_phase_thread();
  fpt_ahb_slave_transaction incoming_req;
  
  forever begin
    @(cfg.vif.cb_slave);
    
    if (cfg.vif.cb_slave.hready === 1'b1 && 
        cfg.vif.cb_slave.hselx === 1'b1 && 
        (cfg.vif.cb_slave.htrans == 2'b10 || cfg.vif.cb_slave.htrans == 2'b11)) begin
       
       incoming_req = fpt_ahb_slave_transaction::type_id::create("incoming_req");
       incoming_req.addr = cfg.vif.cb_slave.haddr;
       incoming_req.direction = (cfg.vif.cb_slave.hwrite == 1'b1) ? FPT_AHB_WRITE : FPT_AHB_READ;
       $cast(incoming_req.size, cfg.vif.cb_slave.hsize);
       $cast(incoming_req.burst, cfg.vif.cb_slave.hburst);
       
       request_q.push_back(incoming_req);
    end
  end
endtask

task fpt_ahb_slave_driver::data_phase_thread();
  fpt_ahb_slave_transaction req;
  int seq_id;
  int tr_id;
  
  // 0. Handshake ban đầu để lấy ID của Sequence, giúp put_response tìm đúng địa chỉ
  seq_item_port.get_next_item(req);
  seq_id = req.get_sequence_id();
  tr_id = req.get_transaction_id();
  seq_item_port.item_done();
  
  forever begin
    if (request_q.size() == 0) begin
      cfg.vif.cb_slave.hreadyout <= 1'b1;
      cfg.vif.cb_slave.hresp     <= 1'b0;
      @(cfg.vif.cb_slave);
      continue;
    end
    
    req = request_q.pop_front();
    
    // Cài ID để Sequence nhận diện được gói tin này
    req.set_sequence_id(seq_id);
    req.set_transaction_id(tr_id);
    
    // 1. Gửi thông tin Address Phase lên Sequence
    seq_item_port.put_response(req);
    
    // 2. Chờ Sequence cấp Data và Wait cycles
    seq_item_port.get_next_item(req);
    
    repeat (req.wait_cycles) begin
       cfg.vif.cb_slave.hreadyout <= 1'b0;
       cfg.vif.cb_slave.hresp     <= 1'b0;
       @(cfg.vif.cb_slave);
    end
    
    cfg.vif.cb_slave.hreadyout <= 1'b1;
    cfg.vif.cb_slave.hresp <= (req.response == FPT_AHB_ERROR) ? 1'b1 : 1'b0;
    
    if (req.direction == FPT_AHB_READ) begin
       cfg.vif.cb_slave.hrdata <= req.read_data;
    end
    
    @(cfg.vif.cb_slave);
    
    if (req.direction == FPT_AHB_WRITE) begin
       req.write_data = cfg.vif.cb_slave.hwdata;
    end
    
    seq_item_port.item_done();
    
    // Cài lại ID (phòng hờ item_done làm mất)
    req.set_sequence_id(seq_id);
    req.set_transaction_id(tr_id);
    
    // 3. Gửi thông tin Data Phase đã hoàn tất (kèm write_data) lên Sequence
    seq_item_port.put_response(req);
  end
endtask

`endif // FPT_AHB_SLAVE_DRIVER_SVH
