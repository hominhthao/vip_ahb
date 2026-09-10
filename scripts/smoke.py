#!/usr/bin/env python3
"""Compile and run standalone Master and Slave transaction smoke tests."""

from pathlib import Path
import shlex
import subprocess


def run_smoke(project_root, role):
    build_dir = project_root / "work" / f"{role}_transaction_smoke"
    build_dir.mkdir(parents=True, exist_ok=True)
    top = f"fpt_ahb_{role}_transaction_smoke_top"
    compile_command = [
        "vcs", "-full64", "-sverilog",
        "-ntb_opts", "uvm-1.2", "+vcs+lic+wait",
        f"+incdir+{project_root / 'vip' / 'include'}",
        f"+incdir+{project_root / 'vip' / 'src'}",
        str(project_root / "vip" / "include" / "fpt_ahb_if.svh"),
        str(project_root / "vip" / "src" / "fpt_ahb_package.sv"),
        str(project_root / "vip" / "example" / "test" /
            f"{top}.sv"),
        "-top", top,
        "-o", "simv", "-l", "compile.log",
    ]
    run_command = ["./simv", "+ntb_random_seed=1", "-l", "run.log"]
    print(f"Project root: {project_root}", flush=True)
    print(f"Build directory: {build_dir}", flush=True)
    for stage, command in [("compile", compile_command), ("simulation", run_command)]:
        print(f"{stage}: {shlex.join(command)}", flush=True)
        try:
            result = subprocess.run(command, cwd=build_dir, check=False)
        except OSError as error:
            print(f"FAIL: {stage}: {error}", flush=True)
            return 1
        if result.returncode != 0:
            print(f"FAIL: {stage} return code {result.returncode}", flush=True)
            return result.returncode

    # Require the test's completion marker as well as a successful process exit.
    run_log = (build_dir / "run.log").read_text(encoding="utf-8", errors="replace")
    if f"PASS: {role} transaction smoke test (" not in run_log:
        print("FAIL: smoke test completion marker missing", flush=True)
        return 1
    print(f"PASS: {role} transaction smoke compile and simulation (seed=1).", flush=True)
    return 0


def main():
    project_root = Path(__file__).resolve().parent.parent
    for role in ("master", "slave"):
        return_code = run_smoke(project_root, role)
        if return_code != 0:
            return return_code
    print("PASS: both transaction smoke tests.", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
