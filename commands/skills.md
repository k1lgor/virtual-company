---
name: skills
description: List and analyze all available agent skills in the Virtual Company plugin
aliases: [list-skills, show-skills, expertise]
---

# Skills Command

List all available agent skills with their descriptions and use cases.

## Usage

```
/virtual-company:skills
/virtual-company:skills [filter]
/virtual-company:skills --category [category]
```

## Examples

**List all skills:**

```
/virtual-company:skills
```

**Filter by keyword:**

```
/virtual-company:skills testing
```

**Show skills by category:**

```
/virtual-company:skills --category architecture
```

**Search for specific domain:**

```
/virtual-company:skills data
```

## Output

The command will analyze the `skills/` directory and provide:

1. Total number of skills available
2. Skill ID and name
3. Brief description from SKILL.md
4. When to use it
5. Related skills (if applicable)
6. Category grouping

## Categories

Skills are organized into the following categories:

- **Core Development**: doc-writer, bug-hunter, test-genius, code-polisher
- **Security & Performance**: security-reviewer, performance-profiler
- **Architecture**: frontend-architect, backend-architect, api-designer, mobile-architect
- **Data & ML**: data-engineer, data-analyst, ml-engineer, search-vector-architect
- **DevOps & Infrastructure**: docker-expert, k8s-orchestrator, infra-architect, ci-config-helper, observability-specialist
- **Product & Design**: ux-designer, product-manager
- **Testing**: e2e-test-specialist, test-genius
- **Orchestration**: workflow-orchestrator, tech-lead
- **Maintenance**: migration-upgrader, legacy-archaeologist
- **Meta**: skill-generator

## Implementation

Analyze the contents of the `skills/` directory and provide a structured list of available agent skills. For each skill:

1. **Parse the SKILL.md frontmatter** to extract:
   - Skill name
   - Description

2. **Read the "When to use" section** to understand use cases

3. **Format the output** as a table or structured list:

   ```
   ID  | Skill Name              | Description                           | Category
   ----|-------------------------|---------------------------------------|-------------
   00  | tech-lead               | Complex project planning              | Orchestration
   01  | doc-writer              | Documentation and comments            | Core Dev
   ...
   ```

4. **If a filter is provided**, only show matching skills

5. **If a category is specified**, group by category and show only that category

6. **Include helpful tips** such as:
   - "Use /apply [skill-name] to activate a skill"
   - "Combine multiple skills for complex tasks"
   - "See /skill-info [name] for detailed information"
