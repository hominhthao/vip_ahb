`ifndef FPT_AHB_SLAVE_TRANSACTION_SVH
`define FPT_AHB_SLAVE_TRANSACTION_SVH

// Context for one observed request and controls for its slave response.
class fpt_ahb_slave_transaction extends uvm_sequence_item;

    `uvm_object_utils(fpt_ahb_slave_transaction)

    // Captured by the future request-handling path, never randomized here.
    bit [`FPT_AHB_VIP_ADDR_WIDTH-1:0] addr;
    fpt_ahb_direction_e direction;
    bit [`FPT_AHB_VIP_DATA_WIDTH-1:0] write_data;
    fpt_ahb_size_e size = FPT_AHB_WORD;
    fpt_ahb_burst_e burst = FPT_AHB_SINGLE;

    // Generated controls, not observed results. READ data is unused for WRITE.
    rand bit [`FPT_AHB_VIP_DATA_WIDTH-1:0] read_data;
    rand fpt_ahb_response_e response;
    // No policy maximum yet; the future sequence must select a practical budget.
    rand int unsigned wait_cycles;

    constraint c_response_defaults {
        soft wait_cycles == 0;
        soft response == FPT_AHB_OKAY;
    }

    // Validate captured v0.0 context without changing it during randomization.
    constraint c_v0_0_context {
        addr[1:0] == 2'b00;
        direction inside {FPT_AHB_READ, FPT_AHB_WRITE};
        size == FPT_AHB_WORD;
        burst == FPT_AHB_SINGLE;
    }

    extern function new(string name = "fpt_ahb_slave_transaction");
    extern virtual function void do_print(uvm_printer printer);
    extern virtual function void do_copy(uvm_object rhs);
    extern virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);

endclass : fpt_ahb_slave_transaction

function fpt_ahb_slave_transaction::new(string name = "fpt_ahb_slave_transaction");
    super.new(name);
endfunction : new

function void fpt_ahb_slave_transaction::do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field("addr", addr, $bits(addr), UVM_HEX);
    if (direction.name() != "")
        printer.print_string("direction", direction.name());
    else
        printer.print_field("direction", direction, $bits(direction), UVM_BIN);
    printer.print_field("write_data", write_data, $bits(write_data), UVM_HEX);
    if (size.name() != "")
        printer.print_string("size", size.name());
    else
        printer.print_field("size", size, $bits(size), UVM_BIN);
    if (burst.name() != "")
        printer.print_string("burst", burst.name());
    else
        printer.print_field("burst", burst, $bits(burst), UVM_BIN);
    // Stored response controls, not evidence of a completed bus transfer.
    printer.print_field("read_data", read_data, $bits(read_data), UVM_HEX);
    if (response.name() != "")
        printer.print_string("response", response.name());
    else
        printer.print_field("response", response, $bits(response), UVM_BIN);
    printer.print_field("wait_cycles", wait_cycles, $bits(wait_cycles), UVM_DEC);
endfunction : do_print

function void fpt_ahb_slave_transaction::do_copy(uvm_object rhs);
    fpt_ahb_slave_transaction rhs_tr;

    if (!$cast(rhs_tr, rhs) || rhs_tr == null) begin
        `uvm_fatal("FPT_AHB_COPY", "Expected a non-null fpt_ahb_slave_transaction")
        return;
    end
    super.do_copy(rhs);
    // Copy all stored fields, including data ignored by compare().
    addr = rhs_tr.addr;
    direction = rhs_tr.direction;
    write_data = rhs_tr.write_data;
    size = rhs_tr.size;
    burst = rhs_tr.burst;
    read_data = rhs_tr.read_data;
    response = rhs_tr.response;
    wait_cycles = rhs_tr.wait_cycles;
endfunction : do_copy

function bit fpt_ahb_slave_transaction::do_compare(uvm_object rhs, uvm_comparer comparer);
    fpt_ahb_slave_transaction rhs_tr;
    bit same;

    if (!$cast(rhs_tr, rhs) || rhs_tr == null) begin
        comparer.print_msg("rhs is not a non-null fpt_ahb_slave_transaction");
        return 0;
    end

    same = super.do_compare(rhs, comparer);
    same &= comparer.compare_field("addr", addr, rhs_tr.addr, $bits(addr), UVM_HEX);
    same &= comparer.compare_field("direction", direction, rhs_tr.direction, $bits(direction));
    same &= comparer.compare_field("size", size, rhs_tr.size, $bits(size));
    same &= comparer.compare_field("burst", burst, rhs_tr.burst, $bits(burst));
    same &= comparer.compare_field("response", response, rhs_tr.response, $bits(response));
    same &= comparer.compare_field("wait_cycles", wait_cycles, rhs_tr.wait_cycles,
                                   $bits(wait_cycles), UVM_DEC);
    if (direction == FPT_AHB_WRITE && rhs_tr.direction == FPT_AHB_WRITE)
        same &= comparer.compare_field("write_data", write_data, rhs_tr.write_data,
                                       $bits(write_data), UVM_HEX);
    // Read data matters only for two successful READ response plans.
    if (direction == FPT_AHB_READ && rhs_tr.direction == FPT_AHB_READ &&
        response == FPT_AHB_OKAY && rhs_tr.response == FPT_AHB_OKAY)
        same &= comparer.compare_field("read_data", read_data, rhs_tr.read_data,
                                       $bits(read_data), UVM_HEX);
    return same;
endfunction : do_compare

`endif
