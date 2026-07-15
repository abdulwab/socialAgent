#requires -Version 5.1
<#
.SYNOPSIS
    Validate comment text against probe-comment patterns before posting to a bead.

.DESCRIPTION
    Implements the Comment-Discipline Self-Check described in
    .orchestrated-agents/workflows/bead-protocol.md Comment-Discipline
    Self-Check section.

    The script is a portable PowerShell 5.1 linter that exits non-zero
    if the supplied comment text matches any probe-comment pattern:

      * The required `### Commentor:` header is missing.
      * The required `**Status:**` field is missing.
      * The required `**Findings:**` field is missing.
      * The required `**Required Next Action:**` field is missing.
      * The text (after stripping backtick-delimited code spans and
        fences) contains an explicit probe phrase, matched
        case-insensitively as a whole word: `test probe`, `test
        line`, `hello world`, `lineA`, `lineB`, `lineC`, `scratch
        text`, `placeholder text`, `formatting experiment`.
      * The text contains a literal `lineN` probe line (`^line\d+$`).
      * The text contains a `Test line N` probe line
        (`^\s*test\s+line\s+\d+$`).
      * The comment is shorter than 200 characters.
      * The comment is sparse (two or fewer non-blank lines and
        shorter than 300 characters).

    The script also accepts a `-comment-id <id>` and a `-bead-id <id>`
    for logging context. Output is JSON on stdout. Exit codes:

      0  - valid comment; no probe patterns detected
      1  - invalid comment; one or more probe patterns detected
      2  - usage error (missing -text or -stdin)

    Portable across Windows PowerShell 5.1 and PowerShell Core.

.EXAMPLE
    PS> $text = Get-Content -Raw comment.md
    PS> .\.orchestrated-agents\bin\test-comment-check.ps1 -text $text -bead-id socialhub-v8g.22.44

.EXAMPLE
    PS> Get-Content -Raw .orchestrated-agents\logs\<bead-id>-<role>-<step>.md |
        .\.orchestrated-agents\bin\test-comment-check.ps1 -bead-id <id> -author "<RoleName>"

.EXAMPLE
    PS> "Test line 1" | .\.orchestrated-agents\bin\test-comment-check.ps1 -bead-id <id>
    # exits 1 with diagnostic JSON
#>
[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline = $true)]
    [string]$InputObject,

    [string]$Text,

    [switch]$Stdin,

    [Alias('bead-id')]
    [string]$BeadId,

    [Alias('comment-id')]
    [string]$CommentId,

    [string]$Author
)

begin {
    $ErrorActionPreference = "Stop"

    # Resolve script path robustly.
    $ScriptPath = $PSCommandPath
    if (-not $ScriptPath) {
        $ScriptPath = $MyInvocation.MyCommand.Path
    }
    if (-not $ScriptPath -and $PSScriptRoot) {
        $ScriptPath = Join-Path $PSScriptRoot "test-comment-check.ps1"
    }

    # Accumulate pipeline input across process blocks.
    $Script:AccumulatedText = New-Object System.Text.StringBuilder
    $Script:SawPipelineInput = $false

    function Write-Result {
        param(
            [bool]$Valid,
            [string[]]$Violations,
            [hashtable]$Context
        )

        $result = [ordered]@{
            valid             = $Valid
            violations        = $Violations
            checked_at        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            bead_id           = $Context.BeadId
            comment_id        = $Context.CommentId
            author            = $Context.Author
            script_version    = "1.0.0"
            script_path       = $ScriptPath
        }
        $result | ConvertTo-Json -Depth 4
    }
}

process {
    # PowerShell binds each pipeline object to $InputObject.
    if ($InputObject) {
        [void]$Script:AccumulatedText.AppendLine($InputObject)
        $Script:SawPipelineInput = $true
    }
}

end {
    # Resolve the final $Text value from one of three sources:
    #   1. -text <value> on the command line
    #   2. Pipeline input accumulated in $Script:AccumulatedText
    #   3. -stdin switch (read from [Console]::In.ReadToEnd())
    #
    # The pipeline accumulator MUST be checked before the -stdin
    # console branch: when both piped input and -stdin are present,
    # the piped data binds to $InputObject in the process block and
    # [Console]::In is already drained (returns empty). Checking the
    # accumulator first ensures the documented pipe-stdin path works.
    if ($Text) {
        # Already set from -text. Use as-is.
    } elseif ($Script:SawPipelineInput) {
        $Text = $Script:AccumulatedText.ToString()
        if ($Text.EndsWith("`r`n")) {
            $Text = $Text.Substring(0, $Text.Length - 2)
        } elseif ($Text.EndsWith("`n")) {
            $Text = $Text.Substring(0, $Text.Length - 1)
        }
    } elseif ($Stdin) {
        $Text = [Console]::In.ReadToEnd()
    }

    if ([string]::IsNullOrWhiteSpace($Text)) {
        Write-Result -Valid $false -Violations @("usage: -text or -stdin required (or pipe via Get-Content | test-comment-check.ps1)") -Context @{ BeadId = $BeadId; CommentId = $CommentId; Author = $Author }
        exit 2
    }

    $violations = New-Object System.Collections.Generic.List[string]

    # Probe-pattern 1: required Markdown structure
    if ($Text -notmatch '(?m)^###\s+Commentor:') {
        $violations.Add("missing `### Commentor:` header")
    }
    if ($Text -notmatch '(?m)^\*\*Status:\*\*') {
        $violations.Add("missing `**Status:**` field")
    }
    if ($Text -notmatch '(?m)^\*\*Findings:\*\*') {
        $violations.Add("missing `**Findings:**` field")
    }
    if ($Text -notmatch '(?m)^\*\*Required Next Action:\*\*') {
        $violations.Add("missing `**Required Next Action:**` field")
    }

    # Strip out backtick-delimited content (code spans `...` and code
    # fences ```...```) before checking for probe phrases. This exempts
    # legitimate documentation comments that reference probe patterns as
    # literal examples inside backticks (e.g., "the probe phrase `test
    # probe` appears in a table"). Probe-comment violations are NEVER
    # inside backticks; they are always raw prose.
    $TextUnquoted = [regex]::Replace($Text, '```[\s\S]*?```', ' ')
    $TextUnquoted = [regex]::Replace($TextUnquoted, '``[^`\n]+``', ' ')
    $TextUnquoted = [regex]::Replace($TextUnquoted, '`[^`\n]+`', ' ')

    # Probe-pattern 2: explicit probe phrases (case-insensitive whole-word)
    $probePhrases = @(
        'test probe',
        'test line',
        'hello world',
        'lineA',
        'lineB',
        'lineC',
        'scratch text',
        'placeholder text',
        'formatting experiment'
    )

    foreach ($phrase in $probePhrases) {
        if ($TextUnquoted -match "(?i)\b$([regex]::Escape($phrase))\b") {
            $violations.Add("contains probe phrase: '$phrase'")
        }
    }

    # Probe-pattern 3: line1/line2/line3 literal lines (only on the
    # stripped text so a documentation comment with a regex example
    # line like "match ^line\d+$" is not flagged)
    if ($TextUnquoted -match '(?m)^line\d+\s*$') {
        $violations.Add("contains literal `lineN` probe line")
    }

    # Probe-pattern 4: "Test line 1" / "Test line 2" / "Test line 3" patterns
    if ($TextUnquoted -match '(?im)^\s*test\s+line\s+\d+\s*$') {
        $violations.Add("contains `Test line N` probe pattern")
    }

    # Probe-pattern 5: very short comments without required structure.
    if ($Text.Length -lt 200) {
        $violations.Add("comment is shorter than 200 chars (length=$($Text.Length)); insufficient for a meaningful Markdown work record")
    }

    # Probe-pattern 6: comment is a single short line with no Markdown structure
    $nonBlankLines = ($Text -split "`r?`n" | Where-Object { $_.Trim() -ne '' })
    if ($nonBlankLines.Count -le 2 -and $Text.Length -lt 300) {
        $violations.Add("comment has <= 2 non-blank lines; insufficient for a meaningful Markdown work record")
    }

    $valid = ($violations.Count -eq 0)

    $context = @{
        BeadId    = $BeadId
        CommentId = $CommentId
        Author    = $Author
    }

    Write-Result -Valid $valid -Violations $violations -Context $context

    if ($valid) {
        exit 0
    } else {
        exit 1
    }
}