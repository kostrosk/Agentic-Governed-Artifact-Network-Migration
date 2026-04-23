# Agentic-Governed-Artifact-Network-Migration

## 🚀 Objective
Architect and execute a secure, cross-platform data migration pipeline from a legacy 2015 MacBook Air (macOS) to a Lenovo ThinkPad T480 (Windows 11) over a local network (SMB). 

The ultimate goal of this project is to safely consolidate 1TB of personal artifacts, perform cryptographic deduplication (SHA-256) to ensure data integrity, securely wipe the legacy NVMe drive, and repurpose that bare-metal hardware into a Lenovo ThinkStation P620 workstation.

This project was built entirely through **Agentic Orchestration**—utilizing Google's **Gemini 3.1 Pro (High)** via the "Antigravity" agent architecture to navigate cross-OS protocol blockers, optimize O(n²) network bottlenecks, and establish a sovereign data governance framework.

---

## 🧠 AI Orchestration & The Prompt Engineering Process
To demonstrate my capability in leveraging Large Language Models (LLMs) for complex infrastructure engineering, I explicitly partnered with the Antigravity agent. The AI was not just a code generator; it was used as an active systems engineer to troubleshoot real-time network layer issues.

### Defining the Scope (The Prompt)
I established the initial scope with a multi-phase declarative prompt:
> *"1TB NVMe Network Migration & Consolidation Plan. The goal is to methodically migrate all personal files from the MacBook Air's 1TB NVMe to the T480's C: drive via a local network connection. Once safely migrated and deduplicated, the Mac's NVMe drive will be moved to the P620 and reformatted."*

I instructed the agent to sequence the execution:
1. **Phase 1: Target Preparation** (Windows SMB Share and Access Control Lists).
2. **Phase 2: Mac Exfiltration** (Bash script traversing the macOS filesystem and piping via SMB).
3. **Phase 3: Cryptographic Deduplication** (PowerShell script using SHA-256 to ensure data integrity).

### Agentic Troubleshooting & Problem Solving
During execution, we encountered two significant engineering hurdles that the AI agent helped me diagnose and resolve in real-time:

1. **The Windows 11 SMB Authentication Blocker:**
   Modern Windows 11 tightly integrates Microsoft Accounts and PINs (`Windows Hello`), which frequently desynchronizes NTLM password hashes and causes macOS SMB clients to fail authentication, even after a password reset. 
   * **The AI Solution:** I prompted the agent to investigate my network profiles. It analyzed the `ipconfig` and `Advanced Sharing Settings`, determined that insecure guest auth was blocked by Windows 11 policy, and automatically ran an elevated PowerShell script to provision a localized, air-gapped `mac_user` account with specific NTFS and Share-level Full Control permissions to bypass the Microsoft Account auth layer entirely.

2. **The O(n²) Network Traversal Bottleneck:**
   During the migration, the transfer velocity plummeted. I fed the AI the execution logs.
   * **The AI Solution:** The agent identified that an application cache had generated over 3,600 files with the exact same name (`5003.JPG`). My collision-handling loop was checking the network drive sequentially (`5003_1.JPG`, `5003_2.JPG`, etc.), resulting in an O(n²) degradation where the 3,600th file caused 3,600 synchronous network queries. The AI diagnosed this instantly, explaining the exact algorithmic bottleneck.

---

## 🛠️ The Architecture & Scripts

This repository contains the two primary scripts engineered for this pipeline. Both scripts were iteratively refined with the agent and represent strong Data Governance principles: **Zero Data Loss (Safe Collisions)** and **Mathematical Integrity (Cryptographic Hashing)**.

### 1. `scripts/migrate.sh` (The macOS Exfiltration Script)
A highly robust Bash script executed on the source macOS machine.
* **Intelligent Traversal:** Scans the entire `/Users` directory but actively prunes the `Library` folder to prevent the migration of useless system caches and application state files.
* **Broad Extension Coverage:** Specifically targets user-generated artifacts across dozens of extensions (RAW photography, iOS HEIC, Microsoft Office, Apple iWork, lossless audio, etc.).
* **Zero-Loss Collision Handling:** Ensures that identically named files across different macOS directories (e.g., `IMG_0001.JPG` in 'Desktop' and 'Pictures') are safely renamed during network transit without overwriting data.

### 2. `scripts/deduplicate.ps1` (The Windows Cryptographic Deduplication Script)
Because the collision handler aggressively preserves files, the resulting dataset inherently contains user-generated duplicates.
* **SHA-256 Hashing:** Instead of relying on brittle file names or timestamps, this PowerShell script calculates the true cryptographic SHA-256 hash of every single file.
* **Memory-Optimized Cleanup:** It maintains an in-memory hash table. If a hash collision occurs (meaning the bits are 100% identical), it safely purges the duplicate, reporting the exact storage space freed.

---

## 💻 Hardware End-State & Business Value
The culmination of this project results in the following state:
1. **Data Sovereignty:** 1TB of raw, unorganized artifacts successfully centralized, mathematically verified, and deduplicated onto a single Windows NVMe drive.
2. **Hardware Recycling:** The legacy 2015 MacBook Air is securely wiped (DoD 5220.22-M or equivalent NVMe secure erase).
3. **Infrastructure Expansion:** The freed 1TB NVMe drive is physically migrated into a high-performance Lenovo ThinkStation P620 to serve as a secondary data pool.

### Why this matters (For Hiring Managers & Recruiters)
This project is a micro-demonstration of enterprise-scale data engineering. It showcases my ability to:
* **Leverage cutting-edge LLMs (Gemini 3.1 Pro)** not just as a chatbot, but as an autonomous coding partner and infrastructure diagnostician.
* **Understand underlying Network Protocols (SMB, NTLM auth, NTFS permissions)** and how modern operating systems interact.
* **Prioritize Data Governance,** proving an understanding that moving data isn't just about `copy/paste`; it requires algorithmic collision handling and cryptographic verification.
* **Script across environments,** utilizing both UNIX/Bash and Windows/PowerShell fluidly to solve platform-specific problems.
