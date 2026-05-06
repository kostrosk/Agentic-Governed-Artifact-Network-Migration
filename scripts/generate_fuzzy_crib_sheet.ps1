<#
.SYNOPSIS
    Generates a Fuzzy Deduplication Crib Sheet for Phase 4 of Mac Migration.
.DESCRIPTION
    Scans the C:\Mac_Migration directory for files with similar base names but 
    different suffixes (e.g. Apple Photos _1_105_c, or generic (1) copies).
    Groups them, ranks them by size and date, and outputs an interactive Markdown 
    file for human approval before deletion.
#>

$TargetDirectory = "C:\Mac_Migration"
$OutputFile = "C:\Users\koryk\.gemini\antigravity\scratch\Agentic-Governed-Artifact-Network-Migration\Fuzzy_Dedupe_Approval.md"

$ProgressFile = "C:\Users\koryk\.gemini\antigravity\scratch\Agentic-Governed-Artifact-Network-Migration\progress.md"

function Write-ProgressBar {
    param([string]$Phase, [int]$Current, [int]$Total)
    $percent = if ($Total -gt 0) { [Math]::Round(($Current / $Total) * 100) } else { 100 }
    $bars = [Math]::Floor($percent / 10)
    $progressStr = ("#" * $bars) + ("-" * (10 - $bars))
    $content = "# AI Task Progress`n`n**Current Phase:** $Phase`n**Progress:** [$progressStr] $percent% ($Current / $Total)"
    Set-Content -Path $ProgressFile -Value $content
}

Write-ProgressBar -Phase "Scanning Filesystem" -Current 0 -Total 100

$files = Get-ChildItem -Path $TargetDirectory -File -Recurse
$totalFiles = $files.Count

$groupedFiles = @{}
$i = 0
foreach ($f in $files) {
    $i++
    if ($i % 1000 -eq 0) { Write-ProgressBar -Phase "Grouping Files by BaseName" -Current $i -Total $totalFiles }
    
    $base = $f.BaseName.Trim()
    $base = $base -replace '_[a-f0-9]{4}$', ''
    $base = $base -replace '_\d+_\d+_[a-z]$', ''
    $base = $base -replace '\(\d+\)$', ''
    $base = $base.Trim()

    if (-not $groupedFiles.ContainsKey($base)) {
        $groupedFiles[$base] = [System.Collections.ArrayList]::new()
    }
    $null = $groupedFiles[$base].Add($f)
}

$keys = $groupedFiles.Keys
$totalKeys = $keys.Count
$k = 0
$fuzzyGroupsFound = 0

$sb = [System.Text.StringBuilder]::new()
$null = $sb.AppendLine("# Phase 4: Fuzzy Deduplication Crib Sheet")
$null = $sb.AppendLine()
$null = $sb.AppendLine("Review the following fuzzy duplicate groups. The AI has recommended which file to keep based on maximum file size (metadata) and recency.")
$null = $sb.AppendLine("If you disagree with a recommendation, simply move the Markdown link from the **DELETE** list to the **KEEP** list.")
$null = $sb.AppendLine("Once you have reviewed this document, run `execute_crib_sheet.ps1` to automatically delete everything under the DELETE headers.")
$null = $sb.AppendLine()
$null = $sb.AppendLine("---")
$null = $sb.AppendLine()

foreach ($key in $keys) {
    $k++
    if ($k % 100 -eq 0) { Write-ProgressBar -Phase "Evaluating Fuzzy Groups & Generating Crib Sheet" -Current $k -Total $totalKeys }
    
    $group = $groupedFiles[$key]
    
    if ($group.Count -gt 1) {
        $ranked = $group | Sort-Object -Property Length, LastWriteTime -Descending
        
        $keep = $ranked[0]
        $deletes = $ranked | Select-Object -Skip 1
        
        if ($deletes.Count -gt 0) {
            $fuzzyGroupsFound++
            $null = $sb.AppendLine("## Group: $key")
            $null = $sb.AppendLine()
            
            $keepSize = [Math]::Round($keep.Length / 1KB, 2)
            $keepDate = $keep.LastWriteTime.ToString("yyyy-MM-dd")
            $keepUrl = $keep.FullName -replace '\\', '/'
            $null = $sb.AppendLine("**✅ Recommended to KEEP:**")
            $null = $sb.AppendLine("- [$($keep.Name)](file:///$keepUrl) ($keepSize KB, $keepDate)")
            $null = $sb.AppendLine()
            
            $null = $sb.AppendLine("**❌ Recommended to DELETE:**")
            foreach ($del in $deletes) {
                $delSize = [Math]::Round($del.Length / 1KB, 2)
                $delDate = $del.LastWriteTime.ToString("yyyy-MM-dd")
                $delUrl = $del.FullName -replace '\\', '/'
                $null = $sb.AppendLine("- [$($del.Name)](file:///$delUrl) ($delSize KB, $delDate)")
            }
            $null = $sb.AppendLine()
            $null = $sb.AppendLine("---")
            $null = $sb.AppendLine()
        }
    }
}

if ($fuzzyGroupsFound -eq 0) {
    $null = $sb.AppendLine("No fuzzy duplicates found! Your directory is clean.")
}

Set-Content -Path $OutputFile -Value $sb.ToString() -Encoding UTF8

Write-ProgressBar -Phase "Complete! Open Fuzzy_Dedupe_Approval.md" -Current 100 -Total 100
Write-Host "Crib sheet generated at $OutputFile"
Write-Host "Found $fuzzyGroupsFound fuzzy duplicate groups."
