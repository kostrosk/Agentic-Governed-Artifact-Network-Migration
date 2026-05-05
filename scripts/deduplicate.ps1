<#
.SYNOPSIS
    Cryptographic Deduplication Script for Windows Phase 3
.DESCRIPTION
    This script traverses the migrated data pool and uses SHA-256 cryptographic 
    hashing to identify true file duplicates regardless of filename.
    It implements an advanced selection logic to prefer keeping the cleanest filename
    (shorter names, no _1_105_c or similar copy suffixes) over duplicates.
#>
Start-Transcript -Path "C:\Mac_Migration\Dedupe_Log.txt" -Append
$TargetDirectory = "C:\Mac_Migration"

Write-Host "================================================"
Write-Host "    Phase 3: Cryptographic Deduplication Tool   "
Write-Host "================================================"
Write-Host "Scanning $TargetDirectory for identical files..."
Write-Host "Depending on file sizes, this may take a while."
Write-Host ""

$duplicateCount = 0
$freedSpace = 0

# Step 1: Retrieve all files and group by Length (size)
# We only need to hash files that have identical sizes to other files.
Write-Host "Finding files and grouping by size to optimize hashing..."
$files = Get-ChildItem -Path $TargetDirectory -File -Recurse
$totalFiles = $files.Count
Write-Host "Found $totalFiles files to analyze."

$groupedBySize = $files | Group-Object Length | Where-Object { $_.Count -gt 1 }
$filesToHash = $groupedBySize | Select-Object -ExpandProperty Group
$totalToHash = $filesToHash.Count

Write-Host "Found $totalToHash files with matching sizes that require cryptographic verification."
Write-Host ""

# Step 2: Hash those files and group by Hash
$hashTable = @{}
$i = 0

foreach ($file in $filesToHash) {
    $i++
    Write-Progress -Activity "Analyzing Files for Duplicates (SHA-256)" -Status "Hashing file $i of $totalToHash - $($file.Name)" -PercentComplete (($i / $totalToHash) * 100)
    
    try {
        $hash = (Get-FileHash -Path $file.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
        
        if ($null -ne $hash) {
            if (-not $hashTable.ContainsKey($hash)) {
                $hashTable[$hash] = @()
            }
            $hashTable[$hash] += $file
        }
    } catch {
        Write-Host "[ERROR] Could not process $($file.FullName): $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Step 3: Process the duplicate sets and apply selection logic
Write-Host "Evaluating duplicates and removing sub-optimal copies..."

foreach ($hashKey in $hashTable.Keys) {
    $fileGroup = $hashTable[$hashKey]
    
    if ($fileGroup.Count -gt 1) {
        # We have a set of exact duplicates. We need to score them to pick the "best" one.
        # A lower score is better.
        # 1. Base score is the length of the file name (shorter is better).
        # 2. Add penalty if it contains a common copy suffix like _1_105_c or (1).
        
        $scoredFiles = @()
        foreach ($f in $fileGroup) {
            $score = $f.Name.Length
            
            # Penalize filenames containing copy patterns like _x_y_c or _abcd or (1)
            # Mac Photos export suffixes like _1_105_c
            if ($f.Name -match "_\d+_\d+_c") { $score += 100 }
            elseif ($f.Name -match "\(\d+\)") { $score += 50 }
            elseif ($f.Name -match "_[a-f0-9]{4}\.") { $score += 20 }
            
            # Penalize longer paths slightly to prefer root-level or shallow folders
            $score += ($f.FullName.Length * 0.1)
            
            $scoredFiles += [PSCustomObject]@{
                File = $f
                Score = $score
            }
        }
        
        # Sort by score ascending (lowest score is best)
        $scoredFiles = $scoredFiles | Sort-Object Score
        
        $bestFile = $scoredFiles[0].File
        $duplicatesToRemove = $scoredFiles | Select-Object -Skip 1 | Select-Object -ExpandProperty File
        
        foreach ($dup in $duplicatesToRemove) {
            Write-Host "[DELETING DUPLICATE] $($dup.Name)"
            Write-Host "    -> Kept optimal copy: $($bestFile.Name)"
            
            $freedSpace += $dup.Length
            $duplicateCount++
            
            Remove-Item -Path $dup.FullName -Force
        }
    }
}

# Calculate bytes to Megabytes/Gigabytes for human readability
$freedMB = [Math]::Round($freedSpace / 1MB, 2)
$freedGB = [Math]::Round($freedSpace / 1GB, 2)

Write-Host ""
Write-Host "================================================"
Write-Host "            Deduplication Complete!             "
Write-Host "================================================"
Write-Host "Total Files Scanned : $totalFiles"
Write-Host "Duplicates Removed  : $duplicateCount"
if ($freedGB -gt 1) {
    Write-Host "Storage Space Freed : $freedGB GB"
} else {
    Write-Host "Storage Space Freed : $freedMB MB"
}
Write-Host "================================================"
Stop-Transcript

Add-Type -AssemblyName PresentationFramework
[System.Windows.MessageBox]::Show("Phase 3 Deduplication is 100% Complete! You can now review the logs at C:\Mac_Migration\Dedupe_Log.txt and restart the migration on your Mac.", "Deduplication Finished")
