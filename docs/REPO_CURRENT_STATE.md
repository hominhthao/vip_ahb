# REPO_CURRENT_STATE.md

Updated: 2026-09-08

- Branch: `feature/transaction-item`
- Owner: Thao
- Task: transaction-layer split into dedicated Master and Slave types.
- Status: COMPLETE / FROZEN by owner after successful verification, including Slave full-field
  print, soft defaults, response-plan compare, and Master/Slave copy/clone support.
  Compile-only and Master/Slave smoke compile and simulation PASS.
- Git checkpoint: this report accompanies the local commit
  `Finalize split AHB v0.0 Master and Slave transactions`, based on `68244ce`.
  Use Git history for its hash. The owner authorized this commit only, not a push.
  AGENTS.md and verdiLog/ remain outside the transaction checkpoint.

## Final checkpoint verification

On 2026-09-08, before staging/committing:

- `git status --short` was reviewed; the index was initially empty.
- `python3 scripts/compile.py`: exit 0, `PASS: compile completed.`
- `python3 scripts/smoke.py`: exit 0, `PASS: both transaction smoke tests.`
- VCS X-2025.06 Full64 / UVM 1.2, seed 1. Both smoke compile invocations passed
  (incremental build reused unchanged designs), and both simulations ran again.
- Master: 52 READ/48 WRITE; print, compare, copy/clone, and expected rejections PASS.
- Slave: 100 default OKAY/zero-wait responses; overrides, compare, copy/clone,
  full-field print/state preservation, and expected rejections PASS.
- Only the owner's transaction source/smoke/docs allowlist is staged for this
  checkpoint; generated work files and unrelated changes are excluded. No push.

## Superseded decision

Lead clarification supersedes the previous shared-transaction decision and
COMPLETE/FROZEN architecture recorded in `68244ce`. Master and Slave transactions
must be separate. Slave will later use a default sequence; that sequence is not
part of this implementation. Previous verification remains historical evidence
for the old code; the new types have been compiled and tested separately.

## Master Transaction

`fpt_ahb_master_transaction` replaces `fpt_ahb_transaction` without an alias.
One item represents one AHB-Lite SINGLE transfer with default 32-bit address/data.

- Random request fields: `addr`, `write_data`, READ/WRITE `direction`.
- Non-random transfer fields: `size = WORD`, `burst = SINGLE`.
- Non-random result storage: `read_data` (logic), `response`.
- Constraints: word alignment and validation of WORD/SINGLE; no repair of invalid
  non-random fields. READ may have nonzero write data.
- Request-only compare: direction/address/size/burst, and write data only for two
  WRITE requests. Results are ignored; null/incompatible types compare unequal.
- Full-field print/sprint: hex address/data, enum names, X/Z result values.
- Factory registration and extern methods retained.
- `do_copy()` copies all seven custom fields, including results and unused payload.

## Slave Transaction

`fpt_ahb_slave_transaction` independently extends `uvm_sequence_item`.

- Captured non-random request context: `addr`, `direction`, `write_data`, `size`,
  `burst`; size/burst initialize to WORD/SINGLE.
- Random generated controls: 32-bit `read_data` (bit vector), OKAY/ERROR `response`,
  and `int unsigned wait_cycles`.
- Context constraints validate aligned READ/WRITE, WORD/SINGLE state without
  modifying captured values. Populate context before randomizing a response.
- Read data is unused for WRITE but is not forced to zero.
- Soft defaults: `wait_cycles == 0`, `response == FPT_AHB_OKAY`. Inline constraints
  may intentionally override them. There is no hard maximum and no MAX_WAIT.
  The unsigned 32-bit range is a representation choice, not a timing policy.
- Slave compare always checks addr/direction/size/burst/response/wait_cycles;
  write_data only for two WRITEs, read_data only for two READs with OKAY responses.
  Null/incompatible types compare unequal; comparison does not modify the objects.
- `do_copy()` copies all eight custom fields, including context, both payloads,
  response, and wait_cycles regardless of direction/response.
- Slave extern do_print calls super.do_print and prints all eight stored fields:
  address/data as hex, valid enum names with binary fallback for unnamed values,
  and wait_cycles as decimal. It does not modify state. read_data remains rand bit.
- No sequence or Driver is added.

Both do_copy implementations safely cast/check rhs before calling super.do_copy
and copying custom fields. A direct null/incompatible do_copy source reports
UVM_FATAL FPT_AHB_COPY; public UVM copy(null) retains its inherited null handling.
No field automation is used. Copy preserves stored state rather than validating
constraints or applying soft defaults. Inherited clone creates a distinct object
and invokes copy. Existing compare semantics remain unchanged.

## Files changed

- Rename `vip/src/fpt_ahb_transaction.svh` to
  `vip/src/fpt_ahb_master_transaction.svh`, updating class/type references.
- Add `vip/src/fpt_ahb_slave_transaction.svh`.
- Update `vip/src/fpt_ahb_package.sv` to include both types after shared enums.
- Rename the generic smoke top to
  `vip/example/tb/fpt_ahb_master_transaction_smoke_top.sv`.
- Add `vip/example/tb/fpt_ahb_slave_transaction_smoke_top.sv`.
- Update `scripts/smoke.py` to compile/run both tops in separate work directories.
- Update `docs/PROJECT_CONTEXT.md`, `docs/ARCHITECTURE.md`, and this report.

The compile-only `scripts/compile.py` needs no source changes; it compiles the
updated package. Macros, teammate-owned interface files, and FU2 are unchanged.
Existing `AGENTS.md` changes and untracked `verdiLog/` remain untouched.

## Reproduction and verification

From the project root, with VCS in PATH and access to the license server:

```bash
python3 scripts/compile.py
python3 scripts/smoke.py
```

Both use VCS X-2025.06 Full64, `-full64 -sverilog -ntb_opts uvm-1.2
+vcs+lic+wait`. The smoke runner uses seed 1 and requires successful compile/run
exit codes plus each test's completion marker. Output stays under `work/`.

- Package compile-only flow: PASS, exit code 0, with both transaction includes.
- Master compile/run: PASS, exit codes 0; 100 random requests, 52 READ/48 WRITE.
  Existing factory, alignment, transfer limits, result preservation, directed
  READ/WRITE, negative constraints, request compare, and print checks passed.
- Slave initial split verification (before soft defaults): PASS, 49 OKAY/51 ERROR.
  Current soft-default/compare verification is recorded below. Context stayed
  unchanged after response randomization. Directed zero/all-one data, OKAY/ERROR,
  and 0/8 wait counts passed for both directions. These wait values are test cases,
  not implementation limits, and no bus cycles are executed.
- Slave rejects inline attempts to change captured address, misaligned context,
  unsupported size, and unsupported burst. Invalid state is not repaired;
  response randomization succeeds after context is restored.
- Expected diagnostics: Master has 3 `CNST-CIF` constraint rejections and intentional
  UVM_INFO `MISCMP` messages; Slave has 4 `CNST-CIF` rejections. These are checked
  negative cases, not unexpected test failures.

Validation after adding Slave defaults/compare: `python3 scripts/smoke.py`
completed with return code 0 using VCS Full64/UVM 1.2, seed 1. Both compilation
stages and both simulations passed. Master remains 52 READ/48 WRITE. Slave has
100 default OKAY responses with zero waits; explicit ERROR/8-wait overrides pass,
and subsequent randomization restores the soft defaults. Only small wait values
0, 3, and 8 are used in the current smoke tests; none is a maximum-wait requirement.
Slave comparison checks cover each always-compared field, WRITE payload even on
ERROR, ignored READ write payload, ignored ERROR READ data, compared OKAY READ
data, null/incompatible objects, symmetry, and preservation of all fields.
The run log contains `PASS: slave response-plan compare checks` and the final
Slave smoke completion marker. Intentional unequal Slave comparisons emit MISCMP.

Validation after copy/clone implementation:

- `python3 scripts/compile.py`: PASS, exit code 0 (package compile-only).
- `python3 scripts/smoke.py`: PASS, exit code 0; Master and Slave both compiled
  and ran with VCS X-2025.06 Full64/UVM 1.2, seed 1.
- Both tests copy between distinct objects with intentionally different values
  in every custom field, checking each field directly with case inequality.
- Both tests clone populated READ and WRITE objects, check correct type and
  distinct handles, verify every field, then mutate the clone and verify the
  original remains equal to an independent full-state snapshot object.
- Master tests include X/Z read data. Non-default size/burst enum values are used
  only to prove copying preserves stored state rather than constructor defaults;
  they are not generated bus transfers or expanded protocol support.
- Master and Slave logs each contain two copy PASS markers and two clone/full-field
  independence PASS markers. Existing randomization, defaults, compare, and Master
  print tests remain PASS. Wait policy and all bus-layer components are unchanged.
- No additional seeds, invalid-source do_copy runtime tests, or bus integration
  were run. No commit or push was performed.

Latest validation after Slave print support:

- `python3 scripts/compile.py`: return code 0, `PASS: compile completed.`
- `python3 scripts/smoke.py`: return code 0, `PASS: both transaction smoke tests.`
- Slave run.log includes `PASS: slave print/sprint all 8 fields and state preservation`.
  Checks match each field name/value on its printed row, cover READ/WRITE and
  OKAY/ERROR names, and verify unnamed enum values remain visible. Snapshots of
  all eight fields before/after public print/sprint match exactly.
- wait_cycles=12 is used only to distinguish decimal from hex output; it is a small
  print-test value, not a maximum or change to wait policy.
- Existing Master/Slave randomization, compare, copy/clone, and negative tests
  remain PASS with seed 1. Random fields, constraints, and wait policy are unchanged.
- This update touches only the Slave class, Slave smoke top, and the three
  transaction documentation files. Generated output is produced only by the
  requested VCS/Python runs, not manually edited. No commit or push was performed.

Logs:

- `work/transaction_compile/compile.log`
- `work/master_transaction_smoke/compile.log` and `run.log`
- `work/slave_transaction_smoke/compile.log` and `run.log`

The older `work/transaction_smoke/` logs are retained historical artifacts; they
are not the result of the new two-type flow. No generated artifacts are tracked.

## Deferred decisions and limits

Only seed 1 and default 32-bit widths have been exercised. Width macros remain
configurable defaults, not evidence of broader support. No bus behavior is tested.

The later default Slave Sequence/Driver task must decide:

- how captured request context reaches the sequence/response-generation path;
- sequence startup phase, lifecycle, and request/response handshake;
- read-data/response override policy and any maximum/timeout policy in the
  Slave configuration/Driver (current transaction soft defaults remain overridable);
- mapping of wait controls and OKAY/ERROR responses to bus cycles;
- reset/timeout behavior and integration checks.

No Master/Slave Driver, Sequencer, default sequence, interface change, memory
model, FU2 integration, or future AHB feature is implemented here.
