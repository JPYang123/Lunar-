//
//  Model.swift
//  Lunar+
//
//  Created by Jiping Yang on 11/23/25.
//

import SwiftUI

struct CalendarDate: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let dayNum: Int
    let isCurrentMonth: Bool
    let lunarDay: String
    let lunarMonth: String
    let zodiac: String
    // Special text (Festival or Solar Term)
    let specialText: String?
}

struct Event: Identifiable, Codable, Hashable {
    var id = UUID()
    let title: String
    let date: Date
    let timeString: String
}

class LunarConverter {
    // Explicitly use Foundation.Calendar to avoid any ambiguity
    private let chineseCalendar = Foundation.Calendar(identifier: .chinese)
    private let lunarMonths = ["正月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "冬月", "腊月"]
    private let chineseNumbers = ["〇", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
    private let zodiacs = ["鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"]
    
    // Festivals
    private let festivals: [String: String] = [
        "1-1": "春节", "1-15": "元宵", "2-2": "龙抬头", "5-5": "端午",
        "7-7": "七夕", "7-15": "中元", "8-15": "中秋", "9-9": "重阳",
        "12-8": "腊八", "12-23": "小年", "12-30": "除夕"
    ]
    
    // Solar Terms (Simplified C constants)
    private let solarTerms: [(name: String, c: Double)] = [
        ("小寒", 5.4055), ("大寒", 20.12), ("立春", 3.87), ("雨水", 18.73),
        ("惊蛰", 5.63), ("春分", 20.646), ("清明", 4.81), ("谷雨", 20.1),
        ("立夏", 5.52), ("小满", 21.04), ("芒种", 5.678), ("夏至", 21.37),
        ("小暑", 7.108), ("大暑", 22.83), ("立秋", 7.5), ("处暑", 23.13),
        ("白露", 7.646), ("秋分", 23.042), ("寒露", 8.318), ("霜降", 23.438),
        ("立冬", 7.438), ("小雪", 22.36), ("大雪", 7.18), ("冬至", 21.94)
    ]
    
    func getSolarTerm(for date: Date) -> String? {
        let calendar = Foundation.Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date) - 1 // 0-based index for array
        let day = calendar.component(.day, from: date)
        
        // Month 0 (Jan) has terms index 0, 1
        let termIndex1 = month * 2
        let termIndex2 = month * 2 + 1
        
        func check(idx: Int) -> String? {
            guard idx >= 0 && idx < 24 else { return nil }
            let term = solarTerms[idx]
            
            // Simplified formula: Int(Y * D + C) - L
            let y = Double(year % 100)
            let _ = Double(year / 4) // Unused variable replaced with _
            // Note: This integer division logic varies by century, but is a decent approximation
            // For swift, let's keep it simple:
            var calculatedDay = Int(y * 0.2422 + term.c) - Int(y/4)
            
            // Correction for 20th century
            if year < 2000 { calculatedDay += 1 }
            
            return day == calculatedDay ? term.name : nil
        }
        
        return check(idx: termIndex1) ?? check(idx: termIndex2)
    }
    
    func getLunarDetails(for date: Date) -> (day: String, month: String, zodiac: String, special: String?) {
        let components = chineseCalendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else { return ("", "", "", nil) }
        
        // Zodiac Fix:
        // In iOS Chinese Calendar, .year returns the cyclic year (1-60).
        // Year 1 (Jia-Zi) is Rat. Year 42 (Yi-Si, 2025) is Snake.
        // We use (year - 1) % 12 to get the correct index.
        let zodiacIndex = (year - 1) % 12
        let zodiacName = zodiacs[zodiacIndex]
        
        let monthName = (month > 0 && month <= 12) ? lunarMonths[month - 1] : "闰月"
        
        // 1. Check Festival
        let festivalKey = "\(month)-\(day)"
        var special = festivals[festivalKey]
        
        // 2. Check Solar Term (if no festival)
        if special == nil {
            special = getSolarTerm(for: date)
        }
        
        // Day String
        var dayName = ""
        if day == 1 { dayName = monthName }
        else if day == 10 { dayName = "初十" }
        else if day == 20 { dayName = "二十" }
        else if day == 30 { dayName = "三十" }
        else if day < 11 { dayName = "初\(chineseNumbers[day])" }
        else if day < 20 { dayName = "十\(chineseNumbers[day - 10])" }
        else if day < 30 { dayName = "廿\(chineseNumbers[day - 20])" }
        else { dayName = "三\(chineseNumbers[day - 30])" }
        
        return (dayName, monthName, zodiacName, special)
    }
}
