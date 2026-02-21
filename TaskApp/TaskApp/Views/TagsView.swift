import SwiftUI
import CoreData

struct TagsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var taskStore: TaskStore

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TagEntity.name, ascending: true)]
    ) private var tags: FetchedResults<TagEntity>

    @State private var showingAddTag = false
    @State private var newTagName = ""
    @State private var newTagColorIndex: Int32 = 0
    @State private var tagToEdit: TagEntity?

    var body: some View {
        NavigationStack {
            Group {
                if tags.isEmpty {
                    ContentUnavailableView(
                        "Нет тегов",
                        systemImage: "tag",
                        description: Text("Создайте тег и привяжите его к задачам в деталях задачи")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(tags) { tag in
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(TagPalette.color(for: Int(tag.colorIndex), colorScheme: colorScheme))
                                    .frame(width: 24, height: 24)
                                Text(tag.name)
                                    .font(.body)
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                            .onTapGesture { tagToEdit = tag }
                        }
                        .onDelete(perform: deleteTags)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Теги")
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        newTagName = ""
                        newTagColorIndex = 0
                        showingAddTag = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTag) {
                addTagSheet
            }
            .sheet(item: $tagToEdit) { tag in
                EditTagSheet(tag: tag) {
                    tagToEdit = nil
                }
                .environmentObject(taskStore)
            }
        }
    }

    private var addTagSheet: some View {
        NavigationStack {
            Form {
                TextField("Название тега", text: $newTagName)
                Section("Цвет") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(0..<TagPalette.count, id: \.self) { index in
                            let isSelected = newTagColorIndex == index
                            Button {
                                newTagColorIndex = Int32(index)
                            } label: {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(TagPalette.color(for: index, colorScheme: colorScheme))
                                    .frame(height: 44)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Новый тег")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        showingAddTag = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Создать") {
                        addTag()
                    }
                    .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func addTag() {
        let name = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            _ = taskStore.createTag(name: name, colorIndex: newTagColorIndex)
        }
        showingAddTag = false
    }

    private func deleteTags(at offsets: IndexSet) {
        withAnimation(.easeInOut(duration: 0.2)) {
            for index in offsets where index < tags.count {
                taskStore.deleteTag(tags[index])
            }
        }
    }
}

// MARK: - Редактирование тега (sheet)

struct EditTagSheet: View {
    let tag: TagEntity
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var taskStore: TaskStore
    @State private var name: String = ""
    @State private var colorIndex: Int32 = 0

    var body: some View {
        NavigationStack {
            Form {
                TextField("Название тега", text: $name)
                Section("Цвет") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(0..<TagPalette.count, id: \.self) { index in
                            let isSelected = colorIndex == index
                            Button {
                                colorIndex = Int32(index)
                            } label: {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(TagPalette.color(for: index, colorScheme: colorScheme))
                                    .frame(height: 44)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Редактировать тег")
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
                name = tag.name
                colorIndex = tag.colorIndex
            }
        }
    }

    private func saveAndDismiss() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        taskStore.updateTag(tag, name: trimmed, colorIndex: colorIndex)
        onDismiss()
    }
}

#Preview {
    TagsView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(TaskStore(context: PersistenceController.shared.container.viewContext))
}
