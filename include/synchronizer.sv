`timescale 1 ns / 1 ps

/***************************************************************************
*
* File: synchronizer.sv
*
* Author: Professor Mike Wirthlin
* Class: ECEN 423
*
* Module: synchronizer
*
****************************************************************************/

module synchronizer(clk, rst, in, out);

    input wire logic clk, rst, in;
    output logic out;

    logic in_d;

    // The following always block creates a "synchronizer" for and asynchronous input.
    // A synchronizer synchronizes the asynchronous input to the global clock.
    // This particular synchronizer is just two flip-flop in series.
    // You should always have a synchronizer on
    // any button input if they are used in a sequential circuit.
    always_ff@(posedge clk)
        if (rst) begin
            in_d <= 0;
            out <= 0;
        end
        else begin
            in_d <= in;
            out <= in_d;
        end

endmodule
