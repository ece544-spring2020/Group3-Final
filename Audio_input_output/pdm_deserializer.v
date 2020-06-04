`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/01/2020 11:51:01 AM
// Design Name: 
// Module Name: Microphone
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


module pdm_deserializer
#(
    parameter integer DATA_WIDTH = 16,
    parameter integer SYS_CLK_FREQ_MHZ = 100, 
    parameter integer SAMPLING_CLK_FREQ_HZ = 44100

)(
    input HCLK,
    input HRESETn,
    input EN,
    output reg data_ready,
    output reg [DATA_WIDTH-1:0] data,
    output reg pdm_clk,
    input pdm_data,
    output pdm_lrsel
    );
    
    localparam integer clockDiv = ((SYS_CLK_FREQ_MHZ * 1000000)/(2 * SAMPLING_CLK_FREQ_HZ * DATA_WIDTH)) - 1;
    
    integer clock_counter, bit_counter;
    reg[DATA_WIDTH-1:0] temp_data;
    reg pdm_clk_rising;
    
    assign pdm_lrsel = 1'b0; // select left channel
    
        // generate the pdm clock
    always @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn | ~EN) begin
            clock_counter <= 0;
            pdm_clk <= 1'b0;
            pdm_clk_rising <= 1'b0;
         end
         else if(clock_counter== clockDiv) begin
            clock_counter <= 0;
            if(pdm_clk == 1'b0)
                pdm_clk_rising <= 1'b1;
            pdm_clk <= ~pdm_clk;
         end
         else begin
            clock_counter <= clock_counter + 1; 
            pdm_clk <= pdm_clk; 
            pdm_clk_rising <= 1'b0;  
         end  
    end
    
    
    // deserialize the pdm_data and Count the number of sampled bits
    always @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn | ~EN) begin
            temp_data <= 16'd0;
            bit_counter <= 0;
         end
         else if (pdm_clk_rising) begin
            temp_data <= {temp_data[DATA_WIDTH-2: 0], pdm_data}; 
            if(bit_counter == DATA_WIDTH - 1)
                    bit_counter <= 0;
             else
                bit_counter  <= bit_counter + 1;
         end  
    end
    
    
    // assign data_ready signal and load the output data
    always @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn | ~EN) begin
            data <= 16'd0;
            data_ready <= 1'b0;
         end
         else if(bit_counter == 0) begin
            data <= temp_data;
            data_ready <= 1'b1;
         end
         else begin
            data <= data;
            data_ready <= 1'b0;    
         end  
    end
   
    
endmodule
