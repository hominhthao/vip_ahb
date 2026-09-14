# FPT AHB VIP v0.1 Plan

## Goal

**Reusable VIP Foundation First, Then Full Burst + WAIT**

v0.1 improves the frozen v0.0 foundation before extending protocol behavior.
The result must remain configurable and reusable by third-party users rather
than being architecturally tied to one DUT or memory use-case.

The verified v0.1 configuration is one Master and one Slave. This is not a
permanent architectural limitation. Component responsibilities and data flow
are defined in `docs/ARCHITECTURE.md`.

## In Scope

- reusable Environment and configuration foundation;
- separate Agent Monitor, System Monitor, and System Checker responsibilities;
- optional memory Predictor / Reference Model;
- READ and WRITE;
- WORD transfers only;
- OKAY-focused stimulus and signoff;
- SINGLE, INCR, INCR4/8/16, and WRAP4/8/16;
- IDLE, BUSY, NONSEQ, and SEQ;
- configurable ZERO, FIXED, and RANDOM WAIT;
- basic reset-during-burst recovery;
- burst-aware observation and checking;
- SVA and functional coverage;
- directed tests and constrained-random regression;
- frozen v0.0 regression compatibility.

Existing ERROR-related code is retained for backward compatibility, but ERROR
enhancement is not part of v0.1.

## Deferred

- full functional multi-Master or multi-Slave operation;
- routing, arbitration, or interconnect implementation;
- BYTE or HALFWORD transfers;
- ERROR enhancement;
- advanced `HPROT`, `HMASTLOCK`, and other sideband behavior;
- advanced/random reset stress;
- unnecessary Proxy, Converter, transport Struct, or HDL BFM layers;
- a virtual sequencer without a concrete approved need.

## Phase 1 — Reusable VIP Foundation

1. Synchronize and freeze v0.1 architecture documentation.
2. Add Environment-level configuration for Agent configuration, topology,
   WAIT/performance policy, and optional checking/prediction policy.
3. Define the System Monitor foundation for future source, destination, and
   system-level context; do not rename the Scoreboard to System Monitor.
4. Evolve the current Scoreboard toward a generic System Checker for
   Master/Slave matching and transaction/data integrity.
5. Separate memory prediction into an optional Predictor / Reference Model.
   Keep it independent of Slave common memory.
6. Remove `HSEL` ownership from the Master protocol Driver. Use a simple
   TB/top-level selection policy for the verified point-to-point configuration.
7. Verify and correct WAIT timing with SINGLE traffic before burst integration.
8. Provide ZERO_WAIT, FIXED_WAIT, and RANDOM_WAIT configuration with fixed,
   minimum, and maximum cycle controls.
9. Review transaction randomization so configurable stimulus fields may remain
   `rand` while constraints, sequences, and Drivers enforce legal behavior.
10. Run the complete maintained v0.0 regression after foundation changes.

## Phase 2 — Full Burst + WAIT

1. Freeze the burst transaction contract:
   - one Master sequence item is one burst request;
   - one Monitor observation is one completed active beat;
   - one System Checker check/count unit is one completed active beat;
   - Slave response behavior remains per beat;
   - `expected_count` and `checked_count` remain completed-beat counts.
2. Add all `HBURST` definitions.
3. Add burst metadata and finite `num_beats` policy. Undefined INCR uses a
   planned default constrained range of 2 through 16 beats, configurable by
   sequence or test.
4. Add reusable generation-side burst address calculation.
5. Enforce WORD alignment, four-byte increments, WRAP boundaries, and the AHB
   1 KB boundary. Keep Checker progression independently verifiable.
6. Extend Master Sequence and Driver for burst-level requests.
7. Enforce legal runtime `HTRANS` progression:
   - first active beat is NONSEQ;
   - later active beats are SEQ;
   - BUSY is optional and does not consume a beat;
   - idle bus uses IDLE.
8. Extend Slave behavior per active beat without premature memory updates.
9. Extend Agent Monitors to reconstruct completed beats and actual WAIT from bus
   signals, independently of Driver/Sequence intent.
10. Extend System Checker burst state and progression checking.
11. Bring up protocol flows incrementally:
    - INCR4 WRITE, zero wait;
    - INCR4 READ, zero wait;
    - INCR4 with WAIT;
    - remaining fixed INCR bursts;
    - WRAP bursts;
    - undefined-length INCR;
    - BUSY insertion and resume.
12. Verify WAIT on first, middle, and final burst beats. Low `HREADY` must not
    advance beat or address state.
13. Implement basic reset recovery: abort incomplete state, clear pending
    Driver/Monitor state, avoid incomplete check/commit, and return to IDLE.

## Phase 3 — Verification Quality

1. Extend SVA for WAIT stability, burst legality, accepted transfers, legal
   NONSEQ/SEQ progression, BUSY, and basic reset recovery.
2. Add functional coverage for:
   - `HBURST` and `HTRANS`;
   - READ and WRITE;
   - WAIT and no-WAIT;
   - burst by direction;
   - burst by wait mode;
   - relevant beat positions and transitions.
3. Add directed tests for every supported burst, READ/WRITE, WAIT positions,
   BUSY, back-to-back traffic, boundary rules, and reset recovery.
4. Run legal constrained-random stress with 100 and 1000 Master burst-level
   sequence requests. Checker expected/checked totals remain counts of completed
   active beats.
5. Add automatic/random-seed regression and failing-seed reproduction.
6. Run the complete frozen v0.0 regression.
7. Review representative waveforms and record known limitations.

## Exit Criteria

v0.1 is complete only when:

- reusable responsibility boundaries are implemented and documented;
- verified topology remains `1M / 1S` without becoming a permanent hardcode;
- System Monitor and System Checker remain separate responsibilities;
- generic checking does not require a memory-like target;
- HSEL is no longer owned by the Master Driver;
- SINGLE WAIT timing passes before burst WAIT signoff;
- all supported HBURST types have directed READ/WRITE evidence;
- WAIT works at multiple beat positions without advancing state;
- BUSY and basic reset recovery are verified;
- Monitors reconstruct completed beats and actual WAIT correctly;
- Checker expected and checked beat counts match with zero mismatches;
- required SVA and functional coverage evidence is collected;
- random stress with 100/1000 Master burst-level sequence requests is
  reproducible by seed;
- no unexpected `UVM_ERROR` or `UVM_FATAL` occurs;
- the frozen v0.0 regression remains PASS;
- representative waveforms and known limitations are reviewed.
