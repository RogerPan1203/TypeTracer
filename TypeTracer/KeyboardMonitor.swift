//
//  KeyboardMonitor.swift
//  TypeTracer
//
//  Monitors keyboard events and tracks typing statistics
//

import Cocoa
import Combine

/// Monitors global keyboard events and tracks keystroke counts
class KeyboardMonitor: ObservableObject {
    // MARK: - Published Properties
    @Published var totalKeystrokes: Int = 0
    @Published var isMonitoring: Bool = false
    @Published var hasAccessibilityPermission: Bool = false
    
    // MARK: - Private Properties
    private var eventMonitor: Any?
    private var statistics: TypingStatistics
    private var permissionCheckTimer: Timer?
    
    // MARK: - Initialization
    init(statistics: TypingStatistics) {
        self.statistics = statistics
        checkAccessibilityPermission()
        
        // Set up a timer to periodically check permissions
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkAccessibilityPermission()
        }
    }
    
    deinit {
        stopMonitoring()
        permissionCheckTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Start monitoring keyboard events
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        // Check if we have accessibility permission
        guard AXIsProcessTrusted() else {
            hasAccessibilityPermission = false
            return
        }
        
        hasAccessibilityPermission = true
        
        // Create global event monitor for key down events
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        
        isMonitoring = true
    }
    
    /// Stop monitoring keyboard events
    func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        isMonitoring = false
    }
    
    /// Request accessibility permission from the system
    func requestAccessibilityPermission() {
        // Open System Preferences directly to Accessibility settings
        // This works on both English and Chinese systems
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        } else {
            // Fallback: show system prompt dialog
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
            AXIsProcessTrustedWithOptions(options)
        }
    }
    
    // MARK: - Private Methods
    
    /// Handle individual key events
    private func handleKeyEvent(_ event: NSEvent) {
        // Only count if there's actual key input (not just modifier keys)
        if let characters = event.characters, !characters.isEmpty {
            DispatchQueue.main.async { [weak self] in
                self?.statistics.recordKeystroke()
                self?.totalKeystrokes = self?.statistics.getTotalKeystrokes() ?? 0
            }
        }
    }
    
    /// Check if the app has accessibility permission
    private func checkAccessibilityPermission() {
        let trusted = AXIsProcessTrusted()
        if trusted != hasAccessibilityPermission {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.hasAccessibilityPermission = trusted
                if trusted && !self.isMonitoring {
                    self.startMonitoring()
                }
            }
        }
    }
}

