`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/06/2020 04:47:18 PM
// Design Name: 
// Module Name: speaker
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


module speaker
#(
    parameter DATA_WIDTH = 16,
    parameter AUD_SAMPLE_FREQ_HZ = 44100,
    parameter SYSCLK_FREQ_MHZ    = 100
)
(
    input s_aclk,
    input s_aresetn,
    input EN,
    output PWM_audio,
    output PDM_sd,

    input [DATA_WIDTH-1:0] s_axis_tdata,
    input	s_axis_tlast,  //unused
    output	s_axis_tready,
    input	s_axis_tvalid
    
    );
    
    localparam bit_freq = (SYSCLK_FREQ_MHZ * 1000000)/ (AUD_SAMPLE_FREQ_HZ * DATA_WIDTH);
    localparam dc_bias = (1 << DATA_WIDTH-1);
    
    integer clock_counter, bit_counter;
    reg[DATA_WIDTH-1:0] temp_data;
    reg pdm_clk_rising;
    
    assign PDM_sd = 1'b1;
    assign s_axis_tready = (bit_counter == 0);
    
    // Count the number of sampled bits
    always @(posedge s_aclk or negedge s_aresetn)
        if(~s_aresetn | EN)
            bit_counter <= 0;
        else if (pdm_clk_rising)
            if(bit_counter == DATA_WIDTH-1)
                bit_counter <= 16'd0;
            else
                bit_counter  <= bit_counter + 1;
 
                  
    // serialize the pdm_data
    always @(posedge s_aclk or negedge s_aresetn)
        if(~s_aresetn | EN)
            temp_data <= 16'd0;
        else if(s_axis_tready && s_axis_tvalid)
             temp_data <= s_axis_tdata + dc_bias;
             
     // assign the serialized PWM_audio signal         
     assign PWM_audio = temp_data[DATA_WIDTH - bit_counter - 1];
                
                
     // generate the pdm clock
    always @(posedge s_aclk or negedge s_aresetn) begin
        if(~s_aresetn | EN) begin
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