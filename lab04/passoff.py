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
    tester = repo_test_suite.build_test_suite("lab04", start_date="01/25/2026",
        max_repo_files = 30)
    tester.add_required_repo_files(["fact_rec_78.s", "fib_iterative.s", "fib_recursive.s"])
    fact_rec_78 = tester.add_makefile_test("fact_rec_78", ["fact_rec_78.s"], ["fact_rec_78.out"])
    fact_rec_78.add_test(repo_test.file_regex_check(tester, "fact_rec_78.out", "\!7 \+ \!8 = 45360",
        "fact_rec_78 output check", error_on_match = False,
        error_msg = "fact_rec_78 output incorrect"))
    fib_iterative = tester.add_makefile_test("fib_iterative", ["fib_iterative.s"], ["fib_iterative.out"])
    fib_iterative.add_test(repo_test.file_regex_check(tester, "fib_iterative.out", "Fibonacci Number of 25 is 75025",
        "fib_iterative output check", error_on_match = False,
        error_msg = "fib_iterative output incorrect"))
    fib_recursive = tester.add_makefile_test("fib_recursive", ["fib_recursive.s"], [])
    fib_recursive.add_test(repo_test.file_regex_check(tester, "fib_recursive.out", "Fibonacci Number of 25 is 75025",
        "fib_recursive output check", error_on_match = False,
        error_msg = "fib_recursive output incorrect"))
    tester.run_main()
 
if __name__ == "__main__":
    main()

