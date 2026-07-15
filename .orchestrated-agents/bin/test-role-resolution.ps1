#requires -Version 5.1
<#
.SYNOPSIS
    Regression test for Resolve-Role canonicalization (ORCH-REQ-008 /
    socialhub-v8g.24.8).

.DESCRIPTION
    Dot-sources .orchestrated-agents/bin/oa.ps1 to load the role-resolution
    functions, then asserts:

      * POSITIVE: for every configured role, all three accepted spellings
        (canonical display name, dash-slug, oa-agent-slug) resolve to the
        correct canonical display name AND the correct oa-* agent slug.
      * CONSISTENCY: Resolve-Role(display).agent equals Get-AgentName(display)
        for every role, so the two resolution paths never disagree.
      * ALIAS: documented aliases (research -> Researcher,
        security/privacy reviewer -> Security Privacy Reviewer) resolve.
      * REGISTRY: every catalog agentSlug exists in opencode.json's agent
        block. This is the genuinely independent cross-check -- the catalog
        (oa.ps1) is validated against a separate declaration (opencode.json)
        so a typo in agentSlug is caught by this test, not just by the
        runtime Test-WrapperSelf pre-flight.
      * NEGATIVE: unrecognized spellings -- including the ORCH-REQ-008 bug class
        of a quoting split that delivers only the first word of a
        space-containing role -- MUST fail-closed (throw). This includes a
        bogus oa-* slug passed to Get-AgentName directly (Needs Fix 4).

    This is the canonical detector for the regression QA Strategist must
    verify in the bead-protocol acceptance gate. It exercises the 10
    space-containing roles explicitly (AC4) plus the 3 single-word roles.

    COVERAGE BOUNDARY (Needs Fix 2, per Adversarial Reviewer):
      This test covers ONLY role resolution (Resolve-Role, Get-AgentName,
      Get-RoleCatalog, Get-RoleSpellingKey, and the opencode.json agent
      registry cross-check). It does NOT cover and provides zero evidence
      for the provider/model/key surface that shares the same oa.ps1 file
      (Get-ActiveModelConfig, Ensure-ActiveProviderKey,
      Normalize-ProviderName, Run-Role model-arg construction, the
      key-setup/key-clear dispatch). A green run here is evidence that role
      resolution is sound, NOT that all of oa.ps1 is sound.

    Exit codes:
      0 - all assertions passed
      1 - one or more assertions failed

    Portable across Windows PowerShell 5.1 and PowerShell Core. Does not
    require git, bd, or network access -- it reads opencode.json relative to
    the test file location ($PSScriptRoot) and tests in-process resolution.

.EXAMPLE
    PS> .\.orchestrated-agents\bin\test-role-resolution.ps1
    # prints a JSON summary; exit code 0 on success.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$script = Join-Path $PSScriptRoot "oa.ps1"
if (-not (Test-Path $script)) {
    throw "oa.ps1 not found at $script"
}

# Dot-source the wrapper. The main dispatch in oa.ps1 is guarded against
# dot-source execution ($MyInvocation.InvocationName -ne '.'), so only the
# function definitions are loaded.
. $script

$pass = 0
$fail = 0
$failures = New-Object System.Collections.Generic.List[hashtable]

function Register-Result {
    param(
        [string]$Category,
        [string]$Spelling,
        [string]$ExpectedDisplay,
        [string]$ExpectedAgent,
        [string]$GotDisplay,
        [string]$GotAgent,
        [bool]$Threw,
        [bool]$Ok
    )
    if ($Ok) {
        $script:pass++
    } else {
        $script:fail++
        $script:failures.Add(@{
            category        = $Category
            spelling        = $Spelling
            expected_display = $ExpectedDisplay
            expected_agent  = $ExpectedAgent
            got_display     = $GotDisplay
            got_agent       = $GotAgent
            threw           = $Threw
        }) | Out-Null
    }
}

# ---------------------------------------------------------------------------
# POSITIVE: every role, all three sanctioned spellings.
# ---------------------------------------------------------------------------
foreach ($entry in (Get-RoleCatalog)) {
    $spellings = @(
        @{ spelling = $entry.display; label = "display" },
        @{ spelling = $entry.dashSlug; label = "dash-slug" },
        @{ spelling = $entry.agentSlug; label = "agent-slug" }
    )
    foreach ($s in $spellings) {
        try {
            $r = Resolve-Role $s.spelling
            $ok = ($r.display -eq $entry.display) -and ($r.agent -eq $entry.agentSlug)
            Register-Result -Category "positive-$($s.label)" -Spelling $s.spelling `
                -ExpectedDisplay $entry.display -ExpectedAgent $entry.agentSlug `
                -GotDisplay $r.display -GotAgent $r.agent -Threw $false -Ok $ok
        } catch {
            Register-Result -Category "positive-$($s.label)" -Spelling $s.spelling `
                -ExpectedDisplay $entry.display -ExpectedAgent $entry.agentSlug `
                -GotDisplay "(threw)" -GotAgent "(threw)" -Threw $true -Ok $false
        }
    }
}

# ---------------------------------------------------------------------------
# CONSISTENCY: Resolve-Role and Get-AgentName must return the same agent for
# every role's canonical display name. NOTE: both resolve from the same
# catalog, so this confirms the two code paths agree on the catalog but is NOT
# an independent validation. The independent check (catalog vs opencode.json)
# is the REGISTRY section below.
# ---------------------------------------------------------------------------
foreach ($entry in (Get-RoleCatalog)) {
    try {
        $agentViaResolve = (Resolve-Role $entry.display).agent
        $agentViaMap = Get-AgentName $entry.display
        $ok = ($agentViaResolve -eq $entry.agentSlug) -and ($agentViaMap -eq $entry.agentSlug)
        Register-Result -Category "consistency" -Spelling $entry.display `
            -ExpectedDisplay $entry.display -ExpectedAgent $entry.agentSlug `
            -GotDisplay $entry.display -GotAgent "resolve=$agentViaResolve map=$agentViaMap" `
            -Threw $false -Ok $ok
    } catch {
        Register-Result -Category "consistency" -Spelling $entry.display `
            -ExpectedDisplay $entry.display -ExpectedAgent $entry.agentSlug `
            -GotDisplay $entry.display -GotAgent "(threw)" -Threw $true -Ok $false
    }
}

# ---------------------------------------------------------------------------
# ALIAS: documented aliases resolve to the right canonical role.
# ---------------------------------------------------------------------------
$aliasCases = @(
    @{ spelling = "research";                expectDisplay = "Researcher" },
    @{ spelling = "Research";                expectDisplay = "Researcher" },
    @{ spelling = "security/privacy reviewer"; expectDisplay = "Security Privacy Reviewer" }
)
foreach ($c in $aliasCases) {
    try {
        $r = Resolve-Role $c.spelling
        $ok = ($r.display -eq $c.expectDisplay)
        Register-Result -Category "alias" -Spelling $c.spelling `
            -ExpectedDisplay $c.expectDisplay -ExpectedAgent ($r.agent) `
            -GotDisplay $r.display -GotAgent $r.agent -Threw $false -Ok $ok
    } catch {
        Register-Result -Category "alias" -Spelling $c.spelling `
            -ExpectedDisplay $c.expectDisplay -ExpectedAgent "?" `
            -GotDisplay "(threw)" -GotAgent "(threw)" -Threw $true -Ok $false
    }
}

# ---------------------------------------------------------------------------
# REGISTRY (independent cross-check, Needs Fix 3): every catalog agentSlug
# must exist in opencode.json's agent block. This validates the role catalog
# (oa.ps1) against a SEPARATE declaration (opencode.json), so a typo in
# agentSlug that a catalog-vs-catalog check could never catch is detected
# here. This is the genuinely independent validation the Adversarial Reviewer
# requested; it cannot live inside Resolve-Role (which reads only the catalog)
# without coupling that pure resolver to the filesystem.
# ---------------------------------------------------------------------------
$registryChecked = $false
$registryPath = (Join-Path $PSScriptRoot "..\..\opencode.json")
if (-not (Test-Path $registryPath)) {
    # Resolve relative ".." to an absolute path for the error message.
    $registryPath = (Resolve-Path $registryPath -ErrorAction SilentlyContinue).Path
}
if ($registryPath -and (Test-Path $registryPath)) {
    $registryChecked = $true
    $config = Get-Content -Raw $registryPath | ConvertFrom-Json
    $agentNames = @($config.agent.PSObject.Properties.Name)
    foreach ($entry in (Get-RoleCatalog)) {
        $found = ($agentNames -contains $entry.agentSlug)
        Register-Result -Category "registry" -Spelling $entry.agentSlug `
            -ExpectedDisplay $entry.display -ExpectedAgent $entry.agentSlug `
            -GotDisplay $entry.display -GotAgent $(if ($found) { $entry.agentSlug } else { "NOT IN opencode.json" }) `
            -Threw $false -Ok $found
    }
} else {
    # opencode.json not found -- the registry cross-check is skipped. This is
    # recorded in the summary so QA can detect when the independent check did
    # not actually run (e.g., a stripped test environment).
    $registryChecked = $false
}

# ---------------------------------------------------------------------------
# NEGATIVE: unrecognized spellings MUST fail-closed.
# This includes the ORCH-REQ-008 bug class: a quoting split that delivers only
# the first word of a space-containing role.
# ---------------------------------------------------------------------------
$negativeCases = @(
    "Workflow",            # truncated first word of "Workflow Engineer"
    "Maker",               # truncated first word of "Maker Engineer"
    "Adversarial",         # truncated first word of "Adversarial Reviewer"
    "engineer",            # bare second word
    "foobar",              # garbage
    "process engineer",    # legacy role name removed by ORCH-REQ-004 rename
    "oa-",                 # bare prefix
    "research-engineer",   # plausible-looking but not a configured role
    "qa",                  # truncated
    "sre reviewer"         # truncated/wrong
)
foreach ($sp in $negativeCases) {
    $threw = $false
    try {
        $null = Resolve-Role $sp
    } catch {
        $threw = $true
    }
    # OK iff it threw (fail-closed).
    Register-Result -Category "negative" -Spelling $sp `
        -ExpectedDisplay "(throw)" -ExpectedAgent "(throw)" `
        -GotDisplay $(if ($threw) { "(threw)" } else { "(did-not-throw)" }) `
        -GotAgent $(if ($threw) { "(threw)" } else { "(did-not-throw)" }) `
        -Threw $threw -Ok $threw
}

# Empty / whitespace MUST throw (covered by Resolve-Role guard).
foreach ($sp in @("", "   ", "`t")) {
    $threw = $false
    try {
        $null = Resolve-Role $sp
    } catch {
        $threw = $true
    }
    Register-Result -Category "negative-empty" -Spelling ($sp | ForEach-Object { if ($_ -eq "") { "<empty>" } else { "<whitespace>" } }) `
        -ExpectedDisplay "(throw)" -ExpectedAgent "(throw)" `
        -GotDisplay $(if ($threw) { "(threw)" } else { "(did-not-throw)" }) `
        -GotAgent $(if ($threw) { "(threw)" } else { "(did-not-throw)" }) `
        -Threw $threw -Ok $threw
}

# ---------------------------------------------------------------------------
# NEGATIVE Get-AgentName (Needs Fix 4): a bogus oa-* slug passed directly to
# Get-AgentName MUST throw (fail-closed). The old oa-prefix passthrough
# returned ANY oa-prefixed string as-is; that silent accept is now closed.
# A VALID oa-* slug still resolves through the catalog loop.
# ---------------------------------------------------------------------------
# Valid oa-* slug should still resolve (positive control for the loop path).
$validOaThrew = $false
try {
    $validAgent = Get-AgentName "oa-workflow-engineer"
} catch {
    $validOaThrew = $true
}
$validOk = (-not $validOaThrew) -and ($validAgent -eq "oa-workflow-engineer")
Register-Result -Category "getagentname-valid-oa" -Spelling "oa-workflow-engineer" `
    -ExpectedDisplay "(loop match)" -ExpectedAgent "oa-workflow-engineer" `
    -GotDisplay "(loop)" -GotAgent $(if ($validOaThrew) { "(threw)" } else { $validAgent }) `
    -Threw $validOaThrew -Ok $validOk

# Bogus oa-* slug MUST throw (the Needs Fix 4 regression case).
$bogusOaThrew = $false
try {
    $null = Get-AgentName "oa-anything"
} catch {
    $bogusOaThrew = $true
}
Register-Result -Category "getagentname-bogus-oa" -Spelling "oa-anything" `
    -ExpectedDisplay "(throw)" -ExpectedAgent "(throw)" `
    -GotDisplay $(if ($bogusOaThrew) { "(threw)" } else { "(did-not-throw)" }) `
    -GotAgent $(if ($bogusOaThrew) { "(threw)" } else { "(did-not-throw)" }) `
    -Threw $bogusOaThrew -Ok $bogusOaThrew

# ---------------------------------------------------------------------------
# Summary.
# ---------------------------------------------------------------------------
$roleCount = @(Get-RoleCatalog).Count
$spaceRoleCount = (@(Get-RoleCatalog) | Where-Object { $_.display -match "\s" }).Count

$summary = [ordered]@{
    test              = "test-role-resolution"
    bead              = "socialhub-v8g.24.8"
    requirement       = "ORCH-REQ-008"
    checked_at        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    configured_roles  = $roleCount
    space_roles       = $spaceRoleCount
    registry_checked  = $registryChecked
    coverage_boundary = "Role resolution ONLY (Resolve-Role, Get-AgentName, catalog, opencode.json registry cross-check). Does NOT cover provider/model/key surface in oa.ps1 (Get-ActiveModelConfig, Ensure-ActiveProviderKey, Normalize-ProviderName, Run-Role model-arg construction, key-setup/key-clear). A green run is evidence of role resolution, not of all of oa.ps1."
    pass              = $pass
    fail              = $fail
    total             = ($pass + $fail)
    failures          = @($failures)
}

$summary | ConvertTo-Json -Depth 5

if ($fail -gt 0) {
    exit 1
} else {
    exit 0
}
