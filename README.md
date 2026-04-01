# 🏢 Virtual Company: Professional Claude Code Plugin

The **Virtual Company** is a state-of-the-art, high-fidelity AI development engine for [Claude Code](https://code.claude.com). It transforms your terminal into a professional engineering team with 27 domain experts, 6 strategic roles, and automated lifecycle hooks.

---

## 🏗️ 3-Tier Multi-Agent Architecture

The Virtual Company operates on three integrated layers:

1.  **🧑‍💻 Domain Experts (Skills)**: 27 specialized technical commands (`/expert-name`) for direct problem-solving across frontend, backend, infra, and data science.
2.  **🤝 Strategic Roles (Agents)**: 6 native subagents (`Agent(name, "task")`) for complex multi-phase delegation (Planner, Architect, Tech-Lead).
3.  **🪄 Lifecycle Logic (Hooks)**: Automated quality enforcement, auto-linting on save, and professional session initialization.

---

## 🚀 Installation & Usage

### 📦 Install from Marketplace

The easiest way to install the Virtual Company is via the official Marketplace:

1.  **Add Marketplace** (uses GitHub `owner/repo` shorthand):
    ```bash
    /plugin marketplace add k1lgor/virtual-company
    ```
2.  **Install Plugin** (use the plugin name `virtual-company`, not the GitHub path):
    ```bash
    /plugin install virtual-company
    ```

> **Note:** Step 1 registers the marketplace using the GitHub shorthand `k1lgor/virtual-company`. Step 2 installs the plugin by its name (`virtual-company`) as defined inside the marketplace. Running `/plugin install k1lgor/virtual-company` will fail because `k1lgor/virtual-company` is the repository path, not the plugin name.

### 🛠️ Manual Installation (Developers)

Clone the repository and install directly from the local path:

```bash
/plugin install --path /path/to/virtual-company
```

---

## 👥 Meet Your Virtual Team

### Strategic Roles (Native Agents)

Invoke these roles for isolated, high-effort architectural or planning tasks:

| Role            | Expertise      | Primary Focus                                            |
| :-------------- | :------------- | :------------------------------------------------------- |
| **planner**     | Strategy       | Milestones, task decomposition, and quality gates.       |
| **architect**   | Design         | System architecture, ADRs, and schema definitions.       |
| **tech-lead**   | Implementation | Coordination, code standards, and technical delivery.    |
| **reviewer**    | Audit          | Peer review, maintainability, and naming standards.      |
| **security**    | Protection     | Vulnerability scanning and risk mitigation.              |
| **qa-engineer** | Verification   | Automated testing, E2E validation, and bug reproduction. |

### Domain Experts (Direct Commands)

Invoke these skills using individual slash commands:

| Category           | experts                                                                                                |
| :----------------- | :----------------------------------------------------------------------------------------------------- |
| **Orchestration**  | `tech-lead`, `product-manager`, `workflow-orchestrator`, `skill-generator`                             |
| **Logic**          | `backend-architect`, `api-designer`, `data-engineer`, `ml-engineer`                                    |
| **Frontend**       | `frontend-architect`, `ux-designer`, `mobile-architect`                                                |
| **Quality**        | `bug-hunter`, `test-genius`, `security-reviewer`, `e2e-test-specialist`                                |
| **Infrastructure** | `infra-architect`, `docker-expert`, `k8s-orchestrator`, `ci-config-helper`, `observability-specialist` |
| **Analysis**       | `search-vector-architect`, `legacy-archaeologist`, `data-analyst`                                      |
| **Maintenance**    | `migration-upgrader`, `code-polisher`, `doc-writer`                                                    |

---

## 🪄 Automated Workflows

The Virtual Company plugin is context-aware and acts autonomously:

- **Welcome Greeting**: Auto-initializes your professional profile at session start.
- **Auto-Refinement**: Triggers a linting/formatting pass after every file edit.
- **Expert Discovery**: All 27 commands are automatically mapped and namespaced for discovery.

---

## 📂 Project Structure

```text
virtual-company/
├── agents/             # 6 Native Role Agents
├── hooks/              # Automated Lifecycle Hooks
├── skills/             # 27 Specialized Domain Expert Skills
├── .claude-plugin/     # Plugin & Marketplace Manifests
└── docs/plans/         # Recommended Task Tracking Location
```

---

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=k1lgor/virtual-company&type=date&legend=top-left)](https://www.star-history.com/#k1lgor/virtual-company&type=date&legend=top-left)

## License

MIT © Plamen Ivanov
