#!/usr/bin/env python3
"""Run the maintained AHB v0.0 integration tests as a regression."""

from run_test import main as run_test_main


def main():
    tests = [
        ("fpt_ahb_single_write_test", 1),
        ("fpt_ahb_read_after_write_test", 1),
        ("fpt_ahb_random_rw_test", 100),
        ("fpt_ahb_random_rw_test", 200),
        ("fpt_ahb_random_rw_test", 300),
    ]
    failed_tests = []

    print("=" * 60)
    print("STARTING AHB VIP REGRESSION SUITE")
    print(f"Total tests queued: {len(tests)}")
    print("=" * 60)

    for index, (test_name, seed) in enumerate(tests, start=1):
        print(f"\n[{index}/{len(tests)}] Running {test_name} (seed={seed})")
        return_code = run_test_main([
            "--test", test_name,
            "--seed", str(seed),
            "--no-wave",
        ])
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
