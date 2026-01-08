`timescale 1ns / 100ps
//
//////////////////////////////////////////////////////////////////////////////////
//
//  Filename: tb_calc.sv
//
//  Author: Mike Wirthlin
//
//  Description: Testbench for top-level calculator circuit
//
//////////////////////////////////////////////////////////////////////////////////

module tb_calc();

    //parameter numPulsesPerTest = 9;
    logic tb_clk, tb_rst, tb_op, tb_op_d;
    logic [2:0] tb_func;
    logic [15:0] tb_count;
    logic [15:0] tb_sw;
    logic [15:0] accumulator = 0;
    int initialized = 0;
    int errors = 0;
    integer random_tests = 200;
    // Enumerated type of button operations
    typedef enum logic [2:0] {
        ADD = 3'b000,
        SUB = 3'b001,
        AND = 3'b010,
        OR  = 3'b011,
        XOR = 3'b100,
        LT  = 3'b101,
        SLL = 3'b110,
        SRA = 3'b111
    } btnop_t;
    btnop_t button_op;

    typedef struct {
        btnop_t func;
        logic [15:0] sw;
    } test_t;
    test_t test_vectors [] = '{
        '{ADD, 16'hFFF3},  // Add a negative number
        '{SUB, 16'hFFF0},  // Subtract a larger magnitude number (result should be positive)
        '{LT, 16'h0000},   // Less than zero? (no, should be zero)
        '{ADD, 16'hFF32},  // Add a negative number
        '{LT, 16'h0000},   // Less than zero? (yes, should be one)
        '{SUB, 16'h7F3E},  // Subtract a large positive number (should be negative)
        '{AND, 16'h00FF},  // Mask the lower 8 bits
        '{XOR, 16'hFFFF},  // Invert all bits
        '{AND, 16'h0000},  // Clear accumulator
        '{OR, 16'hA5A5},   // Set specific pattern
        '{SRA, 16'h0001},  // Arithmetic shift right by 1
        '{SLL, 16'h0002}   // Shift left by 2
    };

    // clock generation
    initial begin
        tb_clk = 0;
        forever #5 tb_clk <= ~tb_clk; // 100MHz clock
    end
    // Instance alu module
    calc my_calc(
        .clk(tb_clk),
        .btnu(tb_rst),
        .btnl(tb_func[2]),
        .btnc(tb_func[1]),
        .btnr(tb_func[0]),
        .btnd(tb_op),
        .sw(tb_sw),
        .led(tb_count)
    );

    // Perform a simulation operation
    task automatic sim_op(input [2:0] func, logic [15:0] sw, logic op = '1);
        logic [15:0] before_val;
        btnop_t button_op;
        before_val = tb_count;
        button_op = btnop_t'(func);
        // Wait for negative edge of clock and set inputs
        @(negedge tb_clk);
        $write("[%0t] led = %04h ", $time, before_val);
        tb_func = func;
        tb_op = op;
        tb_sw = sw;
        if (op == '1) $write("btnd pressed. ");
        else $write("btnd NOT pressed. ");
        $write("sw=%04h l,c,r=%03b (%s) ", sw, button_op, button_op.name());
        // Wait a few clock cycles for the oneshot to propagate and then test the LEDs
        repeat(3) @(negedge tb_clk); 
        $display("next led = %04h", tb_count);
        if (~check_led_output()) begin
            errors = errors + 1;
`ifndef NO_END_ON_FIRST_ERROR
            $display("**** Ending simulation due to error ****");
            $finish;
`endif
        end
        // $display("[%0t]  btnd pressed. sw=%04h l,c,r=%03b : before = %04h after = %04h", $time, sw, func, before_val, tb_count);
        // Set a random value to the switches
        // tb_sw = $urandom_range(0,65535);
        @(negedge tb_clk);
        tb_op = 0;
    endtask

    function automatic logic check_led_output();
        if (initialized==0) begin
            check_led_output = 1; // Okay if not initialized
        end
        else begin
            if (^tb_count === 1'bX) begin
                check_led_output = 0;
                $display("  **** Error: 'x' Values on LEDs");
            end
            else if (tb_count !== accumulator[15:0]) begin
                check_led_output = 0;
                $display("  **** Error: LEDs should be %04h", accumulator);
            end
            else
                check_led_output = 1;
        end
    endfunction

    initial begin
        int i,j;

        //shall print %t with scaled in ns (-9), with 2 precision digits, and would print the " ns" string
        $timeformat(-9, 0, " ns", 20);
        $display("*** Start of Calculator Testbench Simulation ***");

        // Run for some time without valid inputs
        #50

        // execute a few clocks without any reset
        repeat(3) @(negedge tb_clk);

        // Issue a reset and set defaults
        $display("*** Issue Reset ***");
        tb_rst = 1;
        tb_func = 0;
        tb_op = 0;
        repeat(10) @(negedge tb_clk);
        tb_rst = 0;

        // Test random function 10 times with no button d pressed
        $display("*** Change switches without pressing BTND ***");
        for(j=0; j < 10; j=j+1)
            sim_op($urandom_range(0,7), $urandom_range(0,65535), '0);

        // Run the test vectors
        $display("*** Run test vectors ***");
        foreach (test_vectors[i])
            sim_op(test_vectors[i].func, test_vectors[i].sw);
        $display("*** Random Vectors ***");
        for(j=0; j < random_tests; j=j+1)
            sim_op($urandom_range(0,7), $urandom_range(0,65535), '1);
        $display("*** Reset and random switch/buttons ***");
        tb_rst = 1;
        repeat(5) @(negedge tb_clk);
        tb_rst = 0;
        for(j=0; j < 10; j=j+1)
            sim_op($urandom_range(0,7), $urandom_range(0,65535), '0);
        // Run the test vectors after the reset for guaranteed final result
        foreach (test_vectors[i])
            sim_op(test_vectors[i].func, test_vectors[i].sw);

        repeat(20) @(negedge tb_clk);	
        if (errors != 0) begin
            $display("*** Simulation FAILED with %0d errors. Ended at %0t *** ", errors, $time);
        end	
        else
            $display("===== TEST PASSED =====. Final count=%0h. Ended at %0t *** ", tb_count, $time);
        $finish;

    end  // end initial

    // accumulator
    assign button_op = btnop_t'(tb_func);
    always@(posedge tb_clk) begin
        tb_op_d <= tb_op;
        if (tb_rst) begin
            accumulator <= 0;
            initialized <= 1;
        end else begin
            if (tb_op_d == 0 && tb_op == 1)
                case (button_op)
                    ADD: accumulator <= accumulator + tb_sw;
                    SUB: accumulator <= accumulator - tb_sw;
                    AND: accumulator <= accumulator & tb_sw;
                    OR: accumulator <= accumulator | tb_sw;
                    XOR: accumulator <= accumulator ^ tb_sw;
                    LT: accumulator <= ($signed(accumulator) < $signed(tb_sw)) ? 32'b1 : 32'b0;
                    SLL: accumulator <= accumulator << tb_sw[4:0];
                    SRA: accumulator <= $unsigned($signed(accumulator) >>> tb_sw[4:0]);
                    default: accumulator <= accumulator + tb_sw;
                endcase
        end
    end

endmodule
