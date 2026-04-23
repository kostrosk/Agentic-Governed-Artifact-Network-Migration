<#
.SYNOPSIS
    Cryptographic Deduplication Script for Windows Phase 3
.DESCRIPTION
    This script traverses the migrated data pool and uses SHA-256 cryptographic 
    hashing to identify true file duplicates regardless of filename. It was 
    designed iteratively with the Antigravity AI Agent (Gemini 3.1 Pro) to 
    establish mathematical certainty during the data governance phase.
#>

$TargetDirectory = "C:\Mac_Migration"

Write-Host "================================================"
Write-Host "    Phase 3: Cryptographic Deduplication Tool   "
Write-Host "================================================"
Write-Host "Scanning $TargetDirectory for identical files..."
Write-Host "Depending on file sizes, this may take a while."
Write-Host ""

# ------------------------------------------------------------------------------
# In-Memory Data Structure
# We use a hash table (dictionary) to store the SHA-256 hash as the Key, 
# and the FileInfo object as the Value. This allows O(1) constant-time 
# lookups when checking if a hash has been seen before.
# ------------------------------------------------------------------------------
$hashTable = @{}
$duplicateCount = 0
$freedSpace = 0

# Retrieve all files recursively
$files = Get-ChildItem -Path $TargetDirectory -File -Recurse
$totalFiles = $files.Count
Write-Host "Found $totalFiles files to analyze."
Write-Host ""

$i = 0
foreach ($file in $files) {
    $i++
    # Progress UI to keep the user informed during long hashing operations
    Write-Progress -Activity "Analyzing Files for Duplicates (SHA-256)" -Status "Processing file $i of $totalFiles: $($file.Name)" -PercentComplete (($i / $totalFiles) * 100)
    
    try {
        # ----------------------------------------------------------------------
        # Cryptographic Verification
        # By calculating the SHA-256 hash of the file contents, we guarantee 
        # that two files are identical at the binary level. This is vastly 
        # superior to checking filenames or file sizes, which can lead to 
        # catastrophic data loss if two different photos share the same size.
        # ----------------------------------------------------------------------
        $hash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
        
        if ($hashTable.ContainsKey($hash)) {
            $originalFile = $hashTable[$hash]
            Write-Host "[DELETING DUPLICATE] $($file.Name)"
            Write-Host "    -> Exact match of: $($originalFile.Name)"
            
            $freedSpace += $file.Length
            $duplicateCount++
            
            # Safely remove the identified duplicate to reclaim NVMe storage
            Remove-Item -Path $file.FullName -Force
        } else {
            # First time seeing this file content, add it to our dictionary
            $hashTable[$hash] = $file
        }
    } catch {
        Write-Host "[ERROR] Could not process $($file.FullName): $($_.Exception.Message)" -ForegroundColor Red
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

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
