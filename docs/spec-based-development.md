# Spec-Based Development Guide

This guide explains how to use the specification-driven development workflow in this repository.

## Overview

Spec-Based Development (SBD) is a methodology where features are fully specified before implementation begins. This approach:

- Ensures clarity of requirements before coding
- Enables automated implementation via AI tools
- Creates documentation as a natural byproduct
- Reduces rework and miscommunication

### Why Spec-Based Development?

> **Rationale**: Traditional development often suffers from the "telephone game" effect—requirements get distorted as they pass from stakeholders to designers to developers. By formalizing requirements in machine-readable specifications *before* coding begins, we create a single source of truth that:
>
> 1. **Eliminates ambiguity**: Gherkin-style acceptance criteria leave no room for interpretation
> 2. **Enables AI automation**: Structured specs can be directly processed by AI coding assistants
> 3. **Creates audit trails**: Every feature links back to an approved specification
> 4. **Reduces waste**: Catching requirement issues before coding saves 10-100x the cost of fixing them in production
>
> Industry studies (IBM, NIST) consistently show that defects found in requirements cost 10-200x more to fix when discovered in production versus during specification.

---

## The Spec Lifecycle

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  DRAFT   │───▶│  REVIEW  │───▶│ APPROVED │───▶│IMPLEMENTED│───▶│DEPRECATED│
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
     │               │               │               │
     │               │               │               │
  Writing        Feedback       Ready for        Code           Replaced
  spec           & revisions    implementation   complete       or removed
```

### Status Definitions

| Status | Description |
|--------|-------------|
| `draft` | Spec is being written, not ready for review |
| `review` | Spec is complete and awaiting feedback |
| `approved` | Spec has been approved for implementation |
| `implemented` | Feature has been implemented and merged |
| `deprecated` | Spec is no longer relevant or superseded |

### Why This Lifecycle?

> **Rationale**: The five-stage lifecycle mirrors proven software development gates used in enterprise environments:
>
> - **Draft → Review gate**: Prevents incomplete specifications from consuming reviewer time. Authors must self-certify completeness before requesting review.
> - **Review → Approved gate**: Ensures cross-functional validation (architecture, security, product) before any code is written. This is the cheapest place to catch design flaws.
> - **Approved → Implemented gate**: Creates a clear "contract" that implementation must fulfill. No moving goalposts during development.
> - **Implemented → Deprecated gate**: Maintains historical record. Never delete specs—deprecate them with references to replacements for traceability.
>
> This structure also enables metrics: cycle time per stage, approval rates, and rework frequency.

---

## Creating a Specification

### Step 1: Create the Spec File

```bash
# Copy the template
cp specs/features/_template.yaml specs/features/FEAT-0001-my-feature.yaml
```

#### Why YAML Format?

> **Rationale**: YAML was chosen over JSON, Markdown, or custom formats because:
>
> 1. **Human-readable**: Non-technical stakeholders can review specs without tooling
> 2. **Machine-parseable**: Enables validation, automation, and AI processing
> 3. **Schema-validatable**: JSON Schema validation catches errors before review
> 4. **Diff-friendly**: Clean diffs in version control for change tracking
> 5. **Comment support**: Authors can add context that doesn't affect parsing
>
> JSON lacks comments and is harder to read. Markdown is ambiguous to parse. Custom formats require custom tooling.

### Step 2: Fill in Metadata

```yaml
metadata:
  id: "FEAT-0001"
  title: "User Authentication via OAuth"
  version: "1.0.0"
  status: "draft"
  priority: "high"
  author: "your-name"
  created_at: "2024-01-15"
  tags:
    - authentication
    - security
```

#### Why This Metadata Structure?

> **Rationale**: Each metadata field serves a specific purpose in the development workflow:
>
> | Field | Purpose |
> |-------|---------|
> | `id` | Unique identifier for linking commits, PRs, and issues (traceability) |
> | `title` | Human-readable name for dashboards and reports |
> | `version` | Semantic versioning enables tracking spec evolution over time |
> | `status` | Workflow automation trigger—only `approved` specs get implemented |
> | `priority` | Enables automated scheduling and resource allocation |
> | `author` | Accountability and point of contact for questions |
> | `created_at` | Audit trail and cycle time metrics |
> | `tags` | Cross-cutting categorization for filtering and reporting |
>
> The `FEAT-NNNN` pattern follows enterprise ticketing conventions, enabling integration with Jira, Linear, or GitHub Issues.

### Step 3: Define the Problem

```yaml
description:
  summary: |
    Add OAuth 2.0 authentication to allow users to sign in
    with their Google or GitHub accounts.

  problem_statement: |
    Currently, users must create and remember yet another password.
    This creates friction during signup and security risks from
    password reuse.

  proposed_solution: |
    Implement OAuth 2.0 flows for Google and GitHub, allowing
    users to authenticate with existing accounts.
```

#### Why Problem-First Documentation?

> **Rationale**: Starting with the problem rather than the solution prevents "solution bias"—the tendency to build what's technically interesting rather than what's actually needed.
>
> The three-part structure (summary → problem → solution) follows the "Problem Statement" framework used in design thinking:
>
> 1. **Summary**: Elevator pitch for quick scanning
> 2. **Problem Statement**: Forces articulation of the *actual* user pain point
> 3. **Proposed Solution**: Only after the problem is clear do we propose solutions
>
> This structure also helps reviewers ask "Is this the right solution to this problem?" rather than just "Is this solution well-designed?"

### Step 4: Write Acceptance Criteria

Use the Gherkin format (Given/When/Then):

```yaml
acceptance_criteria:
  - id: "AC-001"
    given: "A user is on the login page"
    when: "They click 'Sign in with Google'"
    then: "They are redirected to Google's OAuth consent screen"

  - id: "AC-002"
    given: "A user completes Google OAuth consent"
    when: "They are redirected back to the application"
    then: "A new account is created with their Google email"
    and:
      - "They are automatically logged in"
      - "They see the dashboard"
```

#### Why Gherkin Format?

> **Rationale**: Gherkin (Given/When/Then) is the industry standard for behavior-driven development (BDD) because:
>
> 1. **Unambiguous**: The structured format eliminates interpretation differences between stakeholders, developers, and testers
> 2. **Testable by definition**: Each criterion maps directly to an automated test case
> 3. **AI-friendly**: The explicit structure enables AI tools to generate both implementation and tests
> 4. **Non-technical readable**: Product managers and QA can write and review criteria without coding knowledge
> 5. **Tool ecosystem**: Direct compatibility with Cucumber, Behave, SpecFlow, and other BDD frameworks
>
> Alternative formats like user stories ("As a user, I want...") are too vague—they describe intent but not verifiable behavior. Gherkin criteria are pass/fail by design.

### Step 5: Add Technical Requirements

```yaml
technical_requirements:
  constraints:
    - "Must support both Google and GitHub OAuth"
    - "Must handle OAuth errors gracefully"

  security:
    - "OAuth tokens must be stored securely"
    - "PKCE flow must be used for added security"

  performance:
    response_time_ms: 3000  # OAuth flow can be slow
```

#### Why Separate Technical Requirements?

> **Rationale**: Technical requirements are separated from acceptance criteria because they serve different audiences and purposes:
>
> | Aspect | Acceptance Criteria | Technical Requirements |
> |--------|--------------------|-----------------------|
> | Audience | Product, QA, stakeholders | Engineering, security, ops |
> | Focus | User behavior | System constraints |
> | Testability | Functional tests | Non-functional tests |
> | Negotiability | Often negotiable | Often non-negotiable |
>
> Security and performance requirements are "non-functional"—they don't describe *what* the system does but *how well* it does it. Keeping them separate ensures they aren't overlooked during implementation.

---

## Spec Review Process

### Submitting for Review

1. Change status to `review`
2. Open a Pull Request
3. Tag reviewers (architecture team)

### Review Checklist

Reviewers check for:

- [ ] Clear, testable acceptance criteria
- [ ] Complete technical requirements
- [ ] No scope creep
- [ ] Feasible implementation
- [ ] Security considerations addressed
- [ ] Dependencies identified

#### Why PR-Based Review?

> **Rationale**: Using Pull Requests for spec review (not just code review) provides:
>
> 1. **Version control**: Full history of spec evolution with blame/annotate
> 2. **Inline comments**: Reviewers can comment on specific lines/sections
> 3. **Approval workflow**: GitHub's review system tracks who approved what
> 4. **CI integration**: Automated validation runs before human review
> 5. **Audit trail**: Compliance-friendly record of who approved requirements
>
> This approach treats specifications as first-class artifacts deserving the same rigor as code.

### Approval

Once approved:
1. Status changes to `approved`
2. Spec is added to `specs.config.yaml`
3. Implementation can begin

#### Why Explicit Approval Gates?

> **Rationale**: The explicit approval step serves multiple critical functions:
>
> 1. **Accountability**: Named approvers are responsible for the requirements
> 2. **Prevents premature coding**: Developers can't start until approval—no wasted work
> 3. **Enables automation**: The `approved` status triggers CI/CD workflows
> 4. **Audit compliance**: SOC2, ISO 27001, and similar frameworks require documented approval
>
> Without explicit approval, features tend to "drift" into implementation before requirements are finalized, leading to rework.

---

## Implementation Methods

### Method 1: Automated (Claude Code)

For specs registered in `specs.config.yaml`:

```yaml
specifications:
  - id: "FEAT-0001"
    file: "specs/features/FEAT-0001-oauth.yaml"
    status: "approved"
    auto_implement: true
```

The GitHub Actions workflow will:
1. Detect the approved spec
2. Run Claude Code CLI
3. Create a feature branch
4. Open a PR with implementation

#### Why AI-Assisted Implementation?

> **Rationale**: Structured specifications are ideal inputs for AI coding assistants because:
>
> 1. **Deterministic scope**: Clear acceptance criteria prevent AI "creativity" adding unrequested features
> 2. **Testable output**: Gherkin criteria provide built-in test cases for validation
> 3. **Reduced hallucination**: Concrete requirements constrain AI to specific behaviors
> 4. **Human oversight**: Implementation still requires code review—AI accelerates, humans validate
>
> Studies show AI coding assistants are 30-50% more effective when given structured requirements versus natural language descriptions.

### Method 2: Manual Processing

Run the ingestion script locally:

```bash
# Process a single spec
./scripts/ingest-spec.sh specs/features/FEAT-0001-oauth.yaml

# Validate only (no implementation)
./scripts/ingest-spec.sh --validate specs/features/FEAT-0001-oauth.yaml

# Process all approved specs from config
./scripts/ingest-spec.sh --config
```

#### Why Local Processing Option?

> **Rationale**: Local processing complements CI/CD automation for several reasons:
>
> 1. **Development iteration**: Developers can test spec processing before committing
> 2. **Debugging**: Easier to diagnose issues locally than in CI logs
> 3. **Offline work**: Not dependent on GitHub Actions availability
> 4. **Cost control**: Local runs don't consume CI/CD minutes
>
> The `--validate` flag enables "shift-left" validation—catching spec errors before they reach CI.

### Method 3: Manual Implementation

1. Create feature branch: `git checkout -b spec/FEAT-0001`
2. Implement each acceptance criterion
3. Write tests for each criterion
4. Submit PR referencing the spec

#### Why Keep Manual Option?

> **Rationale**: Manual implementation remains valuable even with AI assistance because:
>
> 1. **Complex domains**: Some features require deep domain expertise AI lacks
> 2. **Legacy integration**: Existing codebases may have patterns AI doesn't recognize
> 3. **Learning**: Junior developers learn more from manual implementation
> 4. **Fallback**: AI services may be unavailable or produce unsatisfactory results
>
> The branch naming convention (`spec/FEAT-XXXX`) enables tracking which branch implements which spec.

---

## Best Practices

### Writing Good Specs

1. **Be specific**: Avoid vague terms like "fast" or "user-friendly"
2. **Be complete**: Include error cases and edge cases
3. **Be testable**: Each criterion should be verifiable
4. **Be minimal**: Don't over-specify implementation details

#### Why These Principles?

> **Rationale**: These four principles address the most common specification failures:
>
> | Principle | Failure it prevents |
> |-----------|-------------------|
> | **Specific** | "I thought fast meant 100ms, they thought it meant 1s" |
> | **Complete** | "Nobody thought about what happens when the API is down" |
> | **Testable** | "How do we know if 'user-friendly' is achieved?" |
> | **Minimal** | "The spec required React but the team wanted Vue" |
>
> The sweet spot is specifying *what* must happen without prescribing *how*. Implementation details should be left to developers unless there are genuine constraints.

### Acceptance Criteria Tips

**DO:**
```yaml
- id: "AC-001"
  given: "A user enters an invalid email format"
  when: "They submit the form"
  then: "An error message 'Please enter a valid email' appears below the field"
```

**DON'T:**
```yaml
- id: "AC-001"
  given: "Bad input"
  when: "Submit"
  then: "Show error"  # Too vague!
```

#### Why This Level of Detail?

> **Rationale**: The "DO" example is testable—you can write an automated test that:
> 1. Enters "not-an-email" in the email field
> 2. Clicks submit
> 3. Asserts the exact error message appears below the field
>
> The "DON'T" example fails because:
> - "Bad input" is undefined—which inputs are bad?
> - "Show error" is vague—where? what message?
>
> The cost of being specific upfront is minutes. The cost of ambiguity is hours of rework and debate during implementation.

### Managing Spec Changes

If requirements change after approval:

1. Create a new spec version (increment `version`)
2. Document what changed and why
3. Re-submit for review if changes are significant

#### Why Version Specs?

> **Rationale**: Versioning specifications (not just code) enables:
>
> 1. **Change tracking**: "v1.2.0 added the bulk upload requirement"
> 2. **Rollback clarity**: Know which spec version a deployment implements
> 3. **Parallel development**: Multiple versions can coexist during migrations
> 4. **Audit compliance**: Regulators can see requirement evolution over time
>
> Semantic versioning (MAJOR.MINOR.PATCH) communicates change magnitude:
> - PATCH: Clarifications, typo fixes
> - MINOR: New acceptance criteria added
> - MAJOR: Breaking changes to existing criteria

---

## Troubleshooting

### Spec Validation Fails

```bash
# Check YAML syntax
yq e '.' specs/features/your-spec.yaml

# Validate against schema
./scripts/ingest-spec.sh --validate specs/features/your-spec.yaml
```

### Implementation Doesn't Match Spec

- Review the acceptance criteria for ambiguity
- Check if all criteria are present in tests
- File an issue referencing specific criteria

### Workflow Not Triggering

Check:
1. Is the spec status `approved`?
2. Is `auto_implement: true` in config?
3. Is `ANTHROPIC_API_KEY` secret set?

#### Why These Common Issues?

> **Rationale**: These three checks address 90% of workflow failures:
>
> 1. **Status check**: The workflow only processes `approved` specs—`draft` or `review` specs are ignored by design
> 2. **Config flag**: `auto_implement: false` is the safe default—explicit opt-in required
> 3. **API key**: AI implementation requires authentication—missing secrets fail silently in logs
>
> The troubleshooting order is deliberate: check the cheapest/fastest things first.

---

## FAQ

**Q: Can I implement without a spec?**
A: For small fixes, yes. For features, always start with a spec.

> **Rationale**: The overhead of a spec isn't justified for typo fixes or one-line bug fixes. The threshold is: "Would another developer need context to understand this change?" If yes, write a spec.

**Q: How detailed should specs be?**
A: Detailed enough that implementation is unambiguous, but not so detailed that it prescribes implementation.

> **Rationale**: The "Goldilocks zone" is: can two different developers read this spec and produce functionally equivalent (though perhaps structurally different) implementations? If the spec is too vague, they'll diverge. If too detailed, you're micromanaging.

**Q: Who approves specs?**
A: The architecture team or designated reviewers in CODEOWNERS.

> **Rationale**: Approval authority should match accountability. Those who will maintain the system long-term should approve what gets built. CODEOWNERS automates this by requiring specific reviewers for spec files.

**Q: Can specs be changed after implementation?**
A: Yes, create a new version for enhancements or changes.

> **Rationale**: Requirements evolve—that's normal. The key is traceability: each implementation should link to a specific spec version, and spec changes should go through the same review process as the original.

---

## Further Reading

- [Behavior-Driven Development (BDD)](https://cucumber.io/docs/bdd/) - The methodology behind Gherkin syntax
- [IEEE 830 Software Requirements Specification](https://standards.ieee.org/) - Industry standard for requirements documentation
- [Shape Up](https://basecamp.com/shapeup) - Basecamp's approach to specification and betting
- [Amazon's Working Backwards](https://www.productplan.com/glossary/working-backward-amazon-method/) - PR/FAQ-driven development
