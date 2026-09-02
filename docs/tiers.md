# Reversibility tiers

The classifier reads this file. `scripts/tier-from-paths.sh` encodes the
path rules below; change both together. Both are code-owned.

| Tier | Definition                              | Authority                                  |
|------|-----------------------------------------|--------------------------------------------|
| T0   | Reversible by revert alone              | Agent opens and merges on green            |
| T1   | Reversible by revert plus a deploy      | Agent implements; a human approves         |
| T2   | Reversible with a compensating action   | Human plans; agent implements; human ships |
| T3   | Not reversible                          | Humans. Agent may draft only.              |

## Paths that fix a floor

| Path                                   | Minimum tier |
|----------------------------------------|--------------|
| `migrations/`, `db/`                   | T3           |
| `src/auth/`, `src/billing/`            | T3           |
| `openapi.yaml`, `src/api/contracts/`   | T2           |
| `tests/`, `.github/`                   | T1           |

Anything the classifier cannot place is T3. A path raises a tier and
never lowers one.
