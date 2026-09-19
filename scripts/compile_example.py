#!/usr/bin/env python3
from pathlib import Path
import subprocess

project_root = Path(__file__).resolve().parent.parent
build_dir = project_root / "work" / "example_compile"
build_dir.mkdir(parents=True, exist_ok=True)

top_file = build_dir / "fpt_ahb_tb_top.sv"

command = [
    "vcs", "-full64", "-sverilog", "-ntb_opts", "uvm-1.2", "+vcs+lic+wait",
    f"+incdir+{project_root / 'vip' / 'include'}",
    f"+incdir+{project_root / 'vip' / 'src'}",
    f"+incdir+{project_root / 'vip' / 'example'}",
    str(project_root / "vip" / "include" / "fpt_ahb_if.svh"),
    str(project_root / "vip" / "src" / "fpt_ahb_package.sv"),
    str(project_root / "vip" / "example" / "fpt_ahb_example_package.sv"),
    str(project_root / "vip" / "example" / "tb" / "fpt_ahb_th.sv"),
    str(project_root / "vip" / "example" / "tb" / "fpt_ahb_tb_top.sv"),
    "-top", "fpt_ahb_tb_top",
    "-o", "simv", "-l", "compile.log"
]

res = subprocess.run(command, cwd=build_dir)
print(f"VCS return code {res.returncode}")
