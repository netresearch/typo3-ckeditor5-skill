<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
<!-- SPDX-FileCopyrightText: Netresearch DTT GmbH -->

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

- **verify-ckeditor5.sh**: Reads a TYPO3 extension directory (default: the current directory) and reports, by file presence and text search: RTE YAML presets and their `editor`, `processing` and toolbar sections, CKEditor JavaScript files (ES module imports, exports, `Plugin`/`Command` classes), stylesheets, preset and plugin registration in `ext_localconf.php`, RTE fields in TCA, CKEditor 4 remnants, and documentation. It does not parse YAML or JavaScript, so it cannot check schema definitions or converters. A missing `ext_localconf.php` is an error and makes it exit 1, matching checkpoint CK-01 (severity `error`); every other finding is a warning or information, and with no error it exits 0.

### Evaluations (`evals/`)

- `evals.json`: prompts with content assertions, validated by the Eval Validation workflow.
- `run-ab-test.sh`: runs each prompt through the `claude` CLI with and without the skill and compares the assertions. It calls a paid model API and is not run in CI.

### Tests (`tests/`)

- Behavioural tests for `verify-ckeditor5.sh`, `Build/Scripts/check-plugin-version.sh` and `Build/hooks/pre-push`, run by `.github/workflows/tests.yml`.

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
- **CI/CD**: GitHub Actions workflows in `.github/workflows/` validate the skill and lint (`lint.yml`), validate the evals (`eval-validate.yml`), run the tests (`tests.yml`), scan for secrets, workflow issues, vulnerable dependencies and insecure code (`security.yml`), check the agent harness and template drift, score the repository with OpenSSF Scorecard, and publish signed releases (`release.yml`)
