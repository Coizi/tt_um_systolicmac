module control_fsm (
	clk,
	rst_n,
	load_done,
	out_done,
	comp_done,
	clear,
	start,
	spi_tx_en
);
	reg _sv2v_0;
	input wire clk;
	input wire rst_n;
	input wire load_done;
	input wire out_done;
	input wire comp_done;
	output reg clear;
	output reg start;
	output reg spi_tx_en;
	reg [2:0] currState;
	reg [2:0] nextState;
	always @(posedge clk or negedge rst_n)
		if (!rst_n)
			currState <= 3'd0;
		else
			currState <= nextState;
	always @(*) begin
		if (_sv2v_0)
			;
		nextState = currState;
		clear = 1'b0;
		start = 1'b0;
		spi_tx_en = 1'b0;
		case (currState)
			3'd0:
				if (load_done)
					nextState = 3'd2;
			3'd1: begin
				clear = 1'b1;
				nextState = 3'd2;
			end
			3'd2: begin
				start = 1'b1;
				nextState = 3'd3;
			end
			3'd3: begin
				start = 1'b1;
				if (comp_done)
					nextState = 3'd4;
			end
			3'd4: begin
				spi_tx_en = 1'b1;
				if (out_done)
					nextState = 3'd0;
			end
		endcase
	end
	initial _sv2v_0 = 0;
endmodule
