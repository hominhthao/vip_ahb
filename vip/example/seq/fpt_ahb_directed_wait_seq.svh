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
    req.write_data = new[1];
    req.write_data[0] = 'hA5A5_5A5A;
    finish_item(req);
    get_response(req);
endtask

`endif // FPT_AHB_DIRECTED_WAIT_SEQ_SVH
