## 🐝 Sub-Agent Swarming (>5 independent files)

Sequential processing of large tasks guarantees context decay — one context window cannot hold 6+ files plus the reasoning about them.

- Tasks touching >5 independent files → dispatch parallel sub-agents, 5-8 files each.
- Give each sub-agent a self-contained brief: goal, known context, expected output format.
- Completion is push-based — do not poll in a loop.
- Never delegate the understanding ("based on your findings, fix it"). Hand over the question, or the exact change with file and line numbers.

