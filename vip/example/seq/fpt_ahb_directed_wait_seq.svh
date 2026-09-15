`ifndef FPT_AHB_DIRECTED_WAIT_SEQ_SVH
`define FPT_AHB_DIRECTED_WAIT_SEQ_SVH

class fpt_ahb_directed_wait_master_seq extends fpt_ahb_master_base_seq;
    `uvm_object_utils(fpt_ahb_directed_wait_master_seq)

    fpt_ahb_direction_e direction = FPT_AHB_READ;

    extern function new(string name = "fpt_ahb_directed_wait_master_seq");
    extern virtual task body();
endclass

function fpt_ahb_directed_wait_master_seq::new(
                                                  string name = "fpt_ahb_directed_wait_master_seq"
                                                  );
    super.new(name);
endfunction

task fpt_ahb_directed_wait_master_seq::body();
    fpt_ahb_master_transaction req;

    req = fpt_ahb_master_transaction::type_id::create("req");
    start_item(req);
    req.addr = 'h100;
    req.direction = direction;
    req.write_data = 'hA5A5_5A5A;
    finish_item(req);
    get_response(req);
endtask

class fpt_ahb_directed_wait_slave_seq extends fpt_ahb_slave_base_seq;
    `uvm_object_utils(fpt_ahb_directed_wait_slave_seq)

    int unsigned wait_cycles;

    extern function new(string name = "fpt_ahb_directed_wait_slave_seq");
    extern virtual task body();
endclass

function fpt_ahb_directed_wait_slave_seq::new(
                                                 string name = "fpt_ahb_directed_wait_slave_seq"
                                                 );
    super.new(name);
endfunction

task fpt_ahb_directed_wait_slave_seq::body();
    fpt_ahb_slave_transaction req;

    if (!uvm_config_db#(int unsigned)::get(m_sequencer, "", "directed_wait_cycles",
                                           wait_cycles)) begin
        `uvm_fatal("NO_WAIT_CYCLES", "Directed WAIT test did not configure wait_cycles")
        return;
    end

    req = fpt_ahb_slave_transaction::type_id::create("req");
    start_item(req);
    finish_item(req);

    forever begin
        get_response(req);

        start_item(req);
        req.response = FPT_AHB_OKAY;
        req.wait_cycles = wait_cycles;
        finish_item(req);

        get_response(req);
    end
endtask

`endif // FPT_AHB_DIRECTED_WAIT_SEQ_SVH
