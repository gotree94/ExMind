//
//  MindMapCanvasView.swift
//  ExMind
//
//  Created by gotree94 on 12/20/25.
//

import SwiftUI
import SwiftData

struct MindMapCanvasView: View {
    let nodes: [MindMapNode]
    @Binding var selectedNode: MindMapNode?
    let onAddChild: (MindMapNode) -> Void
    let onDeleteNode: (MindMapNode) -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
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
        ZStack {
            // 배경 그리드
            CanvasGridBackground()
            
            // 연결선 그리기
            Canvas { context, size in
                drawConnections(context: context, nodes: nodes)
            }
            
            // 노드들
            ForEach(nodes) { node in
                NodeWithChildrenView(
                    node: node,
                    allNodes: allNodes,
                    selectedNode: $selectedNode,
                    onAddChild: onAddChild,
                    onDeleteNode: onDeleteNode
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
#if os(macOS)
        .background(Color(nsColor: .textBackgroundColor))
#else
        .background(Color(uiColor: .systemBackground))
#endif
        .scaleEffect(scale)
        .offset(offset)
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    scale = value
                }
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                }
                .onEnded { _ in
                    lastOffset = offset
                }
        )
        .toolbar {
            ToolbarItem {
                HStack {
                    Button(action: { scale = min(scale + 0.1, 3.0) }) {
                        Label("Zoom In", systemImage: "plus.magnifyingglass")
                    }
                    Button(action: { scale = max(scale - 0.1, 0.3) }) {
                        Label("Zoom Out", systemImage: "minus.magnifyingglass")
                    }
                    Button(action: resetView) {
                        Label("Reset View", systemImage: "arrow.counterclockwise")
                    }
                }
            }
        }
    }
    
    private func drawConnections(context: GraphicsContext, nodes: [MindMapNode]) {
        for node in nodes {
            drawNodeConnections(context: context, node: node)
        }
    }
    
    private func drawNodeConnections(context: GraphicsContext, node: MindMapNode) {
        let boxWidth: CGFloat = 160
        let boxHeight: CGFloat = 70
        
        for child in node.children {
            // 부모의 출발점 계산
            let parentAnchor = node.getParentAnchorPoint(boxWidth: boxWidth, boxHeight: boxHeight, child: child)
            let startPoint = CGPoint(
                x: node.positionX + parentAnchor.x,
                y: node.positionY + parentAnchor.y
            )
            
            // 자식의 도착점 계산
            let childAnchor = child.getAnchorPoint(boxWidth: boxWidth, boxHeight: boxHeight, relativeTo: node)
            let endPoint = CGPoint(
                x: child.positionX + childAnchor.x,
                y: child.positionY + childAnchor.y
            )
            
            var path = Path()
            path.move(to: startPoint)
            
            // 곡선 연결 (베지어 곡선)
            let dx = endPoint.x - startPoint.x
            let dy = endPoint.y - startPoint.y
            let distance = sqrt(dx * dx + dy * dy)
            let controlDistance = min(distance * 0.4, 80)
            
            // 출발점과 도착점의 방향에 따라 제어점 계산
            var controlPoint1 = startPoint
            var controlPoint2 = endPoint
            
            // 부모 앵커 방향으로 제어점 설정
            if abs(parentAnchor.x) > abs(parentAnchor.y) {
                // 좌우 방향
                controlPoint1.x += parentAnchor.x > 0 ? controlDistance : -controlDistance
            } else {
                // 상하 방향
                controlPoint1.y += parentAnchor.y > 0 ? controlDistance : -controlDistance
            }
            
            // 자식 앵커 방향으로 제어점 설정
            if abs(childAnchor.x) > abs(childAnchor.y) {
                // 좌우 방향
                controlPoint2.x += childAnchor.x > 0 ? -controlDistance : controlDistance
            } else {
                // 상하 방향
                controlPoint2.y += childAnchor.y > 0 ? -controlDistance : controlDistance
            }
            
            path.addCurve(to: endPoint, control1: controlPoint1, control2: controlPoint2)
            
            context.stroke(
                path,
                with: .color(node.color.opacity(0.5)),
                lineWidth: 2
            )
            
            // 재귀적으로 자식 노드들의 연결선도 그리기
            drawNodeConnections(context: context, node: child)
        }
    }
    
    private func resetView() {
        withAnimation {
            scale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }
}

// 노드와 그 자식들을 표시하는 뷰
struct NodeWithChildrenView: View {
    @Bindable var node: MindMapNode
    let allNodes: [MindMapNode]
    @Binding var selectedNode: MindMapNode?
    let onAddChild: (MindMapNode) -> Void
    let onDeleteNode: (MindMapNode) -> Void
    
    var body: some View {
        Group {
            // 현재 노드
            DraggableNodeView(
                node: node,
                allNodes: allNodes,
                isSelected: selectedNode?.id == node.id,
                onSelect: { selectedNode = node },
                onAddChild: { onAddChild(node) },
                onDelete: { onDeleteNode(node) }
            )
            .position(x: node.positionX, y: node.positionY)
            
            // 자식 노드들
            ForEach(node.children) { child in
                NodeWithChildrenView(
                    node: child,
                    allNodes: allNodes,
                    selectedNode: $selectedNode,
                    onAddChild: onAddChild,
                    onDeleteNode: onDeleteNode
                )
            }
        }
    }
}

// 드래그 가능한 노드 뷰
struct DraggableNodeView: View {
    @Bindable var node: MindMapNode
    let allNodes: [MindMapNode]
    let isSelected: Bool
    let onSelect: () -> Void
    let onAddChild: () -> Void
    let onDelete: () -> Void
    
    @State private var isDragging = false
    @State private var isEditingTitle = false
    @State private var isEditingNotes = false
    @FocusState private var titleFocused: Bool
    @FocusState private var notesFocused: Bool
    
    // 노트 계산
    var evaluatedNotes: FormulaResult {
        node.evaluateNotes(with: allNodes)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // 타이틀 영역
            HStack(spacing: 8) {
                if isEditingTitle {
                    TextField("Title", text: $node.title)
                        .textFieldStyle(.plain)
                        .focused($titleFocused)
                        .onSubmit {
                            isEditingTitle = false
                        }
                } else {
                    Text("[\(node.title)]")
                        .font(.system(size: 14, weight: .bold))
                        .lineLimit(1)
                        .onTapGesture(count: 2) {
                            isEditingTitle = true
                            titleFocused = true
                        }
                }
                
                if isSelected && !isEditingTitle {
                    Button(action: onAddChild) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            
            // 노트 값 영역
            HStack(spacing: 4) {
                Text(":")
                    .font(.system(size: 13))
                
                if isEditingNotes {
                    TextField("Notes", text: $node.notes)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .focused($notesFocused)
                        .onSubmit {
                            isEditingNotes = false
                        }
                } else {
                    if !node.notes.isEmpty {
                        Text(evaluatedNotes.displayValue)
                            .font(.system(size: 13, weight: .medium))
                            .strikethrough(evaluatedNotes.isError)
                            .foregroundStyle(evaluatedNotes.isError ? .white.opacity(0.7) : .white)
                            .lineLimit(1)
                            .onTapGesture(count: 2) {
                                isEditingNotes = true
                                notesFocused = true
                            }
                    } else {
                        Text("0")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.5))
                            .onTapGesture(count: 2) {
                                isEditingNotes = true
                                notesFocused = true
                            }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 8)
        }
        .frame(minWidth: 160)
        .background(node.color)
        .foregroundStyle(.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.2), radius: isDragging ? 8 : 4, y: isDragging ? 4 : 2)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
            )
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    node.positionX += value.translation.width
                    node.positionY += value.translation.height
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
        .onTapGesture {
            if !isEditingTitle && !isEditingNotes {
                onSelect()
            }
        }
        .onChange(of: titleFocused) { _, newValue in
            if !newValue {
                isEditingTitle = false
            }
        }
        .onChange(of: notesFocused) { _, newValue in
            if !newValue {
                isEditingNotes = false
            }
        }
    }
}

// 캔버스 배경 그리드
struct CanvasGridBackground: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 30
            
            for x in stride(from: 0, through: size.width, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(.gray.opacity(0.1)), lineWidth: 1)
            }
            
            for y in stride(from: 0, through: size.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(.gray.opacity(0.1)), lineWidth: 1)
            }
        }
    }
}

// macOS/iOS 호환성
#if os(macOS)
import AppKit
#else
import UIKit
#endif

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MindMapNode.self, configurations: config)
    
    let node1 = MindMapNode(title: "Main Idea", positionX: 200, positionY: 200)
    let node2 = MindMapNode(title: "Sub Idea 1", positionX: 400, positionY: 150)
    let node3 = MindMapNode(title: "Sub Idea 2", positionX: 400, positionY: 250)
    
    container.mainContext.insert(node1)
    container.mainContext.insert(node2)
    container.mainContext.insert(node3)
    
    node1.children.append(node2)
    node1.children.append(node3)
    
    return MindMapCanvasView(
        nodes: [node1],
        selectedNode: .constant(node1),
        onAddChild: { _ in },
        onDeleteNode: { _ in }
    )
    .modelContainer(container)
}
