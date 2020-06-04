`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/01/2020 04:56:18 PM
// Design Name: 
// Module Name: pdm_serializer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pdm_serializer
#(
    parameter integer DATA_WIDTH = 16,
    parameter integer SYS_CLK_FREQ_MHZ = 100, 
    parameter integer SAMPLING_CLK_FREQ_HZ = 44100

)(
    input HCLK,
    input HRESETn,
    input EN,
    output reg Done,
    input [15:0] DATA,
    inout PWM_AUDIO
    );
    
    localparam integer clockDiv = ((SYS_CLK_FREQ_MHZ * 1000000)/(SAMPLING_CLK_FREQ_HZ * DATA_WIDTH)) - 1;
    
    integer clock_counter, bit_counter;
    reg[DATA_WIDTH-1:0] temp_data;
    reg pdm_clk_rising;
    
    
    // Count the number of sampled bits
    always @(posedge HCLK or negedge HRESETn)
        if(~HRESETn | ~EN)
            bit_counter <= 0;
        else if (pdm_clk_rising)
            if(bit_counter == DATA_WIDTH-1)
                bit_counter <= 16'd0;
            else
                bit_counter  <= bit_counter + 1;
  
                
    // Generate Done signal when the number of bits are serialized
    always @(posedge HCLK or negedge HRESETn)
        if(~HRESETn | ~EN)
            bit_counter <= 0;
        else if (bit_counter == DATA_WIDTH-1)
            Done <= 1'b1;
        else
            Done <= 1'b0;
    
    
                  
    // serialize the pdm_data
    always @(posedge HCLK or negedge HRESETn)
        if(~HRESETn | ~EN)
            temp_data <= 16'd0;
        else if (pdm_clk_rising)
            if (bit_counter == 0)
                 temp_data <= DATA;
            else
                 temp_data <= {temp_data[DATA_WIDTH-2:0], 1'b0};
                 
                 
     // assign the serialized PWM_audio signal 
     //The signal needs to be driven low for logic '0' and left in high-impedance for logic '1'          
     assign PWM_AUDIO = temp_data[DATA_WIDTH-1] ? 1'bz : 1'b0;
                
                
     // generate the pdm clock
    always @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn | ~EN) begin
            clock_counter <= 0;
            pdm_clk_rising <= 1'b0;
         end
         else if(clock_counter== clockDiv) begin
            clock_counter <= 0;
            pdm_clk_rising <= 1'b1;
         end
         else begin
            clock_counter <= clock_counter + 1; 
            pdm_clk_rising <= 1'b0;   
         end  
    end
    
    
endmodule
