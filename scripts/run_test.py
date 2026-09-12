#!/usr/bin/env python3
"""Compile the example testbench and run one UVM test with VCS."""

import argparse
import os
from pathlib import Path
import shlex
import shutil
import subprocess


def parse_args(argv=None):
    parser = argparse.ArgumentParser()
    parser.add_argument("--test", default="fpt_ahb_read_after_write_test")
    parser.add_argument("--seed", type=int, default=1)
    parser.add_argument("--wave", action="store_true")
    parser.add_argument("--no-wave", action="store_false", dest="wave")
    return parser.parse_args(argv)


def run_stage(stage, command, build_dir, environment):
    print(f"{stage}: {shlex.join(command)}", flush=True)
    try:
        result = subprocess.run(command, cwd=build_dir, env=environment, check=False)
    except OSError as error:
        print(f"FAIL: {stage}: {error}", flush=True)
        return 1
    print(
        f"{'PASS' if result.returncode == 0 else 'FAIL'}: "
        f"{stage} return code {result.returncode}",
        flush=True,
    )
    return result.returncode


def main(argv=None):
    args = parse_args(argv)
    project_root = Path(__file__).resolve().parent.parent
    build_dir = project_root / "work" / "vip_run" / args.test
    build_dir.mkdir(parents=True, exist_ok=True)
    environment = os.environ.copy()

    compile_command = [
        "vcs", "-full64", "-sverilog", "-timescale=1ns/1ps",
        "-ntb_opts", "uvm-1.2", "+vcs+lic+wait", "-cm", "assert",
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
    if args.wave:
        compile_command[9:9] = [
            "-debug_access+all", "-kdb", "+define+FPT_AHB_ENABLE_FSDB"
        ]
        if not environment.get("VERDI_HOME"):
            verdi = shutil.which("verdi")
            if verdi:
                environment["VERDI_HOME"] = str(Path(verdi).resolve().parent.parent)

    run_command = [
        "./simv", f"+UVM_TESTNAME={args.test}",
        f"+ntb_random_seed={args.seed}", "+UVM_NO_RELNOTES",
        "-no_save", "-cm", "assert", "-l", "run.log",
    ]

    print(f"Project root: {project_root}", flush=True)
    print(f"Build directory: {build_dir}", flush=True)
    if run_stage("compile", compile_command, build_dir, environment) != 0:
        return 1
    if run_stage("simulation", run_command, build_dir, environment) != 0:
        return 1

    run_log = (build_dir / "run.log").read_text(encoding="utf-8", errors="replace")
    if "UVM_ERROR :    0" not in run_log or "UVM_FATAL :    0" not in run_log:
        print("FAIL: simulation completed with UVM errors or fatals", flush=True)
        return 1
    print(f"PASS: UVM test {args.test} (seed={args.seed})", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
