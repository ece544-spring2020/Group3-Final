`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/03/2020 01:29:12 PM
// Design Name: 
// Module Name: audio_sampler
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


module audio_sampler
#(
    parameter integer DATA_WIDTH = 16,
    parameter integer SYS_CLK_FREQ_MHZ = 100, 
    parameter integer SAMPLING_CLK_FREQ_HZ = 44100

)(
    input HCLK,
    input HRESETn,
    input EN,
    output [10:0] ram_addr,
    output [15:0] ram_data_i,
    output ping_we,
    output pong_we

    );
    
    wire data_ready;
    reg[11:0] addr;
    reg[15:0] audio_data;
    assign ram_addr = addr[10:0];
    assign ping_we = addr[11] & data_ready;
    assign pong_we = ~addr[11] & data_ready;
    assign ram_data_i = audio_data - 16'h7FFF;
    
    always @(data_ready) begin
        if(data_ready)
            addr <= addr + 12'd1;
        else
            addr <= addr;
    end
    
    
     pdm_deserializer
    #(
        .DATA_WIDTH (DATA_WIDTH),
        .SYS_CLK_FREQ_MHZ(SYS_CLK_FREQ_MHZ), 
        .SAMPLING_CLK_FREQ_HZ(SAMPLING_CLK_FREQ_HZ )
    
    )deserializer (
        .HCLK       (HCLK),
        .HRESETn    (HRESETn),
        .EN         (EN),
        .data_ready (data_ready),
        .data       (audio_data),
        .pdm_clk    (pdm_clk),
        .pdm_data   (pdm_data),
        .pdm_lrsel  (pdm_lrsel)
        );
    
    
endmodule
