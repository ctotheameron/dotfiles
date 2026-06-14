# Cameron's preferences

## Commit messages

Match the style of my existing commits — sampled from `git log --author="Cameron Austgen"`.

### Subject

- Format: `type(scope): short description`
- All lowercase, including the description. No trailing period.
- The `(#NNNN)` PR suffix is added by GitHub on squash-merge — never write it manually.
- Keep under ~70 chars.

**Types I actually use** (don't invent new ones unless the situation truly warrants):
- `feat` — new functionality
- `fix` — bug fix
- `chore` — maintenance, deps, cleanup
- `refactor` — internal restructuring with no behavior change
- `test` — adding/improving tests
- `ci` — pipeline / GitHub Actions
- `dev` — local tooling, just recipes, dev workflow, worktree setup
- `doc` — documentation only
- `perf` — performance work
- `style` — formatting only (rare)

**Scopes I actually use**:
- Domain: `directory`, `dataroom`, `transact`, `ds`, `email`, `emails`, `drc`, `controls`, `transfer`, `treasury`, `dr`, `vehicle`
- Stack layer: `prisma`, `core`, `api`, `rest`, `argo`, `stainless`, `std.ts`, `engbot`, `vulcan`
- Other: `e2e`, `Result` (camelCase package names ok)

**Description shape** — pick whichever fits the change:
- Verb-led when adding: `adds idempotency header to payment_instructions`
- Verb-led when modifying: `wire v1 distributions scaffolding`
- Imperative when fixing/removing/renaming: `rm stainless.yml`, `drop distribution_date_override from DistributionPayment`, `rename canApproveTransfers to canManageTransfers`
- Noun phrase ok for foundational/placeholder commits: `placeholder stainless.yml`, `integration, integrationCredential, integrationGrant models`

### Body

**Default to no body.** Many of my commits ship with an empty body. Only write one when:
- The change is non-obvious and a future reader (or me, in three months) will want the rationale.
- There's a "previously / now" worth showing.
- The change has a non-trivial API surface worth documenting inline.

**When I do write a body**, it looks like this:

- Bullet lists (lead with `-` or `*`, both fine; prefer `-` in newer commits), terse, present-tense ("adds X", "wires Y", "accepts Z").
- Prose paragraphs for the WHY of a decision. Direct, technical, no preamble. First person when it's a personal call ("I've restructured...", "Settled on..."), third person otherwise.
- Code fences (```` ``` ````) for API/type examples when illustrating shape — actual snippets, not pseudocode.
- Identifiers, file paths, and column/table names in backticks.
- Subsections labeled inline: `Misc:`, `Note:`, `drive-by:`, `Only "breaking-ish" change:`.
- Skip section headings (no `## Overview`, etc.) — flat structure.
- Verification notes at the bottom when warranted ("Verified that the diagnostic warning in stainless goes away (these ymls are live)").
- Loom links / mermaid diagrams welcome for complex flows.

**What I never do**:
- Multi-paragraph essays explaining every line of the diff.
- Bullet lists that just restate the file list.
- `Co-authored-by:` lines (unless explicitly requested).
- Fluff sentences before the first concrete statement.
- Long "rollout steps" lists in the body when the migration's own comments already cover it — point at the file, don't duplicate.

### Examples to match against

Short, no body — most commits:
```
feat(rest): adds `/v1/payment_instructions` schema
```

Terse bullet list:
```
feat(argo): integration service layer

Functions exposed:
* `integration.authorize()` -> checks that both grant and active integration exist
* `integration.onboard()` -> creates a new integration, and credential, returns the un-hashed `oauthClientSecret` while writing the hashed version
* `integration.grantAccessTo()` -> allow integration to manage an org
...

Utils;
- secret.ts adds oauth client_id/secret generation and scrypt-based hashSecret/verifySecret
```

Prose + code + verification:
```
feat(api): refine api schema for entity / person

Stainless was reporting errors on our Go / Java builds due to the lack of
discriminators on our person/entity types.

Previously they were an intersection of:
{ id: string } | { name: string /** rest **/ }

Naively this could be like:
{ kind: 'existing', id: string } | { kind: 'new', name: string }

---

I also was not a huge fan of the leaky abstraction we had with the nested
creates not accepting "pure" types...

Settled on making the following change:
[code block]

Verified that the diagnostic warning in stainless goes away (these ymls are live)
```

When in doubt, **shorter**. I'd rather a one-line subject with no body than a verbose explanation of something the diff already makes clear.

## Branches

Format: `ctotheameron/<stack-feature>/<specific-change>`

- `ctotheameron` — my personal prefix, always (matches my graphite config).
- `<stack-feature>` — short kebab-case name for the umbrella the stack delivers (e.g. `rest-e2e`, `oauth-org-binding`, `directory-create-many`). Shared across every branch in the same graphite stack.
- `<specific-change>` — short kebab-case name for what *this* branch does within the stack (e.g. `share-oauth-secret-helpers`, `scaffold-contacts`, `wire-rest-handler`).

Single-PR (non-stacked) work can use `ctotheameron/<short-change-name>` (one segment) — common in my older branches like `ctotheameron/feat-authorize-sole-grant`. Prefer the two-segment form whenever there's any chance of follow-up PRs.

### Graphite

- My graphite branch-prefix config is `ctotheameron` (no trailing slash). `gt create <name>` literally concatenates them, with no separator insertion (a leading slash on the arg is stripped before concatenation), so:
  - **Wrong**: `gt create caustgen/foo` → produces `ctotheameroncaustgen/foo`
  - **Wrong**: `gt create /rest-e2e/foo` → produces `ctotheameronrest-e2e/foo` (slash gets eaten)
  - **Works reliably**: `gt create <stack-feature>/<specific-change>` then `gt rename ctotheameron/<stack-feature>/<specific-change>` to fix the prefix in one step. `gt rename` takes the full final name verbatim.
  - I should always `git rev-parse --abbrev-ref HEAD` after `gt create` to verify the resulting branch name, and rename if graphite mangled it.
- One commit per branch in a stack. Use `gt create -m "subject" -m "body" --no-ai --quiet` to take staged changes into a fresh stacked branch with a fixed message (no editor / no AI rename).
- Stage files explicitly per branch (`git add <paths>`) instead of `gt create -a` so the chunking is intentional.
- `gt submit --stack` only after I've eyeballed `gt log --stack`.
