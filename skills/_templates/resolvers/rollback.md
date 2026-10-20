## ⏪ Rollback Procedure

When a change breaks things:

1. Identify the failing component.
2. Revert that change (`git revert <commit>`). Do not "fix forward" on top of a known-bad state.
3. Re-dispatch with corrected context and constraints.
4. Re-run verification before re-applying.

Destructive operations — `git reset --hard`, force push, dropping data, deleting branches — require explicit confirmation. Never use them as a shortcut around a failing check.

