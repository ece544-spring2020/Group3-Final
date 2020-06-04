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


module audio_output
#(
    parameter integer DATA_WIDTH = 16,
    parameter integer SYS_CLK_FREQ_MHZ = 100, 
    parameter integer SAMPLING_CLK_FREQ_HZ = 44100

)(
    input HCLK,
    input HRESETn,
    input EN,
    output [10:0] ram_addr,
    input [15:0] ping_data,
    input [15:0] pong_data,
    inout audio_signal
    );
    
    wire done;
    wire[15:0] audio_data;
    reg[11:0] addr;
    assign audio_data = addr[11] ? (ping_data + 16'h7FFF):( pong_data + 16'h7FFF);
    
    always @(done) begin
        if(done)
            addr <= addr + 12'd1;
        else
            addr <= addr;
    end
    
        
        pdm_serializer
        #(
            
            .DATA_WIDTH             (DATA_WIDTH),
            .SYS_CLK_FREQ_MHZ       (SYS_CLK_FREQ_MHZ), 
            .SAMPLING_CLK_FREQ_HZ   (SAMPLING_CLK_FREQ_HZ )
        
        )(
            .HCLK       (HCLK),
            .HRESETn    (HRESETn),
            .EN         (EN),
            .Done       (Done),
            .DATA       (audio_data),
            .PWM_AUDIO  (audio_signal)
            );
    
    
endmodule
