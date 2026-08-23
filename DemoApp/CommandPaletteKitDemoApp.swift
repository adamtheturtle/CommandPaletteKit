import CommandPaletteKit
import SwiftUI

@main
struct CommandPaletteKitDemoApp: App {
    @State private var showingPalette = false

    var body: some Scene {
        WindowGroup {
            DemoContentView(showingPalette: $showingPalette)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Command Palette") { showingPalette = true }
                    .keyboardShortcut("k", modifiers: .command)
            }
        }
    }
}

private struct DemoContentView: View {
    @Binding var showingPalette: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text("CommandPaletteKit Demo")
                .font(.title)
            Button("Open Command Palette") { showingPalette = true }
                .keyboardShortcut("k", modifiers: .command)
        }
        .frame(minWidth: 420, minHeight: 320)
        .sheet(isPresented: $showingPalette) {
            CommandPaletteView(candidates: demoCandidates)
        }
    }

    @MainActor
    private func demoCandidates() -> [PaletteResult] {
        [
            PaletteResult(
                id: "command.new",
                title: "New Document",
                subtitle: "Create a blank document",
                category: "Command",
                systemImage: "plus.square"
            ) {},
            PaletteResult(
                id: "nav.settings",
                title: "Settings",
                category: "Navigate",
                systemImage: "gearshape"
            ) {}
        ]
    }
}
