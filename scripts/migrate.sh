#!/bin/bash

# ==============================================================================
# Mac to Windows Network Exfiltration Script
# Purpose: Safely migrate user files from macOS to Windows via SMB.
# Agentic Note: Designed iteratively with Gemini 3.1 Pro to ensure zero data
# loss through robust collision handling and strategic directory pruning.
# ==============================================================================

# Configuration
SHARE_NAME="Mac_Migration"
MOUNT_POINT="/Volumes/$SHARE_NAME"

echo "========================================"
echo "  Mac to Windows Comprehensive Script   "
echo "========================================"

# Safety Check: Ensure the network drive is actively mounted
# This prevents the script from accidentally creating local folders on the Mac
# if the SMB connection dropped.
if [ ! -d "$MOUNT_POINT" ]; then
    echo "Error: The share does not appear to be mounted at $MOUNT_POINT."
    exit 1
fi

# ------------------------------------------------------------------------------
# Core Function: copy_files
# Arguments: 
#   $1 = Target Category Folder (e.g., 'Photos', 'Videos')
#   $@ = List of file extensions to search for
# ------------------------------------------------------------------------------
copy_files() {
    local category=$1
    local dest_dir="$MOUNT_POINT/$category"
    shift
    local extensions=("$@")
    
    # Ensure the destination directory exists on the Windows SMB share
    mkdir -p "$dest_dir"
    
    echo "========================================"
    echo "Scanning for $category files..."
    
    # Build a dynamic find command
    # CRITICAL: We explicitly prune (skip) the 'Library' directory.
    # macOS stores hundreds of thousands of hidden cache files, app icons, 
    # and background data in ~/Library. Skipping this prevents the migration 
    # of useless garbage and massively speeds up network traversal.
    local find_cmd="find /Users -type d -name 'Library' -prune -o -type f \( "
    
    # Loop through the provided extensions and build the query string
    for i in "${!extensions[@]}"; do
        if [ $i -gt 0 ]; then find_cmd+=" -o "; fi
        find_cmd+="-iname '*.${extensions[$i]}'"
    done
    find_cmd+=" \) -print"
    
    # Execute the find command and pipe the output to the while loop.
    # 2>/dev/null hides permission denied errors for system-level folders.
    eval "$find_cmd" 2>/dev/null | while read -r file; do
        filename=$(basename "$file")
        dest_path="$dest_dir/$filename"
        
        # ----------------------------------------------------------------------
        # Data Governance: Zero-Loss Collision Handling
        # If the destination already has a file with this name (e.g., from a 
        # different source folder), append a counter (IMG_0001_1.JPG).
        # Note: This is an O(n) check over the network. If there are 3,000 files 
        # with the exact same name, it will query the network 3,000 times.
        # ----------------------------------------------------------------------
        counter=1
        while [ -f "$dest_path" ]; do
            name="${filename%.*}"
            extension="${filename##*.}"
            if [ "$name" == "$filename" ]; then
                dest_path="$dest_dir/${name}_${counter}"
            else
                dest_path="$dest_dir/${name}_${counter}.${extension}"
            fi
            ((counter++))
        done
        
        # Execute the copy over the SMB network mount
        echo "Copying: $filename -> $dest_path"
        cp "$file" "$dest_path"
    done
}

echo "Starting comprehensive migration..."

# Execute the scans by semantic category
copy_files "Photos" "heic" "heif" "jpg" "jpeg" "png" "gif" "tiff" "tif" "raw" "cr2" "nef" "arw" "dng" "bmp" "svg"
copy_files "Videos" "mp4" "mov" "avi" "mkv" "wmv" "flv" "webm" "m4v"
copy_files "Audio" "mp3" "m4a" "wav" "flac" "aac" "ogg" "wma"
copy_files "Documents" "pdf" "doc" "docx" "txt" "rtf" "pages" "numbers" "key" "xls" "xlsx" "ppt" "pptx" "csv" "md"
copy_files "Contacts" "vcf"
copy_files "Other" "zip" "rar" "7z" "tar" "gz"

echo "========================================"
echo "Migration script fully completed!"
