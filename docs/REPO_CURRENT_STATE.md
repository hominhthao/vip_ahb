# REPO_CURRENT_STATE.md

Updated: 2026-09-10

- Branch: `feature/common-memory`
- Current checkpoint: `edb9160 Add independent AHB v0.0 scoreboard`
- Previous checkpoint: `d25ba11 Add shared AHB common memory`
- Generated files under `work/` and untracked `verdiLog/` are not project source.

## Completed Checkpoints

### Transaction Layer

The frozen transaction layer contains separate
`fpt_ahb_master_transaction` and `fpt_ahb_slave_transaction` classes. Both use
the shared address/data width macros and represent one WORD/SINGLE READ or WRITE.
Their approved randomization, constraints, print, compare, copy, and clone
semantics remain unchanged. This layer is frozen.

### Common Memory

`fpt_ahb_common_memory` is a standalone `uvm_object` with sparse associative
storage keyed by the full byte address. Its 2-state address/data types use the
project width macros. It provides:

```text
write(addr, data)
read(addr)
clear()
```

An unwritten address returns zero without allocating an entry. Overwrite replaces
the previous value and `clear()` deletes entries without replacing the object.
The class contains no clock, reset, interface, Driver, or protocol behavior.

The future Environment creates one runtime object and passes the same handle to
the Slave Agent and Slave Driver. The Master Driver must obtain read data from
HRDATA and must not access common memory directly.

### Scoreboard

`fpt_ahb_scoreboard` owns separate Master and Slave analysis FIFOs and pairs
completed observations in order for the one-Master/one-Slave v0.0 topology. It
checks address, direction, size, burst, response, and WRITE data where applicable.

The Scoreboard owns an independent sparse reference memory. It does not receive
or read the Slave common-memory handle. Successful matched WRITEs update expected
state; ERROR WRITEs do not. Successful READs compare both observed data values
against expected state, with zero for unwritten addresses. ERROR READ data is
ignored. `check_phase()` reports unpaired observations.

## Verification Evidence

Run from the repository root:

```bash
python3 scripts/common_memory_smoke.py
python3 scripts/scoreboard_smoke.py
```

Latest verified results with VCS X-2025.06 Full64 and UVM 1.2:

- Common memory: compile return code 0, simulation return code 0, and
  `PASS: common memory package compile and smoke`.
- Scoreboard: compile return code 0, simulation return code 0, and
  `PASS: scoreboard smoke test (checked=14 passed=10 mismatches=5)`.
- The four deliberate negative Scoreboard scenarios produce five expected
  mismatch messages. The report catcher verifies and demotes them; the final UVM
  summary is zero errors and zero fatals.
- Re-running the common-memory smoke after adding the Scoreboard confirms the
  real package and both components still compile together.

Logs:

```text
work/common_memory_smoke/compile.log
work/common_memory_smoke/run.log
work/scoreboard_smoke/compile.log
work/scoreboard_smoke/run.log
```

These are object/component-level tests. They do not prove end-to-end bus timing.

## Open Integration Work

- The current Master Agent, Driver, Monitor, and configuration classes exist and
  compile with their required Interface/include paths. Their bus timing is not
  frozen until real Master/Slave integration is verified.
- Complete and independently verify Slave Agent, Driver, Monitor, configuration,
  and default response Sequence.
- Complete the approved HREADY/HREADYOUT point-to-point Interface contract.
- Create the Environment and TB top, instantiate the one shared common-memory
  object, and distribute its handle only to Slave consumers.
- Connect Master and Slave Monitor analysis ports to the Scoreboard FIFOs.
- Run real WRITE followed by READ at the same address, then back-to-back and
  wait-state cases with Scoreboard checking and waveform review.

A temporary Master/responder integration probe indicated possible Master data-phase
alignment and result-sampling problems for READ, back-to-back WRITE, and wait-state
cases. Because the responder was temporary, retain this as integration evidence
and re-check it with the real Slave and waveform before changing Master timing.

## Deferred Scope

The following remain outside the current implementation:

- multi-Slave/interconnect architecture;
- burst types beyond SINGLE;
- transfer sizes beyond WORD;
- byte enables, memory regions, protection, ECC, and richer memory policies;
- final reset/clear and timeout policies;
- functional coverage expansion and end-to-end regression infrastructure.
