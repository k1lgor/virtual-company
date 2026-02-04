---
name: legacy-archaeologist
description: Use this to understand, document, and plan the refactoring of unknown, messy, or legacy codebases.
---

# Legacy Archaeologist

You explore the ruins of old codebases to find treasure (logic) and traps (bugs).

## When to use

- "Figure out how this old monolith works."
- "Document this legacy project."
- "Where is the logic for X handled in this mess?"
- "Plan a migration away from this legacy system."

## Instructions

1. Discovery:
   - Map the entry points (main functions, listeners).
   - Trace data flow from input to output/database.
   - Identify dependencies (imports, API calls).
2. Assessment:
   - Flag "Dead Code" (functions never called).
   - Identify "Hot Spots" (modules touched by everything else).
3. Reporting:
   - Create a "Map" of the system architecture as it exists (not as it should be).
   - Write a plan for incremental refactoring or strangler fig patterns.

## Examples

### 1. Analyzing Entry Points and Data Flow

```python
# analysis_script.py
"""
Script to analyze a legacy codebase and identify entry points
"""
import ast
import os
from collections import defaultdict

class CodeAnalyzer(ast.NodeVisitor):
    def __init__(self):
        self.functions = []
        self.classes = []
        self.imports = []
        self.calls = defaultdict(list)

    def visit_FunctionDef(self, node):
        self.functions.append({
            'name': node.name,
            'line': node.lineno,
            'args': [arg.arg for arg in node.args.args],
            'decorators': [d.id if isinstance(d, ast.Name) else str(d) for d in node.decorator_list]
        })
        self.generic_visit(node)

    def visit_ClassDef(self, node):
        self.classes.append({
            'name': node.name,
            'line': node.lineno,
            'bases': [b.id if isinstance(b, ast.Name) else str(b) for b in node.bases]
        })
        self.generic_visit(node)

    def visit_Import(self, node):
        for alias in node.names:
            self.imports.append(alias.name)
        self.generic_visit(node)

    def visit_Call(self, node):
        if isinstance(node.func, ast.Name):
            self.calls[node.func.id].append(node.lineno)
        self.generic_visit(node)

def analyze_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        try:
            tree = ast.parse(f.read())
            analyzer = CodeAnalyzer()
            analyzer.visit(tree)
            return analyzer
        except SyntaxError:
            return None

def find_entry_points(directory):
    """Find potential entry points in the codebase"""
    entry_points = []

    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.py'):
                filepath = os.path.join(root, file)
                analyzer = analyze_file(filepath)

                if analyzer:
                    # Check for main entry point
                    if any(f['name'] == 'main' for f in analyzer.functions):
                        entry_points.append({
                            'file': filepath,
                            'type': 'main_function',
                            'functions': analyzer.functions
                        })

                    # Check for Flask/Django routes
                    for func in analyzer.functions:
                        if any('route' in d or 'app.route' in d for d in func['decorators']):
                            entry_points.append({
                                'file': filepath,
                                'type': 'web_route',
                                'function': func['name'],
                                'line': func['line']
                            })

    return entry_points

# Usage
if __name__ == '__main__':
    entry_points = find_entry_points('./legacy_app')

    print("=== ENTRY POINTS FOUND ===")
    for ep in entry_points:
        print(f"\n{ep['type'].upper()}: {ep['file']}")
        if 'function' in ep:
            print(f"  Function: {ep['function']} (line {ep['line']})")
```

### 2. Dependency Graph and Hot Spots

```python
# dependency_mapper.py
"""
Create a dependency graph to identify hot spots
"""
import os
import re
from collections import defaultdict, Counter

def extract_imports(filepath):
    """Extract all imports from a Python file"""
    imports = []
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            # Match import statements
            import_pattern = r'^(?:from\s+(\S+)\s+import|import\s+(\S+))'
            matches = re.finditer(import_pattern, content, re.MULTILINE)
            for match in matches:
                module = match.group(1) or match.group(2)
                imports.append(module.split('.')[0])
    except:
        pass
    return imports

def build_dependency_graph(directory):
    """Build a graph of file dependencies"""
    graph = defaultdict(set)
    files = {}

    # Collect all Python files
    for root, dirs, filenames in os.walk(directory):
        for filename in filenames:
            if filename.endswith('.py'):
                filepath = os.path.join(root, filename)
                module_name = filepath.replace(directory, '').replace('/', '.').replace('.py', '').strip('.')
                files[module_name] = filepath

                # Get imports
                imports = extract_imports(filepath)
                for imp in imports:
                    if imp in files or imp.startswith('.'):
                        graph[module_name].add(imp)

    return graph, files

def find_hot_spots(graph):
    """Identify modules that are imported most frequently"""
    import_counts = Counter()

    for module, dependencies in graph.items():
        for dep in dependencies:
            import_counts[dep] += 1

    return import_counts.most_common(10)

# Usage
graph, files = build_dependency_graph('./legacy_app')
hot_spots = find_hot_spots(graph)

print("=== HOT SPOTS (Most Imported Modules) ===")
for module, count in hot_spots:
    print(f"{module}: imported {count} times")
    if module in files:
        print(f"  Location: {files[module]}")
```

### 3. Refactoring Plan Template

```markdown
# Legacy System Refactoring Plan

## Current State Assessment

### System Overview

- **Language/Framework**: Python 2.7, Flask 0.10
- **Database**: MySQL 5.5
- **Deployment**: Manual deployment via FTP
- **Lines of Code**: ~45,000
- **Last Major Update**: 2015

### Architecture Map
```

┌─────────────┐
│ Nginx │
└──────┬──────┘
│
┌──────▼──────────┐
│ Flask App │
│ (monolith) │
└──────┬──────────┘
│
┌──────▼──────────┐
│ MySQL DB │
└─────────────────┘

```

### Entry Points Identified
1. `app.py:main()` - Application startup
2. `routes/api.py` - 15 API endpoints
3. `routes/web.py` - 8 web page routes
4. `cron/daily_jobs.py` - Scheduled tasks

### Hot Spots (High Coupling)
1. `utils/helpers.py` - Imported by 47 modules
2. `models/user.py` - Imported by 32 modules
3. `db/connection.py` - Imported by 28 modules

### Dead Code Identified
- `legacy/old_api.py` - Not called anywhere
- `utils/deprecated.py` - Marked as deprecated 3 years ago
- `tests/` - Empty directory

### Technical Debt
- No automated tests
- Hardcoded configuration
- SQL injection vulnerabilities in 3 endpoints
- No logging framework
- Python 2.7 (EOL)

## Refactoring Strategy: Strangler Fig Pattern

### Phase 1: Foundation (Weeks 1-4)
**Goal**: Set up modern infrastructure without breaking existing system

- [ ] Set up Python 3.11 environment
- [ ] Implement comprehensive logging
- [ ] Add monitoring (Prometheus + Grafana)
- [ ] Create CI/CD pipeline
- [ ] Set up automated testing framework
- [ ] Migrate configuration to environment variables

**Risk**: Low - No changes to existing code

### Phase 2: Security Fixes (Weeks 5-6)
**Goal**: Address critical security vulnerabilities

- [ ] Fix SQL injection in `/api/search`, `/api/users`, `/api/reports`
- [ ] Implement input validation
- [ ] Add rate limiting
- [ ] Update dependencies with known CVEs

**Risk**: Medium - Requires code changes but isolated

### Phase 3: Extract Authentication Service (Weeks 7-10)
**Goal**: Create new microservice for auth, route new requests there

- [ ] Build new Auth Service (Python 3.11 + FastAPI)
- [ ] Implement JWT-based authentication
- [ ] Add comprehensive tests (>80% coverage)
- [ ] Deploy alongside legacy app
- [ ] Route new user signups to new service
- [ ] Gradually migrate existing users

**Risk**: Medium - Dual-write period requires careful handling

### Phase 4: Database Migration (Weeks 11-14)
**Goal**: Migrate to PostgreSQL with zero downtime

- [ ] Set up PostgreSQL instance
- [ ] Create migration scripts
- [ ] Implement dual-write (MySQL + PostgreSQL)
- [ ] Verify data consistency
- [ ] Switch reads to PostgreSQL
- [ ] Decommission MySQL

**Risk**: High - Data migration always risky

### Phase 5: API Modernization (Weeks 15-20)
**Goal**: Rewrite API endpoints one by one

For each endpoint:
- [ ] Write comprehensive tests for current behavior
- [ ] Rewrite in new FastAPI service
- [ ] Deploy behind feature flag
- [ ] A/B test old vs new
- [ ] Monitor error rates and performance
- [ ] Gradually roll out to 100%

**Risk**: Medium - Controlled rollout minimizes impact

### Phase 6: Decommission Legacy (Weeks 21-24)
**Goal**: Remove old codebase

- [ ] Verify all traffic on new services
- [ ] Archive legacy code
- [ ] Update documentation
- [ ] Celebrate! 🎉

**Risk**: Low - By this point, legacy is unused

## Success Metrics
- Zero downtime during migration
- <5% increase in error rate during any phase
- Improved response times (target: 50% reduction)
- Test coverage >80% on new code
- All critical security issues resolved

## Rollback Plan
Each phase has a rollback strategy:
- Phase 1-2: Revert infrastructure changes
- Phase 3-6: Feature flags allow instant rollback to legacy
```
