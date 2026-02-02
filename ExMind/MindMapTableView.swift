//
//  MindMapTableView.swift
//  ExMind
//
//  Created by gotree94 on 12/20/25.
//

import SwiftUI
import SwiftData

struct MindMapTableView: View {
    let nodes: [MindMapNode]
    @Binding var selectedNode: MindMapNode?
    let onDeleteNode: (MindMapNode) -> Void
    @Environment(\.modelContext) private var modelContext
    
    @State private var columnKeys: [String] = ["Title", "Notes", "Created", "Modified"]
    @State private var showingAddColumn = false
    @State private var newColumnName = ""
    
    var allNodes: [MindMapNode] {
        var result: [MindMapNode] = []
        for node in nodes {
            result.append(contentsOf: flattenNode(node))
        }
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 테이블 헤더
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 0) {
                    // 계층 표시 컬럼
                    Text("Level")
                        .frame(width: 60)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                    
                    Divider()
                    
                    // 기본 컬럼들
                    ForEach(columnKeys, id: \.self) { key in
                        TableHeaderCell(title: key)
                        Divider()
                    }
                    
                    // 커스텀 속성 컬럼들
                    ForEach(getUniquePropertyKeys(), id: \.self) { key in
                        TableHeaderCell(title: key)
                        Divider()
                    }
                    
                    // 새 컬럼 추가 버튼
                    Button(action: { showingAddColumn = true }) {
                        Image(systemName: "plus.circle")
                            .frame(width: 40)
                    }
                    .buttonStyle(.plain)
                }
                .frame(height: 40)
            }
#if os(macOS)
            .background(Color(nsColor: .controlBackgroundColor))
#else
            .background(Color(uiColor: .secondarySystemBackground))
#endif
            
            Divider()
            
            // 테이블 본문
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                VStack(spacing: 0) {
                    ForEach(allNodes) { node in
                        TableRowView(
                            node: node,
                            allNodes: allNodes,
                            level: nodeLevel(node),
                            columnKeys: columnKeys,
                            propertyKeys: getUniquePropertyKeys(),
                            isSelected: selectedNode?.id == node.id,
                            onSelect: { selectedNode = node },
                            onDelete: { onDeleteNode(node) }
                        )
                        Divider()
                    }
                }
            }
        }
        .alert("Add New Column", isPresented: $showingAddColumn) {
            TextField("Column Name", text: $newColumnName)
            Button("Add") {
                if !newColumnName.isEmpty {
                    addPropertyToAllNodes(key: newColumnName)
                    newColumnName = ""
                }
            }
            Button("Cancel", role: .cancel) {
                newColumnName = ""
            }
        }
    }
    
    private func flattenNode(_ node: MindMapNode) -> [MindMapNode] {
        var result = [node]
        for child in node.children {
            result.append(contentsOf: flattenNode(child))
        }
        return result
    }
    
    private func nodeLevel(_ node: MindMapNode) -> Int {
        var level = 0
        var current = node
        while let parent = current.parent {
            level += 1
            current = parent
        }
        return level
    }
    
    private func getUniquePropertyKeys() -> [String] {
        var keys = Set<String>()
        for node in allNodes {
            for property in node.properties {
                keys.insert(property.key)
            }
        }
        return keys.sorted()
    }
    
    private func addPropertyToAllNodes(key: String) {
        for node in allNodes {
            if !node.properties.contains(where: { $0.key == key }) {
                let property = NodeProperty(key: key, value: "", order: node.properties.count)
                modelContext.insert(property)
                node.properties.append(property)
            }
        }
    }
}

// 테이블 헤더 셀
struct TableHeaderCell: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .frame(width: 150, alignment: .leading)
            .padding(.horizontal)
            .background(Color.gray.opacity(0.2))
    }
}

// 테이블 행 뷰
struct TableRowView: View {
    @Bindable var node: MindMapNode
    let allNodes: [MindMapNode]
    let level: Int
    let columnKeys: [String]
    let propertyKeys: [String]
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    // 노트 계산
    var evaluatedNotes: FormulaResult {
        node.evaluateNotes(with: allNodes)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // 레벨 표시
            Text("\(level)")
                .frame(width: 60)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            
            Divider()
            
            // Title
            EditableTableCell(text: $node.title, width: 150)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            Divider()
            
            // Notes (수식 입력)
            HStack {
                EditableTableCell(text: $node.notes, width: 100)
                
                Text("→")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                
                // 계산 결과
                Text(evaluatedNotes.displayValue)
                    .font(.system(.body, design: .monospaced))
                    .strikethrough(evaluatedNotes.isError)
                    .foregroundStyle(evaluatedNotes.isError ? .red : .primary)
                    .frame(width: 50, alignment: .trailing)
            }
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            Divider()
            
            // Created
            Text(node.createdAt, format: .dateTime)
                .frame(width: 150, alignment: .leading)
                .padding(.horizontal)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            Divider()
            
            // Modified
            Text(node.modifiedAt, format: .dateTime)
                .frame(width: 150, alignment: .leading)
                .padding(.horizontal)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            Divider()
            
            // 커스텀 속성들
            ForEach(propertyKeys, id: \.self) { key in
                if let property = node.properties.first(where: { $0.key == key }) {
                    PropertyTableCell(property: property)
                        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                } else {
                    Text("")
                        .frame(width: 150)
                        .padding(.horizontal)
                        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                }
                Divider()
            }
            
            // 삭제 버튼
            if isSelected {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .frame(width: 40)
                .background(Color.accentColor.opacity(0.2))
            }
        }
        .frame(height: 40)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

// 편집 가능한 테이블 셀
struct EditableTableCell: View {
    @Binding var text: String
    let width: CGFloat
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField("", text: $text)
            .textFieldStyle(.plain)
            .focused($isFocused)
            .frame(width: width, alignment: .leading)
            .padding(.horizontal)
    }
}

// 속성 테이블 셀
struct PropertyTableCell: View {
    @Bindable var property: NodeProperty
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Group {
            switch property.propertyType {
            case "number":
                TextField("", text: $property.value)
#if os(iOS)
                    .keyboardType(.decimalPad)
#endif
            case "date":
                if let date = ISO8601DateFormatter().date(from: property.value) {
                    DatePicker("", selection: .constant(date), displayedComponents: .date)
                        .labelsHidden()
                } else {
                    TextField("", text: $property.value)
                }
            case "boolean":
                Toggle("", isOn: Binding(
                    get: { property.value.lowercased() == "true" },
                    set: { property.value = $0 ? "true" : "false" }
                ))
                .labelsHidden()
            default:
                TextField("", text: $property.value)
            }
        }
        .textFieldStyle(.plain)
        .focused($isFocused)
        .frame(width: 150, alignment: .leading)
        .padding(.horizontal)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MindMapNode.self, configurations: config)
    
    let node1 = MindMapNode(title: "Main Node", positionX: 0, positionY: 0)
    let node2 = MindMapNode(title: "Child Node", positionX: 0, positionY: 0)
    
    node1.children.append(node2)
    node2.parent = node1
    
    container.mainContext.insert(node1)
    container.mainContext.insert(node2)
    
    return MindMapTableView(
        nodes: [node1],
        selectedNode: .constant(node1),
        onDeleteNode: { _ in }
    )
    .modelContainer(container)
    .frame(height: 400)
}
