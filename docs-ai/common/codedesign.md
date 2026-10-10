# Shared code standards

## Existing conventions

Use the repository's existing architecture, `.editorconfig`, compiler settings, central package management, and established implementation patterns. Read the affected source before selecting an implementation.

Keep changes within the task's purpose. Prefer clear responsibilities, existing abstractions, and direct implementations. Do not introduce an abstraction, design pattern, or broad refactoring without a concrete requirement.

Name classes, types, members, and data structures by their responsibilities. Do not prepend a product or brand name to individual types solely for branding. Follow the affected project's naming and formatting conventions where this document does not prescribe a rule.

Comments should explain intent, constraints, or non-obvious behavior. Keep comments accurate and avoid restating obvious code. Do not place task history, approval narratives, or change ledgers in source comments.

## Solution and project names

Ordinary solution and project names begin with the product or project name, without an organization prefix. Apply the same convention to their display names and file basenames.

| Project role | Naming pattern | Example |
| --- | --- | --- |
| Ordinary project | `<ProductName>.<Purpose>` | `Flourish.Blazor.Framework` |
| Ordinary project | `<ProductName>.<Purpose>` | `Colligere.Web` |
| Ordinary project | `<ProductName>.<Purpose>` | `Essential.Culture.Blazor` |
| Test project | `Tests.<ProjectName>` | `Tests.Flourish.Blazor.Framework` |
| Gallery project | `Gallery.<ProjectName>` | `Gallery.Flourish.Blazor` |
| Extension or bridge | `<ProjectName>.Extensions.<Integration>` | `Flourish.Extensions.Culture.Blazor` |
| Extension test project | `Tests.<ProjectName>.Extensions.<Integration>` | `Tests.Flourish.Extensions.Culture.Blazor` |
| Extension Gallery project | `Gallery.<ProjectName>.Extensions.<Integration>` | `Gallery.Flourish.Extensions.Culture.Blazor` |

`Tests.` and `Gallery.` are role-prefix exceptions to the product-first convention. Place the product or project name immediately after the role prefix.

## Namespaces and identities

Project-owned namespaces must begin with `ArkheideSystem.` or `Arkheide.`. Prefer `ArkheideSystem.`, for example `ArkheideSystem.Flourish.Blazor`.

Organization-free solution and project names do not remove the organization prefix from namespaces. Do not infer namespace rules from a test or Gallery project prefix.

Keep these identities distinct:

- Solution name and solution file basename.
- Project name and project file basename.
- Namespace and `RootNamespace`.
- `AssemblyName`.
- NuGet `PackageId`.

A project-name change does not automatically authorize changes to its namespace, assembly identity, or package ID. Existing `Arkheide.*` NuGet package IDs must remain unchanged unless a package-specific migration is authorized.

New or explicitly renamed solutions and projects must follow these naming rules. Treat nonconforming existing names as migration work to assess; do not silently accept them as general exceptions or rename them as a side effect. Explain compatibility implications and obtain authorization before migration.

Third-party source retains its original ownership and naming. Do not rename it merely to satisfy project-owned naming rules.

## Behavior and compatibility

Preserve established identifiers and public contracts unless the task authorizes their change. Assess affected callers, serialization, package consumers, and configuration before a compatibility-sensitive change.

Preserve existing access control, domain behavior, and session behavior unless the task requests or approves a change. A UI request does not authorize unrelated business-rule changes.

Follow existing async, cancellation, resource-lifetime, and error-handling conventions where applicable. Keep user-facing behavior consistent with the current product contract; report conflicts rather than inventing a replacement contract.

## Supporting rules

Apply [rules.md](rules.md) for dependency authorization, validation, records, and delivery. For UI work, apply [UIUX.md](UIUX.md) and the actual Flourish implementation.
