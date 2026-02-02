//
//  FormulaEngine.swift
//  ExMind
//
//  Created by gotree94 on 12/20/25.
//

import Foundation

// 수식 계산 결과
enum FormulaResult {
    case number(Double)
    case error(String)
    
    var displayValue: String {
        switch self {
        case .number(let value):
            // 정수면 소수점 없이 표시
            if value.truncatingRemainder(dividingBy: 1) == 0 {
                return String(Int(value))
            }
            return String(format: "%.2f", value)
        case .error(let formula):
            return formula
        }
    }
    
    var isError: Bool {
        if case .error = self {
            return true
        }
        return false
    }
}

// 수식 계산 엔진
class FormulaEngine {
    private var context: [String: Double] = [:]
    
    // 컨텍스트 설정 (다른 노드들의 값)
    func setContext(_ context: [String: Double]) {
        self.context = context
    }
    
    // 수식 평가
    func evaluate(_ input: String) -> FormulaResult {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        
        // 빈 문자열
        if trimmed.isEmpty {
            return .number(0)
        }
        
        // 숫자인 경우
        if let number = Double(trimmed) {
            return .number(number)
        }
        
        // 수식인 경우 (=로 시작하거나 연산자 포함)
        if trimmed.hasPrefix("=") || containsOperator(trimmed) {
            let formula = trimmed.hasPrefix("=") ? String(trimmed.dropFirst()) : trimmed
            return evaluateFormula(formula)
        }
        
        // 단순 텍스트 (에러)
        return .error(trimmed)
    }
    
    // 연산자 포함 여부 확인
    private func containsOperator(_ text: String) -> Bool {
        let operators = ["+", "-", "*", "/", "(", ")"]
        return operators.contains { text.contains($0) }
    }
    
    // 수식 계산
    private func evaluateFormula(_ formula: String) -> FormulaResult {
        do {
            let tokens = try tokenize(formula)
            let result = try evaluateExpression(tokens)
            return .number(result)
        } catch {
            return .error(formula)
        }
    }
    
    // 토큰화
    private func tokenize(_ formula: String) throws -> [Token] {
        var tokens: [Token] = []
        var current = ""
        
        for char in formula {
            if char.isWhitespace {
                if !current.isEmpty {
                    tokens.append(try parseToken(current))
                    current = ""
                }
            } else if "+-*/()".contains(char) {
                if !current.isEmpty {
                    tokens.append(try parseToken(current))
                    current = ""
                }
                tokens.append(.op(String(char)))
            } else {
                current.append(char)
            }
        }
        
        if !current.isEmpty {
            tokens.append(try parseToken(current))
        }
        
        return tokens
    }
    
    // 토큰 파싱
    private func parseToken(_ text: String) throws -> Token {
        if let number = Double(text) {
            return .number(number)
        } else {
            return .variable(text)
        }
    }
    
    // 수식 평가
    private func evaluateExpression(_ tokens: [Token]) throws -> Double {
        var index = 0
        return try parseExpression(tokens, &index)
    }
    
    // 표현식 파싱 (덧셈, 뺄셈)
    private func parseExpression(_ tokens: [Token], _ index: inout Int) throws -> Double {
        var result = try parseTerm(tokens, &index)
        
        while index < tokens.count {
            guard case .op(let op) = tokens[index], op == "+" || op == "-" else {
                break
            }
            index += 1
            let right = try parseTerm(tokens, &index)
            result = op == "+" ? result + right : result - right
        }
        
        return result
    }
    
    // 항 파싱 (곱셈, 나눗셈)
    private func parseTerm(_ tokens: [Token], _ index: inout Int) throws -> Double {
        var result = try parseFactor(tokens, &index)
        
        while index < tokens.count {
            guard case .op(let op) = tokens[index], op == "*" || op == "/" else {
                break
            }
            index += 1
            let right = try parseFactor(tokens, &index)
            if op == "/" && right == 0 {
                throw FormulaError.divisionByZero
            }
            result = op == "*" ? result * right : result / right
        }
        
        return result
    }
    
    // 인수 파싱 (숫자, 변수, 괄호)
    private func parseFactor(_ tokens: [Token], _ index: inout Int) throws -> Double {
        guard index < tokens.count else {
            throw FormulaError.invalidSyntax
        }
        
        let token = tokens[index]
        index += 1
        
        switch token {
        case .number(let value):
            return value
            
        case .variable(let name):
            guard let value = context[name] else {
                throw FormulaError.undefinedVariable(name)
            }
            return value
            
        case .op(let operatorString):
            if operatorString == "(" {
                let result = try parseExpression(tokens, &index)
                guard index < tokens.count, case .op(let closeParen) = tokens[index], closeParen == ")" else {
                    throw FormulaError.unmatchedParenthesis
                }
                index += 1
                return result
            } else if operatorString == "-" {
                // 단항 마이너스
                let value = try parseFactor(tokens, &index)
                return -value
            } else if operatorString == "+" {
                // 단항 플러스
                return try parseFactor(tokens, &index)
            } else {
                throw FormulaError.invalidSyntax
            }
        }
    }
}

// 토큰 타입
private enum Token {
    case number(Double)
    case variable(String)
    case op(String)  // operator 대신 op 사용
}

// 수식 에러
private enum FormulaError: Error {
    case invalidSyntax
    case undefinedVariable(String)
    case divisionByZero
    case unmatchedParenthesis
}

// MindMapNode 확장
extension MindMapNode {
    // 노트 값을 계산된 결과로 반환
    func evaluateNotes(with allNodes: [MindMapNode]) -> FormulaResult {
        // 컨텍스트 생성 (다른 노드들의 값)
        var context: [String: Double] = [:]
        
        func buildContext(_ nodes: [MindMapNode]) {
            for node in nodes {
                let result = node.evaluateNotesRecursive(with: context)
                if case .number(let value) = result {
                    context[node.title] = value
                }
                buildContext(node.children)
            }
        }
        
        buildContext(allNodes)
        
        // 자신의 노트 평가
        let engine = FormulaEngine()
        engine.setContext(context)
        return engine.evaluate(notes)
    }
    
    // 재귀적으로 평가 (순환 참조 방지)
    private func evaluateNotesRecursive(with context: [String: Double]) -> FormulaResult {
        let engine = FormulaEngine()
        engine.setContext(context)
        return engine.evaluate(notes)
    }
}
