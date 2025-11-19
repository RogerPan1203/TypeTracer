//
//  TypingStatistics.swift
//  TypeTracer
//
//  Manages typing statistics and historical data
//

import Foundation
import Combine

/// Represents a keystroke record with timestamp
struct KeystrokeRecord: Codable {
    let timestamp: Date
    let count: Int
}

/// Manages typing statistics for different time intervals
class TypingStatistics: ObservableObject {
    // MARK: - Published Properties
    @Published var currentMinuteCount: Int = 0
    @Published var currentHourCount: Int = 0
    @Published var currentDayCount: Int = 0
    
    // MARK: - Private Properties
    private var keystrokeHistory: [Date] = []
    private var updateTimer: Timer?
    private let userDefaults = UserDefaults.standard
    private let historyKey = "keystrokeHistory"
    
    // MARK: - Initialization
    init() {
        loadHistory()
        startUpdateTimer()
    }
    
    deinit {
        updateTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Record a single keystroke
    func recordKeystroke() {
        let now = Date()
        keystrokeHistory.append(now)
        updateCounts()
        saveHistory()
    }
    
    /// Get total keystrokes
    func getTotalKeystrokes() -> Int {
        return keystrokeHistory.count
    }
    
    /// Get keystrokes for the last minute
    func getLastMinuteCount() -> Int {
        return getKeystrokesInTimeInterval(seconds: 60)
    }
    
    /// Get keystrokes for the last hour
    func getLastHourCount() -> Int {
        return getKeystrokesInTimeInterval(seconds: 3600)
    }
    
    /// Get keystrokes for the last 24 hours
    func getLastDayCount() -> Int {
        return getKeystrokesInTimeInterval(seconds: 86400)
    }
    
    /// Clear all statistics
    func clearStatistics() {
        keystrokeHistory.removeAll()
        updateCounts()
        saveHistory()
    }
    
    /// Get statistics for a specific date
    func getStatisticsForDate(_ date: Date) -> Int {
        let calendar = Calendar.current
        return keystrokeHistory.filter { keystroke in
            calendar.isDate(keystroke, inSameDayAs: date)
        }.count
    }
    
    /// Get hourly breakdown for today
    func getHourlyBreakdownToday() -> [Int] {
        let calendar = Calendar.current
        var hourlyData = Array(repeating: 0, count: 24)
        
        for keystroke in keystrokeHistory {
            if calendar.isDateInToday(keystroke) {
                let hour = calendar.component(.hour, from: keystroke)
                hourlyData[hour] += 1
            }
        }
        
        return hourlyData
    }
    
    // MARK: - Private Methods
    
    /// Get keystrokes within a specific time interval
    private func getKeystrokesInTimeInterval(seconds: TimeInterval) -> Int {
        let now = Date()
        let cutoffTime = now.addingTimeInterval(-seconds)
        return keystrokeHistory.filter { $0 >= cutoffTime }.count
    }
    
    /// Update all count properties
    private func updateCounts() {
        currentMinuteCount = getLastMinuteCount()
        currentHourCount = getLastHourCount()
        currentDayCount = getLastDayCount()
        
        // Clean up old data (older than 7 days)
        cleanupOldData()
    }
    
    /// Remove keystroke data older than 7 days
    private func cleanupOldData() {
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 86400)
        keystrokeHistory.removeAll { $0 < sevenDaysAgo }
    }
    
    /// Start a timer to update counts regularly
    private func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCounts()
        }
    }
    
    /// Save keystroke history to UserDefaults
    private func saveHistory() {
        // Only save the last 7 days of data
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 86400)
        let recentHistory = keystrokeHistory.filter { $0 >= sevenDaysAgo }
        
        // Convert dates to timestamps
        let timestamps = recentHistory.map { $0.timeIntervalSince1970 }
        userDefaults.set(timestamps, forKey: historyKey)
    }
    
    /// Load keystroke history from UserDefaults
    private func loadHistory() {
        if let timestamps = userDefaults.array(forKey: historyKey) as? [TimeInterval] {
            keystrokeHistory = timestamps.map { Date(timeIntervalSince1970: $0) }
            updateCounts()
        }
    }
}

