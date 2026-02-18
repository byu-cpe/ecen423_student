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
    tester = repo_test_suite.build_test_suite("lab07", start_date="02/18/2026", max_repo_files = 30)
    tester.add_required_repo_files(["iosystem.tcl", "buttoncount.s"])
    tester.add_makefile_test("sim_multicycle_iosystem_tcl", [], ["sim_multicycle_iosystem_tcl.log"])
    tester.add_makefile_test("sim_multicycle_iosystem", [], ["sim_multicycle_iosystem.log"])
    tester.add_makefile_test("multicycle_iosystem.bit", [], ["multicycle_iosystem.bit"])
    tester.add_makefile_test("multicycle_buttoncount.bit", [], ["multicycle_buttoncount.bit"])
    tester.run_main()

if __name__ == "__main__":
    main()
