#!/usr/bin/env python3
"""Compatibility wrapper for the single-WRITE integration test."""

from run_raw import main


if __name__ == "__main__":
    raise SystemExit(main(["--test", "fpt_ahb_single_write_test"]))
