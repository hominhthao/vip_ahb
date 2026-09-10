`ifndef FPT_AHB_BASE_TEST_SVH
`define FPT_AHB_BASE_TEST_SVH

class fpt_ahb_base_test extends uvm_test;
  `uvm_component_utils(fpt_ahb_base_test)

  fpt_ahb_env env;
  fpt_ahb_master_agent_cfg master_cfg;
  fpt_ahb_slave_agent_cfg  slave_cfg;
  fpt_ahb_common_memory    mem;

  extern function new(string name = "fpt_ahb_base_test", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void end_of_elaboration_phase(uvm_phase phase);
endclass

//------------------------------------------------------------------------------
// Constructor: Initializes the base test component
//------------------------------------------------------------------------------
function fpt_ahb_base_test::new(string name = "fpt_ahb_base_test", uvm_component parent = null);
  super.new(name, parent);
endfunction

//------------------------------------------------------------------------------
// Build Phase: Creates environment, configs, memory and sets up default sequences
//------------------------------------------------------------------------------
function void fpt_ahb_base_test::build_phase(uvm_phase phase);
  super.build_phase(phase);

  // 1. Khởi tạo mâm cấu hình cho Master
  master_cfg = fpt_ahb_master_agent_cfg::type_id::create("master_cfg");
  
  // Hứng sợi cáp quang (vif) từ file Top thả xuống
  if (!uvm_config_db#(virtual fpt_ahb_if)::get(this, "", "vif", master_cfg.vif)) begin
    `uvm_fatal("NO_VIF", "Virtual interface not found in config_db. Did you set it in Top?")
  end
  // Ném cục Config xuống cho Master Agent
  uvm_config_db#(fpt_ahb_master_agent_cfg)::set(this, "env.master_agent*", "cfg", master_cfg);

  // 2. Khởi tạo mâm cấu hình cho Slave
  slave_cfg = fpt_ahb_slave_agent_cfg::type_id::create("slave_cfg");
  slave_cfg.vif = master_cfg.vif; // Slave xài chung 1 sợi cáp Bus với Master
  uvm_config_db#(fpt_ahb_slave_agent_cfg)::set(this, "env.slave_agent*", "cfg", slave_cfg);

  // 3. Khởi tạo "Tủ lạnh" (Common Memory) và ném xuống cho Bếp trưởng (Slave Sequencer)
  mem = fpt_ahb_common_memory::type_id::create("mem");
  uvm_config_db#(fpt_ahb_common_memory)::set(this, "env.slave_agent.sequencer*", "mem", mem);

  // 4. Tuyệt chiêu: Ép Bếp trưởng tự động phục vụ (Chạy tự động Mem Sequence)
  uvm_config_db#(uvm_object_wrapper)::set(this, 
    "env.slave_agent.sequencer.run_phase", 
    "default_sequence", 
    fpt_ahb_slave_mem_seq::type_id::get());

  // 5. Khởi tạo Environment (Chiếc hộp bọc tất cả lại)
  env = fpt_ahb_env::type_id::create("env", this);
endfunction

//------------------------------------------------------------------------------
// End of Elaboration Phase: Prints the UVM topology tree
//------------------------------------------------------------------------------
function void fpt_ahb_base_test::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);
  // In ra cây cấu trúc gia phả của toàn bộ hệ thống VIP để dễ Debug
  uvm_top.print_topology();
endfunction

`endif // FPT_AHB_BASE_TEST_SVH
