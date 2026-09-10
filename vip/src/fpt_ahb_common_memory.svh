`ifndef FPT_AHB_COMMON_MEMORY_SVH
`define FPT_AHB_COMMON_MEMORY_SVH

// Future Env creates one object and distributes its handle to Slave consumers.
// Storage has no bus timing/reset behavior; callers decide when to clear it.
class fpt_ahb_common_memory extends uvm_object;
    `uvm_object_utils(fpt_ahb_common_memory)

    typedef bit [`FPT_AHB_VIP_ADDR_WIDTH-1:0] addr_t;
    typedef bit [`FPT_AHB_VIP_DATA_WIDTH-1:0] data_t;

    // Keys are full byte addresses; alignment checking belongs to bus components.
    data_t storage[addr_t];

    extern function new(string name = "fpt_ahb_common_memory");
    extern function void write(input addr_t addr, input data_t data);
    extern function data_t read(input addr_t addr);
    extern function void clear();
endclass

function fpt_ahb_common_memory::new(string name = "fpt_ahb_common_memory");
    super.new(name);
endfunction

function void fpt_ahb_common_memory::write(input addr_t addr, input data_t data);
    storage[addr] = data;
endfunction

function fpt_ahb_common_memory::data_t fpt_ahb_common_memory::read(input addr_t addr);
    if (storage.exists(addr))
        return storage[addr];
    return '0;
endfunction

function void fpt_ahb_common_memory::clear();
    storage.delete();
endfunction

`endif
