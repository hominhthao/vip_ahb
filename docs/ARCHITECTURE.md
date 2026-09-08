# ARCHITECTURE.md

## 1. AHB VIP v0.0 Architecture

Current target:

- AHB-Lite
- UVM / SystemVerilog
- minimal point-to-point architecture

Main flow:

```text
Sequence
    ->
Sequencer
    ->
Driver
    ->
Virtual Interface
    ->
DUT
```

Monitor flow:

```text
AHB Signals
    ->
Monitor
    ->
Transaction
    ->
Scoreboard / Functional Coverage
```

Main components:

```text
AHB Environment
    |
    +-- Master Agent
    |     +-- Sequencer
    |     +-- Driver
    |     +-- Monitor
    |     +-- Config
    |
    +-- Slave Agent
    |     +-- Sequencer
    |     +-- Driver
    |     +-- Monitor
    |     +-- Config
    |
    +-- Scoreboard
    +-- Functional Coverage

AHB Interface
    |
    +-- Master clocking block
    +-- Slave clocking block
    +-- Monitor clocking block
    +-- Protocol Assertions

DUT
```

## 2. Key Architecture Decisions for v0.0

The new VIP uses a direct UVM class-based flow.

The following legacy layers are intentionally not used in v0.0:

```text
Proxy
Converter
Intermediate Struct
Separate simulation BFM layer
```

Transaction and Interface are separate abstractions.

```text
Transaction
    ->
Driver
    ->
Interface
```

### Transaction / Driver Responsibilities

Master and Slave transactions are separate, as required by lead clarification
superseding the shared-transaction decision in local commit `68244ce`.
Each describes one AHB-Lite SINGLE transfer. Master generates request fields and
stores observed results. Slave holds non-random captured request context and
randomizable read data, response, and wait count. The future Slave default sequence
will use the Slave Transaction; its implementation is deferred.
Drivers control how transfers and responses are driven cycle-by-cycle.
Approved fields and transfer limits are defined in `docs/PROJECT_CONTEXT.md`.

HTRANS is not a transaction field in v0.0. The Driver generates the required
transfer phase, such as NONSEQ when executing a transaction, and controls IDLE
behavior when no transaction is active.

HTRANS sequencing, IDLE behavior, wait-state cycle handling, reset handling,
and timeout handling belong to Driver/interface behavior. Slave `wait_cycles`
describes a requested count; the transaction itself does not wait or drive signals.
Later burst support may extend Driver behavior to generate SEQ phases.

The Monitor reconstructs observed bus activity back into transaction form.

The v0.0 implementation declares direction, size, burst, and response
enums directly in `vip/src/fpt_ahb_package.sv`, before including both
`fpt_ahb_master_transaction.svh` and `fpt_ahb_slave_transaction.svh`.
Overrideable address/data width defaults are in `vip/include/fpt_ahb_macros.svh`.
There is no separate protocol types file or common transaction base layer.
The old generic class is replaced, without a compatibility alias.

Master Transaction `compare()` checks request fields only; result fields are ignored.
`print()` displays all stored fields without implying transfer completion.
Standalone transaction smoke verification does not require FU2 or an interface.
Slave compare always checks address, direction, size, burst, response, and wait
count. It compares write data for two WRITEs and read data for two READs with
OKAY responses. Slave `print()`/`sprint()` display all eight stored fields:
hex address/data, valid enum names (binary fallback for unnamed values), and
decimal wait_cycles. Printing does not modify state or imply a completed transfer.
Both transaction classes implement extern `do_copy()`: validate/cast the source,
call `super.do_copy(rhs)`, then copy every custom field unconditionally. Master
copies seven fields; Slave also copies wait_cycles. Inherited UVM `clone()` uses
this copy behavior to populate a distinct object. Copy semantics do not follow
the conditional field filtering used by compare and do not randomize or repair state.
Slave response controls default softly to zero waits and OKAY; inline constraints
may override either. No hard maximum or MAX_WAIT is defined. Maximum/timeout
policy belongs to the later Slave configuration/Driver design.
The future default sequence/Driver must define context delivery, response policy,
wait limits, reset/timeout handling, and sequence startup phase before integration.

## 3. v0.0 Boundary

v0.0 focuses on the minimum architecture required to bring up the VIP.

Current focus:

```text
Transaction
Interface
Master Agent
Slave Agent
Driver
Monitor
Environment
Basic Scoreboard/Coverage/SVA integration
```

No common memory model is included in v0.0.

## 4. After v0.0

After the v0.0 foundation is stable, the architecture may be enhanced incrementally.

Expected future direction may include:

```text
Broader AHB-Lite feature support
More complete burst support
Stronger protocol assertions
Expanded functional coverage
More configurable agents
Common memory model in v0.1+
Improved integration/debug infrastructure
```

Future features must be added through approved project decisions and tickets.

Do not redesign the v0.0 architecture preemptively for future features.
