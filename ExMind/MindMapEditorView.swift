//
//  MindMapEditorView.swift
//  ExMind
//
//  Created by gotree94 on 12/20/25.
//

import SwiftUI
import SwiftData

enum EditorMode {
    case canvas  // 시각적 마인드맵
    case table   // 엑셀 스타일 테이블
    case outline // 아웃라인 뷰
}

struct MindMapEditorView: View {
    @Bindable var document: MindMapDocument
    @Environment(\.modelContext) private var modelContext
    @State private var editorMode: EditorMode = .canvas
    @State private var selectedNode: MindMapNode?
    @State private var editingTitle = false
    @State private var showingDeleteAlert = false
    @State private var propertiesPanelHeight: CGFloat = 180
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 툴바
            EditorToolbar(
                document: document,
                editorMode: $editorMode,
                editingTitle: $editingTitle,
                onAddNode: addRootNode,
                onDeleteNode: selectedNode != nil ? { showingDeleteAlert = true } : nil
            )
            
            Divider()
            
            // 메인 에디터 영역
            Group {
                switch editorMode {
                case .canvas:
                    MindMapCanvasView(
                        nodes: document.rootNodes,
                        selectedNode: $selectedNode,
                        onAddChild: addChildNode,
                        onDeleteNode: deleteNode
                    )
                case .table:
                    MindMapTableView(
                        nodes: document.rootNodes,
                        selectedNode: $selectedNode,
                        onDeleteNode: deleteNode
                    )
                case .outline:
                    MindMapOutlineView(
                        nodes: document.rootNodes,
                        selectedNode: $selectedNode,
                        onAddChild: addChildNode,
                        onDeleteNode: deleteNode
                    )
                }
            }
            
            // 하단 속성 패널 (크기 조절 가능)
            if let node = selectedNode {
                ResizableDivider(height: $propertiesPanelHeight)
                
                NodePropertiesPanel(node: node, onDelete: {
                    showingDeleteAlert = true
                })
                .frame(height: propertiesPanelHeight)
            }
        }
        .alert("Edit Title", isPresented: $editingTitle) {
            TextField("Title", text: $document.title)
            Button("OK", action: {})
            Button("Cancel", role: .cancel, action: {})
        }
        .alert("Delete Node", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let node = selectedNode {
                    deleteNode(node)
                }
            }
            Button("Cancel", role: .cancel, action: {})
        } message: {
            Text("Are you sure you want to delete this node? All child nodes will also be deleted.")
        }
#if os(macOS)
        .onDeleteCommand {
            if selectedNode != nil {
                showingDeleteAlert = true
            }
        }
#endif
    }
    
    private func addRootNode() {
        withAnimation {
            let newNode = MindMapNode(
                title: "New Node",
                positionX: Double.random(in: 100...400),
                positionY: Double.random(in: 100...400)
            )
            modelContext.insert(newNode)
            document.rootNodes.append(newNode)
            document.modifiedAt = Date()
            selectedNode = newNode
        }
    }
    
    private func addChildNode(to parent: MindMapNode) {
        withAnimation {
            let newNode = MindMapNode(
                title: "New Child",
                positionX: parent.positionX + 200,
                positionY: parent.positionY + Double.random(in: -50...50)
            )
            newNode.parent = parent
            modelContext.insert(newNode)
            parent.children.append(newNode)
            document.modifiedAt = Date()
            selectedNode = newNode
        }
    }
    
    private func deleteNode(_ node: MindMapNode) {
        withAnimation {
            // 선택 해제
            if selectedNode?.id == node.id {
                selectedNode = nil
            }
            
            // 루트 노드에서 제거
            if let index = document.rootNodes.firstIndex(where: { $0.id == node.id }) {
                document.rootNodes.remove(at: index)
            }
            
            // 부모에서 제거
            if let parent = node.parent,
               let index = parent.children.firstIndex(where: { $0.id == node.id }) {
                parent.children.remove(at: index)
            }
            
            // 데이터베이스에서 삭제 (cascade로 자식도 함께 삭제됨)
            modelContext.delete(node)
            document.modifiedAt = Date()
        }
    }
}

// 에디터 툴바
struct EditorToolbar: View {
    @Bindable var document: MindMapDocument
    @Binding var editorMode: EditorMode
    @Binding var editingTitle: Bool
    let onAddNode: () -> Void
    let onDeleteNode: (() -> Void)?
    
    var body: some View {
        HStack {
            // 문서 제목
            Button(action: { editingTitle = true }) {
                HStack(spacing: 4) {
                    Text(document.title)
                        .font(.headline)
                    Image(systemName: "pencil")
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // 뷰 모드 선택
            Picker("Mode", selection: $editorMode) {
                Label("Canvas", systemImage: "square.on.circle").tag(EditorMode.canvas)
                Label("Table", systemImage: "tablecells").tag(EditorMode.table)
                Label("Outline", systemImage: "list.bullet.indent").tag(EditorMode.outline)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 400)
            
            Spacer()
            
            // 노드 삭제 버튼
            if let deleteAction = onDeleteNode {
                Button(action: deleteAction) {
                    Label("Delete Node", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            
            // 노드 추가 버튼
            Button(action: onAddNode) {
                Label("Add Node", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

// 크기 조절 가능한 구분선
struct ResizableDivider: View {
    @Binding var height: CGFloat
    @State private var isDragging = false
    @State private var isHovering = false
    
    let minHeight: CGFloat = 120
    let maxHeight: CGFloat = 600
    
    var body: some View {
        ZStack {
            // 배경
            Rectangle()
                .fill(backgroundGradient)
                .frame(height: 12)
            
            // 드래그 핸들 (3개의 작은 선)
            VStack(spacing: 2) {
                ForEach(0..<3) { _ in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(handleColor)
                        .frame(width: 40, height: 2)
                }
            }
            .opacity(isHovering || isDragging ? 1.0 : 0.4)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
            .animation(.easeInOut(duration: 0.2), value: isDragging)
        }
        .frame(height: 12)
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    // 드래그 방향: 위로 드래그하면 패널 높이 증가
                    let newHeight = height - value.translation.height
                    height = min(max(newHeight, minHeight), maxHeight)
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
        .onHover { hovering in
            isHovering = hovering
#if os(macOS)
            if hovering {
                NSCursor.resizeUpDown.push()
            } else {
                NSCursor.pop()
            }
#endif
        }
    }
    
    private var backgroundGradient: LinearGradient {
        if isDragging {
            return LinearGradient(
                colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else if isHovering {
            return LinearGradient(
                colors: [Color.secondary.opacity(0.1), Color.secondary.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
#if os(macOS)
            return LinearGradient(
                colors: [Color(nsColor: .separatorColor).opacity(0.5), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
#else
            return LinearGradient(
                colors: [Color(uiColor: .separator).opacity(0.5), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
#endif
        }
    }
    
    private var handleColor: Color {
        if isDragging {
            return Color.accentColor
        } else if isHovering {
            return Color.secondary
        } else {
            return Color.secondary.opacity(0.5)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MindMapDocument.self, configurations: config)
    let document = MindMapDocument(title: "Sample Mind Map")
    container.mainContext.insert(document)
    
    return MindMapEditorView(document: document)
        .modelContainer(container)
}
