import Foundation
import MacroToolkit
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

package struct DefineAlarmsMacro: DeclarationMacro {
    package static func expansion(of node: some FreestandingMacroExpansionSyntax,
                                  in _: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard let (argument) = destructureSingle(node.arguments),
              let systemsExpr = argument.expression.as(ArrayExprSyntax.self) else {
            throw MacroError("@DefineAlarms takes a single argument of type [System]")
        }
        let systems = try systemsExprToValue(systemsExpr)
        return try alarmEnum(systems) + systemEnum(systems)
    }

    private static func systemsExprToValue(_ expr: ArrayExprSyntax) throws -> [System] {
        return try expr.elements.map { element in
            guard let tupleExpr = element.expression.as(TupleExprSyntax.self) else {
                throw MacroError("Invalid argument for @DefineAlarms (systemsExprToValue)")
            }
            return try .init(expr: tupleExpr)
        }
    }

    private static func alarmEnum(_ systems: [System]) throws -> [DeclSyntax] {
        let cases = systems.map(\.alarmEnumCaseSyntax),
            rawCases = systems.map(\.alarmEnumRawCaseSyntax),
            enums = try systems.flatMap { try $0.alarmEnumSyntax }

        return [
            DeclSyntax("""
                public enum Alarm: Sendable, Codable, Equatable {
                """)
        ] + cases + [
            DeclSyntax("""

                    init?(system: String, subsystem: String?, type: Int) {
                        switch system {
                """)
        ] + rawCases + [
            DeclSyntax("""

                            default: return nil
                        }
                    }

                """)
        ] + enums + [
            DeclSyntax("""

                }
                """)
        ]
    }

    private static func systemEnum(_ systems: [System]) throws -> [DeclSyntax] {
        let cases = systems.map(\.systemEnumCaseSyntax),
            rawCases = systems.map(\.systemEnumRawCaseSyntax),
            enums = try systems.flatMap { try $0.systemEnumSyntax }

        return [
            DeclSyntax("""
                public enum AlarmSystem: Sendable, Codable, Equatable {
                """)
        ] + cases + [
            DeclSyntax("""
                    init?(system: String, subsystem: String?) {
                        switch system {
                """)
        ] + rawCases + [
            DeclSyntax("""

                            default: return nil
                        }
                    }

                """)
        ] + enums + [
            DeclSyntax("""

                }
                """)
        ]
    }
}

struct Code: Identifiable, Equatable, Hashable {
    let name: String
    let id: IntegerLiteralExprSyntax

    var caseName: String { name }

    init(expr: DictionaryElementSyntax) throws {
        guard let nameExpr = expr.key.as(StringLiteralExprSyntax.self),
              let name = nameExpr.representedLiteralValue,
              let id = expr.value.as(IntegerLiteralExprSyntax.self) else {
            throw MacroError("Invalid argument for @DefineAlarms (codesExprToValue)")
        }

        self.name = name
        self.id = id
    }
}

struct Subsystem: Identifiable, Equatable, Hashable {
    let name: String
    let id: StringLiteralExprSyntax
    let codes: [Code]

    private var caseName: String { name }
    private var alarmEnumName: String { name.uppercasedFirstChar + "Alarm" }

    var alarmCaseSyntax: DeclSyntax {
        DeclSyntax("""
                    case \(raw: caseName)(type: \(raw: alarmEnumName)?)
            """)
    }

    var alarmRawCaseSyntax: DeclSyntax {
        DeclSyntax("""
                            case \(id): self = .\(raw: caseName)(type: .init(rawValue: type))
            """)
    }

    var systemCaseSyntax: DeclSyntax {
        DeclSyntax("""
                    case \(raw: caseName) = \(id)
            """)
    }

    var alarmSyntax: [DeclSyntax] {
        get throws {
            let initCases = codes.map { code in
                DeclSyntax("""

                                    case \(code.id): self = .\(raw: code.caseName)
                """)
            }
            let rawValueCases = codes.map { code in
                DeclSyntax("""

                                        case .\(raw: code.caseName): return \(code.id)
                    """)
            }
            let cases = codes.map { code in
                DeclSyntax("""
                        case \(raw: code.name)
            """)
            }

            return [
                DeclSyntax("""
                        public enum \(raw: alarmEnumName): Sendable, Codable, Equatable, RawRepresentable, Hashable {
                            public typealias RawValue = Int
                            private static let userDefinedRange = 900...999
                """)
            ] + cases + [
                DeclSyntax("""

                                        case userDefined(value: Int)

                                        public init?(rawValue: Int) {
                                            switch rawValue {
                            """)
            ] + initCases + [
                DeclSyntax("""
                                                case Self.userDefinedRange: self = .userDefined(value: rawValue)
                                                default: return nil
                                            }
                                        }

                                        public var rawValue: Int {
                                            switch self {
                            """)
            ] + rawValueCases + [
                DeclSyntax("""

                                    case let .userDefined(value): return value
                                }
                            }
                        }
                """)
            ]
        }
    }

    init(name: String, id: StringLiteralExprSyntax, codes: [Code]) {
        self.name = name
        self.id = id
        self.codes = codes
    }

    init(expr: TupleExprSyntax) throws {
        guard let nameExpr = expr.elements.first(where: { $0.label?.text == "name" })?.expression.as(StringLiteralExprSyntax.self),
              let name = nameExpr.representedLiteralValue,
              let id = expr.elements.first(where: { $0.label?.text == "id" })?.expression.as(StringLiteralExprSyntax.self),
              let codesExpr = expr.elements.first(where: { $0.label?.text == "codes" })?.expression.as(DictionaryExprSyntax.self) else {
            throw MacroError("Invalid argument for @DefineAlarms (subsystemsExprToValue)")
        }

        self.name = name
        self.id = id
        codes = switch codesExpr.content {
            case .colon: []
            case let .elements(elements): try elements.map { try Code(expr: $0) }
        }
    }
}

struct System: Identifiable, Equatable, Hashable {
    let name: String
    let id: StringLiteralExprSyntax
    let subsystems: [Subsystem]

    private var caseName: String { name }
    private var subsystemsEnumName: String { name.uppercasedFirstChar + "Subsystem" }
    private var alarmEnumName: String { name.uppercasedFirstChar + "Alarm" }

    private var noSubsystems: Bool {
        subsystems.count == 1 && subsystems.first!.name.isEmpty
    }

    private var pseudoSubsystemForAlarms: Subsystem? {
        guard noSubsystems, let subsystem = subsystems.first else { return nil }
        return .init(name: name, id: id, codes: subsystem.codes)
    }

    var alarmEnumCaseSyntax: DeclSyntax {
        if noSubsystems {
            DeclSyntax("""
                case \(raw: caseName)(type: \(raw: alarmEnumName))
            """)
        } else {
            DeclSyntax("""
                case \(raw: caseName)(subsystem: \(raw: subsystemsEnumName))
            """)
        }
    }

    var alarmEnumRawCaseSyntax: DeclSyntax {
        if noSubsystems {
            DeclSyntax("""
                        case \(id):
                            guard subsystem == nil, let alarm = \(raw: alarmEnumName)(rawValue: type) else {
                                return nil
                            }
                            self = .\(raw: caseName)(type: alarm)
            """)
        } else {
            DeclSyntax("""
                        case \(id):
                            if let subsystem = \(raw: subsystemsEnumName)(subsystem: subsystem, type: type) {
                                self = .\(raw: caseName)(subsystem: subsystem)
                            }
                            else { self = .\(raw: caseName)(subsystem: .none(code: type)) }
            """)
        }
    }

    var alarmEnumSyntax: [DeclSyntax] {
        get throws {
            if let subsystem = pseudoSubsystemForAlarms {
                return try subsystem.alarmSyntax
            }
            let cases = subsystems.map(\.alarmCaseSyntax),
                rawCases = subsystems.map(\.alarmRawCaseSyntax),
                alarmEnums = try subsystems.flatMap { try $0.alarmSyntax }

            return [
                DeclSyntax("""
                            public enum \(raw: subsystemsEnumName): Sendable, Codable, Equatable {
                        """)
            ] + cases + [
                DeclSyntax("""
                                init?(subsystem: String?, type: Int) {
                                    guard let subsystem else { return nil }
                                    switch subsystem {
                        """)
            ] + rawCases + [
                DeclSyntax("""

                                        default: return nil
                                    }
                                }

                        """)
            ] + alarmEnums + [
                DeclSyntax("""

                                case none(code: Int)
                            }
                        """)
            ]
        }
    }

    var systemEnumCaseSyntax: DeclSyntax {
        if noSubsystems {
            DeclSyntax("""

                    case \(raw: caseName)
                """)
        } else {
            DeclSyntax("""

                    case \(raw: caseName)(subsystem: \(raw: subsystemsEnumName)?)
                """)
        }
    }

    var systemEnumRawCaseSyntax: DeclSyntax {
        if noSubsystems {
            DeclSyntax("""
                        case \(id):
                            guard subsystem == nil else { return nil }
                            self = .\(raw: caseName)
            """)
        } else {
            DeclSyntax("""
                        case \(id):
                            if let subsystem {
                                if let subsystemEnum = \(raw: subsystemsEnumName)(rawValue: subsystem) {
                                    self = .\(raw: caseName)(subsystem: subsystemEnum)
                                } else { return nil }
                            }
                            else { self = .\(raw: caseName)(subsystem: nil) }
            """)
        }
    }

    var systemEnumSyntax: [DeclSyntax] {
        get throws {
            guard !noSubsystems else { return [] }
            let cases = subsystems.map(\.systemCaseSyntax)

            return [
                DeclSyntax("""
                public enum \(raw: subsystemsEnumName): String, Sendable, Codable, Equatable {
            """)
            ] + cases + [
                DeclSyntax("""

                }
            """)
            ]
        }
    }

    init(name: String, id: StringLiteralExprSyntax, subsystems: [Subsystem]) {
        self.name = name
        self.id = id
        self.subsystems = subsystems
    }

    init(expr: TupleExprSyntax) throws {
        guard let nameExpr = expr.elements.first(where: { $0.label?.text == "name" })?.expression.as(StringLiteralExprSyntax.self),
              let name = nameExpr.representedLiteralValue,
              let id = expr.elements.first(where: { $0.label?.text == "id" })?.expression.as(StringLiteralExprSyntax.self),
              let subsystemsExpr = expr.elements.first(where: { $0.label?.text == "subsystems" })?.expression.as(ArrayExprSyntax.self) else {
            throw MacroError("Invalid argument for @DefineAlarms (System.init)")
        }

        self.name = name
        self.id = id
        subsystems = try subsystemsExpr.elements.map { element in
            guard let tupleExpr = element.expression.as(TupleExprSyntax.self) else {
                throw MacroError("Invalid argument for @DefineAlarms (Subsystem.init)")
            }
            return try .init(expr: tupleExpr)
        }
    }
}
