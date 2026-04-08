module tt_um_systolic_top (
	ui_in,
	uo_out,
	uio_in,
	uio_out,
	uio_oe,
	ena,
	clk,
	rst_n
);
	input wire [7:0] ui_in;
	output wire [7:0] uo_out;
	input wire [7:0] uio_in;
	output wire [7:0] uio_out;
	output wire [7:0] uio_oe;
	input wire ena;
	input wire clk;
	input wire rst_n;
	wire sck;
	wire mosi;
	wire cs;
	assign sck = ui_in[0];
	assign mosi = ui_in[1];
	assign cs = ui_in[2];
	assign uio_out = 8'b00000000;
	assign uio_oe = 8'b00000000;
	wire [63:0] a_in;
	wire [63:0] b_in;
	wire [159:0] acc;
	wire load_done;
	wire comp_done;
	wire spi_done;
	wire clear;
	wire start;
	wire spi_tx_en;
	wire miso;
	spi_slave u_spi_slave(
		.clk(clk),
		.rst_n(rst_n),
		.sck(sck),
		.mosi(mosi),
		.cs(cs),
		.a_out(a_in),
		.b_out(b_in),
		.load_done(load_done)
	);
	control_fsm u_control_fsm(
		.clk(clk),
		.rst_n(rst_n),
		.load_done(load_done),
		.comp_done(comp_done),
		.out_done(spi_done),
		.clear(clear),
		.start(start),
		.spi_tx_en(spi_tx_en)
	);
	systolic_array_4x4 u_systolic(
		.clk(clk),
		.rst_n(rst_n),
		.clear(clear),
		.start(start),
		.a_in(a_in),
		.b_in(b_in),
		.acc(acc),
		.comp_done(comp_done)
	);
	spi_tx u_spi_tx(
		.clk(clk),
		.rst_n(rst_n),
		.sck(sck),
		.cs(cs),
		.spi_tx_en(spi_tx_en),
		.acc(acc),
		.miso(miso),
		.spi_done(spi_done)
	);
	assign uo_out = (ena ? {4'b0000, spi_done, load_done, comp_done, miso} : 8'b00000000);
endmodule
