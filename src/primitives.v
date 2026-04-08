module DFlipFlop (
	d,
	preset_L,
	reset_L,
	clk,
	q
);
	input wire d;
	input wire preset_L;
	input wire reset_L;
	input wire clk;
	output reg q;
	always @(posedge clk or negedge reset_L)
		if (~preset_L & reset_L)
			q <= 1'b1;
		else if (~reset_L & preset_L)
			q <= 1'b0;
		else if (~reset_L & ~preset_L)
			q <= 1'bx;
		else
			q <= d;
endmodule
module Synchronizer (
	async,
	clk,
	sync
);
	input wire async;
	input wire clk;
	output wire sync;
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
	clk,
	rst_n,
	en,
	count
);
	input wire clk;
	input wire rst_n;
	input wire en;
	output reg [7:0] count;
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
			count <= 8'b00000000;
		else if (en)
			count <= count + 1'b1;
endmodule
