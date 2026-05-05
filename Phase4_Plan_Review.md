# Phase 4 Plan Review: Heuristic "Fuzzy" Deduplication

This document outlines the proposed strategy for handling Apple Photos exports (e.g., `_1_105_c`, `_4_5005_c`) and other modified files that cannot be processed by exact-byte cryptographic deduplication.

Please review this plan. Once approved, I will merge this into the main implementation plan and begin execution.

## The Problem
Apple Photos exports multiple versions of the same file:
- The base file (e.g. `000CA262-F5F6-4CAA-A5F1-3373D6A8E63B.jpeg`) is typically the full-resolution original, often around 1.5MB.
- The `_1_105_c` version is an internal modified copy, often much smaller (e.g. 180KB).
- The `_4_5005_c` version is a tiny thumbnail, often around 40KB.

Because these files have completely different byte sizes and metadata, the Cryptographic Hash Deduplication (Phase 3) safely ignores them.

## Proposed Solution: Safe Isolation Strategy
We will create a new script: `scripts/isolate_fuzzy_duplicates.ps1`

### 1. Similarity Grouping
The script will parse the entire `C:\Mac_Migration` directory and group files by their "base name". 
It will actively look for and strip:
- Apple UUID export suffixes (`_1_105_c`, `_4_5005_c`).
- Generic copy suffixes (`(1)`, `(2)`).
- Migration collision suffixes (`_a4b9`).

### 2. Candidate Evaluation
For each group of similar files found, it will evaluate them to identify the "best" candidate based on:
- **Most Metadata / Resolution:** The file with the largest file size (`Length`).
- **Most Recent:** The file with the newest `LastWriteTime`.

### 3. Automated Scoring & Crib Sheet Generation (No Immediate Deletion)
Instead of moving files and making you manually dig through folders, the script will mathematically score the files (preferring largest size/most metadata and shortest name). It will then generate an interactive **"Crib Sheet"** (a Markdown file) directly in your repository (`Fuzzy_Dedupe_Approval.md`).

This Crib Sheet will contain clickable links to every file, organized by group, with explicit recommendations:

```markdown
## Group: 000CA262-F5F6-4CAA-A5F1-3373D6A8E63B

**✅ Recommended to KEEP:**
- [000CA262-F5F6... .jpeg](file:///C:/Mac_Migration/.../000CA262-F5F6-4CAA-A5F1-3373D6A8E63B.jpeg) (1.4 MB, 5/4/2026) 

**❌ Recommended to DELETE:**
- [000CA262-F5F6..._1_105_c.jpeg](file:///C:/Mac_Migration/.../000CA262-F5F6-4CAA-A5F1-3373D6A8E63B_1_105_c.jpeg) (184 KB, 4/30/2026)
- [000CA262-F5F6..._4_5005_c.jpeg](file:///C:/Mac_Migration/.../000CA262-F5F6-4CAA-A5F1-3373D6A8E63B_4_5005_c.jpeg) (42 KB, 5/2/2026)
```

### 4. Human-in-the-Loop Execution
You can open this Crib Sheet in your IDE. Because the links are clickable, you can instantly preview any suspect image without flipping through windows. 
- In 99% of cases, the AI's recommendation will be perfect.
- In rare cases where you disagree, you simply cut/paste the file link from the `DELETE` list to the `KEEP` list.

We will then run a secondary execution script (`execute_crib_sheet.ps1`) that parses this exact Markdown file, reads whatever you left under the `DELETE` headers, and automatically deletes them in bulk.

## Approval Required
Does this interactive Crib Sheet approach solve the babysitting problem? If approved, I will build the analysis script and generate the crib sheet for you.
