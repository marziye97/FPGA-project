`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:49:07 01/21/2018 
// Design Name: 
// Module Name:    top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module top(
	 input clk,
    input sw,
    input rx,
	 output [5:0] rgb,
	 output hsync,
	 output vsync
    );


wire CLK_OUT1;

wire [7:0] dout;
wire [8:0] xk_index;
wire [7:0] doutb;
wire [8:0] addrb;
wire [7:0] douta;
wire [7:0] data;
reg ce = 0;
wire [16:0] sum;
wire [7:0] xk_re;
wire [7:0] xk_im;
reg rd_en = 0;
wire dv;

reg [9:0] rd_count = 0;
reg flag = 0;
reg fwd_inv_we = 0;
reg scale_sch_we = 0;
 
wire RxD_data_ready;
wire busy;

reg wea;
reg [8:0] addra;
reg [7:0] dina;

my_dcm mdcm
   (// Clock in ports
    .CLK_IN(clk),      // IN
    // Clock out ports
    .CLK_OUT1(CLK_OUT1),     // OUT
    .CLK_OUT2(CLK_OUT2),     // OUT
    .CLK_OUT3(CLK_OUT3),     // OUT
    // Status and control signals
    .RESET(RESET),// IN
    .LOCKED(LOCKED));      // OUT
	 
/*ROM my_rom (
  .clka(CLK_OUT1), // input clka
  .addra(addra), // input [8 : 0] addra
  .douta(douta) // output [7 : 0] douta
);*/
 async_receiver uart_rec (
   .clk(CLK_OUT1), 
   .RxD(rx), 
   .RxD_data_ready(RxD_data_ready), 
   .RxD_data(data), 
   .RxD_idle(RxD_idle), 
   .RxD_endofpacket(RxD_endofpacket)
   );

/*always @ (posedge CLK_OUT1) begin
	if(addra == 511)
		addra <= 0;
	else
		addra <= addra + 1'b1;
end*/

wire [8:0]data_count;
FIFO my_fifo (
  .clk(CLK_OUT1), // input clk
  .rst(1'b0), // input rst
  .din(data),//douta), // input [7 : 0] din
  .wr_en(RxD_data_ready), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout), // output [7 : 0] dout
  .full(full), // output full
  .empty(empty), // output empty
  .data_count(data_count) // output [8 : 0] data_count
);

always @ (posedge CLK_OUT1) begin
	if(data_count == 511)begin
		rd_en <= 1'b1;
		ce<= 1'b1;
		rd_count <= 0;
	end
	if(rd_en)
		rd_count <= rd_count+1'b1;
	if(rd_count == 511) begin
		rd_en <= 0;
		rd_count <= 0;
	end
	if(xk_index == 511)
		ce <= 0;
end

reg start=0;
always @ (posedge CLK_OUT1) begin
	if(flag == 0) begin
		fwd_inv_we = 1;
		scale_sch_we = 1;
		flag = 1;
		start=1;
	end
	else if (flag == 1) begin
		fwd_inv_we = 0;
		scale_sch_we = 0;
	end
end


fourie my_fft (
  .clk(CLK_OUT1), // input clk
  .ce(ce), // input ce
  .start(start), // input start
  .unload(1'b1), // input unload
  .xn_re(dout), // input [7 : 0] xn_re
  .xn_im(0), // input [7 : 0] xn_im
  .fwd_inv(1'b1), // input fwd_inv
  .fwd_inv_we(fwd_inv_we), // input fwd_inv_we
  .scale_sch(18'b000000000000010010), // input [17 : 0] scale_sch
  .scale_sch_we(scale_sch_we), // input scale_sch_we
  .rfd(rfd), // output rfd
  .xn_index(xn_index), // output [8 : 0] xn_index
  .busy(busy), // output busy
  .edone(edone), // output edone
  .done(done), // output done
  .dv(dv), // output dv
  .xk_index(xk_index), // output [8 : 0] xk_index
  .xk_re(xk_re), // output [7 : 0] xk_re
  .xk_im(xk_im) // output [7 : 0] xk_im
);


assign sum = (xk_re*xk_re) + (xk_im*xk_im);

always @ (posedge CLK_OUT1) begin
	if(sw == 1) begin
		wea <= dv;
		addra <= xk_index;
		dina <= sum;
	end
	else begin
		wea <= rd_en;
		addra <= data_count;
		dina <= dout;
	end
end



RAM my_ram (
  .clka(CLK_OUT1), // input clka
  .wea(wea), // input [0 : 0] wea
  .addra(addra), // input [8 : 0] addra
  .dina(dina), // input [7 : 0] dina
  .douta(douta), // output [7 : 0] douta
  .clkb(CLK_OUT1), // input clkb
  .web(1'b0), // input [0 : 0] web
  .addrb(addrb), // input [8 : 0] addrb
  .dinb(dinb), // input [7 : 0] dinb
  .doutb(doutb) // output [7 : 0] doutb
);

vga_monitor my_vga (
    .clk(CLK_OUT1), 
    .len(doutb), 
    .address(addrb), 
    .hsync(hsync), 
    .vsync(vsync), 
    .rgb(rgb)
    );

endmodule
