#!/usr/bin/env python3
"""Compile the real VIP package and run the standalone Scoreboard smoke."""

from pathlib import Path
import shlex
import subprocess


def main():
    project_root = Path(__file__).resolve().parent.parent
    build_dir = project_root / "work" / "scoreboard_smoke"
    build_dir.mkdir(parents=True, exist_ok=True)
    top = "fpt_ahb_scoreboard_smoke_top"
    compile_command = [
        "vcs", "-full64", "-sverilog",
        "-ntb_opts", "uvm-1.2", "+vcs+lic+wait",
        f"+incdir+{project_root / 'vip/include'}",
        f"+incdir+{project_root / 'vip/src'}",
        f"+incdir+{project_root / 'vip/example/tb'}",
        f"+incdir+{project_root / 'vip/example/env/master_agent'}",
        f"+incdir+{project_root / 'vip/example/env/scoreboard'}",
        str(project_root / "vip/example/tb/fpt_ahb_if.svh"),
        str(project_root / "vip/src/fpt_ahb_package.sv"),
        str(project_root / "vip/example/test" / f"{top}.sv"),
        "-top", top, "-o", "simv", "-l", "compile.log",
    ]
    run_command = ["./simv", "-l", "run.log"]

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
        print(f"PASS: {stage} (return code 0)", flush=True)

    run_log = (build_dir / "run.log").read_text(encoding="utf-8", errors="replace")
    if "PASS: scoreboard smoke test" not in run_log:
        print("FAIL: smoke completion marker missing", flush=True)
        return 1
    if "UVM_ERROR :    0" not in run_log or "UVM_FATAL :    0" not in run_log:
        print("FAIL: unexpected UVM error or fatal", flush=True)
        return 1
    print("PASS: scoreboard package compile and smoke", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
