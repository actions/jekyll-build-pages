#!/usr/bin/env pwsh
#Requires -Version 7.2

<#
.SYNOPSIS
Trigger the workflow that records the tests expected outputs, wait for its execution to finish,
then bring back those results locally.

.DESCRIPTION
This script is meant to run locally outside of Actions. It relies on `gh` and `git`.
#>

# Get the repository's path (ps1 extension on the script is required for PSScriptRoot to be available 🤦)
$repositoryPath = Resolve-Path (Join-Path $PSScriptRoot '..')

# Get the test_project's path
$testProjectsPath = Resolve-Path (Join-Path $PSScriptRoot '../test_projects')

#
# Utilities
#

# Run a command and validate it returned a 0 exit code
function Invoke-Command {
  param (
    [ScriptBlock] $Command
  )

  & $Command
  if ($LASTEXITCODE -ne 0) {
    Write-Error "Command failed: $Command"
    throw
  }
}

# Get the current git ref name
function Get-GitRef {
  $commitId = Invoke-Command { & git -C $repositoryPath rev-parse --abbrev-ref HEAD }
  $commitId.Trim()
}

# Create a temp folder and return its path
function New-TemporaryFolder {
  $path = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid())
  New-Item -ItemType 'Directory' -Path $path | Out-Null
  $path
}

#
# Main
#

# Init
Set-StrictMode -version 'Latest'
$ErrorActionPreference = 'Stop'

# Get git ref name
$ref = Get-GitRef

# Run the workflow
Write-Host 'Queue workflow'
$workflow = 'record.yml'
Invoke-Command { & gh workflow run $workflow --ref $ref | Out-Null }

# Wait for a few seconds for the workflow to get created
Write-Host 'Wait a few seconds...'
Start-Sleep -Seconds 5

# Lookup the run id (it is not perfect because of the APIs...)
Write-Host 'Lookup run id'
$runId = Invoke-Command { & gh run list --workflow $workflow --branch $ref --limit 1 --json databaseId --jq '.[].databaseId' }

# Wait for the workflow to finish
Write-Host "Wait for workflow $runId to complete"
Invoke-Command { & gh run watch $runId --exit-status }

# Download the artifacts in a temp folder
Write-Host 'Download artifacts'
$tempFolder = New-TemporaryFolder
Invoke-Command { & gh run download $runId --dir $tempFolder }

# Iterate over the test projects
Get-ChildItem -Path $testProjectsPath -Directory | ForEach-Object {
  # Construct the artifact path and make sure a matching artifact is found
  $artifactPath = Join-Path $tempFolder $_.BaseName
  if (Test-Path $artifactPath -PathType 'Container') {
    # Copy artifact to the expected output folder
    $destinationPath = Join-Path $testProjectsPath $_.BaseName '_expected'
    Copy-Item -Path (Join-Path $artifactPath '*') -Destination $destinationPath -Recurse -Force | Out-Null
  }

  # Ignore test project
  else {
    Write-Warning "Unable to find artifact for test project $($_.BaseName)"
  }
}
