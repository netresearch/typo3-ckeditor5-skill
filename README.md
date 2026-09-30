<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
<!-- SPDX-FileCopyrightText: Netresearch DTT GmbH -->

# TYPO3 CKEditor 5 Development Skill

Expert patterns for CKEditor 5 integration in TYPO3, including custom plugin development, configuration, and migration from CKEditor 4.

## 🔌 Compatibility

This is an **Agent Skill** following the [open standard](https://agentskills.io) originally developed by Anthropic and released for cross-platform use.

**Supported Platforms:**
- ✅ Claude Code (Anthropic)
- ✅ Cursor
- ✅ GitHub Copilot
- ✅ Other skills-compatible AI agents

> Skills are portable packages of procedural knowledge that work across any AI agent supporting the Agent Skills specification.


## Features

- **CKEditor 5 Architecture**: Plugin system, schema and conversion system, command pattern implementation, UI component development
- **TYPO3 Integration**: RTE configuration (YAML), custom plugin registration, content element integration, backend module integration
- **Migration Patterns**: CKEditor 4 to 5 migration, custom plugin conversion, configuration transformation, data migration strategies
- **Plugin Development**: Complete patterns for creating custom CKEditor 5 plugins with schema definitions, converters, and commands
- **Configuration Management**: YAML-based RTE presets with toolbar, heading, table, and link configurations
- **ES6 Module Development**: Modern JavaScript patterns for CKEditor 5 plugin architecture

## Installation

### Marketplace (Recommended)

Add the [Netresearch marketplace](https://github.com/netresearch/claude-code-marketplace) once, then browse and install skills:

```bash
# Claude Code
/plugin marketplace add netresearch/claude-code-marketplace
/plugin install typo3-ckeditor5@netresearch-claude-code-marketplace
```

### Without a marketplace

Since Claude Code 2.1.157 a plugin directory under your personal skills directory loads on its own:

```bash
mkdir -p ~/.claude/skills
git clone https://github.com/netresearch/typo3-ckeditor5-skill.git \
  ~/.claude/skills/typo3-ckeditor5
```

It loads as `typo3-ckeditor5@skills-dir` on the next session. Update with `git -C ~/.claude/skills/typo3-ckeditor5 pull` and start a new session; remove it by deleting the directory. This route has no `claude plugin update`.

### npx ([skills.sh](https://skills.sh))

Install with any [Agent Skills](https://agentskills.io)-compatible agent:

```bash
npx skills add https://github.com/netresearch/typo3-ckeditor5-skill --skill typo3-ckeditor5
```

### Download Release

Download the [latest release](https://github.com/netresearch/typo3-ckeditor5-skill/releases/latest) and extract to your agent's skills directory.

### Git Clone

```bash
git clone https://github.com/netresearch/typo3-ckeditor5-skill.git
```

### Composer (PHP Projects)

```bash
composer require netresearch/typo3-ckeditor5-skill
```

Requires [netresearch/composer-agent-skill-plugin](https://github.com/netresearch/composer-agent-skill-plugin).
## Usage

This skill is automatically triggered when:

- Developing custom CKEditor 5 plugins for TYPO3
- Configuring RTE presets in TYPO3 v12+
- Integrating CKEditor with TYPO3 backend modules
- Migrating from CKEditor 4 to CKEditor 5
- Working with CKEditor 5 schema, conversion, or command patterns

Example queries:
- "Create a custom CKEditor 5 plugin for TYPO3"
- "Configure RTE preset with custom toolbar"
- "Migrate CKEditor 4 plugin to CKEditor 5"
- "Implement custom element with schema and converters"

## Structure

```
typo3-ckeditor5-skill/
├── skills/typo3-ckeditor5/
│   ├── SKILL.md                          # Skill metadata and core patterns
│   ├── checkpoints.yaml                  # CK-XX checkpoints for assessment tools
│   ├── references/
│   │   ├── ckeditor5-architecture.md     # CKEditor 5 gotchas (figcaption, view vs DOM)
│   │   ├── typo3-integration.md          # TYPO3-specific integration patterns
│   │   ├── plugin-development.md         # TYPO3 plugin wiring and gotchas
│   │   └── migration-guide.md            # CKEditor 4 to 5 migration
│   └── scripts/
│       └── verify-ckeditor5.sh           # Verification script
├── tests/                                # Behavioural tests for the scripts
├── evals/                                # Skill evaluation suite and A/B runner
├── Build/                                # Version check and pre-push hook
└── docs/                                 # Architecture and security assurance case
```

## Expertise Areas

### CKEditor 5 Architecture
- Plugin system and architecture
- Schema and conversion system
- Command pattern implementation
- UI component development

### TYPO3 Integration
- RTE configuration (YAML)
- Custom plugin registration
- Content element integration
- Backend module integration

### Migration Patterns
- CKEditor 4 to 5 migration
- Custom plugin conversion
- Configuration transformation
- Data migration strategies

## Related Skills

- **typo3-extension-upgrade-skill**: References this skill for RTE migration
- **php-modernization-skill**: Modern PHP patterns for backend integration

## Contributing

Open issues and pull requests on [GitHub](https://github.com/netresearch/typo3-ckeditor5-skill). The commands for working on this repository are listed in [AGENTS.md](AGENTS.md#commands). A pull request that adds or changes behaviour in a script adds or updates a check in `tests/` that fails without the change.

### Tests

The behavioural tests live in `tests/` and run offline; they need bash, git, find, grep and python3:

```bash
bash tests/verify-ckeditor5.sh      # skills/typo3-ckeditor5/scripts/verify-ckeditor5.sh
bash tests/check-plugin-version.sh  # Build/Scripts/check-plugin-version.sh and Build/hooks/pre-push
```

- `tests/verify-ckeditor5.sh` builds fixture extension directories (empty, complete, with empty configuration directories, with a weak preset and plugin, with CKEditor 4 remnants, with a file name containing a space) and checks the verifier's exit code, that every section runs, the individual findings and the exact warning count.
- `tests/check-plugin-version.sh` builds throwaway git repositories and checks that a semver tag at `HEAD` must match the version in `.claude-plugin/plugin.json`, and that the pre-push hook passes the result on.

Each check prints `ok` or `FAIL`; a `FAIL` line names the expectation that was not met and is followed by the script's output. A test file exits 1 when any check failed. In CI, the Skill Tests workflow (`.github/workflows/tests.yml`) runs every `tests/**/*.sh` on each pull request and on pushes to `main`, and fails when the repository ships scripts under `skills/*/scripts/` but no test ran.

The skill's Markdown is not executed. Skill Validation checks its structure, and Eval Validation checks the eval definitions in `evals/evals.json`. `evals/run-ab-test.sh`, which runs those evals against a model through the `claude` CLI, costs money per run and is not run in CI. `pre-commit run --all-files` runs the hooks of [`.pre-commit-config.yaml`](.pre-commit-config.yaml) locally.

### Dependencies

- **Composer:** `composer.json` requires `netresearch/composer-agent-skill-plugin` (`*`, the latest release at install time), which installs the skill into a PHP project. No `composer.lock` is committed (`.gitignore`).
- **Scripts:** `verify-ckeditor5.sh` needs bash, `find`, `grep`, `wc` and `basename`; `check-plugin-version.sh` needs git and python3. Nothing is installed by them.
- **Development tools:** the hooks in `.pre-commit-config.yaml` are pinned by `rev:`. Renovate ([`renovate.json`](renovate.json), `config:recommended` with the pre-commit manager enabled) proposes updates for them. The Composer requirement has no version range and no lock file, so there is nothing for it to update.
- **CI:** the workflows call reusable workflows of `netresearch/.github`, `netresearch/skill-repo-skill` and `netresearch/typo3-ci-workflows`; those reusables pin the actions they use by commit SHA.

## Governance and policies

This repository follows the Netresearch organisation policies:

- [Governance](https://github.com/netresearch/.github/blob/main/GOVERNANCE.md): ownership, roles, how decisions are made and disputes resolved, and continuity.
- [Roadmap](https://github.com/netresearch/.github/blob/main/ROADMAP.md): planned and explicitly excluded work for the coming year.
- [Handling of dependency and code analysis findings](https://github.com/netresearch/.github/blob/main/SECURITY.md#handling-of-dependency-and-code-analysis-findings): thresholds, deadlines and the exception process for dependency (SCA) and static analysis (SAST) findings.
- [Secret management](https://github.com/netresearch/.github/blob/main/SECURITY.md#secret-management): how CI and release credentials are stored, accessed and rotated.
- [Access roster](https://github.com/netresearch/.github/blob/main/docs/access-roster.md): who holds administrative access to this repository and the organisation.

The security assurance case for this skill (threat model, trust boundaries, countermeasures and limits) is in [docs/SECURITY-ASSURANCE.md](docs/SECURITY-ASSURANCE.md).

Checks that run on pull requests in this repository:

- Every pull request: Skill Validation (`lint.yml`: skill structure, markdownlint, yamllint, actionlint, JSON syntax, ShellCheck, ruff, checkpoint schema), Eval Validation (`eval-validate.yml`) and Skill Tests (`tests.yml`).
- Pull requests to `main`: `security.yml` with Betterleaks (secret scanning), zizmor (workflow static analysis), dependency review (fails on vulnerabilities of severity high or above), Composer Audit and Opengrep SAST (fails on findings of severity WARNING or above); Harness Verification (`harness-verify.yml`) and Template Drift (`check-template-drift.yml`).

## License

This project uses split licensing:

- **Code** (scripts, workflows, configs): [MIT](LICENSE-MIT)
- **Content** (skill definitions, documentation, references): [CC-BY-SA-4.0](LICENSE-CC-BY-SA-4.0)

See the individual license files for full terms.
## Credits

Developed and maintained by [Netresearch DTT GmbH](https://www.netresearch.de/).

---

**Made with ❤️ for Open Source by [Netresearch](https://www.netresearch.de/)**
