//
//  Item.swift
//  ExMind
//
//  Created by gotree94 on 12/20/25.
//

import Foundation
import SwiftData
import SwiftUI

// 마인드맵 노드
@Model
final class MindMapNode {
    var id: UUID
    var title: String
    var notes: String
    var createdAt: Date
    var modifiedAt: Date
    
    // 위치 정보 (시각적 마인드맵용)
    var positionX: Double
    var positionY: Double
    
    // 색상
    var colorHex: String
    
    // 연결점 설정 (부모로부터의 연결)
    var anchorPoint: String // "top", "bottom", "left", "right", "auto"
    
    // 계층 구조
    var parent: MindMapNode?
    @Relationship(deleteRule: .cascade, inverse: \MindMapNode.parent)
    var children: [MindMapNode]
    
    // 엑셀 스타일 속성들
    @Relationship(deleteRule: .cascade)
    var properties: [NodeProperty]
    
    init(title: String, positionX: Double = 0, positionY: Double = 0, colorHex: String = "007AFF", anchorPoint: String = "auto") {
        self.id = UUID()
        self.title = title
        self.notes = ""
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.positionX = positionX
        self.positionY = positionY
        self.colorHex = colorHex
        self.anchorPoint = anchorPoint
        self.children = []
        self.properties = []
    }
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
    
    // 연결점 계산 (노드 박스 크기 기준)
    func getAnchorPoint(boxWidth: CGFloat = 160, boxHeight: CGFloat = 70, relativeTo parent: MindMapNode?) -> CGPoint {
        let halfWidth = boxWidth / 2
        let halfHeight = boxHeight / 2
        
        // auto인 경우 부모 위치를 기준으로 자동 결정
        if anchorPoint == "auto", let parent = parent {
            let dx = positionX - parent.positionX
            let dy = positionY - parent.positionY
            
            // 각도에 따라 최적의 연결점 선택
            if abs(dx) > abs(dy) {
                // 좌우
                if dx > 0 {
                    return CGPoint(x: -halfWidth, y: 0) // left
                } else {
                    return CGPoint(x: halfWidth, y: 0) // right
                }
            } else {
                // 상하
                if dy > 0 {
                    return CGPoint(x: 0, y: -halfHeight) // top
                } else {
                    return CGPoint(x: 0, y: halfHeight) // bottom
                }
            }
        }
        
        // 수동 설정
        switch anchorPoint {
        case "top":
            return CGPoint(x: 0, y: -halfHeight)
        case "bottom":
            return CGPoint(x: 0, y: halfHeight)
        case "left":
            return CGPoint(x: -halfWidth, y: 0)
        case "right":
            return CGPoint(x: halfWidth, y: 0)
        default: // "auto"
            return CGPoint(x: -halfWidth, y: 0) // 기본값: 왼쪽
        }
    }
    
    // 부모로의 연결점 (출발점)
    func getParentAnchorPoint(boxWidth: CGFloat = 160, boxHeight: CGFloat = 70, child: MindMapNode) -> CGPoint {
        let halfWidth = boxWidth / 2
        let halfHeight = boxHeight / 2
        
        let dx = child.positionX - positionX
        let dy = child.positionY - positionY
        
        // 자식 방향에 따라 부모의 연결점 결정
        if abs(dx) > abs(dy) {
            if dx > 0 {
                return CGPoint(x: halfWidth, y: 0) // right
            } else {
                return CGPoint(x: -halfWidth, y: 0) // left
            }
        } else {
            if dy > 0 {
                return CGPoint(x: 0, y: halfHeight) // bottom
            } else {
                return CGPoint(x: 0, y: -halfHeight) // top
            }
        }
    }
}

// 노드의 속성 (엑셀 스타일)
@Model
final class NodeProperty {
    var id: UUID
    var key: String
    var value: String
    var propertyType: String // "text", "number", "date", "boolean"
    var order: Int
    
    init(key: String, value: String, propertyType: String = "text", order: Int = 0) {
        self.id = UUID()
        self.key = key
        self.value = value
        self.propertyType = propertyType
        self.order = order
    }
}

// 마인드맵 문서
@Model
final class MindMapDocument {
    var id: UUID
    var title: String
    var createdAt: Date
    var modifiedAt: Date
    
    @Relationship(deleteRule: .cascade)
    var rootNodes: [MindMapNode]
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.rootNodes = []
    }
}

// Color extension for hex support
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String? {
#if os(macOS)
        guard let components = NSColor(self).cgColor.components, components.count >= 3 else {
            return nil
        }
#else
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return nil
        }
#endif
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}

#if os(iOS)
import UIKit
#endif
