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
    tester = repo_test_suite.build_test_suite("lab08", start_date="02/25/2026", max_repo_files = 30)
    tester.add_required_repo_files(["riscv_basic_pipeline.sv","bounds_nop.s"])
    sim_test1 = tester.add_makefile_test("sim_riscv_pipeline", [], ["sim_riscv_pipeline.log"])
    sim_test1.add_test(repo_test.file_regex_check(tester, "sim_riscv_pipeline.log", "===== TEST PASSED =====",
        "testbench check", error_on_match = False,
        error_msg = "testbench failed"))
    sim_test2 = tester.add_makefile_test("sim_bounds_nop", [], ["sim_bounds_nop.log"])
    sim_test2.add_test(repo_test.file_regex_check(tester, "sim_bounds_nop.log", "===== TEST PASSED =====",
        "testbench check", error_on_match = False,
        error_msg = "testbench failed"))
    tester.add_makefile_test("riscv_basic_pipeline.dcp", ["riscv_basic_pipeline.sv"], 
                             ["riscv_basic_pipeline.dcp", "riscv_basic_pipeline.log"])
    tester.run_main()

if __name__ == "__main__":
    main()
