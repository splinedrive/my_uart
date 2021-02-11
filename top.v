/*
 *  uart top- a simple uart rx/tx loopback
 *
 *  copyright (c) 2021  hirosh dabui <hirosh@dabui.de>
 *
 *  permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  the software is provided "as is" and the author disclaims all warranties
 *  with regard to this software including all implied warranties of
 *  merchantability and fitness. in no event shall the author be liable for
 *  any special, direct, indirect, or consequential damages or any damages
 *  whatsoever resulting from loss of use, data or profits, whether in an
 *  action of contract, negligence or other tortious action, arising out of
 *  or in connection with the use or performance of this software.
 *
 */
`include "my_tx_uart.v"
`include "my_rx_uart.v"
`ifdef SYNTHESES
module top(input clk25,
           input uart_rx,
           output uart_tx,
           output reg [7:0] led,
           output reg [3:0] led1 = 4'b1001
          );

assign uart_tx = tx_out;
assign rx_in = uart_rx;
`else
`default_nettype none
module top_tb;
`endif

localparam BAUDRATE=3_000_000;
localparam SYSTEM_CLK_MHZ=50;

`ifndef SYNTHESES
reg clk25 = 0;
always #5 clk25 = ~clk25;
initial
begin
    $dumpfile("top.vcd");
    $dumpvars(0, top_tb);
    //$dumpoff;
    $dumpon;

    repeat(80000) @(posedge clk);
    $finish();
end
`endif

//wire clk = clk25;

wire locked;
pll pll_i(clk25, clk, locked);

reg [5:0] reset_counter = 0;
wire resetn = &reset_counter;
always @(posedge clk) begin
    reset_counter <= reset_counter + !resetn;
end

reg transfer = 0;
reg [7:0] tx_data = 0;
wire tx_out;
wire tx_ready;

my_tx_uart #(SYSTEM_CLK_MHZ, BAUDRATE) my_tx_uart_i(.clk(clk),
           .resetn(resetn), .transfer(transfer),
           .tx_data(tx_data), .tx_out(tx_out), .ready(tx_ready));

wire rx_in;
wire rx_valid;
wire [7:0] rx_data;
wire error;

my_rx_uart #(SYSTEM_CLK_MHZ, BAUDRATE) my_rx_uart_i(.clk(clk),
           .resetn(resetn), .rx_in(rx_in),
           .error(error), .valid(rx_valid), .rx_data(rx_data));

//assign led = {0, 0, 0, tx_in, rx_in, error, rx_valid, tx_ready};
reg [0:31] count = 0;
wire tick = (count == SYSTEM_CLK_MHZ * 1000_0);
always @(posedge clk) begin
    count <= (tick) ? 0 : count + 1;
end

reg [0:31] count1 = 0;
wire tick1 = (count1 == SYSTEM_CLK_MHZ * 1000_000);
always @(posedge clk) begin
    count1 <= (tick1) ? 0 : count1 + 1;
end

always @(posedge clk) begin
    if (tick) begin
        led <= tx_data;
    end

    if (tick1) begin
        led1 <= led1 ^ 4'b1111;
    end
end

always @(posedge clk) begin
    if (tx_ready) begin
        transfer <= rx_valid;
        tx_data <= rx_data;
    end
end

endmodule
    /**
     * PLL configuration
     *
     * This Verilog module was generated automatically
     * using the icepll tool from the IceStorm project.
     * Use at your own risk.
     *
     * Given input frequency:        25.000 MHz
     * Requested output frequency:   50.000 MHz
     * Achieved output frequency:    50.000 MHz
     */

    module pll(
        input  clock_in,
        output clock_out,
        output locked
    );

SB_PLL40_CORE #(
                  .FEEDBACK_PATH("SIMPLE"),
                  .DIVR(4'b0000),         // DIVR =  0
                  .DIVF(7'b0011111),      // DIVF = 31
                  .DIVQ(3'b100),          // DIVQ =  4
                  .FILTER_RANGE(3'b010)   // FILTER_RANGE = 2
              ) uut (
                  .LOCK(locked),
                  .RESETB(1'b1),
                  .BYPASS(1'b0),
                  .REFERENCECLK(clock_in),
                  .PLLOUTCORE(clock_out)
              );

endmodule

