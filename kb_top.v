`timescale 1ns / 1ps
module kb_top(
	input wire clk, reset,
	input wire ps2d,ps2c,
	output wire [7:0] ascii_code
    );
	 
	// signal declaration
	reg [7:0] key_code;
	wire [7:0] ps2O;
	reg [7:0] lastKey;
	reg [7:0] count;
	wire scan_done_tick;
	
	localparam BRK = 8'hf0;
	
	reg state;

	
	
	// instantiate kb code
	ps2_rx ps2_rx_unit
      (.clk(clk), .reset(reset), .rx_en(1'b1),
       .ps2d(ps2d), .ps2c(ps2c),
       .rx_done_tick(scan_done_tick), .dout(ps2O));
	// instantiate key-to-ascii
	always @(posedge clk) begin
		if (ps2O == 8'hf0) begin
			count = 8'd0;
			state = 1;
		end
		count = count + 1;
		if (state == 1) key_code = 8'd0;
		else key_code = ps2O;
		if (count == 8'hff) state = 0;
	end
	
	key2ascii key2ascii_unit
		(.key_code(key_code),
		 .ascii_code(ascii_code)
		);
	 


endmodule
