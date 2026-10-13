# Current delivery audit — 2026-10-05

| Assignment requirement | Evidence / status |
| --- | --- |
| Real AI and streamed response | Passed separate LiveAI UI scenario using OpenRouter |
| Stop, retained partial text, next question | Passed real-provider UI scenario and cancellation unit tests |
| Multiple chats, switching, deletion | Passed full default UI suite |
| History after full app restart | Passed real-provider/default UI cases and disk unit test |
| Empty/loading/error/Retry | Passed UI/unit cases; retry does not duplicate user prompt |
| Offline, timeout, quota, HTTP, malformed SSE | Tested by deterministic actual-client/parser fixtures; real quota deliberately not exhausted |
| Native light/dark | Explicit system/light/dark menu, persisted setting; screenshots visually inspected |
| New-conversation button | Fixed rounded shape and readable contrast; normal/max font UI cases passed |
| Keyboard, large text, landscape, long history | Default suite plus maximum-accessibility targeted tests passed |
| iOS 18 minimum target | Debug/Release built with MinimumOSVersion=18.0 |
| Actual iOS 18 execution | NOT VERIFIED: Xcode catalog cannot download arm64/universal iOS18.5 runtime |
| Available latest installed runtime | Tested iPhone 17 Pro Simulator / iOS26.3 |
| XcodeGen / Build.command / SPM | Builds passed; no third-party dependencies; clean ZIP build verification below |
| Embedded obfuscated key, no reviewer setup | Included intentionally per assignment; not a cryptographic protection scheme |
| Free quota for reviewer | 44/50 requests left, zero paid daily usage at latest key check; quota-check.json |
| Planning, agent rules, README, time | Included and updated; actual observed intervals in time.json |
| Incremental Git history | Chronological stages/dates preserved; IDs changed to clean old log versions |
| Sanitized AI logs / personal data | Current and historical exports sanitized; reflogs expired; unreachable objects pruned; zero-finding security-audit.json |
| Tests | 20 unit + 7 UI full suite passed; real-provider UI case passed; targeted theme/large-text cases passed |
| Release | Final build passed |

Full runtime coverage is still pending iOS18 execution. Physical-device signing was not tested. Optional photo/Mac/offline features were not implemented. The key remains recoverable from a client bundle, as required by the embedded-key specification. Privacy checks cover delivered logs/source/Git and PNG text metadata; original private Codex session files are not part of the ZIP.

Final current ZIP extracted into a new directory; Build.command ran from /private/tmp and succeeded. Extracted Git fsck and full-object privacy audit passed with zero findings. Source tests/builds described above remain valid; final packaging changes only documentation/log export.
