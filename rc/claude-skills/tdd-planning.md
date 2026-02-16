# TDD Planning Skill

## When to use

When reviewing or rewriting a Claude plan (the markdown plan file), modify
it so the implementation follows test-driven development and flocking-style
refactoring. Don't lecture about TDD or flocking — just shape the steps so
they naturally lead there.

## How to modify a plan

### 1. Start with a failing test for the simplest case

The first step in the plan should be writing a test for the smallest useful
behavior. The implementation that follows should be the dumbest thing that
makes the test pass — a hard-coded return, a single `if`, whatever. Naive
green code is good. Don't plan to "set up architecture" first.

### 2. Add cases one at a time

Each subsequent step adds one new test case and the minimum code to make it
pass. The plan should make it clear that each addition is a small increment.
The code will get messy — `if/else` chains, duplicated branches, inlined
logic. That's fine. That's the point.

### 3. Only refactor when new complexity is about to arrive

Do NOT plan a refactoring step after every test. Only plan a refactoring
phase when:
- The next addition would create a third or fourth branch in a conditional
- The code is about to get genuinely hard to read or extend
- There are two or more chunks of code that look almost-but-not-quite alike

If the code is messy but still easy to change, leave it messy. Refactoring
too early hides the pattern you need to see.

### 4. Refactor by flocking, not by redesigning

When a refactoring step IS warranted, plan it as a sequence of small moves
under green tests:
- Find two pieces of code that are almost alike
- Make them a little more alike (extract a variable, align a conditional,
  rename to match)
- Repeat until they are identical
- Remove the duplication (extract method, introduce parameter, pull up into
  a shared path)

The plan should NOT say "refactor into a Strategy pattern" or "extract a
base class." It should say things like "make the two branches look more
alike" or "line up the differences so they can collapse." The design
emerges from the flocking — it is not decided up front.

### 5. Repeat

After a refactoring phase, go back to adding test cases. The cycle is:
add cases → notice growing mess → flock under green → add more cases.

## Toy example

Suppose the task is: "write a function that converts an integer to its
Roman numeral string."

### Bad plan (over-designed)

1. Design a mapping table of Roman numeral values
2. Implement a loop that subtracts values and appends numerals
3. Handle subtractive cases (IV, IX, etc.)
4. Write tests

### Good plan (TDD + flocking)

1. **Test: `1` → `"I"`**
   Write a test asserting `roman(1)` returns `"I"`. Make it pass by
   returning `"I"`.

2. **Test: `2` → `"II"`**
   Add a test for `2`. Make it pass — maybe `"I" * n`, maybe an `if`.
   Whatever is simplest.

3. **Test: `3` → `"III"`**
   Add a test for `3`. The current code probably already handles it. If
   not, adjust.

4. **Test: `4` → `"IV"`**
   Add a test for `4`. This is a new kind of thing. An `if n == 4` is
   fine here. The code now has a branch but that's only two cases.

5. **Test: `5` → `"V"`, then `6` → `"VI"`**
   Two more cases. Probably more `if/else` branches. Code is getting
   a bit ugly but it still works and each case is obvious.

6. **Test: `9` → `"IX"`**
   Another subtractive case. Now there are two subtractive branches (`4`
   and `9`) that look similar and several additive branches that look
   similar. A third kind is about to arrive (`10`, `40`, `50`...) — this
   is where the code would start to buckle.

7. **Refactor under green: flock the branches**
   Don't redesign. Look at the `if` branches:
   - The subtractive cases (`4`, `9`) both check a threshold then prepend
     a smaller numeral. Make them look more alike — same variable names,
     same shape.
   - The additive cases (`1`, `5`) both subtract and append. Make those
     look alike too.
   - Once each group is identical except for the specific numerals and
     values, collapse them into a loop over a table of
     `(value, numeral)` pairs.
   The table-driven design emerges; it was not planned in step 1.

8. **Continue adding tests: `10`, `14`, `40`, `99`, `1994`...**
   The table makes these easy now. Add pairs to the table as needed. If
   a new case doesn't fit the table, add it naively first, then flock
   again if the new code creates near-duplicates.
