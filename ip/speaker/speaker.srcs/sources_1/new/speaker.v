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
    output	reg s_axis_tready,
    input	s_axis_tvalid
    
    );
    
    localparam freq = (SYSCLK_FREQ_MHZ * 1000000)/ AUD_SAMPLE_FREQ_HZ;
    localparam dc_bias = (1 << DATA_WIDTH-1);
    integer clock_counter;
    reg[DATA_WIDTH-1:0] temp_data, counter;
    reg pdm_clk_rising;
    
    // assign the serialized PWM_audio signal         
    assign PWM_audio = (counter <= temp_data);
    
    assign PDM_sd = 1'b1;
    
    // Count increment for the PWM
    always @(posedge s_aclk or negedge s_aresetn)
        if(~s_aresetn | EN)
            counter <= 0;
        else
            counter <= counter + 1;
 
     // Count the number of sampled bits
    always @(posedge s_aclk or negedge s_aresetn)
        if(~s_aresetn | EN)
            s_axis_tready = 1'b0;
        else if(clock_counter == freq) 
            s_axis_tready = 1'b1;
        else
            s_axis_tready = 1'b0;
                  
    // serialize the pdm_data
    always @(posedge s_aclk or negedge s_aresetn)
        if(~s_aresetn | EN)
            temp_data <= 16'd0;
        else if(s_axis_tready && s_axis_tvalid)
             temp_data <= s_axis_tdata + dc_bias;
             
  
     // generate the pdm clock
    always @(posedge s_aclk or negedge s_aresetn) begin
        if(~s_aresetn | EN) begin
            clock_counter <= 0;
         end
         else if(clock_counter == freq) begin
            clock_counter <= 0;
         end
         else begin
            clock_counter <= clock_counter + 1; 
         end  
    end
    
    
endmodule