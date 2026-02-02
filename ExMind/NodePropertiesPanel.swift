//
//  NodePropertiesPanel.swift
//  ExMind
//
//  Created by gotree94 on 12/20/25.
//

import SwiftUI
import SwiftData

struct NodePropertiesPanel: View {
    @Bindable var node: MindMapNode
    let onDelete: () -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddProperty = false
    @State private var newPropertyKey = ""
    @State private var newPropertyType = "text"
    @State private var expandedSections: Set<String> = ["basic", "custom"]
    
    let propertyTypes = ["text", "number", "date", "boolean"]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // 왼쪽 패널: 기본 정보 (50%)
                VStack(alignment: .leading, spacing: 8) {
                    // 헤더
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .font(.caption)
                        Text("Basic")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    
                    Divider()
                    
                    // 컴팩트한 기본 정보
                    GeometryReader { innerGeometry in
                        let availableWidth = innerGeometry.size.width - 16 // 패딩 제외
                        let colorPickerHeight = CompactColorPicker.calculateHeight(availableWidth: availableWidth)
                        
                        VStack(spacing: 6) {
                            CompactPropertyRow(label: "Title", icon: "textformat") {
                                TextField("Title", text: $node.title)
                                    .textFieldStyle(.roundedBorder)
#if os(macOS)
                                    .controlSize(.small)
#endif
                            }
                            
                            CompactPropertyRow(label: "Notes", icon: "note.text") {
                                TextField("Formula or text", text: $node.notes)
                                    .textFieldStyle(.roundedBorder)
#if os(macOS)
                                    .controlSize(.small)
#endif
                            }
                            
                            CompactPropertyRow(label: "Color", icon: "paintpalette") {
                                CompactColorPicker(colorHex: $node.colorHex)
                                    .frame(height: colorPickerHeight)
                            }
                            
                            CompactPropertyRow(label: "Anchor", icon: "point.3.connected.trianglepath.dotted") {
                                Picker("", selection: $node.anchorPoint) {
                                    Text("Auto").tag("auto")
                                    Text("↑").tag("top")
                                    Text("↓").tag("bottom")
                                    Text("←").tag("left")
                                    Text("→").tag("right")
                                }
                                .pickerStyle(.menu)
#if os(macOS)
                                .controlSize(.small)
#endif
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                    }
                }
                .frame(width: (geometry.size.width - 80 - 2) * 0.5) // 50% (액션 버튼 폭 제외)
#if os(macOS)
                .background(Color(nsColor: .controlBackgroundColor))
#else
                .background(Color(uiColor: .secondarySystemBackground))
#endif
                
                Divider()
                
                // 중앙 패널: 커스텀 속성들 (50%)
                VStack(alignment: .leading, spacing: 8) {
                    // 헤더
                    HStack {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.caption)
                        Text("Custom Properties")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Spacer()
                        Button(action: { showingAddProperty = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    
                    Divider()
                    
                    // 커스텀 속성 목록 (2열 그리드)
                    if node.properties.isEmpty {
                        VStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "tray")
                                    .font(.title2)
                                    .foregroundStyle(.tertiary)
                                Text("No custom properties")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Button("Add Property") {
                                    showingAddProperty = true
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8)
                            ], spacing: 8) {
                                ForEach(node.properties.sorted(by: { $0.order < $1.order })) { property in
                                    CompactCustomPropertyCard(property: property) {
                                        deleteProperty(property)
                                    }
                                }
                            }
                            .padding(8)
                        }
                    }
                }
                .frame(width: (geometry.size.width - 80 - 2) * 0.5) // 50% (액션 버튼 폭 제외)
#if os(macOS)
                .background(Color(nsColor: .windowBackgroundColor))
#else
                .background(Color(uiColor: .systemBackground))
#endif
                
                Divider()
                
                // 오른쪽 패널: 액션 버튼
                VStack(spacing: 8) {
                    Spacer()
                    
                    Button(action: onDelete) {
                        VStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.title3)
                            Text("Delete")
                                .font(.caption2)
                        }
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    
                    Spacer()
                }
                .frame(width: 80)
                .padding(8)
#if os(macOS)
                .background(Color(nsColor: .controlBackgroundColor))
#else
                .background(Color(uiColor: .secondarySystemBackground))
#endif
            }
        }
        .sheet(isPresented: $showingAddProperty) {
            AddPropertySheet(
                propertyKey: $newPropertyKey,
                propertyType: $newPropertyType,
                propertyTypes: propertyTypes,
                onAdd: addProperty,
                onCancel: { showingAddProperty = false }
            )
        }
    }
    
    private func addProperty() {
        guard !newPropertyKey.isEmpty else { return }
        
        let property = NodeProperty(
            key: newPropertyKey,
            value: "",
            propertyType: newPropertyType,
            order: node.properties.count
        )
        modelContext.insert(property)
        node.properties.append(property)
        
        newPropertyKey = ""
        newPropertyType = "text"
        showingAddProperty = false
        node.modifiedAt = Date()
    }
    
    private func deleteProperty(_ property: NodeProperty) {
        withAnimation {
            if let index = node.properties.firstIndex(where: { $0.id == property.id }) {
                node.properties.remove(at: index)
            }
            modelContext.delete(property)
            node.modifiedAt = Date()
        }
    }
}

// 컴팩트 속성 행 (레이블 + 값을 한 줄에)
struct CompactPropertyRow<Content: View>: View {
    let label: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 12)
                
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 50, alignment: .leading)
            }
            
            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// 컴팩트 색상 피커
struct CompactColorPicker: View {
    @Binding var colorHex: String
    
    // 6개씩 묶음으로 구성 (5개 그룹 = 30색상)
    let colorGroups: [[String]] = [
        // 그룹 1: 기본 시스템 색상
        ["007AFF", "5856D6", "AF52DE", "FF2D55", "FF3B30", "FF9500"],
        // 그룹 2: 밝은 색상
        ["FFCC00", "34C759", "00C7BE", "30B0C7", "FF6482", "FF8C42"],
        // 그룹 3: 파스텔 톤
        ["A8E6CF", "FFD3B6", "FFAAA5", "C7CEEA", "E6B8AF", "B4A7D6"],
        // 그룹 4: 중간 톤
        ["2E86AB", "A23B72", "F18F01", "C73E1D", "6A994E", "BC4B51"],
        // 그룹 5: 어두운 톤 + 흰색/회색
        ["1B263B", "415A77", "778DA9", "E0E1DD", "FFFFFF", "D3D3D3"]
    ]
    
    // 색상 크기 상수
    private static let colorSize: CGFloat = 16
    private static let colorSpacing: CGFloat = 3
    private static let groupSpacing: CGFloat = 8
    private static let rowSpacing: CGFloat = 6
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let groupsPerRow = Self.calculateGroupsPerRow(width: availableWidth)
            let shouldScroll = groupsPerRow == 0
            
            if shouldScroll {
                // 공간이 부족하면 가로 스크롤
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Self.groupSpacing) {
                        ForEach(colorGroups.indices, id: \.self) { groupIndex in
                            ColorGroupView(
                                colors: colorGroups[groupIndex],
                                selectedColor: $colorHex,
                                colorSize: Self.colorSize,
                                colorSpacing: Self.colorSpacing
                            )
                        }
                    }
                }
                .frame(height: Self.colorSize)
            } else {
                // 여러 그룹이 보이면 그리드로 표시
                let rows = createRows(groupsPerRow: groupsPerRow)
                VStack(alignment: .leading, spacing: Self.rowSpacing) {
                    ForEach(rows.indices, id: \.self) { rowIndex in
                        HStack(spacing: Self.groupSpacing) {
                            ForEach(rows[rowIndex], id: \.self) { groupIndex in
                                ColorGroupView(
                                    colors: colorGroups[groupIndex],
                                    selectedColor: $colorHex,
                                    colorSize: Self.colorSize,
                                    colorSpacing: Self.colorSpacing
                                )
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .frame(height: Self.calculateHeight(availableWidth: 0)) // 기본 높이 설정
    }
    
    // 정적 메서드: 주어진 너비에서 색상 피커의 높이를 계산
    static func calculateHeight(availableWidth: CGFloat) -> CGFloat {
        let groupsPerRow = calculateGroupsPerRow(width: availableWidth)
        
        if groupsPerRow == 0 {
            // 스크롤 모드: 단일 줄
            return colorSize
        } else {
            // 그리드 모드: 총 5개 그룹을 몇 줄로 배치하는지 계산
            let totalGroups = 5
            let numberOfRows = Int(ceil(Double(totalGroups) / Double(groupsPerRow)))
            
            // 높이 = (색상 크기 × 행 수) + (행 간격 × (행 수 - 1))
            return (colorSize * CGFloat(numberOfRows)) + (rowSpacing * CGFloat(max(0, numberOfRows - 1)))
        }
    }
    
    private static func calculateGroupsPerRow(width: CGFloat) -> Int {
        // 각 그룹의 실제 너비 계산
        // 그룹 너비 = (색상 크기 × 6) + (색상 간격 × 5)
        let groupWidth = (colorSize * 6) + (colorSpacing * 5)
        
        // 1개 그룹도 들어가지 않으면 0 반환 (스크롤 모드)
        guard width >= groupWidth else {
            return 0
        }
        
        // 최대 몇 개의 그룹이 들어갈 수 있는지 계산
        var maxGroups = 1
        var requiredWidth = groupWidth
        
        // 총 5개 그룹까지 시도
        for i in 2...5 {
            requiredWidth = (groupWidth * CGFloat(i)) + (groupSpacing * CGFloat(i - 1))
            if requiredWidth <= width {
                maxGroups = i
            } else {
                break
            }
        }
        
        return maxGroups
    }
    
    private func createRows(groupsPerRow: Int) -> [[Int]] {
        var rows: [[Int]] = []
        var currentRow: [Int] = []
        
        for index in colorGroups.indices {
            currentRow.append(index)
            if currentRow.count == groupsPerRow {
                rows.append(currentRow)
                currentRow = []
            }
        }
        
        if !currentRow.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
}

// 색상 그룹 뷰 (6개 색상을 한 줄로)
struct ColorGroupView: View {
    let colors: [String]
    @Binding var selectedColor: String
    let colorSize: CGFloat
    let colorSpacing: CGFloat
    
    var body: some View {
        HStack(spacing: colorSpacing) {
            ForEach(colors, id: \.self) { hex in
                Button(action: { selectedColor = hex }) {
                    Circle()
                        .fill(Color(hex: hex) ?? .blue)
                        .frame(width: colorSize, height: colorSize)
                        .overlay(
                            Circle()
                                .stroke(selectedColor == hex ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: selectedColor == hex ? 2 : 0.5)
                        )
                        .overlay(
                            // 흰색/밝은 색상은 테두리 표시
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: (hex == "FFFFFF" || hex == "E0E1DD" || hex == "D3D3D3") ? 1 : 0)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// 컴팩트 커스텀 속성 카드
struct CompactCustomPropertyCard: View {
    @Bindable var property: NodeProperty
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(property.key)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(property.propertyType)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            PropertyValueEditor(property: property)
        }
        .padding(8)
#if os(macOS)
        .background(Color(nsColor: .controlBackgroundColor))
#else
        .background(Color(uiColor: .secondarySystemBackground))
#endif
        .cornerRadius(6)
    }
}

// 속성 행
struct PropertyRow<Content: View>: View {
    let label: String
    let systemImage: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
            content
        }
    }
}

// 커스텀 속성 행
struct CustomPropertyRow: View {
    @Bindable var property: NodeProperty
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(property.key)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("(\(property.propertyType))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Capsule())
                }
                
                PropertyValueEditor(property: property)
            }
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
        }
    }
}

// 속성 값 에디터
struct PropertyValueEditor: View {
    @Bindable var property: NodeProperty
    
    var body: some View {
        switch property.propertyType {
        case "number":
            TextField("Value", text: $property.value)
                .textFieldStyle(.roundedBorder)
#if os(iOS)
                .keyboardType(.decimalPad)
#endif
                
        case "date":
            DatePicker(
                "",
                selection: Binding(
                    get: {
                        ISO8601DateFormatter().date(from: property.value) ?? Date()
                    },
                    set: { newDate in
                        property.value = ISO8601DateFormatter().string(from: newDate)
                    }
                ),
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            
        case "boolean":
            Toggle(
                "",
                isOn: Binding(
                    get: { property.value.lowercased() == "true" },
                    set: { property.value = $0 ? "true" : "false" }
                )
            )
            .labelsHidden()
            
        default: // text
            TextField("Value", text: $property.value)
                .textFieldStyle(.roundedBorder)
        }
    }
}

// 색상 피커
struct ColorPickerView: View {
    @Binding var colorHex: String
    
    // 확장된 색상 팔레트 (5줄 × 6열 = 30색상)
    let presetColors = [
        // 1줄: 기본 시스템 색상
        ["007AFF", "5856D6", "AF52DE", "FF2D55", "FF3B30", "FF9500"],
        // 2줄: 밝은 색상
        ["FFCC00", "34C759", "00C7BE", "30B0C7", "FF6482", "FF8C42"],
        // 3줄: 파스텔 톤
        ["A8E6CF", "FFD3B6", "FFAAA5", "C7CEEA", "E6B8AF", "B4A7D6"],
        // 4줄: 중간 톤
        ["2E86AB", "A23B72", "F18F01", "C73E1D", "6A994E", "BC4B51"],
        // 5줄: 어두운 톤 + 흰색/회색
        ["1B263B", "415A77", "778DA9", "E0E1DD", "FFFFFF", "D3D3D3"]
    ]
    
    var body: some View {
        VStack(spacing: 6) {
            ForEach(presetColors.indices, id: \.self) { rowIndex in
                HStack(spacing: 6) {
                    ForEach(presetColors[rowIndex], id: \.self) { hex in
                        Button(action: { colorHex = hex }) {
                            Circle()
                                .fill(Color(hex: hex) ?? .blue)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(colorHex == hex ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: colorHex == hex ? 2.5 : 0.5)
                                )
                                .overlay(
                                    // 흰색/밝은 색상은 추가 테두리 표시
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: (hex == "FFFFFF" || hex == "E0E1DD" || hex == "D3D3D3") ? 1 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// 연결점 피커
struct AnchorPointPicker: View {
    @Binding var anchorPoint: String
    
    let anchorPoints = [
        ("auto", "Auto", "circle.grid.cross"),
        ("top", "Top", "arrow.up.square"),
        ("bottom", "Bottom", "arrow.down.square"),
        ("left", "Left", "arrow.left.square"),
        ("right", "Right", "arrow.right.square")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 시각적 선택기
            HStack(spacing: 12) {
                ForEach(anchorPoints, id: \.0) { point in
                    VStack(spacing: 4) {
                        Button(action: { anchorPoint = point.0 }) {
                            Image(systemName: point.2)
                                .font(.title3)
                                .frame(width: 40, height: 40)
                                .background(anchorPoint == point.0 ? Color.accentColor : Color.gray.opacity(0.2))
                                .foregroundStyle(anchorPoint == point.0 ? .white : .primary)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        
                        Text(point.1)
                            .font(.caption2)
                            .foregroundStyle(anchorPoint == point.0 ? .primary : .secondary)
                    }
                }
            }
            
            Text("Select where the connection line enters this node from its parent")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// 속성 추가 시트
struct AddPropertySheet: View {
    @Binding var propertyKey: String
    @Binding var propertyType: String
    let propertyTypes: [String]
    let onAdd: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Custom Property")
                .font(.headline)
            
            TextField("Property Name", text: $propertyKey)
                .textFieldStyle(.roundedBorder)
            
            Picker("Type", selection: $propertyType) {
                ForEach(propertyTypes, id: \.self) { type in
                    Text(type.capitalized).tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                
                Button("Add", action: onAdd)
                    .keyboardShortcut(.defaultAction)
                    .disabled(propertyKey.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MindMapNode.self, configurations: config)
    
    let node = MindMapNode(title: "Sample Node", positionX: 0, positionY: 0)
    let property1 = NodeProperty(key: "Priority", value: "High", propertyType: "text", order: 0)
    let property2 = NodeProperty(key: "Progress", value: "75", propertyType: "number", order: 1)
    
    container.mainContext.insert(node)
    container.mainContext.insert(property1)
    container.mainContext.insert(property2)
    
    node.properties.append(property1)
    node.properties.append(property2)
    
    return NodePropertiesPanel(node: node, onDelete: {})
        .modelContainer(container)
        .frame(height: 300)
}
