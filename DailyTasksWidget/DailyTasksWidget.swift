import WidgetKit
import SwiftUI


private let appGroupID = "group.com.taskplanner.shared"
private let widgetKind = "DailyTasksWidget"


struct WidgetTask: Identifiable, Codable {
    let id: UUID
    let title: String
    let difficulty: Int
    let isCompleted: Bool
}

struct TasksEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
}


struct TasksProvider: TimelineProvider {

    func placeholder(in context: Context) -> TasksEntry {
        TasksEntry(
            date: Date(),
            tasks: sampleTasks()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TasksEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TasksEntry>) -> Void) {
        let entry = loadEntry()

        let nextUpdate = Calendar.current.date(
            byAdding: .minute,
            value: 15,
            to: Date()
        )!

        completion(
            Timeline(
                entries: [entry],
                policy: .after(nextUpdate)
            )
        )
    }

   
    private func loadEntry() -> TasksEntry {
        let defaults = UserDefaults(suiteName: appGroupID)

        if let data = defaults?.data(forKey: "widget_tasks"),
           let tasks = try? JSONDecoder().decode([WidgetTask].self, from: data) {

            return TasksEntry(date: Date(), tasks: tasks)
        }

        return TasksEntry(date: Date(), tasks: [])
    }

    private func sampleTasks() -> [WidgetTask] {
        [
            WidgetTask(id: UUID(), title: "Пример задачи", difficulty: 3, isCompleted: false),
            WidgetTask(id: UUID(), title: "Ещё одна", difficulty: 2, isCompleted: true)
        ]
    }
}

enum WidgetStyle {
    static let difficultyColors: [Int: Color] = [
        1: .green,
        2: .mint,
        3: .yellow,
        4: .orange,
        5: .red
    ]
}

struct TasksWidgetView: View {
    let entry: TasksEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        content
            .containerBackground(.background, for: .widget)
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(tasks: entry.tasks)
        case .systemMedium:
            MediumWidgetView(tasks: entry.tasks)
        case .systemLarge:
            LargeWidgetView(tasks: entry.tasks)
        default:
            EmptyView()
        }
    }
}


struct SmallWidgetView: View {
    let tasks: [WidgetTask]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            Text("Задачи")
                .font(.headline)

            VStack(alignment: .leading, spacing: 2) {
              
                Text("Выполнено: \(tasks.filter{$0.isCompleted}.count) / \(tasks.count) ")
            }
            .font(.caption2)
            .foregroundColor(.secondary)

            Divider()

            ForEach(tasks.prefix(3)) { task in
                HStack(spacing: 6) {
                    Circle()
                        .fill(
                            WidgetStyle.difficultyColors[task.difficulty] ?? .gray
                        )
                        .frame(width: 6, height: 6)

                    Text(task.title)
                        .font(.caption)
                        .lineLimit(1)
                        .strikethrough(task.isCompleted)
                        .opacity(task.isCompleted ? 0.5 : 1)
                }
            }

            Spacer()
        }
        .padding()
    }
}


struct MediumWidgetView: View {
    let tasks: [WidgetTask]

    var body: some View {
        HStack {

            VStack(alignment: .leading, spacing: 6) {
                Text("Сегодня")
                    .font(.headline)

                ForEach(tasks.prefix(5)) { task in
                    HStack {
                        Circle()
                            .fill(
                                WidgetStyle.difficultyColors[task.difficulty] ?? .gray
                            )
                            .frame(width: 6, height: 6)

                        Text(task.title)
                            .font(.caption)
                            .lineLimit(1)
                            .strikethrough(task.isCompleted)
                            .opacity(task.isCompleted ? 0.5 : 1)
                    }
                }
            }

            Spacer()

            VStack {
                Text("\(tasks.filter{$0.isCompleted}.count)/\(tasks.count)")
                    .font(.title2)
                    .bold()
                Text("выполнено")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

struct LargeWidgetView: View {
    let tasks: [WidgetTask]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("Задачи на сегодня")
                .font(.title2)
                .bold()

            ProgressView(
                value: Double(tasks.filter{$0.isCompleted}.count),
                total: Double(max(tasks.count, 1))
            )

            Divider()

            ForEach(tasks.prefix(8)) { task in
                HStack {
                    Circle()
                        .fill(
                            WidgetStyle.difficultyColors[task.difficulty] ?? .gray
                        )
                        .frame(width: 8, height: 8)

                    Text(task.title)
                        .font(.body)
                        .lineLimit(1)
                        .strikethrough(task.isCompleted)
                        .opacity(task.isCompleted ? 0.5 : 1)

                    Spacer()
                }
            }

            Spacer()
        }
        .padding()
    }
}

@main
struct DailyTasksWidget: Widget {

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: widgetKind,
            provider: TasksProvider()
        ) { entry in
            TasksWidgetView(entry: entry)
        }
        .configurationDisplayName("Задачи на день")
        .description("Показывает задачи на сегодня")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge
        ])
    }
}
