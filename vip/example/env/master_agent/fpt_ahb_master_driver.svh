`ifndef FPT_AHB_MASTER_DRIVER_SVH
`define FPT_AHB_MASTER_DRIVER_SVH

class fpt_ahb_master_driver extends uvm_driver #(fpt_ahb_master_transaction);
  `uvm_component_utils(fpt_ahb_master_driver)

  fpt_ahb_master_agent_cfg cfg;
  
  // Hàng đợi kết nối giữa 2 luồng Address và Data
  fpt_ahb_master_transaction pipeline_q[$];

  extern function new(string name = "fpt_ahb_master_driver", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task reset_signals();
  extern virtual task address_phase_thread();
  extern virtual task data_phase_thread();
endclass

//------------------------------------------------------------------------------
// Constructor: Initializes the driver component
//------------------------------------------------------------------------------
function fpt_ahb_master_driver::new(string name = "fpt_ahb_master_driver", uvm_component parent = null);
  super.new(name, parent);
endfunction

//------------------------------------------------------------------------------
// Build Phase: Retrieves the agent configuration containing the virtual interface
//------------------------------------------------------------------------------
function void fpt_ahb_master_driver::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (cfg == null) begin
    if (!uvm_config_db#(fpt_ahb_master_agent_cfg)::get(this, "", "cfg", cfg)) begin
      `uvm_fatal("NO_CFG", {"Configuration must be set for: ", get_full_name(), ".cfg"})
    end
  end
endfunction

//------------------------------------------------------------------------------
// Run Phase: Splits execution into two concurrent threads for AHB pipelining
//------------------------------------------------------------------------------
task fpt_ahb_master_driver::run_phase(uvm_phase phase);
  reset_signals();
  fork
    address_phase_thread();
    data_phase_thread();
  join_none
endtask

//------------------------------------------------------------------------------
// Reset Signals: Clears bus and flushes the pipeline queue during reset
//------------------------------------------------------------------------------
task fpt_ahb_master_driver::reset_signals();
  wait (cfg.vif.hresetn === 1'b0); 
  cfg.vif.cb_master.htrans <= 2'b00; 
  cfg.vif.cb_master.hselx  <= 0;
  pipeline_q.delete(); // Xóa sạch hàng đợi
  wait (cfg.vif.hresetn === 1'b1);
endtask

//------------------------------------------------------------------------------
// Address Phase Thread: Polls sequencer and drives address pipeline
//------------------------------------------------------------------------------
task fpt_ahb_master_driver::address_phase_thread();
  fpt_ahb_master_transaction req;
  
  forever begin
    @(cfg.vif.cb_master);
    
    // Nếu Slave đang hold hready = 0 (bận xử lý lệnh trước) -> Bắt buộc đứng im
    if (cfg.vif.cb_master.hready === 1'b0) continue;

    // Dùng try_next_item thay vì get_next_item để không bị treo luồng khi Sequencer rỗng
    seq_item_port.try_next_item(req);
    
    if (req != null) begin
      `uvm_info("DRV_ADDR", $sformatf("Driving Address: 'h%0h", req.addr), UVM_HIGH)
      
      cfg.vif.cb_master.haddr  <= req.addr;
      cfg.vif.cb_master.hwrite <= (req.direction == FPT_AHB_WRITE) ? 1'b1 : 1'b0;
      cfg.vif.cb_master.hsize  <= req.size;
      cfg.vif.cb_master.hburst <= req.burst;
      cfg.vif.cb_master.hprot  <= 4'b0011; 
      cfg.vif.cb_master.htrans <= 2'b10; // TR_NONSEQ
      cfg.vif.cb_master.hselx  <= 1'b1;  
      
      // Chuyển giao dịch vào Hàng đợi cho Data Thread xử lý ở nhịp sau
      pipeline_q.push_back(req);
      
      // Báo cáo hoàn tất để Sequencer nhả lệnh tiếp theo ngay lập tức (Pipelining)
      seq_item_port.item_done(); 
    end else begin
      // Không có lệnh -> Trả Bus về trạng thái nghỉ (IDLE)
      cfg.vif.cb_master.htrans <= 2'b00; // TR_IDLE
      cfg.vif.cb_master.hselx  <= 1'b0;
    end
  end
endtask

//------------------------------------------------------------------------------
// Data Phase Thread: Pops queue and executes data transfers
//------------------------------------------------------------------------------
task fpt_ahb_master_driver::data_phase_thread();
  fpt_ahb_master_transaction current_tx;
  
  forever begin
    // Ngủ đông chờ cho đến khi có lệnh lọt vào hàng đợi
    wait (pipeline_q.size() > 0);
    current_tx = pipeline_q.pop_front();
    
    `uvm_info("DRV_DATA", $sformatf("Driving/Reading Data for Addr: 'h%0h", current_tx.addr), UVM_HIGH)

    // Ép Dữ liệu lên Bus (nếu là lệnh Ghi) ngay tại nhịp Clock hiện tại
    if (current_tx.direction == FPT_AHB_WRITE) begin
      cfg.vif.cb_master.hwdata <= current_tx.write_data;
    end
    
    // Phải chờ ít nhất 1 chu kỳ clock (bản chất của Data Phase nằm sau Address Phase)
    // Và tiếp tục chờ nếu hready = 0 (Wait States)
    do begin
      @(cfg.vif.cb_master);
    end while (cfg.vif.cb_master.hready === 1'b0);
    
    // Lấy kết quả trả về từ Slave
    if (current_tx.direction == FPT_AHB_READ) begin
      current_tx.read_data = cfg.vif.cb_master.hrdata;
    end
    current_tx.response = (cfg.vif.cb_master.hresp == 1'b1) ? FPT_AHB_ERROR : FPT_AHB_OKAY;
  end
endtask

`endif // FPT_AHB_MASTER_DRIVER_SVH
