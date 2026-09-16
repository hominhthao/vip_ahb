`ifndef FPT_AHB_SLAVE_WAIT_MEM_SEQ_SVH
`define FPT_AHB_SLAVE_WAIT_MEM_SEQ_SVH

class fpt_ahb_slave_wait_mem_seq extends fpt_ahb_slave_mem_seq;
    `uvm_object_utils(fpt_ahb_slave_wait_mem_seq)

    extern function new(string name = "fpt_ahb_slave_wait_mem_seq");
    extern virtual function bit resolve_wait_cycles(
        fpt_ahb_slave_transaction req
    );
endclass

function fpt_ahb_slave_wait_mem_seq::new(string name = "fpt_ahb_slave_wait_mem_seq");
    super.new(name);
endfunction

function bit fpt_ahb_slave_wait_mem_seq::resolve_wait_cycles(
    fpt_ahb_slave_transaction req
    );
    int unsigned resolved_wait_cycles;

    if (!std::randomize(resolved_wait_cycles) with {
            resolved_wait_cycles inside {[0:4]};
        }) begin
        `uvm_error("SEQ_WAIT_RAND", "Legacy WAIT-cycle randomization failed")
        return 0;
    end

    req.wait_cycles = resolved_wait_cycles;
    `uvm_info("SLV_WAIT",
              $sformatf("Legacy WAIT resolved to wait_cycles=%0d for addr='h%0h",
                        req.wait_cycles, req.addr),
              UVM_HIGH)
    return 1;
endfunction : resolve_wait_cycles

`endif // FPT_AHB_SLAVE_WAIT_MEM_SEQ_SVH
