import SwiftUI
import SwiftData

struct FavoritesView: View {
    let onStartPractice: (String) -> Void  // 新增：开始练习回调
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FavoriteText.createdAt, order: .reverse) private var favorites: [FavoriteText]
    
    @State private var showAddSheet = false
    @State private var newTitle = ""
    @State private var newContent = ""

    init(onStartPractice: @escaping (String) -> Void) {
        self.onStartPractice = onStartPractice
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("收藏的文本")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    showAddSheet = true
                } label: {
                    Label("添加", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            if favorites.isEmpty {
                // 空状态
                VStack(spacing: 20) {
                    Image(systemName: "star")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    
                    Text("还没有收藏的文本")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    
                    Button("添加第一个收藏") {
                        showAddSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 收藏列表
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(favorites) { favorite in
                            FavoriteCard(
                                favorite: favorite,
                                onDelete: {
                                    modelContext.delete(favorite)
                                    do {
                                        try modelContext.save()
                                    } catch {
                                        print("❌ 删除收藏失败: \(error.localizedDescription)")
                                    }
                                },
                                onStartPractice: {
                                    onStartPractice(favorite.content)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddFavoriteSheet(
                title: $newTitle,
                content: $newContent,
                onSave: {
                    saveFavorite()
                },
                onCancel: {
                    showAddSheet = false
                    newTitle = ""
                    newContent = ""
                }
            )
        }
    }
    
    private func saveFavorite() {
        guard !newTitle.isEmpty, !newContent.isEmpty else { return }
        
        let favorite = FavoriteText(title: newTitle, content: newContent, category: "自定义")
        modelContext.insert(favorite)
        
        do {
            try modelContext.save()
        } catch {
            print("❌ 保存收藏失败: \(error.localizedDescription)")
        }
        
        showAddSheet = false
        newTitle = ""
        newContent = ""
    }
}

struct FavoriteCard: View {
    let favorite: FavoriteText
    let onDelete: () -> Void
    let onStartPractice: () -> Void  // 新增：开始练习回调
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(favorite.title)
                    .font(.headline)
                
                Spacer()
                
                // 开始练习按钮
                Button {
                    onStartPractice()
                } label: {
                    Label("开始练习", systemImage: "play.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
            
            Text(favorite.content)
                .font(.body)
                .lineLimit(3)
                .foregroundStyle(.secondary)
            
            HStack {
                Text(favorite.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundStyle(Color.accentColor)
                    .cornerRadius(4)
                
                Spacer()
                
                Text(favorite.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
    }
}

struct AddFavoriteSheet: View {
    @Binding var title: String
    @Binding var content: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("添加收藏文本")
                .font(.title2)
                .fontWeight(.bold)
            
            TextField("标题", text: $title)
                .textFieldStyle(.roundedBorder)
            
            TextEditor(text: $content)
                .frame(height: 200)
                .padding(8)
                .background(Color(.textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            HStack(spacing: 12) {
                Button("取消") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                
                Button("保存") {
                    onSave()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty || content.isEmpty)
            }
        }
        .padding(30)
        .frame(width: 500, height: 400)
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView(onStartPractice: { _ in })
            .modelContainer(for: [PracticeSession.self, FavoriteText.self], inMemory: true)
    }
}
