# FPT AHB VIP v0.0 — Technical Overview and Current State

Updated: 2026-09-12  
Repository: `hominhthao/vip_ahb`  
Branch: `main`  
Checkpoint: `876e83d Integrate AHB regression runner and waveform evidence`

## 1. Purpose and verified scope

FPT AHB VIP is a direct UVM/SystemVerilog verification component for AHB-Lite.
Version v0.0 establishes the minimum reusable end-to-end foundation:

- one Master and one Slave in a point-to-point topology;
- SINGLE transfers only;
- WORD transfers only;
- 32-bit byte address and 32-bit data by current default macros;
- READ and WRITE;
- OKAY responses in the basic verified flows;
- zero-wait basic tests plus bounded random wait injection in the random test;
- one shared Slave-side memory object;
- independent Scoreboard reference memory;
- protocol SVA and assertion coverage;
- VCS compile, smoke, integration, regression, and optional FSDB generation.

Features such as bursts beyond SINGLE, sizes beyond WORD, multiple Slaves,
interconnect/address decoding, byte enables, protection policy, exclusive access,
ERROR scenarios in the end-to-end suite, ECC, memory regions, and advanced
coverage are outside the approved v0.0 behavior.

## 2. Repository layout

```text
VIP_AHB/
├── vip/
│   ├── include/
│   │   ├── fpt_ahb_macros.svh           Width/default macros
│   │   └── fpt_ahb_if.svh               Interface, clocking blocks, modports
│   ├── src/
│   │   ├── fpt_ahb_package.sv           Reusable VIP package
│   │   ├── fpt_ahb_master_transaction.svh
│   │   ├── fpt_ahb_slave_transaction.svh
│   │   ├── fpt_ahb_common_memory.svh
│   │   ├── master_agent/                 Master cfg/driver/monitor/agent
│   │   ├── slave_agent/                  Slave cfg/driver/monitor/agent
│   │   └── sequence_lib/                 Reusable base/default Slave sequences
│   └── example/
│       ├── fpt_ahb_example_package.sv    Example environment/test package
│       ├── env/                          Environment and Scoreboard
│       ├── seq/                          Master stimulus sequences
│       ├── test/                         UVM tests and standalone smoke tops
│       └── tb/                           Top and SVA
├── scripts/                              Python compile/test runners
├── photo/                                Checked-in waveform evidence
├── docs/                                 Project and engineering documentation
└── work/                                 Generated build, log, simv, FSDB files
```

`vip/src` and `vip/include` form the reusable VIP library. `vip/example` is the
consumer example and integration testbench. Generated files under `work/` and
Verdi runtime files under `verdiLog/` are not source and are ignored by Git.

## 3. End-to-end UVM architecture

```text
Master Sequence
      |
      v
Master Sequencer -> Master Driver -> fpt_ahb_if -> Slave Driver
                                          |              |
                                          |              v
                                          |      shared common_memory
                                          |
                  +-----------------------+-----------------------+
                  |                                               |
                  v                                               v
          Master Monitor                                  Slave Monitor
                  |                                               |
                  +---- master FIFO -> Scoreboard <- slave FIFO --+
                                          |
                                          v
                              independent reference_memory
      ```   

The architecture uses direct UVM classes. It does not introduce Proxy,
Converter, intermediate transport structs, or a separate simulation BFM layer.

### Runtime construction and connection

`fpt_ahb_tb_top` creates clock/reset and `fpt_ahb_if`, connects
`HREADYOUT -> HREADY`, publishes the virtual interface through `uvm_config_db`,
instantiates SVA, and calls `run_test()`.

`fpt_ahb_base_test` creates Master/Slave configurations, selects the default
Slave memory sequence, creates the Environment, and provides the bounded
`run_sequence_and_wait()` completion helper.

`fpt_ahb_env` creates:

- one Master Agent;
- one Slave Agent;
- one Scoreboard;
- exactly one `fpt_ahb_common_memory` runtime object.

The Environment distributes the memory handle only to the Slave Agent. The
Slave Agent passes the same handle to its Driver. Master components and the
Scoreboard do not receive it. Master and Slave Monitor analysis ports connect
to separate Scoreboard analysis FIFOs.

## 4. Interface contract

`fpt_ahb_if` declares bus signals and three clocking blocks:

- `cb_master`: Master drives request/address/control/write-data and observes
  response/read-data/readiness;
- `cb_slave`: Slave observes requests and drives `HRDATA`, `HRESP`, `HEXOKAY`,
  and `HREADYOUT`;
- `cb_monitor`: observation-only view of all bus signals.

Address and data signals use the same project macros as transactions and memory:

```text
HADDR              FPT_AHB_VIP_ADDR_WIDTH
HWDATA / HRDATA    FPT_AHB_VIP_DATA_WIDTH
```

The point-to-point top connects selected Slave readiness with:

```systemverilog
assign ahb_if.hready = ahb_if.hreadyout;
```

Sideband signals exist at interface level but are not transaction fields in
v0.0: `HPROT`, `HMASTLOCK`, `HNONSEC`, `HEXCL`, `HMASTER`, `HWSTRB`, `HEXOKAY`,
and `HSELx`. Their broader policies/features are not part of v0.0.

Current implementation note: the Master clocking block and Master Driver still
drive `HSELx`. The earlier intended contract assigns selection ownership to
TB/top/address-selection logic. This is an implementation-policy mismatch to
review before claiming reusable multi-component ownership; it does not prevent
the current one-Slave point-to-point regression from passing.

## 5. Transaction model

### Master Transaction

`fpt_ahb_master_transaction` represents one request and its observed result.

| Field | Meaning | Randomized |
| --- | --- | --- |
| `addr` | Byte address | Yes |
| `direction` | READ or WRITE | Yes |
| `write_data` | WRITE payload | Yes |
| `size` | WORD in v0.0 | Constrained |
| `burst` | SINGLE in v0.0 | Constrained |
| `read_data` | HRDATA result | No |
| `response` | HRESP result | No |

Its address is word-aligned. `do_compare()` compares request state only.
`do_print()` displays all fields, and `do_copy()`/`clone()` preserve all seven.

### Slave Transaction

`fpt_ahb_slave_transaction` separates captured request context from response
planning.

| Field | Meaning |
| --- | --- |
| `addr`, `direction`, `write_data`, `size`, `burst` | Captured bus request |
| `read_data` | READ response data/completed observation |
| `response` | Planned/observed response |
| `wait_cycles` | Planned Slave response latency |

The request context is non-random. Response fields may be randomized. Soft
defaults are `response == FPT_AHB_OKAY` and `wait_cycles == 0`; inline constraints
may override them. There is no hard `MAX_WAIT` policy in the transaction.

Slave compare always checks address, direction, size, burst, response, and wait
count. It conditionally checks WRITE data for WRITE and READ data for successful
READ. Print, copy, and clone cover all eight fields.

## 6. Shared common memory

`fpt_ahb_common_memory` is a standalone `uvm_object` with a sparse associative
array keyed by the complete byte address. Its address/data typedefs are 2-state
`bit` vectors using the common width macros.

```text
write(addr, data)    Store or overwrite an address
read(addr)           Return stored data; zero when unwritten
clear()              Delete all entries while preserving the object handle
```

It contains no timing, clock, reset, interface, response, FIFO, Driver, or
configuration behavior. Actual bus memory access belongs to the Slave Driver:

- completed successful WRITE: sample `HWDATA`, then `mem.write(addr, data)`;
- READ: call `mem.read(addr)`, place the result in the Slave transaction, and
  drive it on `HRDATA`.

The Master Driver never reads common memory. It obtains READ data only by
sampling `HRDATA`.

## 7. Driver and sequence behavior

### Master side

The Master Driver accepts Master transactions, drives a NONSEQ address/control
phase, drives `HWDATA` for WRITE, waits for `HREADY`, samples `HRDATA` for READ,
samples `HRESP`, and returns the completed transaction to its sequence.

### Slave side

The Slave Driver observes accepted address phases, queues their context, asks
the default Slave sequence for response controls, performs common-memory access,
drives wait cycles/response/read data, samples WRITE data in the data phase, and
returns completion to the sequence.

`fpt_ahb_slave_mem_seq` supplies the normal v0.0 randomized response plan with
soft zero-wait/OKAY defaults. `fpt_ahb_slave_wait_mem_seq`, selected only by the
random R/W test, assigns a bounded `wait_cycles` value from 0 through 4. Neither
sequence reads nor writes common memory.

## 8. Monitor and Scoreboard behavior

Both Monitors reconstruct completed transfers from actual interface signals.
The Scoreboard pairs one Master observation with one Slave observation in FIFO
order, which is valid for the current one-Master/one-Slave in-order scope.

The Scoreboard owns an independent sparse reference memory. This preserves test
independence: a bug in Slave common-memory behavior cannot automatically become
the expected value.

For each pair, the Scoreboard:

1. logs complete Master and Slave observations;
2. checks address, direction, size, burst, response, and WRITE data;
3. updates reference memory after a matching successful WRITE;
4. checks successful READ data from both Monitors against reference memory;
5. expects zero at an unwritten address;
6. reports a per-transfer PASS or mismatch;
7. reports final `expected`, `checked`, `passed`, and `mismatches` counts.

Every integration test sets an exact expected transfer count. End-of-test fails
when `checked_count != expected_count` or unmatched FIFO observations remain.
Tests wait for completion using interface clock events and a 100-cycle test
timeout instead of arbitrary drain delays.

## 9. Tests and verification commands

### Object/component smoke tests

```bash
python3 scripts/compile.py
python3 scripts/smoke.py
python3 scripts/common_memory_smoke.py
python3 scripts/scoreboard_smoke.py
```

- transaction smoke checks randomization, compare, print, copy, and clone;
- common-memory smoke checks sparse/shared-handle behavior, independent and
  exact byte addresses, overwrite, unwritten-zero, clear, and reuse;
- Scoreboard smoke checks positive reference modeling and deliberate negative
  mismatch detection using a report catcher.

The Scoreboard smoke intentionally generates and demotes expected mismatch
reports. Its internal `mismatches` count can therefore be nonzero while the
final UVM error/fatal totals are zero.

### Integration tests

```bash
python3 scripts/run_single_write.py --seed 1
python3 scripts/run_raw.py --seed 1
python3 scripts/run_random_rw.py --seed 1
```

`run_raw.py` is the compatibility wrapper for
`fpt_ahb_read_after_write_test`. All wrappers call `run_test.py`; VCS compile/run
logic is maintained in one place.

To select a test directly:

```bash
python3 scripts/run_test.py --test fpt_ahb_read_after_write_test --seed 1
```

To generate FSDB for Verdi, add `--wave`. Without this flag no FSDB is requested.

```bash
python3 scripts/run_test.py \
    --test fpt_ahb_read_after_write_test \
    --seed 1 \
    --wave
```

Output is placed under:

```text
work/vip_run/<test-name>/compile.log
work/vip_run/<test-name>/run.log
work/vip_run/<test-name>/ahb_vip.fsdb
```

Run the maintained regression with:

```bash
python3 scripts/run_regression.py
```

It runs single WRITE seed 1, READ-after-WRITE seed 1, and random R/W seeds 100,
200, and 300. Regression disables waveform generation to reduce runtime/storage.

## 10. Latest verified evidence

At checkpoint `876e83d`, VCS X-2025.06 Full64 with UVM 1.2 produced:

| Verification | Result |
| --- | --- |
| Common-memory smoke | PASS |
| Scoreboard smoke | PASS |
| Single WRITE | `expected=1 checked=1 mismatches=0` |
| READ-after-WRITE | `expected=2 checked=2 mismatches=0` |
| Random R/W | expected equals checked, `mismatches=0` |
| Maintained regression | 5/5 PASS |
| Final UVM totals | `UVM_ERROR=0`, `UVM_FATAL=0` |
| Whitespace validation | `git diff --check` PASS |

Checked-in visual evidence:

```text
photo/waveform_single_write.png
photo/waveform_raw.png
photo/waveform_random.png
```

The authoritative result for a run is its `run.log`; waveform evidence is used
to inspect signal phasing and wait behavior. A passing log alone does not prove
all protocol timing corner cases, and a waveform alone does not prove Scoreboard
signoff.

## 11. Current Git and project state

As of this document update:

```text
local main       876e83d6d078f9e93694c5306996962e3eb03880
origin/main      876e83d6d078f9e93694c5306996962e3eb03880
```

The v0.0 bring-up is functionally integrated and regression-tested for the
approved basic flows. The frozen Master/Slave transaction layer, shared memory,
both Agents, Environment, Scoreboard, top, SVA, integration tests, shared runner,
regression runner, and waveform evidence are present on `main`.

Local `evidence/` content is currently untracked and is not part of the source
checkpoint. Three older stashes preserve historical local work; they are not
applied to `main` and are not part of runtime behavior.

## 12. Known limits and review items

Before expanding beyond the present v0.0 proof, review these points explicitly:

1. Resolve and freeze `HSELx` ownership; current Master Driver drives it while
   the intended contract assigns selection to TB/top logic.
2. Perform focused waveform review of address/data phase alignment, back-to-back
   transfers, READ sampling, reset interruption, and random wait behavior.
3. Define owner-approved ERROR-response tests and any wait timeout/maximum
   policy before treating those behaviors as supported requirements.
4. Decide sideband default/configuration policies before advertising support for
   protection, exclusive, strobe, lock, or multi-master behavior.
5. Extend burst, transfer size, topology, coverage, and memory policies only
   through future approved tickets.

These items do not invalidate the current passing basic regression. They mark
the boundary between the verified v0.0 bring-up and future protocol hardening.

## 13. Definition of a trustworthy PASS

For an integration run, check all of the following:

```text
VCS compile return code = 0
simulation return code = 0
expected == checked
mismatches == 0
UVM_ERROR == 0
UVM_FATAL == 0
```

When timing matters, also open the matching FSDB and inspect `HCLK`, `HRESETn`,
`HSELx`, `HTRANS`, `HADDR`, `HWRITE`, `HSIZE`, `HBURST`, `HWDATA`, `HRDATA`,
`HREADY`, `HREADYOUT`, and `HRESP` across the complete transfer.
