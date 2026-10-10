# Framework dependency inventory

## Scope and evidence

This repository distributes text instructions and a manifest-based PowerShell installer. There are no package-manager manifests, application projects, NuGet/npm packages, local project references, fonts, icons, databases, or deployed application services. No third-party PowerShell modules or Pester packages are required.

Evidence: `scripts/fetch-agents.ps1`, `scripts/publish-framework.ps1`, `fetch-agents.bat`, `tests/test-sync.ps1`, and `.github/workflows/verify.yml`. The root `debug-handler.bat` is an empty seed and introduces no dependency. BAT operations acquire the central controller on every run, even when the selected payload is local. Integration tests redirect the central Git URL through child-process-only Git configuration to temporary local repositories; no global configuration or network is required. Hosted checkout and live bootstrap smoke verification require network access.

## Direct tools, runtimes, and services

| Dependency | Constraint or contract | Observed version / pin | Scope and consumers | Purpose and evidence |
| --- | --- | --- | --- | --- |
| PowerShell | Windows PowerShell 5.1 or PowerShell 7 | Observed locally: 5.1.26100.9444 and 7.6.5; CI tests platform-provided versions | Installer, publisher, tests | `#requires -Version 5.1`; uses built-in cmdlets and .NET APIs only |
| .NET framework/runtime | Supplied with the selected PowerShell edition | Observed locally: .NET Framework 4.8.9345.0 and .NET 10.0.11; resolved by PowerShell distribution, no independent pin | Installer/publisher/tests | UTF-8, JSON, SHA-256, process execution, and file operations; no additional assembly/package installation |
| Git | Available on PATH; Git for Windows for the BAT launcher; historical commit objects required by regression tests | Observed locally: 2.56.0.windows.1; no project minimum version pin | Installer, bootstrap, tests, development | Temporary fetch/clone, commit/tree/blob reads, historical fixture archives, and isolated repositories; CI uses `fetch-depth: 0` |
| Windows CMD | Windows `cmd.exe` | Operating-system component, unpinned | Optional Windows entry point | `fetch-agents.bat`; PowerShell can also run directly on Linux/macOS |
| curl | Windows `curl.exe`, HTTPS download | Observed locally: 8.21.0; operating-system/tool installation, unpinned | First-install command only | README bootstrap downloads the launcher; later launcher updates use Git |
| GitHub Git/HTTPS | Public repository and raw-file service | `https://github.com/Evigila/AGENTS.md.git` `main` for the controller; selected payload branch/tag/commit recorded independently | Every Windows BAT synchronization/check and default payload source | Verified central controller acquisition; compatible alternate payload sources can be selected without changing the controller source |
| GitHub Actions | Hosted workflow service | `windows-latest`, `ubuntu-latest`; image contents are provider-managed | CI only | Workflow matrix runs manifest verification and the local integration suite |
| `actions/checkout` | Commit-pinned action | `11d5960a326750d5838078e36cf38b85af677262` (v4 ref inspected) | CI only, direct action dependency | `.github/workflows/verify.yml`; action checks out the repository |
| Node.js action runtime | `node20` declared by the pinned checkout action | Supplied by GitHub Actions; not a local installer dependency | CI only, transitive runtime | Pinned action's `action.yml` declares `runs.using: node20` |

The checkout action ships bundled JavaScript (`dist/index.js`); this repository does not resolve or install its internal development packages. There is no application package-resolution graph to enumerate. OS/provider tools may contain internal dependencies outside this project's declarations; they are not represented as independently resolved project packages.

## Sources and licensing

- PowerShell distribution: [PowerShell repository](https://github.com/PowerShell/PowerShell). Distribution/OS licensing is supplied by the installed edition; no license text is redistributed here.
- Git distribution: [Git project](https://git-scm.com/). No Git binaries are redistributed.
- Checkout action: [pinned action declaration](https://github.com/actions/checkout/blob/11d5960a326750d5838078e36cf38b85af677262/action.yml) and [MIT license](https://github.com/actions/checkout/blob/11d5960a326750d5838078e36cf38b85af677262/LICENSE), inspected at the pinned revision.
- GitHub and Windows services/components follow their respective platform terms. No credentials or binaries are stored in this repository.

## Compatibility and unresolved facts

The integration suite checks PowerShell edition compatibility through CI. Exact versions of rolling runner images and tools are determined per run; the workflow log is their resolved evidence. macOS execution is supported by the portable installer design but is not in the CI matrix. Native BAT behavior requires Windows; Linux checks do not establish CMD compatibility.

The shared Flourish and Arkheide policies describe consumer project standards. This framework contains no Flourish assembly/package and introduces no such runtime dependency into its installer.
