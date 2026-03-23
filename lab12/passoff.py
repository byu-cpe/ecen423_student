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
    tester = repo_test_suite.build_test_suite("lab12", start_date="03/30/2026", max_repo_files = 50)
    tester.add_required_repo_files(["custom_font.txt", "custom_background.mem", "instructions.txt",
                                    "project_font.txt", "project.s", "project_background.txt"])
    sim_test1 = tester.add_makefile_test("custom_background.bit", [], [])
    sim_test2 = tester.add_makefile_test("project.bit", [], [])
    tester.run_main()

if __name__ == "__main__":
    main()
