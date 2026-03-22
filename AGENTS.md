# TYPO3 CKEditor 5 Skill

Expert patterns for CKEditor 5 integration in TYPO3: custom plugin development, RTE configuration, and CKEditor 4 to 5 migration.

## Repo Structure

```
typo3-ckeditor5-skill/
├── skills/typo3-ckeditor5/      # Skill definition and references
│   ├── SKILL.md                 # Skill metadata and trigger patterns
│   ├── checkpoints.yaml         # Verification checkpoints
│   ├── scripts/                 # Verification scripts
│   └── references/              # Reference guides (architecture, integration, migration)
├── evals/                       # Skill evaluation tests
├── Build/                       # Build utilities
├── .github/workflows/           # CI (lint.yml, release.yml, auto-merge-deps.yml)
├── composer.json                # PHP package definition
└── docs/                        # Architecture and planning docs
    └── ARCHITECTURE.md          # Architecture overview
```

## Commands

No Makefile or build scripts defined. Key operations:

- Install PHP dependencies: run `composer` with `install`
- Verify CKEditor 5 setup: `bash skills/typo3-ckeditor5/scripts/verify-ckeditor5.sh`
- Verify harness maturity: `bash scripts/verify-harness.sh --format=text --status`

## Rules

- CKEditor 5 plugins must follow the Plugin class pattern (extend Plugin base class)
- Schema definitions are mandatory for custom model elements (allowAttributes, allowIn)
- Converters must be registered for both upcast (view-to-model) and downcast (model-to-view)
- TYPO3 RTE configuration uses YAML presets under `Configuration/RTE/`
- Custom plugins must be registered via `ext_localconf.php` using `$GLOBALS['TYPO3_CONF_VARS']`
- ES6 module syntax is required (no AMD/CommonJS)
- CKEditor 4 to 5 migration requires complete plugin rewrite (no compatibility layer)

## References

- [SKILL.md](skills/typo3-ckeditor5/SKILL.md) -- skill definition and trigger patterns
- [checkpoints.yaml](skills/typo3-ckeditor5/checkpoints.yaml) -- verification checkpoints
- [references/](skills/typo3-ckeditor5/references/) -- architecture, integration, plugin dev, migration guides
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) -- architecture overview
