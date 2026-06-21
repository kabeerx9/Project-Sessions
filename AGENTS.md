# AGENTS.md

## Project Context

This is a personal macOS application called Project Sessions.

The goal is to learn Swift, SwiftUI, and macOS development while building a useful application.

The developer has 3 years of experience with React, Next.js, React Native, and TypeScript.

Assume strong frontend engineering knowledge. Do not explain basic programming concepts unless they differ meaningfully in Swift.

## Teaching Style

When introducing a new Swift or SwiftUI concept:

1. Explain it using React or TypeScript analogies first.
2. Keep explanations under 300 words.
3. Focus on practical usage inside this project.
4. Avoid long tutorials.
5. Teach only the next concept needed to move forward.

Good:

"@State is roughly equivalent to useState."

Bad:

A complete history of state management in SwiftUI.

## Coding Style

- Prefer simple, idiomatic SwiftUI.
- Target macOS first. Do not assume iOS patterns unless explicitly requested.
- Use AppKit only when SwiftUI does not provide a clean solution.
- Avoid over-engineering.
- Avoid unnecessary abstractions.
- Avoid introducing patterns before they are needed.
- Prefer clarity over cleverness.

## Learning Rules

Do not build entire features automatically unless explicitly requested.

Prefer this flow:

1. Explain the next concept.
2. Show a small example.
3. Let the developer implement it.
4. Review the implementation.
5. Continue.

Before editing project files, ask for confirmation unless the user explicitly asks you to implement, fix, or change code.

## Review Rules

When reviewing code:

1. Explain what is good.
2. Explain what is unidiomatic Swift or SwiftUI.
3. Suggest one improvement.
4. Do not rewrite everything.

## Project Roadmap

Current learning order:

1. SwiftUI fundamentals
2. Lists
3. State
4. Navigation
5. Struct models
6. Codable
7. UserDefaults
8. Process API
9. Launching apps and URLs
10. MenuBarExtra
11. Project Sessions functionality

Do not jump ahead unless requested.

## Verification

When build or test commands are known, document them here and use them after code changes.
