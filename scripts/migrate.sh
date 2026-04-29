#!/bin/bash

# ==============================================================================
# Mac to Windows Network Exfiltration Script (v2.0 - O(1) Refactor)
# Purpose: Safely migrate user files from macOS to Windows via SMB.
# Agentic Note: Refactored with Gemini 3.1 Pro to resolve O(n^2) network
# bottlenecks and implement single-pass, null-terminated filesystem traversal.
# ==============================================================================

# Configuration
SHARE_NAME="Mac_Migration"
MOUNT_POINT="/Volumes/$SHARE_NAME"
LOG_FILE=~/Desktop/Migration_Log_$(date +%s).txt

# Set up logging to output to both console and log file
exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================"
echo "  Mac to Windows Comprehensive Script   "
echo "  Version: 2.0 (Single-Pass O(1))       "
echo "  Log File: $LOG_FILE                   "
echo "========================================"

if [ ! -d "$MOUNT_POINT" ]; then
    echo "Error: The share does not appear to be mounted at $MOUNT_POINT."
    exit 1
fi

# Create target directories upfront
mkdir -p "$MOUNT_POINT/Photos" "$MOUNT_POINT/Videos" "$MOUNT_POINT/Audio"
mkdir -p "$MOUNT_POINT/Documents" "$MOUNT_POINT/Contacts" "$MOUNT_POINT/Other"

echo "Scanning /Users (excluding Library)... This may take a moment to index."

# ------------------------------------------------------------------------------
# Single-Pass Filesystem Traversal
# By using `-print0` and `read -d $'\0'`, we safely handle emojis, newlines, 
# and special characters in folder/file names. We only run `find` ONCE.
# ------------------------------------------------------------------------------
find /Users -type d -name 'Library' -prune -o -type f -print0 | while IFS= read -r -d $'\0' file; do
    
    filename=$(basename "$file")
    extension="${filename##*.}"
    
    # If the file has no extension or is hidden, skip it to save time
    if [[ "$filename" == .* ]] || [[ "$filename" == "$extension" ]]; then
        continue
    fi
    
    # Convert extension to lowercase for reliable matching
    ext_lower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
    
    category=""
    
    # Fast in-memory semantic categorization
    case "$ext_lower" in
        heic|heif|jpg|jpeg|png|gif|tiff|tif|raw|cr2|nef|arw|dng|bmp|svg) category="Photos" ;;
        mp4|mov|avi|mkv|wmv|flv|webm|m4v) category="Videos" ;;
        mp3|m4a|wav|flac|aac|ogg|wma) category="Audio" ;;
        pdf|doc|docx|txt|rtf|pages|numbers|key|xls|xlsx|ppt|pptx|csv|md) category="Documents" ;;
        vcf) category="Contacts" ;;
        zip|rar|7z|tar|gz) category="Other" ;;
        *) continue ;; # Skip unsupported file types
    esac
    
    dest_dir="$MOUNT_POINT/$category"
    dest_path="$dest_dir/$filename"
    
    # --------------------------------------------------------------------------
    # O(1) Collision Handler
    # Instead of checking network sequentially (name_1, name_2 ... name_3600),
    # we instantly append a randomized 4-character hex string if the file exists.
    # This prevents the script from freezing on app cache folders with thousands
    # of identically named files.
    # --------------------------------------------------------------------------
    if [ -f "$dest_path" ]; then
        name="${filename%.*}"
        rand_str=$(openssl rand -hex 2)
        dest_path="$dest_dir/${name}_${rand_str}.${extension}"
        
        # Unlikely secondary collision fallback
        while [ -f "$dest_path" ]; do
            rand_str=$(openssl rand -hex 3)
            dest_path="$dest_dir/${name}_${rand_str}.${extension}"
        done
        echo "[COLLISION AVOIDED] Renamed to ${name}_${rand_str}.${extension}"
    fi
    
    echo "Copying [$category]: $filename"
    cp "$file" "$dest_path"
done

# Copy the local log file to the SMB share for review
cp "$LOG_FILE" "$MOUNT_POINT/Other/Migration_Log_Final.txt"

echo "========================================"
echo "Migration script fully completed!"
echo "Log saved to: $MOUNT_POINT/Other/Migration_Log_Final.txt"
