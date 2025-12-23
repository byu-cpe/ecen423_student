//////////////////////////////////////////////////////////////////////////////////
// UpDownButtonCount_tb testbench
//////////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 100 ps 

module UpDownButtonCount_tb ();

    logic clk, btnc, btnu, btnd, btnl, btnr;
    logic [15:0] led;
    logic [15:0] sw;

    integer error = 0;

    // ButtonCount DUT
    UpDownButtonCount dut (.*);

    //////////////////////////////////////////////////////////////////////////////////
    // Clock Generator
    //////////////////////////////////////////////////////////////////////////////////
    always
    begin
        clk <= 1'b0;
        forever #5ns clk = ~clk;
    end

    // Check the led value against expected value
    task check_led(logic [15:0] expected_led);
        if (led !== expected_led ) begin
            $display(" - ERROR. Expected %h, got %h", expected_led, led);
            error = error + 1;
        end
        else if ($isunknown(led)) begin
            $display(" - ERROR. LED is unknown");
            error = error + 1;
        end
        else begin
            $display(" - OK. LED is %h as expected", led);
        end
    endtask

    // Press btnu to increment by 1
    task automatic inc_1();
        logic [15:0] cur_count = led;
        @(negedge clk);
        $write("[%0t] Pressing BTNU", $time);
        btnu = 1;
        repeat (4) @(negedge clk);
        btnu = 0;
        check_led(cur_count + 1);
    endtask

    // Press btnd to decrement by 1
    task automatic dec_1();
        logic [15:0] cur_count = led;
        @(negedge clk);
        btnd = 1;
        $write("[%0t] Pressing BTND", $time);
        repeat (4) @(negedge clk);
        btnd = 0;
        check_led(cur_count - 1);
    endtask

    // Press btnl to increment by switch value
    task automatic inc_sw(logic [15:0] sw_value);
        logic [15:0] cur_count = led;
        @(negedge clk);
        btnl = 1;
        sw = sw_value;
        $write("[%0t] Pressing BTNL (sw=%0h)", $time, sw_value);
        repeat (4) @(negedge clk);
        btnl = 0;
        check_led(cur_count + sw_value);
    endtask

    // Press btnr to decrement by switch value
    task automatic dec_sw(logic [15:0] sw_value);
        logic [15:0] cur_count = led;
        @(negedge clk);
        btnr = 1;
        sw = sw_value;
        $write("[%0t] Pressing BTNR (sw=%0h)", $time, sw_value);
        repeat (4) @(negedge clk);
        btnr = 0;
        check_led(cur_count - sw_value);
    endtask

    task automatic button_event();
        case($urandom()%4)
            0: inc_1();
            1: dec_1();
            2: inc_sw($urandom_range(0,16'hffff));
            3: dec_sw($urandom_range(0,16'hffff));
        endcase
        repeat ($urandom_range(0,16)) @(negedge clk);
    endtask

    //////////////////////////////////
    // Main Test Bench Process
    //////////////////////////////////
    initial begin
        $display("===== ButtonCount Testbench =====");

        // Simulate some time with no stimulus/reset
        #100ns
        // Set switch defaults
        btnu = 0;
        btnd = 0;
        btnl = 0;
        btnr = 0;
        btnc = 0;
        sw = 0;
        #100ns

        // Reset
        $display("[%0t] Reset", $time);
        btnc = 1;
        #80ns;
        @(negedge clk)
        $display("[%0t] LED is %h", $time, led);
        btnc = 0;

        for (int i = 0; i < 100; i++)
            button_event();

        if (error == 0)
            $display("===== TEST PASSED =====");
        else
            $display("===== TEST FAILED with %0d errors =====", error);
        $finish;
    end

endmodule
