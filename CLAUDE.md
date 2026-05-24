# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Tools and scripts for freeing up disk space on macOS (Darwin). Targets caches, build artifacts, logs, downloads, and other reclaimable junk on the user's Mac.

## Project metadata

- **GitHub profile:** https://github.com/sososaity

## Critical safety rules

**Never delete the user's work or system files.** When in doubt, list candidates and confirm before deleting.

- **Never** touch macOS system paths: `/System`, `/Library`, `/private`, `/usr`, `/bin`, `/sbin`, `/var` (except `/var/folders/*/T` user-scoped temp), or anything under `/Applications` directly.
- **Never** delete from these user work locations without explicit confirmation:
  - `~/Documents/Workspace/`, `~/Documents/Workspace.nosync/` — active source repos (SCG/CPO and others)
  - `~/Documents/Obsidian Vault/`, `~/Documents/Personal Document/`, `~/Documents/Specification/`, `~/Documents/Assets/`, `~/Documents/E-Commerce/`, `~/Documents/Claude/`
  - `~/Desktop/Cowork/` (this workspace), `~/Desktop/Projects/`, `~/Desktop/AWS-Certification/`, `~/Desktop/AllPay/`, `~/Desktop/CPO-Leasing/`, `~/Desktop/Migration/`, `~/Desktop/Documents/`, `~/Desktop/Screenshots/`
  - Any `.git`, `.env`, credentials, SSH keys, signed certificates, or `node_modules` inside an active repo (only clean `node_modules` if the user asks specifically and the repo is identifiable as inactive).
- **Safe-by-default targets** (still confirm before bulk delete):
  - User-scoped caches: `~/Library/Caches/*`, `~/.cache/`, `~/.npm/_cacache/`, `~/.yarn/cache/`, `~/.pnpm-store/`, `~/.bun/install/cache/`, `~/.gradle/caches/`, `~/Library/Developer/Xcode/DerivedData/`, `~/Library/Developer/CoreSimulator/Caches/`, `~/Library/Containers/*/Data/Library/Caches/`
  - Logs: `~/Library/Logs/`
  - Downloads older than N days (ask the user for N)
  - Trash: `~/.Trash/`
  - Docker/Colima images and dangling volumes (only on user request)
- **Mandatory pre-flight for any deletion**:
  1. Show what will be deleted (paths + sizes via `du -sh`).
  2. Show total reclaimable size.
  3. Ask for explicit confirmation.
  4. Prefer `trash` (move to Trash) over `rm -rf` when possible — recovery beats speed.

## Useful disk-usage commands

- `du -sh ~/Library/Caches/* 2>/dev/null | sort -h` — top user caches by size
- `du -sh ~/* 2>/dev/null | sort -h` — top home dirs by size
- `df -h /` — overall disk free
- `mdfind -onlyin ~ "kMDItemFSSize > 1073741824"` — files >1GB in home

## Landing page

`landing.html` is the project marketing page. It is a single self-contained HTML file with embedded CSS and JS. When editing it:

- Keep it self-contained — no external CSS/JS files.
- The app UI mockups are built with CSS to match the SwiftUI source (see `docs/LANDING.md` for the mapping).
- Category accent colors must match `CleanupCategory.accent` in `Sources/Bytegone/Models.swift`.
- The donation link must match `SupportLink.url` in `Sources/Bytegone/SupportLink.swift`.

## AWS configuration

When running AWS CLI commands for this project (e.g., uploading build artifacts or managing S3 assets), use the **`personal`** profile:

```bash
export AWS_PROFILE=personal
```

This profile is mapped to the `lung-wang` credentials in `~/.aws/credentials` with region `ap-southeast-1`.

## Landing page deployment

The landing page is deployed to AWS using S3 + CloudFront + Route 53. All infrastructure is defined as code in `infra/landing-stack.yaml`.

### Architecture

| Service | Purpose |
|---|---|
| Route 53 | Domain registration (`bytegone.app`) + DNS |
| ACM | Free SSL certificate (must be in `us-east-1` for CloudFront) |
| S3 | Static website bucket (`bytegone.app`) + redirect bucket (`www.bytegone.app`) |
| CloudFront | Edge CDN with HTTPS, custom domain, and Origin Access Control (OAC) |

### One-time setup

```bash
export AWS_PROFILE=personal

# 1. Request SSL certificate in us-east-1 (required for CloudFront)
scripts/request-certificate.sh bytegone.app

# 2. Deploy the CloudFormation stack
#    (replace <CertificateArn> with the ARN from step 1)
scripts/deploy-stack.sh bytegone.app <CertificateArn>

# 3. Register the domain and point nameservers to Route 53
scripts/register-domain.sh bytegone.app
```

### Deploying updates

```bash
# Build app, generate assets, and deploy to S3 + invalidate CloudFront
scripts/deploy-landing.sh bytegone.app
```

### Cost optimization

- CloudFront **Price Class 100** (NA/EU/Asia only) — saves ~20% vs All regions
- No WAF, no logging buckets, no extra services
- Estimated monthly cost: ~$2 (domain amortized + Route 53 hosted zone + S3 + CloudFront free tier)

## Parent workspace

This directory inherits rules from `~/Desktop/Cowork/CLAUDE.md` (Clockify time-logging and MS Graph API rules). Cleanup work itself is unrelated to those — log it under `00-Other` if a Clockify entry is needed.
