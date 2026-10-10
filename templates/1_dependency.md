# Project dependency inventory

**Status:** Template awaiting repository inspection. No dependency identities or versions have been verified. Complete this inventory from declarations and resolved evidence before marking the documentation audit complete.

## Inventory scope and evidence

Cover every dependency actually used by the project, including direct and resolved transitive packages, local project references, SDKs and runtimes, external services, fonts and icon resources, and build/test/development tools. Classify production, build, test, development, and optional usage explicitly.

Record the inspected repository revision or scope and the relevant manifests, central configuration, lock files, project-reference declarations, and dependency resolution reports. Do not treat a declared version range as an exact resolved version.

| Evidence path or command | What it establishes | Verification status |
| --- | --- | --- |

## Direct packages

List each direct package and all consuming projects. Use separate rows when version requirements or resolved versions differ.

| Package ID | Declared version/constraint | Resolved version | Consumers | Usage scope | Purpose | Source/license | Declaration and resolution evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |

## Resolved transitive packages

Enumerate resolved transitive dependencies completely in this file. Do not replace the inventory with a few examples.

| Package ID | Resolved version | Consumers | Introduced by | Usage scope | Purpose | Source/license | Resolution evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |

## Local project references

Record project-to-project dependencies separately from external package dependencies.

| Consuming project | Referenced project | Purpose and dependency direction | Declaration |
| --- | --- | --- | --- |

## SDKs, frameworks, and runtimes

Include required toolchains, target frameworks, runtime requirements, and relevant pinning or compatibility constraints.

| Dependency | Declared constraint | Observed/resolved version | Consumers | Usage scope | Purpose | Evidence |
| --- | --- | --- | --- | --- | --- | --- |

## External services

Record service dependencies and relevant API contracts or deployment requirements. Use `Not applicable` where a package-style version is not meaningful. Never include credentials or secret connection data.

| Service | Contract/version | Consumers | Usage scope | Purpose | Declaration or configuration evidence |
| --- | --- | --- | --- | --- | --- |

## Assets and development tools

Include fonts, icon resources, and other external UI assets, plus build, test, code-generation, and development tools actually required by the repository. Record verified licensing and distribution sources where applicable.

| Dependency | Kind | Version/constraint | Consumers | Usage scope | Purpose | Source/license | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |

## Active constraints and unresolved facts

Record currently applicable dependency constraints, known compatibility boundaries, and information still awaiting verification. Mark unknown identities, versions, or licenses explicitly; do not invent values.

Keep proposed dependencies out of the active inventory until adopted. Record historical adoption, replacement, and upgrade decisions in `1_changelogs/`; archive abandoned dependency designs in `1_archived/` when useful.

Apply the external dependency authorization rules in `docs-ai/common/rules.md` before changing dependency declarations. This inventory records actual usage and does not grant authorization.
