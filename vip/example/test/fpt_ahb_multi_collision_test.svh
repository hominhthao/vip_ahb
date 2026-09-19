`ifndef FPT_AHB_MULTI_COLLISION_TEST_SVH
`define FPT_AHB_MULTI_COLLISION_TEST_SVH

class fpt_ahb_multi_collision_test extends fpt_ahb_base_test;
    `uvm_component_utils(fpt_ahb_multi_collision_test)

    function new(string name = "fpt_ahb_multi_collision_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase); // Base test allocates env_cfg and sets default 2x2 map

    endfunction


    
    
    virtual task main_phase(uvm_phase phase);
        fpt_ahb_multi_collision_vseq vseq = fpt_ahb_multi_collision_vseq::type_id::create("vseq");

        vseq.m0_seqr = env.master_agents[0].sequencer;
        vseq.m1_seqr = env.master_agents[1].sequencer;

        env.system_checker.expected_count = 2;

        phase.raise_objection(this);
        `uvm_info("TEST", "Starting Multi Collision Test...", UVM_LOW)
        
        vseq.start(null);
        
        `uvm_info("TEST", "Sequences completed. Waiting for RTL to finish transfers...", UVM_LOW)
        fork
            begin
                wait (env.system_checker.checked_count >= 2);
            end
            begin
                #10000ns;
                `uvm_error("TEST", "Timeout waiting for Checker to complete 2 transactions!")
            end
        join_any
        disable fork;

        `uvm_info("TEST", "Multi Collision Test Completed.", UVM_LOW)
        phase.drop_objection(this);
    endtask


endclass

`endif // FPT_AHB_MULTI_COLLISION_TEST_SVH
