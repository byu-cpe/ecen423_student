#!/usr/bin/python3

# Manages file paths
import pathlib
import sys

sys.dont_write_bytecode = True # Prevent the bytecodes for the resources directory from being cached
# Add to the system path the "resources" directory relative to the script that was run
resources_path = pathlib.Path(__file__).resolve().parent.parent  / 'resources'
sys.path.append( str(resources_path) )

import repo_test_suite, repo_test

def main():
    tester = repo_test_suite.build_test_suite("buttoncount", start_date="01/06/2026", 
        max_repo_files = 30)
    tester.add_required_repo_files(["buttoncount.sv", ])
    sim_test = tester.add_makefile_test("sim_buttoncount_tb", ["buttoncount.sv"],
                                            ["sim_buttoncount_tb.log"])
    sim_test.add_test(repo_test.file_regex_check(tester, "sim_buttoncount_tb.log",
        "===== TEST PASSED =====",
        "updownbuttoncount testbench check", error_on_match = False,
        error_msg = "updownbuttoncount testbench failed"))
    tester.add_makefile_test("buttoncount_synth.dcp", ["buttoncount.sv"],
                                            ["buttoncount_synth.log"])
    tester.add_makefile_test("buttoncount.bit", ["buttoncount_synth.dcp"],
                             ["buttoncount.bit", "buttoncount_imp.log",
                             "buttoncount_timing.rpt", "buttoncount_utilization.rpt"])
    tester.run_main()

if __name__ == "__main__":
    main()

