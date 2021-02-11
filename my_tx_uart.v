/*
 *  my_tx_uart - a simple tx uart
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
`timescale 1ns/1ps
`ifndef SYNTHESES
  `default_nettype none
`endif
module my_tx_uart(
           input clk,
           input resetn,
           input transfer,
           input [7:0] tx_data,
           output reg tx_out,
           output reg ready
       );

parameter SYSTEM_CLK_MHZ = 25;
parameter BAUDRATE = 9600;
localparam SYSTEM_CYCLES = $rtoi(SYSTEM_CLK_MHZ*$pow(10,6));
localparam WAITSTATES_BIT_WIDTH = $clog2(SYSTEM_CYCLES);
localparam [WAITSTATES_BIT_WIDTH-1:0] CYCLES_PER_SYMBOL = /*(WAITSTATES_BIT_WIDTH)'*/($rtoi(SYSTEM_CYCLES/BAUDRATE));

initial begin
    $display("SYSTEM_CLK_MHZ:\t\t", SYSTEM_CLK_MHZ);
    $display("SYSTEM_CYCLES:\t\t", SYSTEM_CYCLES);
    $display("BAUDRATE:\t\t", BAUDRATE);
    $display("CYCLES_PER_SYMBOL:\t", CYCLES_PER_SYMBOL);
    $display("WAITSTATES_BIT_WIDTH:\t", WAITSTATES_BIT_WIDTH);
end

reg [2:0] state;
reg [2:0] return_state;
reg [2:0] bit_idx;

reg [WAITSTATES_BIT_WIDTH-1:0] wait_states;

always @(posedge clk) begin

    if (resetn == 1'b0) begin
        tx_out <= 1'b1;
        state <= 0;
        ready <= 1'b0;
        bit_idx <= 0;
    end else begin

        case (state)

            0: begin /* idle */
                if (transfer) begin
                    tx_out <= 1'b0; /* start bit */

                    wait_states <= CYCLES_PER_SYMBOL;
                    return_state <= 1;
                    state <= 3;

                    ready <= 1'b0;
                end else begin
                    ready <= 1'b1;
                    tx_out <= 1'b1;
                end
            end

            1: begin
                tx_out <= tx_data[bit_idx]; /* lsb first */
                bit_idx <= bit_idx + 1;

                wait_states <= CYCLES_PER_SYMBOL;
                return_state <= &bit_idx ? 2 : 1;
                state <= 3;
            end

            2: begin
                tx_out <= 1'b1; /* stop bit */
                ready <= 1'b1;

                wait_states <= CYCLES_PER_SYMBOL;
                return_state <= 0;
                state <= 3;
            end

            3: begin /* wait states */
                wait_states <= wait_states -1;
                if (wait_states == 1) begin
                    state <= return_state;
                end
            end

            default: begin
                state <= 0;
            end

        endcase

    end
end /* !reset */

endmodule
