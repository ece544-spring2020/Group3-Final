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


module pdm_serializer
#(
    parameter DATA_WIDTH = 16,
    parameter AUD_SAMPLE_FREQ_HZ = 44100,
    parameter SYSCLK_FREQ_MHZ    = 100
)
(
    input HCLK,
    input HRESETn,
    input data_valid,
    input [DATA_WIDTH-1:0] Data_in,
    output PWM_audio,
    output PDM_sd,
    output ready
    );
    
    localparam bit_freq = (SYSCLK_FREQ_MHZ * 1000000)/ (AUD_SAMPLE_FREQ_HZ * DATA_WIDTH);
    
    integer clock_counter, bit_counter;
    reg[DATA_WIDTH-1:0] temp_data;
    reg pdm_clk_rising;
    
    assign PDM_sd = 1'b1;
    assign ready = (bit_counter == 0);
    
    // Count the number of sampled bits
    always @(posedge HCLK or negedge HRESETn)
        if(~HRESETn)
            bit_counter <= 0;
        else if (pdm_clk_rising)
            if(bit_counter == DATA_WIDTH-1)
                bit_counter <= 16'd0;
            else
                bit_counter  <= bit_counter + 1;
 
                  
    // serialize the pdm_data
    always @(posedge HCLK or negedge HRESETn)
        if(~HRESETn)
            temp_data <= 16'd0;
        else if(ready)
             temp_data <= Data_in;
             
     // assign the serialized PWM_audio signal 
     //The signal needs to be driven low for logic '0' and left in high-impedance for logic '1'          
     assign PWM_audio = temp_data[DATA_WIDTH - bit_counter - 1];
                
                
     // generate the pdm clock
    always @(posedge HCLK or negedge HRESETn) begin
        if(~HRESETn) begin
            clock_counter <= 0;
            pdm_clk_rising <= 1'b0;
         end
         else if(clock_counter == bit_freq) begin
            clock_counter <= 0;
            pdm_clk_rising <= 1'b1;
         end
         else begin
            clock_counter <= clock_counter + 1; 
            pdm_clk_rising <= 1'b0;   
         end  
    end
    
    
endmodule
