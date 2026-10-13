# Task: AI Assistant for iPhone

Build a small, polished native SwiftUI AI chat within approximately one workday. Minimum iOS 18; also validate on the available current iOS runtime.

## Required behavior
- Real streamed cloud AI response with Stop; keep partial text and allow subsequent messages.
- Multiple independent conversations: create, open, switch, delete; title from first prompt; id/title/createdAt/updatedAt/messages; messages have id/role/content/createdAt.
- History survives process termination/relaunch. Explicit empty/loading/error states and meaningful retry without duplicate prompts.
- Handle offline, timeout, HTTP/API failures, quota/rate limiting, malformed/truncated streams. Never expose raw server/URLSession error text.
- Native light/dark appearance, Dynamic Type, keyboard safe area, long text and history, automatic streaming scroll.
- Separate UI, state, persistence and streaming. Swift concurrency and testable dependencies.

## Delivery
- XcodeGen project.yml, executable Build.command launched by Finder; only SPM dependencies (prefer none).
- Embedded obfuscated API key with enough remaining quota, no runtime setup for reviewer. Client obfuscation is not cryptographic secret protection.
- Meaningful tests and code review; incremental .git history; docs/task.md, docs/plan.md, actual AGENTS.md and sanitized ai-logs/.
- README: factual time/tools/provider/implemented/known issues/testing/build/architecture.
- ZIP includes full source and .git; exclude derived build products and plaintext secrets.
- Optional photo/Mac/offline features only after required behavior is complete.

## Initial environment
Empty projectless workspace, no existing repository. Xcode 26.3 (17C529), XcodeGen installed. iOS 26.3 simulator available; iOS 18 runtimes currently unavailable. API credential has been requested from the user by local file path.
