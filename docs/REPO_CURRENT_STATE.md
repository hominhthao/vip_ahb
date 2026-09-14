# FPT AHB VIP Repository Current State

Updated: 2026-09-14

## Git State

- frozen baseline branch: `main`;
- `main` checkpoint: `0d00803 Document AHB VIP v0.0 technical overview`;
- v0.0 implementation/regression checkpoint: `876e83d Integrate AHB regression runner and waveform evidence`;
- active branch: `feature/v0.1-burst-wait`;
- branch checkpoint before documentation synchronization: `e18a906 Add AHB VIP v0.1 development plan`.

Generated `work/` content and Verdi runtime files are not project source.

## Implemented and Frozen

v0.0 is frozen for its point-to-point `1M / 1S`, WORD/SINGLE scope. It includes:

- separate Master and Slave transactions;
- AHB interface and shared width macros;
- Master and Slave Agents, Drivers, Sequencers, and Monitors;
- Environment and Monitor-to-Scoreboard connections;
- Environment-owned Slave common memory;
- Scoreboard with independent reference memory;
- TB top, SVA, smoke tests, and integration tests;
- Python compile/run/regression flow;
- representative waveform evidence.

The maintained v0.0 regression passed 5/5 at the frozen checkpoint with no
unexpected UVM errors or fatals. Details are in
`docs/V0_0_TECHNICAL_OVERVIEW.md`.

## Current v0.1 Work

Completed:

- branch creation;
- audit of v0.0 burst, WAIT, HSEL, monitoring, checking, test, and regression
  assumptions;
- approval of the reusable-foundation-first direction;
- synchronization and compaction of active documentation.

No v0.1 UVM/SystemVerilog or Python implementation has started. Full Burst,
the revised WAIT architecture, System Monitor, System Checker refactor, and
optional Predictor separation are not implemented.

## Next Immediate Task

Begin Phase 1 reusable-foundation work by defining the Environment configuration
contract. It must provide policy/configuration rather than hardcoded DUT behavior
and must preserve the verified v0.0 flow.

Subsequent Phase 1 work is:

1. define System Monitor and System Checker boundaries;
2. separate optional memory prediction from generic checking;
3. remove HSEL ownership from the Master Driver;
4. verify and correct WAIT timing on SINGLE;
5. review transaction randomization/configuration;
6. rerun the frozen v0.0 regression.

Burst implementation starts only after the reusable foundation and SINGLE WAIT
timing are stable.

## Current Limitations

- only the v0.0 WORD/SINGLE `1M / 1S` behavior is currently implemented;
- `1M / 1S` is the v0.1 verified configuration, not a permanent architecture
  limit;
- current HSEL ownership still conflicts with the approved v0.1 direction;
- current WAIT timing requires focused SINGLE validation/correction;
- the current Scoreboard still embeds memory prediction;
- System Monitor and generic System Checker boundaries do not yet exist;
- Full HBURST, BUSY burst behavior, and reset-during-burst recovery do not exist;
- ERROR enhancement and functional multi-agent routing are deferred.

## Active References

- `docs/V0_1_PLAN.md`: v0.1 scope, phases, and exit criteria.
- `docs/ARCHITECTURE.md`: component responsibilities and ownership.
- `docs/PROJECT_CONTEXT.md`: project objective and verified scope.
- `docs/V0_0_TECHNICAL_OVERVIEW.md`: frozen v0.0 behavior and evidence.
- `docs/CODING_RULES.md`: coding conventions.

This documentation-only change does not modify implementation files and does
not provide new compile or simulation evidence.
