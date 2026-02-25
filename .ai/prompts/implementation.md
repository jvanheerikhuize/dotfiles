# Implementation Prompt Template

> Use this prompt when asking AI to implement a feature from a specification.

---

## Prompt

```
I need you to implement a feature based on the following specification.

## Project Context
- Read `.ai/CONTEXT.md` for project overview
- Follow patterns in `.ai/architecture/PATTERNS.md`
- Check existing code in `[relevant directory]` for conventions

## Specification
[Paste the spec YAML here, or reference the file]

## Requirements
1. Implement ALL acceptance criteria - no partial implementations
2. Follow existing code patterns exactly
3. Include tests for each acceptance criterion
4. Do not add features not in the spec
5. Update any necessary documentation

## Expected Output
1. Implementation code with clear file paths
2. Test code with clear file paths
3. Brief explanation of key decisions
4. Any clarifying questions before proceeding

## Questions Before Starting
- Do you need any clarification on the spec?
- Are there existing patterns you're unsure about?
- Any potential conflicts with existing code?
```

---

## Usage Notes

1. **Always include project context** - Don't assume AI remembers previous conversations
2. **Be specific about output format** - Request file paths, test locations
3. **Encourage questions** - Better to clarify upfront than refactor later
4. **Reference patterns** - Point to PATTERNS.md for consistency
