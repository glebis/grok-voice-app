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

        // Register for URL events
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent reply: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString) else {
            return
        }

        print("[AppDelegate] Received URL: \(url)")

        // Handle grokvoice://activate and grokvoice://activate?...
        if url.host == "activate" {
            let context = ActivationContext.from(url: url)
            print("[AppDelegate] Activating with context: session=\(context.sessionId ?? "none"), url=\(context.url?.absoluteString ?? "none")")
            WindowManager.shared.activateFromWakeWord(context: context)
        }
    }
}
