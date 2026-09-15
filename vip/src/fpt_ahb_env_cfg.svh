`ifndef FPT_AHB_ENV_CFG_SVH
`define FPT_AHB_ENV_CFG_SVH

class fpt_ahb_env_cfg extends uvm_object;
    `uvm_object_utils(fpt_ahb_env_cfg)

    int unsigned num_masters = 1;
    int unsigned num_slaves  = 1;

    fpt_ahb_master_agent_cfg master_cfgs[];
    fpt_ahb_slave_agent_cfg  slave_cfgs[];
    bit agent_cfgs_created = 0;

    // This policy becomes active when the Scoreboard evolves into System Checker.
    bit has_system_checker = 1;

    extern function new(string name = "fpt_ahb_env_cfg");
    extern function void create_agent_cfgs();
    extern function bit validate();
endclass : fpt_ahb_env_cfg

function fpt_ahb_env_cfg::new(string name = "fpt_ahb_env_cfg");
    super.new(name);
endfunction : new

function void fpt_ahb_env_cfg::create_agent_cfgs();
    if (agent_cfgs_created) begin
        `uvm_fatal("FPT_AHB_ENV_CFG_CREATE",
                   "Agent configuration arrays have already been created")
        return;
    end
    agent_cfgs_created = 1;

    master_cfgs = new[num_masters];
    slave_cfgs = new[num_slaves];

    foreach (master_cfgs[i]) begin
        master_cfgs[i] = fpt_ahb_master_agent_cfg::type_id::create(
            $sformatf("master_cfg_%0d", i));
    end
    foreach (slave_cfgs[i]) begin
        slave_cfgs[i] = fpt_ahb_slave_agent_cfg::type_id::create(
            $sformatf("slave_cfg_%0d", i));
    end
endfunction : create_agent_cfgs

function bit fpt_ahb_env_cfg::validate();
    if (num_masters == 0 || num_slaves == 0) begin
        `uvm_fatal("FPT_AHB_ENV_CFG_COUNT",
                   "Environment requires at least one Master and one Slave configuration")
        return 0;
    end

    if (num_masters != 1 || num_slaves != 1) begin
        `uvm_fatal("FPT_AHB_ENV_CFG_TOPOLOGY",
                   $sformatf({"AHB VIP v0.1 currently verifies only 1 Master / 1 Slave; ",
                              "configured num_masters=%0d num_slaves=%0d"},
                             num_masters, num_slaves))
        return 0;
    end

    if (master_cfgs.size() != num_masters || slave_cfgs.size() != num_slaves) begin
        `uvm_fatal("FPT_AHB_ENV_CFG_ARRAY",
                   $sformatf({"Agent configuration array size mismatch: ",
                              "master_cfgs=%0d num_masters=%0d ",
                              "slave_cfgs=%0d num_slaves=%0d"},
                             master_cfgs.size(), num_masters,
                             slave_cfgs.size(), num_slaves))
        return 0;
    end

    foreach (master_cfgs[i]) begin
        if (master_cfgs[i] == null) begin
            `uvm_fatal("FPT_AHB_ENV_CFG_NULL",
                       $sformatf("master_cfgs[%0d] is null", i))
            return 0;
        end
        if (master_cfgs[i].vif == null) begin
            `uvm_fatal("FPT_AHB_ENV_CFG_VIF",
                       $sformatf("master_cfgs[%0d].vif is null", i))
            return 0;
        end
    end

    foreach (slave_cfgs[i]) begin
        if (slave_cfgs[i] == null) begin
            `uvm_fatal("FPT_AHB_ENV_CFG_NULL",
                       $sformatf("slave_cfgs[%0d] is null", i))
            return 0;
        end
        if (slave_cfgs[i].vif == null) begin
            `uvm_fatal("FPT_AHB_ENV_CFG_VIF",
                       $sformatf("slave_cfgs[%0d].vif is null", i))
            return 0;
        end
        if (!slave_cfgs[i].validate()) begin
            return 0;
        end
    end

    return 1;
endfunction : validate

`endif // FPT_AHB_ENV_CFG_SVH
