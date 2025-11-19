//
//  MenuBarManager.swift
//  TypeTracer
//
//  Manages the menu bar icon and menus
//

import SwiftUI
import AppKit
import Combine

/// Manages the menu bar status item and its menu
class MenuBarManager: ObservableObject {
    // MARK: - Properties
    private var statusItem: NSStatusItem?
    private var statistics: TypingStatistics
    private var monitor: KeyboardMonitor
    @Published var isWindowVisible: Bool = true
    
    // MARK: - Initialization
    init(statistics: TypingStatistics, monitor: KeyboardMonitor) {
        self.statistics = statistics
        self.monitor = monitor
        setupMenuBar()
    }
    
    // MARK: - Public Methods
    
    /// Toggle window visibility
    func toggleWindow() {
        if isWindowVisible {
            hideWindow()
        } else {
            showWindow()
        }
    }
    
    /// Show the main window
    func showWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // Show all windows
        for window in NSApp.windows {
            window.makeKeyAndOrderFront(nil)
        }
        
        isWindowVisible = true
        updateMenuBarIcon()
    }
    
    /// Hide the main window (but keep monitoring)
    func hideWindow() {
        // Hide all windows but keep the app running
        for window in NSApp.windows {
            window.orderOut(nil)
        }
        
        // Keep app as accessory to hide from Dock when window is hidden
        NSApp.setActivationPolicy(.accessory)
        
        isWindowVisible = false
        updateMenuBarIcon()
    }
    
    // MARK: - Private Methods
    
    /// Set up the menu bar status item
    private func setupMenuBar() {
        // Create status item in menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Set initial icon and title
        updateMenuBarIcon()
        
        // Create and set menu
        setupMenu()
    }
    
    /// Update menu bar icon and text
    private func updateMenuBarIcon() {
        guard let button = statusItem?.button else { return }
        
        // Use keyboard icon
        if let image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "TypeTracer") {
            image.isTemplate = true
            button.image = image
        }
        
        // Add text showing current minute count
        let minuteCount = statistics.getLastMinuteCount()
        button.title = " \(minuteCount)"
        
        // Set up a timer to update the count periodically
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateMenuBarCount()
        }
    }
    
    /// Update the keystroke count in menu bar
    private func updateMenuBarCount() {
        guard let button = statusItem?.button else { return }
        let minuteCount = statistics.getLastMinuteCount()
        button.title = " \(minuteCount)"
    }
    
    /// Set up the menu bar menu
    private func setupMenu() {
        let menu = NSMenu()
        
        // Statistics section
        let statsItem = NSMenuItem()
        statsItem.title = "TypeTracer Statistics"
        statsItem.isEnabled = false
        menu.addItem(statsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Dynamic stats items (will be updated)
        let minuteItem = NSMenuItem()
        minuteItem.title = "Last Minute: \(statistics.getLastMinuteCount())"
        minuteItem.isEnabled = false
        menu.addItem(minuteItem)
        
        let hourItem = NSMenuItem()
        hourItem.title = "Last Hour: \(statistics.getLastHourCount())"
        hourItem.isEnabled = false
        menu.addItem(hourItem)
        
        let dayItem = NSMenuItem()
        dayItem.title = "Today: \(statistics.getLastDayCount())"
        dayItem.isEnabled = false
        menu.addItem(dayItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Monitoring status
        let statusItem = NSMenuItem()
        statusItem.title = monitor.isMonitoring ? "Status: Monitoring" : "Status: Not Monitoring"
        statusItem.isEnabled = false
        menu.addItem(statusItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Show/Hide Window
        let toggleWindowItem = NSMenuItem(
            title: isWindowVisible ? "Hide Window" : "Show Window",
            action: #selector(toggleWindowClicked),
            keyEquivalent: ""
        )
        toggleWindowItem.target = self
        menu.addItem(toggleWindowItem)
        
        // Start/Stop Monitoring
        let toggleMonitorItem = NSMenuItem(
            title: monitor.isMonitoring ? "Stop Monitoring" : "Start Monitoring",
            action: #selector(toggleMonitoringClicked),
            keyEquivalent: ""
        )
        toggleMonitorItem.target = self
        menu.addItem(toggleMonitorItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(
            title: "Quit TypeTracer",
            action: #selector(quitClicked),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        // Set the menu for the status item
        if let item = self.statusItem {
            item.menu = menu
        }
        
        // Update menu periodically
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateMenu()
        }
    }
    
    /// Update menu items with current statistics
    private func updateMenu() {
        guard let menu = statusItem?.menu else { return }
        
        // Update statistics items (indices 2, 3, 4)
        if menu.items.count > 4 {
            menu.items[2].title = "Last Minute: \(statistics.getLastMinuteCount())"
            menu.items[3].title = "Last Hour: \(statistics.getLastHourCount())"
            menu.items[4].title = "Today: \(statistics.getLastDayCount())"
        }
        
        // Update monitoring status (index 6)
        if menu.items.count > 6 {
            menu.items[6].title = monitor.isMonitoring ? "Status: Monitoring" : "Status: Not Monitoring"
        }
        
        // Update toggle window text (index 8)
        if menu.items.count > 8 {
            menu.items[8].title = isWindowVisible ? "Hide Window" : "Show Window"
        }
        
        // Update toggle monitoring text (index 9)
        if menu.items.count > 9 {
            menu.items[9].title = monitor.isMonitoring ? "Stop Monitoring" : "Start Monitoring"
        }
    }
    
    // MARK: - Menu Actions
    
    @objc private func toggleWindowClicked() {
        toggleWindow()
    }
    
    @objc private func toggleMonitoringClicked() {
        if monitor.isMonitoring {
            monitor.stopMonitoring()
        } else {
            if monitor.hasAccessibilityPermission {
                monitor.startMonitoring()
            } else {
                // Show window to prompt for permission
                showWindow()
                monitor.requestAccessibilityPermission()
            }
        }
    }
    
    @objc private func quitClicked() {
        NSApp.terminate(nil)
    }
}

