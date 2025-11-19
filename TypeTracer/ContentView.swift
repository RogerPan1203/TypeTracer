//
//  ContentView.swift
//  TypeTracer
//
//  Created by Roger on 11/18/25.
//

import SwiftUI

struct ContentView: View {
    // MARK: - Observed Objects
    @StateObject private var statistics: TypingStatistics
    @StateObject private var monitor: KeyboardMonitor
    @StateObject private var menuBarManager: MenuBarManager
    
    // MARK: - State Properties
    @State private var selectedTab = 0
    private let appDelegate: AppDelegate
    
    // MARK: - Initialization
    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        
        let stats = TypingStatistics()
        let mon = KeyboardMonitor(statistics: stats)
        let menuBar = MenuBarManager(statistics: stats, monitor: mon)
        
        _statistics = StateObject(wrappedValue: stats)
        _monitor = StateObject(wrappedValue: mon)
        _menuBarManager = StateObject(wrappedValue: menuBar)
        
        // Store references in app delegate
        appDelegate.statistics = stats
        appDelegate.monitor = mon
        appDelegate.menuBarManager = menuBar
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Tab Selection
            Picker("View", selection: $selectedTab) {
                Text("实时统计").tag(0)
                Text("历史数据").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content based on selected tab
            if selectedTab == 0 {
                realTimeView
            } else {
                historyView
            }
            
            Divider()
            
            // Footer with controls
            footerView
        }
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            if monitor.hasAccessibilityPermission {
                monitor.startMonitoring()
            }
        }
    }
    
    // MARK: - View Components
    
    /// Header view with app title and status
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("TypeTracer")
                    .font(.title)
                    .fontWeight(.bold)
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(monitor.isMonitoring ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text(monitor.isMonitoring ? "正在监控" : "未启动")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Total keystrokes badge
            VStack(alignment: .trailing, spacing: 4) {
                Text("总按键数")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(statistics.getTotalKeystrokes())")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    /// Real-time statistics view
    private var realTimeView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time interval statistics cards
                HStack(spacing: 20) {
                    StatisticCard(
                        title: "最近一分钟",
                        count: statistics.currentMinuteCount,
                        icon: "timer",
                        color: .blue
                    )
                    
                    StatisticCard(
                        title: "最近一小时",
                        count: statistics.currentHourCount,
                        icon: "clock",
                        color: .green
                    )
                    
                    StatisticCard(
                        title: "今日",
                        count: statistics.currentDayCount,
                        icon: "calendar",
                        color: .orange
                    )
                }
                .padding(.horizontal)
                
                // Hourly breakdown chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("今日每小时统计")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HourlyChartView(hourlyData: statistics.getHourlyBreakdownToday())
                        .frame(height: 200)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .padding(.vertical)
        }
    }
    
    /// Historical data view
    private var historyView: some View {
        VStack(spacing: 16) {
            Text("历史数据")
                .font(.headline)
            
            // Last 7 days statistics
            VStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { dayOffset in
                    let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!
                    let count = statistics.getStatisticsForDate(date)
                    
                    HStack {
                        Text(formatDate(date))
                            .frame(width: 120, alignment: .leading)
                        
                        GeometryReader { geometry in
                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color.blue.opacity(0.7))
                                    .frame(width: CGFloat(count) / 1000 * geometry.size.width)
                                
                                Spacer()
                            }
                        }
                        .frame(height: 30)
                        
                        Text("\(count)")
                            .frame(width: 80, alignment: .trailing)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .padding(.vertical)
    }
    
    /// Footer view with control buttons
    private var footerView: some View {
        HStack {
            if !monitor.hasAccessibilityPermission {
                Button(action: {
                    monitor.requestAccessibilityPermission()
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                        Text("请求辅助功能权限")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            
            // Hide to menu bar button
            Button(action: {
                menuBarManager.hideWindow()
            }) {
                HStack {
                    Image(systemName: "menubar.rectangle")
                    Text("隐藏到菜单栏")
                }
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button(action: {
                statistics.clearStatistics()
            }) {
                Text("清除数据")
            }
            .buttonStyle(.bordered)
            
            Button(action: {
                if monitor.isMonitoring {
                    monitor.stopMonitoring()
                } else {
                    monitor.startMonitoring()
                }
            }) {
                Text(monitor.isMonitoring ? "停止监控" : "开始监控")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!monitor.hasAccessibilityPermission)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Helper Methods
    
    /// Format date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日 (EEE)"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - Statistic Card Component

/// A card component to display a single statistic
struct StatisticCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(count)")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(color)
            
            Text("按键")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Hourly Chart Component

/// A chart component to display hourly statistics
struct HourlyChartView: View {
    let hourlyData: [Int]
    
    var body: some View {
        GeometryReader { geometry in
            let maxCount = hourlyData.max() ?? 1
            let barWidth = geometry.size.width / CGFloat(hourlyData.count) - 4
            
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<hourlyData.count, id: \.self) { hour in
                    VStack(spacing: 4) {
                        Spacer()
                        
                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.opacity(0.7))
                            .frame(
                                width: barWidth,
                                height: maxCount > 0 ? 
                                    CGFloat(hourlyData[hour]) / CGFloat(maxCount) * (geometry.size.height - 30) : 0
                            )
                        
                        // Hour label
                        Text("\(hour)")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView(appDelegate: AppDelegate())
}
