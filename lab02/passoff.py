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
    tester = repo_test_suite.build_test_suite("lab02", start_date="01/04/2026",
        max_repo_files = 30)
    tester.add_required_repo_files(["alu.sv", "../include/riscv_alu_constants.sv", "alu_sim.tcl", "calc.sv",
                                    "calc_sim.tcl",])
    sim_test = tester.add_makefile_test("sim_tb_alu", ["alu.sv"], ["sim_tb_alu.log"])
    sim_test.add_test(repo_test.file_regex_check(tester, "sim_tb_alu.log", "===== TEST PASSED =====",
        "tb_alu testbench check", error_on_match = False,
        error_msg = "tb_alu testbench failed"))
    sim_test = tester.add_makefile_test("sim_tb_calc", ["calc.sv"], ["sim_tb_calc.log"])
    sim_test.add_test(repo_test.file_regex_check(tester, "sim_tb_calc.log", "===== TEST PASSED =====",
        "tb_calc testbench check", error_on_match = False,
        error_msg = "tb_calc testbench failed"))
    tester.add_makefile_test("calc_synth.dcp", ["calc.sv"], ["calc_synth.log"])
    tester.add_makefile_test("calc.bit", ["calc_synth.dcp"],
                             ["calc.bit", "calc_imp.log",
                             "calc_timing.rpt", "calc_utilization.rpt"])
    tester.run_main()

if __name__ == "__main__":
    main()

