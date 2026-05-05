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

Write-Host "Scanning $TargetDirectory for fuzzy duplicates..."

$files = Get-ChildItem -Path $TargetDirectory -File -Recurse

# Grouping mechanism
$groupedFiles = @{}

foreach ($f in $files) {
    $base = $f.BaseName.Trim()
    
    # Strip Mac Migration collision suffixes (e.g. _a4b9)
    $base = $base -replace '_[a-f0-9]{4}$', ''
    
    # Strip Apple Photos export suffixes (e.g. _1_105_c, _4_5005_c)
    $base = $base -replace '_\d+_\d+_[a-z]$', ''
    
    # Strip generic Windows copy suffixes (e.g. (1), (2))
    $base = $base -replace '\(\d+\)$', ''
    
    $base = $base.Trim()

    # Sometimes files have identical names but different extensions (e.g. IMG.HEIC and IMG.JPG)
    # We should group them if they are the same base name.
    
    if (-not $groupedFiles.ContainsKey($base)) {
        $groupedFiles[$base] = @()
    }
    $groupedFiles[$base] += $f
}

Write-Host "Evaluating groups..."

# Generate Markdown content
$mdContent = @(
    "# Phase 4: Fuzzy Deduplication Crib Sheet",
    "",
    "Review the following fuzzy duplicate groups. The AI has recommended which file to keep based on maximum file size (metadata) and recency.",
    "If you disagree with a recommendation, simply move the Markdown link from the **DELETE** list to the **KEEP** list.",
    "Once you have reviewed this document, run `execute_crib_sheet.ps1` to automatically delete everything under the DELETE headers.",
    "",
    "---",
    ""
)

$fuzzyGroupsFound = 0

foreach ($key in $groupedFiles.Keys) {
    $group = $groupedFiles[$key]
    
    if ($group.Count -gt 1) {
        # Check if they are actually the exact same file object (edge case), or different
        # Let's rank them. Largest file size first, then newest LastWriteTime.
        $ranked = $group | Sort-Object -Property Length, LastWriteTime -Descending
        
        $keep = $ranked[0]
        $deletes = $ranked | Select-Object -Skip 1
        
        # Only list if there is at least one delete
        if ($deletes.Count -gt 0) {
            $fuzzyGroupsFound++
            $mdContent += "## Group: $key"
            $mdContent += ""
            
            $keepSize = [Math]::Round($keep.Length / 1KB, 2)
            $keepDate = $keep.LastWriteTime.ToString("yyyy-MM-dd")
            $mdContent += "**✅ Recommended to KEEP:**"
            $mdContent += "- [$($keep.Name)](file:///$($keep.FullName.Replace('\', '/')))` ($keepSize KB, $keepDate)"
            $mdContent += ""
            
            $mdContent += "**❌ Recommended to DELETE:**"
            foreach ($del in $deletes) {
                $delSize = [Math]::Round($del.Length / 1KB, 2)
                $delDate = $del.LastWriteTime.ToString("yyyy-MM-dd")
                $mdContent += "- [$($del.Name)](file:///$($del.FullName.Replace('\', '/')))` ($delSize KB, $delDate)"
            }
            $mdContent += ""
            $mdContent += "---"
            $mdContent += ""
        }
    }
}

if ($fuzzyGroupsFound -eq 0) {
    $mdContent += "No fuzzy duplicates found! Your directory is clean."
}

$mdContent | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host "Crib sheet generated at $OutputFile"
Write-Host "Found $fuzzyGroupsFound fuzzy duplicate groups."
