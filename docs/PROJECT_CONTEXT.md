# FPT AHB VIP Project Context

## Project

FPT AHB VIP is a direct UVM/SystemVerilog verification component for AHB-Lite.
It is a new implementation, not a refactor of the legacy VIP, and is intended
to become reusable by third-party users.

Current development context:

- active release: v0.1;
- frozen baseline: v0.0 on `main`;
- active branch: `feature/v0.1-burst-wait`;
- verified v0.1 configuration: one Master and one Slave;
- methodology: UVM / SystemVerilog.

Configuration and useful defaults are acceptable. Architecture must not be
hardcoded for one particular DUT or memory-like use-case.

## Current Objective

v0.1 first improves the v0.0 foundation toward a reusable VIP architecture,
then adds Full Burst + WAIT, and finally adds verification-quality evidence.

The order is:

1. reusable-foundation cleanup;
2. Full Burst + WAIT implementation;
3. coverage, stress, regression, and signoff.

The active plan is `docs/V0_1_PLAN.md`. Architectural responsibilities are
defined in `docs/ARCHITECTURE.md`.

## Verified v0.1 Scope

v0.1 will functionally verify:

- one Master and one Slave;
- READ and WRITE;
- WORD transfers only;
- OKAY-focused stimulus and signoff;
- SINGLE, INCR, INCR4/8/16, and WRAP4/8/16;
- IDLE, BUSY, NONSEQ, and SEQ;
- configurable ZERO, FIXED, and RANDOM WAIT behavior;
- basic reset-during-burst recovery;
- functional coverage;
- directed burst and WAIT tests;
- 100/1000-transaction random stress and seed-based regression.

One Master and one Slave is the verified v0.1 configuration, not a permanent
architectural limit.

## High-Level Architecture Direction

The reusable VIP direction consists of:

- a System Environment and environment-level configuration;
- configurable Master and Slave Agents;
- Agent Monitors for protocol-facing observations;
- a separate System Monitor for system context;
- a generic System Checker for transaction and data integrity;
- an optional Predictor / Reference Model for memory-like behavior.

The current Scoreboard evolves toward the System Checker. It is not renamed to
System Monitor. Memory prediction becomes optional, while the Slave common
memory remains independent.

Detailed ownership and data-flow contracts are in `docs/ARCHITECTURE.md`.

## Frozen v0.0 Baseline

v0.0 is frozen for the verified point-to-point WORD/SINGLE scope. It includes
Master and Slave Agents, transactions, Drivers, Monitors, Environment, shared
Slave common memory, independent Scoreboard reference memory, SVA, smoke tests,
integration tests, regression, and waveform evidence.

v0.1 must preserve the maintained v0.0 regression. The authoritative v0.0
description and evidence remain in `docs/V0_0_TECHNICAL_OVERVIEW.md`.

## Deferred from v0.1

- full functional multi-Master or multi-Slave operation;
- routing, arbitration, and interconnect implementation;
- BYTE and HALFWORD transfers;
- ERROR enhancement;
- advanced `HPROT`, `HMASTLOCK`, and other sideband behavior;
- advanced/random reset stress;
- unnecessary Proxy, Converter, transport Struct, or HDL BFM layers;
- a virtual sequencer without an approved concrete need.

Existing v0.0 ERROR-related code is retained for compatibility even though
ERROR enhancement and ERROR-focused v0.1 signoff are deferred.

## References

- `docs/V0_1_PLAN.md`: active v0.1 work and exit criteria.
- `docs/ARCHITECTURE.md`: architectural source of truth.
- `docs/REPO_CURRENT_STATE.md`: factual repository status.
- `docs/CODING_RULES.md`: mandatory coding conventions.
- `docs/V0_0_TECHNICAL_OVERVIEW.md`: frozen v0.0 behavior and evidence.
