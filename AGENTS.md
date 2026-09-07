# AGENTS.md

## Purpose

This file defines mandatory working rules for AI agents in the FPT AHB VIP repository.

The project owner controls project idea, scope, priorities, and final technical decisions.

AI assists with engineering and implementation.
AI does not own project direction.


## Source of Truth

Before implementation, read:

- `docs/PROJECT_CONTEXT.md`
- `docs/ARCHITECTURE.md`
- `docs/CODING_RULES.md`
- `docs/REPO_CURRENT_STATE.md`

Priority of authority:

1. Project owner instruction
2. Project lead requirement
3. Approved project documentation
4. Active task
5. AHB-Lite specification
6. Legacy VIP reference

Do not turn assumptions, recommendations, legacy behavior, or future ideas into requirements.


## Scope Rules

Work only on the active approved task.

Do not:

- implement future features;
- expand scope automatically;
- refactor unrelated code;
- modify another owner's area without approval;
- introduce new architecture layers without approval;
- create speculative infrastructure or placeholders.

If an issue is outside the active task:

**Report it. Do not fix it automatically.**


## Architecture Rule

Current VIP direction is a direct UVM class-based architecture.

Do not recreate unnecessary legacy layers such as:

- Proxy
- Converter
- intermediate transport Struct
- separate simulation BFM layer

Any architecture change requires project-owner approval.


## Coding Rule

Follow:

`docs/CODING_RULES.md`

Do not invent alternative coding conventions.


## Ambiguity Rule

Do not guess silently.

If a requirement, protocol behavior, architecture decision, or ownership boundary is unclear:

1. identify the ambiguity;
2. explain the available options;
3. request a decision if necessary.

Engineering recommendations are not approved decisions until accepted by the project owner.


## Verification Rule

A task is not complete only because code was generated.

Run the required compile/test/simulation when possible.

Never claim verification passed if it was not actually run.


## Completion Report

After implementation, report:

- summary;
- files changed;
- verification performed;
- anything not verified;
- assumptions/risks;
- out-of-scope follow-ups.

Do not implement follow-up work unless it becomes the active approved task.