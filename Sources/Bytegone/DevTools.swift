import Foundation
import SwiftUI
import AppKit

// MARK: - Tool definition

enum DeveloperTool: String, CaseIterable, Identifiable {
    case docker        // automated
    case homebrew      // automated
    case npkill        // recommendation only (project scan = needs user judgment)
    case cargoSweep    // recommendation only

    var id: String { rawValue }

    var name: String {
        switch self {
        case .docker:     return "Docker"
        case .homebrew:   return "Homebrew"
        case .npkill:     return "node_modules cleanup"
        case .cargoSweep: return "Rust target dirs"
        }
    }

    var icon: String {
        switch self {
        case .docker:     return "shippingbox.fill"
        case .homebrew:   return "mug.fill"
        case .npkill:     return "tray.full.fill"
        case .cargoSweep: return "wrench.and.screwdriver.fill"
        }
    }

    var accent: Color {
        switch self {
        case .docker:     return Color(red: 0.13, green: 0.50, blue: 0.96) // docker blue
        case .homebrew:   return Color(red: 0.95, green: 0.65, blue: 0.20) // brew amber
        case .npkill:     return Color(red: 0.83, green: 0.20, blue: 0.20) // npm red
        case .cargoSweep: return Color(red: 0.85, green: 0.45, blue: 0.20) // rust orange
        }
    }

    var summary: String {
        switch self {
        case .docker:
            return "Wipe stopped containers, dangling images, unused networks, and reclaimable volumes."
        case .homebrew:
            return "Remove outdated formula downloads and cellar versions left after updates."
        case .npkill:
            return "Find and delete node_modules in old projects you haven't touched in months."
        case .cargoSweep:
            return "Recursively clean stale Rust target/ directories across all your projects."
        }
    }

    var binaryName: String? {
        switch self {
        case .docker:   return "docker"
        case .homebrew: return "brew"
        default:        return nil
        }
    }

    var checkCommand: String? {
        switch self {
        case .docker:   return "docker system df"
        case .homebrew: return "brew cleanup -n"
        default:        return nil
        }
    }

    var cleanCommand: String? {
        switch self {
        case .docker:   return "docker system prune -a --volumes -f"
        case .homebrew: return "brew cleanup -s"
        default:        return nil
        }
    }

    var recommendedCommand: String? {
        switch self {
        case .npkill:     return "npx npkill"
        case .cargoSweep: return "cargo install cargo-sweep && cargo sweep -r -t 30 ~"
        default:          return nil
        }
    }

    var warning: String? {
        switch self {
        case .docker:
            return "Stops nothing, but removes ALL data not attached to a running container. Make sure your stack is running before cleanup if you depend on a volume."
        case .homebrew:
            return "Safe — only deletes downloads and outdated versions Homebrew already considers reclaimable."
        default:
            return nil
        }
    }

    var hasAutomation: Bool { binaryName != nil && cleanCommand != nil }
}

// MARK: - Shell runner

enum ShellRunner {
    /// Runs `command` via the user's login zsh so PATH includes Homebrew, etc.
    static func run(_ command: String, timeout: TimeInterval = 90) async -> (stdout: String, stderr: String, status: Int32) {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/zsh")
                // -l forces a login shell so .zprofile / .zshrc populate PATH.
                process.arguments = [
                    "-l", "-c",
                    "export PATH=\"/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH\"; \(command)"
                ]

                let outPipe = Pipe()
                let errPipe = Pipe()
                process.standardOutput = outPipe
                process.standardError = errPipe

                do {
                    try process.run()
                } catch {
                    continuation.resume(returning: (
                        "",
                        "Failed to launch shell: \(error.localizedDescription)",
                        -1
                    ))
                    return
                }

                process.waitUntilExit()
                let out = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                continuation.resume(returning: (out, err, process.terminationStatus))
            }
        }
    }

    static func isInstalled(_ binary: String) async -> Bool {
        let result = await run("command -v \(binary)")
        let trimmed = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        return result.status == 0 && !trimmed.isEmpty
    }
}

// MARK: - Per-tool reactive state

enum ToolStatus: Equatable {
    case unknown
    case checking
    case installed
    case notInstalled
    case running
    case idle           // installed + check has completed
}

struct ToolState: Equatable {
    var status: ToolStatus = .unknown
    var output: String = ""
    var lastReclaimable: String? = nil   // parsed reclaimable size, when available
    var error: String? = nil
}

// MARK: - DevTools store

@MainActor
final class DevToolsStore: ObservableObject {
    @Published var states: [DeveloperTool: ToolState] = [:]

    func state(for tool: DeveloperTool) -> ToolState {
        states[tool] ?? ToolState()
    }

    /// Detect installation status for every automated tool.
    func refreshInstallStatus() async {
        for tool in DeveloperTool.allCases where tool.hasAutomation {
            states[tool, default: ToolState()].status = .checking
            let installed = await ShellRunner.isInstalled(tool.binaryName ?? "")
            withAnimation(.smooth(duration: 0.3)) {
                states[tool, default: ToolState()].status = installed ? .installed : .notInstalled
            }
        }
    }

    /// Run the tool's check command (size estimate) and store the output.
    func check(_ tool: DeveloperTool) async {
        guard let cmd = tool.checkCommand else { return }
        var st = state(for: tool)
        st.status = .running
        st.output = "$ \(cmd)\n"
        st.error = nil
        states[tool] = st

        let result = await ShellRunner.run(cmd)
        var newState = state(for: tool)
        newState.output = "$ \(cmd)\n\n" + result.stdout + (result.stderr.isEmpty ? "" : "\n[stderr]\n" + result.stderr)
        newState.lastReclaimable = parseReclaimable(tool: tool, output: result.stdout)
        newState.status = result.status == 0 ? .idle : .installed
        if result.status != 0 { newState.error = "Exit \(result.status)" }
        withAnimation(.smooth(duration: 0.3)) { states[tool] = newState }
    }

    /// Run the tool's cleanup command.
    func clean(_ tool: DeveloperTool) async {
        guard let command = tool.cleanCommand else { return }

        var st = state(for: tool)
        st.status = .running
        st.output = "$ \(command)\n"
        st.error = nil
        states[tool] = st

        let result = await ShellRunner.run(command, timeout: 600)
        var newState = state(for: tool)
        newState.output = "$ \(command)\n\n" + result.stdout + (result.stderr.isEmpty ? "" : "\n[stderr]\n" + result.stderr)
        newState.status = result.status == 0 ? .idle : .installed
        if result.status != 0 { newState.error = "Exit \(result.status)" }
        newState.lastReclaimable = nil
        withAnimation(.smooth(duration: 0.3)) { states[tool] = newState }
    }

    private func parseReclaimable(tool: DeveloperTool, output: String) -> String? {
        switch tool {
        case .docker:
            // Look for a "RECLAIMABLE" column total in `docker system df` output.
            // Lines look like: "Images 12 4 1.234GB 800MB (64%)"
            // Sum of reclaimable column would need parsing — easier to surface
            // the whole table; for the badge we just look for "Total reclaimable".
            for line in output.split(separator: "\n") {
                if line.lowercased().contains("total reclaimable") {
                    return String(line).trimmingCharacters(in: .whitespaces)
                }
            }
            // Fallback: pull the last column from the Images row if present.
            return nil
        case .homebrew:
            // `brew cleanup -n` ends with: "This operation would free approximately 432.1MB of disk space."
            for line in output.split(separator: "\n").reversed() {
                let s = String(line).lowercased()
                if s.contains("would free") || s.contains("removed") {
                    return String(line).trimmingCharacters(in: .whitespaces)
                }
            }
            return nil
        default:
            return nil
        }
    }
}
