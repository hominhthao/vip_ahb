`ifndef FPT_AHB_SLAVE_WAIT_MEM_SEQ_SVH
`define FPT_AHB_SLAVE_WAIT_MEM_SEQ_SVH

class fpt_ahb_slave_wait_mem_seq extends fpt_ahb_slave_mem_seq;
    `uvm_object_utils(fpt_ahb_slave_wait_mem_seq)

    extern function new(string name = "fpt_ahb_slave_wait_mem_seq");
    extern virtual task body();
endclass

function fpt_ahb_slave_wait_mem_seq::new(string name = "fpt_ahb_slave_wait_mem_seq");
    super.new(name);
endfunction

task fpt_ahb_slave_wait_mem_seq::body();
    fpt_ahb_slave_transaction req;

    req = fpt_ahb_slave_transaction::type_id::create("req");
    start_item(req);
    req.c_v0_0_context.constraint_mode(0);
    finish_item(req);

    forever begin
        get_response(req);

        start_item(req);
        req.c_v0_0_context.constraint_mode(1);
        if (!req.randomize()) begin
            `uvm_error("SEQ_RAND", "Randomization failed")
        end
        // The sequence plans response latency only; the Slave Driver owns memory access.
        req.wait_cycles = $urandom_range(0, 4);
        `uvm_info("SLV_WAIT",
                  $sformatf("Planned wait_cycles=%0d for addr='h%0h",
                            req.wait_cycles, req.addr),
                  UVM_HIGH)
        finish_item(req);

        get_response(req);
    end
endtask

`endif // FPT_AHB_SLAVE_WAIT_MEM_SEQ_SVH
