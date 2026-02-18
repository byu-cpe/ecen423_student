`timescale 1ns / 100ps
//
//////////////////////////////////////////////////////////////////////////////////
//
//  Filename: tb_riscv_pipeline.sv
//
//  Author: Mike Wirthlin
//  
//////////////////////////////////////////////////////////////////////////////////

module tb_riscv_pipeline #(
    logic [31:0] TEXT_ADDRESS = 32'h00003000,
    logic [31:0] DATA_ADDRESS = 32'h00000000,
    string TEXT_MEM = "pipeline_nop_text.mem",
    string DATA_MEM = "pipeline_nop_data.mem",
    int MAX_INSTRUCTION_COUNT = 2000
    ) ();

    import tb_riscv_pkg::*;

    // Testbench global signals
    logic clk, rst;
    // DUT input signals (used by DUT)
    logic [31:0] tb_instruction, tb_PC, tb_ALUResult, tb_Address, tb_dWriteData;
    logic [31:0] tb_dReadData, tb_WriteBackData;
    logic tb_MemRead, tb_MemWrite;

    // clock generation
    initial begin
        clk = 0;
        forever #5 clk <= ~clk; // 100MHz
    end

    // Instance student pipeline processor
    riscv_basic_pipeline #(.INITIAL_PC(TEXT_ADDRESS))
    riscv(.clk(clk), .rst(rst), .instruction(tb_instruction), .PC(tb_PC),
        .ALUResult(tb_ALUResult), .dAddress(tb_Address), .dWriteData(tb_dWriteData),
        .dReadData(tb_dReadData),
        .MemRead(tb_MemRead), .MemWrite(tb_MemWrite), .WriteBackData(tb_WriteBackData) );

    riscv_pipeline_model #(.TEXT_MEM(TEXT_MEM), .DATA_MEM(DATA_MEM), .TEXT_ADDRESS(TEXT_ADDRESS), 
        .DATA_ADDRESS(DATA_ADDRESS))
    riscv_model(.clk(clk), .rst(rst), .tb_PC(tb_PC), .tb_Instruction(tb_instruction), .tb_ALUResult(tb_ALUResult),
        .tb_dAddress(tb_Address), .tb_dWriteData(tb_dWriteData), .tb_dReadData(tb_dReadData),
        .tb_WriteBackData(tb_WriteBackData), .tb_MemRead(tb_MemRead), .tb_MemWrite(tb_MemWrite)
    );

    initial begin

        //shall print %t with scaled in ns (-9), with 2 precision digits, and would print the " ns" string
        $timeformat(-9, 0, " ns", 20);
        $display("*** Start of RISC-V Pipeline Simulation (Lab 8) ***");

        // Initialize the inputs
        repeat(3) @(negedge clk);
        rst = 1;
        repeat(3) @(negedge clk);
        rst = 0;

        while(^tb_instruction === 1'bX || tb_instruction != riscv_instr::EBREAK_INSTRUCTION) begin
            @(negedge clk);
            if (riscv_model.errors != 0) begin
                $display("*** Simulation stopped due to error @ %0t *** ", $time);
                $finish;
            end
            if (riscv_model.instruction_count >= MAX_INSTRUCTION_COUNT) begin
                $display("*** Simulation stopped due to max instruction count (%0d) @ %0t *** ",
                    MAX_INSTRUCTION_COUNT, $time);
                $finish;
            end
        end

        $display("*** Simulation done @ %0t - %0d instructions *** ", $time, riscv_model.instruction_count);
        if (riscv_model.errors == 0)
            $display("===== TEST PASSED =====");
        else
            $display("===== TEST FAILED =====");

        $finish;

    end  // end initial
    
endmodule

// This model simulates the datapath and generates the control signals for testing.
module riscv_pipeline_model #(
    string TEXT_MEM = "",
    string DATA_MEM = "",
    logic [31:0] TEXT_ADDRESS = 32'h00200000,
    logic [31:0] DATA_ADDRESS = 32'h00000000,
    int MAX_TEXT_SIZE = 4096,
    int MAX_DATA_SIZE = 1024
    ) 
    (
    input logic clk,
    input logic rst,
    input [31:0] tb_PC,
    output [31:0] tb_Instruction,
    input [31:0] tb_ALUResult,
    input [31:0] tb_dAddress,
    input [31:0] tb_dWriteData,
    output [31:0] tb_dReadData,
    input [31:0] tb_WriteBackData,
    input tb_MemRead, tb_MemWrite
    );

    import tb_riscv_pkg::*;
    riscv_regfile regfile;

    logic [31:0] instruction_id;
    logic [31:0] if_PC, id_PC, ex_PC, mem_PC, wb_PC, if_PC_next;
    logic [31:0] ex_alu_result, mem_alu_result, wb_alu_result, mem_dAddress;
    logic [31:0] ex_readData1, ex_readData2, mem_readData2, mem_dWriteData;
    logic [31:0] wb_readData_i, wb_writedata;
    logic [31:0] b_operand;
    logic ex_alu_zero, mem_alu_zero, wb_alu_zero;
    riscv_instr id_inst, ex_inst, mem_inst, wb_inst;
    riscv_simple_control ex_riscv_ctrl, mem_riscv_ctrl, wb_riscv_ctrl;
    logic MemRead_i, MemWrite_i;
    logic initialized = 0;
    logic errors = 0;
    int instruction_count = 0;

    initial begin
        regfile = new();
    end

    // Instruction Memory (don't print memory transactions for instruction memory)
    riscv_memory #(
        .MEMORY_FILENAME(TEXT_MEM), .MEMORY_NAME(".text"),
        .MEMORY_WORDS(MAX_TEXT_SIZE), .MEMORY_OFFSET(TEXT_ADDRESS),
        .PRINT_MEMORY_TRANSACTIONS(0), .DEFAULT_MEMORY_VALUE(NOP_INSTRUCTION)
    ) instruction_memory(
        .clk(clk), .rst(rst),
        .read_en(1'b1), .write_en(1'b0), .address(if_PC),
        .write_data('0), .read_data(instruction_id)
    );

    // Data Memory
    assign mem_dAddress = mem_alu_result;
    assign mem_dWriteData = mem_readData2;
    // assign tb_dReadData = (MemRead_i) ? wb_readData_i : 'x; // Only provide data when reading from memory
    assign tb_dReadData = wb_readData_i;
    riscv_memory #(
        .MEMORY_FILENAME(DATA_MEM), .MEMORY_NAME(".data"),
        .MEMORY_WORDS(MAX_DATA_SIZE), .MEMORY_OFFSET(DATA_ADDRESS),
        .PRINT_MEMORY_TRANSACTIONS(0), .DEFAULT_MEMORY_VALUE(32'h00000000)
    ) data_memory(
        .clk(clk), .rst(rst),
        .read_en(MemRead_i), .write_en(MemWrite_i), .address(mem_dAddress),
        .write_data(mem_dWriteData), .read_data(wb_readData_i)
    );
    assign tb_Instruction = instruction_id;

    always @(rst) begin
        if (rst) begin
            $display("%0t: rst Asserted", $time);
        end
        else
            $display("%0t: rst Released", $time);
    end

    // Pipeline: registers that change on clock edge
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            errors <= 0;
            if_PC <= TEXT_ADDRESS;
            if (!initialized)
                $display("%0t: rst Asserted", $time);
            initialized <= 1;
            id_inst = new(NOP_INSTRUCTION);
            ex_inst = new(NOP_INSTRUCTION);
            mem_inst = new(NOP_INSTRUCTION);
            wb_inst = new(NOP_INSTRUCTION);
            ex_riscv_ctrl = new(NOP_INSTRUCTION);
            mem_riscv_ctrl = new(NOP_INSTRUCTION);
            wb_riscv_ctrl = new(NOP_INSTRUCTION);
        end
        else if (initialized == 1'b1) begin
            id_PC <= if_PC;
            ex_PC <= id_PC;
            mem_PC <= ex_PC;
            wb_PC <= mem_PC;
            mem_readData2 <= ex_readData2;
            mem_alu_result <= ex_alu_result;
            wb_alu_result <= mem_alu_result;
            mem_alu_zero <= ex_alu_zero;
            wb_alu_zero <= mem_alu_zero;
            // Register writes
            if (wb_riscv_ctrl.RegWrite)
                regfile.write_reg_i(wb_inst.u, tb_WriteBackData);
            // PC update logic
            if (mem_alu_zero && mem_riscv_ctrl.branch) begin
                if_PC = mem_PC + mem_inst.imm_b();
                // $display("%0t: Branch taken to PC=0x%8h %8h", $time, if_PC, mem_inst.u);
            end
            else
                if_PC = if_PC + 4;
        end
    end

    // ID stage
    always @(posedge clk or posedge rst) begin
        if (!rst && initialized === 1'b1) begin
            // These "automatic" objects cannot be assigned using non blocking statements.
            // Assign them using blocking statements but do it in a special order to implement pipelining
            #1ns; // need delay for instruction to propagate
            // $display("%0t id:%8h ex:%8h mem:%8h wb:%8h pc:%8h inst:%8h", $time, id_inst.u, ex_inst.u, mem_inst.u, wb_inst.u, if_PC, instruction_id);
            wb_inst = mem_inst;
            mem_inst = ex_inst;
            ex_inst = id_inst;
            id_inst = new(instruction_id);
            // Setup control
            wb_riscv_ctrl = mem_riscv_ctrl;
            mem_riscv_ctrl = ex_riscv_ctrl;
            ex_riscv_ctrl = new(ex_inst.u);

        end
    end
    // EX stage
    always @(posedge clk or posedge rst) begin
        if (!rst && initialized === 1'b1) begin
            #2ns; // registers have settled
            ex_readData1 = regfile.read_rs1_i(ex_inst.u);
            ex_readData2 = regfile.read_rs2_i(ex_inst.u);
            b_operand = ex_riscv_ctrl.b_operand(ex_readData2);
            ex_alu_result = riscv_alu::exec(riscv_alu::aluop_t'(ex_riscv_ctrl.ALUCtrl),
                ex_readData1, b_operand);
            ex_alu_zero = (ex_alu_result == 0);
        end
    end
    // MEM stage
    always @(posedge clk or posedge rst) begin
        #2ns;
        MemRead_i = 0;
        MemWrite_i = 0;
        if (!rst && initialized === 1'b1) begin
            // Setup for memory interface
            MemRead_i = mem_riscv_ctrl.MemRead;
            MemWrite_i = mem_riscv_ctrl.MemWrite;
        end
    end
    // WB stage
    always @(posedge clk or posedge rst) begin
        #2ns;
        if (!rst && initialized === 1'b1) begin
            wb_writedata = (wb_riscv_ctrl.MemtoReg) ? wb_readData_i : wb_alu_result;
        end
    end

    // Create a debug message at each negative edge of the clock
    always@(negedge clk) begin
        if (initialized != 0) begin
            $write("%0t:",$time);
            if (rst)
                $display(" - Reset asserted");
            else
                $display();

            // Print IF stage debug
            $write("  IF: PC=0x%8h",tb_PC);
            if (if_PC != tb_PC || ^tb_PC[0] === 1'bX) begin
                $display(" ** ERR** expecting PC=%h", if_PC);
                errors = errors + 1;
            end
            else $display();

            // Print ID stage debug
            $write("  ID: PC=0x%8h ",id_PC);
            // SHouldn't get different instruction results: we are providing the data
            if (! (^id_PC === 1'bX)) begin
                $write("I=0x%8h [%s]",id_inst.u, id_inst.inst_str());
                // if (tb_Instruction != instruction_id || ^tb_Instruction[0] === 1'bX) begin
                //     $write(" ** ERR** expecting Instruction=%h", instruction_id);
                //     errors = errors + 1;
                // end
            end
            $display();

            // EX stage
            $write("  EX: PC=0x%8h ",ex_PC);
            if (! (^ex_PC === 1'bX)) begin
                $write("I=0x%8h [%s] alu result=0x%h ",ex_inst.u,ex_inst.inst_str(),tb_ALUResult);
                if (tb_ALUResult != ex_alu_result || ^tb_ALUResult[0] === 1'bX) begin
                    $write(" ** ERR** expecting alu result=%h", ex_alu_result);
                    errors = errors + 1;
                end
            end
            $display();

            // MEM stage
            $write("  MEM:PC=0x%8h ",mem_PC);
            if (! (^mem_PC === 1'bX)) begin
                $write("I=0x%8h [%s] ",mem_inst.u, mem_inst.inst_str());
                // Check for undefined memory control signals
                if ($isunknown(tb_MemRead)) begin
                        $write("*** ERR: MemRead undefined ");
                        errors = errors + 1;
                end
                else if ($isunknown(tb_MemWrite))begin
                        $write("*** ERR: MemWrite undefined ");
                        errors = errors + 1;
                end
                // Print debug message for memory stage
                if (MemRead_i == 1'b0 && MemWrite_i == 1'b0) // No reads or writes going on in simulation model
                    if (tb_MemRead) begin 
                        $write("*** ERR: MemRead should be low ");
                        errors = errors + 1;
                    end else if (tb_MemWrite) begin
                        $write("*** ERR: MemWrite should be low ");
                        errors = errors + 1;
                    end else $write("No memory read/write ");  // debug message (all is well)

                else if (MemRead_i == 1'b1 && MemWrite_i == 1'b0)  // Memory read in simulation model
                    if (!tb_MemRead) begin
                        $write("*** ERR: MemRead should be high ");
                        errors = errors + 1;
                    end else if (tb_MemWrite) begin
                        $write("*** ERR: MemWrite should be low ");
                        errors = errors + 1;
                    end else if (tb_dAddress != mem_dAddress) begin
                        $write("*** Err: Memory Read to address 0x%1h but expecting address 0x%1h",tb_dAddress,mem_dAddress);
                        errors = errors + 1;
                    end else $write("Memory Read from address 0x%1h ",tb_dAddress);  // Note: data not ready until next cycle

                else if (MemRead_i == 1'b0 && MemWrite_i == 1'b1)  // Memory write in simulation model
                    if (tb_MemRead) begin
                        $write("*** ERR: MemRead should be low ");
                        errors = errors + 1;
                    end else if (!tb_MemWrite) begin
                        $write("*** ERR: MemWrite should be high ***");
                        errors = errors + 1;
                    end else if (tb_dAddress != mem_dAddress) begin
                        $write("*** Err: Memory Write to address 0x%1h but expecting address 0x%1h",tb_dAddress,mem_dAddress);
                        errors = errors + 1;
                    end else if (tb_dWriteData != mem_dWriteData) begin
                        $write("*** Err: Memory Write value 0x%1h but expecting value 0x%1h",tb_dWriteData,mem_dWriteData);
                        errors = errors + 1;
                    end else $write("Memory Write 0x%1h to address 0x%1h ",tb_dWriteData,tb_dAddress);
                else begin  // Should never get here (simulation model will not do simulataneous read/write)
                    $write("*** ERROR: simultaneous read and write ");
                    errors = errors + 1;
                end
            end
            $display();

            $write("  WB: PC=0x%8h ",wb_PC);
            if (! (^wb_PC === 1'bX)) begin
                $write("I=0x%8h [%s] ",wb_inst.u,wb_inst.inst_str());
                // Write back debug messages
                if (wb_riscv_ctrl.RegWrite) begin
                    $write("WriteBackData=0x%h ",tb_WriteBackData);
                    if (!(tb_WriteBackData === wb_writedata) && wb_riscv_ctrl.RegWrite) begin
                        $write(" ** ERR** expecting write back data=%h", wb_writedata);
                        errors = errors + 1;
                    // end else if ( (^tb_WriteBackData === 1'bX || ^wb_writedata === 1'bX) && valid_wb[4] == 1'b1) begin
                    //     $display(" ** ERR** Write back data is undefined=%h", wb_writedata);
                    //     errors = errors + 1;
                    end
                end
                if (wb_riscv_ctrl.branch) begin
                    if (wb_alu_zero)
                        $write("Branch taken to PC=0x%8h ", wb_PC + wb_inst.imm_b());
                    else
                        $write("Branch not taken ");
                end
            end
            $display();
        end
    end

endmodule