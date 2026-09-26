# DevinMobile repository guide

Read `CLAUDE.md` before code changes and retain its MVVM/Observation, Swift concurrency, APIClient actor, design-system, availability, local cache, and no-third-party-dependency requirements. This is the implemented Swift app, distinct from the lowercase specification-only repository. `DevinMobile/` contains application sources and `DevinMobile.xcodeproj` owns the build settings.

The project declares iOS 26.0, Swift 6.0, and complete concurrency checking. Use macOS/Xcode with the iOS 26 SDK and any FoundationModels APIs used by the source; the README's Xcode 16.2 minimum alone is not sufficient evidence that those SDKs are installed. Inspect schemes/destinations with `xcodebuild -list -project DevinMobile.xcodeproj`, then build the DevinMobile scheme for an explicitly available simulator or device. There is no separate test target in the checked-in project; don't invent a test-suite pass.

For authorized runtime checks, exercise affected session navigation, loading/errors, and API interactions using safe data. Devin credentials belong in Keychain, and session creation/messages/termination and uploads are remote mutations. Simulator/build evidence does not prove device Live Activities or model availability. Release/upload scripts are publication actions and should not be used as build checks.

## Completing work

Carry the authorized change through the relevant checks and repair failures it causes. Make routine, reversible implementation choices using existing patterns; ask only when missing information, a material product decision, or an authorization boundary prevents the next step. Existing authorization remains valid within its scope. If blocked, name the exact action and missing prerequisite, retain concise evidence, and continue independent work.

Choose verification proportional to the change. For instructions or prose, inspect changed paths, links, and local instruction precedence and run `git diff --check -- <changed-paths>`; don't install dependencies or run the application solely for a prose edit. For behavior changes, exercise the affected behavior and applicable checks below, then broaden only for failures or unresolved risk. Report files changed, checks actually run and their results, commands only inspected, and remaining limitations. A build or source inspection alone does not prove runtime behavior. Continue through already-authorized follow-through; stop at explicit review checkpoints or boundaries requiring new authorization.
