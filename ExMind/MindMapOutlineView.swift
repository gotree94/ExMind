//
//  MindMapOutlineView.swift
//  ExMind
//
//  Created by gotree94 on 12/20/25.
//

import SwiftUI
import SwiftData

struct MindMapOutlineView: View {
    let nodes: [MindMapNode]
    @Binding var selectedNode: MindMapNode?
    let onAddChild: (MindMapNode) -> Void
    let onDeleteNode: (MindMapNode) -> Void
    
    // 모든 노드를 flat하게 가져오기 (수식 계산용)
    var allNodes: [MindMapNode] {
        var result: [MindMapNode] = []
        func flatten(_ nodes: [MindMapNode]) {
            for node in nodes {
                result.append(node)
                flatten(node.children)
            }
        }
        flatten(nodes)
        return result
    }
    
    var body: some View {
        List(selection: $selectedNode) {
            ForEach(nodes) { node in
                OutlineNodeView(
                    node: node,
                    allNodes: allNodes,
                    selectedNode: $selectedNode,
                    onAddChild: onAddChild,
                    onDeleteNode: onDeleteNode
                )
            }
        }
#if os(macOS)
        .listStyle(.sidebar)
#else
        .listStyle(.insetGrouped)
#endif
    }
}

// 재귀적 아웃라인 노드 뷰
struct OutlineNodeView: View {
    @Bindable var node: MindMapNode
    let allNodes: [MindMapNode]
    @Binding var selectedNode: MindMapNode?
    let onAddChild: (MindMapNode) -> Void
    let onDeleteNode: (MindMapNode) -> Void
    @State private var isExpanded = true
    
    // 노트 계산
    var evaluatedNotes: FormulaResult {
        node.evaluateNotes(with: allNodes)
    }
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(node.children) { child in
                OutlineNodeView(
                    node: child,
                    allNodes: allNodes,
                    selectedNode: $selectedNode,
                    onAddChild: onAddChild,
                    onDeleteNode: onDeleteNode
                )
            }
        } label: {
            HStack {
                Circle()
                    .fill(node.color)
                    .frame(width: 12, height: 12)
                
                // [타이틀]:값 형식으로 표시
                HStack(spacing: 4) {
                    Text("[\(node.title)]")
                        .font(.body)
                    
                    Text(":")
                        .foregroundStyle(.secondary)
                    
                    Text(evaluatedNotes.displayValue)
                        .font(.system(.body, design: .monospaced))
                        .strikethrough(evaluatedNotes.isError)
                        .foregroundStyle(evaluatedNotes.isError ? .red : .primary)
                }
                
                Spacer()
                
                if selectedNode?.id == node.id {
                    Button(action: { onAddChild(node) }) {
                        Image(systemName: "plus.circle")
                    }
                    .buttonStyle(.borderless)
                    
                    Button(action: { onDeleteNode(node) }) {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                }
                
                Text("\(node.children.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .tag(node)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MindMapNode.self, configurations: config)
    
    let node1 = MindMapNode(title: "Main Idea", positionX: 0, positionY: 0)
    let node2 = MindMapNode(title: "Sub Idea 1", positionX: 0, positionY: 0)
    let node3 = MindMapNode(title: "Sub Idea 2", positionX: 0, positionY: 0)
    
    node1.children.append(node2)
    node1.children.append(node3)
    node2.parent = node1
    node3.parent = node1
    
    container.mainContext.insert(node1)
    container.mainContext.insert(node2)
    container.mainContext.insert(node3)
    
    return MindMapOutlineView(
        nodes: [node1],
        selectedNode: .constant(node1),
        onAddChild: { _ in },
        onDeleteNode: { _ in }
    )
    .modelContainer(container)
}
