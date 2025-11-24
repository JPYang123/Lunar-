//
//  ContentView.swift
//  Lunar+
//
//  Created by Jiping Yang on 11/23/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CalendarViewModel()
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                CalendarHeaderView(viewModel: viewModel)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Grid
                        CalendarGridView(viewModel: viewModel)
                        
                        // Detail Card
                        DetailView(selectedDate: viewModel.selectedDate,
                                   lunar: viewModel.selectedDateLunarDetails)
                    }
                    .padding(.bottom, 100)
                }
            }
            
            // Floating Year Picker
            if viewModel.isYearPickerPresented {
                YearPickerView(currentYear: Int(viewModel.displayYear) ?? 2024) { year in
                    viewModel.setYear(year)
                } onClose: {
                    viewModel.isYearPickerPresented = false
                }
            }
            
            // Bottom Bar
            VStack {
                Spacer()
                BottomBar(viewModel: viewModel)
            }
        }
    }
}

struct CalendarHeaderView: View {
    @ObservedObject var viewModel: CalendarViewModel
    
    var body: some View {
        HStack {
            Button(action: { viewModel.isYearPickerPresented.toggle() }) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(viewModel.displayMonth)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.red)
                    
                    Text(viewModel.displayYear)
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(.red.opacity(0.8))
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.5))
                }
            }
            
            Spacer()
            
            HStack(spacing: 20) {
                Button(action: { viewModel.changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                
                Button(action: { viewModel.changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}

struct CalendarGridView: View {
    @ObservedObject var viewModel: CalendarViewModel
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    let weekDays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    
    var body: some View {
        VStack(spacing: 10) {
            // Weekday Header
            LazyVGrid(columns: columns) {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }
            }
            
            // Days
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(viewModel.daysGrid) { day in
                    DayCell(day: day,
                           isSelected: Calendar.current.isDate(day.date, inSameDayAs: viewModel.selectedDate))
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.selectDate(day.date)
                            }
                        }
                }
            }
        }
        .padding()
    }
}

struct DayCell: View {
    let day: CalendarDate
    let isSelected: Bool
    
    var isToday: Bool {
        Calendar.current.isDateInToday(day.date)
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(day.dayNum)")
                .font(.system(size: 18, weight: isToday || isSelected ? .bold : .medium))
            
            Text(day.lunarDay)
                .font(.system(size: 9))
                .fontWeight(.medium)
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.red)
                } else if isToday {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                }
            }
        )
        .foregroundColor(textColor)
    }
    
    var textColor: Color {
        if isSelected { return .white }
        if isToday { return .red }
        if !day.isCurrentMonth { return .gray.opacity(0.3) }
        let weekday = Calendar.current.component(.weekday, from: day.date)
        if weekday == 1 || weekday == 7 { return .secondary }
        return .primary
    }
}

struct DetailView: View {
    let selectedDate: Date
    let lunar: (day: String, month: String, zodiac: String)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text("SELECTED DATE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    Text(selectedDate, style: .date)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("LUNAR")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("\(lunar.month)\(lunar.day)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .fontDesign(.serif)
                    
                    Text("Year of the \(lunar.zodiac)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            HStack(spacing: 15) {
                Capsule()
                    .fill(Color.red)
                    .frame(width: 4, height: 40)
                
                VStack(alignment: .leading) {
                    Text("No events")
                        .font(.headline)
                    Text("Tap + to add event")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct YearPickerView: View {
    let currentYear: Int
    let onSelect: (Int) -> Void
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { onClose() }
            
            VStack {
                HStack {
                    Text("Select Year")
                        .font(.headline)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.title2)
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 15) {
                            ForEach(1900...2100, id: \.self) { year in
                                Button(action: { onSelect(year) }) {
                                    Text(String(format: "%d", year))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(year == currentYear ? Color.red : Color(UIColor.secondarySystemBackground))
                                        .foregroundColor(year == currentYear ? .white : .primary)
                                        .cornerRadius(8)
                                }
                                .id(year)
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        proxy.scrollTo(currentYear, anchor: .center)
                    }
                }
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .padding(20)
            .frame(maxHeight: 500)
        }
    }
}

struct BottomBar: View {
    @ObservedObject var viewModel: CalendarViewModel
    
    var body: some View {
        HStack {
            Spacer()
            Button(action: { viewModel.jumpToToday() }) {
                VStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.title2)
                    Text("Today")
                        .font(.caption2)
                }
                .foregroundColor(.red)
            }
            Spacer()
            Button(action: {}) {
                VStack(spacing: 4) {
                    Image(systemName: "list.bullet")
                        .font(.title2)
                    Text("List")
                        .font(.caption2)
                }
                .foregroundColor(.gray)
            }
            Spacer()
            Button(action: {}) {
                VStack(spacing: 4) {
                    Image(systemName: "gearshape")
                        .font(.title2)
                    Text("Settings")
                        .font(.caption2)
                }
                .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.top, 10)
        .padding(.bottom, 30) // Safe area
        .background(Color(UIColor.systemBackground).opacity(0.95))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(UIColor.separator)), alignment: .top)
    }
}

// MARK: - PREVIEW
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
