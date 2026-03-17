---
name: test-driven-engineering
description: >
  Foundational skill for test-driven engineering (TDE). Defines principles and practices
  that apply to every agent role — planning, implementing, reviewing, orchestrating, and
  code review. TDE extends TDD beyond code: plans have acceptance criteria written before
  the plan, reviews have expectations set before reading the diff, orchestrators hold
  private invariants they verify through reviewers. Read this skill whenever you are writing
  code, writing a plan, reviewing work, or orchestrating agents.
version: 0.1.0
---

# Test-Driven Engineering

Test-driven engineering (TDE) applies the test-driven development cycle — **set
expectations first, then build, then verify** — to every kind of work an agent does.
Code has unit tests. Plans have acceptance criteria. Reviews have evaluation frameworks.
Orchestrators hold invariants they verify through delegated reviewers.

The core loop is always the same:

1. **Red.** Define what success looks like before doing the work.
2. **Green.** Do the simplest thing that meets those expectations.
3. **Refactor.** Improve the implementation while keeping the expectations satisfied.

This skill defines the principles that all other skills reference. It is the source of
truth for how we think about testing, verification, and quality.

---

## Principle 1: Expectations Before Implementation

Write your expectations before you write (or read) the implementation. This applies at
every level:

| Role | "Test" (expectation) | "Implementation" (work product) |
|------|---------------------|---------------------------------|
| **Plan author** | Acceptance criteria for each step | The step's specification |
| **Implementor** | Unit and integration tests | The production code |
| **Reviewer** | Evaluation checklist derived from the plan | The review verdict |
| **Orchestrator** | Invariants from PLAN.md | The merged result across steps |
| **Code reviewer** | Expected behaviors from the commit message and context | The review document |

### Why this matters

Writing expectations first forces you to think about *what* before *how*. It prevents
the common failure mode where the "test" is written after the code and merely restates
what the code already does — which tests nothing.

### Good: expectations before implementation

```markdown
# Step 03: Add session expiry

## Tests (written by plan-author before the implementation spec)
- A session created 29 minutes ago is valid
- A session created 31 minutes ago is expired
- A session with no created_at timestamp is expired (fail closed)
- Expiry check does not hit the database (pure function on the session struct)

## Implementation
SessionValidator.expired?(session) returns true/false based on created_at...
```

The tests constrain the implementation. An implementor who reads this knows exactly what
to build and can write the test file first.

### Bad: expectations after implementation

```markdown
# Step 03: Add session expiry

## Implementation
SessionValidator.expired?(session) checks if the session is older than 30 minutes.

## Tests
- Test that expired? returns true for expired sessions
- Test that expired? returns false for valid sessions
```

These "tests" are just the implementation restated in English. They don't specify edge
cases, don't define what "expired" means precisely, and an implementor can pass them
with almost any interpretation.

---

## Principle 2: Shameless Green

The first implementation that satisfies the tests should be the **simplest possible
thing that works**. Do not introduce abstractions, indirection, generality, or
configuration that the tests don't require.

### Why this matters

Premature abstraction is the root of most accidental complexity. If you write a test
that says "expired sessions return true" and your implementation is a simple `<`
comparison on timestamps, that's correct — even if you "know" you'll later need to
support configurable timeouts. You don't need that yet. The tests don't ask for it.

### Good: shameless green

```ruby
# Test
test "session older than 30 minutes is expired" do
  session = Session.new(created_at: Time.now - 31 * 60)
  assert SessionValidator.expired?(session)
end

# Implementation (shameless green)
module SessionValidator
  EXPIRY_SECONDS = 30 * 60

  def self.expired?(session)
    return true if session.created_at.nil?
    (Time.now - session.created_at) > EXPIRY_SECONDS
  end
end
```

This is direct, readable, and passes the test. There's no `ExpiryPolicy` class, no
`ConfigurableTimeout` module, no strategy pattern — just arithmetic.

### Bad: premature abstraction

```ruby
# Same test, but the implementation does this:
class ExpiryPolicy
  def initialize(strategy: :fixed, timeout: nil, config: ExpiryConfig.default)
    @strategy = strategy
    @timeout = timeout || config.default_timeout
  end

  def expired?(session)
    ExpiryStrategyFactory.build(@strategy).check(session, @timeout)
  end
end
```

This passes the same test but introduces three unnecessary abstractions. When the tests
eventually *do* require configurable behavior, we'll add it then — driven by a test.

---

## Principle 3: Flocking

When duplication appears across the codebase, resist the urge to extract it immediately.
Let the pattern appear at least twice. Only extract when you can see the *actual* shared
structure — not the structure you imagine.

### Why this matters

Two things that look similar often diverge as requirements evolve. Extracting too early
creates a shared abstraction that serves neither use case well, and both callers end up
working around it.

### Good: let duplication exist, then extract

```ruby
# Step 2 introduced this:
def validate_session(session)
  return :expired if session.created_at.nil?
  return :expired if (Time.now - session.created_at) > 30 * 60
  :valid
end

# Step 4 introduces something similar:
def validate_token(token)
  return :expired if token.issued_at.nil?
  return :expired if (Time.now - token.issued_at) > 60 * 60
  :valid
end

# Step 6 (refactoring step) extracts the shared pattern:
def check_expiry(timestamp, max_age_seconds)
  return :expired if timestamp.nil?
  return :expired if (Time.now - timestamp) > max_age_seconds
  :valid
end
```

By step 6 we can see the real shared shape: a timestamp and a max-age. If we'd
extracted at step 2, we might have baked in assumptions about sessions that don't
apply to tokens.

### Bad: extract on first sight

```ruby
# Step 2 sees a "pattern" and immediately creates:
class TemporalValidator
  def initialize(field:, max_age:, entity_type:)
    # ...
  end
end
```

Now step 4's token validation has to conform to `TemporalValidator`'s interface, which
was designed around sessions. The abstraction becomes a constraint instead of a tool.

---

## Principle 4: Tests Verify Behavior, Not Implementation

A test passes inputs and checks properties of the outputs. It does not inspect how the
code internally arrives at those outputs. This makes tests resilient to refactoring —
if the behavior is the same, the test still passes.

### Why this matters

Tests coupled to implementation break every time you refactor, even when behavior is
unchanged. This makes refactoring expensive and discourages it — the opposite of what
TDD intends.

### Good: test the behavior

```ruby
test "full name joins first and last with a space" do
  user = User.new(first_name: "Ada", last_name: "Lovelace")
  assert_equal "Ada Lovelace", user.full_name
end
```

This test doesn't care whether `full_name` uses string interpolation, `join`, `+`,
or a format string. It checks the output.

### Bad: test the implementation

```ruby
test "full name calls join" do
  user = User.new(first_name: "Ada", last_name: "Lovelace")
  # This test breaks if we switch from join to interpolation
  assert_equal "Ada Lovelace", [user.first_name, user.last_name].join(" ")
end
```

This test duplicates the production logic. It will pass even if `user.full_name` is
completely broken, because it never calls `full_name` at all.

---

## Principle 5: Exercise Properties of Inputs

Every test suite should include cases for the interesting properties of inputs: empty,
nil/null, zero, negative, boundary values, invalid types. This is inspired by
property-based testing (QuickCheck-style) but applied as concrete examples.

### Why this matters

Happy-path tests confirm the code works when everything is normal. Property tests
confirm it behaves *correctly* when things are weird. Most production bugs live in the
weird cases.

### Good: exercise input properties

```ruby
test "full name with nil last name returns first name only" do
  user = User.new(first_name: "Ada", last_name: nil)
  assert_equal "Ada", user.full_name
end

test "full name with empty first name returns last name only" do
  user = User.new(first_name: "", last_name: "Lovelace")
  assert_equal "Lovelace", user.full_name
end

test "full name with both nil returns empty string" do
  user = User.new(first_name: nil, last_name: nil)
  assert_equal "", user.full_name
end

test "full name strips leading and trailing whitespace" do
  user = User.new(first_name: " Ada ", last_name: " Lovelace ")
  assert_equal "Ada Lovelace", user.full_name
end
```

### Bad: only test the happy path

```ruby
test "full name works" do
  user = User.new(first_name: "Ada", last_name: "Lovelace")
  assert_equal "Ada Lovelace", user.full_name
end
```

One test, one path. What happens with nil? Empty string? Whitespace? We don't know.

---

## Principle 6: Tests Justify Their Own Existence

Every test must be able to fail meaningfully. If a test can never fail, or can only fail
when the test itself is wrong, it is a tautology and should be removed.

### Why this matters

Tautological tests create a false sense of coverage. They inflate test counts without
catching bugs. Worse, they slow down the suite and obscure the tests that *do* matter.

### Good: tests that can meaningfully fail

```ruby
test "discount rounds to two decimal places" do
  product = Product.new(price: 10.00)
  assert_equal 9.85, product.apply_discount(0.015)
end
```

This can fail if rounding is wrong, if the discount formula is wrong, or if floating
point issues aren't handled. It tests a specific, meaningful property.

### Bad: tautological tests

```ruby
# Tautology: tests that the constructor works
test "creates a product" do
  product = Product.new(price: 10.00)
  assert product
end

# Tautology: tests the language, not the code
test "price is a number" do
  product = Product.new(price: 10.00)
  assert_kind_of Numeric, product.price
end

# Tautology: asserts what was just set
test "price is correct" do
  product = Product.new(price: 10.00)
  assert_equal 10.00, product.price
end
```

The first test checks that Ruby can instantiate a class. The second checks that Ruby's
type system works. The third checks that a getter returns what was passed to the
constructor — this is testing the language, not business logic.

---

## Principle 7: Never Mock What You're Testing

A mock replaces a real dependency with a controlled stand-in. Mocks are appropriate when
isolating a unit from external systems (network, disk, third-party APIs). They are
**never appropriate** for replacing the behavior the test is supposed to verify.

### Why this matters

When you mock the thing you're testing, the test verifies the mock — not the code. It
will pass forever, no matter how broken the real implementation becomes.

### Bad: mocking the behavior under test

```ruby
# Production code
class OrderProcessor
  def total(order)
    subtotal = order.line_items.sum(&:price)
    TaxCalculator.compute(subtotal, order.region)
  end
end

# Test — mocks TaxCalculator, which is exactly what we're testing
test "computes order total with tax" do
  TaxCalculator.stubs(:compute).returns(107.00)
  processor = OrderProcessor.new
  assert_equal 107.00, processor.total(order)
end
```

This test will pass even if `TaxCalculator.compute` is completely broken, because it
never runs. It mocks the very dependency whose integration we want to verify.

### Good: use real collaborators via dependency injection

```ruby
# Production code — accepts collaborators through the constructor
class OrderProcessor
  def initialize(tax_calculator: TaxCalculator.new)
    @tax_calculator = tax_calculator
  end

  def total(order)
    subtotal = order.line_items.sum(&:price)
    @tax_calculator.compute(subtotal, order.region)
  end
end

# Test — uses the real TaxCalculator
test "computes order total with tax for California" do
  order = Order.new(
    line_items: [LineItem.new(price: 50.00), LineItem.new(price: 50.00)],
    region: "CA"
  )
  processor = OrderProcessor.new
  assert_equal 109.25, processor.total(order)  # CA tax rate: 9.25%
end
```

This test exercises the real integration between `OrderProcessor` and `TaxCalculator`.
If the tax rate logic changes, the test will catch it.

### When mocking IS appropriate

Mock external systems that you can't or shouldn't call in tests:

```ruby
# Good use of mocking: isolate from an external HTTP API
test "fetches exchange rate from API" do
  stub_request(:get, "https://api.exchange.com/rates/USD")
    .to_return(body: '{"rate": 1.12}')

  converter = CurrencyConverter.new
  assert_equal 1.12, converter.rate_for("USD")
end
```

The key distinction: we're testing that `CurrencyConverter` **correctly parses the
response**. We mock the network, not the parsing logic.

---

## Principle 8: Functional Core / Imperative Shell

Separate pure logic from side effects. The functional core takes inputs and returns
outputs — no database, no network, no file system, no global state. The imperative
shell orchestrates I/O and calls the core.

### Why this matters for TDD

Functional-core code is trivially testable: pass inputs, check outputs. No setup, no
teardown, no mocks. The harder-to-test imperative shell becomes a thin layer that's
easy to verify through integration tests.

### Good: functional core with thin shell

```ruby
# Functional core — pure, testable, no dependencies
module PricingEngine
  def self.compute_total(items, tax_rate, discount_code: nil)
    subtotal = items.sum { |i| i[:price] * i[:quantity] }
    discount = resolve_discount(subtotal, discount_code)
    tax = (subtotal - discount) * tax_rate
    { subtotal: subtotal, discount: discount, tax: tax.round(2),
      total: (subtotal - discount + tax).round(2) }
  end

  def self.resolve_discount(subtotal, code)
    case code
    when "HALF"  then subtotal * 0.5
    when "TENTH" then subtotal * 0.1
    else 0
    end
  end
end

# Imperative shell — thin, orchestrates I/O
class CheckoutController
  def create
    items = CartRepository.items_for(current_user)
    tax_rate = TaxService.rate_for(current_user.region)
    result = PricingEngine.compute_total(items, tax_rate, discount_code: params[:code])
    OrderRepository.save(current_user, result)
    render json: result
  end
end
```

```ruby
# Tests for the functional core — easy, fast, no mocks
test "compute_total with no discount" do
  items = [{ price: 10.00, quantity: 2 }, { price: 5.00, quantity: 1 }]
  result = PricingEngine.compute_total(items, 0.08)
  assert_equal 25.00, result[:subtotal]
  assert_equal 0, result[:discount]
  assert_equal 2.00, result[:tax]
  assert_equal 27.00, result[:total]
end

test "compute_total with HALF discount" do
  items = [{ price: 20.00, quantity: 1 }]
  result = PricingEngine.compute_total(items, 0.10, discount_code: "HALF")
  assert_equal 20.00, result[:subtotal]
  assert_equal 10.00, result[:discount]
  assert_equal 1.00, result[:tax]
  assert_equal 11.00, result[:total]
end

test "compute_total with empty items" do
  result = PricingEngine.compute_total([], 0.08)
  assert_equal 0, result[:subtotal]
  assert_equal 0, result[:total]
end

test "compute_total with unknown discount code" do
  items = [{ price: 10.00, quantity: 1 }]
  result = PricingEngine.compute_total(items, 0.0, discount_code: "FAKE")
  assert_equal 0, result[:discount]
  assert_equal 10.00, result[:total]
end
```

```ruby
# Integration test for the shell — exercises the wiring
test "checkout creates an order with correct total" do
  login_as users(:california_buyer)
  add_to_cart products(:widget), quantity: 2  # $10 each

  post "/checkout", params: { code: "TENTH" }

  assert_response :success
  order = Order.last
  assert_equal 18.34, order.total  # (20 - 2) * 1.0925 (CA tax)
end
```

### Bad: everything in the shell

```ruby
class CheckoutController
  def create
    items = CartRepository.items_for(current_user)
    subtotal = items.sum { |i| i.price * i.quantity }
    discount = params[:code] == "HALF" ? subtotal * 0.5 : 0
    tax_rate = TaxService.rate_for(current_user.region)
    tax = (subtotal - discount) * tax_rate
    total = subtotal - discount + tax

    Order.create!(user: current_user, total: total.round(2))
    render json: { total: total.round(2) }
  end
end
```

All the logic lives in the controller. Testing it requires mocking the cart repository,
the tax service, the database, and the HTTP layer. Any change to any of those breaks the
test — even if the pricing logic itself is correct.

---

## Applying TDE to Non-Code Work

TDE isn't just for code. The red-green-refactor cycle applies to any work product:

### Plans

- **Red:** Write acceptance criteria for each step *before* writing the implementation
  specification. What must be true when this step is done?
- **Green:** Write the simplest step specification that satisfies those criteria.
- **Refactor:** Review the step for clarity and completeness without changing what it
  requires.

### Reviews

- **Red:** Before reading the diff, write down what you expect the implementation to
  accomplish based on the plan and commit message. What properties should the code have?
- **Green:** Read the diff and check each expectation. Record pass/fail.
- **Refactor:** Organize findings into a structured review. Add observations that weren't
  in your initial expectations.

### Orchestration

- **Red:** Before spawning agents, identify the invariants from PLAN.md that must hold
  across the full implementation. These are your "tests."
- **Green:** Execute the plan. After each step merges, verify the invariant still holds
  (through the reviewer).
- **Refactor:** At final verification, run the full test suite and check the combined
  diff against the original plan invariants.

### Good: plan with TDE

```markdown
# PLAN.md

## Invariants (the orchestrator's "tests")
- The full test suite passes after every step merge
- No step introduces a dependency that isn't declared in the Gemfile
- Every public method added has at least one test
- Session expiry is always fail-closed (ambiguous state = expired)
```

### Bad: plan without TDE

```markdown
# PLAN.md

## Steps
1. Add session model
2. Add session validation
3. Add controller
4. Add tests
```

Step 4 defers all testing to the end. There are no invariants for the orchestrator to
verify. Nothing prevents a step from introducing untested or incorrect code.

---

## Summary of Principles

| # | Principle | One-line rule |
|---|-----------|---------------|
| 1 | Expectations before implementation | Write the test (or acceptance criteria) before the code (or spec) |
| 2 | Shameless green | The simplest thing that passes is the right first implementation |
| 3 | Flocking | Let duplication exist until the shared pattern is obvious |
| 4 | Verify behavior, not implementation | Pass inputs, check outputs — don't inspect internals |
| 5 | Exercise input properties | Test empty, nil, zero, negative, boundary, invalid |
| 6 | Tests justify their existence | Every test must be able to fail meaningfully |
| 7 | Never mock what you're testing | Mock external systems, not the code under test |
| 8 | Functional core / imperative shell | Pure logic is easy to test; side effects live in a thin shell |

---

## Cross-references

This skill is referenced by:

- **plan-author** — Principles 1–3, 6, 8 shape how steps and their tests are written
- **plan-implementor** — Principles 2, 4–8 guide how code and tests are written
- **plan-reviewer** — Principles 4–7 define what "good tests" look like during review
- **plan-orchestrator** — Principle 1 (invariants as tests) guides orchestration
- **code-review** — Principles 4–7 define test quality evaluation criteria
