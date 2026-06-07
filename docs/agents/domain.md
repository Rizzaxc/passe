# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`CLAUDE.md`** at the repo root — currently the primary home of domain language, architecture decisions, and coding guidelines for this project.
- **`CONTEXT.md`** at the repo root, if it exists — created by `/grill-with-docs` when domain terms are formally resolved. Takes precedence over CLAUDE.md for glossary purposes once it exists.
- **`docs/adr/`** — read ADRs that touch the area you're about to work in.

If `CONTEXT.md` or `docs/adr/` don't exist yet, **proceed silently**. Don't flag their absence; don't suggest creating them upfront. The producer skill (`/grill-with-docs`) creates them lazily when terms or decisions actually get resolved.

## File structure

Single-context repo:

```
/
├── CLAUDE.md          ← domain language + guidelines (current primary source)
├── CONTEXT.md         ← glossary (created by /grill-with-docs when ready)
├── docs/adr/
│   ├── 0001-*.md
│   └── ...
└── lib/               ← Flutter app source
```

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in `CONTEXT.md` (or `CLAUDE.md` until that exists). Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal — either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `/grill-with-docs`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0007 (example) — but worth reopening because…_
