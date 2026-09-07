`ifndef FPT_AHB_TRANSACTION_SVH
`define FPT_AHB_TRANSACTION_SVH

// One item requests one AHB-Lite SINGLE, WORD-sized transfer.
class fpt_ahb_transaction extends uvm_sequence_item;

    `uvm_object_utils(fpt_ahb_transaction)

    rand bit [`FPT_AHB_VIP_ADDR_WIDTH-1:0] addr;

    // Used only for WRITE; READ does not constrain this unused payload.
    rand bit [`FPT_AHB_VIP_DATA_WIDTH-1:0] write_data;
    rand fpt_ahb_direction_e direction;

    fpt_ahb_size_e size = FPT_AHB_WORD;
    fpt_ahb_burst_e burst = FPT_AHB_SINGLE;

    // Results are populated by the response/observation path, not randomization.
    // Interpret them only after transfer completion; read_data is for READ only.
    logic [`FPT_AHB_VIP_DATA_WIDTH-1:0] read_data;
    fpt_ahb_response_e response;

    constraint c_word_alignment {
        addr[1:0] == 2'b00;
    }

    // Non-random state is checked, not repaired, by randomize().
    constraint c_v0_0_transfer {
        size == FPT_AHB_WORD;
        burst == FPT_AHB_SINGLE;
    }

    extern function new(string name = "fpt_ahb_transaction");

endclass : fpt_ahb_transaction

function fpt_ahb_transaction::new(string name = "fpt_ahb_transaction");
    super.new(name);
endfunction : new

`endif
