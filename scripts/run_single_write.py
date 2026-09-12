#!/usr/bin/env python3
"""Compatibility wrapper for the single-WRITE integration test."""

import sys

from run_test import main


if __name__ == "__main__":
    args = sys.argv[1:]
    if "--test" not in args:
        args = ["--test", "fpt_ahb_single_write_test"] + args
    raise SystemExit(main(args))
