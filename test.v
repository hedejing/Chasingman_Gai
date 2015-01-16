`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   19:43:27 01/05/2015
// Design Name:   game_controller
// Module Name:   F:/bomb/test.v
// Project Name:  bomb
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: game_controller
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module test;

	// Inputs
	reg clk;
	reg reset_n;
	reg iVS;
	reg [7:0] iKEY;
	reg change;

	// Outputs
	wire [1:0] oBkg_sel;
	wire [2:0] oObjRam_addr;
	wire [12:0] oObjRam_data;
	wire oObjRam_we;
	initial forever begin 
		clk = 1;
		#10;
		clk = 0;
		#10;
	end
	// Instantiate the Unit Under Test (UUT)
	game_controller uut (
		.clk(clk), 
		.reset_n(reset_n), 
		.iVS(iVS), 
		.iKEY(iKEY), 
		.change(change), 
		.oBkg_sel(oBkg_sel), 
		.oObjRam_addr(oObjRam_addr), 
		.oObjRam_data(oObjRam_data), 
		.oObjRam_we(oObjRam_we)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		reset_n = 0;
		iVS = 0;
		iKEY = 0;
		change = 0;

		// Wait 100 ns for global reset to finish
		#100;
		
		iKEY = 8'b00010000;
		#20;
		
		iKEY = 8'B00100000;
		#20;
        
		// Add stimulus here

	end
      
endmodule

