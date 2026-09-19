`ifndef FPT_AHB_UTILITIES_SVH
`define FPT_AHB_UTILITIES_SVH

// Reusable utility class for AHB protocol mathematical calculations
class fpt_ahb_utilities;
    
    // Calculates the exact byte address of the next beat in an AHB burst
    static function bit [`FPT_AHB_VIP_ADDR_WIDTH-1:0] get_next_beat_addr(
        input bit [`FPT_AHB_VIP_ADDR_WIDTH-1:0] current_addr,
        input fpt_ahb_size_e                    hsize,
        input fpt_ahb_burst_e                   hburst,
        input int unsigned                      num_beats
    );
        int unsigned bytes_per_beat;
        int unsigned wrap_boundary_bytes;
        bit [`FPT_AHB_VIP_ADDR_WIDTH-1:0] wrap_lower_bound;
        bit [`FPT_AHB_VIP_ADDR_WIDTH-1:0] wrap_upper_bound;
        bit [`FPT_AHB_VIP_ADDR_WIDTH-1:0] next_addr;

        // 1. Calculate how many bytes are in a single beat (e.g. WORD = 4 bytes)
        bytes_per_beat = 1 << int'(hsize);
        
        // 2. Default assumption: Just increment the address (used for INCR and first step of WRAP)
        next_addr = current_addr + bytes_per_beat;

        // 3. Handle WRAP boundary conditions
        if (hburst inside {FPT_AHB_WRAP4, FPT_AHB_WRAP8, FPT_AHB_WRAP16}) begin
            // Total bytes in the entire wrap region (e.g. WRAP4 of WORDs = 4 * 4 = 16 bytes)
            wrap_boundary_bytes = bytes_per_beat * num_beats;
            
            // Mask out the lower bits to find the aligned starting boundary
            wrap_lower_bound = current_addr & ~(wrap_boundary_bytes - 1);
            
            // The upper boundary is simply the lower bound plus the total region size
            wrap_upper_bound = wrap_lower_bound + wrap_boundary_bytes;
            
            // If the incremented address hits the upper ceiling, wrap it back to the floor
            if (next_addr == wrap_upper_bound) begin
                next_addr = wrap_lower_bound;
            end
        end

        return next_addr;
    endfunction

endclass : fpt_ahb_utilities

`endif
