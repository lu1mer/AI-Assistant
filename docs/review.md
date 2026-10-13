# Self-review

- UI/ViewModel/SwiftData state is MainActor isolated. Only Sendable message snapshots cross to networking; no ModelContext crosses an actor boundary.
- No networking in SwiftUI views; dependencies are injected through AIService and ConversationRepository.
- Request-scoped URLSession has request/resource deadlines, no disk URL cache, and is invalidated on stream termination. Stop invalidates request identity before cancelling the consumer; stale output cannot mutate a later response.
- ViewModel task uses weak self across awaits. Navigation and scene inactivity call Stop. No indefinite background-generation promise.
- SSE parser preserves empty event delimiters, split UTF-8, CR/LF/CRLF, comments and multiline data; it bounds individual event size and requires [DONE]. An abrupt EOF is reported as interruption.
- User + placeholder are saved before networking. Partial output is checkpointed at most every 350 ms and on Stop/finish/background. On process restart any leftover generating status becomes stopped.
- Retry removes the failed assistant placeholder/partial output and resends history through the existing user turn. Failed assistant output is excluded from subsequent requests.
- SwiftData saves are atomic; failed save/delete rolls back the context and surfaces a storage error. A missing/corrupt store does not trigger deletion or silent in-memory fallback.
- First-launch Application Support directory is created explicitly after the first runtime trace revealed CoreData's noisy recovery path.
- Accessibility identifiers belong to interactive elements; removed an error-container identifier that overrode its retry button identifier.
- No force unwrap, force try, third-party packages, plaintext credential or production fake-answer fallback.
- AppIntents metadata extraction is skipped by Xcode because the app exposes no AppIntents. This is a build-tool notice, not a Swift source warning.

## Remaining limits

Live provider authentication, streaming, Stop, follow-up and restart passed in an opt-in UI test. Free request quota was checked through the provider key endpoint. iOS 18 runtime remains unavailable after two Xcode catalog download attempts; this prevents claiming full runtime coverage.

Appearance is persisted through AppStorage; system follows the device and explicit light/dark overrides the window. New-conversation button uses a predictable rounded rectangle rather than nested prominent styling. All production AI requests remain real and cancellable. Search is local and does not transmit history. Copy/share require deliberate user action. Sanitized Git commits retain dates/stages but IDs changed; old reachable/unreachable log objects scrubbed and pruned.
