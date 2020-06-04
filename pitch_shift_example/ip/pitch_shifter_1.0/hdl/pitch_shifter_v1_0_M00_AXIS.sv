
`timescale 1 ns / 1 ps

	module pitch_shifter_v1_0_M00_AXIS #
	(
		// Users to add parameters here
		parameter integer WIDTH_BRAM_READ_ADDR = 12,
		parameter integer WIDTH_BRAM_READ_DATA = 64,
		parameter integer MAX_BIN_SHIFT_WIDTH = WIDTH_BRAM_READ_ADDR,
		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
		parameter integer C_M_AXIS_TDATA_WIDTH	= 32,
		// Start count is the number of clock cycles the master will wait before initiating/issuing any transaction.
		parameter integer C_M_START_COUNT	= 32
	)
	(
		// Users to add ports here
		output reg [WIDTH_BRAM_READ_ADDR - 1 : 0] read_bram_addr,
		input wire [WIDTH_BRAM_READ_DATA - 1 : 0] read_bram_d,
		input wire ready_to_shift,
		input wire integer n_bins_to_shift,
		// User ports ends
		// Do not modify the ports beyond this line

		// Global ports
		input wire  M_AXIS_ACLK,
		// 
		input wire  M_AXIS_ARESETN,
		// Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted. 
		output wire  M_AXIS_TVALID,
		// TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
		output wire [C_M_AXIS_TDATA_WIDTH-1 : 0] M_AXIS_TDATA,
		// TSTRB is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
		output wire [(C_M_AXIS_TDATA_WIDTH/8)-1 : 0] M_AXIS_TSTRB,
		// TLAST indicates the boundary of a packet.
		output wire  M_AXIS_TLAST,
		// TREADY indicates that the slave can accept a transfer in the current cycle.
		input wire  M_AXIS_TREADY
	);

localparam MAX_CLOCKED_OUT = 4096;
reg [11:0] count;
enum {IDLE, INITIALIZING, CONVERTING} pitchshiftstate; 

wire ready;
reg [WIDTH_BRAM_READ_DATA - 1 : 0] dbuf1, dbuf2, d;
reg validm2, validm1, valid;
reg lastm2, lastm1, last;
reg repzerom2, repzerom1, repzero;
reg [1:0] n_bram_overflows;

// Signals for indexing through the data when shifting
integer idx;
integer incdec;
integer last_idx;

// Assign the outputs
assign M_AXIS_TVALID = valid;
// The upper 16 bits are zero because we're only providing real
// input to the FFT (zero out the imaginary portion)
assign M_AXIS_TDATA	= d;
assign M_AXIS_TLAST	= last;
assign M_AXIS_TSTRB	= {(C_M_AXIS_TDATA_WIDTH/8){1'b1}};
assign ready = M_AXIS_TREADY;

always @(posedge M_AXIS_ACLK) begin
    // Check the AXI-S handshake status
	case (pitchshiftstate)
	CONVERTING: begin
    case ({valid, ready})
        2'b11: begin 
            // If data is transferred, take action based on how much data
            // is accumulated (from the bram pipeline emptying)
            // when the downstream slave wasnt ready) This
            // should basically always be 0 as the downstream
            // slave should nearly always accept new data
            case (n_bram_overflows)
                2'b00: begin
                    // If there arent any in the buffer, move the pipeline
            		lastm1 <= lastm2;
            		last <= lastm1;
            		validm1 <= validm2;
            		valid <= validm1;
					repzerom1 <= repzerom2;
					repzero <= repzerom1;
                    count <= count + 1;
                    // Assign the current bram data out
                    // it aligns with the address requested
                    // 2 cycles ago, and will hopefully be trasferred
                    // next clock
                    if(repzero)
						d <= 0;
					else
        		    	d <= read_bram_d;
                    // Indicate that 2 cycles from now, the data is valid
                    validm2 <= 1'b1;
                    // If the address on the bram is the next to last, then
                    // set the last flag in the pipeline next cycle, otherwise
                    // indicate that it isnt last
                    if(count == MAX_CLOCKED_OUT - 1)
                        lastm2 <= 1'b1;
                    else
                        lastm2 <= 1'b0;
                    // Go on to the next address, as the previous address is now in the pipe
                    if((idx < 0) || (idx > last_idx)) begin
						// Send out zero instead (a couple cycles from now)
						repzerom2 <= 1'b1;
						read_bram_addr <= 0;
					end
					else begin
						repzerom2 <= 1'b0;
                        // TODO: figure out if this is going to cause problems with a bad cast
						read_bram_addr <= idx + incdec;
					end
					idx <= idx + incdec; 
                end
                2'b01: begin
                    // Only one stored value, so output the dbuf1
                    // value and make it valid
                    d <= dbuf1;
                    // then decrement the overflow count
                    n_bram_overflows <= n_bram_overflows - 1;
                    // ensure that the value is valid
                    valid <= 1'b1;
                end
                2'b10: begin
                    // Twp values stored, so output the dbuf2 value
                    // next clock should output the dbuf1 value
                    d <= dbuf2;
                    // then decrement the overflow count
                    n_bram_overflows <= n_bram_overflows - 1;
                end
                // No default statement because we better not get to 3, overflowed values.
                // That would mean that we kept moving the pipeline when data wasnt being
                // transferred.
            endcase
        end
        2'b10: begin
            // If the slave isnt ready but data is valid, then dont move the pipeline
            // and check how long we've been stalled
            case (n_bram_overflows)
                2'b00: begin
                    // This is our first stall, so the bram pipeline is moving and
                    // we need to stash the bram output so we dont lose data
                    dbuf1 <= read_bram_d;
                    // increment n_bram_overflows
                    n_bram_overflows <= n_bram_overflows + 1;
                end
                2'b01: begin
                    // We've now been stalled for two consecutive cycles so store
                    // the second bram output value, from here on we can just do
                    // nothing for further stalls since we've buffered all of the
                    // bram pipeline outputs and havent been changing the address
                    dbuf2 <= read_bram_d;
                    // Indicate that there are now two values overflowed
                    n_bram_overflows <= n_bram_overflows + 1;
                end
                // No default statement because we better not get to 3, overflowed values.
                // That would mean that we kept moving the pipeline when data wasnt being
                // transferred.
            endcase
        end
        default: begin
            // These are cases where the data isnt valid for some reason.
            // Just push the pipeline along to try to get to valid data.  Perhaps
            // we are just initializing the pipeline for the first time
            lastm1 <= lastm2;
            last <= lastm1;
            validm1 <= validm2;
            valid <= validm1;
			repzerom1 <= repzerom2;
			repzero <= repzerom1;
            count <= count + 1;
            // Assign the current bram data out
            // it aligns with the address requested
            // 2 cycles ago, and will hopefully be trasferred
            // next clock
			if(repzero)
				d <= 0;
			else
            	d <= read_bram_d;
            // Indicate that 2 cycles from now, the data is valid
            validm2 <= 1'b1;
            // If the address on the bram is the last, then
            // set the last flag in the pipeline, otherwise
            // indicate that it isnt last
            if(count == MAX_CLOCKED_OUT - 1)
                lastm2 <= 1'b1;
            else
                lastm2 <= 1'b0;
            // Go on to the next address, as the previous address is now in the pipe
			if((idx < 0) || (idx > last_idx)) begin
				// Send out zero instead (a couple cycles from now)
				repzerom2 <= 1'b1;
				read_bram_addr <= 0;
			end
			else begin
				repzerom2 <= 1'b0;
                // TODO: Check this to see the effects of the BRAM read when idx + (-1) at the end of the countdown
				read_bram_addr <= idx + incdec;
			end
			idx <= idx + incdec; 
        end
    endcase
	end
	INITIALIZING: begin
        count <= 0;
		idx <= -n_bins_to_shift;
        read_bram_addr <= -n_bins_to_shift;
        validm2 <= 1'b1;
        lastm1 <= lastm2;
        last <= lastm1;
        validm1 <= validm2;
        valid <= validm1;
		repzerom1 <= repzerom2;
		repzero <= repzerom1;
	end
    IDLE: begin
        count <= 0;
        idx <= 0;
        valid <= 0;
        //validm1 <= 0;
        //validm2 <= 0;
        repzero <= 0;
        last <= 0;
    end
    endcase
end

assign last_idx = ((MAX_CLOCKED_OUT/2) - 1) + n_bins_to_shift;

// TODO: Improve this to properly mirror the shifted result
// Procedural block to manage state
always @(posedge M_AXIS_ACLK) begin
	case (pitchshiftstate)
		IDLE: begin
			if(ready_to_shift)
				pitchshiftstate <= INITIALIZING;
			else
				pitchshiftstate <= IDLE;
		end
		INITIALIZING: begin
			pitchshiftstate <= CONVERTING;
            incdec <= 1;
		end
		CONVERTING: begin
			if(last)
				pitchshiftstate <= IDLE;
			else
				pitchshiftstate <= CONVERTING;
            if(count >= (MAX_CLOCKED_OUT/2) - 1)
                incdec <= -1;
            else
                incdec <= 1;
		end 
		default:
			pitchshiftstate <= IDLE; 
	endcase
end

initial begin
    count = 0;
	idx = 0;
    incdec = 0;
    validm2 = 1'b0;
    validm1 = 1'b0;
    valid = 1'b0;
    lastm2 = 1'b0;
    lastm1 = 1'b0;
    last = 1'b0;
    read_bram_addr = 12'h000;
    n_bram_overflows = 2'b00;
    dbuf1 = 16'h0000;
    dbuf2 = 16'h0000;
    d = 16'h0000;
	repzerom1 = 1'b0;
	repzerom2 = 1'b0;
	repzero = 1'b0;
end

endmodule
