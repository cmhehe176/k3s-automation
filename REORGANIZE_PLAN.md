# 📋 Documentation Reorganization Plan

## Current State (Duplicated Content)

1. **COMPLETE_GUIDE.md** (518 lines) - Comprehensive guide covering everything
2. **docs/guides/deployment.md** (964 lines) - Detailed deployment guide
3. **docs/guides/add-nodes.md** (157 lines) - Node management
4. **README.md** (241 lines) - Project overview

## Problem: Overlapping Content

- COMPLETE_GUIDE.md duplicates much of deployment.md
- deployment.md has very detailed steps that overlap with scripts
- Multiple "getting started" sections

## Proposed Structure (No Duplication)

### Keep as Single Source of Truth:

**README.md** (Root) - Entry point
- Project overview
- Quick start (3-5 commands)
- Link to complete guide
- Repository structure

**COMPLETE_GUIDE.md** (Root) - Complete reference
- Full deployment walkthrough
- All scripts usage
- Troubleshooting
- Pod scheduling & load balancing
- Everything in one place

**docs/** - Specialized topics only
- **guides/operations.md** - Day-2 operations (backup, upgrade, monitoring)
- **operations/security.md** - Security hardening
- **operations/requirements.md** - System requirements
- **reference/inventory.md** - Inventory configuration
- **reference/troubleshooting.md** - Extended troubleshooting

**ansible/scripts/README.md** - Scripts quick reference

## Action Plan

1. Keep COMPLETE_GUIDE.md as-is (comprehensive, self-contained)
2. Slim down README.md to quick overview only
3. Remove docs/guides/deployment.md (duplicates COMPLETE_GUIDE.md)
4. Remove docs/guides/add-nodes.md (covered in COMPLETE_GUIDE.md)
5. Keep specialized docs (security, requirements, reference)
6. Update docs/README.md index

