//
//  ContentView.swift
//  LunarV3
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
                if viewModel.activeTab == .calendar {
                    CalendarView(viewModel: viewModel)
                } else if viewModel.activeTab == .list {
                    ListView(viewModel: viewModel)
                } else {
                    SettingsView()
                }
                Spacer()
                BottomBar(viewModel: viewModel)
            }
            .edgesIgnoringSafeArea(.bottom)
            
            if viewModel.isYearPickerPresented {
                YearPickerView(currentYear: Int(viewModel.displayYear) ?? 2024) { year in
                    viewModel.setYear(year)
                } onClose: { viewModel.isYearPickerPresented = false }
            }
            
            // Fortune Overlay
            if viewModel.isFortunePresented {
                FortuneView(text: viewModel.fortuneText) {
                    viewModel.isFortunePresented = false
                }
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
            VStack(spacing: 0) {
                CalendarGridView(viewModel: viewModel)
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
    var upcomingDates: [Date] {
        let calendar = Foundation.Calendar.current
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
            Text("Upcoming 30 Days").font(.largeTitle).bold().padding().padding(.top, 40)
            List {
                ForEach(upcomingDates, id: \.self) { date in
                    let lunar = converter.getLunarDetails(for: date)
                    let events = viewModel.events[viewModel.dateKey(for: date)] ?? []
                    HStack(alignment: .center, spacing: 15) {
                        VStack(alignment: .center) {
                            Text(date, format: .dateTime.weekday(.abbreviated)).font(.caption).bold().foregroundColor(.red)
                            Text(date, format: .dateTime.day()).font(.title3).bold()
                        }
                        .frame(width: 40)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(lunar.special ?? "\(lunar.month)\(lunar.day)")
                                .font(.caption)
                                .foregroundColor(lunar.special != nil ? .red : .gray)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(lunar.special != nil ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                                .cornerRadius(4)
                            if events.isEmpty {
                                Text("No events").font(.caption).foregroundColor(.gray.opacity(0.5))
                            } else {
                                ForEach(events) { event in
                                    HStack {
                                        Text(event.title).font(.body)
                                        Spacer()
                                        Button(action: { viewModel.deleteEvent(event) }) {
                                            Image(systemName: "trash").font(.caption).foregroundColor(.red.opacity(0.6))
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
        }
    }
}

struct SettingsView: View {
    @AppStorage("gemini_api_key") private var apiKey = ""
    @State private var lunarEnabled = true
    @State private var startOnSunday = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("AI Configuration")) {
                    SecureField("Enter Gemini API Key", text: $apiKey)
                    if apiKey.isEmpty {
                        Text("Required for Fortune & Magic Events").font(.caption).foregroundColor(.red)
                    }
                    Link("Get API Key", destination: URL(string: "https://aistudio.google.com/app/apikey")!)
                        .font(.caption)
                }
                
                Section(header: Text("Calendars")) {
                    HStack { Text("Gregorian"); Spacer(); Image(systemName: "checkmark").foregroundColor(.red) }
                    Toggle("Chinese Lunar", isOn: $lunarEnabled).tint(.red)
                }
                Section(header: Text("Appearance")) {
                    Toggle("Start Week on Sunday", isOn: $startOnSunday).tint(.red)
                }
                Section {
                    HStack { Text("Version"); Spacer(); Text("2.1.1").foregroundColor(.gray) }
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
                            isSelected: Foundation.Calendar.current.isDate(day.date, inSameDayAs: viewModel.selectedDate),
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
    var isToday: Bool { Foundation.Calendar.current.isDateInToday(day.date) }
    var body: some View {
        VStack(spacing: 2) {
            Text("\(day.dayNum)").font(.system(size: 18, weight: isToday || isSelected ? .bold : .medium))
            // Display Special Text (Festival/Solar Term) if available
            Text(day.specialText ?? day.lunarDay)
                .font(.system(size: 9))
                .fontWeight(day.specialText != nil ? .bold : .medium)
                .foregroundColor(isSelected ? .white : (day.specialText != nil ? .red : .primary))
            
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
                    // Show special text in detail view too
                    Text(viewModel.selectedDateLunarDetails.special ?? "\(viewModel.selectedDateLunarDetails.month)\(viewModel.selectedDateLunarDetails.day)")
                        .font(.title2).fontWeight(.bold).fontDesign(.serif)
                    Text("\(viewModel.selectedDateLunarDetails.zodiac)年").font(.caption).foregroundColor(.gray)
                }
            }
            
            Divider()
            
            // Fortune Button
            Button(action: { viewModel.generateFortune() }) {
                HStack {
                    ZStack {
                        Circle().fill(Color.white).frame(width: 32, height: 32)
                        if viewModel.isFortuneLoading {
                            ProgressView().tint(.purple)
                        } else {
                            Image(systemName: "sparkles").foregroundColor(.purple).font(.system(size: 16))
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("Daily Fortune").font(.subheadline).fontWeight(.bold).foregroundColor(.purple)
                        Text("Ask the Zodiac").font(.caption).foregroundColor(.purple.opacity(0.6))
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(.purple.opacity(0.4)).font(.caption)
                }
                .padding(12)
                .background(LinearGradient(colors: [Color.purple.opacity(0.05), Color.blue.opacity(0.05)], startPoint: .leading, endPoint: .trailing))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.purple.opacity(0.1), lineWidth: 1))
                .cornerRadius(12)
            }
            .disabled(viewModel.isFortuneLoading)
            
            if !viewModel.currentEvents.isEmpty {
                ForEach(viewModel.currentEvents) { event in
                    HStack {
                        Capsule().fill(Color.red).frame(width: 4, height: 40)
                        VStack(alignment: .leading) {
                            Text(event.title).font(.headline)
                            Text(event.timeString).font(.caption).foregroundColor(.gray)
                        }
                        Spacer()
                        Button(action: { viewModel.deleteEvent(event) }) {
                            Image(systemName: "trash").foregroundColor(.gray.opacity(0.5)).padding(10)
                        }
                    }
                    .padding().background(Color.white).cornerRadius(10)
                }
            } else {
                Text("No events for this day").font(.body).foregroundColor(.gray).italic().padding(.vertical, 10)
            }
            Button(action: { viewModel.isAddingEvent = true }) {
                HStack { Image(systemName: "plus.circle.fill").font(.title2); Text("Add Event").fontWeight(.semibold) }
                .foregroundColor(.red).padding().frame(maxWidth: .infinity).background(Color.white).cornerRadius(10).shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
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
                Section { HStack { Text("Date"); Spacer(); Text(viewModel.selectedDate, style: .date).foregroundColor(.gray) } }
            }
            .navigationTitle("New Event")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Add") { if !title.isEmpty { viewModel.addEvent(title: title); dismiss() } }.disabled(title.isEmpty)
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
                HStack { Text("Select Year").font(.headline); Spacer(); Button(action: onClose) { Image(systemName: "xmark.circle.fill").foregroundColor(.gray).font(.title2) } }
                .padding()
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 15) {
                            ForEach(1...9999, id: \.self) { year in
                                Button(action: { onSelect(year) }) {
                                    Text(String(format: "%d", year)).font(.subheadline).fontWeight(.semibold).frame(maxWidth: .infinity).padding(.vertical, 10)
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
            Button(action: { viewModel.jumpToToday() }) { VStack(spacing: 4) { Image(systemName: "calendar").font(.title2); Text("Today").font(.caption2) }.foregroundColor(viewModel.activeTab == .calendar ? .red : .gray) }
            Spacer()
            Button(action: { viewModel.activeTab = .list }) { VStack(spacing: 4) { Image(systemName: "list.bullet").font(.title2); Text("List").font(.caption2) }.foregroundColor(viewModel.activeTab == .list ? .red : .gray) }
            Spacer()
            Button(action: { viewModel.activeTab = .settings }) { VStack(spacing: 4) { Image(systemName: "gearshape").font(.title2); Text("Settings").font(.caption2) }.foregroundColor(viewModel.activeTab == .settings ? .red : .gray) }
            Spacer()
        }
        .padding(.top, 10).padding(.bottom, 30).background(Color(UIColor.systemBackground).opacity(0.95))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(UIColor.separator)), alignment: .top)
    }
}

struct FortuneView: View {
    let text: String
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onClose() }
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.1))
                        .frame(width: 80, height: 80)
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundColor(.purple)
                }
                .padding(.top, 20)
                
                Text("Daily Insight")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(text)
                    .font(.system(.body, design: .serif))
                    .italic()
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .lineSpacing(4)
                
                Button(action: onClose) {
                    Text("Close")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary)
                        .foregroundColor(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                }
                .padding(.top, 10)
            }
            .padding(24)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(24)
            .shadow(radius: 20)
            .padding(30)
            .transition(.scale.combined(with: .opacity))
        }
        .zIndex(100)
    }
}

#Preview {
    ContentView()
}
