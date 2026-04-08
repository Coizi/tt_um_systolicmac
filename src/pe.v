module pe (
	clk,
	rst_n,
	clear,
	start,
	a_in,
	b_in,
	a_out,
	b_out,
	acc
);
	input wire clk;
	input wire rst_n;
	input wire clear;
	input wire start;
	input wire [3:0] a_in;
	input wire [3:0] b_in;
	output wire [3:0] a_out;
	output wire [3:0] b_out;
	output reg [9:0] acc;
	reg [3:0] a_reg;
	reg [3:0] b_reg;
	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			a_reg <= 4'b0000;
			b_reg <= 4'b0000;
			acc <= 10'b0000000000;
		end
		else if (clear) begin
			acc <= 10'b0000000000;
			a_reg <= 4'b0000;
			b_reg <= 4'b0000;
		end
		else if (start) begin
			a_reg <= a_in;
			b_reg <= b_in;
			acc <= acc + (a_reg * b_reg);
		end
	assign a_out = a_reg;
	assign b_out = b_reg;
endmodule
