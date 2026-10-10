# Shared UI and UX integration standards

## Authority

Flourish repository source, styles, and component implementations are the sole authority for component visuals and interaction behavior. Use the actual implementation and its public contracts to determine supported behavior.

This document defines integration and ownership rules. It does not define a separate visual system, duplicate visual tokens, or replace Flourish source with Markdown specifications. Runtime, localization, and package documentation govern their technical subjects without becoming a competing visual authority.

## Reading order

For each affected UI area, inspect:

1. The actual Flourish components that provide the required capability.
2. Their styles and supported configuration.
3. Their public APIs and interaction contracts.
4. The host's existing usage and relevant product requirements.

When Flourish source is unavailable, identify the gap and obtain the necessary source or direction. Do not guess unsupported public APIs or invent a substitute component system.

## Component reuse

Use Flourish controls, styles, and supported extension points for applicable interfaces. Do not:

- Copy or clone Flourish controls into a host project.
- Create host skins or parallel component styling that replaces Flourish.
- Implement an independent control in place of an available Flourish component.
- Hard-code a competing set of visual standards in host markup or styles.

Use the component's existing mechanisms for state, validation, interaction, and localization where available. Follow its actual contract rather than duplicating behavior in the host.

## Host responsibilities

Hosts own business and backend logic, domain behavior, access control, and approved brand and semantic color-role configuration. Compose supported Flourish components according to product requirements and pass data through their public interfaces.

Do not take over visuals or interaction behavior that Flourish owns. Keep changes to business, permission, or session behavior within the authorized task scope under [rules.md](rules.md).

Semantic HTML and native GET/POST handling may be used at a host protocol boundary. They must not serve as replacements for Flourish UI controls.

## Missing capabilities

If Flourish does not provide a required capability:

1. Identify the missing control or behavior and affected requirement.
2. Continue supported work that does not depend on the missing capability.
3. Leave the unsupported portion unimplemented and report its impact.
4. Obtain explicit direction before introducing a custom implementation or expanding Flourish.

Record a durable project-specific gap in `docs-ai/current/` when it affects the implementation or a continuing decision. Do not present skipped work as completed.

## Verification

Verify component usage, supported configuration, and affected behavior through code inspection and appropriate builds or tests. Provide manual steps for user-visible interactions that require human verification. Apply the testing boundaries in [rules.md](rules.md); UI work does not create an exception to them.
