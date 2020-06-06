`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/05/2020 12:12:53 PM
// Design Name: 
// Module Name: microphone
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
    parameter DATA_WIDTH = 16,
    parameter AUD_SAMPLE_FREQ_HZ = 44100,
    parameter SYSCLK_FREQ_MHZ    = 100
)
(
    input HCLK,
    input HRESETn,
    input pdm_data,
    output pdm_lrsel,
    output reg pdm_clk,
    output reg [DATA_WIDTH-1:0] audio_data,
    output reg data_valid
    );
    
    localparam bit_freq = (SYSCLK_FREQ_MHZ * 1000000)/ (2 * AUD_SAMPLE_FREQ_HZ * DATA_WIDTH);
    integer clock_counter, bit_counter;
    reg[DATA_WIDTH-1:0] temp_data;
    reg pdm_clk_rising;
    
    assign pdm_lrsel = 1'b0; // select left channel
    
        // generate the pdm clock
    always @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            clock_counter <= 0;
            pdm_clk <= 1'b0;
            pdm_clk_rising <= 1'b0;
         end
         else if(clock_counter == bit_freq) begin
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
        if(~HRESETn) begin
            temp_data <= 16'd0;
            bit_counter <= 0;
         end
         else if (pdm_clk_rising) begin
            temp_data[DATA_WIDTH - bit_counter - 1] <= pdm_data; 
            if(bit_counter == DATA_WIDTH - 1)
                    bit_counter <= 0;
             else
                bit_counter  <= bit_counter + 1;
         end  
    end
    
    
    // assign data_ready signal and load the output data
    always @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            audio_data <= 0;
            data_valid <= 1'b0;
         end
         else if(bit_counter == 0) begin
            audio_data <= temp_data;
            data_valid <= 1'b1;
         end
         else begin
            audio_data <= audio_data;
            data_valid <= 1'b0;    
         end  
    end
endmodule

