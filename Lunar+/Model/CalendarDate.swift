//
//  Model.swift
//  Lunar+
//
//  Created by Jiping Yang on 11/23/25.
//

import Foundation
import SwiftUI

// MARK: - MODEL LAYER
// Pure data logic and Lunar conversion utilities.

struct CalendarDate: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let dayNum: Int
    let isCurrentMonth: Bool
    let lunarDay: String
    let lunarMonth: String
    let zodiac: String
}

struct Event: Identifiable, Codable, Hashable {
    var id = UUID()
    let title: String
    let date: Date
    let timeString: String
}

class LunarConverter {
    private let chineseCalendar = Calendar(identifier: .chinese)
    private let lunarMonths = ["正月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "冬月", "腊月"]
    private let chineseNumbers = ["〇", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
    private let zodiacs = ["鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"]
    
    func getLunarDetails(for date: Date) -> (day: String, month: String, zodiac: String) {
        let components = chineseCalendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else { return ("", "", "") }
        
        let zodiacIndex = (year - 1900) % 12
        let zodiacName = zodiacIndex >= 0 ? zodiacs[zodiacIndex] : ""
        let monthName = (month > 0 && month <= 12) ? lunarMonths[month - 1] : "闰月"
        
        var dayName = ""
        if day == 1 { dayName = monthName }
        else if day == 10 { dayName = "初十" }
        else if day == 20 { dayName = "二十" }
        else if day == 30 { dayName = "三十" }
        else if day < 11 { dayName = "初\(chineseNumbers[day])" }
        else if day < 20 { dayName = "十\(chineseNumbers[day - 10])" }
        else if day < 30 { dayName = "廿\(chineseNumbers[day - 20])" }
        else { dayName = "三\(chineseNumbers[day - 30])" }
        
        return (dayName, monthName, zodiacName)
    }
}
