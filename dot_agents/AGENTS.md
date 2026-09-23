# Commenting Rules

- Prefer clear names and simple structure over explanatory comments.
- Do not add comments that merely restate obvious code, narrate routine steps, or serve as filler or decoration.
- Use comments to explain non-obvious intent, tradeoffs, invariants, constraints, edge cases, or historical context that maintainers need.
- Document API contracts and complex behavior when callers or maintainers cannot reasonably infer them from names, types, and structure. Avoid duplicating the implementation.
- Preserve required license headers, tool directives, and documentation conventions.
- Keep comments concise, specific, and close to the code they clarify.
- When changing behavior, update or remove related comments. Do not leave stale or contradictory comments or commented-out code.
- TODOs should state the remaining work, why it is deferred, and what would resolve it. Include a real owner or issue reference when applicable; never invent one.
