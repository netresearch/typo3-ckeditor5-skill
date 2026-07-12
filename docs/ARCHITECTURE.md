# Architecture

## Overview

The typo3-ckeditor5-skill is an AI agent skill that provides expert guidance for CKEditor 5 integration in TYPO3. It follows the [Agent Skills](https://agentskills.io) open standard and delivers patterns for plugin development, RTE configuration, and CKEditor 4 to 5 migration.

## Components

### Skill Definition (`skills/typo3-ckeditor5/`)

- **SKILL.md**: Entry point loaded by AI agents. Contains trigger patterns, procedural instructions for CKEditor 5 development within TYPO3.
- **checkpoints.yaml**: Verification checkpoints for validating CKEditor 5 integration correctness.
- **references/**: Standalone reference guides:
  - `ckeditor5-architecture.md` -- CKEditor 5 gotchas that diverge from public docs (figcaption content model, view-vs-DOM element pitfall)
  - `typo3-integration.md` -- TYPO3-specific patterns (YAML presets, plugin registration, content elements)
  - `plugin-development.md` -- TYPO3 plugin wiring (bundling, registration, YAML config) plus consumable-API and jQuery-removal gotchas
  - `migration-guide.md` -- CKEditor 4 to 5 migration strategies and patterns

### Verification Scripts (`skills/typo3-ckeditor5/scripts/`)

- **verify-ckeditor5.sh**: Validates a TYPO3 project's CKEditor 5 setup (plugin registration, schema definitions, converter completeness).

### Evaluations (`evals/`)

- Skill evaluation tests validating that the skill produces correct guidance.

## Key Concepts

### CKEditor 5 Architecture in TYPO3

```
TYPO3 YAML Preset → CKEditor 5 Config → Plugin Loading → Schema + Converters → Editor UI
```

1. TYPO3 loads RTE YAML presets from `Configuration/RTE/`
2. Presets define toolbar items, heading levels, and plugin imports
3. Custom plugins register schema (model), converters (upcast/downcast), and commands
4. The editor renders based on schema rules and converter output

## Integration

- **composer.json**: Enables installation via Composer with `netresearch/composer-agent-skill-plugin`
- **CI/CD**: GitHub Actions workflows handle linting and release automation
