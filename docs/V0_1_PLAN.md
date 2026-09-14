# FPT AHB VIP v0.1 Plan

## 1. Version Goal

**Theme:** Full Burst + WAIT Support + System-ready Architecture

v0.1 enhances the frozen v0.0 baseline instead of rebuilding the VIP.

Primary goals:

- Add full `HBURST` support.
- Add real `WAIT` / `HREADYOUT` behavior.
- Preserve the current class-based UVM architecture.
- Keep the verified topology at **1 Master / 1 Slave** for v0.1.
- Prepare Environment / Checker structures for future multi-agent expansion.
- Preserve all v0.0 behavior and regression results.

## 2. Frozen v0.1 Scope

### In Scope

- READ / WRITE
- WORD transfers only
- OKAY response only
- 1 Master / 1 Slave verified topology
- Full `HBURST`: SINGLE, INCR, INCR4/8/16, WRAP4/8/16
- `HTRANS`: IDLE, BUSY, NONSEQ, SEQ
- WAIT / `HREADY` / `HREADYOUT`
- Configurable Slave performance / wait policy
- Burst-aware Monitor / Checker
- Functional coverage
- Directed burst tests
- Random stress and regression
- System-ready Env / Config / Checker foundation

### Deferred

- ERROR response
- BYTE / HALFWORD support
- Full functional multi-Master / multi-Slave verification
- Interconnect / arbitration
- Full routing implementation
- Advanced sideband behavior
- Advanced protection / lock features

## 3. Architecture Principles

- Keep dynamic protocol behavior in UVM classes.
- Do not add Proxy / Converter / HDL BFM layers.
- Keep static SystemVerilog only where appropriate: interface, tb_top, SVA/assertions.
- v0.1 is an enhancement of v0.0 components, not a new architecture.
- Multi-agent readiness does not mean full multi-agent functionality in v0.1.
- The v0.0 regression must remain valid throughout development.

## 4. Component Enhancement Plan

### 4.1 Architecture / System Environment

- Define System Env responsibility.
- Add `fpt_ahb_env_cfg`.
- Prepare `num_master`, `num_slave`, Master/Slave cfg arrays, and wait/performance policy.
- Keep v0.1 verified topology at `1M / 1S`.
- Define future System Checker and System Monitor responsibilities.
- Prepare source/destination metadata concept for future routing.
- Do not implement full multi-agent routing in v0.1.

### 4.2 Interface / SVA

- Clean up `HSEL` ownership.
- Ensure Master protocol flow does not own Slave selection policy.
- Verify `HREADY` / `HREADYOUT` connections support real wait states.
- Preserve current clocking/interface structure where possible.
- Extend assertions for wait-state stability, burst legality, NONSEQ->SEQ progression, BUSY behavior, and accepted-transfer conditions.

### 4.3 Transaction / Sequence

- Enable full `HBURST` values.
- Enable complete `HTRANS` usage.
- Add burst metadata for burst type, beat index, burst length, start address, current address.
- Define finite sequence policy for undefined-length `INCR`.
- Add reusable burst address generation.
- Support legal constrained-random burst generation.

Initial protocol rules:

- First active beat: `NONSEQ`
- Following active beats: `SEQ`
- `BUSY` does not consume a burst data beat.
- `HREADY == 0` does not advance beat/address state.
- WORD transfer step = 4 bytes.

### 4.4 Master Driver / Monitor

Master Driver:

- Support multi-beat burst execution.
- Generate correct `NONSEQ` / `SEQ`.
- Support `BUSY`.
- Advance burst state only after accepted transfer.
- Hold required protocol information during wait states.
- Preserve v0.0 SINGLE behavior.

Master Monitor:

- Reconstruct actual completed burst beats from bus signals.
- Remain independent from Driver intent.
- Handle pipelined address/data behavior across wait states.
- Publish enough burst metadata for checking.

### 4.5 Slave Driver / Monitor

Slave Driver:

- Support configurable / random `HREADYOUT`.
- HIGH performance -> zero wait.
- Configured/random mode -> bounded wait.
- Process every accepted burst beat.
- Preserve Env-owned common-memory semantics.
- READ common memory for successful reads.
- WRITE common memory only after valid completed writes.

Slave Monitor:

- Reconstruct actual Slave-side burst behavior.
- Measure actual observed wait cycles.
- Publish accepted/completed beat information independently.

### 4.6 Checker / Coverage

- Preserve independent reference memory.
- Check Master vs Slave observations.
- Check burst type, beat count, address progression, direction, data integrity, and response.
- Add pending queues where required for pipelined/waited traffic.
- Prepare future source/destination metadata for multi-agent routing.
- Do not depend on the Slave common memory for expected data.

Functional coverage:

- `HBURST`
- `HTRANS`
- READ / WRITE
- WAIT / no-WAIT
- Burst x direction
- Burst x wait
- Relevant beat / transition coverage

### 4.7 TB / Test / Regression

Directed tests:

- SINGLE compatibility
- INCR
- INCR4
- INCR8
- INCR16
- WRAP4
- WRAP8
- WRAP16
- READ burst
- WRITE burst
- WAIT on first/middle/final beat
- BUSY insertion and resume
- back-to-back transfers / bursts

Random testing:

- legal constrained-random traffic
- 100 transactions
- 1000 transactions
- multiple / automatic seeds
- preserve failing seed for reproduction

Regression requirements:

- all maintained v0.0 tests remain PASS
- no new UVM_ERROR / UVM_FATAL
- no checker mismatch
- SVA clean
- waveform evidence for representative burst/wait scenarios

## 5. Suggested Development Order

1. Freeze architecture and v0.1 scope.
2. Audit v0.0 assumptions related to SINGLE / NONSEQ / wait / 1M1S.
3. Clean up HSEL ownership.
4. Add Env configuration foundation.
5. Define burst transaction model.
6. Implement and verify burst address helper.
7. Extend Master Sequence.
8. Bring up Master burst flow incrementally:
   - INCR4 WRITE, zero wait
   - INCR4 READ, zero wait
   - INCR4 + WAIT
   - remaining INCR bursts
   - WRAP bursts
   - INCR
   - BUSY
9. Extend Slave Driver / Monitor.
10. Extend Master Monitor.
11. Extend System Checker.
12. Add SVA and functional coverage.
13. Add directed tests.
14. Add random stress / regression.
15. Run full v0.0 compatibility regression.
16. Sign off v0.1.

## 6. Team Split

### Master / Burst Track

- HSEL cleanup
- Burst transaction model
- Burst address generation
- Master Sequence
- Master Driver
- Master Monitor
- SVA
- Functional coverage
- Random stress / regression

### Slave / System Track

- System Env / Config
- System Checker foundation
- System Monitor foundation
- Slave WAIT / performance behavior
- Slave burst processing
- Slave Monitor
- Reference/data-integrity checking
- v0.0 compatibility regression

Integration points are reviewed jointly.

## 7. v0.1 Exit Criteria

v0.1 is complete only when:

- All supported HBURST types have directed evidence.
- READ and WRITE burst paths pass.
- WAIT works at multiple positions within a burst.
- BUSY behavior is verified.
- Monitors reconstruct actual completed traffic correctly.
- Checker expected count equals checked count.
- Checker mismatches = 0.
- No unexpected `UVM_ERROR`.
- No `UVM_FATAL`.
- Required SVA checks pass.
- Functional coverage evidence is collected.
- Random stress runs complete with reproducible seeds.
- Frozen v0.0 regression remains PASS.
- Representative waveforms are reviewed.
- Known limitations are documented.

## 8. First Codex Audit Task

Before implementation, run an **audit-only** task.

Codex should identify every v0.0 assumption related to:

- `HBURST == SINGLE`
- `HTRANS == NONSEQ`
- 1 Master / 1 Slave assumptions
- always-ready or bounded hard-coded wait behavior
- HSEL ownership
- one-transfer-per-transaction assumptions
- Monitor pairing assumptions
- Scoreboard FIFO pairing assumptions
- burst-unaware address/data tracking
- tests or scripts that assume SINGLE-only behavior

The audit must report:

- affected file
- affected class/function/task
- current assumption
- why it blocks v0.1
- suggested change
- dependency / risk

**Do not modify any source file during the audit.**
