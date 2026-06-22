# UI Agent Caution File

## Purpose

This file is only a caution/guardrail document for a UI-focused agent.

Do not treat this as a UI design brief.

## Do Not Change

- Do not rewrite the app architecture.
- Do not replace SwiftUI with another UI framework or approach.
- Do not change persistence behavior.
- Do not change the `ProjectSession` data model unless explicitly asked.
- Do not change browser detection logic.
- Do not change browser profile detection logic.
- Do not change URL launching logic.
- Do not change Cursor launching logic.
- Do not change Terminal command execution logic.
- Do not change Terminal process tracking logic.
- Do not change workspace shutdown logic.
- Do not remove existing features.
- Do not add cloud sync.
- Do not add AI features.
- Do not add accounts, auth, teams, or collaboration.
- Do not add new product features unless explicitly requested.
- Do not introduce a large state-management pattern.
- Do not add MVVM/coordinator/repository abstractions just for cleanup.
- Do not do broad refactors unrelated to UI.

## Behavior That Must Keep Working

- Create session.
- Edit session.
- Delete session.
- Select session.
- Persist sessions across app restarts.
- Detect installed supported browsers.
- Detect Chrome, Brave, and Edge profiles.
- Save the real browser profile directory name.
- Open all configured URLs.
- Open URLs in the selected browser/profile.
- Open the repository in Cursor.
- Run configured Terminal commands.
- Track Terminal command status.
- Stop tracked Terminal commands.
- Close Terminal windows/tabs created by Project Sessions.
- Leave unrelated Terminal windows alone.

## Regression Checklist

After UI changes, manually verify:

- Existing saved sessions still load.
- Creating a new session still works.
- Editing a session still works.
- Deleting a session still works.
- Browser picker still shows installed supported browsers.
- Browser profile picker still works for Chrome, Brave, and Edge.
- Launch URLs opens every configured URL.
- Launch session opens URLs, Cursor, and Terminal commands.
- Terminal command status updates correctly.
- Shutdown workspace stops tracked commands.
- Shutdown workspace closes only Project Sessions Terminal windows/tabs.

## Stop And Ask First

Stop and ask before changing files related to:

- Browser launching
- Browser profile detection
- Terminal execution
- Terminal process tracking
- Workspace shutdown
- Session persistence
- Data model migrations
