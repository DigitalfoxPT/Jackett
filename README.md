# Jackett - DigitalfoxPT Windows x64 Fork

[![Windows x64 Build](https://github.com/DigitalfoxPT/Jackett/actions/workflows/windows-build.yml/badge.svg)](https://github.com/DigitalfoxPT/Jackett/actions/workflows/windows-build.yml)
[![Latest Release](https://img.shields.io/github/v/release/DigitalfoxPT/Jackett?style=flat-square)](https://github.com/DigitalfoxPT/Jackett/releases/latest)
[![Upstream](https://img.shields.io/badge/upstream-Jackett%2FJackett-blue?style=flat-square)](https://github.com/Jackett/Jackett)

This repository is a **personal Windows-only fork of [Jackett/Jackett](https://github.com/Jackett/Jackett)** maintained by `DigitalfoxPT`.

The purpose of this fork is not to become an independent rewrite of Jackett. It keeps the upstream Jackett code and indexer ecosystem while applying a small, controlled set of Windows-specific customizations and automatically synchronizing with upstream.

> **Important maintenance note:** This README is intentionally written as both user documentation and a maintenance contract. A future maintainer, including ChatGPT, should read this section before changing the repository.

## Fork goals

This fork must preserve the following behavior unless the repository owner explicitly requests otherwise:

- **Windows only**.
- **x64 only** using the `win-x64` runtime identifier.
- **.NET 10** as the target framework.
- **Self-contained deployment**, so the target PC does not need a separately installed .NET runtime.
- **No Jackett system tray application** in the shipped binaries.
- Jackett runs as a **Windows Service** and starts automatically with Windows when installed.
- The web dashboard supports **System / Light / Dark** themes.
- The selected UI theme is stored locally in the browser.
- Automatic application updates are obtained from **`DigitalfoxPT/Jackett`**, not directly from `Jackett/Jackett`.
- The fork performs a **full source synchronization once per day** and checks for a **new stable upstream release every 6 hours**.
- GitHub Releases in this fork use **exactly the same version number as the latest stable upstream Jackett release**.
- The installed Jackett checks this fork for application updates every **6 hours**, after an initial check 1 hour after startup.
- The fork should stay as close to upstream as practical so synchronization remains maintainable.

## Upstream and fork relationship

| Purpose | Repository |
|---|---|
| Official upstream project | `Jackett/Jackett` |
| Customized Windows fork | `DigitalfoxPT/Jackett` |
| Default branch | `master` |

The upstream project remains the source of Jackett functionality, tracker definitions, fixes and normal product development.

This fork adds only the Windows-specific build, packaging, update and UI customizations described in this README.

### Maintenance principle

**Keep the custom delta small.**

Do not perform large frontend rewrites or unnecessary refactors merely because newer technologies exist. Changes that touch many upstream files make the daily merge harder and increase the probability of conflicts.

When updating a dependency or modernizing code:

1. Prefer stable releases.
2. Update only when there is a practical benefit.
3. Compile and run the full test suite.
4. Preserve upstream behavior.
5. Avoid replacing working upstream architecture unless required for .NET 10 or Windows compatibility.

## Current technical profile

| Component | Fork configuration |
|---|---|
| Operating system | Windows |
| CPU architecture | x64 |
| Target framework | .NET 10 |
| Runtime identifier | `win-x64` |
| Deployment | Self-contained |
| Build configuration | Release |
| CI runner | `windows-2025-vs2026` |
| CI operating system | Windows Server 2025 |
| CI Visual Studio | Visual Studio 2026 |
| Service | Windows Service |
| System tray | Removed from shipped package |
| Web UI themes | System / Light / Dark |
| Updater source | `DigitalfoxPT/Jackett` releases |
| Upstream release check | Every 6 hours |
| Full upstream source sync | Once per day |
| Installed app update check | 1 hour after startup, then every 6 hours |

The build currently publishes these executables/components:

- `JackettConsole.exe`
- `JackettService.exe`
- `JackettUpdater.exe`

`JackettTray.exe` must **not** be present in the release package.

## Versioning contract

This fork does **not** have an independent application version scheme.

The release version must always match the latest stable release published by the official Jackett repository.

Example:

```text
Official Jackett release:     v0.24.2581
DigitalfoxPT fork release:    v0.24.2581
Assembly/File version:        0.24.2581
Installer version:            0.24.2581
```

When upstream later publishes:

```text
v0.24.2582
```

this fork should publish:

```text
v0.24.2582
```

### Never do this

Do not create an unrelated sequence such as:

```text
v1.0.0
v1.0.1
v2.0.0
```

unless the repository owner explicitly changes the versioning policy.

The build workflow obtains the current version from:

```text
https://api.github.com/repos/Jackett/Jackett/releases/latest
```

and uses the upstream release tag throughout the build.

## Release behavior

The release assets expected by the updater and installer workflow are:

```text
Jackett.Binaries.Windows.zip
Jackett.Installer.Windows.exe
```

Keep `Jackett.Binaries.Windows.zip` with this exact name unless the updater code is intentionally changed at the same time.

### Rebuilding the same upstream version

A custom fork change can occur while upstream is still on the same version. For example, documentation, a dark-mode fix or a .NET compatibility correction may be committed while upstream remains at `v0.24.2581`.

In that case the workflow intentionally:

1. builds and tests the current fork commit;
2. removes the existing fork release with that version, if present;
3. removes/recreates the corresponding tag so it points to the commit that produced the new binaries;
4. recreates the GitHub Release using the same upstream version number;
5. uploads fresh ZIP and installer assets.

This is deliberate. It ensures the GitHub release timestamp and tag correspond to the most recent successful build while still preserving the upstream version number.

## GitHub Actions

### `.github/workflows/windows-build.yml`

This is the main Windows build and release workflow.

It runs on:

- pushes to `master`;
- pull requests targeting `master`;
- manual `workflow_dispatch`.

It uses:

```yaml
runs-on: windows-2025-vs2026
```

The workflow performs this sequence:

```text
Checkout
  -> Setup .NET 10
  -> Read latest upstream release version
  -> dotnet restore
  -> dotnet build
  -> unit tests
  -> publish Jackett.Server win-x64 self-contained
  -> publish Jackett.Updater win-x64 self-contained
  -> publish Jackett.Service win-x64 self-contained
  -> assemble Windows package
  -> verify JackettTray.exe is absent
  -> create Jackett.Binaries.Windows.zip
  -> build Inno Setup installer
  -> upload GitHub Actions artifact
  -> recreate the GitHub Release on master push or workflow_dispatch
```

The workflow uses `concurrency` with `cancel-in-progress: true` so multiple builds of the same ref do not simultaneously attempt to replace the same release.

### `.github/workflows/upstream-sync.yml`

This workflow combines a lightweight stable-release check with a daily full source synchronization.

Current schedule:

```text
00:17 UTC - full source synchronization and release check
06:17 UTC - lightweight release check
12:17 UTC - lightweight release check
18:17 UTC - lightweight release check
```

It can also be launched manually with `workflow_dispatch`; a manual run performs a full source synchronization.

The workflow first queries the latest stable `Jackett/Jackett` release. If the matching release already exists in this fork and the run is one of the 6-hour lightweight checks, the workflow stops without checkout, .NET setup, compilation or tests.

A full daily sync, or any 6-hour check that detects a missing upstream release, performs this sequence:

1. checks out the fork `master` with full history;
2. adds `https://github.com/Jackett/Jackett.git` as the `upstream` remote;
3. fetches upstream `master` and tags;
4. checks whether new upstream commits exist;
5. merges `upstream/master` locally when required;
6. installs .NET 10 only when source changes actually need validation;
7. validates changed source with restore, build and unit tests;
8. pushes the merge only if validation succeeds;
9. if the latest stable upstream release is missing from this fork, dispatches `windows-build.yml` explicitly.

The explicit workflow dispatch after synchronization is important. Do not rely on a push made with the default `GITHUB_TOKEN` to start another workflow.

If the merge fails, it aborts the merge and creates a GitHub issue titled:

```text
Daily upstream sync conflict
```

If the merge succeeds but compilation/tests fail, it does **not** push the merged source and creates an issue titled:

```text
Daily upstream validation failed
```

This safety mechanism is important. Do not change it to blindly push upstream changes before validation.

### New upstream release detection

A new official stable release is detected within at most roughly 6 hours by the scheduled release checks.

If the latest official upstream release does not yet exist in this fork, the workflow synchronizes the source as required and dispatches `windows-build.yml`. The Windows build reads the official upstream release number, compiles the Windows x64 / .NET 10 fork, and creates the matching fork release.

## Automatic updates inside Jackett

The application updater has been customized to query this fork's GitHub Releases rather than the official Jackett release feed.

Expected update flow:

```text
Jackett/Jackett stable release
        |
        v
Release check every 6 hours
        |
        v
Synchronize fork source when required
        |
        v
DigitalfoxPT/Jackett master
        |
        v
Windows x64 / .NET 10 build and tests
        |
        v
DigitalfoxPT/Jackett GitHub Release
        |
        v
Installed Jackett checks this fork every 6 hours
```

The installed application performs its first automatic update check approximately **1 hour after startup**. After that, it checks this fork every **6 hours**.

Therefore, ignoring build time and GitHub scheduling delays, a newly published official release should normally reach an already-running installation within **about 12 hours in the worst alignment case**, instead of the previous theoretical 48-hour window.

The custom requirement is that the GitHub release API remains pointed at `DigitalfoxPT/Jackett`.

When working on updater code, confirm that it has **not reverted to `Jackett/Jackett/releases`** and that `Jackett.Binaries.Windows.zip` remains the Windows updater asset.

## Windows Service behavior

The fork does not use the tray application as its runtime launcher.

The installer uses Jackett's Windows Service support. The intended installed state is:

```text
Jackett Windows Service
Startup type: Automatic
Web UI: http://127.0.0.1:9117/UI/Dashboard
```

A future change must not accidentally make `JackettTray.exe` required for normal operation.

When testing installer changes, verify:

- service installation succeeds;
- service starts;
- service survives a Windows restart;
- web UI opens on port 9117;
- uninstall stops and removes the service cleanly;
- no tray process is required.

## Native web UI theme

This fork adds a persistent theme selector to the Jackett web interface with:

```text
System
Light
Dark
```

`System` follows the browser/Windows preference through `prefers-color-scheme`.

The theme implementation is intentionally lightweight and should remain compatible with the existing Jackett frontend instead of requiring a full frontend rewrite.

Relevant custom assets include the theme CSS/JavaScript under the Jackett Server `Content` directory, including:

```text
src/Jackett.Server/Content/theme.css
src/Jackett.Server/Content/theme.js
```

The theme preference is stored in browser local storage. It is not necessary to add server-side configuration merely to remember Light/Dark/System.

When modifying frontend dependencies, verify dark mode on at least:

- dashboard;
- forms and text inputs;
- dropdowns;
- tables and DataTables;
- modals;
- alerts;
- indexer configuration;
- manual search;
- logs;
- mobile layout.

## Dependency modernization policy

This fork moved the backend to .NET 10 and modernized selected NuGet dependencies where practical.

Future maintainers may update stable dependencies, but should avoid mass upgrades without testing.

In particular, frontend major upgrades such as these can require substantial code changes:

```text
jQuery 3 -> 4
Bootstrap 3 -> 5
DataTables 1.x -> 3.x
```

Do not perform those migrations only to make version numbers newer. Evaluate them independently because they can greatly increase divergence from upstream.

For NuGet updates:

```text
dotnet restore src/Jackett.sln
dotnet build src/Jackett.sln -c Release --no-restore
dotnet test src/Jackett.Test/Jackett.Test.csproj -c Release --no-build --framework net10.0-windows
```

must continue to pass.

## Important custom files

A future maintainer should inspect these files first when debugging fork-specific behavior:

| File | Purpose |
|---|---|
| `.github/workflows/windows-build.yml` | Windows x64 build, tests, packaging and release creation |
| `.github/workflows/upstream-sync.yml` | 6-hour stable-release checks plus daily upstream source synchronization and validation |
| `Installer.iss` | Windows x64 installer and Windows Service setup |
| `src/Jackett.Common/Services/UpdateService.cs` | Automatic 6-hour update checks and fork release source |
| `src/Jackett.Common/Utils/Variants.cs` | Artifact/platform naming used by updater |
| `src/Jackett.Server/Jackett.Server.csproj` | .NET 10 Windows server build |
| `src/Jackett.Updater/Jackett.Updater.csproj` | .NET 10 Windows updater build |
| `src/Jackett.Service/Jackett.Service.csproj` | .NET 10 Windows Service build |
| `src/Jackett.sln` | Solution composition; tray is not part of the shipped build |
| `src/Jackett.Server/Content/theme.css` | Light/Dark/System theme styling |
| `src/Jackett.Server/Content/theme.js` | Theme selection and persistence |

## Instructions for a future maintainer or ChatGPT

Before changing this repository:

1. **Read this README first.**
2. Inspect the latest successful `Windows x64 Build` Action.
3. Inspect the latest `Daily Upstream Sync` Action.
4. Compare the fork against `Jackett/Jackett` to understand whether a failure came from upstream or from a custom fork change.
5. Preserve the release/versioning contract.
6. Keep the updater pointed at this fork.
7. Preserve the 6-hour stable-release detection cadence and the daily full source sync unless the owner requests another policy.
8. Keep the build Windows x64 only.
9. Keep .NET 10 unless the owner explicitly requests a later supported .NET version.
10. Keep the package self-contained.
11. Do not restore `JackettTray.exe` to the shipped package.
12. Do not push an upstream merge that fails compilation or tests.
13. Prefer a small, targeted fix over a broad rewrite.
14. After a fix, monitor the resulting GitHub Actions run and inspect job logs if it fails.
15. A green compile alone is not enough. Unit tests, packaging and release creation must also succeed.

### If a GitHub Action fails

Use this order when diagnosing the problem:

```text
1. Identify the exact failed step.
2. Read that job's logs.
3. Determine whether the failure is:
   - GitHub Actions/YAML
   - .NET restore
   - compilation/API compatibility
   - unit tests
   - publish
   - packaging/Inno Setup
   - GitHub Release/tag handling
   - upstream merge conflict
4. Correct only the affected layer when possible.
5. Re-run and verify the complete workflow.
```

Past examples of fork-specific failures include library API changes after dependency updates and PowerShell/GitHub CLI commands returning a non-zero exit code for an expected "not found" condition. Do not assume that a red workflow means compilation failed; inspect the exact step.

## Installing this fork

Use the latest release from:

https://github.com/DigitalfoxPT/Jackett/releases/latest

Recommended asset:

```text
Jackett.Installer.Windows.exe
```

A portable/self-contained package is also available as:

```text
Jackett.Binaries.Windows.zip
```

After installation, open:

```text
http://127.0.0.1:9117/UI/Dashboard
```

## Basic acceptance test after installation

After installing a new fork release, verify:

- displayed Jackett version matches the corresponding official upstream release;
- `Jackett` Windows Service exists and is running;
- startup type is automatic;
- `http://127.0.0.1:9117/UI/Dashboard` opens normally;
- there is no `JackettTray.exe` requirement;
- System/Light/Dark theme selection works and persists;
- existing indexers load and can be tested;
- automatic update checks query this fork;
- uninstall removes/stops the service correctly.

## Original Jackett documentation

For general Jackett usage, tracker support, API documentation and upstream troubleshooting, use the official project documentation:

- Upstream repository: https://github.com/Jackett/Jackett
- Upstream releases: https://github.com/Jackett/Jackett/releases
- Upstream wiki: https://github.com/Jackett/Jackett/wiki
- Upstream contributing guide: https://github.com/Jackett/Jackett/blob/master/CONTRIBUTING.md

When upstream documentation conflicts with this README on build platform, runtime, tray behavior, release source or update source, **this README describes the intended behavior of the DigitalfoxPT fork**.

## License and credits

Jackett is an open-source project maintained by the Jackett community. This repository is a customized fork and retains the upstream project license and copyright notices.

See [LICENSE](LICENSE) for the applicable license terms.
