module spi_tx (
	clk,
	rst_n,
	sck,
	cs,
	spi_tx_en,
	acc,
	miso,
	spi_done
);
	input wire clk;
	input wire rst_n;
	input wire sck;
	input wire cs;
	input wire spi_tx_en;
	input wire [319:0] acc;
	output wire miso;
	output reg spi_done;
	reg sck_curr;
	reg sck_prev;
	reg cs_prev;
	wire cs_curr;
	wire sck_sync;
	wire cs_sync;
	wire falling_edge;
	reg [2:0] bit_cnt;
	reg [3:0] byte_cnt;
	reg [15:0] shift_reg;
	assign falling_edge = ~sck_curr & sck_prev;
	Synchronizer s0(
		.async(sck),
		.clk(clk),
		.sync(sck_sync)
	);
	Synchronizer s1(
		.async(cs),
		.clk(clk),
		.sync(cs_sync)
	);
	assign miso = shift_reg[15];
	always @(posedge clk or negedge rst_n)
		if (!rst_n) begin
			bit_cnt <= 3'd0;
			byte_cnt <= 4'd0;
			shift_reg <= 16'd0;
			spi_done <= 1'b0;
		end
		else begin
			sck_prev <= sck_curr;
			sck_curr <= sck_sync;
			cs_prev <= cs_sync;
			if (cs_sync && !cs_prev) begin
				bit_cnt <= 3'd0;
				byte_cnt <= 4'd0;
			end
			if ((falling_edge && !cs_sync) && spi_tx_en) begin
				shift_reg[15:0] <= {shift_reg[14:0], 1'd0};
				bit_cnt <= bit_cnt + 1;
				if (bit_cnt == 0)
					shift_reg <= acc[((((3 - (byte_cnt / 4)) * 4) + (3 - (byte_cnt % 4))) * 20) + 15-:16];
				else
					shift_reg <= {shift_reg[14:0], 1'b0};
				if (bit_cnt == 7)
					byte_cnt <= byte_cnt + 1;
				if ((bit_cnt == 7) && (byte_cnt == 15))
					spi_done <= 1'b1;
			end
		end
endmodule
