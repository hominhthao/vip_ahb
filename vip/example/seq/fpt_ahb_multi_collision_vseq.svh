`ifndef FPT_AHB_MULTI_COLLISION_VSEQ_SVH
`define FPT_AHB_MULTI_COLLISION_VSEQ_SVH

class fpt_ahb_target_write_seq extends fpt_ahb_master_base_seq;
    `uvm_object_utils(fpt_ahb_target_write_seq)
    function new(string name=""); super.new(name); endfunction
    task body();
        fpt_ahb_master_transaction req = fpt_ahb_master_transaction::type_id::create("req");
        start_item(req);
        if (!req.randomize() with { addr == 32'h0000_00A4; direction == FPT_AHB_WRITE; })
            `uvm_error("SEQ", "Rand failed")
        finish_item(req);
    endtask
endclass

class fpt_ahb_target_read_seq extends fpt_ahb_master_base_seq;
    `uvm_object_utils(fpt_ahb_target_read_seq)
    function new(string name=""); super.new(name); endfunction
    task body();
        fpt_ahb_master_transaction req = fpt_ahb_master_transaction::type_id::create("req");
        start_item(req);
        if (!req.randomize() with { addr == 32'h0000_00A4; direction == FPT_AHB_READ; })
            `uvm_error("SEQ", "Rand failed")
        finish_item(req);
    endtask
endclass

class fpt_ahb_multi_collision_vseq extends uvm_sequence;
    `uvm_object_utils(fpt_ahb_multi_collision_vseq)

    uvm_sequencer #(fpt_ahb_master_transaction) m0_seqr;
    uvm_sequencer #(fpt_ahb_master_transaction) m1_seqr;

    function new(string name = "fpt_ahb_multi_collision_vseq");
        super.new(name);
    endfunction

    task body();
        fpt_ahb_target_write_seq m0_seq = fpt_ahb_target_write_seq::type_id::create("m0_seq");
        fpt_ahb_target_read_seq  m1_seq = fpt_ahb_target_read_seq::type_id::create("m1_seq");

        if (m0_seqr == null || m1_seqr == null) begin
            `uvm_fatal("VSEQ", "Sequencers are not assigned!")
        end

        `uvm_info("VSEQ", "Starting concurrent M0 and M1 requests to S0...", UVM_LOW)
        
        fork
            m0_seq.start(m0_seqr);
            m1_seq.start(m1_seqr);
        join

        `uvm_info("VSEQ", "Concurrent requests completed!", UVM_LOW)
    endtask
endclass

`endif // FPT_AHB_MULTI_COLLISION_VSEQ_SVH
