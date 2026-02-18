`timescale 1ns / 100ps
//
//////////////////////////////////////////////////////////////////////////////////
//
//  Filename: tb_multicycle_io.v
//
//  Author: Mike Wirthlin
//  
//////////////////////////////////////////////////////////////////////////////////

module tb_multicycle_io 
	#(
		parameter TEXT_MEM = "multicycle_iosystem_text.mem",
		parameter DATA_MEM = ""
	);
	localparam WAIT_INST = 100;
	logic tb_clk, tb_btnc, tb_btnu, tb_btnd, tb_btnl, tb_btnr;
	logic [15:0] tb_sw, tb_led;
	logic [3:0] tb_an;
	logic [6:0] tb_seg;
	logic tb_dp;
	logic tb_RsTx = 1;  // UART not active

	// Clock
	initial begin
			tb_clk = 0;
			forever #5 tb_clk <= ~tb_clk; // 100MHz
	end

	task automatic wait_instructions(input int num_instructions);
		repeat (num_instructions * 5) @(negedge tb_clk);
	endtask

	task error();
		// Provide some delay after error so that you don't have to look at end of waveform
		wait_instructions(1);
		$finish("Exiting with error");
	endtask;

	task buttons_off;
		tb_btnc = 0;
		tb_btnu = 0;
		tb_btnd = 0;
		tb_btnl = 0;
		tb_btnr = 0;
	endtask

	task automatic test_switches(input logic [15:0] sw_val);
		// Set the switches with no buttons pressed and see if LEDs follow
		tb_sw = sw_val;
		wait_instructions(WAIT_INST);
		if (tb_led != tb_sw) begin
			$display("**** LEDs did not update with changes in switches");
			error();
		end
	endtask
	
	task automatic test_btnd(input logic [15:0] sw_val);
		// # Check button D: turn LEDs off
		tb_sw = sw_val;
		tb_btnd = 1;
		wait_instructions(WAIT_INST);
		if (tb_led != 0) begin
			$display("**** LEDs did not turn off with BTND");
			error();
		end
		tb_btnd = 0;
	endtask

	task automatic test_btnu(input logic [15:0] sw_val);
			// 	# Button U pressed - write ffff to LEDs (turn them on)
			tb_sw = sw_val;
			tb_btnu = 1;
			wait_instructions(WAIT_INST);
			if (tb_led != 16'hffff) begin
				$display("**** LEDs did not turn on with BTNU");
				error();
			end
			tb_btnu = 0;
	endtask

	task automatic test_btnr(input logic [15:0] sw_val);
		// 	# Check button R: Invert switches when displaying on LEDs
		tb_sw = sw_val;
		tb_btnr = 1;
		wait_instructions(WAIT_INST);
		if (tb_led != ~tb_sw) begin
			$display("**** LEDs did not invert with BTNR");
			error();
		end
		tb_btnr = 0;
	endtask
 
	task automatic test_btnl(input logic [15:0] sw_val);
		tb_sw = sw_val;
		tb_btnl = 1;
		wait_instructions(WAIT_INST);
		if (tb_led != tb_sw << 1) begin
			$display("**** LEDs did not shift with BTNL");
			error();
		end
	endtask

	initial begin
			$timeformat(-9, 0, " ns", 20);

			buttons_off();
			tb_sw = 0;
			// Startup delay
			wait_instructions(120);

			// Change the switchces and observe LEDs
			$display("Test #1: change switches");
			test_switches(16'ha5a5);
			$display("Test #2: BTNL: Shift LEDs left");
			test_btnl(16'h00ff);
			$display("Test #3: BTNR: Invert LEDs");
			test_btnr(16'hff00);
			$display("Test #4: BTNU: Turn LEDs on");
			test_btnu(16'h0ff0);
			$display("Test #5: BTND: Turn LEDs off");
			test_btnd(16'hf00f);
			
			$display("===== TEST PASSED =====");
			$finish;
	end

	// Instance system
	multicycle_iosystem #(.TEXT_MEM(TEXT_MEM),
			.DATA_MEM(DATA_MEM),.USE_DEBOUNCER(0))
	riscv(.clk(tb_clk), 
			.btnc(tb_btnc), .btnd(tb_btnd), .btnl(tb_btnl), .btnr(tb_btnr), .btnu(tb_btnu), 
			.sw(tb_sw), .led(tb_led),
			.an(tb_an), .seg(tb_seg), .dp(tb_dp), 
			.RsRx(), .RsTx(tb_RsTx), 
			.vgaBlue(), .vgaGreen(), .vgaRed(), .Hsync(), .Vsync()
	);

endmodule