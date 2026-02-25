# Project Context

> **For AI Assistants**: This is the master context file. Start here for a complete understanding of the project.

<!--
  AI PROCESSING INSTRUCTIONS:
  1. Read this file first to understand project scope
  2. Follow links to detailed documents as needed
  3. Check config.yaml for behavior preferences
  4. Respect patterns in architecture/PATTERNS.md
-->

## Quick Reference

| Document | Purpose | When to Read |
|----------|---------|--------------|
| [SPEC.md](specs/SPEC.md) | Product requirements | Understanding WHAT to build |
| [ARCHITECTURE.md](architecture/ARCHITECTURE.md) | System design | Understanding HOW it's built |
| [PATTERNS.md](architecture/PATTERNS.md) | Code conventions | Writing or reviewing code |
| [decisions/](decisions/) | ADRs | Understanding WHY decisions were made |

---

## 1. Project Summary

<!-- Fill this section with your project's key information -->

### Identity
- **Name**: [Project Name]
- **Type**: [Web App | API | Library | CLI | etc.]
- **Stage**: [Greenfield | MVP | Growth | Mature]

### One-Liner
> [One sentence describing what this project does and for whom]

### Tech Stack
| Layer | Technology |
|-------|------------|
| Language | [TypeScript, Python, Go, etc.] |
| Framework | [Next.js, FastAPI, etc.] |
| Database | [PostgreSQL, MongoDB, etc.] |
| Infrastructure | [AWS, GCP, Vercel, etc.] |

---

## 2. Current State

### Active Work
<!-- What's being worked on right now? -->
- [ ] [Current feature/task 1]
- [ ] [Current feature/task 2]

### Recent Changes
<!-- What changed recently that AI should know about? -->
- [Date]: [Change description]
- [Date]: [Change description]

### Known Issues
<!-- Problems AI should be aware of -->
- [Issue 1]: [Brief description]
- [Issue 2]: [Brief description]

---

## 3. Key Concepts

### Domain Model
<!-- Core entities and their relationships -->
```
[User] ──1:N── [Account] ──1:N── [Resource]
```

### Bounded Contexts
<!-- If using DDD, list bounded contexts -->
| Context | Responsibility | Key Entities |
|---------|---------------|--------------|
| [Context 1] | [What it handles] | [Entities] |

### Critical Paths
<!-- Most important user journeys -->
1. **[Path Name]**: [Step 1] → [Step 2] → [Step 3]
2. **[Path Name]**: [Step 1] → [Step 2] → [Step 3]

---

## 4. Codebase Navigation

### Entry Points
| Purpose | Location |
|---------|----------|
| Application start | `src/index.ts` |
| API routes | `src/api/routes/` |
| Main business logic | `src/services/` |
| Configuration | `src/config/` |

### Key Files
<!-- Files AI should prioritize reading -->
```
src/
├── index.ts              # Application entry
├── config/index.ts       # Configuration
├── services/
│   └── [core].service.ts # Core business logic
└── models/
    └── [main].model.ts   # Main domain model
```

### Module Map
<!-- How major modules relate -->
```
[API Layer] → [Service Layer] → [Repository Layer] → [Database]
     ↓              ↓                  ↓
[Validators]   [Domain Models]   [Query Builders]
```

---

## 5. Development Rules

### Must Follow
<!-- Non-negotiable rules -->
1. **All code must have tests** - No exceptions for business logic
2. **Use existing patterns** - Check PATTERNS.md before creating new ones
3. **No secrets in code** - Use environment variables
4. **Spec before code** - Features require approved specs

### Prefer
<!-- Strong preferences -->
1. Composition over inheritance
2. Explicit over implicit
3. Small functions (< 20 lines)
4. Descriptive names over comments

### Avoid
<!-- Anti-patterns and practices to avoid -->
1. God classes/functions
2. Deep nesting (> 3 levels)
3. Magic numbers/strings
4. Mutable global state

---

## 6. Testing Requirements

### Coverage Expectations
| Type | Target | Focus |
|------|--------|-------|
| Unit | 80% | Services, utilities |
| Integration | Key paths | API endpoints |
| E2E | Critical flows | User journeys |

### Test Locations
```
tests/
├── unit/           # src/__tests__/ also acceptable
├── integration/
└── e2e/
```

---

## 7. Environment Setup

### Prerequisites
```bash
# Required tools
[tool1] >= [version]
[tool2] >= [version]
```

### Quick Start
```bash
# Clone and setup
git clone [repo-url]
cd [project]
[install command]
[setup command]
[run command]
```

### Environment Variables
| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | Database connection string |
| `API_KEY` | Yes | External service API key |
| `DEBUG` | No | Enable debug logging |

---

## 8. AI Assistant Guidelines

### When Generating Code
1. **Read before writing** - Understand existing patterns first
2. **Match style** - Follow PATTERNS.md conventions
3. **Minimal changes** - Don't refactor unrelated code
4. **Include tests** - Generate tests alongside implementation

### When Answering Questions
1. **Reference files** - Point to specific code locations
2. **Cite architecture** - Link to relevant ADRs
3. **Stay current** - Check "Recent Changes" above

### When Debugging
1. **Check known issues** - Review section above first
2. **Trace data flow** - Follow the module map
3. **Verify assumptions** - Read actual implementation

### Forbidden Actions
<!-- Things AI should never do -->
- Delete or modify test files without explicit request
- Change security-related code without review
- Modify configuration files without confirmation
- Add dependencies without discussion

---

## 9. Related Documentation

### Internal
- [specs/](specs/) - Product specifications
- [architecture/](architecture/) - Technical architecture
- [decisions/](decisions/) - Architecture Decision Records

### External
- [Design System]([link])
- [API Documentation]([link])
- [Runbook]([link])

---

## 10. Contacts

| Role | Contact | When to Escalate |
|------|---------|-----------------|
| Tech Lead | @[username] | Architecture decisions |
| Product | @[username] | Requirement clarifications |
| Security | @[username] | Security concerns |

---

## Document Maintenance

| Field | Value |
|-------|-------|
| Last Updated | YYYY-MM-DD |
| Update Frequency | Weekly / After major changes |
| Owner | [Team/Person] |

### Update Checklist
When updating this document:
- [ ] Update "Current State" section
- [ ] Review "Key Files" for accuracy
- [ ] Check "Known Issues" is current
- [ ] Verify links are working
