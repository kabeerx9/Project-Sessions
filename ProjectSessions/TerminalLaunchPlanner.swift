import Foundation

struct TerminalLaunchPlan: Identifiable {
    let id = UUID()
    let title: String
    let shellCommand: String
}

enum TerminalLaunchPlanner {
    static func plans(for session: ProjectSession) -> [TerminalLaunchPlan] {
        var plans: [TerminalLaunchPlan] = []
        var commandGroup: [TerminalCommand] = []

        func flushCommandGroup() {
            guard !commandGroup.isEmpty else {
                return
            }

            let title = commandGroup
                .map { displayName(for: $0) }
                .joined(separator: " + ")
            let shellCommand = commandGroup
                .map(\.command)
                .joined(separator: " && ")

            plans.append(TerminalLaunchPlan(title: title, shellCommand: shellCommand))
            commandGroup = []
        }

        for command in session.commands {
            if command.runsInSeparateTab {
                flushCommandGroup()
                plans.append(
                    TerminalLaunchPlan(
                        title: displayName(for: command),
                        shellCommand: command.command
                    )
                )
            } else {
                commandGroup.append(command)
            }
        }

        flushCommandGroup()

        return plans
    }

    private static func displayName(for command: TerminalCommand) -> String {
        command.name.isEmpty ? command.command : command.name
    }
}
