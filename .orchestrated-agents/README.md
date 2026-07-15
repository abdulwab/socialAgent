# Orchestrated Agents

This package makes Beads the durable control plane and OpenCode the role execution surface.

Codex should stay small: choose a bead ID, invoke a role, and handle only infrastructure failures that doer roles cannot repair. The configured model performs the SDLC work, debate, critique, implementation, QA, security review, release review, documentation review, and workflow improvement.

For the shared workflow reference, read `.orchestrated-agents/WORKFLOW.md`. For the full operating context, read `.orchestrated-agents/docs/CONTEXT.md`. (Note: on Windows this path is case-insensitive; on macOS/Linux the file must be referenced with exactly that uppercase spelling. The framework's system-reminder injection uses the uppercase path, so this README matches.)

Role invocations default to Z.AI GLM-5.2. Thinking effort is role-policy controlled: `Researcher`, `Planner`, and `Architect` use `--variant max --thinking`; every other role uses `--variant high --thinking`.

## Quick Start

1. Ensure `bd` is installed and initialized in the repository.
2. Ensure OpenCode is installed and callable as `opencode.cmd` on Windows.
3. Configure the Z.AI key outside the repo without printing it:

   ```powershell
   .\.orchestrated-agents\bin\oa.cmd key-setup zai
   ```

4. Open a new terminal so the environment refreshes.
5. Run a local check:

   ```powershell
   .\.orchestrated-agents\bin\oa.cmd status
   ```

6. If `active_provider_key_present` is false, configure the active provider key without printing it:

   ```powershell
   .\.orchestrated-agents\bin\oa.cmd key-setup zai
   ```

   Use a rotated key if any previous key was pasted into chat or logs.

7. To switch providers/models for all role invocations, set one of:

   ```powershell
   $env:OA_MODEL_SPEC = "zai/glm-5.2"
   $env:OA_MODEL_SPEC = "minimax/MiniMax-M3"
   ```

   Or set the pieces separately:

   ```powershell
   $env:OA_PROVIDER = "zai"
   $env:OA_MODEL = "glm-5.2"
   # Thinking effort is not globally widened by default.
   # Researcher, Planner, and Architect use max; every other role uses high.
   ```

   To switch only one role, use the role name as uppercase underscores:

   ```powershell
   $env:OA_QA_STRATEGIST_MODEL_SPEC = "zai/glm-5.2"
   $env:OA_SECURITY_PRIVACY_REVIEWER_MODEL_SPEC = "minimax/MiniMax-M3"
   ```

   Role-specific model variables override global model variables. Global model variables override the default `zai/glm-5.2`.
   `oa.cmd status` prints `role_model_map` so the active model and enforced thinking effort per role can be checked without invoking a role.

8. Invoke a role by bead ID:

   ```powershell
   .\.orchestrated-agents\bin\oa.cmd run socialhub-v8g.1 role-selector
   .\.orchestrated-agents\bin\oa.cmd run socialhub-v8g.1 maker-engineer
   .\.orchestrated-agents\bin\oa.cmd run socialhub-v8g.1 adversarial-reviewer
   ```

   The `<role-name>` argument accepts three equivalent spellings (ORCH-REQ-008):
   the canonical display name (`"Workflow Engineer"`), the dash-slug
   (`workflow-engineer`), or the oa-agent-slug (`oa-workflow-engineer`). All
   three resolve to the same canonical display role and the same configured
   agent. Unrecognized spellings fail closed. The orchestrator/operator MUST
   quote space-containing role names (e.g. `oa.cmd run <bead> "Workflow
   Engineer"`) so a quoting split cannot silently run the wrong agent or corrupt
   the bd comment author. Slugs are an invocation convenience only; role
   comments and Beads authors must use the canonical display name.

   Role runs are monitored by the wrapper. Runtime evidence is written under
   `.orchestrated-agents/logs/role-runs/` (ignored by git): `*.meta.json`,
   `*.stdout.log`, `*.stderr.log`, and `*.result.json` or `*.timeout.json`.
   Defaults: poll every `30` seconds, warn after `300` seconds without log
   output, and hard-timeout after `720` seconds. Override only for a specific
   troubleshooting session:

   ```powershell
   $env:OA_ROLE_RUN_POLL_SECONDS = "30"
   $env:OA_ROLE_RUN_STALE_SECONDS = "300"
   $env:OA_ROLE_RUN_TIMEOUT_SECONDS = "720"
   $env:OA_ROLE_RUN_LOG_DIR = ".orchestrated-agents/logs/role-runs"
   ```

## Design Rules

- Every role must assign the bead to itself before work.
- Every role must add formatted Markdown comments for every meaningful substep.
- The wrapper must not add comments as a role. It only sets role context and invokes OpenCode.
- Every bead starts with role-selection debate.
- Use `Researcher`, `Planner`, and `Architect` as first-class roles when a bead needs authoritative evidence, execution planning, or architecture tradeoff analysis.
- Every bead then runs a human-input debate before SDLC work.
- No single role may complete a task without adversarial review.
- Maker roles are the only roles allowed to edit files.
- Adversarial roles critique and comment; they do not change files.
- Workflow flaws become new workflow-improvement beads created by Workflow Scout.

## Copying To Another Repository

Copy these paths:

- `.orchestrated-agents/`
- `opencode.json` or merge its `provider`, `instructions`, and `agent` entries into the target repo config.

Then run:

```powershell
bd init --quiet --non-interactive --init-if-missing
.\.orchestrated-agents\bin\oa.cmd status
```

## Platform Support

**Status: Windows-only.** The wrapper (`bin/oa.cmd` and `bin/oa.ps1`) uses Windows-specific features:

- `oa.cmd` is a Windows CMD shim.
- `oa.ps1` uses `Read-Host -AsSecureString` and `[Runtime.InteropServices.Marshal]` for `SecureString` -> `BSTR`, which is a Windows-only DPAPI path.
- `oa.ps1` uses `Remove-Item Env:` for clearing per-process env vars and writes to the User environment via `[Environment]::SetEnvironmentVariable(..., "User")`.
- The wrapper resolves `bd.exe`, `bd.cmd`, `opencode.cmd` first, then `.exe`, then extension-less names - all Windows conventions.

**macOS and Linux are NOT supported by this version.** POSIX support requires a parallel `oa.sh` wrapper that replaces `SecureString` with `read -s`, drops DPAPI, and uses the `unset` builtin for env clearing. POSIX support is tracked as a future-work follow-up bead, not implemented here.

When copying to another repository, only target Windows hosts until the POSIX wrapper is added.

## Secret Handling

Do not place provider keys in repo files, Beads comments, prompts, logs, screenshots, or generated docs. Use `ZAI_API_KEY` for Z.AI and `MINIMAX_API_KEY` for MiniMax in the user or process environment. The wrapper only reports whether a key is present; it never prints the value.

To clear user-scoped provider environment variables:

```powershell
.\.orchestrated-agents\bin\oa.cmd key-clear zai
.\.orchestrated-agents\bin\oa.cmd key-clear minimax
```
