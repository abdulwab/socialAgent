# Orchestrated Agents

This package makes Beads the durable control plane and OpenCode the MiniMax-M3 execution surface.

Codex should stay small: choose a bead ID, invoke a role, and handle only infrastructure failures that MiniMax roles cannot repair. MiniMax roles do the SDLC work, debate, critique, implementation, QA, security review, release review, documentation review, and workflow improvement.

For the full operating context, read `.orchestrated-agents/docs/CONTEXT.md`. (Note: on Windows this path is case-insensitive; on macOS/Linux the file must be referenced with exactly that uppercase spelling. The framework's system-reminder injection uses the uppercase path, so this README matches.)

Role invocations use MiniMax-M3 with the highest available OpenCode thinking variant: `--variant max --thinking`.

## Quick Start

1. Ensure `bd` is installed and initialized in the repository.
2. Ensure OpenCode is installed and callable as `opencode.cmd` on Windows.
3. Set the MiniMax key outside the repo:

   ```powershell
   [Environment]::SetEnvironmentVariable("MINIMAX_API_KEY", "<your-key>", "User")
   ```

4. Open a new terminal so the environment refreshes.
5. Run a local check:

   ```powershell
   .\.orchestrated-agents\bin\oa.cmd status
   ```

6. If `minimax_key_present` is false, configure the key without printing it:

   ```powershell
   .\.orchestrated-agents\bin\oa.cmd key-setup
   ```

   Use a rotated key if any previous key was pasted into chat or logs.

7. Invoke a role by bead ID:

   ```powershell
   .\.orchestrated-agents\bin\oa.cmd run socialhub-v8g.1 role-selector
   .\.orchestrated-agents\bin\oa.cmd run socialhub-v8g.1 maker-engineer
   .\.orchestrated-agents\bin\oa.cmd run socialhub-v8g.1 adversarial-reviewer
   ```

## Design Rules

- Every role must assign the bead to itself before work.
- Every role must add formatted Markdown comments for every meaningful substep.
- The wrapper must not add comments as a role. It only sets role context and invokes OpenCode.
- Every bead starts with role-selection debate.
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

Do not place MiniMax keys in repo files, Beads comments, prompts, logs, screenshots, or generated docs. Use `MINIMAX_API_KEY` in the user or process environment. The wrapper only reports whether a key is present; it never prints the value.

To clear user-scoped MiniMax environment variables:

```powershell
.\.orchestrated-agents\bin\oa.cmd key-clear
```
