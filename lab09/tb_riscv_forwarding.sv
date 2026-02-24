`timescale 1ns / 100ps
//
//////////////////////////////////////////////////////////////////////////////////
//
//  Filename: tb_riscv_forwarding.sv
//
//  Author: Mike Wirthlin
//  
//////////////////////////////////////////////////////////////////////////////////

module tb_riscv_forwarding #(
    logic [31:0] TEXT_ADDRESS = 32'h00000000, // CompactTextAtZero in RARS
    logic [31:0] DATA_ADDRESS = 32'h00002000,
    string TEXT_MEM = "forwarding_text.mem",
    string DATA_MEM = "forwarding_data.mem",
    int MAX_INSTRUCTION_COUNT = 2000
    ) ();

    import tb_riscv_pkg::*;

    // Testbench global signals
    logic clk, rst;
    // DUT input signals (used by DUT)
    logic [31:0] tb_instruction, tb_PC, tb_ALUResult, tb_Address, tb_dWriteData;
    logic [31:0] tb_dReadData, tb_WriteBackData;
    logic tb_MemRead, tb_MemWrite, tb_iMemRead;

    // clock generation
    initial begin
        clk = 0;
        forever #5 clk <= ~clk; // 100MHz
    end

    // Instance student pipeline processor
    riscv_forwarding_pipeline #(.INITIAL_PC(TEXT_ADDRESS))
    riscv(.clk(clk), .rst(rst), .instruction(tb_instruction), .iMemRead(tb_iMemRead), .PC(tb_PC),	
        .ALUResult(tb_ALUResult), .dAddress(tb_Address), .dWriteData(tb_dWriteData), .dReadData(tb_dReadData),
        .MemRead(tb_MemRead), .MemWrite(tb_MemWrite), .WriteBackData(tb_WriteBackData) );

    // Instance simulation model
    riscv_forwarding_model #(.TEXT_MEM(TEXT_MEM), .DATA_MEM(DATA_MEM), .TEXT_ADDRESS(TEXT_ADDRESS), 
        .DATA_ADDRESS(DATA_ADDRESS))
    riscv_model(.clk(clk), .rst(rst), .tb_PC(tb_PC), .tb_Instruction(tb_instruction), .tb_ALUResult(tb_ALUResult),
        .tb_dAddress(tb_Address), .tb_dWriteData(tb_dWriteData), .tb_dReadData(tb_dReadData),
        .tb_WriteBackData(tb_WriteBackData), .tb_MemRead(tb_MemRead), .tb_MemWrite(tb_MemWrite),
        .tb_iMemRead(tb_iMemRead)
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

module riscv_forwarding_model #(
    string TEXT_MEM = "",
    string DATA_MEM = "",
    logic [31:0] TEXT_ADDRESS = 32'h00200000,
    logic [31:0] DATA_ADDRESS = 32'h00000000,
    int MAX_TEXT_SIZE = 4096,
    int MAX_DATA_SIZE = 1024,
    int DEBUG_LEVEL = 0
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
    input tb_MemRead, tb_MemWrite, tb_iMemRead
    );

    import tb_riscv_pkg::*;
    riscv_regfile regfile;

    logic [31:0] instruction_id;
    logic [31:0] if_PC, id_PC, ex_PC, mem_PC, wb_PC;
    logic [31:0] ex_alu_result, mem_alu_result, wb_alu_result, mem_dAddress;
    logic [31:0] ex_readData1, ex_readData2, mem_dWriteData;
    logic [31:0] wb_memReadData_i, wb_writedata;
    logic [31:0] b_operand, ex_operand1, ex_operand2;
    logic ex_alu_zero, mem_alu_zero, wb_alu_zero;
    riscv_instr id_inst, ex_inst, mem_inst, wb_inst;
    riscv_instr NOP_inst = new(NOP_INSTRUCTION); // addi x0, x0, 0
    riscv_simple_control ex_riscv_ctrl, mem_riscv_ctrl, wb_riscv_ctrl;
    riscv_pipeline_forwarding forwarding = new();
    riscv_pipeline_forwarding::forward_t forwardA = riscv_pipeline_forwarding::NO_FORWARD;
    riscv_pipeline_forwarding::forward_t forwardB = riscv_pipeline_forwarding::NO_FORWARD;
    logic insert_ex_bubble, load_use, load_use_condition, mem_branch_taken, wb_branch_taken;
    logic MemRead_i, MemWrite_i;
    logic initialized = 0;
    logic errors = 0;
    logic iMemRead;
    int instruction_count = 0;

    initial begin
        regfile = new();
    end

    // This signal stalls both the IF and ID stages
    assign iMemRead = ~(load_use && ~mem_branch_taken); // Stall on load-use hazard but not if there is a branch in MEM stage (since that bubble will also cause a stall)
    // Instruction Memory (insruction_id available in id stage)
    riscv_memory #(
        .MEMORY_FILENAME(TEXT_MEM), .MEMORY_NAME(".text"),
        .MEMORY_WORDS(MAX_TEXT_SIZE), .MEMORY_OFFSET(TEXT_ADDRESS),
        .PRINT_MEMORY_TRANSACTIONS(0), .DEFAULT_MEMORY_VALUE(NOP_INSTRUCTION)
    ) instruction_memory(
        .clk(clk), .rst(rst),
        .read_en(iMemRead), .write_en(1'b0), .address(if_PC),
        .write_data('0), .read_data(instruction_id)
    );

    // Data Memory
    assign mem_dAddress = mem_alu_result;
    // assign mem_dWriteData = mem_readData2;
    assign tb_dReadData = wb_memReadData_i;
    riscv_memory #(
        .MEMORY_FILENAME(DATA_MEM), .MEMORY_NAME(".data"),
        .MEMORY_WORDS(MAX_DATA_SIZE), .MEMORY_OFFSET(DATA_ADDRESS),
        .PRINT_MEMORY_TRANSACTIONS(0), .DEFAULT_MEMORY_VALUE(32'h00000000)
    ) data_memory(
        .clk(clk), .rst(rst),
        .read_en(MemRead_i), .write_en(MemWrite_i), .address(mem_dAddress),
        .write_data(mem_dWriteData), .read_data(wb_memReadData_i)
    );
    assign tb_Instruction = instruction_id;

    always @(rst) begin
        if (rst)
            $display("%0t: rst Asserted", $time);
        else
            $display("%0t: rst Released", $time);
    end

    // Pipeline: registers that change on clock edge
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            errors <= 0;
            if_PC <= TEXT_ADDRESS;
            id_PC <= 'x;
            ex_PC <= 'x;
            mem_PC <= 'x;
            wb_PC <= 'x;
            if (!initialized)
                $display("%0t: rst Asserted", $time);
            initialized <= 1;
            // Initialize static members upon reset
            id_inst = new(NOP_INSTRUCTION);
            ex_inst = new(NOP_INSTRUCTION);
            mem_inst = new(NOP_INSTRUCTION);
            wb_inst = new(NOP_INSTRUCTION);
            ex_riscv_ctrl = new(NOP_INSTRUCTION);
            mem_riscv_ctrl = new(NOP_INSTRUCTION);
            wb_riscv_ctrl = new(NOP_INSTRUCTION);
            mem_alu_result <= 0;
            wb_alu_result <= 0;
            mem_alu_zero <= 0;
            wb_alu_zero <= 0;
            mem_branch_taken <= 0;
            wb_branch_taken <= 0;
        end
        else if (initialized == 1'b1) begin
            if (insert_ex_bubble)
                ex_PC <= 'x;
            else
                ex_PC <= id_PC;
            if (mem_branch_taken) // insert buggle in MEM
                mem_PC <= 'x;
            else
                mem_PC <= ex_PC;
            wb_PC <= mem_PC;
            mem_dWriteData <= ex_operand2;
            mem_alu_result <= ex_alu_result;
            wb_alu_result <= mem_alu_result;
            mem_alu_zero <= ex_alu_zero;
            wb_alu_zero <= mem_alu_zero;
            wb_branch_taken <= mem_branch_taken;
            // Register writes
            if (wb_riscv_ctrl.RegWrite) begin
                regfile.write_reg_i(wb_inst.u, tb_WriteBackData);
                if (DEBUG_LEVEL > 0 && wb_inst.rd() != 0) begin
                    $display("%0t: DEBUG: Write back to regfile: 0x%0h x%0d = 0x%1h", $time, wb_inst.u, wb_inst.rd(), tb_WriteBackData);
                end
            end
            // PC update logic
            if (iMemRead) begin
                if (mem_branch_taken)
                    if_PC <= mem_PC + mem_inst.imm_b();
                else
                    if_PC <= if_PC + 4;
                id_PC <= if_PC;
            end
        end
    end

    // ID stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Need default instructions when pipeline is initialized to avoid unknowns
            ex_inst = NOP_inst;
            mem_inst = NOP_inst;
            wb_inst = NOP_inst;
        end
        else if (initialized === 1'b1) begin
            // These "automatic" objects cannot be assigned using non blocking statements.
            // Assign them using blocking statements but do it in a special order to implement pipelining
            // #1ns; // need delay for instruction to propagate
            // This 'pipeline' happens immediately on the clock edge (no propagation needed)
            wb_inst = mem_inst;
            wb_riscv_ctrl = mem_riscv_ctrl;
            if (mem_branch_taken) begin
                mem_inst = NOP_inst;
                mem_riscv_ctrl = new(NOP_INSTRUCTION);
            end else begin
                mem_inst = ex_inst;
                mem_riscv_ctrl = ex_riscv_ctrl;
            end
            if (insert_ex_bubble) begin
                ex_inst = NOP_inst;
                ex_riscv_ctrl = new(NOP_INSTRUCTION);
            end else begin
                ex_inst = id_inst;
                ex_riscv_ctrl = new(ex_inst.u);
            end
            #1ns; // need delay for instruction read to propagate
            if (iMemRead) // Don't create a new instruction if there is a stall
                id_inst = new(instruction_id);
            // Setup control

        end
    end
    // EX stage
    assign insert_ex_bubble = load_use || mem_branch_taken || wb_branch_taken;
    always @(posedge clk or posedge rst) begin
        if (initialized === 1'b1) begin // initialization initializes static members
            #2ns; // registers have settled
            forwardA = forwarding.forward_rs1(ex_riscv_ctrl,mem_riscv_ctrl,wb_riscv_ctrl);
            forwardB = forwarding.forward_rs2(ex_riscv_ctrl,mem_riscv_ctrl,wb_riscv_ctrl);
            load_use = forwarding.load_use_condition(id_inst, ex_inst) && !mem_branch_taken;
            ex_readData1 = regfile.read_rs1_i(ex_inst.u);
            ex_readData2 = regfile.read_rs2_i(ex_inst.u);
            // Forwarding logic
            if (forwardA == riscv_pipeline_forwarding::MEM_FORWARD)
                ex_operand1 = mem_alu_result;
            else if (forwardA == riscv_pipeline_forwarding::WB_FORWARD)
                ex_operand1 = wb_writedata;
            else ex_operand1 = ex_readData1;
            // ex_operand2 is passed on to the MEM stage for writing data (store instructions)
            if (forwardB == riscv_pipeline_forwarding::MEM_FORWARD)
                ex_operand2 = mem_alu_result;
            else if (forwardB == riscv_pipeline_forwarding::WB_FORWARD)
                ex_operand2 = wb_writedata;
            else ex_operand2 = ex_readData2;
            b_operand = ex_riscv_ctrl.b_operand(ex_operand2);
            ex_alu_result = riscv_alu::exec(riscv_alu::aluop_t'(ex_riscv_ctrl.ALUCtrl),
                ex_operand1, b_operand);
            ex_alu_zero = (ex_alu_result == 0);
            // $display("%0t: ex_readData1=0x%1h ex_readData2=0x%1h ex_operand1=0x%1h ex_operand2=0x%1h b_operand=0x%1h, mem_result=0x%1h, wb_Result = 0x%1h, result=0x%1h, instruction=0x%1h",
            //     $time, ex_readData1, ex_readData2, ex_operand1, ex_operand2, b_operand, mem_alu_result, wb_writedata, ex_alu_result, ex_inst.u);
        end
    end
    // MEM stage
    always @(posedge clk) begin
        #2ns;
        MemRead_i = 0;
        MemWrite_i = 0;
        if (!rst && initialized === 1'b1) begin
            // Setup for memory interface
            mem_branch_taken = mem_inst.is_branch() && mem_alu_zero;
            MemRead_i = mem_riscv_ctrl.MemRead;
            MemWrite_i = mem_riscv_ctrl.MemWrite;
        end
    end
    // WB stage
    always @(posedge clk or posedge rst) begin
        #1.5ns;
        if (!rst && initialized === 1'b1) begin
            wb_writedata = (wb_riscv_ctrl.MemtoReg) ? wb_memReadData_i : wb_alu_result;
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
            if (!iMemRead) begin
                $write(" Load Use Stall");
            end
            if (iMemRead != tb_iMemRead) begin
                $write(" ** ERR ** incorrect iMemRead=%1h", tb_iMemRead);
                errors = errors + 1;
            end
            else $display();

            // Print ID stage debug
            $write("  ID: PC=0x%8h ",id_PC);
            // SHouldn't get different instruction results: we are providing the data
            if (! (^id_PC === 1'bX)) begin
                $write("I=0x%8h [%s]",id_inst.u, id_inst.inst_str());
                if (!iMemRead)
                    $write(" Load Use Stall");
                if (insert_ex_bubble)
                    $write(" (insert bubble)");
            end
            $display();

            // EX stage
            $write("  EX: PC=0x%8h ",ex_PC);
            if (! (^ex_PC === 1'bX)) begin
                $write("I=0x%8h [%s] ",ex_inst.u,ex_inst.inst_str());
                if (mem_branch_taken)
                    $write("(EX stage flushed) ");
                else if (ex_inst.uses_alu_result()) begin
                    $write("alu result=0x%h ",tb_ALUResult);
                    if (tb_ALUResult != ex_alu_result || ^tb_ALUResult[0] === 1'bX) begin
                        $write(" ** ERR** expecting alu result=%h", ex_alu_result);
                        errors = errors + 1;
                    end
                    if (forwardA == riscv_pipeline_forwarding::MEM_FORWARD)
                        $write(" [FWD MEM(0x%1h) to r1]",mem_alu_result);
                    else if (forwardA == riscv_pipeline_forwarding::WB_FORWARD)
                        $write(" [FWD WB(0x%1h) to r1]",wb_writedata);
                    if (forwardB == riscv_pipeline_forwarding::MEM_FORWARD)
                        $write(" [FWD MEM(0x%1h) to r2]",mem_alu_result);
                    else if (forwardB == riscv_pipeline_forwarding::WB_FORWARD)
                        $write(" [FWD WB(0x%1h) to r2]",wb_writedata);
                end
            end
            else if (DEBUG_LEVEL > 0)
                 $write("0x%8h ",ex_inst.u);
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
                    // end else $write("(no mem) ");  // debug message (all is well)
                    end else $write("");

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
            else if (DEBUG_LEVEL > 0)
                 $write("0x%8h ",mem_inst.u);

            if (mem_riscv_ctrl.branch) begin // Only print a branch taken/not taken message for branch instructions
                if (mem_alu_zero)
                    $write("Branch taken to PC=0x%8h ", mem_PC + mem_inst.imm_b());
                else
                    $write("Branch not taken ");
            end
            $display();

            $write("  WB: PC=0x%8h ",wb_PC);
            if (! (^wb_PC === 1'bX)) begin
                $write("I=0x%8h [%s] ",wb_inst.u,wb_inst.inst_str());
                instruction_count = instruction_count + 1;
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
            end
            else if (DEBUG_LEVEL > 0)
                 $write("0x%8h ",wb_inst.u);
            $display();
        end
    end

endmodule