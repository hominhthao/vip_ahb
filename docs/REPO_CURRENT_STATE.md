# REPO_CURRENT_STATE.md

Updated: 2026-09-08

- Branch: `feature/transaction-item`
- Task: complete v0.0 transaction attributes, constraints, print, compare, and smoke test
- Owner: Thao
- Status: COMPLETE / FROZEN by owner on 2026-09-08.
- Verification: compiled/ran successfully with VCS X-2025.06 Full64 and UVM 1.2,
  seed 1. Further scope changes require an approved task.

## Frozen transaction scope

One item represents one AHB-Lite SINGLE transfer, with 32-bit address/data and
WORD size. `addr`, `write_data`, and READ/WRITE `direction` are random fields.
`size` and `burst` are non-random WORD/SINGLE defaults. `read_data` and `response`
are non-random result storage. READ does not require zero write data.

Constraints enforce word alignment and validate size/burst; they do not repair
invalid non-random state. Width macros are overrideable, but broader width support
has not been approved or verified. HTRANS, reset, timeout, and wait-state behavior
remain outside the transaction.

The owner froze the shared transaction after reviewing FU2 references. No split
into master/slave transaction types or addition of FU2 interface fields is included.

## Files in this task

- `vip/src/fpt_ahb_transaction.svh`: added extern `do_print` and `do_compare`.
- `vip/example/tb/fpt_ahb_transaction_smoke_top.sv`: standalone test top.
- `scripts/smoke.py`: minimal compile/run script; output under
  `work/transaction_smoke/`.
- `scripts/compile.py`: compile-only script; generates a minimal top and output
  under `work/transaction_compile/`, without running simv.
- `docs/REPO_CURRENT_STATE.md`: this status report.

Package and macros were already committed in `760ccdb`; their source is unchanged.
Existing local changes to `AGENTS.md` and `verdiLog/` are preserved outside the
transaction commit. Generated logs and simulator output remain under ignored `work/`.

## Frozen utility semantics

- `compare()` checks request direction, address, size, and burst, plus write data
  only when both objects are WRITE. Read data and response are ignored.
- Null and incompatible objects compare unequal. Field mismatches use UVM
  comparer diagnostics. Comparing does not modify either transaction.
- `print()` / `sprint()` show all seven fields: address/data in hex, named enums,
  and X/Z result values. Printed results are stored values, not evidence of a
  completed transfer. No additional state field or copy utility is introduced.

## Verification

Run from the repository root with VCS available in PATH and license access:

```bash
python3 scripts/compile.py  # compile only
python3 scripts/smoke.py    # compile and run transaction smoke test
```

Both use `-full64 -sverilog -ntb_opts uvm-1.2 +vcs+lic+wait`.
The smoke script uses seed 1 for reproducibility; direction remains randomized
without forcing a 50/50 count. It requires successful process exits and the
simulation completion marker. Each run updates its build-directory logs.

Compile and simulation returned 0. Test completion marker was found in
`work/transaction_smoke/run.log`.
Recompiled and reran seed 1 after adding per-item logs: PASS, 52 READ and 48 WRITE.
The log now shows address, write data, direction, size, burst, and result sentinels
for each random item, forced direction case, and restored-state case.

- Factory creation and WORD/SINGLE constructor defaults passed.
- 100 random items: 52 READ, 48 WRITE; word alignment and transfer limits passed.
- Result fields remained unchanged, including an unknown read-data sentinel.
- Forced READ with nonzero write payload and forced WRITE passed.
- Misaligned address, invalid size, and invalid burst were rejected.
- Non-random size/burst were not repaired; randomization succeeded after restore.
- Utility checks passed after implementation: equal READ/WRITE requests, each
  differing request field, ignored READ payload and results, null/incompatible
  objects, symmetry, and unchanged fields after comparison.
- Public print/sprint output contains all fields, named enums, known hex data,
  and X/Z read data and response. The utility PASS marker is present in run.log.

VCS emitted three expected `Error-[CNST-CIF]` diagnostics for the deliberate
constraint conflicts. These calls returned failure as required; the test reached
its PASS marker. Solver-generated diagnostic files remain under the work directory.
Expected unequal comparisons also emit UVM_INFO `[MISCMP]` messages.

The sandbox could not connect to the license server. The approved run outside
the sandbox completed successfully.

## Limits and next action

Only seed 1 and the default 32-bit configuration were tested. This is an object-level
smoke test, not a bus READ/WRITE, interface/SVA, or DUT integration test.
No FU2 integration or Verdi is used.

The owner approved freezing and committing this independent transaction ticket.
This report is included in the transaction completion commit; use Git history for
its identifier. No push or PR publication is included in this action.
Bus integration and any copy utility are outside this task. Interface ownership
remains with the teammate; future signal mappings and slave-response generation
must be agreed before implementation.
