<#
.SYNOPSIS
    Executes the Fuzzy Deduplication Crib Sheet deletions.
.DESCRIPTION
    Parses the Fuzzy_Dedupe_Approval.md file, finds files listed under the 
    DELETE headers, and permanently deletes them to reclaim storage.
#>

$CribSheet = "C:\Users\koryk\.gemini\antigravity\scratch\Agentic-Governed-Artifact-Network-Migration\Fuzzy_Dedupe_Approval.md"
Add-Type -AssemblyName System.Web

if (-not (Test-Path $CribSheet)) {
    Write-Host "[ERROR] Crib sheet not found at $CribSheet" -ForegroundColor Red
    exit
}

$lines = Get-Content $CribSheet
$inDeleteSection = $false
$deletedCount = 0
$freedSpace = 0

Write-Host "================================================"
Write-Host "    Phase 4: Executing Fuzzy Deduplication      "
Write-Host "================================================"

foreach ($line in $lines) {
    if ($line -match 'Recommended to KEEP:\*\*') {
        $inDeleteSection = $false
    }
    elseif ($line -match 'Recommended to DELETE:\*\*') {
        $inDeleteSection = $true
    }
    elseif ($line -match '^## Group:') {
        $inDeleteSection = $false
    }
    elseif ($inDeleteSection -and $line -match '^- \[.*?\]\(file:///(.*)\) \(') {
        # Extract the file path from the markdown link
        $filePath = $matches[1]
        
        # Markdown URLs often use forward slashes, replace with backslashes for Windows
        $filePath = $filePath.Replace('/', '\')
        
        # Paths are literal (not URL encoded), so do not decode them
        
        if (Test-Path -LiteralPath $filePath) {
            $fileObj = Get-Item -LiteralPath $filePath
            $freedSpace += $fileObj.Length
            
            Write-Host "[DELETING] $($fileObj.Name)"
            Remove-Item -LiteralPath $filePath -Force
            $deletedCount++
        } else {
            Write-Host "[WARNING] File not found: $filePath" -ForegroundColor Yellow
        }
    }
}

$freedMB = [Math]::Round($freedSpace / 1MB, 2)

Write-Host ""
Write-Host "================================================"
Write-Host "         Fuzzy Deduplication Complete!          "
Write-Host "================================================"
Write-Host "Files Deleted : $deletedCount"
Write-Host "Space Freed   : $freedMB MB"
Write-Host "================================================"

Add-Type -AssemblyName PresentationFramework
[System.Windows.MessageBox]::Show("Phase 4 Fuzzy Deduplication is complete! $deletedCount files were deleted, freeing $freedMB MB.", "Cleanup Finished")
