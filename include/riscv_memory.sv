`timescale 1ns / 100ps
/**
* RISC-V Memory Module.
* Defines a memory module that is organized as an array of 32-bit words.
* Memory addresses are word aligned so the bottom two bits of the address are ignored.
* This is a synthesizeable module that can be used in simulation as well.
**/
module riscv_memory #(
    parameter MEMORY_FILENAME = "",
    parameter MEMORY_NAME = "", // used for debug messages
    parameter FINISH_ON_NOFILE = 0,
    int MEMORY_WORDS = 1024,
    logic [31:0] MEMORY_OFFSET = '0, // base address of memory. Should be a power of 2
    logic PRINT_MEMORY_TRANSACTIONS = 0,
    logic [31:0] DEFAULT_MEMORY_VALUE = '0
    ) (
    input logic clk,
    input logic rst,
    input logic read_en,
    input logic write_en,
    input logic [31:0] address,
    input logic [31:0] write_data,
    output logic [31:0] read_data
    );

    // Number of valid address bits
    localparam MEMORY_ADDRESS_BITS = $clog2(MEMORY_WORDS);
    // Number of upper bits to check for address match. 
    localparam UPPER_ADDRESS_BITS_TO_CHECK = 32 - MEMORY_ADDRESS_BITS - 2;

    // Address bits for indexing memory array

    // Data memory
    (* rom_style = "block" *) logic [31:0] memory_contents [0:MEMORY_WORDS-1];
    logic valid_address;

    // Initialize Memory
    initial
    begin
        integer i;
        // Load the Instruction Memory
        if (MEMORY_FILENAME == "") begin
            $display("**** No %s memory file defined", MEMORY_NAME);
            if (FINISH_ON_NOFILE)
                $finish;
        end
        else begin
            // Initialize memory with default value
            for (i = 0; i < MEMORY_WORDS; i=i+1)
                memory_contents[i] = DEFAULT_MEMORY_VALUE;
            // Update memory with contents of memory file
            $readmemh(MEMORY_FILENAME,memory_contents);
        end

        // Debug messages for simulation

        // synthesis translate_off
        if (^memory_contents[0] === 1'bX || memory_contents[0] == DEFAULT_MEMORY_VALUE ) begin
            $display("**** No %s memory file defined", MEMORY_NAME);
            if (FINISH_ON_NOFILE)
                $finish;
        end
        else
            $display("**** %s memory file '%s' loaded ****", MEMORY_NAME, MEMORY_FILENAME);
        // synthesis translate_on
    end

    // Is the address valid for this memory?
    assign valid_address = 
        (address[31:UPPER_ADDRESS_BITS_TO_CHECK] == MEMORY_OFFSET[31:UPPER_ADDRESS_BITS_TO_CHECK]);

    // Data Memory Read (synchronous)
    always_ff @(posedge clk)
    begin
        if(write_en == 1 && valid_address) begin
            memory_contents[address[MEMORY_ADDRESS_BITS-1:2]] <= write_data;
            // synthesis translate_off
            if (PRINT_MEMORY_TRANSACTIONS)
                $display("%0t:Writing 0x%h to address 0x%h",$time, write_data, address);
            // synthesis translate_on	
        end
        // synthesis translate_off
        if (PRINT_MEMORY_TRANSACTIONS && read_en && valid_address)
            $display("%0t:Reading 0x%h from address 0x%h",$time, memory_contents[address[MEMORY_ADDRESS_BITS-1:2]], address);
        // synthesis translate_on			
        read_data <= memory_contents[address[MEMORY_ADDRESS_BITS-1:2]];   
    end

endmodule
