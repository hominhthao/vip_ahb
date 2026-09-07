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

Approved transaction scope:

- One transaction item represents one AHB-Lite SINGLE transfer, either READ or WRITE.
- Address and data widths are 32 bits. Only WORD transfers are supported;
  the HSIZE signal encoding width is 3 bits and the active transfer size is WORD.

| Field         | Role      | Width / values        | Randomized |
| ---           | ---       | ---                   | ---        |
| `addr`        | Stimulus  | 32 bits               | Yes        |
| `write_data`  | Stimulus  | 32 bits               | Yes        |
| `direction`   | Stimulus  | READ or WRITE         | Yes        |
| `read_data`   | Result    | 32 bits               | No         |
| `response`    | Result    | Response information  | No         |

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

Current phase:

**Freeze project documentation and task definitions before implementation.**

Implementation status:

**Not started yet.**

Next development work:

- Transaction Item — Thao
- Interface — teammate

Both will proceed in parallel after the initial task definitions are approved.
