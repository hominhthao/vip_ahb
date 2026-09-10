# CODING_RULES.md

## 1. Purpose

This file defines the coding rules for FPT AHB VIP v0.0.

Follow project-lead coding guidance.
Do not invent new conventions unless explicitly approved.

## 2. File Naming

- All VIP files use prefix `fpt_`.
- AHB VIP files should follow `fpt_ahb_...`.
- Class/include files use `.svh`.
- Package files use `.sv`.

Example:

```text
fpt_ahb_package.sv
fpt_ahb_transaction.svh
fpt_ahb_interface.svh
```

## 3. Include Guard

Every `.svh` file must use an include guard.

Example:

```systemverilog
`ifndef FPT_AHB_TRANSACTION_SVH
`define FPT_AHB_TRANSACTION_SVH

// content

`endif
```

## 4. Formatting

- Use 4 spaces for indentation.
- Keep code simple and readable.
- Important members and methods should have useful descriptions.
- Do not add comments that only repeat the code.

## 5. Class Method Style

Prefer method declaration inside the class and implementation outside the class using `extern`.

Example:

```systemverilog
class fpt_ahb_example extends uvm_object;

    extern function new(string name = "fpt_ahb_example");

endclass


function fpt_ahb_example::new(string name = "fpt_ahb_example");
    super.new(name);
endfunction
```

## 6. Configuration Macros

Important compile-time configuration values should have overrideable defaults.

Use:

```systemverilog
`ifndef FPT_AHB_VIP_<NAME>
    `define FPT_AHB_VIP_<NAME> <DEFAULT_VALUE>
`endif
```

Do not scatter configurable values as hard-coded literals.

## 7. Delay Rules

Do not use ambiguous delays:

```systemverilog
#1;
```

Use an explicit time unit when a delay is required:

```systemverilog
#1ns;
#1ps;
```

Do not add arbitrary delays to hide race conditions.

## 8. Interface / Clocking Block

Timed VIP access to interface signals must use clocking blocks.

Do not drive directly:

```systemverilog
m_vif.haddr <= addr;
```

Use the proper clocking block:

```systemverilog
m_vif.master_cb.haddr <= addr;
```

Current clocking skew direction from the project lead:

```systemverilog
default input #1step output #1step;
```

Driver and Monitor code must not bypass the defined clocking blocks.

## 9. Class Parameters and Access Control

For v0.0:

- Avoid `parameter` / `localparam` inside VIP classes unless explicitly required.
- Avoid unnecessary `protected` / `local` complexity.
- Prefer simple and clear implementation.

## 10. Constraints

Constraints must generate legal protocol behavior.

For bounded configurable values such as delay, consider:

```text
minimum
middle range
maximum
```

Do not mechanically apply this pattern to unrelated random fields.

## 11. Compile / Run Direction

The project lead prefers a Python-based compile/run flow.

Future compile/run support should allow waveform/debug options.

Do not implement compile infrastructure during unrelated tickets.

## 12. v0.0 Scope Rule

The approved v0.0 common memory is intentionally minimal:

- use one Environment-owned runtime object shared with Slave consumers;
- use sparse full-byte-address storage and the project width macros;
- support only `write()`, `read()`, and `clear()`;
- keep bus timing, reset, response, and wait-state behavior in bus components.

Do not add unapproved memory features such as:

- byte enables;
- regions or protection policies;
- ECC;
- protocol timing;
- future-version infrastructure.

## 13. General Rule

Coding rules define **HOW** code is written.

They do not define **WHAT** should be implemented.

Implementation scope comes from the approved ticket.

If something useful is outside the current ticket:

**Report it. Do not implement it automatically.**
