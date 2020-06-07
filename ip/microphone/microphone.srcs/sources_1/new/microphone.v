`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/06/2020 04:44:12 PM
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


module microphone
#(
    parameter DATA_WIDTH = 16,
    parameter AUD_SAMPLE_FREQ_HZ = 44100,
    parameter SYSCLK_FREQ_MHZ    = 100,
    parameter PACKET_SIZE = 4096
)
(
    input s_aclk,
    input s_aresetn,
    input EN,
    input pdm_data,
    output pdm_lrsel,
    output reg pdm_clk,


    output reg [DATA_WIDTH-1:0] m_axis_tdata,
    output	m_axis_tlast,  
    input	m_axis_tready,
    output	reg m_axis_tvalid
    );
    
    localparam bit_freq = (SYSCLK_FREQ_MHZ * 1000000)/ (2 * AUD_SAMPLE_FREQ_HZ * DATA_WIDTH);
    localparam dc_bias = (1 << DATA_WIDTH-1);
    integer clock_counter, bit_counter, packetcounter;
    reg[DATA_WIDTH-1:0] temp_data;
    reg pdm_clk_rising;
    
    assign pdm_lrsel = 1'b0; // select left channel
    
        // generate the pdm clock
    always @(posedge s_aclk or negedge s_aresetn) begin
        if(~s_aresetn | EN) begin
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
    always @(posedge s_aclk or negedge s_aresetn) begin
        if(~s_aresetn | EN) begin
            temp_data <= 16'd0;
            bit_counter <= 0;
            m_axis_tvalid = 1'b0;
         end
         else if (pdm_clk_rising) begin
            temp_data[DATA_WIDTH - bit_counter - 1] <= pdm_data; 
            if(bit_counter == DATA_WIDTH - 1) begin
                    bit_counter <= 0;
                    m_axis_tvalid = 1'b1;
            end
            else begin
                bit_counter  <= bit_counter + 1;
                m_axis_tvalid = 1'b0;
            end
         end  
    end
    
    

    // assign data_ready signal and load the output data
    always @(posedge s_aclk or negedge s_aresetn) begin
        if(~s_aresetn | EN) begin
             m_axis_tdata <= 0;
             packetcounter <= 0;
         end
         else if(m_axis_tvalid  && m_axis_tready) begin
             m_axis_tdata <= temp_data  - dc_bias;
             if(packetcounter == PACKET_SIZE -1)
                packetcounter <= 0;
             else
                packetcounter <= packetcounter + 1;
         end 
    end
    
    assign m_axis_tlast = (packetcounter == PACKET_SIZE-1);
    
endmodule
