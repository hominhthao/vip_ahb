#!/usr/bin/env python3
"""Compile and run a supported AHB VIP UVM test with VCS."""

import argparse
import os
from pathlib import Path
import shlex
import shutil
import subprocess


# Logical CLI name -> existing UVM test. Add a new entry only when its test exists.
TESTS = {
    "wait": "fpt_ahb_directed_wait_test",
    "fpt_ahb_single_write_test": "fpt_ahb_single_write_test",
    "fpt_ahb_single_read_test": "fpt_ahb_single_read_test",
    "fpt_ahb_read_after_write_test": "fpt_ahb_read_after_write_test",
    "fpt_ahb_random_rw_test": "fpt_ahb_random_rw_test",
    "fpt_ahb_directed_burst_test": "fpt_ahb_directed_burst_test",
    "fpt_ahb_multi_collision_test": "fpt_ahb_multi_collision_test",
}


def parse_args(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--list", action="store_true", help="list supported logical tests")
    parser.add_argument("--test", default="fpt_ahb_read_after_write_test",
                        help="logical test name (see --list)")
    parser.add_argument("--dir", choices=("read", "write"), dest="direction",
                        help="transfer direction for --test wait")
    parser.add_argument("--wait", type=int, help="non-negative WAIT cycles for --test wait")
    parser.add_argument("--seed", type=int, default=1, help="simulator random seed (default: 1)")
    parser.add_argument("--fsdb", "--wave", action="store_true", dest="fsdb",
                        help="compile with FSDB enabled and dump a waveform")
    parser.add_argument("--no-wave", action="store_false", dest="fsdb",
                        help="legacy spelling to disable FSDB")
    parser.add_argument("--dry-run", action="store_true",
                        help="print build and simulation commands without running them")
    parser.set_defaults(fsdb=False)
    args, extra_args = parser.parse_known_args(argv)

    if args.list:
        return args, extra_args
    if args.test not in TESTS:
        parser.error(f"unknown test '{args.test}'; use --list to see supported tests")
    if args.test == "wait":
        if args.direction is None:
            parser.error("--test wait requires --dir read|write")
        if args.wait is None:
            parser.error("--test wait requires --wait <non-negative integer>")
        if args.wait < 0:
            parser.error("--wait must be non-negative")
    elif args.direction is not None or args.wait is not None:
        parser.error("--dir and --wait are supported only with --test wait")
    return args, extra_args


def build_directory(project_root, args):
    if args.test == "wait":
        case = f"{args.direction.upper()}_W{args.wait}_SEED{args.seed}"
        return project_root / "work" / "vip_run" / "wait" / case
    return project_root / "work" / "vip_run" / TESTS[args.test]


def compile_command(project_root, fsdb):
    command = [
        "vcs", "-full64", "-sverilog", "-timescale=1ns/1ps",
        "-ntb_opts", "uvm-1.2", "+vcs+lic+wait", "-cm", "assert",
    ]
    if fsdb:
        command += ["-debug_access+all", "-kdb", "+define+FPT_AHB_ENABLE_FSDB"]
    command += [
        f"+incdir+{project_root / 'vip/include'}",
        f"+incdir+{project_root / 'vip/src'}",
        f"+incdir+{project_root / 'vip/example'}",
        f"+incdir+{project_root / 'vip/example/tb'}",
        str(project_root / "vip/include/fpt_ahb_if.svh"),
        str(project_root / "vip/src/fpt_ahb_package.sv"),
        str(project_root / "vip/example/fpt_ahb_example_package.sv"),
        str(project_root / "vip/example/tb/fpt_ahb_tb_top.sv"),
        "-top", "fpt_ahb_tb_top", "-o", "simv", "-l", "compile.log",
    ]
    return command


def simulation_command(args, extra_args, log_name):
    command = [
        "./simv", f"+UVM_TESTNAME={TESTS[args.test]}",
    ]
    if args.test == "wait":
        command += [
            f"+FPT_AHB_WRITE={int(args.direction == 'write')}",
            f"+FPT_AHB_WAIT_CYCLES={args.wait}",
        ]
    command += [
        f"+ntb_random_seed={args.seed}", "+UVM_NO_RELNOTES",
        "-no_save", "-cm", "assert", "-l", log_name,
    ]
    if extra_args:
        command.extend(extra_args)
    return command


def run_stage(stage, command, build_dir, environment):
    print(f"{stage}: {shlex.join(command)}", flush=True)
    try:
        result = subprocess.run(command, cwd=build_dir, env=environment, check=False)
    except OSError as error:
        print(f"FAIL: {stage}: {error}", flush=True)
        return 1
    print(f"{'PASS' if result.returncode == 0 else 'FAIL'}: "
          f"{stage} return code {result.returncode}", flush=True)
    return result.returncode


def main(argv=None):
    args, extra_args = parse_args(argv)
    if args.list:
        print("Available tests:")
        for name, uvm_test in TESTS.items():
            print(f"  {name}: {uvm_test}")
        return 0

    project_root = Path(__file__).resolve().parent.parent
    build_dir = build_directory(project_root, args)
    environment = os.environ.copy()
    if args.fsdb and not environment.get("VERDI_HOME"):
        verdi = shutil.which("verdi")
        if verdi:
            environment["VERDI_HOME"] = str(Path(verdi).resolve().parent.parent)

    if args.test == "wait":
        log_name = (f"run_WAIT_{args.direction.upper()}_W{args.wait}_SEED{args.seed}"
                    f"{'_fsdb' if args.fsdb else ''}.log")
    else:
        log_name = "run.log"

    build_cmd = compile_command(project_root, args.fsdb)
    run_cmd = simulation_command(args, extra_args, log_name)
    print(f"Build directory: {build_dir}", flush=True)
    if args.dry_run:
        print(f"compile: {shlex.join(build_cmd)}")
        print(f"simulation: {shlex.join(run_cmd)}")
        print("DRY RUN: no commands executed")
        return 0

    build_dir.mkdir(parents=True, exist_ok=True)
    # Preserve the existing clean-build behavior so FSDB/non-FSDB flags cannot
    # accidentally reuse a simv from the other configuration.
    subprocess.run(["rm", "-rf", "csrc", "simv", "simv.daidir"],
                   cwd=build_dir, check=False)
    if run_stage("compile", build_cmd, build_dir, environment) != 0:
        print("FAIL: selected testbench compile failed; simv is unavailable", flush=True)
        return 1
    if not (build_dir / "simv").is_file():
        print(f"FAIL: missing {build_dir / 'simv'}; compile the selected testbench",
              flush=True)
        return 1
    result = run_stage("simulation", run_cmd, build_dir, environment)
    if result != 0:
        print(f"FAIL: {args.test} (seed={args.seed})", flush=True)
        return result

    run_log = (build_dir / log_name).read_text(encoding="utf-8", errors="replace")
    if "UVM_ERROR :    0" not in run_log or "UVM_FATAL :    0" not in run_log:
        print("FAIL: simulation completed with UVM errors or fatals", flush=True)
        return 1
    if args.fsdb and not (build_dir / "ahb_vip.fsdb").is_file():
        print("FAIL: FSDB was requested but ahb_vip.fsdb was not generated", flush=True)
        return 1
    print(f"PASS: {args.test} (seed={args.seed}); log={build_dir / log_name}", flush=True)
    if args.fsdb:
        print(f"FSDB: {build_dir / 'ahb_vip.fsdb'}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
