//////////////////////////////////////////////////////////////////////////////////
//  Filename: tb_riscv_pkg.sv
//  Provides simulation types and functions for RISC-V testbenches
//
// - Package must be analyzed before testbench that uses it (testbench updated when package changes)
//
//////////////////////////////////////////////////////////////////////////////////

package tb_riscv_pkg;

    // Package-level constants for use in module parameters
    localparam logic [31:0] NOP_INSTRUCTION = 32'h00000013;       // ADDI x0, x0, 0
    localparam logic [31:0] EBREAK_INSTRUCTION = 32'h00100073;    // EBREAK

    // Class that represents RISC-V ALU operations and constants
    class riscv_alu;

        // ALU operation type
        typedef enum logic [3:0] {
            AND  = 4'b0000,
            OR   = 4'b0001,
            ADD  = 4'b0010,
            SUB  = 4'b0110,
            LT   = 4'b0111,        
            SRL  = 4'b1000,
            SLL  = 4'b1001,
            SRA  = 4'b1010,
            XOR  = 4'b1101
        } aluop_t;

        // ALU constants
        static const aluop_t OP_AND = AND;
        static const aluop_t OP_OR  = OR;
        static const aluop_t OP_ADD = ADD;
        static const aluop_t OP_SUB = SUB;
        static const aluop_t OP_SLT = LT;
        static const aluop_t OP_SRL = SRL;
        static const aluop_t OP_SLL = SLL;
        static const aluop_t OP_SRA = SRA;
        static const aluop_t OP_XOR = XOR;

        // Static functions for implementing each ALU operation
        static function automatic logic [31:0] and_op(logic [31:0] a,logic [31:0] b);
            and_op = a & b;
        endfunction

        static function automatic logic [31:0] or_op(logic [31:0] a,logic [31:0] b);
            or_op = a | b;
        endfunction

        static function automatic logic [31:0] xor_op(logic [31:0] a,logic [31:0] b);
            xor_op = a ^ b;
        endfunction

        static function automatic logic [31:0] add_op(logic [31:0] a,logic [31:0] b);
            add_op = a + b;
        endfunction

        static function automatic logic [31:0] sub_op(logic [31:0] a,logic [31:0] b);
            sub_op = a - b;
        endfunction

        static function automatic logic [31:0] slt_op(logic [31:0] a,logic [31:0] b);
            slt_op = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
        endfunction

        static function automatic logic [31:0] srl_op(logic [31:0] a,logic [31:0] b);
            srl_op = a >> b[4:0];
        endfunction

        static function automatic logic [31:0] sll_op(logic [31:0] a,logic [31:0] b);
            sll_op = a << b[4:0];
        endfunction

        static function automatic logic [31:0] sra_op(logic [31:0] a,logic [31:0] b);
            sra_op = $signed(a) >>> b[4:0];
        endfunction

        // Core ALU function (implement all based on alu operation)
        static function automatic logic [31:0] exec(
            aluop_t op,
            logic [31:0] a,
            logic [31:0] b
        );
            case (op)
                ADD: exec = add_op(a,b);
                SUB: exec = sub_op(a,b);
                AND: exec = and_op(a,b);
                OR : exec = or_op(a,b);
                XOR: exec = xor_op(a,b);
                LT : exec = slt_op(a,b);
                SLL: exec = sll_op(a,b);
                SRL: exec = srl_op(a,b);
                SRA: exec = sra_op(a,b);
                default: exec = add_op(a,b);
            endcase
        endfunction

        // Optional: validity check
        static function automatic bit valid(aluop_t op);
            return op inside {AND, OR, ADD, SUB, LT, SRL, SLL, SRA, XOR};
        endfunction

        // Optional: pretty-print
        static function automatic string name(aluop_t op);
            return op.name();
        endfunction

    endclass

    // A class that wraps a 32-bit instruction and provides views for each format.
    class riscv_instr;

        // Packed union overlays the same 32 bits with different struct layouts.
        // logic [31:0] word;

        static const logic[6:0] OPCODE_MASK = 7'b1111111;
        static const logic[6:0] OPCODE_RTYPE_ALU = 7'b0110011;
        static const logic[6:0] OPCODE_IMMEDIATE_ALU = 7'b0010011;
        static const logic[6:0] OPCODE_STORE = 7'b0100011;
        static const logic[6:0] OPCODE_LW = 7'b0000011;
        static const logic[6:0] OPCODE_SW = 7'b0100011;
        static const logic[6:0] OPCODE_BRANCH = 7'b1100011;
        static const logic[6:0] OPCODE_ENVIRONMENT = 7'b1110011;

        static const logic[6:0] FUNC3_MASK = 32'h00007000; // bits [14:12]
        static const integer FUNC3_SHIFT = 12;
        static const logic[2:0] FUNC3_ADD = 3'b000;
        static const logic[2:0] FUNC3_SUB = 3'b000;
        static const logic[2:0] FUNC3_AND = 3'b111;
        static const logic[2:0] FUNC3_OR  = 3'b110;
        static const logic[2:0] FUNC3_XOR = 3'b100;
        static const logic[2:0] FUNC3_SLT = 3'b010;
        static const logic[2:0] FUNC3_SLL = 3'b001;
        static const logic[2:0] FUNC3_SRL = 3'b101;
        static const logic[2:0] FUNC3_SRA = 3'b101;
        static const logic[2:0] FUNC3_LW  = 3'b010;
        static const logic[2:0] FUNC3_SW  = 3'b010;
        static const logic[2:0] FUNC3_BEQ  = 3'b000;

        static const logic [11:0] IMMEDIATE_ECALL = 12'h000;
        static const logic [11:0] IMMEDIATE_EBREAK = 12'h001;

        static const logic [6:0] FUNC7_DEFAULT = 7'b0000000;
        static const logic [6:0] FUNC7_SUB = 7'b0100000;
        static const logic [6:0] FUNC7_SRA = 7'b0100000;

        // Common instruction encoding constants
        static const logic [31:0] NOP_INSTRUCTION = 32'h00000013; // ADDI x0, x0, 0
        static const logic [31:0] EBREAK_INSTRUCTION = 32'h00100073; // EBREAK

        typedef union packed {

            // R-type: funct7 rs2 rs1 funct3 rd opcode
            struct packed {
                logic [6:0]  funct7;    // [31:25]
                logic [4:0]  rs2;       // [24:20]    
                logic [4:0]  rs1;       // [19:15]
                logic [2:0]  funct3;    // [14:12]
                logic [4:0]  rd;        // [11:7]
                logic [6:0]  opcode;    // [6:0]
            } r;

            // I-type: imm[11:0] rs1 funct3 rd opcode
            struct packed {
                logic [11:0] imm;      // [31:20]
                logic [4:0]  rs1;      // [19:15]
                logic [2:0]  funct3;   // [14:12]
                logic [4:0]  rd;       // [11:7]
                logic [6:0]  opcode;   // [6:0]
            } i;

            // S-type: imm[11:5] rs2 rs1 funct3 imm[4:0] opcode
            struct packed {
                logic [6:0]  imm11_5;    // [31:25]
                logic [4:0]  rs2;        // [24:20]
                logic [4:0]  rs1;        // [19:15]
                logic [2:0]  funct3;     // [14:12]
                logic [4:0]  imm4_0;     // [11:7]
                logic [6:0]  opcode;    // [6:0]
            } s;

            // B-type: imm[12|10:5] rs2 rs1 funct3 imm[4:1|11] opcode
            struct packed {
                logic        imm12;     // [31]
                logic [5:0]  imm10_5;   // [30:25]
                logic [4:0]  rs2;       // [24:20]
                logic [4:0]  rs1;       // [19:15]
                logic [2:0]  funct3;    // [14:12]
                logic [3:0]  imm4_1;    // [11:8]
                logic        imm11;     // [7]
                logic [6:0]  opcode;    // [6:0]
            } b;

            // U-type: imm[31:12] rd opcode
            struct packed {
                logic [19:0] imm31_12;  // [31:12]
                logic [4:0]  rd;        // [11:7]
                logic [6:0]  opcode;    // [6:0]
            } u;

            // J-type: imm[20|10:1|11|19:12] rd opcode
            struct packed {
                logic        imm20;     // [31]
                logic [9:0]  imm10_1;   // [30:21]
                logic        imm11;     // [20]
                logic [7:0]  imm19_12;  // [19:12]
                logic [4:0]  rd;        // [11:7]
                logic [6:0]  opcode;    // [6:0]
            } j;

            struct packed {
                logic [31:0]  word;
            } w;

        } instr_u;

        static function automatic logic [4:0] get_rs1(logic [31:0] instruction);
            instr_u u = instruction;
            return u.r.rs1;
        endfunction

        static function automatic logic [4:0] get_rs2(logic [31:0] instruction);
            instr_u u = instruction;
            return u.r.rs2;
        endfunction

        static function automatic logic [4:0] get_rd(logic [31:0] instruction);
            instr_u u = instruction;
            return u.r.rd;
        endfunction

        static function automatic logic [31:0] create_rtype_instr(logic [4:0] rd, logic [4:0] rs1, logic [4:0] rs2,
             logic [2:0] funct3, logic [6:0] funct7);
            instr_u u;
            u.r = '{funct7, rs2, rs1, funct3, rd, OPCODE_RTYPE_ALU};
            return u.w;
        endfunction

        static function automatic logic [31:0] create_add_instr(logic [4:0] rd, logic [4:0] rs1, logic [4:0] rs2);
            return create_rtype_instr(rd, rs1, rs2, FUNC3_ADD, FUNC7_DEFAULT);
        endfunction

        static function automatic logic [31:0] create_sub_instr(logic [4:0] rd, logic [4:0] rs1, logic [4:0] rs2);
            return create_rtype_instr(rd, rs1, rs2, FUNC3_SUB, FUNC7_SUB);
        endfunction

        static function automatic logic [31:0] create_or_instr(logic [4:0] rd, logic [4:0] rs1, logic [4:0] rs2);
            return create_rtype_instr(rd, rs1, rs2, FUNC3_OR, FUNC7_DEFAULT);
        endfunction

        static function automatic logic [31:0] create_xor_instr(logic [4:0] rd, logic [4:0] rs1, logic [4:0] rs2);
            return create_rtype_instr(rd, rs1, rs2, FUNC3_XOR, FUNC7_DEFAULT);
        endfunction

        static function automatic logic [31:0] create_slt_instr(logic [4:0] rd, logic [4:0] rs1, logic [4:0] rs2);
            return create_rtype_instr(rd, rs1, rs2, FUNC3_SLT, FUNC7_DEFAULT);
        endfunction

        static function automatic logic [31:0] create_sll_instr(logic [4:0] rd, logic [4:0] rs1, logic [4:0] rs2);
            return create_rtype_instr(rd, rs1, rs2, FUNC3_SLL, FUNC7_DEFAULT);
        endfunction

        static function automatic logic [31:0] create_sra_instr(logic [4:0] rd, logic [4:0] rs1, logic [4:0] rs2);
            return create_rtype_instr(rd, rs1, rs2, FUNC3_SRA, FUNC7_SRA);
        endfunction

        static function automatic logic [31:0] create_srl_instr(logic [4:0] rd, logic [4:0] rs1, logic [4:0] rs2);
            return create_rtype_instr(rd, rs1, rs2, FUNC3_SRL, FUNC7_DEFAULT);
        endfunction

        static function automatic logic [31:0] create_immediate_instr(logic [4:0] rd, logic [4:0] rs1, logic [11:0] imm,
             logic [2:0] funct3, logic [6:0] opcode);
            instr_u u;
            u.i = '{imm, rs1, funct3, rd, opcode};
            return u.w;
        endfunction

        static function automatic logic [31:0] create_immediate_alu_instr(logic [4:0] rd, logic [4:0] rs1, logic [11:0] imm,
             logic [2:0] funct3);
            return create_immediate_instr(rd, rs1, imm, funct3, OPCODE_IMMEDIATE_ALU);
        endfunction

        static function automatic logic [31:0] create_addi_instr(logic [4:0] rd, logic [4:0] rs1, logic [11:0] imm);
            return create_immediate_alu_instr(rd, rs1, imm, FUNC3_ADD);
        endfunction

        static function automatic logic [31:0] create_andi_instr(logic [4:0] rd, logic [4:0] rs1, logic [11:0] imm);
            return create_immediate_alu_instr(rd, rs1, imm, FUNC3_AND);
        endfunction

        static function automatic logic [31:0] create_ori_instr(logic [4:0] rd, logic [4:0] rs1, logic [11:0] imm);
            return create_immediate_alu_instr(rd, rs1, imm, FUNC3_OR);
        endfunction

        static function automatic logic [31:0] create_xori_instr(logic [4:0] rd, logic [4:0] rs1, logic [11:0] imm);
            return create_immediate_alu_instr(rd, rs1, imm, FUNC3_XOR);
        endfunction

        static function automatic logic [31:0] create_slti_instr(logic [4:0] rd, logic [4:0] rs1, logic [11:0] imm);
            return create_immediate_alu_instr(rd, rs1, imm, FUNC3_SLT);
        endfunction

        static function automatic logic [31:0] create_immediate_shift_instr(logic [4:0] rd, logic [4:0] rs1, logic [4:0] imm, logic [6:0] func7, logic [2:0] func3);
            return create_immediate_alu_instr(rd, rs1, {func7, imm}, func3);
        endfunction

        static function automatic logic [31:0] create_slli_instr(logic [4:0] rd, logic [4:0] rs1, logic [4:0] imm);
            return create_immediate_shift_instr(rd, rs1, imm, FUNC7_DEFAULT, FUNC3_SLL);
        endfunction

        static function automatic logic [31:0] create_srli_instr(logic [4:0] rd, logic [4:0] rs1, logic [4:0] imm);
            return create_immediate_shift_instr(rd, rs1, imm, FUNC7_DEFAULT, FUNC3_SRL);
        endfunction

        static function automatic logic [31:0] create_srai_instr(logic [4:0] rd, logic [4:0] rs1, logic [4:0] imm);
            return create_immediate_shift_instr(rd, rs1, imm, FUNC7_SRA, FUNC3_SRA);
        endfunction

        static function automatic logic [31:0] create_lw_instr(logic [4:0] rd, logic [4:0] rs1, logic [4:0] imm);
            return create_immediate_instr(rd, rs1, imm, FUNC3_LW, OPCODE_LW);
        endfunction

        static function automatic logic [31:0] create_stype_instr(logic [11:0] imm, logic [4:0] rs1, logic [4:0] rs2, logic[2:0] func3, logic[6:0] opcode);
            instr_u u;
            u.s = '{imm[11:5], rs2, rs1, func3, imm[4:0], opcode};
            return u.w;
        endfunction

        static function automatic logic [31:0] create_sw_instr(logic [11:0] imm, logic [4:0] rs1, logic [4:0] rs2);
            return create_stype_instr(imm, rs1, rs2, FUNC3_SW, OPCODE_SW);
        endfunction

        static function automatic logic [31:0] create_btype_instr(logic [12:0] imm, logic [4:0] rd, logic [4:0] rs1, logic [4:0] rs2, logic[2:0] func3, logic[6:0] opcode);
            instr_u u;
            u.b = '{imm[12], imm[10:5], rs2, rs1, func3, imm[4:1], imm[11], opcode};
            return u.w;
        endfunction

        static function automatic logic [31:0] create_branch_instr(logic [12:0] imm, logic [4:0] rd, logic [4:0] rs1, logic [4:0] rs2, logic[2:0] func3);
            return create_btype_instr(imm, rd, rs1, rs2, func3, OPCODE_BRANCH);
        endfunction

        static function automatic logic [31:0] create_beq_instr(logic [12:0] imm, logic [4:0] rd, logic [4:0] rs1, logic [4:0] rs2);
            return create_branch_instr(imm, rd, rs1, rs2, FUNC3_BEQ);
        endfunction


        // The actual instruction storage
        instr_u u;

        // Construct from a 32-bit word
        function new(logic [31:0] w = 32'h0000_0013); // default: ADDI x0,x0,0 (NOP)
            u.w = w;
        endfunction

        // Convenience: raw word
        function logic [31:0] getword();
            return u;
        endfunction

        // Common fields exist in every encoding (same bit positions)
        function logic [6:0] opcode();
            return u.r.opcode; // any view works for opcode/rd/funct3/rs1/rs2 where defined
        endfunction

        function logic [4:0] rd();
            return u.r.rd;
        endfunction

        function logic [2:0] funct3();
            return u.r.funct3;
        endfunction

        // Signed immediate extractors (use correct bit stitching)
        function automatic logic signed [31:0] imm_i();
            return $signed({{20{u.i.imm[11]}}, u.i.imm});
        endfunction

        function automatic logic signed [31:0] imm_s();
        logic [11:0] imm;
            imm = {u.s.imm11_5, u.s.imm4_0};
        return $signed({{20{imm[11]}}, imm});
        endfunction

        function automatic logic signed [31:0] imm_b();
        logic [12:0] imm;
            imm = {u.b.imm12, u.b.imm11, u.b.imm10_5, u.b.imm4_1, 1'b0};
            return $signed({{19{imm[12]}}, imm});
        endfunction

        function automatic logic signed [31:0] imm_u();
            return $signed({u.u.imm31_12, 12'b0});
        endfunction

        function automatic logic signed [31:0] imm_j();
        logic [20:0] imm;
            imm = {u.j.imm20, u.j.imm19_12, u.j.imm11, u.j.imm10_1, 1'b0};
            return $signed({{11{imm[20]}}, imm});
        endfunction

        function automatic logic is_rtype();
            return (opcode() == OPCODE_RTYPE_ALU);
        endfunction

        function automatic logic is_immediate();
            return (opcode() == OPCODE_IMMEDIATE_ALU);
        endfunction

        function automatic logic is_environment();
            return (opcode() == OPCODE_ENVIRONMENT);
        endfunction

        function automatic logic is_ebreak();
            return is_environment && (u.i.imm == IMMEDIATE_EBREAK) && (u.i.rd == 5'd0) && (u.i.rs1 == 5'd0);
        endfunction

        function automatic logic is_lw();
            return (opcode() == OPCODE_LW) && (funct3() == FUNC3_LW);
        endfunction

        function automatic logic is_sw();
            return (opcode() == OPCODE_SW) && (funct3() == FUNC3_SW);
        endfunction

        function automatic logic is_beq();
            return (opcode() == OPCODE_BRANCH) && (funct3() == FUNC3_BEQ);
        endfunction

        function automatic logic signed [31:0] imm_i_s32();
            return $signed({ {20{u.i.imm[11]}}, u.i.imm});
        endfunction

        function automatic logic signed [31:0] imm_s_s32();
            return $signed({ {20{u.s.imm11_5[6]}}, {u.s.imm11_5, u.s.imm4_0} });
        endfunction

        function automatic logic signed [31:0] imm_b_s32();
            return $signed({ {19{u.b.imm12}}, u.b.imm11, u.b.imm10_5, u.b.imm4_1, 1'b0 });
        endfunction


        // Returns the instruction mnemonic
        function automatic string mnemonic();
            if (is_rtype())
                return rtype_mnemonic();
            else if (is_immediate())
                return immediate_mnemonic();
            else if (is_environment())
                return environment_mnemonic();
            else if (is_lw())
                return "lw";
            else if (is_sw())  // sw is an immediate type but we handle it separately
                return "sw";
            else if (is_beq())
                return "beq";
            return "UNDEFINED";
        endfunction

        function automatic string rtype_mnemonic();
            case(u.r.funct3)
                FUNC3_ADD:
                    if (u.r.funct7 == FUNC7_DEFAULT) return "add";
                    else if (u.r.funct7 == FUNC7_SUB)return "sub";
                    else return "UNDEFINED ADD/SUB";
                FUNC3_AND: return "and";
                FUNC3_OR:  return "or";
                FUNC3_XOR: return "xor";
                FUNC3_SLT: return "slt";
                FUNC3_SLL: return "sll";
                FUNC3_SRL:
                    if (u.r.funct7 == FUNC7_DEFAULT) return "srl";
                    else if (u.r.funct7 == FUNC7_SRA) return "sra";
            endcase
            return $sformatf("UNDEFINED RTYPE : func3 %0x func7 %0x",
                u.r.funct3, u.r.funct7);
        endfunction

        function automatic string immediate_mnemonic();
            case(u.r.funct3)
                FUNC3_ADD: return "addi"; // 0
                FUNC3_SLL: return "slli"; // 1
                FUNC3_SLT: return "slti"; // 2
                // 3 sltiu not implemented
                FUNC3_XOR: return "xori"; // 4
                FUNC3_SRL: // 5
                    if (u.r.funct7 == FUNC7_DEFAULT) return "srli";
                    else if (u.r.funct7 == FUNC7_SRA) return "srai";
                FUNC3_OR:  return "ori"; // 6
                FUNC3_AND: return "andi"; // 7
            endcase
            return $sformatf("UNDEFINED IMMEDIATE : opcode %0x func3 %0x func7 %0x",
                u.i.opcode, u.i.funct3, u.r.funct7);
        endfunction

        function automatic string environment_mnemonic();
            if (u.i.imm == IMMEDIATE_ECALL && u.i.rd == 5'd0 && u.i.rs1 == 5'd0)
                return "ecall";
            else if (u.i.imm == IMMEDIATE_EBREAK && u.i.rd == 5'd0 && u.i.rs1 == 5'd0)
                return "ebreak";
            return $sformatf("UNDEFINED ENVIRONMENT : imm %0x rd %0d rs1 %0d",
                u.i.imm, u.i.rd, u.i.rs1);
        endfunction

        // Returns the decoded instruction string
        function automatic string inst_str();
            string mnem;
            mnem = mnemonic();
            if (is_rtype())
                return $sformatf("%s x%0d,x%0d,x%0d", mnem, u.r.rd, u.r.rs1, u.r.rs2);
            else if (is_immediate())
                return $sformatf("%s x%0d,x%0d,%0d (0x%08h)", mnem, u.i.rd, u.i.rs1, imm_i(),imm_i());
            else if (is_lw())
                return $sformatf("%s x%0d,%0d(x%0d)", mnem, u.i.rd, imm_i_s32(), u.i.rs1);
            else if (is_sw())
                return $sformatf("sw x%0d,%0d(x%0d)", u.s.rs2, imm_s_s32(), u.s.rs1);
            else if (is_beq())
                return $sformatf("beq x%0d,x%0d,%0d", u.b.rs1, u.b.rs2, imm_b_s32());
            else if (is_ebreak())
                return "ebreak";
            return $sformatf("UNDEFINED Instruction %s opcode 0x%0x", mnem, u.r.opcode);
        endfunction

        function automatic string inst_fields();
            return "UNDEFINED";
        endfunction

    endclass

    // Represents the simple control signals for a risc-v instruction
    class riscv_simple_control;
        logic       ALUSrc;
        riscv_alu::aluop_t ALUCtrl;
        logic       MemWrite;
        logic       MemRead;
        logic       branch;
        logic       RegWrite;
        logic       MemtoReg;
        riscv_instr instr;

        function new(logic [31:0] instruction);
            instr = new(instruction);
            // Default values
            ALUSrc   = 0;
            ALUCtrl  = riscv_alu::OP_ADD;
            MemWrite = 0;
            MemRead  = 0;
            branch   = 0;
            RegWrite = 0;
            MemtoReg = 0;
            // RegWrite value: rtype, immediate, and lw
            if (instr.is_rtype() || instr.is_immediate() ||
                instr.is_lw())
                RegWrite = '1;
            // ALUSrc: immediate, lw, and sw
            if (instr.is_immediate() ||
                instr.is_lw() || instr.is_sw())
                ALUSrc = '1;
            // MemWrite: sw
            if (instr.is_sw())
                MemWrite = '1;
            // MemRead: lw
            if (instr.is_lw())
                MemRead = '1;
            // MemtoReg: lw
            if (instr.is_lw())
                MemtoReg = '1;
            // Branch
            if (instr.is_beq())
                branch = '1;
            // ALU control
            if (instr.is_lw() || instr.is_sw())
                ALUCtrl  = riscv_alu::OP_ADD;
            else if (instr.is_beq())
                ALUCtrl  = riscv_alu::OP_SUB;
            else begin
                case (instr.funct3())
                    riscv_instr::FUNC3_ADD:
                        if (instr.u.r.funct7 == riscv_instr::FUNC7_SUB && !instr.is_immediate())
                            ALUCtrl = riscv_alu::OP_SUB;
                        else
                            ALUCtrl = riscv_alu::OP_ADD;
                    riscv_instr::FUNC3_AND: ALUCtrl = riscv_alu::OP_AND;
                    riscv_instr::FUNC3_OR:  ALUCtrl = riscv_alu::OP_OR;
                    riscv_instr::FUNC3_XOR: ALUCtrl = riscv_alu::OP_XOR;
                    riscv_instr::FUNC3_SLT: ALUCtrl = riscv_alu::OP_SLT;
                    riscv_instr::FUNC3_SLL: ALUCtrl = riscv_alu::OP_SLL;
                    riscv_instr::FUNC3_SRL:
                        if (instr.u.r.funct7 == riscv_instr::FUNC7_DEFAULT)
                            ALUCtrl = riscv_alu::OP_SRL;
                        else if (instr.u.r.funct7 == riscv_instr::FUNC7_SRA)
                            ALUCtrl = riscv_alu::OP_SRA;
                    default: ALUCtrl = riscv_alu::OP_ADD;
                endcase
            end
        endfunction

        // Returns the decoded instruction string
        function automatic logic [31:0] b_operand(logic [31:0] regB);
            if (ALUSrc == 0)  // use conventional second register operand
                return regB;
            else begin
                if (instr.is_sw())
                    return instr.imm_s(); // store instruction immediate
                else //
                    return instr.imm_i(); // conventional immediate
            end
        endfunction

    endclass

    class riscv_regfile;

        // Simulated register file
        logic [31:0] regfile [31:0];

        // Constructor: initialize register file to zero
        function new();
            for (int i=0; i<32; i=i+1)
                regfile[i] = 32'd0;
        endfunction

        // Read registers
        function automatic logic [31:0] read_reg(logic [4:0] regnum);
            return regfile[regnum];
        endfunction

        // Write register
        function automatic void write_reg(logic [4:0] regnum, logic [31:0] data);
            if (regnum != 5'd0)
                regfile[regnum] = data;
        endfunction

        function automatic logic [31:0] read_rs1_i(logic [31:0] instruction);
            return read_reg(riscv_instr::get_rs1(instruction));
        endfunction

        function automatic logic [31:0] read_rs2_i(logic [31:0] instruction);
            return read_reg(riscv_instr::get_rs2(instruction));
        endfunction

        // Write register
        function automatic void write_reg_i(logic [31:0] instruction, logic [31:0] data);
            write_reg(riscv_instr::get_rd(instruction), data);
        endfunction

    endclass

    class riscv_mem;

        // Simulated register file
        logic [31:0] memory[];

        function new(int size, string filename="");
            memory = new[size];
            // Initialize memory from file if provided
            if (filename != "") begin
                $readmemh(filename, memory);
            end else begin
                for (int i=0; i<size; i=i+1)
                    memory[i] = 32'd0;
            end
        endfunction

        // Read registers
        function automatic logic [31:0] read(int index);
            return memory[index];
        endfunction

        // Write register
        function automatic void write(int index, logic [31:0] data);
            memory[index] = data;
        endfunction

    endclass

endpackage : tb_riscv_pkg