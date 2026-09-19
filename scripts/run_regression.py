#!/usr/bin/env python3
"""Run the maintained AHB v0.1 integration tests as a regression."""

import sys
from run_test import main as run_test_main

def main():
    # Pass all command line arguments down to run_test (e.g., --fsdb, +PERF_MODE=LOW, +UVM_VERBOSITY=UVM_HIGH)
    user_args = sys.argv[1:]

    # Base tests and their seeds
    tests = [
        # Single tests
        ("fpt_ahb_single_write_test", 1),
        ("fpt_ahb_single_read_test", 1),
        # Random R/W with different seeds
        ("fpt_ahb_random_rw_test", 100),
        ("fpt_ahb_random_rw_test", 200),
        ("fpt_ahb_random_rw_test", 300),
        # Read After Write
        ("fpt_ahb_read_after_write_test", 1),
        # Directed Burst
        ("fpt_ahb_directed_burst_test", 1),
        # Multi Collision
        ("fpt_ahb_multi_collision_test", 1),
    ]
    failed_tests = []

    print("=" * 60)
    print("STARTING AHB VIP REGRESSION SUITE (V0.1)")
    print(f"Total tests queued: {len(tests)}")
    if user_args:
        print(f"Extra arguments: {' '.join(user_args)}")
    print("=" * 60)

    for index, (test_name, seed) in enumerate(tests, start=1):
        print(f"\n[{index}/{len(tests)}] Running {test_name} (seed={seed})")
        
        args_list = ["--test", test_name, "--seed", str(seed)] + user_args
        return_code = run_test_main(args_list)
        
        if return_code != 0:
            failed_tests.append((test_name, seed))

    print("\n" + "=" * 60)
    print("REGRESSION SUMMARY")
    print(f"Total: {len(tests)}")
    print(f"Passed: {len(tests) - len(failed_tests)}")
    print(f"Failed: {len(failed_tests)}")
    for test_name, seed in failed_tests:
        print(f"FAIL: {test_name} (seed={seed})")
    print("=" * 60)

    return 1 if failed_tests else 0

if __name__ == "__main__":
    raise SystemExit(main())
