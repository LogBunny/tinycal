import SwiftUI

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State var tasks: [Date: [Task]] = [:] // Public for AppDelegate access
    @State private var newTaskTitle: String = ""
    
    private let tasksKey = "PersistentTasks"
    private let calendar = Calendar.current
    
    init() {
        if let data = UserDefaults.standard.data(forKey: tasksKey),
           let decodedTasks = try? JSONDecoder().decode([Date: [Task]].self, from: data) {
            _tasks = State(initialValue: decodedTasks)
        } else {
            _tasks = State(initialValue: [:])
        }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Month header with padding below
            Text(selectedDate, formatter: monthYearFormatter)
                .font(.headline)
                .frame(height: 30)
                .padding(.bottom, 15) // Added padding between month name and calendar
            
            // Calendar grid
            CalendarGrid(date: $selectedDate)
                .frame(height: 180)
                .padding(.bottom, 20) // Existing padding before tasks section
            
            // Tasks section
            VStack(alignment: .leading, spacing: 5) {
                Text("Tasks for \(selectedDate, formatter: dayFormatter)")
                    .font(.subheadline)
                    .frame(height: 20)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        if let dateTasks = tasks[calendar.startOfDay(for: selectedDate)], !dateTasks.isEmpty {
                            ForEach(dateTasks) { task in
                                HStack {
                                    Text(task.title)
                                        .lineLimit(1)
                                    Spacer()
                                    Button(action: {
                                        deleteTask(task, for: selectedDate)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        } else {
                            Text("No tasks for this day")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(maxHeight: 195) // Adjusted to fit within 500 points
                
                HStack {
                    TextField("New task", text: $newTaskTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: addTask) {
                        Text("Add")
                    }
                    .disabled(newTaskTitle.isEmpty)
                }
                .frame(height: 30)
            }
            
            // Today button
            Button("Today") {
                selectedDate = Date()
            }
            .frame(height: 30)
        }
        .padding(10)
        .frame(width: 300, height: 500)
    }
    
    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
    
    private func addTask() {
        let trimmedTitle = newTaskTitle.trimmingCharacters(in: .whitespaces)
        if !trimmedTitle.isEmpty {
            let task = Task(title: trimmedTitle)
            let startOfDay = calendar.startOfDay(for: selectedDate)
            if var existingTasks = tasks[startOfDay] {
                existingTasks.append(task)
                tasks[startOfDay] = existingTasks
            } else {
                tasks[startOfDay] = [task]
            }
            newTaskTitle = ""
            saveTasks()
        }
    }
    
    private func deleteTask(_ task: Task, for date: Date) {
        let startOfDay = calendar.startOfDay(for: date)
        if var existingTasks = tasks[startOfDay] {
            existingTasks.removeAll { $0.id == task.id }
            if existingTasks.isEmpty {
                tasks.removeValue(forKey: startOfDay)
            } else {
                tasks[startOfDay] = existingTasks
            }
            saveTasks()
        }
    }
    
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: tasksKey)
        }
    }
}

struct Task: Identifiable, Codable {
    let id = UUID()
    let title: String
}

struct CalendarGrid: View {
    @Binding var date: Date
    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack(spacing: 5) {
            HStack {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .frame(maxWidth: .infinity)
                        .font(.caption)
                }
            }
            
            let days = generateDaysInMonth(for: date)
            let columns = Array(repeating: GridItem(.flexible()), count: 7)
            
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    if let day = day {
                        Text("\(calendar.component(.day, from: day))")
                            .frame(width: 30, height: 30)
                            .background(isSameDay(day, date) ? Color.blue : Color.clear)
                            .clipShape(Circle())
                            .foregroundColor(isSameDay(day, Date()) ? .red : .primary)
                            .onTapGesture {
                                date = day
                            }
                    } else {
                        Text("")
                            .frame(width: 30, height: 30)
                    }
                }
            }
        }
    }
    
    func generateDaysInMonth(for date: Date) -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        let totalSlots = firstWeekday + range.count
        let paddedSlots = (totalSlots + 6) / 7 * 7
        
        var days: [Date?] = Array(repeating: nil, count: paddedSlots)
        
        for day in 0..<range.count {
            let date = calendar.date(byAdding: .day, value: day, to: firstDayOfMonth)!
            days[firstWeekday + day] = date
        }
        
        return days
    }
    
    func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}
