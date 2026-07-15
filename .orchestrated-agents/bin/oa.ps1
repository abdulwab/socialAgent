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
  if ([string]::IsNullOrWhiteSpace($RoleName)) {
    throw "Get-AgentName: role name is required. Configured roles: $((Get-RequiredRoleNames) -join ', ')."
  }
  $normalized = ($RoleName.Trim()).ToLowerInvariant()
  # NOTE: there is NO early-return passthrough for oa-* slugs. An oa-prefixed
  # input is validated through the catalog loop below: Get-RoleSpellingKey
  # strips the "oa-" prefix and normalizes separators, so a VALID oa-agent-slug
  # (e.g. "oa-workflow-engineer") matches its catalog entry and returns that
  # entry's agentSlug, while a BOGUS oa-* string (e.g. "oa-anything") matches
  # no catalog entry and falls through to the fail-closed throw. This closes
  # the silent-accept gap flagged by Adversarial Reviewer Needs Fix 4
  # (socialhub-v8g.24.8): the old passthrough returned ANY oa-prefixed string
  # as-is, which is a silent accept, not fail-closed.

  foreach ($entry in (Get-RoleCatalog)) {
    $candidateKeys = @(
      (Get-RoleSpellingKey $entry.display),
      (Get-RoleSpellingKey $entry.dashSlug)
    )
    foreach ($alias in $entry.aliases) {
      $candidateKeys += (Get-RoleSpellingKey $alias)
    }
    if ((Get-RoleSpellingKey $RoleName) -in $candidateKeys) {
      return $entry.agentSlug
    }
  }

  # Fail-closed: do NOT silently slugify an unrecognized role. A silent fallback
  # could route a restricted role to the wrong agent (the original ORCH-REQ-008
  # bug class, socialhub-v8g.24.8). Resolve-Role is the public Run-Role entry
  # point; this guard is defense-in-depth for any internal caller. All internal
  # callers pass canonical names from Get-RequiredRoleNames, so this throw is
  # only reachable for a genuinely unrecognized input.
  throw "Get-AgentName: unrecognized role '$RoleName'. Accepted spellings are the canonical display name (e.g. 'Workflow Engineer'), the dash-slug (e.g. 'workflow-engineer'), or the oa-agent-slug (e.g. 'oa-workflow-engineer'). Configured roles: $((Get-RequiredRoleNames) -join ', ')."
}

function Get-RequiredRoleNames {
  @(
    "Role Selector",
    "Human Question Framer",
    "Researcher",
    "Planner",
    "Architect",
    "Maker Engineer",
    "Workflow Engineer",
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

function Get-RoleCatalog {
  # Single source of truth for the 13-role taxonomy and their accepted
  # spellings. Returns one object per role with: display (canonical name used
  # in comments and BEADS_ACTOR), dashSlug, agentSlug (oa-*), and aliases
  # (legacy/convenience spellings). The canonical display list mirrors
  # Get-RequiredRoleNames exactly; aliases are the only supplemental data.
  # ORCH-REQ-008 / socialhub-v8g.24.8.
  $spec = @(
    @{ display = "Role Selector";             aliases = @() },
    @{ display = "Human Question Framer";     aliases = @() },
    @{ display = "Researcher";                aliases = @("research") },
    @{ display = "Planner";                   aliases = @() },
    @{ display = "Architect";                 aliases = @() },
    @{ display = "Maker Engineer";            aliases = @() },
    @{ display = "Workflow Engineer";         aliases = @() },
    @{ display = "Adversarial Reviewer";      aliases = @() },
    @{ display = "QA Strategist";             aliases = @() },
    @{ display = "Security Privacy Reviewer"; aliases = @("security/privacy reviewer") },
    @{ display = "Release SRE Reviewer";      aliases = @() },
    @{ display = "Documentation Reviewer";    aliases = @() },
    @{ display = "Workflow Scout";            aliases = @() }
  )
  foreach ($entry in $spec) {
    $dash = (($entry.display.ToLowerInvariant() -replace "[^a-z0-9]+", "-").Trim("-"))
    [pscustomobject]@{
      display   = $entry.display
      dashSlug  = $dash
      agentSlug = "oa-$dash"
      aliases   = @($entry.aliases)
    }
  }
}

function Get-RoleSpellingKey {
  # Normalize any role spelling to a single comparison key so the three accepted
  # forms collapse to one space:
  #   "Workflow Engineer"    -> "workflow engineer"
  #   "workflow-engineer"    -> "workflow engineer"
  #   "oa-workflow-engineer" -> "workflow engineer"  (oa- agent prefix stripped)
  # Separators [-_/] and whitespace collapse to single spaces; case-insensitive.
  param([string]$Spelling)
  $k = ($Spelling.Trim()).ToLowerInvariant()
  if ($k.StartsWith("oa-")) {
    $k = $k.Substring(3)
  }
  $k = ($k -replace "[-_/\s]+", " ").Trim()
  return $k
}

function Resolve-Role {
  # Public Run-Role entry-point resolver (ORCH-REQ-008 / socialhub-v8g.24.8).
  # Accepts any sanctioned spelling -- canonical display name, dash-slug,
  # oa-agent-slug, or a documented alias -- and returns BOTH the canonical
  # display role name (for the prompt, BEADS_ACTOR, and comment template) and
  # the configured agent slug (for opencode run). FAIL-CLOSED on any
  # unrecognized spelling: a quoting split that delivers only the first word of
  # a space-containing role MUST surface a clear error rather than silently run
  # the wrong agent or corrupt BEADS_ACTOR / comment attribution.
  param([string]$RoleSpelling)
  if ([string]::IsNullOrWhiteSpace($RoleSpelling)) {
    throw "Missing role name. Accepted spellings: canonical display name (e.g. 'Workflow Engineer'), dash-slug (e.g. 'workflow-engineer'), or oa-agent-slug (e.g. 'oa-workflow-engineer'). Configured roles: $((Get-RequiredRoleNames) -join ', ')."
  }

  $inputKey = Get-RoleSpellingKey $RoleSpelling
  foreach ($entry in (Get-RoleCatalog)) {
    $candidateKeys = @(
      (Get-RoleSpellingKey $entry.display),
      (Get-RoleSpellingKey $entry.dashSlug),
      (Get-RoleSpellingKey $entry.agentSlug)
    )
    foreach ($alias in $entry.aliases) {
      $candidateKeys += (Get-RoleSpellingKey $alias)
    }
    if ($inputKey -in $candidateKeys) {
      # No catalog-internal cross-check here. Comparing the catalog's own
      # agentSlug against Get-AgentName (which reads the SAME catalog) is
      # tautological -- it can catch neither a typo in agentSlug nor a
      # spelling-key collision, because both sides derive from one source.
      # The INDEPENDENT validation that every catalog agent slug exists as a
      # configured agent in opencode.json (a separate declaration) is
      # performed by Test-WrapperSelf (see the $agentNames -notcontains loop
      # there), which runs at the top of Run-Role before any role invocation,
      # and is independently exercised by the regression test's "registry"
      # section in test-role-resolution.ps1.
      return [pscustomobject]@{
        display  = $entry.display
        agent    = $entry.agentSlug
        spelling = $RoleSpelling
      }
    }
  }

  throw "Unrecognized role spelling: '$RoleSpelling'. Accepted spellings are the canonical display name (e.g. 'Workflow Engineer'), the dash-slug (e.g. 'workflow-engineer'), or the oa-agent-slug (e.g. 'oa-workflow-engineer'). Configured roles: $((Get-RequiredRoleNames) -join ', ')."
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

function Get-ZaiKeyState {
  $processApi = -not [string]::IsNullOrWhiteSpace($env:ZAI_API_KEY)
  $userApi = -not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable("ZAI_API_KEY", "User"))
  $machineApi = -not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable("ZAI_API_KEY", "Machine"))

  [pscustomobject]@{
    process_zai_api_key = $processApi
    user_zai_api_key = $userApi
    machine_zai_api_key = $machineApi
    any_key_present = ($processApi -or $userApi -or $machineApi)
  }
}

function Ensure-ZaiKey {
  if (-not [string]::IsNullOrWhiteSpace($env:ZAI_API_KEY)) {
    return
  }

  $candidates = @(
    [Environment]::GetEnvironmentVariable("ZAI_API_KEY", "User"),
    [Environment]::GetEnvironmentVariable("ZAI_API_KEY", "Machine")
  )

  foreach ($candidate in $candidates) {
    if (-not [string]::IsNullOrWhiteSpace($candidate)) {
      $env:ZAI_API_KEY = $candidate
      return
    }
  }
}

function Set-ZaiKey {
  $first = Read-Host "Enter Z.AI API key for user environment" -AsSecureString
  $second = Read-Host "Confirm Z.AI API key" -AsSecureString
  $firstPlain = Get-SecretPlainText $first
  $secondPlain = Get-SecretPlainText $second
  try {
    if ([string]::IsNullOrWhiteSpace($firstPlain)) {
      throw "No key entered."
    }
    if ($firstPlain -ne $secondPlain) {
      throw "Key entries did not match."
    }
    [Environment]::SetEnvironmentVariable("ZAI_API_KEY", $firstPlain, "User")
    $env:ZAI_API_KEY = $firstPlain
    [pscustomobject]@{
      provider = "zai"
      zai_key_saved_to_user_environment = $true
      zai_key_value_printed = $false
      restart_shell_recommended = $true
    } | ConvertTo-Json -Depth 3
  } finally {
    $firstPlain = $null
    $secondPlain = $null
  }
}

function Clear-ZaiKey {
  [Environment]::SetEnvironmentVariable("ZAI_API_KEY", $null, "User")
  Remove-Item Env:\ZAI_API_KEY -ErrorAction SilentlyContinue
  [pscustomobject]@{
    provider = "zai"
    user_zai_key_cleared = $true
    zai_key_value_printed = $false
  } | ConvertTo-Json -Depth 3
}

function Normalize-ProviderName {
  param([string]$ProviderName)
  $value = $ProviderName
  if ([string]::IsNullOrWhiteSpace($value)) {
    $value = $env:OA_PROVIDER
  }
  if ([string]::IsNullOrWhiteSpace($value) -and -not [string]::IsNullOrWhiteSpace($env:OA_MODEL_SPEC)) {
    $value = ($env:OA_MODEL_SPEC -split "/", 2)[0]
  }
  if ([string]::IsNullOrWhiteSpace($value)) {
    $value = "zai"
  }

  $key = (($value.Trim()).ToLowerInvariant() -replace "[^a-z0-9]+", "-").Trim("-")
  switch ($key) {
    "zai" { "zai"; break }
    "z-ai" { "zai"; break }
    "zai-coding-plan" { "zai"; break }
    "z-ai-coding-plan" { "zai"; break }
    "glm" { "zai"; break }
    "minimax" { "minimax"; break }
    default { $key }
  }
}

function Get-RoleEnvSuffix {
  param([string]$RoleName)
  if ([string]::IsNullOrWhiteSpace($RoleName)) {
    return $null
  }
  $roleKey = (($RoleName.Trim()).ToUpperInvariant() -replace "[^A-Z0-9]+", "_").Trim("_")
  return $roleKey
}

function Get-EnvValue {
  param([string[]]$Names)
  foreach ($name in $Names) {
    if ([string]::IsNullOrWhiteSpace($name)) {
      continue
    }
    $value = [Environment]::GetEnvironmentVariable($name, "Process")
    if (-not [string]::IsNullOrWhiteSpace($value)) {
      return $value
    }
    $value = [Environment]::GetEnvironmentVariable($name, "User")
    if (-not [string]::IsNullOrWhiteSpace($value)) {
      return $value
    }
    $value = [Environment]::GetEnvironmentVariable($name, "Machine")
    if (-not [string]::IsNullOrWhiteSpace($value)) {
      return $value
    }
  }
  return $null
}

function Get-RoleKey {
  param([string]$RoleName)
  if ([string]::IsNullOrWhiteSpace($RoleName)) {
    return ""
  }
  return (($RoleName.Trim()).ToLowerInvariant() -replace "[-_]+", " " -replace "\s+", " ").Trim()
}

function Test-MaxThinkingRole {
  param([string]$RoleName)
  $roleKey = Get-RoleKey $RoleName
  $agentKey = ""
  if (-not [string]::IsNullOrWhiteSpace($RoleName)) {
    $agentKey = ((Get-AgentName $RoleName).ToLowerInvariant() -replace "^oa-", "" -replace "[-_]+", " " -replace "\s+", " ").Trim()
  }

  foreach ($candidate in @($roleKey, $agentKey)) {
    if ($candidate -in @("research", "researcher", "planner", "architect")) {
      return $true
    }
  }
  return $false
}

function Get-RoleThinkingVariant {
  param([string]$RoleName)
  if (Test-MaxThinkingRole $RoleName) {
    return "max"
  }
  return "high"
}

function Get-ActiveModelConfig {
  param([string]$RoleName)

  $roleSuffix = Get-RoleEnvSuffix $RoleName
  $roleAgentSuffix = $null
  if (-not [string]::IsNullOrWhiteSpace($RoleName)) {
    $roleAgentSuffix = ((Get-AgentName $RoleName).ToUpperInvariant() -replace "^OA-", "" -replace "[^A-Z0-9]+", "_").Trim("_")
  }

  $roleSpecificModelSpecNames = @()
  $roleSpecificProviderNames = @()
  $roleSpecificModelNames = @()
  $roleSpecificVariantNames = @()
  $roleSpecificThinkingNames = @()
  foreach ($suffix in @($roleSuffix, $roleAgentSuffix)) {
    if (-not [string]::IsNullOrWhiteSpace($suffix)) {
      $roleSpecificModelSpecNames += "OA_${suffix}_MODEL_SPEC"
      $roleSpecificModelSpecNames += "OA_MODEL_SPEC_${suffix}"
      $roleSpecificProviderNames += "OA_${suffix}_PROVIDER"
      $roleSpecificProviderNames += "OA_PROVIDER_${suffix}"
      $roleSpecificModelNames += "OA_${suffix}_MODEL"
      $roleSpecificModelNames += "OA_MODEL_${suffix}"
      $roleSpecificVariantNames += "OA_${suffix}_THINKING_VARIANT"
      $roleSpecificVariantNames += "OA_THINKING_VARIANT_${suffix}"
      $roleSpecificThinkingNames += "OA_${suffix}_THINKING"
      $roleSpecificThinkingNames += "OA_THINKING_${suffix}"
    }
  }

  $modelSpec = Get-EnvValue ($roleSpecificModelSpecNames + @("OA_MODEL_SPEC"))
  $provider = Normalize-ProviderName (Get-EnvValue ($roleSpecificProviderNames + @("OA_PROVIDER")))
  $model = Get-EnvValue ($roleSpecificModelNames + @("OA_MODEL"))

  if (-not [string]::IsNullOrWhiteSpace($modelSpec)) {
    $parts = $modelSpec -split "/", 2
    if ($parts.Count -eq 2) {
      $provider = Normalize-ProviderName $parts[0]
      $model = $parts[1]
    }
  }

  if ([string]::IsNullOrWhiteSpace($model)) {
    if ($provider -eq "minimax") {
      $model = "MiniMax-M3"
    } else {
      $model = "glm-5.2"
    }
  }

  if ([string]::IsNullOrWhiteSpace($modelSpec)) {
    $modelSpec = "$provider/$model"
  }

  $requestedVariant = Get-EnvValue ($roleSpecificVariantNames + @("OA_THINKING_VARIANT"))
  $variant = Get-RoleThinkingVariant $RoleName
  $thinkingPolicy = "Researcher/Planner/Architect use max; every other role uses high."
  if (-not [string]::IsNullOrWhiteSpace($requestedVariant) -and ($requestedVariant -ne $variant)) {
    $thinkingPolicy = "$thinkingPolicy Requested variant '$requestedVariant' ignored by role-effort policy."
  }

  $thinkingText = Get-EnvValue ($roleSpecificThinkingNames + @("OA_THINKING"))
  $thinking = $true
  if (-not [string]::IsNullOrWhiteSpace($thinkingText)) {
    $thinking = ($thinkingText -notmatch '^(0|false|no|off)$')
  }

  [pscustomobject]@{
    provider = $provider
    model = $model
    model_spec = $modelSpec
    thinking_variant = $variant
    thinking_enabled = $thinking
    thinking_policy = $thinkingPolicy
    role = $RoleName
    role_env_suffix = $roleSuffix
    source = "role model env > global model env; defaults to zai/glm-5.2; thinking effort is role-policy controlled"
  }
}

function Get-ProviderKeyState {
  $miniMax = Get-MiniMaxKeyState
  $zai = Get-ZaiKeyState
  $active = Get-ActiveModelConfig
  $activePresent = $false
  switch ($active.provider) {
    "minimax" { $activePresent = $miniMax.any_key_present }
    "zai" { $activePresent = $zai.any_key_present }
  }

  [pscustomobject]@{
    active_provider = $active.provider
    active_provider_key_present = $activePresent
    zai = $zai
    minimax = $miniMax
    key_value_printed = $false
  }
}

function Ensure-ActiveProviderKey {
  param([object]$ModelConfig)
  switch ($ModelConfig.provider) {
    "minimax" {
      Ensure-MiniMaxKey
      if ([string]::IsNullOrWhiteSpace($env:MINIMAX_API_KEY)) {
        throw "MINIMAX_API_KEY is not set. Run 'oa.cmd key-setup minimax' or set MINIMAX_API_KEY outside the repo."
      }
    }
    "zai" {
      Ensure-ZaiKey
      if ([string]::IsNullOrWhiteSpace($env:ZAI_API_KEY)) {
        throw "ZAI_API_KEY is not set. Run 'oa.cmd key-setup zai' or set ZAI_API_KEY outside the repo."
      }
    }
    default {
      throw "No key handler is configured for provider '$($ModelConfig.provider)'. Set OA_MODEL_SPEC to a configured OpenCode provider/model and authenticate that provider separately."
    }
  }
}

function Set-ProviderKey {
  param([string]$ProviderName)
  $provider = Normalize-ProviderName $ProviderName
  switch ($provider) {
    "minimax" { Set-MiniMaxKey }
    "zai" { Set-ZaiKey }
    default { throw "No key-setup handler for provider '$provider'." }
  }
}

function Clear-ProviderKey {
  param([string]$ProviderName)
  $provider = Normalize-ProviderName $ProviderName
  switch ($provider) {
    "minimax" { Clear-MiniMaxKey }
    "zai" { Clear-ZaiKey }
    default { throw "No key-clear handler for provider '$provider'." }
  }
}

function Show-Help {
  @"
Orchestrated Agents wrapper

Usage:
  .\.orchestrated-agents\bin\oa.cmd status
  .\.orchestrated-agents\bin\oa.cmd key-setup [zai|minimax]
  .\.orchestrated-agents\bin\oa.cmd key-clear [zai|minimax]
  .\.orchestrated-agents\bin\oa.cmd run <bead-id> <role-name> [extra prompt]

Role names (ORCH-REQ-008):
  The <role-name> argument accepts three equivalent spellings. All three resolve
  to the SAME canonical display role name and the SAME configured oa-* agent:
    - canonical display name : "Workflow Engineer", "QA Strategist", ...
    - dash-slug              : workflow-engineer, qa-strategist, ...
    - oa-agent-slug          : oa-workflow-engineer, oa-qa-strategist, ...
  Unrecognized spellings FAIL CLOSED (the wrapper errors out instead of running
  the wrong agent). This also catches a quoting split: if a space-containing
  role name is passed unquoted and only the first word arrives, the wrapper
  rejects it rather than silently corrupting the bd comment author. The
  orchestrator/operator MUST quote space-containing role names, e.g.:
    oa.cmd run <bead-id> "Workflow Engineer"
  The canonical display name is what appears in comments and BEADS_ACTOR; slugs
  are accepted as a convenience but role comments and Beads authors must use the
  canonical display name (see .orchestrated-agents/WORKFLOW.md Role Invocation).

Examples:
  .\.orchestrated-agents\bin\oa.cmd run socialhub-v8g.1 role-selector
  .\.orchestrated-agents\bin\oa.cmd run socialhub-v8g.1 "Maker Engineer" "Implement only the accepted scope."
  .\.orchestrated-agents\bin\oa.cmd run socialhub-v8g.1 oa-adversarial-reviewer
  .\.orchestrated-agents\bin\oa.cmd run socialhub-v8g.1 workflow-engineer

Environment:
  Default active model is zai/glm-5.2.
  Set OA_MODEL_SPEC (for example zai/glm-5.2 or minimax/MiniMax-M3) to switch globally.
  Set OA_PROVIDER and OA_MODEL as an alternative to OA_MODEL_SPEC.
  Thinking effort is role-policy controlled: Researcher, Planner, and Architect use max; every other role uses high.
  OA_THINKING_VARIANT and role-specific thinking-variant variables are reported but ignored when they conflict with this policy.
  Set OA_<ROLE>_MODEL_SPEC (for example OA_QA_STRATEGIST_MODEL_SPEC=zai/glm-5.2) to switch one role.
  ZAI_API_KEY is required for Z.AI GLM calls.
  MINIMAX_API_KEY is required for MiniMax calls.
  MINIMAX_SUBSCRIPTION_KEY is accepted as an alias and copied to MINIMAX_API_KEY for the child process.
  key-setup stores the provider key in the user environment without printing it.
"@
}

function Test-WrapperSelf {
  # Pre-flight self-check: parses oa.ps1 as PowerShell and validates oa.cmd shim syntax.
  # This runs before any role invocation so a typo introduced by Workflow Engineer is caught
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
  $modelConfig = Get-ActiveModelConfig
  $keyState = Get-ProviderKeyState
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
    role_model_map = @($roleAgentMap | ForEach-Object {
      $roleModel = Get-ActiveModelConfig -RoleName $_.role
      [pscustomobject]@{
        role = $_.role
        agent = $_.agent
        model_spec = $roleModel.model_spec
        thinking_variant = $roleModel.thinking_variant
        thinking_enabled = $roleModel.thinking_enabled
        role_env_suffix = $roleModel.role_env_suffix
      }
    })
    active_model = $modelConfig
    active_provider_key_present = $keyState.active_provider_key_present
    key_sources = $keyState
    key_value_printed = $false
  } | ConvertTo-Json -Depth 3
}

function Get-PositiveIntEnv {
  param(
    [string[]]$Names,
    [int]$Default,
    [int]$Minimum = 1
  )
  $raw = Get-EnvValue $Names
  if ([string]::IsNullOrWhiteSpace($raw)) {
    return $Default
  }
  $value = 0
  if (-not [int]::TryParse($raw, [ref]$value)) {
    throw "Invalid integer value '$raw' for $($Names -join '/')."
  }
  if ($value -lt $Minimum) {
    throw "Invalid value '$raw' for $($Names -join '/'); expected >= $Minimum."
  }
  return $value
}

function Get-RoleRunWatchdogConfig {
  $repo = Get-RepoRoot
  $defaultLogDir = Join-Path $repo ".orchestrated-agents\logs\role-runs"
  $logDir = Get-EnvValue @("OA_ROLE_RUN_LOG_DIR")
  if ([string]::IsNullOrWhiteSpace($logDir)) {
    $logDir = $defaultLogDir
  }
  if (-not [System.IO.Path]::IsPathRooted($logDir)) {
    $logDir = Join-Path $repo $logDir
  }

  [pscustomobject]@{
    poll_seconds = Get-PositiveIntEnv @("OA_ROLE_RUN_POLL_SECONDS") 30 1
    stale_seconds = Get-PositiveIntEnv @("OA_ROLE_RUN_STALE_SECONDS") 300 5
    timeout_seconds = Get-PositiveIntEnv @("OA_ROLE_RUN_TIMEOUT_SECONDS") 720 5
    log_dir = $logDir
  }
}

function Get-RoleRunLogPrefix {
  param(
    [string]$Id,
    [string]$RoleName,
    [string]$LogDir
  )
  $safeId = (($Id -replace "[^A-Za-z0-9_.-]+", "-").Trim("-"))
  $safeRole = (($RoleName -replace "[^A-Za-z0-9_.-]+", "-").Trim("-"))
  $stamp = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")
  return (Join-Path $LogDir "$stamp-$safeId-$safeRole")
}

function Get-FileByteCount {
  param([string[]]$Paths)
  $total = 0
  foreach ($path in $Paths) {
    if (Test-Path $path) {
      $item = Get-Item $path
      $total += [int64]$item.Length
    }
  }
  return $total
}

function Stop-MatchingOpenCodeRoleProcesses {
  param(
    [string]$Id,
    [string]$RoleName,
    [string]$Agent
  )
  $needleTitle = "oa $RoleName $Id"
  $processes = Get-CimInstance Win32_Process -Filter "Name = 'opencode.exe'" -ErrorAction SilentlyContinue | Where-Object {
    ($_.CommandLine -like "*$Id*" -and $_.CommandLine -like "*$Agent*") -or
    ($_.CommandLine -like "*$needleTitle*")
  }
  foreach ($process in $processes) {
    try {
      Stop-Process -Id $process.ProcessId -Force -ErrorAction Stop
    } catch {
      Write-Warning "Failed to stop opencode process $($process.ProcessId): $($_.Exception.Message)"
    }
  }
}

function Invoke-OpenCodeWithWatchdog {
  param(
    [string]$OpenCode,
    [string[]]$RunArgs,
    [string]$Id,
    [string]$RoleName,
    [string]$Agent,
    [object]$ModelConfig
  )

  $watchdog = Get-RoleRunWatchdogConfig
  New-Item -ItemType Directory -Force -Path $watchdog.log_dir | Out-Null
  $prefix = Get-RoleRunLogPrefix -Id $Id -RoleName $RoleName -LogDir $watchdog.log_dir
  $stdoutPath = "$prefix.stdout.log"
  $stderrPath = "$prefix.stderr.log"
  $metaPath = "$prefix.meta.json"

  [ordered]@{
    bead_id = $Id
    role = $RoleName
    agent = $Agent
    model_spec = $ModelConfig.model_spec
    thinking_variant = $ModelConfig.thinking_variant
    thinking_enabled = $ModelConfig.thinking_enabled
    started_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    poll_seconds = $watchdog.poll_seconds
    stale_seconds = $watchdog.stale_seconds
    timeout_seconds = $watchdog.timeout_seconds
    stdout = $stdoutPath
    stderr = $stderrPath
  } | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 $metaPath

  Write-Host "oa role run logs:"
  Write-Host "  meta:   $metaPath"
  Write-Host "  stdout: $stdoutPath"
  Write-Host "  stderr: $stderrPath"

  $job = Start-Job -Name "oa-$RoleName-$Id" -ScriptBlock {
    param(
      [string]$ChildOpenCode,
      [string[]]$ChildRunArgs,
      [string]$ChildStdout,
      [string]$ChildStderr
    )
    & $ChildOpenCode @ChildRunArgs > $ChildStdout 2> $ChildStderr
    $LASTEXITCODE
  } -ArgumentList $OpenCode, $RunArgs, $stdoutPath, $stderrPath

  $started = Get-Date
  $lastBytes = Get-FileByteCount @($stdoutPath, $stderrPath)
  $lastProgress = Get-Date
  $lastWarningAt = $null

  try {
    while ($job.State -eq "Running") {
      Start-Sleep -Seconds $watchdog.poll_seconds
      $elapsed = ((Get-Date) - $started).TotalSeconds
      $bytes = Get-FileByteCount @($stdoutPath, $stderrPath)
      if ($bytes -ne $lastBytes) {
        $lastBytes = $bytes
        $lastProgress = Get-Date
      }

      $silentSeconds = ((Get-Date) - $lastProgress).TotalSeconds
      if ($elapsed -ge $watchdog.stale_seconds -and $silentSeconds -ge $watchdog.stale_seconds) {
        if (-not $lastWarningAt -or ((Get-Date) - $lastWarningAt).TotalSeconds -ge $watchdog.stale_seconds) {
          Write-Warning "Role run has produced no log output for $([int]$silentSeconds)s (bead=$Id role=$RoleName). Logs: $metaPath"
          $lastWarningAt = Get-Date
        }
      }

      if ($elapsed -ge $watchdog.timeout_seconds) {
        Stop-Job -Job $job -ErrorAction SilentlyContinue
        Stop-MatchingOpenCodeRoleProcesses -Id $Id -RoleName $RoleName -Agent $Agent
        [ordered]@{
          bead_id = $Id
          role = $RoleName
          agent = $Agent
          timed_out = $true
          elapsed_seconds = [int]$elapsed
          timeout_seconds = $watchdog.timeout_seconds
          stopped_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
          stdout = $stdoutPath
          stderr = $stderrPath
        } | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 "$prefix.timeout.json"
        throw "Role run timed out after $([int]$elapsed)s (limit=$($watchdog.timeout_seconds)s). Stopped matching opencode processes. Logs: $metaPath"
      }
    }

    $received = @(Receive-Job -Job $job -ErrorAction SilentlyContinue)
    if ($job.State -eq "Failed") {
      $reason = $job.ChildJobs[0].JobStateInfo.Reason
      throw "Role run job failed: $reason. Logs: $metaPath"
    }
    $exit = 0
    if ($received.Count -gt 0) {
      $exit = [int]($received | Select-Object -Last 1)
    }
    $stdoutBytes = 0
    $stderrBytes = 0
    if (Test-Path $stdoutPath) {
      $stdoutBytes = (Get-Item $stdoutPath).Length
    }
    if (Test-Path $stderrPath) {
      $stderrBytes = (Get-Item $stderrPath).Length
    }

    [ordered]@{
      bead_id = $Id
      role = $RoleName
      agent = $Agent
      completed_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
      exit_code = $exit
      stdout_bytes = $stdoutBytes
      stderr_bytes = $stderrBytes
    } | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 "$prefix.result.json"
    return $exit
  } finally {
    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
  }
}

function Run-Role {
  param(
    [string]$Id,
    [string]$RoleName,
    [string[]]$ExtraPrompt
  )
  if (-not $Id) { throw "Missing bead id." }
  if (-not $RoleName) { throw "Missing role name." }

  # Canonicalize the role spelling BEFORE any downstream use of $RoleName
  # (ORCH-REQ-008 / socialhub-v8g.24.8). The canonical display name flows into
  # the prompt, BEADS_ACTOR, and the comment template; the configured agent slug
  # flows into opencode run. This makes display-name ("Workflow Engineer"),
  # dash-slug ("workflow-engineer"), and oa-agent-slug ("oa-workflow-engineer")
  # invocations resolve identically. FAIL-CLOSED: an unrecognized spelling --
  # including a quoting split that delivers only the first word of a
  # space-containing role -- throws here instead of silently running the wrong
  # agent and corrupting the bd comment author.
  $resolved = Resolve-Role $RoleName
  $RoleName = $resolved.display
  $agent = $resolved.agent

  $selfCheck = Test-WrapperSelf
  if ($selfCheck.wrapper_self_check -ne "ok") {
    throw "Wrapper self-check did not return ok. Aborting role invocation."
  }

  $repo = Get-RepoRoot
  $opencode = Resolve-Exe @("opencode.cmd", "opencode.exe", "opencode")
  if (-not $opencode) {
    throw "opencode was not found on PATH."
  }

  $modelConfig = Get-ActiveModelConfig -RoleName $RoleName
  Ensure-ActiveProviderKey $modelConfig

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

Do not write test, probe, placeholder, or scratch comments on real beads. Every comment must be a real formatted Markdown work record. Use only your role permissions.

MANDATORY PRE-WRITE COMMENT DISCIPLINE SELF-CHECK: Before posting any comment to a bead via bd comment, you MUST validate the comment text through the deterministic linter at .orchestrated-agents/bin/test-comment-check.ps1. The linter rejects probe comments (test probe, test line, hello world, lineA/lineB/lineC, line1/line2/line3, scratch text, placeholder text, formatting experiment), missing required Markdown structure (### Commentor: header, **Status:**, **Findings:**, **Required Next Action:**), short comments (< 200 chars), and sparse comments (<= 2 non-blank lines). Run it BEFORE piping the comment to bd comment -- only proceed if exit code is 0. If the linter rejects, revise the comment and re-run until it accepts. If a justified short comment is necessary, declare "claim pending verification: short comment justified per <reason>" in the Status field and post anyway. See .orchestrated-agents/workflows/bead-protocol.md Comment-Discipline Self-Check section for the full rule and invocation patterns. $extra
"@

  $oldActor = $env:BEADS_ACTOR
  $oldTarget = $env:OA_TARGET_BEAD
  $oldRole = $env:OA_ROLE_NAME
  $env:BEADS_ACTOR = $RoleName
  $env:OA_TARGET_BEAD = $Id
  $env:OA_ROLE_NAME = $RoleName
  $runArgs = @(
    "run",
    "--dir", $repo,
    "--agent", $agent,
    "--model", $modelConfig.model_spec,
    "--variant", $modelConfig.thinking_variant
  )
  if ($modelConfig.thinking_enabled) {
    $runArgs += "--thinking"
  }
  $runArgs += @(
    "--auto",
    "--title", "oa $RoleName $Id",
    $prompt
  )
  try {
    $exit = Invoke-OpenCodeWithWatchdog -OpenCode $opencode -RunArgs $runArgs -Id $Id -RoleName $RoleName -Agent $agent -ModelConfig $modelConfig
  } finally {
    $env:BEADS_ACTOR = $oldActor
    $env:OA_TARGET_BEAD = $oldTarget
    $env:OA_ROLE_NAME = $oldRole
  }

  if ($exit -ne 0) {
    exit $exit
  }
}

# Guard the main dispatch so the script can be dot-sourced by the regression
# test (.orchestrated-agents/bin/test-role-resolution.ps1) without executing a
# command. When dot-sourced, $MyInvocation.InvocationName is "."; when run
# (including via oa.cmd `powershell -File oa.ps1`), it is the script path/name.
# All functions above are available in both cases. ORCH-REQ-008.
if ($MyInvocation.InvocationName -ne '.') {
  switch ($Command.ToLowerInvariant()) {
    "help" { Show-Help }
    "status" { Show-Status }
    "key-setup" { Set-ProviderKey -ProviderName $BeadId }
    "key-clear" { Clear-ProviderKey -ProviderName $BeadId }
    "run" { Run-Role -Id $BeadId -RoleName $Role -ExtraPrompt $Rest }
    default {
      Show-Help
      throw "Unknown command: $Command"
    }
  }
}
