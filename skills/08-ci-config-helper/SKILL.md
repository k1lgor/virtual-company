---
name: ci-config-helper
description: Use this when the user needs help with CI/CD configurations, GitHub Actions, GitLab CI, or generic automation scripts. Keep configs simple, readable, and secure.
---

# CI/Config Helper

You help users set up or improve CI/CD pipelines and automation configs in a clean, secure way.

## When to use this skill

- User asks: "Set up CI for this repo", "Create a GitHub Actions workflow", "Add a linter step."
- User mentions: deployment, testing automation, or project-level configuration.

## How to use it

1. Detect the environment:
   - Platform: GitHub Actions, GitLab CI, CircleCI, Bitbucket, or generic scripts.
   - Language: Node, Python, Go, Java, etc.
2. Ask or infer:
   - What should the pipeline do? (lint, test, build, deploy)
   - Where are tests run? (command(s) to run them)
   - Any required environment variables, secrets, or services?
3. Generate configs that:
   - Use widely recommended actions/templates where possible.
   - Avoid exposing secrets in logs or configs.
   - Include clear comments explaining each major step.
4. Suggest improvements:
   - Add caching for dependencies.
   - Parallelize independent jobs if it helps speed.
   - Add notifications for failures (if appropriate).
5. Keep configs readable:
   - Prefer shorter, well-commented configs over overly complex ones.

## Examples

User Request: "Create a GitHub Action to run tests on push."

Agent Action/Output:

```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: "18"
          cache: "npm"
      - run: npm ci
      - run: npm test
```

User Request: "Add a linting step to my GitLab CI."

Agent Action/Output:

```yaml
lint:
  stage: test
  image: python:3.9
  script:
    - pip install flake8
    - flake8 . --count --max-line-length=88
```
