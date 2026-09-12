#!/usr/bin/env python3
"""Compatibility wrapper for the READ-after-WRITE integration test."""

import sys

from run_test import main


if __name__ == "__main__":
    args = sys.argv[1:]
    if "--test" not in args:
        args = ["--test", "fpt_ahb_read_after_write_test"] + args
    raise SystemExit(main(args))
