# Project Sessions Learning Plan

This file is the learning and implementation roadmap for Project Sessions.

The goal is to learn Swift, SwiftUI, and macOS app development by building a real local-first macOS app for restoring developer project workspaces.

## Product Vision

Project Sessions is a native macOS application for developers who work across multiple projects and frequently switch contexts.

The app should reduce repetitive setup work when switching projects. Instead of manually opening browser tabs, Cursor workspaces, terminal commands, documentation pages, and localhost URLs, a developer should be able to restore a project workspace with one action.

The first version should stay simple, local-only, and focused on real workflow value.

## MVP Scope

The first version should support:

- [ ] Create project sessions
- [ ] Edit project sessions
- [ ] Delete project sessions
- [ ] Store a session name
- [ ] Store browser URLs
- [ ] Store a repository path
- [ ] Store terminal commands
- [ ] Launch URLs in a browser
- [ ] Open the repository in Cursor
- [ ] Persist sessions locally

Out of scope for MVP:

- [ ] AI features
- [ ] Cloud sync
- [ ] Team features
- [ ] Pull request integrations
- [ ] Terminal process management
- [ ] Automatic service health checks

## Learning Principles

- Learn one concept at a time.
- Implement a small piece after each concept.
- Prefer native macOS behavior over web-app patterns.
- Prefer simple SwiftUI before introducing AppKit.
- Avoid architecture patterns until the app needs them.
- Keep each step connected to Project Sessions.
- Prefer early visible progress over perfect structure.

## Learning Order

1. SwiftUI fundamentals
2. Lists and collections
3. State
4. Struct models
5. Codable
6. UserDefaults
7. Forms and editing
8. Navigation
9. Launching apps and URLs with NSWorkspace
10. Process API
11. macOS app polish
12. MenuBarExtra
13. AppKit only when needed

## Section 1: SwiftUI Fundamentals

SwiftUI views are closest to React function components. A view describes what the UI should look like for the current state.

### React Equivalent

- `View` = component contract
- `body` = render output
- `some View` = opaque return type for UI
- `VStack` = vertical flex column
- `HStack` = horizontal flex row
- `Spacer` = flexible empty space
- Modifiers = chained styling and behavior helpers

### Concepts To Learn

- [x] `View`
- [x] `body`
- [x] `some View`
- [x] `Text`
- [x] `Image`
- [x] `VStack`
- [x] `HStack`
- [x] `Spacer`
- [x] `.padding()`
- [x] `.frame()`
- [x] `.font()`
- [x] `.foregroundStyle()`
- [x] SwiftUI modifiers
- [ ] Xcode previews

### Project Implementation

- [x] Replace the default "Hello, world!" screen
- [x] Create a basic Project Sessions home screen
- [x] Add a title
- [x] Add a short empty state
- [x] Add a placeholder button for creating a session

### Example Exercise

```swift
struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Project Sessions")
                .font(.largeTitle)

            Text("Restore your development workspace.")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
```

## Section 2: Lists and Collections

A SwiftUI `List` is similar to rendering an array with `.map()` in React, but it also gives native macOS list behavior.

### React Equivalent

- `Array` = `ProjectSession[]`
- `List` = native list container
- `ForEach` = `.map()`
- `Identifiable` = stable React `key`
- Empty state = conditional render when array is empty

### Concepts To Learn

- [x] Arrays in Swift
- [x] `List`
- [x] `ForEach`
- [x] `Identifiable`
- [x] Static list rows
- [x] Dynamic list rows
- [ ] Empty states

### Project Implementation

- [x] Show a list of project sessions
- [x] Create temporary hardcoded sessions
- [x] Render each session name
- [x] Render a short summary of URLs or repository path
- [ ] Show an empty state when no sessions exist

### Example Exercise

```swift
struct ProjectSession: Identifiable {
    let id = UUID()
    let name: String
}

let sessions = [
    ProjectSession(name: "Fantasy App"),
    ProjectSession(name: "Project Sessions")
]
```

## Section 3: State

`@State` is roughly equivalent to `useState`. It stores local view state and causes the view to update when the value changes.

### React Equivalent

- `@State` = `useState`
- `Button` action = `onClick`
- State-driven rendering = JSX changing when state changes
- Mutating an array = `setSessions(...)`
- `private` state = component-local state

### Concepts To Learn

- [x] `@State`
- [x] State-driven rendering
- [x] Button actions
- [x] Mutating arrays
- [x] Local UI state
- [x] Simple form state

### Project Implementation

- [x] Store sessions in local `@State`
- [x] Add a button that creates a temporary session
- [x] Add a delete action
- [ ] Add selected session state

### Example Exercise

```swift
@State private var sessions: [ProjectSession] = []
```

## Section 4: Struct Models

Swift structs are commonly used for app data. For this app, a `ProjectSession` model will represent one saved workspace.

### React Equivalent

- `struct ProjectSession` = TypeScript `type` or `interface` plus value behavior
- Stored properties = object fields
- `UUID` = stable id for rendering and persistence
- Optional value = `string | undefined`, but checked by the compiler
- Model file = shared TypeScript model file

### Concepts To Learn

- [x] `struct`
- [x] Stored properties
- [x] `UUID`
- [x] Optional values
- [x] Arrays of models
- [x] Separating models from views

### Project Implementation

- [x] Create a `ProjectSession` model
- [x] Add `name`
- [x] Add `browser`
- [x] Add `urls`
- [x] Add `repositoryPath`
- [x] Move the model into its own file

### Target Model

```swift
struct ProjectSession: Identifiable {
    let id: UUID
    var name: String
    var browser: String
    var urls: [String]
    var repositoryPath: String
}
```

## Section 5: Codable

`Codable` is Swift's built-in way to convert data models to and from JSON. It is similar to serializing typed objects in TypeScript, but Swift can synthesize a lot of the conversion automatically.

### React Equivalent

- `Codable` = typed JSON serialize and parse support
- `Encodable` = object to JSON
- `Decodable` = JSON to object
- `JSONEncoder` = `JSON.stringify` with Swift types
- `JSONDecoder` = `JSON.parse` with Swift types

### Concepts To Learn

- [x] `Codable`
- [x] `Encodable`
- [x] `Decodable`
- [x] JSON encoding
- [x] JSON decoding
- [x] Error handling basics

### Project Implementation

- [x] Make `ProjectSession` conform to `Codable`
- [x] Encode sessions to JSON
- [x] Decode sessions from JSON
- [x] Handle invalid saved data simply

### Target Model Update

```swift
struct ProjectSession: Identifiable, Codable {
    var id: UUID
    var name: String
    var browser: String
    var urls: [String]
    var repositoryPath: String
}
```

## Section 6: UserDefaults and Local Persistence

`UserDefaults` is a simple local key-value store. For the MVP, it is enough for saving a small list of sessions.

This section comes early because the first big product milestone is making sessions survive app restarts.

### React Equivalent

- `UserDefaults` = `localStorage`, but native to Apple platforms
- Storage key = `localStorage` key
- Load on app start = initial state hydration
- Save after changes = persist state after mutation

### Concepts To Learn

- [x] `UserDefaults`
- [x] Saving data locally
- [x] Loading data at app startup
- [x] Choosing storage keys
- [ ] When not to use `UserDefaults`

### Project Implementation

- [x] Save sessions to `UserDefaults`
- [x] Load sessions when the app opens
- [x] Persist create and delete actions
- [x] Confirm sessions survive app restart

### First Persistence Milestone

By the end of this section, the app should be able to show sample sessions such as:

- [x] Fantasy App
- [x] Dashboard
- [x] SaaS

Those sessions should survive quitting and reopening the app.

Future note:

- [ ] Consider moving to JSON files or SwiftData after the MVP if sessions become more complex

## Section 7: Forms and Editing

Forms let the user create and edit data. In this app, forms are needed for creating and editing project sessions after the basic persistence loop works.

### React Equivalent

- `Form` = form layout component
- `TextField` = controlled input
- `$name` binding = `value` plus `onChange`
- `@Binding` = passing state setter behavior into a child component
- `Picker` = select/dropdown input
- Swift enum = TypeScript string union with behavior
- Sheet = modal

### Concepts To Learn

- [x] `Form`
- [x] `TextField`
- [x] `Button`
- [ ] `Toggle`
- [x] `Picker`
- [x] Enum-backed form options
- [x] Bindings with `$`
- [x] `@Binding`
- [x] Sheet presentation
- [x] Extracting reusable form views

### Project Implementation

- [x] Create a new session form
- [x] Edit an existing session
- [x] Add and remove URLs
- [x] Save form values into app state
- [x] Persist form changes to `UserDefaults`
- [x] Cancel editing
- [x] Reuse one form view for create and edit sheets
- [x] Replace free-text browser input with a browser picker

### Example Exercise

```swift
TextField("Session name", text: $name)
```

## Section 8: Navigation

Navigation in SwiftUI is similar to moving between screens or routes in React, but it is built into the native UI framework.

### React Equivalent

- `NavigationSplitView` = sidebar layout with a detail route
- `NavigationStack` = stacked screen navigation
- Selection state = selected item id
- Detail view = route/page for selected data
- Fallback detail = empty route state
- Child navigation view = React route/layout component

### Concepts To Learn

- [x] `NavigationSplitView`
- [ ] `NavigationStack`
- [x] Sidebar layouts
- [x] Detail views
- [x] Selection state
- [x] macOS navigation conventions
- [x] Passing action closures into child views

### Project Implementation

- [x] Create a sidebar with all project sessions
- [x] Create a detail view for the selected session
- [x] Show session details on the right side
- [x] Add a fallback detail view when nothing is selected
- [x] Extract the sidebar into `SessionSidebarView`
- [x] Extract the detail pane into `SessionDetailView`

### Example Exercise

```swift
NavigationSplitView {
    List(sessions) { session in
        Text(session.name)
    }
} detail: {
    Text("Select a session")
}
```

## Section 9: Launching Apps and URLs with NSWorkspace

macOS apps can open URLs, files, folders, and other apps. This is where Project Sessions starts becoming useful.

### React Equivalent

- `NSWorkspace.shared.open(url)` = opening an external URL from the browser
- File URL = local file or folder path
- Bundle identifier = app package id
- Launch failure = rejected promise or failed side effect

### Concepts To Learn

- [x] `NSWorkspace`
- [x] Opening URLs
- [x] Opening local folders
- [x] Launching apps
- [x] Basic error handling
- [ ] App bundle identifiers
- [ ] File paths and `URL(fileURLWithPath:)`

### Project Implementation

- [x] Launch all URLs for a session
- [x] Open a repository path in Finder
- [x] Open a repository path in Cursor
- [x] Add a "Launch Session" button
- [x] Show a simple failure message if something cannot be opened

### Example Exercise

```swift
if let url = URL(string: "https://github.com") {
    NSWorkspace.shared.open(url)
}
```

## Section 10: Process API

The Process API is for starting and controlling command-line programs. It should come after `NSWorkspace` because launching URLs and apps is enough for the MVP.

### React Equivalent

- `Process` = Node's `child_process`
- Executable URL = command path
- Arguments = command arguments array
- Environment = process environment variables
- Termination status = exit code

### Concepts To Learn

- [x] `Process`
- [x] Executable paths
- [x] Arguments
- [ ] Working directories
- [ ] Environment variables
- [ ] Reading output later
- [ ] Knowing when not to run shell commands from the app

### Project Implementation

- [ ] Explore how a command could be launched
- [x] Store terminal commands without running them
- [x] Defer automatic terminal command execution until after the MVP
- [ ] Decide whether terminal control belongs in the app

## Section 11: macOS App Polish

After the MVP works, improve how the app feels as a native macOS application.

### React Equivalent

- Toolbar = app-level action bar
- Keyboard shortcut = global or scoped hotkey
- Alert = native confirmation dialog
- Menu command = desktop app menu item
- App icon = favicon plus installed app identity

### Concepts To Learn

- [ ] Window sizing
- [ ] Toolbar buttons
- [ ] Keyboard shortcuts
- [ ] Menus
- [x] Confirmation dialogs
- [x] Native alerts
- [ ] App icon basics

### Project Implementation

- [ ] Add toolbar actions
- [ ] Add keyboard shortcut for creating a session
- [x] Add delete confirmation
- [ ] Improve empty states
- [ ] Add app icon

## Section 12: MenuBarExtra

`MenuBarExtra` allows a macOS app to live in the menu bar. This can make Project Sessions feel like a fast project launcher.

### React Equivalent

- `MenuBarExtra` = persistent system-level mini UI
- Menu item action = compact command button
- Shared app state = state used by multiple views
- Main window = full editing surface

### Concepts To Learn

- [ ] `MenuBarExtra`
- [ ] Menu bar app behavior
- [ ] Commands inside a menu
- [ ] Sharing state between windows and menu bar

### Project Implementation

- [ ] Add a menu bar item
- [ ] List saved sessions in the menu bar
- [ ] Launch a session from the menu bar
- [ ] Keep the main window available for editing

## Section 13: AppKit Only When Needed

SwiftUI should be the default. AppKit should be introduced only when SwiftUI cannot cleanly solve a macOS-specific problem.

### React Equivalent

- AppKit = lower-level native UI framework
- SwiftUI wrapping AppKit = React component wrapping an imperative library
- `NSOpenPanel` = native file or folder picker
- Advanced window control = browser APIs that React does not own directly

### Concepts To Learn Later

- [x] What AppKit is
- [x] When SwiftUI wraps AppKit
- [x] `NSOpenPanel`
- [x] Choosing folders
- [ ] Advanced window behavior

### Project Implementation

- [x] Use `NSOpenPanel` to select a repository folder
- [x] Store the selected path in a session
- [ ] Avoid AppKit for normal layout and forms

## Future Features

These should wait until the MVP is complete.

### Session Restore

- [ ] Browser profile support
- [ ] Open multiple browser tabs
- [ ] Open Cursor workspace
- [ ] Open Ghostty windows
- [ ] Run terminal commands

### Session Health

- [ ] Detect running local servers
- [ ] Show browser status
- [ ] Show frontend status
- [ ] Show backend status
- [ ] Show simulator status

### Project Dashboard

- [ ] Show current Git branch
- [ ] Show uncommitted file count
- [ ] Show open pull requests
- [ ] Show running services

### Workspace Shutdown

- [ ] Stop project servers
- [ ] Close project terminal windows
- [ ] Close project browser windows

## Suggested Implementation Order

Follow this order unless there is a specific reason to jump ahead:

1. Build a static home screen
2. Render hardcoded sessions in a list
3. Add local state
4. Create the `ProjectSession` model
5. Make the model `Codable`
6. Save and load sample sessions with `UserDefaults`
7. Build create and edit forms
8. Add delete support
9. Add navigation split view
10. Launch URLs with `NSWorkspace`
11. Open repository paths
12. Open repositories in Cursor
13. Add macOS polish
14. Add menu bar support

## Current Next Step

- [x] Open a repository path in Finder
- [x] Open a repository path in Cursor
- [ ] Add browser-specific launch behavior
