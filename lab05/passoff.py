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
    tester = repo_test_suite.build_test_suite("lab05", start_date="02/04/2026",
        max_repo_files = 30)
    tester.add_required_repo_files(["riscv_simple_datapath.sv", "../include/riscv_datapath_constants.sv"])
    sim_test = tester.add_makefile_test("sim_tb_simple_datapath", ["riscv_simple_datapath.sv"], ["sim_tb_simple_datapath.log"])
    sim_test.add_test(repo_test.file_regex_check(tester, "sim_tb_simple_datapath.log", "===== TEST PASSED =====",
        "tb_rtb_simple_datapathgfile testbench check", error_on_match = False,
        error_msg = "tb_simple_datapath testbench failed"))
    tester.add_makefile_test("riscv_simple_datapath_synth.dcp", ["riscv_simple_datapath.sv"], ["riscv_simple_datapath_synth.log"])
    tester.run_main()

if __name__ == "__main__":
    main()

