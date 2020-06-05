`timescale 1 ns / 1 ps

module bram_to_fft_v1_0_M00_AXIS #
	(
		// Users to add parameters here
		parameter integer WIDTH_BRAM_READ_ADDR = 12,
		parameter integer WIDTH_BRAM_READ_DATA = 16,
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
        input wire ready_to_read,
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

localparam MAX_BRAM_READS = 4096;
reg [WIDTH_BRAM_READ_ADDR:0] count;
enum {IDLE, INITIALIZING, CONVERTING} state; 

wire ready;
reg [WIDTH_BRAM_READ_DATA - 1 : 0] dbuf1, dbuf2, d;
reg validm2, validm1, valid;
reg last;
reg [1:0] n_bram_overflows;

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
	case (state)
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
                    count <= count + 1;
                    // Assign the current bram data out
                    // it aligns with the address requested
                    // 2 cycles ago, and will hopefully be trasferred
                    // next clock
                    d <= read_bram_d;
                    // Indicate that 2 cycles from now, the data is valid
                    // If the address on the bram is the next to last, then
                    // set the last flag in the pipeline next cycle, otherwise
                    // indicate that it isnt last
                    if(count == MAX_BRAM_READS + 1) begin
                        last <= 1'b1;
                        validm2 <= 0;
                        validm1 <= 0;
                        valid <= 1;
                    end
                    else begin
                        validm2 <= 1'b1;
                		validm1 <= validm2;
                		valid <= validm1;
                        last <= 1'b0;
                    end
                    // Go on to the next address, as the previous address is now in the pipe
                    read_bram_addr <= count;
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

            count <= count + 1;
            // Assign the current bram data out
            // it aligns with the address requested
            // 2 cycles ago, and will hopefully be trasferred
            // next clock (3 cycles total latency)
			d <= read_bram_d;
            // Indicate that 3 cycles from now, the data is valid
            // If the address on the bram is the last, then
            // set the last flag in the pipeline, otherwise
            // indicate that it isnt last
            if(count == MAX_BRAM_READS + 1) begin
                last <= 1'b1;
                validm2 <= 0;
                validm1 <= 0;
                valid <= 1;
            end
            else begin
                last <= 1'b0;
                validm2 <= 1'b1;
                validm1 <= validm2;
                valid <= validm1;
            end
            // Go on to the next address, as the previous address is now in the pipe
			read_bram_addr <= count;
        end
    endcase
	end 
    IDLE: begin
        count <= 0;
        validm2 <= 1;
        validm1 <= 0;
        valid <= 0;
        last <= 0;
        read_bram_addr <= 0;
        n_bram_overflows <= 0;
        dbuf1 <= 0;
        dbuf2 <= 0;
        d <= 0;
    end
    endcase
end

always @(posedge M_AXIS_ACLK) begin
	case (state)
		IDLE: begin
			if(ready_to_read)
				state <= CONVERTING;
			else
				state <= IDLE;
		end
		CONVERTING: begin
			if(last)
				state <= IDLE;
			else
				state <= CONVERTING;
		end 
		default:
			state <= IDLE; 
	endcase
end

initial begin
    state <= IDLE;
    count = 0;
    validm2 = 0;
    validm1 = 0;
    valid = 0;
    last = 0;
    read_bram_addr = 0;
    n_bram_overflows = 0;
    dbuf1 = 0;
    dbuf2 = 0;
    d = 0;
end

endmodule