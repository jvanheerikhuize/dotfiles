# Code Patterns & Conventions

> **For AI Assistants**: Follow these patterns when generating or modifying code. Consistency is critical.

## Document Info

| Field | Value |
|-------|-------|
| Version | 1.0.0 |
| Last Updated | YYYY-MM-DD |

---

## 1. General Principles

### 1.1 Core Values
1. **Clarity over cleverness** - Code should be readable by humans first
2. **Explicit over implicit** - Make behavior obvious
3. **Composition over inheritance** - Prefer small, composable units
4. **Fail fast** - Validate early, fail with clear errors

### 1.2 SOLID Principles
- **S**ingle Responsibility - One reason to change
- **O**pen/Closed - Open for extension, closed for modification
- **L**iskov Substitution - Subtypes must be substitutable
- **I**nterface Segregation - Small, focused interfaces
- **D**ependency Inversion - Depend on abstractions

---

## 2. Naming Conventions

### 2.1 General Rules

| Element | Convention | Example |
|---------|------------|---------|
| Files | kebab-case | `user-service.ts` |
| Classes | PascalCase | `UserService` |
| Functions | camelCase | `getUserById` |
| Constants | SCREAMING_SNAKE | `MAX_RETRIES` |
| Variables | camelCase | `userCount` |
| Interfaces | PascalCase (no I prefix) | `UserRepository` |
| Types | PascalCase | `UserCreateInput` |
| Enums | PascalCase | `UserStatus.Active` |

### 2.2 Naming Patterns

```
# Functions - verb + noun
createUser(), getUserById(), deleteExpiredSessions()

# Booleans - is/has/can/should prefix
isActive, hasPermission, canEdit, shouldRetry

# Collections - plural nouns
users, pendingOrders, activeConnections

# Handlers - on + event
onUserCreated, onPaymentReceived

# Factories - create + noun
createLogger(), createDatabaseConnection()
```

### 2.3 Domain Language
<!-- Define ubiquitous language for your domain -->

| Term | Definition | Usage |
|------|------------|-------|
| [Term] | [Definition] | [How to use in code] |

---

## 3. File Organization

### 3.1 Directory Structure

```
src/
├── api/                    # HTTP layer
│   ├── routes/            # Route definitions
│   ├── middleware/        # Express/Koa middleware
│   ├── validators/        # Request validation
│   └── transformers/      # Response transformation
│
├── services/              # Business logic
│   ├── user/             # Feature-based organization
│   │   ├── user.service.ts
│   │   ├── user.service.test.ts
│   │   └── index.ts
│   └── ...
│
├── repositories/          # Data access
│   ├── user.repository.ts
│   └── ...
│
├── models/               # Domain models
│   ├── user.model.ts
│   └── ...
│
├── lib/                  # Shared libraries
│   ├── database/
│   ├── cache/
│   └── logger/
│
├── config/               # Configuration
│   └── index.ts
│
└── types/                # Type definitions
    └── index.ts
```

### 3.2 File Contents Order

```typescript
// 1. Imports (external, then internal)
import { external } from 'external-lib';
import { internal } from '@/lib/internal';

// 2. Types/Interfaces
interface UserInput { ... }

// 3. Constants
const MAX_RETRIES = 3;

// 4. Main export (class or function)
export class UserService { ... }

// 5. Helper functions (private)
function validateInput() { ... }
```

---

## 4. Code Patterns

### 4.1 Error Handling

**Pattern: Result Type**
```typescript
type Result<T, E = Error> =
  | { success: true; data: T }
  | { success: false; error: E };

// Usage
function getUser(id: string): Result<User> {
  const user = db.find(id);
  if (!user) {
    return { success: false, error: new NotFoundError('User not found') };
  }
  return { success: true, data: user };
}

// Handling
const result = getUser('123');
if (!result.success) {
  logger.error(result.error);
  return;
}
const user = result.data;
```

**Pattern: Custom Error Classes**
```typescript
class AppError extends Error {
  constructor(
    message: string,
    public code: string,
    public statusCode: number = 500,
    public isOperational: boolean = true
  ) {
    super(message);
    this.name = this.constructor.name;
  }
}

class NotFoundError extends AppError {
  constructor(resource: string) {
    super(`${resource} not found`, 'NOT_FOUND', 404);
  }
}

class ValidationError extends AppError {
  constructor(message: string) {
    super(message, 'VALIDATION_ERROR', 400);
  }
}
```

### 4.2 Dependency Injection

```typescript
// Define interface
interface UserRepository {
  findById(id: string): Promise<User | null>;
  save(user: User): Promise<User>;
}

// Service depends on abstraction
class UserService {
  constructor(private userRepo: UserRepository) {}

  async getUser(id: string): Promise<User> {
    const user = await this.userRepo.findById(id);
    if (!user) throw new NotFoundError('User');
    return user;
  }
}

// Inject implementation
const userService = new UserService(new PostgresUserRepository(db));
```

### 4.3 Repository Pattern

```typescript
interface Repository<T, ID> {
  findById(id: ID): Promise<T | null>;
  findAll(filter?: Partial<T>): Promise<T[]>;
  save(entity: T): Promise<T>;
  delete(id: ID): Promise<void>;
}

class UserRepository implements Repository<User, string> {
  constructor(private db: Database) {}

  async findById(id: string): Promise<User | null> {
    const row = await this.db.query('SELECT * FROM users WHERE id = $1', [id]);
    return row ? this.toEntity(row) : null;
  }

  private toEntity(row: any): User {
    return new User(row.id, row.email, row.name);
  }
}
```

### 4.4 Service Layer Pattern

```typescript
class OrderService {
  constructor(
    private orderRepo: OrderRepository,
    private paymentService: PaymentService,
    private notificationService: NotificationService
  ) {}

  async createOrder(input: CreateOrderInput): Promise<Order> {
    // 1. Validate
    this.validateInput(input);

    // 2. Business logic
    const order = Order.create(input);

    // 3. Persist
    const savedOrder = await this.orderRepo.save(order);

    // 4. Side effects
    await this.notificationService.sendOrderConfirmation(savedOrder);

    return savedOrder;
  }
}
```

### 4.5 Factory Pattern

```typescript
class NotificationFactory {
  static create(type: NotificationType, config: NotificationConfig): Notification {
    switch (type) {
      case 'email':
        return new EmailNotification(config);
      case 'sms':
        return new SMSNotification(config);
      case 'push':
        return new PushNotification(config);
      default:
        throw new Error(`Unknown notification type: ${type}`);
    }
  }
}
```

---

## 5. API Patterns

### 5.1 REST Conventions

| Action | Method | Path | Response |
|--------|--------|------|----------|
| List | GET | `/users` | 200 + array |
| Get | GET | `/users/:id` | 200 + object |
| Create | POST | `/users` | 201 + object |
| Update | PUT | `/users/:id` | 200 + object |
| Partial Update | PATCH | `/users/:id` | 200 + object |
| Delete | DELETE | `/users/:id` | 204 |

### 5.2 Response Format

```json
// Success
{
  "data": { ... },
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 100
  }
}

// Error
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "details": [
      { "field": "email", "message": "Invalid email format" }
    ]
  }
}
```

### 5.3 Controller Pattern

```typescript
class UserController {
  constructor(private userService: UserService) {}

  async getUser(req: Request, res: Response) {
    const { id } = req.params;

    const result = await this.userService.getUser(id);

    if (!result.success) {
      return res.status(404).json({ error: result.error });
    }

    return res.json({ data: result.data });
  }
}
```

---

## 6. Testing Patterns

### 6.1 Test Organization

```
tests/
├── unit/                  # Unit tests (isolated)
│   └── services/
│       └── user.service.test.ts
├── integration/           # Integration tests (with deps)
│   └── api/
│       └── users.test.ts
└── e2e/                   # End-to-end tests
    └── user-flow.test.ts
```

### 6.2 Test Structure (AAA)

```typescript
describe('UserService', () => {
  describe('getUser', () => {
    it('should return user when found', async () => {
      // Arrange
      const mockUser = { id: '1', email: 'test@example.com' };
      const mockRepo = { findById: jest.fn().mockResolvedValue(mockUser) };
      const service = new UserService(mockRepo);

      // Act
      const result = await service.getUser('1');

      // Assert
      expect(result).toEqual(mockUser);
      expect(mockRepo.findById).toHaveBeenCalledWith('1');
    });

    it('should throw NotFoundError when user not found', async () => {
      // Arrange
      const mockRepo = { findById: jest.fn().mockResolvedValue(null) };
      const service = new UserService(mockRepo);

      // Act & Assert
      await expect(service.getUser('999')).rejects.toThrow(NotFoundError);
    });
  });
});
```

### 6.3 Test Fixtures

```typescript
// fixtures/users.ts
export const createTestUser = (overrides: Partial<User> = {}): User => ({
  id: 'test-user-id',
  email: 'test@example.com',
  name: 'Test User',
  createdAt: new Date('2024-01-01'),
  ...overrides,
});
```

---

## 7. Documentation Patterns

### 7.1 Code Comments

```typescript
// DO: Explain WHY, not WHAT
// Retry with exponential backoff to handle transient network failures
const result = await retry(fetchData, { maxAttempts: 3 });

// DON'T: State the obvious
// Loop through users
for (const user of users) { ... }
```

### 7.2 JSDoc for Public APIs

```typescript
/**
 * Creates a new user account.
 *
 * @param input - User creation data
 * @returns The created user
 * @throws {ValidationError} If input is invalid
 * @throws {ConflictError} If email already exists
 *
 * @example
 * const user = await userService.createUser({
 *   email: 'user@example.com',
 *   name: 'John Doe'
 * });
 */
async createUser(input: CreateUserInput): Promise<User> { ... }
```

---

## 8. Anti-Patterns to Avoid

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| God Class | Too many responsibilities | Split into focused services |
| Magic Numbers | Unclear meaning | Use named constants |
| Deep Nesting | Hard to read | Extract functions, early returns |
| Shotgun Surgery | Changes spread everywhere | Improve cohesion |
| Primitive Obsession | Primitives instead of objects | Create domain types |
| Feature Envy | Method uses another class's data | Move method to that class |

---

## 9. Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | YYYY-MM-DD | [Name] | Initial version |
