# Agent working rules

- Build a native iPhone AI chat for iOS 18+, SwiftUI + MVVM + service layer.
- Read docs/task.md and docs/plan.md before changes; keep the plan truthful.
- Views own presentation only. Inject AIService and ConversationRepository protocols.
- Use Swift 6 strict concurrency; UI and SwiftData context are MainActor isolated. Network work is asynchronous and cancellable. Never swallow cancellation as a user error.
- Persist user messages before requesting; checkpoint partial output; explicitly save on Stop/background. Retry replaces the failed assistant response without duplicating the user.
- Use small cohesive types, descriptive names, no force unwrap/force try, no unnecessary dependencies or abstraction layers.
- Use only Apple frameworks unless a dependency is demonstrably necessary; SPM only.
- Never store or print plaintext API credentials. Only generated obfuscated bytes may be tracked. Never put credentials in commands, logs or documentation.
- Make logical incremental Git commits. Build after substantial stages and fix failures before claiming success.
- Test parser boundaries, error mapping, cancellation, retry, and disk persistence. Use deterministic fixtures only in tests/debug UI test mode; production must use real SSE.
- Record actual validation, limitations, elapsed time and sanitized authentic session logs. Never claim an unperformed check passed.
