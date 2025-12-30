//
//  WindowManager.swift
//  GrokVoice
//
//  Manages the notch window lifecycle
//

import AppKit
import os.log

private let logger = Logger(subsystem: "com.glebkalinin.GrokVoice", category: "Window")

class WindowManager {
    static let shared = WindowManager()

    private(set) var windowController: NotchWindowController?

    private init() {}

    func setup() {
        _ = setupNotchWindow()
    }

    func setupNotchWindow() -> NotchWindowController? {
        guard let screen = NSScreen.builtin else {
            logger.warning("No screen found")
            return nil
        }

        if let existingController = windowController {
            existingController.window?.orderOut(nil)
            existingController.window?.close()
            windowController = nil
        }

        windowController = NotchWindowController(screen: screen)
        windowController?.showWindow(nil)

        return windowController
    }
}
