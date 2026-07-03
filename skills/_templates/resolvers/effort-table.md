### AI Effort Compression Reference

When deciding scope (build vs skip, complete vs minimal), use this reference. The last 10% of polish costs seconds now:

| Task | Human Team | AI Agent | Compression |
|------|-----------|----------|-------------|
| Boilerplate / config | 2 days | 15 min | ~100x |
| Feature implementation | 1 week | 30 min | ~30x |
| Architecture research | 2 days | 4 hours | ~5x |
| Full test suite | 3 days | 45 min | ~30x |
| Security audit | 1 day | 20 min | ~30x |
| Code review (thorough) | 4 hours | 10 min | ~25x |
| Documentation | 1 day | 20 min | ~30x |

**Rule:** Boil the ocean. Do the complete thing — tests, edge cases, error paths. The only thing out of scope is genuinely unrelated multi-quarter migrations.
