#!/usr/bin/env python3
"""Compile the reusable AHB VIP library package; do not run simulation."""

from pathlib import Path
import shlex
import subprocess


def main():
    project_root = Path(__file__).resolve().parent.parent
    build_dir = project_root / "work" / "package_compile"
    build_dir.mkdir(parents=True, exist_ok=True)

    top_file = build_dir / "fpt_ahb_compile_top.sv"
    top_file.write_text(
        """module fpt_ahb_compile_top;
    import uvm_pkg::*;
    import fpt_ahb_package::*;

    initial begin
        $display("Compile-check executable started.");
        $finish;
    end

endmodule : fpt_ahb_compile_top
""",
        encoding="utf-8",
    )

    command = [
        "vcs",
        "-full64",
        "-sverilog",
        "-ntb_opts", "uvm-1.2",
        "+vcs+lic+wait",
        f"+incdir+{project_root / 'vip' / 'include'}",
        f"+incdir+{project_root / 'vip' / 'src'}",
        str(project_root / "vip" / "include" / "fpt_ahb_if.svh"),
        str(project_root / "vip" / "src" / "fpt_ahb_package.sv"),
        str(top_file),
        "-top", "fpt_ahb_compile_top",
        "-o", "simv",
        "-l", "compile.log",
    ]

    print(f"Project root: {project_root}", flush=True)
    print(f"Build directory: {build_dir}", flush=True)
    print(f"VCS command: {shlex.join(command)}", flush=True)

    try:
        result = subprocess.run(command, cwd=build_dir, check=False)
    except OSError as error:
        print(f"FAIL: could not launch VCS: {error}", flush=True)
        return 1

    if result.returncode == 0:
        print("PASS: compile completed.", flush=True)
    else:
        print(f"FAIL: VCS return code {result.returncode}", flush=True)
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
