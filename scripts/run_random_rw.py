#!/usr/bin/env python3
import subprocess
from pathlib import Path
import shlex

def main():
    project_root = Path(__file__).resolve().parent.parent
    build_dir = project_root / "work" / "vip_run"
    build_dir.mkdir(parents=True, exist_ok=True)
    
    top = "fpt_ahb_tb_top"
    
    compile_command = [
        "vcs", "-full64", "-sverilog", "-timescale=1ns/1ps",
        "-ntb_opts", "uvm-1.2", "+vcs+lic+wait",
        "-debug_access+all", "-kdb", "-cm", "assert",
        f"+incdir+{project_root / 'vip/include'}",
        f"+incdir+{project_root / 'vip/src'}",
        f"+incdir+{project_root / 'vip/example/tb'}",
        f"+incdir+{project_root / 'vip/example/env'}",
        f"+incdir+{project_root / 'vip/example/env/master_agent'}",
        f"+incdir+{project_root / 'vip/example/env/slave_agent'}",
        f"+incdir+{project_root / 'vip/example/test'}",
        f"+incdir+{project_root / 'vip/example/seq'}",
        f"+incdir+{project_root / 'vip/example/seq/master_seq'}",
        f"+incdir+{project_root / 'vip/example/seq/slave_seq'}",
        str(project_root / "vip/example/tb/fpt_ahb_if.svh"),
        str(project_root / "vip/src/fpt_ahb_package.sv"),
        str(project_root / f"vip/example/tb/{top}.sv"),
        "-top", top, "-o", "simv", "-l", "compile.log",
    ]
    
    run_command = [
        "./simv", 
        "+UVM_TESTNAME=fpt_ahb_random_rw_test", 
        "-l", "run.log", "-cm", "assert", "+ntb_random_seed_automatic"
    ]
    
    print(f"Starting Build & Run at: {build_dir}", flush=True)
    
    subprocess.run(["rm", "-rf", "csrc", "simv", "simv.daidir"], cwd=build_dir)
    
    for stage, cmd in [("COMPILE", compile_command), ("SIMULATION", run_command)]:
        print(f"\n[{stage}] Executing command:\n{shlex.join(cmd)}", flush=True)
        try:
            result = subprocess.run(cmd, cwd=build_dir, check=False)
        except OSError as e:
            print(f"OS Error: Unable to execute command: {e}", flush=True)
            return 1
            
        if result.returncode != 0:
            print(f"FAILED at stage {stage}! Check log.", flush=True)
            return result.returncode
            
    print(f"\nSUCCESS! Simulation completed smoothly.")
    print(f"To view the waveform, navigate to {build_dir} and run: verdi -ssf ahb_vip.fsdb", flush=True)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
