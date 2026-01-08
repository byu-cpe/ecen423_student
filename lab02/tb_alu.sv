`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
//
//  Filename: tb_alu.sv
//
//  Author: Mike Wirthlin
//
//////////////////////////////////////////////////////////////////////////////////

// Note for Instructor and TA's: If this testbench is modified, make sure that the exercise questions from the learning  
// suite lab report are accurate with corresponding the simulation timing and answer. 

module tb_alu();

    logic zero;
    logic [31:0] op1, op2, result;
    logic [3:0] alu_op;

    int errors = 0;

    typedef struct {
        logic [31:0] operandA;
        logic [31:0] operandB;
    } operand_t;

    // Specific test vectors to test for all operations
    operand_t test_instructions [] = '{
        '{32'h00000000, 32'h00000000}, // Corner cases
        '{32'hFFFFFFFF, 32'hFFFFFFFF}, 
        '{32'h77777777, 32'h77777777}, 
        '{32'hFFFFFFFF, 32'h00000001}, 
        '{32'h00000001, 32'hFFFFFFFF}, 
        '{32'hFFFFFFFF, 32'h00000000}, 
        '{32'h00000000, 32'hFFFFFFFF}, 
        '{32'hAAAAAAAA, 32'h55555555}, // Bit manipulatin patterns
        '{32'h55555555, 32'hAAAAAAAA},
        '{32'h55555555, 32'hFFFF0000},
        '{32'h0000FFFF, 32'h0000FFFF},
        '{32'h00FFFF00, 32'h0000FFFF},
        '{32'hFFFF0000, 32'h0000FFFF},
        '{32'hFFFF0000, 32'h00FFFF00},
        '{32'hFFFF0000, 32'hFFFF0000},
        '{32'h7FFFFFFF, 32'h7FFFFFFF}, // Arithmetic tests. Pos/Pos
        '{32'h00000001, 32'h7FFFFFFF},
        '{32'h7FFFFFFF, 32'h00000001}, 
        '{32'h7FFFFFFF, 32'hFFFFFFFF}, // Pos/Neg
        '{32'hFFFFFFFF, 32'h7FFFFFFF}, // neg/pos
        '{32'hFFFFFFFF, 32'h80000000}, // neg/neg
        '{32'h00001234, 32'h00000000}, // Shifts
        '{32'h00001234, 32'h00000005}, 
        '{32'h00001234, 32'h0000001F}, 
        '{32'h00001234, 32'h00000020}, 
        '{32'hFFFF0000, 32'h00000000}, 
        '{32'hFFFF0000, 32'h00000005}, 
        '{32'hFFFF0000, 32'h0000001F}, 
        '{32'hFFFF0000, 32'h00000020}, 
        '{32'h39FE1CD7, 32'hDB1E0246}, // Random values
        '{32'h00000001, 32'h00000002}  // Last dummy entry
    };

    typedef enum logic [3:0] {
        AND  = 4'h0,
        OR   = 4'h1,
        ADD  = 4'h2,
        SUB  = 4'h6,
        LT   = 4'h7,        
        SRL  = 4'h8,
        SLL = 4'h9,
        SRA  = 4'hA,
        XOR  = 4'hD
    } opcode_t;

    localparam[3:0] UNDEFINED_OP1 = 4'b0100;
    localparam[3:0] UNDEFINED_OP2 = 4'b0101;
    localparam[3:0] UNDEFINED_OP3 = 4'b0011;
    localparam[3:0] UNDEFINED_OP4 = 4'b1011;
    localparam[3:0] UNDEFINED_OP5 = 4'b1100;
    localparam[3:0] UNDEFINED_OP6 = 4'b1110;
    localparam[3:0] UNDEFINED_OP7 = 4'b1111;
    localparam[3:0] ALUOP_AND = 4'b0000;
    localparam[3:0] ALUOP_OR = 4'b0001;
    localparam[3:0] ALUOP_ADD = 4'b0010;
    localparam[3:0] ALUOP_SUB = 4'b0110;
    localparam[3:0] ALUOP_LT = 4'b0111;
    localparam[3:0] ALUOP_SRL = 4'b1000;
    localparam[3:0] ALUOP_SLL = 4'b1001;
    localparam[3:0] ALUOP_SRA = 4'b1010;
    localparam[3:0] ALUOP_XOR = 4'b1101;

    // Constants for the operands of the deterministic ALU test
    localparam[31:0] OP1_VAL = 32'h12345678;
    localparam[31:0] OP2_VAL = 32'h2456fdec;
    // Number of random tests per ALU op
    localparam NUM_RANDOM_TESTS = 15;

    localparam non_specified_alu_op_tests = 2;
    localparam specified_alu_op_tests = 16;


    // Function to check if inputs are defined
    function logic [15:0] inputs_defined();
        inputs_defined = 1;
        if (^op1 === 1'bX || ^op2 === 1'bX || ^alu_op === 1'bX)
            inputs_defined = 0;
    endfunction

    // function to check if the outputs are defined
    function logic [15:0] results_defined();
        if (^result === 1'bX)
            results_defined = 0;
        else
            results_defined = 1;
    endfunction

    // Task for simulating a single ALU operation
    task sim_alu_op;
        input [3:0] operation;
        input [31:0] operand1, operand2;
        string opname;
        opcode_t op;
        op = opcode_t'(operation);
        begin
            op1 = operand1;
            op2 = operand2;
            alu_op = operation;
            #5
            $display("[%0t] %08h %s (%04b) %08h = %08h (zero=%b)", $time, op1, op.name(), 
                operation, op2, result, zero);
            #5
            ;
        end
    endtask

    // Task for simulating all ALU operations with predefined vectors
    task sim_alu_vectors;
        opcode_t op;
        begin
            for (op = op.first(); op != op.last(); op = op.next()) begin
                $display("Testing opcode = %s (0x%0h)", op.name(), op);
                foreach (test_instructions[i])
                    sim_alu_op(op,test_instructions[i].operandA,test_instructions[i].operandB);
            end            
        end
    endtask

    // Task for simulating a single ALU operation multiple times with random inputs
    task sim_alu_op_random;
        input [3:0] operation;
        input int num_tests;
        int i;
        begin
            for(i=0; i < num_tests; i=i+1) begin
                sim_alu_op(operation,$urandom,$urandom);
            end
        end
    endtask

    // Instance alu module
    alu alu_dut(.*);

    // Start of simulation
    initial begin
        int i,j,test_count;
         
        //shall print %t with scaled in ns (-9), with 2 precision digits, and would print the " ns" string
        $timeformat(-9, 0, " ns", 20);
        $display("*** Start of ALU Testbench Simulation ***");
        
        // Run for some time without valid inputs
        #50
        
        // Set values to all zero
        alu_op = 0;
        op1 = 0;
        op2 = 0;
        #50

        sim_alu_vectors();
        // Perform a few deterministic tests with no random inputs
        sim_alu_op(ALUOP_AND, OP1_VAL, OP2_VAL);
        sim_alu_op(ALUOP_OR, OP1_VAL, OP2_VAL);
        sim_alu_op(ALUOP_ADD, OP1_VAL, OP2_VAL);
        sim_alu_op(ALUOP_SUB, OP1_VAL, OP2_VAL);
        sim_alu_op(ALUOP_LT, OP1_VAL, OP2_VAL);
        sim_alu_op(ALUOP_SRL, OP1_VAL, OP2_VAL);
        sim_alu_op(ALUOP_SLL, OP1_VAL, OP2_VAL);
        sim_alu_op(ALUOP_SRA, OP1_VAL, OP2_VAL);
        sim_alu_op(ALUOP_XOR, OP1_VAL, OP2_VAL);

        // Test all control inputs with random stimulus
        sim_alu_op_random(ALUOP_AND, NUM_RANDOM_TESTS);
        sim_alu_op_random(ALUOP_OR, NUM_RANDOM_TESTS);
        sim_alu_op_random(ALUOP_ADD, NUM_RANDOM_TESTS);
        sim_alu_op_random(ALUOP_SUB, NUM_RANDOM_TESTS);
        sim_alu_op_random(ALUOP_LT, NUM_RANDOM_TESTS);
        sim_alu_op_random(ALUOP_SRL, NUM_RANDOM_TESTS);
        sim_alu_op_random(ALUOP_SLL, NUM_RANDOM_TESTS);
        sim_alu_op_random(ALUOP_SRA, NUM_RANDOM_TESTS);
        sim_alu_op_random(ALUOP_XOR, NUM_RANDOM_TESTS);

        if (errors != 0) begin
            $display("*** Simulation Failed ***");
            $display("  *** %0d Errors ***",errors);
            // $fatal;
        end else begin
            $display("*** Simulation Complete ***");
            $display("===== TEST PASSED =====");
        end
        $finish;
        
    end  // end initial

    logic expected_zero;
    assign expected_zero = (result == 0);
    // Check the zero output
    always@(alu_op, op1, op2) begin
        // Wait 5 ns after op has changed
        #5
        // See if any of the inputs are 'x'. If so, ignore
        if (inputs_defined()) begin
            if ((zero == 1'bz) || (zero == 1'bx)) begin
                $display("***Error***: Invalid 'zero' value");
                // $fatal;
                errors = errors + 1;
            end
            else begin
                if (zero != expected_zero) begin
                    $display("***Error***: Invalid 'zero' value. Received %x but expecting %x", zero, expected_zero);
                    // $fatal;
                    errors = errors + 1;
                end
            end
        end
    end


    // Check the result
    logic [31:0] expected_result;
    always@(alu_op, op1, op2) begin
        // Wait 5 ns after op has changed
        #5
        // See if any of the inputs are 'x'. If so, ignore
        if (inputs_defined()) begin
            if (!results_defined()) begin
                $display("[%0t] ****Error****: Invalid result (x's)", $time);
                // $fatal;
            end
            else begin
                case(alu_op)
                    ALUOP_AND: expected_result = op1 & op2;
                    ALUOP_OR: expected_result = op1 | op2;
                    ALUOP_ADD: expected_result = op1 + op2;
                    ALUOP_SUB: expected_result = op1 - op2;
                    ALUOP_LT: expected_result = ($signed(op1) < $signed(op2)) ? 32'd1 : 32'd0;
                    ALUOP_SRL: expected_result = op1 >> op2[4:0]; 
                    ALUOP_SLL: expected_result = op1 << op2[4:0]; 
                    ALUOP_SRA: expected_result = $unsigned($signed(op1) >>> op2[4:0]); 
                    ALUOP_XOR: expected_result = op1 ^ op2; 
                    default: expected_result = op1 + op2;
                endcase
                if (result != expected_result) begin
                    $display("[%0t] **** Error ****: Invalid 'result' value %x but expecting %x", $time, result, expected_result);
                    // $fatal;
                    errors = errors + 1;
                end
            end
        end
    end

endmodule
