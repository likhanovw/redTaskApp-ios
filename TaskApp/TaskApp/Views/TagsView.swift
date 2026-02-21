import SwiftUI
import CoreData

struct TagsView: View {
    @EnvironmentObject private var taskStore: TaskStore

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TagEntity.name, ascending: true)]
    ) private var tags: FetchedResults<TagEntity>

    @State private var showingAddTag = false
    @State private var newTagName = ""
    @State private var newTagColorIndex: Int32 = 0

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
                                    .fill(TagPalette.color(for: Int(tag.colorIndex)))
                                    .frame(width: 24, height: 24)
                                Text(tag.name)
                                    .font(.body)
                            }
                            .padding(.vertical, 6)
                        }
                        .onDelete(perform: deleteTags)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Теги")
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
                                    .fill(TagPalette.color(for: index))
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

#Preview {
    TagsView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(TaskStore(context: PersistenceController.shared.container.viewContext))
}
