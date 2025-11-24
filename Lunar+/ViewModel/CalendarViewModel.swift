//
//  CalendarViewModel.swift
//  Lunar+
//
//  Created by Jiping Yang on 11/23/25.
//

import Foundation
import SwiftUI

class CalendarViewModel: ObservableObject {
    @Published var currentDate: Date
    @Published var selectedDate: Date
    @Published var daysGrid: [CalendarDate] = []
    @Published var isYearPickerPresented = false
    
    private let calendar = Calendar.current
    private let lunarConverter = LunarConverter()
    
    init() {
        let now = Date()
        self.currentDate = now
        self.selectedDate = now
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
    
    var selectedDateLunarDetails: (day: String, month: String, zodiac: String) {
        return lunarConverter.getLunarDetails(for: selectedDate)
    }
    
    func generateDays() {
        guard let range = calendar.range(of: .day, in: .month, for: currentDate),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) else {
            return
        }
        
        let startingWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1 // 0-based Sunday
        let daysInPrevMonth = startingWeekday
        
        var newDays: [CalendarDate] = []
        
        // Previous Month Filler
        if let prevMonthDate = calendar.date(byAdding: .month, value: -1, to: firstDayOfMonth),
           let rangePrev = calendar.range(of: .day, in: .month, for: prevMonthDate) {
            let totalDaysPrev = rangePrev.count
            for i in 0..<daysInPrevMonth {
                let dayNum = totalDaysPrev - (daysInPrevMonth - i) + 1
                if let date = calendar.date(byAdding: .day, value: dayNum - 1, to: prevMonthDate) {
                    let lunar = lunarConverter.getLunarDetails(for: date)
                    newDays.append(CalendarDate(
                        date: date,
                        dayNum: dayNum,
                        isCurrentMonth: false,
                        lunarDay: lunar.day,
                        lunarMonth: lunar.month,
                        zodiac: lunar.zodiac
                    ))
                }
            }
        }
        
        // Current Month
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                let lunar = lunarConverter.getLunarDetails(for: date)
                newDays.append(CalendarDate(
                    date: date,
                    dayNum: day,
                    isCurrentMonth: true,
                    lunarDay: lunar.day,
                    lunarMonth: lunar.month,
                    zodiac: lunar.zodiac
                ))
            }
        }
        
        // Next Month Filler (to fill 42 cells)
        let remainingCells = 42 - newDays.count
        if let nextMonthDate = calendar.date(byAdding: .month, value: 1, to: firstDayOfMonth) {
            for i in 1...remainingCells {
                if let date = calendar.date(byAdding: .day, value: i - 1, to: nextMonthDate) {
                    let lunar = lunarConverter.getLunarDetails(for: date)
                    newDays.append(CalendarDate(
                        date: date,
                        dayNum: i,
                        isCurrentMonth: false,
                        lunarDay: lunar.day,
                        lunarMonth: lunar.month,
                        zodiac: lunar.zodiac
                    ))
                }
            }
        }
        
        self.daysGrid = newDays
    }
    
    func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: currentDate) {
            // Bounds check 1900-2100
            let year = calendar.component(.year, from: newDate)
            if year >= 1900 && year <= 2100 {
                currentDate = newDate
                generateDays()
            }
        }
    }
    
    func selectDate(_ date: Date) {
        selectedDate = date
        // If selecting a grayed out date, switch month
        if !calendar.isDate(date, equalTo: currentDate, toGranularity: .month) {
            currentDate = date
            generateDays()
        }
    }
    
    func jumpToToday() {
        let now = Date()
        selectedDate = now
        currentDate = now
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
}
