# System Architecture

> **For AI Assistants**: This document defines HOW the system is built. For WHAT it does, see `../specs/SPEC.md`. For WHY decisions were made, see `../decisions/`.

## Document Info

| Field | Value |
|-------|-------|
| Version | 1.0.0 |
| Status | Draft |
| Last Updated | YYYY-MM-DD |
| Owner | [Team/Person] |

---

## 1. Architecture Overview

### 1.1 System Context
<!-- Highest level view: the system and its environment -->

```
┌─────────────────────────────────────────────────────────────┐
│                     External Systems                         │
├─────────────────────────────────────────────────────────────┤
│  [Identity Provider]    [Payment Service]    [Email Service] │
└──────────┬─────────────────────┬─────────────────┬──────────┘
           │                     │                 │
           ▼                     ▼                 ▼
┌─────────────────────────────────────────────────────────────┐
│                    [SYSTEM NAME]                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Web App   │  │   API       │  │   Workers   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
│                          │                                   │
│                    ┌─────┴─────┐                            │
│                    │ Database  │                            │
│                    └───────────┘                            │
└─────────────────────────────────────────────────────────────┘
           ▲                     ▲                 ▲
           │                     │                 │
┌──────────┴─────────────────────┴─────────────────┴──────────┐
│  [Web Users]           [Mobile Users]        [API Clients]   │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Architecture Style
<!-- What architectural pattern(s) does this system follow? -->

| Aspect | Choice | Rationale |
|--------|--------|-----------|
| Overall Style | [Monolith / Microservices / Serverless / Hybrid] | [Why] |
| API Style | [REST / GraphQL / gRPC] | [Why] |
| Data Architecture | [Single DB / Polyglot / Event Sourced] | [Why] |
| Deployment | [Containers / Serverless / VMs] | [Why] |

---

## 2. Component Architecture

### 2.1 Component Diagram
<!-- Main components and their relationships -->

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                      │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  Web UI     │  │  Mobile App │  │  Admin UI   │         │
│  │  (React)    │  │  (Native)   │  │  (React)    │         │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘         │
└─────────┼────────────────┼────────────────┼─────────────────┘
          │                │                │
          ▼                ▼                ▼
┌─────────────────────────────────────────────────────────────┐
│                       API Gateway                            │
│  [Authentication] [Rate Limiting] [Routing] [Logging]       │
└────────────────────────────┬────────────────────────────────┘
                             │
          ┌──────────────────┼──────────────────┐
          ▼                  ▼                  ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│  User Service   │ │  Core Service   │ │ Notification    │
│                 │ │                 │ │    Service      │
│ - Auth          │ │ - Business      │ │ - Email         │
│ - Profile       │ │   Logic         │ │ - Push          │
│ - Preferences   │ │ - Workflows     │ │ - SMS           │
└────────┬────────┘ └────────┬────────┘ └────────┬────────┘
         │                   │                   │
         ▼                   ▼                   ▼
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  PostgreSQL │  │   Redis     │  │  S3/Blob    │         │
│  │  (Primary)  │  │  (Cache)    │  │  (Files)    │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Component Descriptions

| Component | Purpose | Technology | Owner |
|-----------|---------|------------|-------|
| Web UI | User-facing web application | React, TypeScript | Frontend Team |
| API Gateway | Request routing, auth, rate limiting | [Kong/Nginx/Custom] | Platform Team |
| User Service | Authentication, authorization, profiles | [Language/Framework] | Backend Team |
| Core Service | Primary business logic | [Language/Framework] | Backend Team |
| Notification Service | Multi-channel notifications | [Language/Framework] | Backend Team |

---

## 3. Data Architecture

### 3.1 Data Model Overview
<!-- Key entities and relationships -->

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│    User      │───────│   Account    │───────│   Resource   │
├──────────────┤  1:N  ├──────────────┤  1:N  ├──────────────┤
│ id           │       │ id           │       │ id           │
│ email        │       │ user_id      │       │ account_id   │
│ created_at   │       │ name         │       │ type         │
└──────────────┘       │ plan         │       │ data         │
                       └──────────────┘       └──────────────┘
```

### 3.2 Data Storage Strategy

| Data Type | Storage | Rationale |
|-----------|---------|-----------|
| Transactional | PostgreSQL | ACID compliance, complex queries |
| Cache | Redis | Low latency, session data |
| Files/Media | S3/Blob | Scalable object storage |
| Search | Elasticsearch | Full-text search capabilities |
| Analytics | [ClickHouse/BigQuery] | Time-series, aggregations |

### 3.3 Data Flow
<!-- How data moves through the system -->

```
[User Input] → [API Gateway] → [Validation] → [Business Logic] → [Database]
                                                      │
                                                      ▼
                                              [Event Published]
                                                      │
                                    ┌─────────────────┼─────────────────┐
                                    ▼                 ▼                 ▼
                              [Analytics]      [Notifications]    [Webhooks]
```

---

## 4. Integration Architecture

### 4.1 External Integrations

| System | Purpose | Protocol | Auth | Status |
|--------|---------|----------|------|--------|
| [Auth0/Okta] | Identity | OAuth 2.0 | API Key | Active |
| [Stripe] | Payments | REST | Secret Key | Active |
| [SendGrid] | Email | REST | API Key | Active |
| [Twilio] | SMS | REST | API Key | Planned |

### 4.2 API Contracts
<!-- Where to find API specifications -->

- **Internal APIs**: `specs/api/` (OpenAPI 3.1)
- **External Webhooks**: `specs/webhooks/`
- **Event Schemas**: `specs/events/`

### 4.3 Event Architecture
<!-- If using events/messaging -->

| Event | Publisher | Subscribers | Schema |
|-------|-----------|-------------|--------|
| `user.created` | User Service | Notification, Analytics | `events/user.json` |
| `order.completed` | Core Service | Notification, Billing | `events/order.json` |

---

## 5. Infrastructure Architecture

### 5.1 Deployment Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        Cloud Provider                        │
├─────────────────────────────────────────────────────────────┤
│  Region: [us-east-1]                                        │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  VPC: Production                                     │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │   │
│  │  │ Public      │  │ Private     │  │ Data        │ │   │
│  │  │ Subnet      │  │ Subnet      │  │ Subnet      │ │   │
│  │  │             │  │             │  │             │ │   │
│  │  │ [ALB]       │  │ [ECS/K8s]   │  │ [RDS]       │ │   │
│  │  │ [NAT]       │  │ [Workers]   │  │ [ElastiCache│ │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘ │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 5.2 Environment Strategy

| Environment | Purpose | Data | Access |
|-------------|---------|------|--------|
| Development | Local development | Synthetic | Developers |
| Staging | Integration testing | Sanitized copy | Team |
| Production | Live system | Real | Restricted |

### 5.3 Scaling Strategy

| Component | Scaling Type | Trigger | Limits |
|-----------|--------------|---------|--------|
| API Servers | Horizontal | CPU > 70% | 2-20 instances |
| Workers | Horizontal | Queue depth > 100 | 1-10 instances |
| Database | Vertical + Read Replicas | Manual | [Size limits] |

---

## 6. Security Architecture

### 6.1 Security Layers

```
┌─────────────────────────────────────────────────────────────┐
│                      WAF / DDoS Protection                   │
├─────────────────────────────────────────────────────────────┤
│                      API Gateway (Auth)                      │
├─────────────────────────────────────────────────────────────┤
│                   Application Security                       │
│  [Input Validation] [Output Encoding] [CSRF] [Rate Limiting]│
├─────────────────────────────────────────────────────────────┤
│                      Data Security                           │
│  [Encryption at Rest] [Encryption in Transit] [Key Mgmt]    │
├─────────────────────────────────────────────────────────────┤
│                   Infrastructure Security                    │
│  [Network Isolation] [IAM] [Secrets Management] [Logging]   │
└─────────────────────────────────────────────────────────────┘
```

### 6.2 Authentication & Authorization

| Aspect | Implementation |
|--------|----------------|
| User Auth | OAuth 2.0 / OIDC via [Provider] |
| Service Auth | mTLS / API Keys |
| Authorization | RBAC with [permissions model] |
| Session | JWT with [expiry] refresh tokens |

### 6.3 Data Classification

| Classification | Examples | Controls |
|----------------|----------|----------|
| Public | Marketing content | None |
| Internal | Business metrics | Auth required |
| Confidential | User PII | Encryption, audit logs |
| Restricted | Payment data | Encryption, PCI compliance |

---

## 7. Observability

### 7.1 Monitoring Stack

| Capability | Tool | Purpose |
|------------|------|---------|
| Metrics | [Prometheus/CloudWatch] | System and business metrics |
| Logging | [ELK/CloudWatch Logs] | Centralized log aggregation |
| Tracing | [Jaeger/X-Ray] | Distributed tracing |
| Alerting | [PagerDuty/OpsGenie] | Incident notification |

### 7.2 Key Metrics

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| API Latency (P95) | < 200ms | > 500ms |
| Error Rate | < 0.1% | > 1% |
| Availability | 99.9% | < 99.5% |
| CPU Utilization | < 70% | > 85% |

### 7.3 Logging Standards

```json
{
  "timestamp": "ISO8601",
  "level": "INFO|WARN|ERROR",
  "service": "service-name",
  "trace_id": "uuid",
  "message": "Human readable message",
  "context": { "user_id": "...", "request_id": "..." }
}
```

---

## 8. Development Standards

### 8.1 Code Organization

```
src/
├── api/              # API route handlers
├── services/         # Business logic
├── models/           # Data models
├── repositories/     # Data access
├── utils/            # Shared utilities
├── config/           # Configuration
└── tests/            # Test files
```

### 8.2 Key Patterns

| Pattern | Usage | Example |
|---------|-------|---------|
| Repository | Data access abstraction | `UserRepository.findById()` |
| Service | Business logic encapsulation | `AuthService.authenticate()` |
| Factory | Object creation | `NotificationFactory.create()` |
| Strategy | Algorithm selection | `PaymentStrategy` |

### 8.3 Cross-Cutting Concerns

| Concern | Implementation |
|---------|----------------|
| Error Handling | [Pattern - e.g., Result types, exceptions] |
| Validation | [Library/approach] |
| Logging | [Library] with structured format |
| Configuration | Environment variables + [config library] |

---

## 9. Appendix

### A. Technology Radar

| Technology | Status | Notes |
|------------|--------|-------|
| [Tech 1] | Adopt | Production ready |
| [Tech 2] | Trial | Evaluating |
| [Tech 3] | Hold | Not recommended |

### B. Architecture Decision Records

See `../decisions/` for detailed ADRs:
- ADR-001: [Decision title]
- ADR-002: [Decision title]

### C. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | YYYY-MM-DD | [Name] | Initial version |
