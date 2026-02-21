import SwiftUI
import CoreData

struct EpicsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var taskStore: TaskStore

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \EpicEntity.order, ascending: true), NSSortDescriptor(keyPath: \EpicEntity.name, ascending: true)]
    ) private var epics: FetchedResults<EpicEntity>

    @State private var showingAddEpic = false
    @State private var newEpicName = ""
    @State private var epicToEdit: EpicEntity?

    var body: some View {
        NavigationStack {
            Group {
                if epics.isEmpty {
                    ContentUnavailableView(
                        "Нет эпиков",
                        systemImage: "square.stack.3d.up",
                        description: Text("Создайте эпик и привяжите его к задачам в деталях задачи")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(epics) { epic in
                            HStack(spacing: 12) {
                                Text("#\(epic.name)")
                                    .font(.body)
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                            .onTapGesture { epicToEdit = epic }
                        }
                        .onDelete(perform: deleteEpics)
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await MainActor.run {
                            viewContext.refreshAllObjects()
                        }
                    }
                }
            }
            .navigationTitle("Эпики")
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        newEpicName = ""
                        showingAddEpic = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEpic) {
                addEpicSheet
            }
            .sheet(item: $epicToEdit) { epic in
                EditEpicSheet(epic: epic) {
                    epicToEdit = nil
                }
                .environmentObject(taskStore)
            }
        }
    }

    private var addEpicSheet: some View {
        NavigationStack {
            Form {
                TextField("Название эпика", text: $newEpicName)
            }
            .navigationTitle("Новый эпик")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        showingAddEpic = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        addEpic()
                    }
                    .disabled(newEpicName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func addEpic() {
        let name = newEpicName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            _ = taskStore.createEpic(name: name)
        }
        showingAddEpic = false
    }

    private func deleteEpics(at offsets: IndexSet) {
        withAnimation(.easeInOut(duration: 0.2)) {
            for index in offsets where index < epics.count {
                taskStore.deleteEpic(epics[index])
            }
        }
    }
}

// MARK: - Редактирование эпика (sheet)

struct EditEpicSheet: View {
    let epic: EpicEntity
    let onDismiss: () -> Void

    @EnvironmentObject private var taskStore: TaskStore
    @State private var name: String = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Название эпика", text: $name)
            }
            .navigationTitle("Редактировать эпик")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        saveAndDismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                name = epic.name
            }
        }
    }

    private func saveAndDismiss() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        taskStore.updateEpic(epic, name: trimmed)
        onDismiss()
    }
}

#Preview {
    EpicsView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(TaskStore(context: PersistenceController.shared.container.viewContext))
}
