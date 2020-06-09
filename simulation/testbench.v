`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/07/2020 07:37:33 PM
// Design Name: 
// Module Name: testbench
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


module testbench();

    reg clk_100MHz;
    reg reset_rtl_0;

    design_1 design_1_i(
        .clk_100MHz(clk_100MHz),
        .reset_rtl_0(reset_rtl_0)
    );
    
    initial 
    begin 
        clk_100MHz = 0;
        reset_rtl_0 = 0;
    end 

    always
        #5  clk_100MHz =  !clk_100MHz;

endmodule
