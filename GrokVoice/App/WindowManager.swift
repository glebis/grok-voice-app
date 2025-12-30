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

    /// Called when wake word is detected via URL scheme
    func activateFromWakeWord(context: ActivationContext = ActivationContext()) {
        logger.info("Activating from wake word")
        guard let controller = windowController else {
            logger.warning("No window controller for wake word activation")
            return
        }

        Task { @MainActor in
            // Open the notch panel
            controller.viewModel.notchOpen()

            // Auto-connect if not already connected
            if controller.viewModel.phase == .idle {
                await controller.viewModel.connect(with: context)
            } else if !context.isEmpty {
                // Already connected - just set the context
                controller.viewModel.setActivationContext(context)
            }
        }
    }
}
