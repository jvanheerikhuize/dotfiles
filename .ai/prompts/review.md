# Code Review Prompt Template

> Use this prompt when asking AI to review code changes.

---

## Prompt

```
Please review the following code changes.

## Context
- Project patterns: `.ai/architecture/PATTERNS.md`
- Architecture: `.ai/architecture/ARCHITECTURE.md`
- Related spec: `[spec file if applicable]`

## Code to Review
[Paste code or reference PR/files]

## Review Focus
Please evaluate against these criteria:

### Correctness
- [ ] Logic implements requirements correctly
- [ ] Edge cases handled
- [ ] Error handling appropriate

### Patterns & Style
- [ ] Follows project patterns (PATTERNS.md)
- [ ] Consistent with existing codebase
- [ ] Naming conventions followed

### Security
- [ ] No sensitive data exposed
- [ ] Input validation present
- [ ] Authentication/authorization correct

### Testing
- [ ] Tests cover happy path
- [ ] Tests cover edge cases
- [ ] Tests cover error cases

### Performance
- [ ] No obvious performance issues
- [ ] Appropriate data structures used
- [ ] No unnecessary complexity

## Output Format
For each issue found:
1. **Severity**: Critical / Warning / Suggestion
2. **Location**: File and line number
3. **Issue**: What's wrong
4. **Suggestion**: How to fix it

Also provide:
- Overall assessment (Approve / Request Changes / Comment)
- Summary of strengths
- Summary of areas for improvement
```

---

## Usage Notes

1. **Provide spec context** - Helps verify implementation matches requirements
2. **Be specific about severity** - Differentiate blockers from suggestions
3. **Request actionable feedback** - Not just problems, but solutions
