module spi_slave (
	clk,
	rst_n,
	sck,
	mosi,
	cs,
	a_out,
	b_out,
	load_done
);
	input wire clk;
	input wire rst_n;
	input wire sck;
	input wire mosi;
	input wire cs;
	output reg [127:0] a_out;
	output reg [127:0] b_out;
	output reg load_done;
	wire sck_sync;
	wire mosi_sync;
	wire cs_sync;
	reg sck_prev;
	reg sck_curr;
	wire rising_edge;
	reg [7:0] shift_reg;
	reg [2:0] bit_cnt;
	reg [5:0] byte_cnt;
	reg cs_prev;
	assign rising_edge = sck_curr & ~sck_prev;
	Synchronizer s0(
		.async(sck),
		.clk(clk),
		.sync(sck_sync)
	);
	Synchronizer s1(
		.async(mosi),
		.clk(clk),
		.sync(mosi_sync)
	);
	Synchronizer s2(
		.async(cs),
		.clk(clk),
		.sync(cs_sync)
	);
	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			bit_cnt <= 3'd0;
			byte_cnt <= 6'd0;
			shift_reg <= 8'd0;
			load_done <= 1'd0;
		end
		else begin
			sck_prev <= sck_curr;
			sck_curr <= sck_sync;
			cs_prev <= cs_sync;
			if (cs_sync && !cs_prev) begin
				bit_cnt <= 3'd0;
				byte_cnt <= 6'd0;
				load_done <= 1'd0;
			end
			if (rising_edge && !cs_sync) begin
				shift_reg[7:0] <= {shift_reg[6:0], mosi_sync};
				bit_cnt <= bit_cnt + 1;
				if (byte_cnt == 32)
					load_done <= 1'b1;
				if (bit_cnt == 3'd7) begin
					byte_cnt <= byte_cnt + 1;
					if (byte_cnt == 0)
						;
					else if (byte_cnt < 17)
						a_out[(((3 - ((byte_cnt - 1) / 4)) * 4) + (3 - ((byte_cnt - 1) % 4))) * 8+:8] <= shift_reg;
					else if (byte_cnt >= 17)
						b_out[(((3 - ((byte_cnt - 17) / 4)) * 4) + (3 - ((byte_cnt - 17) % 4))) * 8+:8] <= shift_reg;
				end
			end
		end
endmodule
