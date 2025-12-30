import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowManager: WindowManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon (menubar app)
        NSApp.setActivationPolicy(.accessory)

        // Initialize window manager
        windowManager = WindowManager.shared
        windowManager?.setup()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
