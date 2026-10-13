# Implementation plan

Planning started 2026-10-05 14:12 UTC, before implementation.

## Architecture decisions
SwiftUI + @Observable MainActor ChatViewModel. Value-type Codable conversations/messages keep request snapshots immutable and tests simple. SwiftData stores one record per conversation with a Codable messages payload (preserves explicit message order and makes each save atomic); repository is the sole owner of ModelContext. ChatStore publishes sorted conversation summaries. No third-party dependencies.

OpenRouter Chat Completions, openrouter/free, HTTPS POST with stream=true (initial implementation used Groq; migration recorded below). URLSession.AsyncBytes feeds an isolated SSE decoder; AsyncThrowingStream termination cancels the producer and invalidates its request-scoped session. Retry reuses the same user turn, replacing failed partial output. Stop preserves received content. Navigating away/background stops and saves the active generation.

## Stages
- [x] Inspect requirements and environment; choose architecture/provider; record real agent rules.
- [x] Bootstrap XcodeGen, executable Finder build, Git; build minimal app.
- [x] Implement domain and SwiftData repository; checkpointing and recovery.
- [x] Implement SSE parser, Groq client, error mapping and obfuscated key tooling.
- [x] Implement list/chat UI, cancellation, retry and lifecycle behavior.
- [x] Add/run unit and UI tests; build significant stages.
- [x] Connect provided key, verify real streaming/Stop and remaining quota.
- [x] Inspect light/dark, keyboard, long history and restart; review code and fix defects.
- [x] Clean simulator build, README and sanitized authentic logs.
- [x] Package ZIP including .git and verify archive integrity.

## Verification strategy
Use deterministic unit fixtures for parser framing/malformed/truncated streams, HTTP/network errors, ChatViewModel retry/cancellation including stale emissions, and SwiftData disk reopen. XCUITest exercises navigation, input, persistence, Stop and retry with a debug-only fixture dependency. Separately perform actual provider requests when a key is available; fixtures do not count as live API validation.

## Known risks / unresolved inputs
- API key and quota: connected and checked; 47/50 free requests remained after live verification. Free provider availability can change.
- iOS 18 runtime absent: minimum target will be compiled; runtime compatibility remains unverified until a runtime is available.
- Embedded key is recoverable by determined users; obfuscation meets test requirement only.
- Free provider limits/model availability can change. Handle 429 and context rejection explicitly.

## Sources checked
- https://console.groq.com/docs/text-chat
- https://console.groq.com/docs/rate-limits

### Bootstrap result
Build.command executed successfully with Xcode 26.3 for generic iOS Simulator. User has no API key; live integration remains blocked on obtaining a provider credential.

### Persistence stage
Domain models and atomic SwiftData conversation snapshots compile successfully. Store surfaces save/delete failures; interrupted generating status recovers to stopped. Runtime tests follow with the UI stage.

### Networking stage
SSE byte framing and request-scoped cancellable Groq client compile successfully with Swift 6. Key embedding script is ready; credential intentionally remains empty because the user has none.

### UI stage
List/chat screens, MainActor ViewModel, generation checkpointing, Stop/Retry and background/navigation cancellation compile. Only build-tool notice is AppIntents metadata skipped (no AppIntents dependency); no Swift compiler warnings.

### Verified test stage
19 unit tests and 4 UI tests passed via Test.command on 2026-10-05 at 17:43 Moscow time. Actual system dark mode screenshots were visually inspected; initial launch-argument-only dark-mode test did not change appearance and was corrected. UI automation intermittently missed navigation during simulator cold startup with multiple simulators; final suite passed on a single warmed simulator with 15-second navigation waits. Do not describe earlier failed runs as successful. Release simulator build passed. See docs/testing.md for limits.

### Clean build
Build.command succeeded from /private/tmp with minimal PATH on 2026-10-05 18:57 Moscow time, with no existing generated project or DerivedData. Built MinimumOSVersion is 18.0. Only AppIntents tool notice; no Swift compiler warnings.

### Delivery snapshot
ZIP CRC/integrity passed; complete .git and executable Build.command included. Every tracked revision scanned for common API credential patterns and personal home paths. Live API and iOS 18 runtime checks remain open; this is not full Definition of Done.

### OpenRouter migration plan
User obtained an OpenRouter key after Groq denied access. Switch to openrouter/free (free-only routing, no paid fallback), update hidden-input key tooling, handle numeric SSE error codes, run parser/client tests and rebuild. Credential entry and live validation remain separate pending steps.

OpenRouter migration complete: app compiled and all 20 unit tests passed, including numeric mid-stream errors and usage frames. UI was unchanged; previous 4 UI-test results are historical. Waiting for local key entry before live request verification.

### ConfigureAI launch fix
Finder launch selected third-party Python.app and failed to read Scripts/embed_key.py with Operation not permitted. Pinned system Python, added a visible failure message with macOS Documents-access steps. Shell syntax and system-Python script loading verified; the user must retry from Terminal to verify its privacy permission context.

Native Cocoa key-entry window compiled and opened. User entered the credential; real OpenRouter SSE request returned 2 content events and [DONE]. App simulator build with embedded key passed. Live UI Stop and quota remain open.

### Final requirements audit
20 unit and 4 default UI tests passed again. Separate LiveAI real-provider UI scenario passed streaming, Stop, preserved partial output, follow-up and restart. Final free quota: 47/50 requests remaining, paid daily usage zero. Release build passed. Found oversized composer icon/footer at maximum Dynamic Type; reduced icon to fixed symbol size, hid supplementary caption in compact/accessibility layouts and limited multiline composer height; targeted visual test rerun pending. iOS 18.5 catalog download rejected as unavailable for both architectures.

Composer visual regression test passed after fix. Full-device screenshots confirm usable portrait/landscape controls at maximum accessibility size. Corrected screenshot-only XCTest API compile error; final run passed.

Final ZIP extracted into a clean directory; its Build.command ran from /private/tmp and succeeded. Extracted Git fsck passed, executable bits preserved. Final tracked-file privacy scan found no plaintext credential or personal home path.

### User-requested usability iteration
Compact searchable conversation list (titles and message contents); new chat directly from conversation; copy/share actions with visible confirmation; keyboard Done and automatic dismissal after send; user-controlled streaming scroll with jump-to-latest button. Preserve streaming/storage semantics. Verify default suite, utility actions, light/dark and large-text screenshots, then update ZIP. Build authorization attempt timed out before execution; retry pending.

### UX iteration validation
Changed ChatView, MessageRow and ChatListView typechecked against previously compiled app domain/state module, targeting arm64 iOS 18 simulator. Updated ChatFlowTests typechecked with XCTest Swift overlay. Neither check executes UI or replaces a full app build. Added scenario covers keyboard dismissal, copying confirmation, new conversation from chat and search by message content. Runtime execution pending.

Two escalated Build.command attempts timed out in automatic permission review before execution. Native Xcode entry also timed out. Restricted build failed at asset catalog because CoreSimulator runtimes were inaccessible. Whole-app standalone typecheck could not spawn sandboxed macro plugins; changed views were then successfully checked against the prebuilt module. No permission settings or sandbox policy were modified.

### Button, appearance and privacy re-audit
Replaced system prominent list button with consistent full-width rounded shape. Added persistent system/light/dark appearance menu. Debug and Release builds passed. All 20 unit + 7 UI tests passed (including search/copy/new-chat and explicit themes/restart). LiveAI real API UI test passed again. Inspected new light/dark screenshots. Enhanced redaction and scrubbed historic logs, preserved chronological commits, expired reflogs/pruned old objects. Final image-metadata-aware security scan and ZIP validation pending. iOS18 runtime remains unavailable.

Additional maximum-accessibility tests passed for appearance/button and landscape. Decorative welcome copy is suppressed at accessibility sizes so the primary button stays near the top. Button colors keep white symbols readable in both themes. Fixture appearance uses a separate preference key so UI tests do not change the real-user selection. Git privacy canaries cover keys, headers, user/device paths, email, UUIDs and image data.

Final current ZIP extracted into a new directory; Build.command ran from /private/tmp and succeeded. Extracted Git fsck and full-object privacy audit passed with zero findings. Source tests/builds described above remain valid; final packaging changes only documentation/log export.
