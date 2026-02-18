#!/usr/bin/python3

# Manages file paths
import pathlib
import sys

sys.dont_write_bytecode = True # Prevent the bytecodes for the resources directory from being cached
# Add to the system path the "resources" directory relative to the script that was run
resources_path = pathlib.Path(__file__).resolve().parent.parent  / 'resources'
sys.path.append( str(resources_path) )

import repo_test_suite
import repo_test

def main():
    tester = repo_test_suite.build_test_suite("lab06", start_date="02/11/2026",
        max_repo_files = 30)
    tester.add_required_repo_files(["riscv_multicycle.sv", ])
    sim_test1 = tester.add_makefile_test("sim_tb_multicycle", ["riscv_multicycle.sv"], ["sim_tb_multicycle.log"])
    sim_test1.add_test(repo_test.file_regex_check(tester, "sim_tb_multicycle.log", "===== TEST PASSED =====",
        "tb_multicycle testbench check", error_on_match = False,
        error_msg = "tb_multicycle testbench failed"))
    sim_test2 = tester.add_makefile_test("sim_tb_multicycle_bounds", ["riscv_multicycle.sv"], ["sim_tb_multicycle.log"])
    sim_test2.add_test(repo_test.file_regex_check(tester, "sim_tb_multicycle_bounds.log", "===== TEST PASSED =====",
        "tb_multicycle_bounds testbench check", error_on_match = False,
        error_msg = "tb_multicycle_bounds testbench failed"))
    tester.add_makefile_test("riscv_multicycle_synth.dcp", ["riscv_multicycle.sv"], 
                             ["riscv_multicycle_synth.dcp", "riscv_multicycle_synth.log"])
    tester.run_main()

if __name__ == "__main__":
    main()

