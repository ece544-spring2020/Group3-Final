
`timescale 1 ns / 1 ps

module pitch_shifter_v1_0_S00_AXIS #
(
	// Users to add parameters here
	parameter integer WIDTH_BRAM_WRITE_ADDR = 12,
	parameter integer WIDTH_BRAM_WRITE_DATA = 64,
	// User parameters ends
	// Do not modify the parameters beyond this line

	// AXI4Stream sink: Data Width
	parameter integer C_S_AXIS_TDATA_WIDTH	= 64
)
(
    output reg [C_S_AXIS_TDATA_WIDTH - 1:0] bram_dout,
    output reg [WIDTH_BRAM_WRITE_ADDR - 1:0] bram_write_addr,
	output reg bram_write_en_d1,
	output reg bram_transfer_complete,

	// AXI4Stream sink: Clock
	input wire  S_AXIS_ACLK,
	// AXI4Stream sink: Reset
	input wire  S_AXIS_ARESETN,
	// Ready to accept data in
	output wire  S_AXIS_TREADY,
	// Data in
	input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] S_AXIS_TDATA,
	// Byte qualifier
	input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,
	// Indicates boundary of last packet
	input wire  S_AXIS_TLAST,
	// Data is in valid
	input wire  S_AXIS_TVALID
);
	
wire axis_tready;
// Whether we are ready to write this clock cycle
wire bram_write_en;
// A delayed write enable to go with the data which takes one cycle to clock through
reg bram_write_en_d1;
reg bram_transfer_complete;
reg [WIDTH_BRAM_WRITE_ADDR - 1:0] next_bram_wr_addr;

assign S_AXIS_TREADY = axis_tready;
assign axis_tready = 1'b1; // Always ready, master doesnt listen to it anyways
assign bram_write_en = S_AXIS_TVALID && axis_tready;

always @(posedge S_AXIS_ACLK) begin
	// If the incoming data is valid (and we're ready for it)
	// then write it to the BRAM.
	if(bram_write_en) begin
		bram_write_addr <= next_bram_wr_addr;
		bram_dout <= S_AXIS_TDATA;

		// If the incoming data says this is the last value
		// then set the next address to 0 so that we start
		// from the beginning again next time the data is
		// valid (next computational cycle)
		if(S_AXIS_TLAST)
			next_bram_wr_addr <= 0;
		else
			next_bram_wr_addr <= next_bram_wr_addr + 1;
	end
	bram_transfer_complete <= S_AXIS_TLAST;
	// If the data coming in isnt valid or ready then just do nothing
	// except move along the write enable incase this is the clock cycle
	// following last, and the last word still needs to be clocked in. 

	// Delay the write enable by one so that it always
	// matches up with the data.
	bram_write_en_d1 <= bram_write_en;
end

initial begin
	bram_dout = 0;
	bram_write_addr = 0;
	bram_write_en_d1 = 1'b0;
	bram_transfer_complete = 1'b0;
	next_bram_wr_addr = 1'b0;
end

endmodule
