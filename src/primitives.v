module DFlipFlop (
	input wire d,
	input wire preset_L,
	input wire reset_L,
	input wire clk,
	output reg q
);
	always @(posedge clk or negedge reset_L)
		if (~reset_L)
			q <= 1'b0;
		else
			q <= d;
endmodule

module Synchronizer (
	input wire async,
	input wire clk,
	output wire sync
);
	wire metastable;
	DFlipFlop one(
		.d(async),
		.q(metastable),
		.clk(clk),
		.preset_L(1'b1),
		.reset_L(1'b1)
	);
	DFlipFlop two(
		.d(metastable),
		.q(sync),
		.clk(clk),
		.preset_L(1'b1),
		.reset_L(1'b1)
	);
endmodule

module Counter (
	input wire clk,
	input wire rst_n,
	input wire en,
	output reg [7:0] count
);
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
			count <= 8'b00000000;
		else if (en)
			count <= count + 1'b1;
endmodule