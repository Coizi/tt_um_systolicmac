module systolic_array_4x4 (
	clk,
	rst_n,
	clear,
	start,
	a_in,
	b_in,
	acc,
	comp_done
);
	input wire clk;
	input wire rst_n;
	input wire clear;
	input wire start;
	input wire [63:0] a_in;
	input wire [63:0] b_in;
	output wire [159:0] acc;
	output wire comp_done;
	wire [3:0] a_wire [0:3][0:3];
	wire [3:0] b_wire [0:3][0:3];
	wire [3:0] boundary_a [3:0];
	wire [3:0] boundary_b [3:0];
	reg [3:0] cnt;
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
			cnt <= 4'd0;
		else if (clear)
			cnt <= 4'd0;
		else if (start)
			cnt <= cnt + 4'd1;
	genvar _gv_k_1;
	generate
		for (_gv_k_1 = 0; _gv_k_1 < 4; _gv_k_1 = _gv_k_1 + 1) begin : gen_boundary_a
			localparam k = _gv_k_1;
			assign boundary_a[k] = ((cnt >= k) && ((cnt - k) < 4) ? a_in[(((3 - k) * 4) + (3 - (cnt - k))) * 4+:4] : 4'd0);
		end
		for (_gv_k_1 = 0; _gv_k_1 < 4; _gv_k_1 = _gv_k_1 + 1) begin : gen_boundary_b
			localparam k = _gv_k_1;
			assign boundary_b[k] = ((cnt >= k) && ((cnt - k) < 4) ? b_in[(((3 - (cnt - k)) * 4) + (3 - k)) * 4+:4] : 4'd0);
		end
	endgenerate
	assign comp_done = cnt == 4'd9;
	genvar _gv_i_1;
	genvar _gv_j_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < 4; _gv_i_1 = _gv_i_1 + 1) begin : gen_row
			localparam i = _gv_i_1;
			for (_gv_j_1 = 0; _gv_j_1 < 4; _gv_j_1 = _gv_j_1 + 1) begin : gen_col
				localparam j = _gv_j_1;
				pe leaf(
					.clk(clk),
					.rst_n(rst_n),
					.clear(clear),
					.start(start),
					.a_in((j == 0 ? boundary_a[i] : a_wire[i][j - 1])),
					.b_in((i == 0 ? boundary_b[j] : b_wire[i - 1][j])),
					.a_out(a_wire[i][j]),
					.b_out(b_wire[i][j]),
					.acc(acc[(((3 - i) * 4) + (3 - j)) * 10+:10])
				);
			end
		end
	endgenerate
endmodule
