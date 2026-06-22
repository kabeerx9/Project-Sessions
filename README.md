# Project Sessions

Project Sessions is a native macOS app for developers who switch between projects and want to restore a workspace quickly.

Instead of reopening the same browser tabs, project folder, Cursor workspace, and terminal commands manually, a session keeps those details in one place.

## Current Features

- Create, edit, and delete project sessions.
- Store a session name, repository path, browser, browser profile, URLs, and terminal commands.
- Detect installed supported browsers automatically.
- Detect browser profiles for Chromium-based browsers such as Chrome, Brave, and Edge.
- Start a session with one action.
- Open session URLs in the selected browser and browser profile.
- Open the project folder in Finder.
- Open the project in Cursor.
- Launch Terminal commands from the session's repository path.
- Group terminal commands together or run them in separate Terminal windows.
- Track running terminal processes started by the app.
- Show terminal command health as running, exited, failed, or stopped.
- Shut down a workspace by stopping tracked terminal processes and closing Terminal windows created by the app.
- Track whether a session is active.
- Show a full-screen launch overlay when starting a session.
- Provide a menu bar entry for quickly starting saved sessions.
- Store everything locally using UserDefaults.

## MVP Scope

The app is intentionally local-first and simple.

Current MVP focus:

- Project session management
- Browser and URL restore
- Browser profile support
- Cursor launch
- Terminal command launch
- Runtime tracking
- Workspace shutdown

Not included right now:

- Cloud sync
- Team sharing
- AI features
- Pull request dashboards
- Advanced service monitoring
- Terminal app customization beyond macOS Terminal

## Development

Open the project in Xcode:

```bash
open ProjectSessions.xcodeproj
```

Build from the command line:

```bash
xcodebuild -project ProjectSessions.xcodeproj -scheme ProjectSessions -configuration Debug build
```

## Product Direction

The goal is not to become a generic launcher.

The goal is to become a lightweight project operating system for one developer: start a project, restore its workspace, see what is running, and shut it down cleanly.
