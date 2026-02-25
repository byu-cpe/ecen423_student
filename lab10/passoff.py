#!/usr/bin/python3

# Manages file paths
import pathlib
import sys

sys.dont_write_bytecode = True
resources_path = pathlib.Path(__file__).resolve().parent.parent  / 'resources'
sys.path.append( str(resources_path) )

import repo_test_suite
import repo_test

def main():
    tester = repo_test_suite.build_test_suite("lab10", start_date="03/11/2026", max_repo_files = 30)
    tester.add_required_repo_files(["vga_sim_new.tcl", "vga.jpg", "move_char.s"])
    sim_test1 = tester.add_makefile_test("sim_forwarding_iosystem_tcl", [], ["sim_forwarding_iosystem_tcl.log"])
    sim_test1.add_test(repo_test.file_regex_check(tester, "sim_forwarding_iosystem_tcl.log",
        "Writing 0x00000039 to VGA at address 0x00008004",
        "testbench check", error_on_match = False,
        error_msg = "testbench failed"))
    tester.add_makefile_test("forwarding_iosystem.bit", [], 
                             ["forwarding_iosystem.log"])
    tester.add_makefile_test("forwarding_defuse.bit", [], 
                             ["forwarding_defuse.log"])
    tester.add_makefile_test("forwarding_move_char.bit", [], 
                             ["forwarding_move_char.log"])
    tester.run_main()

if __name__ == "__main__":
    main()
