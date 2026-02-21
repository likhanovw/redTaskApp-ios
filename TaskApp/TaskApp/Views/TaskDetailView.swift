import SwiftUI
import CoreData

struct TaskDetailView: View {
    @ObservedObject var task: TaskEntity
    @EnvironmentObject private var taskStore: TaskStore
    @Environment(\.dismiss) private var dismiss

    @State private var editableTitle: String = ""
    @State private var editableDescription: String = ""
    @State private var newChecklistTitle: String = ""
    @State private var showingCompleteAlert = false
    /// Кэш id и objectID задачи, чтобы не обращаться к task при перерисовке после save().
    @State private var cachedTaskId: UUID?
    @State private var cachedTaskObjectID: NSManagedObjectID?

    private var isTimerActive: Bool {
        taskStore.activeTimerTaskId == (cachedTaskId ?? task.id)
    }

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TagEntity.name, ascending: true)]
    ) private var allTags: FetchedResults<TagEntity>

    var body: some View {
        Form {
            Section("Задача") {
                TextField("Название", text: $editableTitle)
                    .onSubmit { commitTitleAndDescription() }
                TextField("Описание", text: $editableDescription, axis: .vertical)
                    .lineLimit(2...5)
                    .onSubmit { commitTitleAndDescription() }
            }

            Section("Теги") {
                if allTags.isEmpty {
                    Text("Создайте теги во вкладке «Теги», затем выберите их здесь.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(allTags) { tag in
                        let isSelected = task.tagsArray.contains { $0.id == tag.id }
                        Button {
                            taskStore.toggleTag(tag, on: task)
                        } label: {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(TagPalette.color(for: Int(tag.colorIndex)))
                                    .frame(width: 24, height: 24)
                                Text(tag.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }
                }
            }

            Section("Чеклист") {
                checklistSection
            }

            Section("Таймер") {
                timerSection
            }

            Section {
                Button(role: .destructive) {
                    showingCompleteAlert = true
                } label: {
                    Label("Завершить задачу", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .disabled(task.isCompleted)
            }
        }
        .navigationTitle("Детали")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            cachedTaskId = task.id
            cachedTaskObjectID = task.objectID
            editableTitle = task.title
            editableDescription = task.taskDescription ?? ""
        }
        .onDisappear {
            commitTitleAndDescription()
            taskStore.notifyDetailDismissed()
            // Таймер не останавливаем при выходе — пользователь может вернуться, время продолжает идти
        }
        .alert("Завершить задачу?", isPresented: $showingCompleteAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Завершить") {
                withAnimation(.easeInOut(duration: 0.25)) {
                    taskStore.markTaskCompleted(task)
                }
                dismiss()
            }
        } message: {
            Text("Задача будет перенесена в архив.")
        }
    }

    private var checklistSection: some View {
        let items = task.checklistItemsArray
        let completedCount = items.filter(\.isCompleted).count
        let totalCount = items.count

        return Group {
            if totalCount > 0 {
                HStack(spacing: 8) {
                    ProgressView(value: Double(completedCount) / Double(totalCount))
                        .tint(.accentColor)
                        .animation(.easeInOut(duration: 0.3), value: completedCount)
                    Text("\(completedCount)/\(totalCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            ForEach(items) { item in
                HStack(spacing: 10) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            taskStore.toggleChecklistItem(item)
                        }
                    } label: {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isCompleted ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                    Text(item.title)
                        .strikethrough(item.isCompleted)
                        .foregroundStyle(item.isCompleted ? .secondary : .primary)
                    Spacer()
                    Button {
                        let oid = cachedTaskObjectID ?? task.objectID
                        taskStore.deleteChecklistItem(byId: item.id, taskObjectID: oid)
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 2)
            }
            .onDelete { indexSet in
                let oid = cachedTaskObjectID ?? task.objectID
                for index in indexSet where index < items.count {
                    let item = items[index]
                    taskStore.deleteChecklistItem(byId: item.id, taskObjectID: oid)
                }
            }
            HStack {
                TextField("Новый пункт", text: $newChecklistTitle)
                    .onSubmit { addChecklistItem() }
                Button {
                    addChecklistItem()
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(newChecklistTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var timerSection: some View {
        let totalSeconds = task.totalTimeSpent + (isTimerActive ? taskStore.currentSessionSeconds : 0)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Текущая сессия:")
                    .foregroundStyle(.secondary)
                Spacer()
                if isTimerActive {
                    Text(formatTime(taskStore.currentSessionSeconds))
                        .fontWeight(.medium)
                        .monospacedDigit()
                } else {
                    Text("—")
                        .foregroundStyle(.secondary)
                }
            }
            HStack {
                Text("Всего времени:")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatTime(totalSeconds))
                    .fontWeight(.medium)
                    .monospacedDigit()
            }
            Button {
                if isTimerActive {
                    taskStore.stopTimer()
                } else {
                    taskStore.startTimer(for: task)
                }
            } label: {
                HStack {
                    Image(systemName: isTimerActive ? "stop.fill" : "play.fill")
                    Text(isTimerActive ? "Стоп" : "Старт")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(isTimerActive ? .red : .accentColor)
            .animation(.easeInOut(duration: 0.2), value: isTimerActive)
        }
    }

    private func addChecklistItem() {
        let title = newChecklistTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let oid = cachedTaskObjectID ?? task.objectID
        taskStore.addChecklistItem(taskObjectID: oid, title: title)
        newChecklistTitle = ""
    }

    private func commitTitleAndDescription() {
        let t = editableTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !t.isEmpty && t != task.title {
            taskStore.updateTask(task, title: t, taskDescription: editableDescription.isEmpty ? nil : editableDescription)
        } else if task.taskDescription != editableDescription {
            taskStore.updateTask(task, title: nil, taskDescription: editableDescription.isEmpty ? nil : editableDescription)
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%d:%02d", m, s)
        }
    }

}

#Preview {
    let ctx = PersistenceController.shared.container.viewContext
    let task = TaskEntity(context: ctx)
    task.id = UUID()
    task.title = "Пример задачи"
    task.taskDescription = "Описание"
    task.isCompleted = false
    task.order = 0
    task.totalTimeSpent = 0
    task.createdAt = Date()
    return NavigationStack {
        TaskDetailView(task: task)
            .environmentObject(TaskStore(context: ctx))
    }
}
