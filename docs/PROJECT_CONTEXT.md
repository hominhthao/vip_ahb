# PROJECT_CONTEXT.md

## 1. Project Overview

This repository contains the development of the **FPT AHB VIP**.

Current target:

- Protocol: **AHB-Lite**
- Release: **v0.0**
- Methodology: **UVM / SystemVerilog**
- Initial topology: **point-to-point**
- Goal: build a clean, reusable foundation for future AHB VIP development

The project is a new implementation, not a direct refactor of the existing AHB VIP.


## 2. v0.0 Scope

v0.0 focuses on bringing up the basic AHB-Lite VIP foundation.

Approved transaction scope (lead clarification supersedes the previous shared
transaction decision and freeze in local commit `68244ce`):

- Master and Slave use separate transaction classes, each for one AHB-Lite
  SINGLE transfer, either READ or WRITE.
- Address and data widths are 32 bits. Only WORD transfers are supported;
  the HSIZE signal encoding width is 3 bits and the active transfer size is WORD.

Master Transaction (`fpt_ahb_master_transaction`):

| Field         | Role      | Width / values        | Randomized |
| ---           | ---       | ---                   | ---        |
| `addr`        | Stimulus  | 32 bits               | Yes        |
| `write_data`  | Stimulus  | 32 bits               | Yes        |
| `direction`   | Stimulus  | READ or WRITE         | Yes        |
| `read_data`   | Result    | 32 bits               | No         |
| `response`    | Result    | Response information  | No         |
| `size`        | Transfer  | WORD                  | No         |
| `burst`       | Transfer  | SINGLE                | No         |

Slave Transaction (`fpt_ahb_slave_transaction`):

| Field | Role | Randomized |
| --- | --- | --- |
| `addr`, `direction`, `write_data` | Captured Master request context | No |
| `size`, `burst` | Captured context, limited to WORD/SINGLE | No |
| `read_data` | Slave-generated READ response data, 32 bits | Yes |
| `response` | Slave-generated OKAY/ERROR response | Yes |
| `wait_cycles` | Requested wait count, unsigned integer | Yes |

Slave randomization validates aligned READ/WRITE, WORD/SINGLE context and leaves
that context unchanged. Soft defaults are `wait_cycles == 0` and
`response == FPT_AHB_OKAY`; inline constraints may override them.
No hard maximum or MAX_WAIT is introduced. No maximum wait-count policy has been specified; the
unsigned 32-bit representation is an implementation choice, not a timing budget.
The future default Slave Sequence will select practical response controls.
Implementing that sequence, Drivers, Sequencers, interface changes, and a memory
model is outside this transaction-layer task.

Use separate `write_data` and `read_data`, not a shared generic `data` field.
HBURST is transaction-level protocol information restricted to SINGLE;
it must not randomize to unsupported burst types in v0.0.

Basic address/control/data handling, response handling, wait-state handling,
and reset behavior remain in scope. Transaction/Driver responsibility boundaries
are defined in `docs/ARCHITECTURE.md`.

More advanced features will be added incrementally after the v0.0 foundation is stable.


## 3. Out of Scope for v0.0

The following are not part of the current v0.0 scope:

- common memory model;
- AHB5-only features;
- future-version infrastructure;
- unnecessary legacy architecture layers;
- speculative features not requested by an approved task.

The common memory model is currently planned for a later release, approximately v0.1+.


## 4. Legacy VIP Reference

The existing AHB VIP is available in the FU2 environment:

```text
~/fu2/dv/sim/uvm_env/vip/ahb_vip
```

It may be used to study:

- protocol behavior;
- existing implementation experience;
- corner cases;
- feature support;
- known limitations.

The legacy VIP is **reference material only**.

Its implementation and architecture must not be copied automatically.


## 5. Current Team Ownership

### Transaction Item

Owner: **Thao**

Primary work area:

```text
vip/src/
```

Main responsibilities:

- transaction definition;
- attributes;
- constraints;
- transaction utilities;
- transaction smoke verification.


### Interface

Owner: **teammate**

Primary work area:

```text
vip/include/
```

Main responsibilities:

- AHB interface;
- bus signals;
- clock/reset;
- clocking blocks;
- Master/Slave/Monitor signal views.

Transaction and Interface may be developed in parallel.


## 6. Repository Structure

The repository follows the structure defined by the project lead:

```text
vip/
├── src/
├── include/
└── example/
    ├── test/
    ├── seq/
    ├── env/
    └── tb/
```

Detailed coding conventions are defined in:

```text
docs/CODING_RULES.md
```

Detailed architecture is defined in:

```text
docs/ARCHITECTURE.md
```


## 7. Current Status

Completed:

- legacy AHB VIP investigation;
- AHB-Lite specification review;
- feature / gap / limitation analysis;
- initial v0.0 architecture;
- repository setup;
- base folder structure;
- team ownership split;
- coding-rule collection;
- AI working rules.

Transaction layer — Thao: split into dedicated Master and Slave classes following
lead clarification. The earlier shared-transaction freeze is superseded.
Master retains the prior randomization, request-only compare, and full-field print.
Slave separates captured request context from randomized response controls. Its
compare checks context, response, and wait count; write data only for WRITE, and
read data only for two READ plans with OKAY responses.
Both classes implement complete-state copy/clone support: all seven Master fields
and all eight Slave fields are copied, including fields ignored by compare.
Separate transaction smoke tops use the existing Python/VCS flow.
Slave now has full-field print/sprint support for all eight stored fields, including
decimal wait_cycles. Compile-only and both transaction smoke tests passed with
VCS Full64/UVM 1.2, seed 1, including the final pre-commit rerun. Transaction layer
is complete and frozen by the owner on 2026-09-08. The split-transaction checkpoint
is authorized for local commit only; no push is included.

Interface remains owned by the teammate; its implementation/integration status
is not established by this transaction test. Bus READ/WRITE verification is a
separate integration task.

Current semantics, commands, verification evidence, and limitations are recorded
in `docs/REPO_CURRENT_STATE.md`.
