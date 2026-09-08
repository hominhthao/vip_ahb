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

One transaction represents one AHB-Lite SINGLE transfer.
The Transaction describes WHAT transfer is requested; the Driver controls HOW
that transfer is driven cycle-by-cycle. Approved fields and transfer limits are
defined in `docs/PROJECT_CONTEXT.md`.

HTRANS is not a transaction field in v0.0. The Driver generates the required
transfer phase, such as NONSEQ when executing a transaction, and controls IDLE
behavior when no transaction is active.

HTRANS sequencing, IDLE behavior, wait-state cycle handling, reset handling,
and timeout handling belong to Driver/interface behavior, not transaction stimulus.
Later burst support may extend Driver behavior to generate SEQ phases.

The Monitor reconstructs observed bus activity back into transaction form.

The frozen v0.0 implementation declares direction, size, burst, and response
enums directly in `vip/src/fpt_ahb_package.sv`, before including the transaction.
Overrideable address/data width defaults are in `vip/include/fpt_ahb_macros.svh`.
There is no separate protocol types file or master/slave transaction split.

Transaction `compare()` checks request fields only; result fields are ignored.
`print()` displays all stored fields without implying transfer completion.
Standalone transaction smoke verification does not require FU2 or an interface.

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
