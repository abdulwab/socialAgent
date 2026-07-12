# BeadBox Windows Detection Note

BeadBox may fail to detect Beads when only the npm shim exists (`bd.cmd`) or when the app was started before PATH refreshed.

## Verified Setup

- Native `bd.exe` should be discoverable:

  ```powershell
  where.exe bd.exe
  bd.exe version
  ```

- This machine installs the native binary at:

  ```text
  C:\Users\alvil\.local\bin\bd.exe
  ```

- The directory must be in the user PATH:

  ```powershell
  [Environment]::GetEnvironmentVariable("Path", "User")
  ```

## If BeadBox Still Shows The Welcome Screen

1. Fully quit BeadBox.
2. Start BeadBox again from the Start menu or desktop shortcut.
3. Click **Check again**.
4. If it still fails, start BeadBox from a fresh terminal that can run `bd.exe version` and inspect its diagnostics/dev console.

## Known BeadBox Comment-Body Bug

BeadBox v0.24.1 with `bd` v1.1.0 has a known open upstream issue where the UI can show a bead's `comment_count` but not render the comment bodies:

- Upstream issue: https://github.com/beadbox/beadbox/issues/27
- Local CLI evidence: `bd comments socialhub-v8g.4 --json` returns role comment bodies.
- Local CLI evidence: `bd show socialhub-v8g.4 --json` reports `comment_count` but does not include a `comments` field.
- Local BeadBox API evidence: `/api/bd` can return `bd comments socialhub-v8g.4 --json`.
- Local BeadBox log evidence: normal detail refreshes call `bd show`; no `bd comments` call appears during the detail load.

Conclusion: missing comment bodies in BeadBox are a BeadBox UI/data-loading issue, not a Beads setup failure and not proof that roles failed to comment.

Local workaround applied for this repository:

- Downgraded the native Windows CLI at `C:\Users\alvil\.local\bin\bd.exe` to `bd` v1.0.4.
- Rebuilt `.beads` from a JSONL export so the embedded database is v1.0.4-compatible.
- Restarted BeadBox so it detected `bd version 1.0.4`.
- Verified BeadBox `/api/bd` with `show socialhub-v8g.4 --json`; the response includes a `comments` field with 21 comment entries.

If a future upgrade reintroduces missing comment bodies, use:

```powershell
bd comments <bead-id>
bd comments <bead-id> --json
```

Restarting BeadBox can fix PATH/detection issues. With `bd` v1.1.0 specifically, restart alone did not fix the known comment-body rendering bug.

Do not add API keys or Beads credentials to BeadBox troubleshooting notes.
