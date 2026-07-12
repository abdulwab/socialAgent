param(
  [Parameter(Position = 0)]
  [string]$Command = "help",

  [Parameter(Position = 1)]
  [string]$BeadId,

  [Parameter(Position = 2)]
  [string]$Role,

  [Parameter(Position = 3, ValueFromRemainingArguments = $true)]
  [string[]]$Rest
)

$ErrorActionPreference = "Stop"

function Get-RepoRoot {
  $root = (& git rev-parse --show-toplevel 2>$null)
  if (-not $root) {
    throw "Run oa from inside a git repository."
  }
  return $root.Trim()
}

function Resolve-Exe {
  param([string[]]$Names)
  foreach ($name in $Names) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) {
      return $cmd.Source
    }
  }
  return $null
}

function Invoke-Bd {
  param([string[]]$Args)
  $bd = Resolve-Exe @("bd.exe", "bd.cmd", "bd")
  if (-not $bd) {
    throw "bd was not found on PATH."
  }
  & $bd @Args
  if ($LASTEXITCODE -ne 0) {
    throw "bd failed with exit code $LASTEXITCODE"
  }
}

function Get-AgentName {
  param([string]$RoleName)
  $normalized = ($RoleName.Trim()).ToLowerInvariant()
  if ($normalized.StartsWith("oa-")) {
    return $normalized
  }

  $roleKey = (($normalized -replace "[-_]+", " ") -replace "\s+", " ").Trim()
  $knownRoles = @{
    "role selector" = "role-selector"
    "human question framer" = "human-question-framer"
    "maker engineer" = "maker-engineer"
    "process engineer" = "process-engineer"
    "adversarial reviewer" = "adversarial-reviewer"
    "qa strategist" = "qa-strategist"
    "security privacy reviewer" = "security-privacy-reviewer"
    "security/privacy reviewer" = "security-privacy-reviewer"
    "release sre reviewer" = "release-sre-reviewer"
    "documentation reviewer" = "documentation-reviewer"
    "workflow scout" = "workflow-scout"
  }

  if ($knownRoles.ContainsKey($roleKey)) {
    return "oa-$($knownRoles[$roleKey])"
  }

  $slug = ($roleKey -replace "[^a-z0-9]+", "-").Trim("-")
  return "oa-$slug"
}

function Get-RequiredRoleNames {
  @(
    "Role Selector",
    "Human Question Framer",
    "Maker Engineer",
    "Process Engineer",
    "Adversarial Reviewer",
    "QA Strategist",
    "Security Privacy Reviewer",
    "Release SRE Reviewer",
    "Documentation Reviewer",
    "Workflow Scout"
  )
}

function Get-RoleAgentMap {
  foreach ($roleName in Get-RequiredRoleNames) {
    [pscustomobject]@{
      role = $roleName
      agent = Get-AgentName $roleName
    }
  }
}

function Get-SecretPlainText {
  param([securestring]$Secret)
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secret)
  try {
    return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  } finally {
    if ($bstr -ne [IntPtr]::Zero) {
      [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
  }
}

function Get-MiniMaxKeyState {
  $processApi = -not [string]::IsNullOrWhiteSpace($env:MINIMAX_API_KEY)
  $processAlias = -not [string]::IsNullOrWhiteSpace($env:MINIMAX_SUBSCRIPTION_KEY)
  $userApi = -not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable("MINIMAX_API_KEY", "User"))
  $userAlias = -not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable("MINIMAX_SUBSCRIPTION_KEY", "User"))
  $machineApi = -not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable("MINIMAX_API_KEY", "Machine"))
  $machineAlias = -not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable("MINIMAX_SUBSCRIPTION_KEY", "Machine"))

  [pscustomobject]@{
    process_minimax_api_key = $processApi
    process_minimax_subscription_key = $processAlias
    user_minimax_api_key = $userApi
    user_minimax_subscription_key = $userAlias
    machine_minimax_api_key = $machineApi
    machine_minimax_subscription_key = $machineAlias
    any_key_present = ($processApi -or $processAlias -or $userApi -or $userAlias -or $machineApi -or $machineAlias)
  }
}

function Ensure-MiniMaxKey {
  if (-not [string]::IsNullOrWhiteSpace($env:MINIMAX_API_KEY)) {
    return
  }

  $candidates = @(
    $env:MINIMAX_SUBSCRIPTION_KEY,
    [Environment]::GetEnvironmentVariable("MINIMAX_API_KEY", "User"),
    [Environment]::GetEnvironmentVariable("MINIMAX_SUBSCRIPTION_KEY", "User"),
    [Environment]::GetEnvironmentVariable("MINIMAX_API_KEY", "Machine"),
    [Environment]::GetEnvironmentVariable("MINIMAX_SUBSCRIPTION_KEY", "Machine")
  )

  foreach ($candidate in $candidates) {
    if (-not [string]::IsNullOrWhiteSpace($candidate)) {
      $env:MINIMAX_API_KEY = $candidate
      return
    }
  }
}

function Set-MiniMaxKey {
  $first = Read-Host "Enter rotated MiniMax key for user environment" -AsSecureString
  $second = Read-Host "Confirm MiniMax key" -AsSecureString
  $firstPlain = Get-SecretPlainText $first
  $secondPlain = Get-SecretPlainText $second
  try {
    if ([string]::IsNullOrWhiteSpace($firstPlain)) {
      throw "No key entered."
    }
    if ($firstPlain -ne $secondPlain) {
      throw "Key entries did not match."
    }
    [Environment]::SetEnvironmentVariable("MINIMAX_API_KEY", $firstPlain, "User")
    $env:MINIMAX_API_KEY = $firstPlain
    [pscustomobject]@{
      minimax_key_saved_to_user_environment = $true
      minimax_key_value_printed = $false
      restart_shell_recommended = $true
    } | ConvertTo-Json -Depth 3
  } finally {
    $firstPlain = $null
    $secondPlain = $null
  }
}

function Clear-MiniMaxKey {
  [Environment]::SetEnvironmentVariable("MINIMAX_API_KEY", $null, "User")
  [Environment]::SetEnvironmentVariable("MINIMAX_SUBSCRIPTION_KEY", $null, "User")
  Remove-Item Env:\MINIMAX_API_KEY -ErrorAction SilentlyContinue
  Remove-Item Env:\MINIMAX_SUBSCRIPTION_KEY -ErrorAction SilentlyContinue
  [pscustomobject]@{
    user_minimax_key_cleared = $true
    minimax_key_value_printed = $false
  } | ConvertTo-Json -Depth 3
}

function Show-Help {
  @"
Orchestrated Agents wrapper

Usage:
  .\.orchestrated-agents\bin\oa.cmd status
  .\.orchestrated-agents\bin\oa.cmd key-setup
  .\.orchestrated-agents\bin\oa.cmd key-clear
  .\.orchestrated-agents\bin\oa.cmd run <bead-id> <role-name> [extra prompt]

Examples:
  .\.orchestrated-agents\bin\oa.cmd run socialhub-v8g.1 role-selector
  .\.orchestrated-agents\bin\oa.cmd run socialhub-v8g.1 maker-engineer "Implement only the accepted scope."
  .\.orchestrated-agents\bin\oa.cmd run socialhub-v8g.1 adversarial-reviewer

Environment:
  MINIMAX_API_KEY is required for real model calls.
  MINIMAX_SUBSCRIPTION_KEY is accepted as an alias and copied to MINIMAX_API_KEY for the child process.
  key-setup stores MINIMAX_API_KEY in the user environment without printing it.
"@
}

function Test-WrapperSelf {
  # Pre-flight self-check: parses oa.ps1 as PowerShell and validates oa.cmd shim syntax.
  # This runs before any role invocation so a typo introduced by Process Engineer is caught
  # before it can break the orchestration loop. The check is best-effort and only fails loudly
  # if PowerShell cannot parse the file at all.
  $script = $MyInvocation.MyCommand.Path
  if (-not $script) {
    $script = Join-Path $PSScriptRoot "oa.ps1"
  }
  if (-not (Test-Path $script)) {
    throw "Wrapper self-check failed: oa.ps1 not found at $script"
  }
  $tokens = $null
  $errors = $null
  $null = [System.Management.Automation.Language.Parser]::ParseFile($script, [ref]$tokens, [ref]$errors)
  if ($errors -and $errors.Count -gt 0) {
    $first = $errors | Select-Object -First 1
    throw "Wrapper self-check failed: oa.ps1 has parse error at line $($first.Extent.StartLineNumber): $($first.Message)"
  }

  $shim = Join-Path $PSScriptRoot "oa.cmd"
  if (-not (Test-Path $shim)) {
    throw "Wrapper self-check failed: oa.cmd not found at $shim"
  }

  $repo = Get-RepoRoot
  $configPath = Join-Path $repo "opencode.json"
  if (-not (Test-Path $configPath)) {
    throw "Wrapper self-check failed: opencode.json not found at $configPath"
  }

  try {
    $config = Get-Content -Raw $configPath | ConvertFrom-Json
  } catch {
    throw "Wrapper self-check failed: opencode.json is not valid JSON: $($_.Exception.Message)"
  }

  if (-not $config.agent) {
    throw "Wrapper self-check failed: opencode.json has no agent block"
  }

  $agentNames = @($config.agent.PSObject.Properties.Name)
  $missing = @()
  $roleMap = @(Get-RoleAgentMap)
  foreach ($entry in $roleMap) {
    if ($agentNames -notcontains $entry.agent) {
      $missing += "$($entry.role) -> $($entry.agent)"
    }
  }
  if ($missing.Count -gt 0) {
    throw "Wrapper self-check failed: role display names do not map to configured agents: $($missing -join ', ')"
  }

  return [pscustomobject]@{
    wrapper_self_check = "ok"
    oa_ps1_path = $script
    oa_cmd_path = $shim
    role_agent_map = $roleMap
  }
}

function Show-Status {
  $repo = Get-RepoRoot
  $bd = Resolve-Exe @("bd.exe", "bd.cmd", "bd")
  $opencode = Resolve-Exe @("opencode.cmd", "opencode.exe", "opencode")
  $keyState = Get-MiniMaxKeyState
  $config = Join-Path $repo "opencode.json"

  $selfState = "unknown"
  $roleAgentMap = @()
  try {
    $selfCheck = Test-WrapperSelf
    $selfState = "ok"
    $roleAgentMap = @($selfCheck.role_agent_map)
  } catch {
    $selfState = "fail: $($_.Exception.Message)"
  }

  [pscustomobject]@{
    repo = $repo
    bd = $bd
    opencode = $opencode
    opencode_config = $config
    opencode_config_exists = Test-Path $config
    wrapper_self_check = $selfState
    role_agent_map = $roleAgentMap
    minimax_key_present = $keyState.any_key_present
    key_sources = $keyState
    minimax_key_value_printed = $false
  } | ConvertTo-Json -Depth 3
}

function Run-Role {
  param(
    [string]$Id,
    [string]$RoleName,
    [string[]]$ExtraPrompt
  )
  if (-not $Id) { throw "Missing bead id." }
  if (-not $RoleName) { throw "Missing role name." }

  $selfCheck = Test-WrapperSelf
  if ($selfCheck.wrapper_self_check -ne "ok") {
    throw "Wrapper self-check did not return ok. Aborting role invocation."
  }

  $repo = Get-RepoRoot
  $opencode = Resolve-Exe @("opencode.cmd", "opencode.exe", "opencode")
  if (-not $opencode) {
    throw "opencode was not found on PATH."
  }

  Ensure-MiniMaxKey
  if ([string]::IsNullOrWhiteSpace($env:MINIMAX_API_KEY)) {
    throw "MINIMAX_API_KEY is not set. Run 'oa.cmd key-setup' or set MINIMAX_API_KEY outside the repo before running MiniMax roles."
  }

  $agent = Get-AgentName $RoleName

  $extra = ""
  if ($ExtraPrompt) {
    $extra = [string]::Join(" ", $ExtraPrompt)
  }

  $prompt = @"
Target bead: $Id
Role: $RoleName

Use the repository Beads workflow. You, the role, must run the Beads commands yourself. The wrapper will not assign the bead or add comments for you.

Your first commands must be equivalent to:

```powershell
`$env:BEADS_ACTOR="$RoleName"
bd show $Id
bd update $Id --assignee "$RoleName" --status in_progress
@'
### Commentor: $RoleName

**Step/Subtask:** <real subtask you are starting>

**Status:** In Progress

**Findings:** <what you are doing and why>

**Evidence:** <bead, files, commands, sources, or reasoning>

**Required Next Action:** <next action>
'@ | bd comment $Id --stdin
```

Do not write test, probe, placeholder, or scratch comments on real beads. Every comment must be a real formatted Markdown work record. Use only your role permissions. $extra
"@

  $oldActor = $env:BEADS_ACTOR
  $oldTarget = $env:OA_TARGET_BEAD
  $oldRole = $env:OA_ROLE_NAME
  $env:BEADS_ACTOR = $RoleName
  $env:OA_TARGET_BEAD = $Id
  $env:OA_ROLE_NAME = $RoleName
  & $opencode run --dir $repo --agent $agent --model minimax/MiniMax-M3 --variant max --thinking --auto --title "oa $RoleName $Id" $prompt
  $exit = $LASTEXITCODE
  $env:BEADS_ACTOR = $oldActor
  $env:OA_TARGET_BEAD = $oldTarget
  $env:OA_ROLE_NAME = $oldRole

  if ($exit -ne 0) {
    exit $exit
  }
}

switch ($Command.ToLowerInvariant()) {
  "help" { Show-Help }
  "status" { Show-Status }
  "key-setup" { Set-MiniMaxKey }
  "key-clear" { Clear-MiniMaxKey }
  "run" { Run-Role -Id $BeadId -RoleName $Role -ExtraPrompt $Rest }
  default {
    Show-Help
    throw "Unknown command: $Command"
  }
}
