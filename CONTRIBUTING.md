# Contributing to Bytegone

Thank you for your interest in contributing!

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/your-username/bytegone.git`
3. Build the project: `./build.sh`

## How to Contribute

- **Bug Reports**: Use the [Bug Report template](https://github.com/sososaity/bytegone/issues/new?template=bug_report.yml)
- **Feature Requests**: Use the [Feature Request template](https://github.com/sososaity/bytegone/issues/new?template=feature_request.yml)
- **Pull Requests**: Keep changes focused. Update docs if behavior changes.

## Code Guidelines

- Follow Swift style conventions
- Add safety guards for any new cleanup paths
- Never use `rm` directly — always `FileManager.trashItem`
- Update `docs/` if adding new categories or features

## Safety First

Bytegone handles file deletion. Any PR touching `SafetyGuard.swift`, `DiskScanner.swift`, or `CleanupService.swift` will be reviewed with extra scrutiny.

## Questions?

Open a [Discussion](https://github.com/sososaity/bytegone/discussions) or reach out via the project's social channels.
