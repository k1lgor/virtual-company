# Virtual Company

This repository contains a collection of **Agent Skills**—standardized, specialized sets of instructions and workflows designed to enhance AI agents (like Claude Code, Codex, Kimi CLI, and Gemini CLI, etc.) with domain-specific expertise.

## Project Structure

```text
virtual-company/
├── .claude-plugin/
│   ├── plugin.json           # Plugin manifest with metadata
│   └── marketplace.json      # Marketplace catalog configuration
├── commands/
│   └── skills.md             # /virtual-company:skills command
└── skills/                   # 27 specialized agent skills
    ├── 00-tech-lead/
    ├── 01-doc-writer/
    ├── 02-bug-hunter/
    ├── ...
    └── 26-skill-generator/
```

Each skill folder contains a `SKILL.md` file which provides the agent with its identity, tools, and workflow for a specific domain. All skills include:

- **Frontmatter**: Name and description
- **When to use**: Example use cases
- **Instructions**: Step-by-step guidelines
- **Examples**: Practical code samples

## 🚀 Claude Code Plugin & Marketplace

This repository is now a fully-featured **Claude Code Plugin** and includes its own **Marketplace** catalog.

### Installation

To install these skills as a plugin in Claude Code:

1. **Add the Marketplace**:
   ```bash
   /plugin marketplace add virtual-company https://github.com/k1lgor/virtual-company
   ```
2. **Install the Plugin**:
   ```bash
   /plugin install virtual-company
   ```

### Plugin Features

The Virtual Company plugin includes:

- **27 Expert Skills**: Complete coverage across development, architecture, testing, DevOps, and data engineering
- **Smart Commands**: Use `/virtual-company:skills` to list and filter available skills
- **Rich Metadata**: Categorized skills with comprehensive keywords for easy discovery
- **MIT Licensed**: Free to use and modify
- **Active Maintenance**: Regular updates with new skills and improvements

### Available Commands

Once installed, you can use these commands:

```bash
# List all available skills
/virtual-company:skills

# Filter skills by keyword
/virtual-company:skills testing

# Show skills by category
/virtual-company:skills --category architecture

# Alternative aliases
/list-skills
/show-skills
```

---

## ⚡ Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/k1lgor/virtual-company.git
   cd virtual-company
   ```
2. **Setup your favorite CLI**: Follow the guides below (Claude, Codex, Kimi, etc.) to link these skills.
3. **Verify**: Ask your AI agent to list its available skills or to "Apply the `tech-lead` persona."

---

## Setup Guide for AI CLIs

To use these skills with your favorite AI terminal assistant, follow the setup instructions below.

### 🤖 Claude Code (Anthropic)

Claude Code supports **Agent Skills** globally and per-project.

1. **Install**: `npm install -g @anthropic-ai/claude-code`
2. **Global Skills**: Copy skills to `~/.claude/skills/`
3. **Project Context**: Use a `CLAUDE.md` file in your project root for unified instructions.
4. **Usage**: Claude automatically detects skills by their description in `SKILL.md`.

### 🧠 Codex CLI (OpenAI)

Codex CLI uses a dedicated skills directory for custom workflows.

1. **Install**: `npm install -g @openai/codex`
2. **Setup**: Symlink skills to `~/.codex/skills/`
   ```bash
   ln -s /path/to/virtual-company/.agent/skills/ ~/.codex/skills
   ```
3. **Usage**: Access skills via `/skills list` in the interactive terminal.

### 🌒 Kimi CLI (Moonshot AI)

Kimi is highly compatible with the `.agent` standard and supports multiple discovery paths.

1. **Install**: `uv tool install --python 3.13 kimi-cli`
2. **Global Discovery**: Checks `~/.config/agents/skills/` and `~/.claude/skills/`.
3. **Project Discovery**: Checks `.agents/skills/` or `.claude/skills/` in your project root.
4. **Usage**: Run `kimi` and it will automatically load expertise based on your task.

### ♊ Gemini CLI (Google)

Gemini CLI uses the `.gemini` or `.agent` folder to manage specialized agents.

1. **Install**: Follow the guide at [geminicli.com](https://geminicli.com).
2. **Setup**: Use `gemini skills install <path>` or symlink:
   ```bash
   ln -s skills .agent/skills
   ```
3. **Usage**: List skills with `gemini skills list`.

### 🔓 OpenCode CLI (OpenCode.ai)

OpenCode is an open-source agentic CLI that supports the `SKILL.md` format.

1. **Install**: `curl -fsSL https://opencode.ai/install | bash`
2. **Paths**: Supports `.opencode/skills/` and `.claude/skills/` paths.
3. **Usage**: Run `opencode` and use `/init` to index your project and skills.

### 🐉 Qwen Code CLI (Alibaba)

Qwen 3 Coder provides a rich agentic workflow similar to Claude Code.

1. **Install**: `npm install -g @qwen-code/qwen-code`
2. **Setup**: Point your skills directory via environment variables or default paths.
3. **Usage**: Run `qwen` to start the agentic coding environment.

### 🐙 GitHub Copilot CLI

Supports modular skills for specialized repository tasks.

1. **Setup**: Place skills in `.github/skills/` or `~/.copilot/skills/`.
2. **Usage**: Copilot will suggest using a skill when it matches your request.

---

## Available Skills

| ID  | Skill Name                 | Description                                        |
| --- | -------------------------- | -------------------------------------------------- |
| 00  | `tech-lead`                | Complex project planning and orchestration.        |
| 01  | `doc-writer`               | Generating docs, READMEs, and inline comments.     |
| 02  | `bug-hunter`               | Debugging, crash analysis, and stack trace fixing. |
| 03  | `test-genius`              | Writing unit tests and increasing coverage.        |
| 04  | `code-polisher`            | Refactoring and improving code quality.            |
| 05  | `security-reviewer`        | Security audits and vulnerability checks.          |
| 06  | `performance-profiler`     | Optimization and performance tuning.               |
| 07  | `migration-upgrader`       | Version upgrades and framework migrations.         |
| 08  | `ci-config-helper`         | CI/CD (GitHub Actions, GitLab) setup.              |
| 09  | `infra-architect`          | IaC (Terraform, CloudFormation) and Cloud setup.   |
| 10  | `api-designer`             | REST/GraphQL API design and OpenAPI specs.         |
| 11  | `data-engineer`            | SQL, ETL, and data transformation.                 |
| 12  | `frontend-architect`       | UI, Components, and Responsive Design.             |
| 13  | `backend-architect`        | Server-side logic and architecture patterns.       |
| 14  | `docker-expert`            | Dockerfiles and container orchestration.           |
| 15  | `k8s-orchestrator`         | Kubernetes manifests and Helm charts.              |
| 16  | `data-analyst`             | Data visualization and insights (Python/SQL).      |
| 17  | `mobile-architect`         | iOS/Android and Flutter/React Native dev.          |
| 18  | `ml-engineer`              | Machine learning pipelines and integrations.       |
| 19  | `observability-specialist` | Logging, tracing, and monitoring setup.            |
| 20  | `ux-designer`              | UI/UX flows and design systems.                    |
| 21  | `product-manager`          | Task breakdown and user stories.                   |
| 22  | `e2e-test-specialist`      | Playwright/Cypress end-to-end testing.             |
| 23  | `search-vector-architect`  | Vector search (RAG) and Elasticsearch.             |
| 24  | `workflow-orchestrator`    | Complex task scheduling and orchestration.         |
| 25  | `legacy-archaeologist`     | Understanding and refactoring legacy code.         |
| 26  | `skill-generator`          | Creating and debugging new SKILL.md files.         |

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=k1lgor/virtual-company&type=date&legend=top-left)](https://www.star-history.com/#k1lgor/virtual-company&type=date&legend=top-left)
