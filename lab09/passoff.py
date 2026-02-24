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
    tester = repo_test_suite.build_test_suite("lab09", start_date="03/04/2026", max_repo_files = 30)
    tester.add_required_repo_files(["riscv_forwarding_pipeline.sv",])
    sim_test1 = tester.add_makefile_test("sim_riscv_forwarding", [], ["sim_riscv_forwarding.log"])
    sim_test1.add_test(repo_test.file_regex_check(tester, "sim_riscv_forwarding.log", "===== TEST PASSED =====",
        "testbench check", error_on_match = False,
        error_msg = "testbench failed"))
    tester.add_makefile_test("riscv_forwarding_pipeline.dcp", ["riscv_forwarding_pipeline.sv"], 
                             ["riscv_forwarding_pipeline.log"])
    tester.run_main()

if __name__ == "__main__":
    main()
