# Validation report

Environment: Xcode 26.3 (17C529), Swift 6 strict concurrency, XcodeGen 2.46.0, iOS 26.2 SDK, iPhone 17 Pro Simulator running iOS 26.3. Deployment target: iOS 18.0.

## Completed

| Area | Evidence | Result |
| --- | --- | --- |
| XcodeGen | project generated from project.yml during every build | Pass |
| Debug build | Build.command executed after bootstrap, persistence, networking and UI stages | Pass |
| Release build | generic iOS Simulator, Release configuration | Pass |
| Unit suite | 20 XCTest cases, final audit 2026-10-05 22:14 Moscow | Pass |
| UI suite | 4 default cases at 22:17 plus new large-font/landscape case at 22:25 after composer fix | Pass |
| SSE framing | split UTF-8, CR/LF/CRLF, comments, multiline data, oversized input | Pass |
| Network client | URLProtocol supplies real byte streams to the actual OpenRouter client | Pass |
| Errors | offline, timeout, 401, 429, 503, wrong MIME, malformed JSON, early EOF | Pass with fixtures |
| Stop | URLProtocol.stopLoading called; partial response survives; stale callbacks ignored | Pass |
| Retry | replaces failed partial assistant text, no duplicated user turn | Pass |
| Persistence | disk-backed SwiftData store closed/reopened; UI app terminated/relaunched | Pass |
| Multiple chats | independent histories, navigation, confirmed deletion | Pass |
| Light/dark | system appearance, screenshots inspected | Pass |
| Keyboard / long text | stopped partial reply with keyboard; 60-message seeded long history | Pass with fixtures |
| Missing credential | ordinary non-fixture launch manually exercised in Simulator | Correct explicit error |
| Scripts | bash syntax and Python parsing | Pass |

The default tests do not connect to the provider. The separate LiveAI scheme uses the embedded credential and the real OpenRouter API. URLProtocol checks actual HTTP/SSE handling locally; Debug UI fixtures are visibly synthetic text and use a separate persistence store. Production has no artificial answer fallback or simulated streaming delay.

## Test failures fixed / investigation

- Swift 6 rejected a test task capturing non-Sendable XCTestCase. Captured the Sendable service instead.
- A parent accessibility identifier shadowed the Retry button. Removed the parent identifier.
- Created Application Support explicitly, avoiding SwiftData's initial missing-directory recovery trace.
- A launch argument named Dark did not actually change iOS appearance. Verified using simctl system appearance instead; never used the light screenshots as evidence of dark mode.
- During cold simulator startup, first navigation taps sometimes failed to produce the expected element within 5 seconds. Isolated a single simulator and increased navigation waits to 15 seconds. The final complete Test.command run passed. Earlier failed runs remain in the authentic logs; cold-start automation may still be sensitive to host load.
- Adjusted initial conversation scrolling to show latest messages and scroll after generation finishes; verified the Stop/Retry footer in final screenshots.

## Not verified / delivery blockers

- Live OpenRouter authentication, streaming, Stop, follow-up and restart passed in the separate LiveAI UI test (22:20 Moscow).
- iOS 18 runtime unavailable: compiled minimum version is 18.0, but no runtime test on iOS 18.
- No physical-device test/signing. Maximum accessibility font-size controls passed the targeted UI test; portrait screenshot inspected. Landscape controls and full-screen screenshot passed; visually inspected with maximum accessibility font size.
- Offline/rate-limit/timeout scenarios were injected, not produced by disabling the physical network or exhausting a real account.

## Screenshots

`docs/screenshots/light-empty.png` and `dark-empty.png` show the empty chat. Files ending in `-fixture.png` contain deterministic test content, not cloud-generated answers. Screenshots are exported from XCTest attachments and visually inspected. The light screenshots precede the final background-color refinement; the final dark screenshots include it.

## Clean build result

Clean Build.command invocation passed from /private/tmp with PATH=/usr/bin:/bin, after deleting the generated Xcode project and moving DerivedData aside. Confirmed executable permissions and MinimumOSVersion=18.0 in the built app. Details: validation-results.txt. Full Definition of Done remains blocked by untested iOS 18 runtime.

## OpenRouter migration — 2026-10-05 21:53 Moscow
Changed endpoint to OpenRouter and model to openrouter/free with no paid fallback. Hidden-input key script accepts OpenRouter keys. Added numeric SSE error/usage-frame coverage. All 20 unit tests passed and simulator application compiled. No new UI run was needed because views and state logic did not change. Live API remains pending credential entry.

## Live key verification — 2026-10-05
User entered key through native secure field. A real HTTPS request to openrouter/free returned 2 content events and [DONE]. No credential or response body was logged. Debug simulator build with the embedded credential passed. This verifies authentication and provider SSE separately from the iOS app; live UI Stop and remaining quota were subsequently checked below.

## Final real-provider audit
LiveAI/testRealStreamingStopFollowupAndRestart passed. Normal app launch (no fixture arguments) received real text, stopped it during generation, verified no late chunks changed it, completed a second real request, then terminated/relaunched and checked retained answers. Real dark screenshots were exported and visually inspected. Release build passed with MinimumOSVersion=18.0. The key endpoint reported free tier and 49/50 requests remaining before the live UI run; final counter is recorded in README. Both arm64 and universal iOS 18.5 runtime download attempts reported unavailable in the installed Xcode catalog.

### Large-font review fix
At maximum Dynamic Type, the send symbol grew beyond its circle and the supplementary caption consumed too much space. Fixed symbols retain a 44pt button target; caption hides for compact/accessibility layouts; composer limits lines to keep controls usable. Targeted UI test passed after the fix.

The screenshot helper initially used an unavailable XCUIDevice method and failed compilation; corrected to XCUIScreen.main.screenshot. Final targeted run passed and full-device landscape screenshot was inspected. Final default test target compiles. Screenshots dark-*-live.png use real OpenRouter, light-*-large-fixture.png use deterministic fixtures.

Final ZIP extracted into a clean directory; its Build.command ran from /private/tmp and succeeded. Extracted Git fsck passed, executable bits preserved. Final tracked-file privacy scan found no plaintext credential or personal home path.

### UX iteration validation
Changed ChatView, MessageRow and ChatListView typechecked against previously compiled app domain/state module, targeting arm64 iOS 18 simulator. Updated ChatFlowTests typechecked with XCTest Swift overlay. Neither check executes UI or replaces a full app build. Added scenario covers keyboard dismissal, copying confirmation, new conversation from chat and search by message content. Runtime execution pending.

Two escalated Build.command attempts timed out in automatic permission review before execution. Native Xcode entry also timed out. Restricted build failed at asset catalog because CoreSimulator runtimes were inaccessible. Whole-app standalone typecheck could not spawn sandboxed macro plugins; changed views were then successfully checked against the prebuilt module. No permission settings or sandbox policy were modified.

## Current version re-audit — 23:44–23:49 Moscow
Debug/Release passed. 20 unit + 7 UI passed in full Test.command; LiveAI real-provider UI case passed separately. Explicit theme switching and dark persistence after restart are visible in exported, inspected screenshots. Prior UX permission timeouts were resolved for this re-audit. Remaining free requests:44/50, daily paid usage0. Historic reports above describe earlier snapshots.

Additional maximum-accessibility tests passed for appearance/button and landscape. Decorative welcome copy is suppressed at accessibility sizes so the primary button stays near the top. Button colors keep white symbols readable in both themes. Fixture appearance uses a separate preference key so UI tests do not change the real-user selection. Git privacy canaries cover keys, headers, user/device paths, email, UUIDs and image data.

Final current ZIP extracted into a new directory; Build.command ran from /private/tmp and succeeded. Extracted Git fsck and full-object privacy audit passed with zero findings. Source tests/builds described above remain valid; final packaging changes only documentation/log export.
