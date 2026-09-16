`ifndef FPT_AHB_MASTER_BASE_SEQ_SVH
`define FPT_AHB_MASTER_BASE_SEQ_SVH

class fpt_ahb_master_base_seq extends uvm_sequence #(fpt_ahb_master_transaction);
    `uvm_object_utils(fpt_ahb_master_base_seq)

    fpt_ahb_master_agent_cfg cfg;

    extern function new(string name = "fpt_ahb_master_base_seq");
    extern virtual task pre_body();
    extern virtual function void mid_do(uvm_sequence_item this_item);
    extern virtual function void response_handler(uvm_sequence_item response);
    extern virtual function void process_response(fpt_ahb_master_transaction rsp);
endclass

//------------------------------------------------------------------------------
// Constructor
//------------------------------------------------------------------------------
function fpt_ahb_master_base_seq::new(string name = "fpt_ahb_master_base_seq");
    super.new(name);
endfunction

task fpt_ahb_master_base_seq::pre_body();
    if (!uvm_config_db#(fpt_ahb_master_agent_cfg)::get(m_sequencer, "", "cfg", cfg) || cfg == null) begin
        `uvm_fatal("NO_CFG", "Master base sequence requires Master Agent Config")
    end
    use_response_handler(1);
endtask

function void fpt_ahb_master_base_seq::mid_do(uvm_sequence_item this_item);
    fpt_ahb_master_transaction req;
    if ($cast(req, this_item)) begin
        if (cfg.wait_mode == FPT_AHB_RANDOM_WAIT) begin
            req.master_delay = $urandom_range(cfg.max_delay, cfg.min_delay);
        end else begin
            req.master_delay = 0;
        end
    end
endfunction

function void fpt_ahb_master_base_seq::response_handler(uvm_sequence_item response);
    fpt_ahb_master_transaction rsp_tx;
    if (!$cast(rsp_tx, response)) begin
        `uvm_error("SEQ_RSP", "Invalid response type received in base sequence")
        return;
    end
    process_response(rsp_tx);
endfunction

function void fpt_ahb_master_base_seq::process_response(fpt_ahb_master_transaction rsp);
    // Derived classes can override this to process completed transfers.
endfunction

`endif // FPT_AHB_MASTER_BASE_SEQ_SVH
