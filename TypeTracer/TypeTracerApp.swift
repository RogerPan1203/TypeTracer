//
//  TypeTracerApp.swift
//  TypeTracer
//
//  Created by Roger on 11/18/25.
//

import SwiftUI

/// App delegate to handle menu bar and lifecycle
class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarManager: MenuBarManager?
    var statistics: TypingStatistics?
    var monitor: KeyboardMonitor?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar manager will be set up by ContentView
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Don't quit when window is closed - we have a menu bar item
        return false
    }
}

@main
struct TypeTracerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView(appDelegate: appDelegate)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            // Remove the "New Window" command
            CommandGroup(replacing: .newItem) { }
        }
    }
}
