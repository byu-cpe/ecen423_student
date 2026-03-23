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
    tester = repo_test_suite.build_test_suite("lab11", start_date="03/18/2026", max_repo_files = 30)
    tester.add_required_repo_files(["riscv_final.sv",])
    sim_test1 = tester.add_makefile_test("sim_riscv_final", [], ["sim_riscv_final.log"])
    sim_test1.add_test(repo_test.file_regex_check(tester, "sim_riscv_final.log", "===== TEST PASSED =====",
        "testbench check", error_on_match = False,
        error_msg = "testbench failed"))
    sim_test2 = tester.add_makefile_test("fib_main.log", [], ["fib_main.log"], timeout_seconds= 60*40)
    sim_test2.add_test(repo_test.file_regex_check(tester, "fib_main.log", "s0\s+0x0000000f",
        "s0 check", error_on_match = False, error_msg = "s0 incorrect"))
    sim_test2.add_test(repo_test.file_regex_check(tester, "fib_main.log",
        "Mem\[0x00002000\]\s0x00000000\s+0x00000001\s+0x00000001\s+0x00000002",
        "Mem check", error_on_match = False, error_msg = "Mem incorrect"))
    sim_test2.add_test(repo_test.file_regex_check(tester, "fib_main.log",
        "Mem\[0x00002010\]\s0x00000003\s+0x00000005\s+0x00000008\s+0x0000000d",
        "Mem check", error_on_match = False, error_msg = "Mem incorrect"))
    sim_test2.add_test(repo_test.file_regex_check(tester, "fib_main.log",
        "Mem\[0x00002020\]\s0x00000015\s+0x00000022\s+0x00000037\s+0x00000059",
        "Mem check", error_on_match = False, error_msg = "Mem incorrect"))
    sim_test2.add_test(repo_test.file_regex_check(tester, "fib_main.log",
        "Mem\[0x00002030\]\s0x00000090\s+0x000000e9\s+0x00000179\s+0x00000000",
        "Mem check", error_on_match = False, error_msg = "Mem incorrect"))
    sim_test2.add_test(repo_test.file_regex_check(tester, "fib_main.log",
        "Mem\[0x00002040\]\s0x00000000\s+0x00000001\s+0x00000001\s+0x00000002",
        "Mem check", error_on_match = False, error_msg = "Mem incorrect"))
    sim_test2.add_test(repo_test.file_regex_check(tester, "fib_main.log",
        "Mem\[0x00002050\]\s0x00000003\s+0x00000005\s+0x00000008\s+0x0000000d",
        "Mem check", error_on_match = False, error_msg = "Mem incorrect"))
    sim_test2.add_test(repo_test.file_regex_check(tester, "fib_main.log",
        "Mem\[0x00002060\]\s0x00000015\s+0x00000022\s+0x00000037\s+0x00000059",
        "Mem check", error_on_match = False, error_msg = "Mem incorrect"))
    sim_test2.add_test(repo_test.file_regex_check(tester, "fib_main.log",
        "Mem\[0x00002070\]\s0x00000090\s+0x000000e9\s+0x00000179\s+0x00000000",
        "Mem check", error_on_match = False, error_msg = "Mem incorrect"))
    sim_test3 = tester.add_makefile_test("sim_riscv_final_fib", [], ["sim_riscv_final_fib.log"])
    sim_test3.add_test(repo_test.file_regex_check(tester, "sim_riscv_final_fib.log", "===== TEST PASSED =====",
        "testbench check", error_on_match = False, error_msg = "testbench failed"))
    tester.add_makefile_test("riscv_final.dcp", ["riscv_final.sv"], 
                             ["riscv_final.log"])
    tester.run_main()

if __name__ == "__main__":
    main()
