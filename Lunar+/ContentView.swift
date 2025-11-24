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
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main Content Swapper
                if viewModel.activeTab == .calendar {
                    CalendarView(viewModel: viewModel)
                } else if viewModel.activeTab == .list {
                    ListView(viewModel: viewModel)
                } else {
                    SettingsView()
                }
                
                // Bottom Bar
                Spacer()
                BottomBar(viewModel: viewModel)
            }
            .edgesIgnoringSafeArea(.bottom)
            
            // Overlays
            if viewModel.isYearPickerPresented {
                YearPickerView(currentYear: Int(viewModel.displayYear) ?? 2024) { year in
                    viewModel.setYear(year)
                } onClose: { viewModel.isYearPickerPresented = false }
            }
        }
        .sheet(isPresented: $viewModel.isAddingEvent) {
            AddEventView(viewModel: viewModel)
        }
    }
}

struct CalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            CalendarHeaderView(viewModel: viewModel)
            
            // Main Calendar + Detail Area
            VStack(spacing: 0) {
                // Grid
                CalendarGridView(viewModel: viewModel)
                
                // Scrollable Details
                ScrollView {
                    DetailView(viewModel: viewModel)
                        .padding(.top, 20)
                }
                .background(Color(UIColor.secondarySystemBackground))
            }
        }
    }
}

struct ListView: View {
    @ObservedObject var viewModel: CalendarViewModel
    let converter = LunarConverter()
    
    // Generate next 30 days
    var upcomingDates: [Date] {
        let calendar = Calendar.current
        var dates: [Date] = []
        let today = Date()
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: i, to: today) {
                dates.append(date)
            }
        }
        return dates
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Upcoming 30 Days")
                .font(.largeTitle)
                .bold()
                .padding()
                .padding(.top, 40)
            
            List {
                ForEach(upcomingDates, id: \.self) { date in
                    let lunar = converter.getLunarDetails(for: date)
                    let events = viewModel.events[viewModel.dateKey(for: date)] ?? []
                    
                    HStack(alignment: .center, spacing: 15) {
                        // Date Column
                        VStack(alignment: .center) {
                            Text(date, format: .dateTime.weekday(.abbreviated))
                                .font(.caption)
                                .bold()
                                .foregroundColor(.red)
                            Text(date, format: .dateTime.day())
                                .font(.title3)
                                .bold()
                        }
                        .frame(width: 40)
                        
                        // Content Column
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(lunar.month)\(lunar.day)")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                            
                            if events.isEmpty {
                                Text("No events")
                                    .font(.caption)
                                    .foregroundColor(.gray.opacity(0.5))
                            } else {
                                ForEach(events) { event in
                                    Text(event.title)
                                        .font(.body)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Add Event Button for List Item
                        Button(action: {
                            viewModel.selectDate(date)
                            viewModel.isAddingEvent = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.red)
                                .padding(8)
                                .background(Color.red.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle()) // Needed to prevent whole row click
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
        }
    }
}

struct SettingsView: View {
    @State private var lunarEnabled = true
    @State private var startOnSunday = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Calendars")) {
                    HStack {
                        Text("Gregorian")
                        Spacer()
                        Image(systemName: "checkmark").foregroundColor(.red)
                    }
                    Toggle("Chinese Lunar", isOn: $lunarEnabled)
                        .tint(.red)
                }
                
                Section(header: Text("Appearance")) {
                    Toggle("Start Week on Sunday", isOn: $startOnSunday)
                        .tint(.red)
                }
                
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.1").foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct CalendarHeaderView: View {
    @ObservedObject var viewModel: CalendarViewModel
    var body: some View {
        HStack {
            Button(action: { withAnimation { viewModel.isYearPickerPresented.toggle() } }) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(viewModel.displayMonth).font(.system(size: 28, weight: .bold)).foregroundColor(.red)
                    Text(viewModel.displayYear).font(.system(size: 28, weight: .light)).foregroundColor(.red.opacity(0.8))
                    Image(systemName: "chevron.right").font(.caption).foregroundColor(.red.opacity(0.5))
                }
            }
            Spacer()
            HStack(spacing: 20) {
                Button(action: { viewModel.changeMonth(by: -1) }) { Image(systemName: "chevron.left").font(.title2).foregroundColor(.red) }
                Button(action: { viewModel.changeMonth(by: 1) }) { Image(systemName: "chevron.right").font(.title2).foregroundColor(.red) }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}

struct CalendarGridView: View {
    @ObservedObject var viewModel: CalendarViewModel
    let columns = Array(repeating: GridItem(.flexible()), count: 7)
    var body: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: columns) {
                ForEach(["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"], id: \.self) { day in
                    Text(day).font(.caption2).fontWeight(.bold).foregroundColor(.gray)
                }
            }
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(viewModel.daysGrid) { day in
                    DayCell(day: day,
                            isSelected: Calendar.current.isDate(day.date, inSameDayAs: viewModel.selectedDate),
                            hasEvent: viewModel.hasEvents(for: day.date))
                        .onTapGesture { withAnimation { viewModel.selectDate(day.date) } }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}

struct DayCell: View {
    let day: CalendarDate
    let isSelected: Bool
    let hasEvent: Bool
    
    var isToday: Bool { Calendar.current.isDateInToday(day.date) }
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(day.dayNum)").font(.system(size: 18, weight: isToday || isSelected ? .bold : .medium))
            Text(day.lunarDay).font(.system(size: 9)).fontWeight(.medium)
            if hasEvent {
                Circle().fill(isSelected ? .white : .gray).frame(width: 4, height: 4)
            } else {
                Spacer().frame(height: 4)
            }
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                if isSelected { Circle().fill(Color.red) }
                else if isToday { Circle().fill(Color.red.opacity(0.1)) }
            }
        )
        .foregroundColor(isSelected ? .white : (isToday ? .red : (day.isCurrentMonth ? .primary : .gray.opacity(0.3))))
    }
}

struct DetailView: View {
    @ObservedObject var viewModel: CalendarViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text(viewModel.selectedDate, format: .dateTime.weekday(.wide)).font(.caption).fontWeight(.bold).foregroundColor(.gray)
                    Text(viewModel.selectedDate, format: .dateTime.day().month(.wide)).font(.title2).fontWeight(.bold)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("LUNAR").font(.caption).fontWeight(.bold).foregroundColor(.red)
                    Text("\(viewModel.selectedDateLunarDetails.month)\(viewModel.selectedDateLunarDetails.day)").font(.title2).fontWeight(.bold).fontDesign(.serif)
                    Text("Year of the \(viewModel.selectedDateLunarDetails.zodiac)").font(.caption).foregroundColor(.gray)
                }
            }
            
            Divider()
            
            // Events List
            if !viewModel.currentEvents.isEmpty {
                ForEach(viewModel.currentEvents) { event in
                    HStack {
                        Capsule().fill(Color.red).frame(width: 4, height: 40)
                        VStack(alignment: .leading) {
                            Text(event.title).font(.headline)
                            Text(event.timeString).font(.caption).foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                }
            } else {
                Text("No events for this day")
                    .font(.body)
                    .foregroundColor(.gray)
                    .italic()
                    .padding(.vertical, 10)
            }
            
            // Add Event Button (Always Visible)
            Button(action: { viewModel.isAddingEvent = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("Add Event")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.red)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .padding(.top, 10)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }
}

struct AddEventView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @State private var title = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Event Title (e.g., Lunch)", text: $title)
                
                // Show date being added to
                Section {
                    HStack {
                        Text("Date")
                        Spacer()
                        Text(viewModel.selectedDate, style: .date)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("New Event")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Add") {
                    if !title.isEmpty {
                        viewModel.addEvent(title: title)
                        dismiss()
                    }
                }.disabled(title.isEmpty)
            )
        }
    }
}

struct YearPickerView: View {
    let currentYear: Int
    let onSelect: (Int) -> Void
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea().onTapGesture { onClose() }
            VStack {
                HStack {
                    Text("Select Year").font(.headline)
                    Spacer()
                    Button(action: onClose) { Image(systemName: "xmark.circle.fill").foregroundColor(.gray).font(.title2) }
                }
                .padding()
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 15) {
                            ForEach(1900...2100, id: \.self) { year in
                                Button(action: { onSelect(year) }) {
                                    Text(String(format: "%d", year))
                                        .font(.subheadline).fontWeight(.semibold)
                                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                                        .background(year == currentYear ? Color.red : Color(UIColor.secondarySystemBackground))
                                        .foregroundColor(year == currentYear ? .white : .primary).cornerRadius(8)
                                }.id(year)
                            }
                        }
                        .padding()
                    }
                    .onAppear { proxy.scrollTo(currentYear, anchor: .center) }
                }
            }
            .background(Color(UIColor.systemBackground)).cornerRadius(16).padding(20).frame(maxHeight: 500)
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
                    Image(systemName: "calendar").font(.title2)
                    Text("Today").font(.caption2)
                }
                .foregroundColor(viewModel.activeTab == .calendar ? .red : .gray)
            }
            Spacer()
            Button(action: { viewModel.activeTab = .list }) {
                VStack(spacing: 4) {
                    Image(systemName: "list.bullet").font(.title2)
                    Text("List").font(.caption2)
                }
                .foregroundColor(viewModel.activeTab == .list ? .red : .gray)
            }
            Spacer()
            Button(action: { viewModel.activeTab = .settings }) {
                VStack(spacing: 4) {
                    Image(systemName: "gearshape").font(.title2)
                    Text("Settings").font(.caption2)
                }
                .foregroundColor(viewModel.activeTab == .settings ? .red : .gray)
            }
            Spacer()
        }
        .padding(.top, 10)
        .padding(.bottom, 30)
        .background(Color(UIColor.systemBackground).opacity(0.95))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(UIColor.separator)), alignment: .top)
    }
}
