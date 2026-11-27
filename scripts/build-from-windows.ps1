[CmdletBinding()]
param(
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_.-]{0,99}$')]
    [string]$RepositoryName = 'pulso-ios',
    [switch]$SkipDownload
)

# Run this in an extracted, standalone copy of the project.
# Creates a NEW PRIVATE repository. Never pushes to an existing repository.
$ErrorActionPreference = 'Stop'
$PulsoRoot = Split-Path -Parent $PSScriptRoot

function Run-PulsoCommand {
    param([string]$Program, [string[]]$CommandArguments)
    & $Program @CommandArguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Program failed (exit $LASTEXITCODE). See the command output above."
    }
}

function Read-PulsoCommand {
    param([string]$Program, [string[]]$CommandArguments)
    # Windows PowerShell 5.1 can wrap native stderr as ErrorRecord objects.
    # Expected non-zero exits are data here, not terminating PowerShell errors.
    $ErrorActionPreference = 'Continue'
    $CommandOutput = & $Program @CommandArguments 2>$null
    $CommandExitCode = $LASTEXITCODE
    return [PSCustomObject]@{
        ExitCode = $CommandExitCode
        Text = ($CommandOutput -join "`n")
    }
}

Push-Location $PulsoRoot
try {
    foreach ($Program in @('git', 'gh')) {
        if (-not (Get-Command $Program -ErrorAction SilentlyContinue)) {
            throw "Install '$Program' first. Instructions: docs/BUILD.md"
        }
    }
    if (-not (Test-Path 'Pulso.xcodeproj/project.pbxproj')) {
        throw 'Project is incomplete. Extract the full ZIP before running this helper.'
    }
    if (Test-Path '.git') {
        throw 'This folder is already a Git repository. Use an untouched extracted copy, or publish manually with the instructions in docs/BUILD.md.'
    }
    $ExistingParent = Read-PulsoCommand 'git' @('rev-parse', '--show-toplevel')
    if ($ExistingParent.ExitCode -eq 0) {
        throw 'Extract the project outside any existing Git repository, then run this helper again.'
    }

    $AuthStatus = Read-PulsoCommand 'gh' @('auth', 'status', '--hostname', 'github.com')
    if ($AuthStatus.ExitCode -ne 0) {
        Run-PulsoCommand 'gh' @('auth', 'login', '--hostname', 'github.com', '--git-protocol', 'https', '--web', '--scopes', 'workflow')
    }
    $OwnerResult = Read-PulsoCommand 'gh' @('api', 'user', '--jq', '.login')
    $Owner = $OwnerResult.Text.Trim()
    if ($OwnerResult.ExitCode -ne 0 -or -not $Owner) {
        throw 'Could not determine the signed-in GitHub account.'
    }
    $Repository = "$Owner/$RepositoryName"
    # Inspect the account repository names through a successful API response.
    # This never treats a network/auth failure as permission to create or overwrite.
    $ExistingNames = Read-PulsoCommand 'gh' @('api', '--paginate', 'user/repos?affiliation=owner&per_page=100', '--jq', '.[].full_name')
    if ($ExistingNames.ExitCode -ne 0) {
        throw 'Could not inspect existing repositories. Nothing has been published.'
    }
    if (@($ExistingNames.Text -split "`n") -contains $Repository) {
        throw "$Repository already exists. Choose a new -RepositoryName; this helper never modifies an existing repository."
    }

    $AuthorName = Read-PulsoCommand 'git' @('config', 'user.name')
    $AuthorEmail = Read-PulsoCommand 'git' @('config', 'user.email')
    if (-not $AuthorName.Text -or -not $AuthorEmail.Text) {
        throw 'Configure your own Git identity first: git config --global user.name "YOUR NAME" and git config --global user.email "YOUR EMAIL". Then run this helper again.'
    }
    Write-Host "Creating a new PRIVATE repository: $Repository" -ForegroundColor Cyan
    Run-PulsoCommand 'git' @('init', '-b', 'main')
    Run-PulsoCommand 'git' @('add', '--all')
    Run-PulsoCommand 'git' @('commit', '-m', 'Create Pulso native iOS 26 NFC reader')
    Run-PulsoCommand 'gh' @('auth', 'setup-git', '--hostname', 'github.com')
    Run-PulsoCommand 'gh' @('repo', 'create', $Repository, '--private', '--source', '.', '--remote', 'origin', '--push')

    Write-Host "Repository: https://github.com/$Repository" -ForegroundColor Green
    Write-Host "Builds: https://github.com/$Repository/actions" -ForegroundColor Green
    if ($SkipDownload) {
        Write-Host 'The push starts the workflow. Download its IPA artifact from Actions when it finishes.'
        return
    }

    $HeadResult = Read-PulsoCommand 'git' @('rev-parse', 'HEAD')
    if ($HeadResult.ExitCode -ne 0) { throw 'Could not determine the published commit.' }
    $HeadSHA = $HeadResult.Text.Trim()
    $BuildRun = $null
    for ($Attempt = 0; $Attempt -lt 12; $Attempt++) {
        $RunsResult = Read-PulsoCommand 'gh' @('run', 'list', '--repo', $Repository, '--commit', $HeadSHA, '--limit', '10', '--json', 'databaseId,workflowName')
        if ($RunsResult.ExitCode -eq 0) {
            # Explicit foreach works with array output from both PowerShell 5.1 and 7.
            foreach ($Candidate in (ConvertFrom-Json -InputObject $RunsResult.Text)) {
                if ($Candidate.workflowName -eq 'Compilar IPA - iOS 26') {
                    $BuildRun = $Candidate
                    break
                }
            }
            if ($null -ne $BuildRun) { break }
        }
        Start-Sleep -Seconds 5
    }
    if ($null -eq $BuildRun) {
        Write-Host 'GitHub has not listed the workflow yet. Open Actions to enable/run Compilar IPA - iOS 26.'
        return
    }
    $RunID = [string]$BuildRun.databaseId
    Run-PulsoCommand 'gh' @('run', 'watch', $RunID, '--repo', $Repository, '--exit-status')
    $DownloadDirectory = Join-Path $PulsoRoot "downloads/run-$RunID"
    Run-PulsoCommand 'gh' @('run', 'download', $RunID, '--repo', $Repository, '--pattern', 'Pulso-iOS26-unsigned-*', '--dir', $DownloadDirectory)
    Write-Host "Downloaded to: $DownloadDirectory" -ForegroundColor Green
    Write-Host 'The IPA is unsigned. Its final signature/profile must include the NFC TAG entitlement.'
}
finally {
    Pop-Location
}
