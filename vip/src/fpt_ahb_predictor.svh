`ifndef FPT_AHB_PREDICTOR_SVH
`define FPT_AHB_PREDICTOR_SVH

class fpt_ahb_predictor extends uvm_subscriber #(fpt_ahb_master_transaction);
    `uvm_component_utils(fpt_ahb_predictor)

    typedef bit [`FPT_AHB_VIP_ADDR_WIDTH-1:0] addr_t;
    typedef bit [`FPT_AHB_VIP_DATA_WIDTH-1:0] data_t;

    uvm_analysis_port #(data_t) expected_ap;
    
    protected fpt_ahb_common_memory ref_mem;

    extern function new(string name = "fpt_ahb_predictor", uvm_component parent = null);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void write(fpt_ahb_master_transaction t);
endclass : fpt_ahb_predictor

//---------------
// Description: Implementation of new
//---------------
function fpt_ahb_predictor::new(string name = "fpt_ahb_predictor", uvm_component parent = null);
    super.new(name, parent);
    expected_ap = new("expected_ap", this);
endfunction : new

//---------------
// Description: Implementation of build_phase
//---------------
function void fpt_ahb_predictor::build_phase(uvm_phase phase);
    super.build_phase(phase);
    ref_mem = fpt_ahb_common_memory::type_id::create("ref_mem");
endfunction : build_phase

//---------------
// Description: Implementation of write
//---------------
function void fpt_ahb_predictor::write(fpt_ahb_master_transaction t);
    data_t expected_data;
    
    if (t == null) return;

    if (t.response === FPT_AHB_OKAY) begin
        if (t.direction == FPT_AHB_WRITE) begin
            `uvm_info("FPT_AHB_PREDICTOR", 
                      $sformatf("WRITE addr=0x%0h data=0x%0h; updating reference memory", t.addr, t.write_data), 
                      UVM_LOW)
            ref_mem.write(t.addr, t.write_data);
        end else if (t.direction == FPT_AHB_READ) begin
            expected_data = ref_mem.read(t.addr);
            `uvm_info("FPT_AHB_PREDICTOR", 
                      $sformatf("READ addr=0x%0h expected_data=0x%0h; sending to expected_ap", t.addr, expected_data), 
                      UVM_LOW)
            expected_ap.write(expected_data);
        end
    end
endfunction : write

`endif
