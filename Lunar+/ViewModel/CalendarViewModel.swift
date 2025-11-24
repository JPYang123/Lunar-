//
//  CalendarViewModel.swift
//  LunarV+
//
//  Created by Jiping Yang on 11/23/25.
//

import SwiftUI
import Foundation

enum AppTab {
    case calendar, list, settings
}

class CalendarViewModel: ObservableObject {
    @Published var currentDate: Date
    @Published var selectedDate: Date
    @Published var daysGrid: [CalendarDate] = []
    @Published var isYearPickerPresented = false
    @Published var activeTab: AppTab = .calendar // Updated Type
    @Published var isAddingEvent = false
    @Published var events: [String: [Event]] = [:]
    
    // Fortune State
    @Published var isFortuneLoading = false
    @Published var fortuneText = ""
    @Published var isFortunePresented = false
    
    private let calendar = Foundation.Calendar.current
    private let lunarConverter = LunarConverter()
    private let eventsKey = "saved_events"
    
    init() {
        let now = Date()
        self.currentDate = now
        self.selectedDate = now
        loadEvents()
        generateDays()
    }
    
    var displayMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: currentDate)
    }
    
    var displayYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: currentDate)
    }
    
    var selectedDateLunarDetails: (day: String, month: String, zodiac: String, special: String?) {
        return lunarConverter.getLunarDetails(for: selectedDate)
    }
    
    var currentEvents: [Event] {
        let key = dateKey(for: selectedDate)
        return events[key] ?? []
    }
    
    func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    func generateDays() {
        guard let range = calendar.range(of: .day, in: .month, for: currentDate),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) else { return }
        
        let startingWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        var newDays: [CalendarDate] = []
        
        // Previous Month
        if let prevMonthDate = calendar.date(byAdding: .month, value: -1, to: firstDayOfMonth),
           let rangePrev = calendar.range(of: .day, in: .month, for: prevMonthDate) {
            let totalDaysPrev = rangePrev.count
            for i in 0..<startingWeekday {
                let dayNum = totalDaysPrev - (startingWeekday - i) + 1
                if let date = calendar.date(byAdding: .day, value: dayNum - 1, to: prevMonthDate) {
                    let lunar = lunarConverter.getLunarDetails(for: date)
                    newDays.append(CalendarDate(
                        date: date, dayNum: dayNum, isCurrentMonth: false,
                        lunarDay: lunar.day, lunarMonth: lunar.month, zodiac: lunar.zodiac, specialText: lunar.special
                    ))
                }
            }
        }
        
        // Current Month
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                let lunar = lunarConverter.getLunarDetails(for: date)
                newDays.append(CalendarDate(
                    date: date, dayNum: day, isCurrentMonth: true,
                    lunarDay: lunar.day, lunarMonth: lunar.month, zodiac: lunar.zodiac, specialText: lunar.special
                ))
            }
        }
        
        // Next Month Filler
        let remainingCells = 42 - newDays.count
        if let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: firstDayOfMonth) {
            for i in 1...remainingCells {
                if let date = calendar.date(byAdding: .day, value: i - 1, to: nextMonthDate) {
                    let lunar = lunarConverter.getLunarDetails(for: date)
                    newDays.append(CalendarDate(
                        date: date, dayNum: i, isCurrentMonth: false,
                        lunarDay: lunar.day, lunarMonth: lunar.month, zodiac: lunar.zodiac, specialText: lunar.special
                    ))
                }
            }
        }
        self.daysGrid = newDays
    }
    
    func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: currentDate) {
            currentDate = newDate
            generateDays()
        }
    }
    
    func selectDate(_ date: Date) {
        selectedDate = date
        if !calendar.isDate(date, equalTo: currentDate, toGranularity: .month) {
            currentDate = date
            generateDays()
        }
    }
    
    func jumpToToday() {
        let now = Date()
        selectedDate = now
        currentDate = now
        activeTab = .calendar
        generateDays()
    }
    
    func setYear(_ year: Int) {
        var components = calendar.dateComponents([.year, .month, .day], from: currentDate)
        components.year = year
        if let newDate = calendar.date(from: components) {
            currentDate = newDate
            generateDays()
            isYearPickerPresented = false
        }
    }
    
    func addEvent(title: String) {
        let key = dateKey(for: selectedDate)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let newEvent = Event(title: title, date: selectedDate, timeString: formatter.string(from: Date()))
        
        var existing = events[key] ?? []
        existing.append(newEvent)
        events[key] = existing
        saveEvents()
    }
    
    func deleteEvent(_ event: Event) {
        let key = dateKey(for: event.date)
        if var existing = events[key] {
            existing.removeAll { $0.id == event.id }
            events[key] = existing
            saveEvents()
        }
    }
    
    private func saveEvents() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: eventsKey)
        }
    }
    
    private func loadEvents() {
        if let data = UserDefaults.standard.data(forKey: eventsKey),
           let decoded = try? JSONDecoder().decode([String: [Event]].self, from: data) {
            events = decoded
        }
    }
    
    func hasEvents(for date: Date) -> Bool {
        let key = dateKey(for: date)
        return !(events[key]?.isEmpty ?? true)
    }
    
    // Generate Fortune
    func generateFortune() {
        guard !isFortuneLoading else { return }
        isFortuneLoading = true
        
        let zodiac = selectedDateLunarDetails.zodiac
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateStr = formatter.string(from: selectedDate)
        
        let prompt = "Write a short, mystical daily fortune for the \(zodiac) sign on \(dateStr). Mention lunar energy. Keep it under 2 sentences."
        
        Task {
            let result = await callGemini(prompt: prompt)
            DispatchQueue.main.async {
                self.fortuneText = result
                self.isFortuneLoading = false
                self.isFortunePresented = true
            }
        }
    }
}
