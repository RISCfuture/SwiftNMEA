import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftNMEA_MacrosPlugin: CompilerPlugin {
    package let providingMacros: [Macro.Type] = [
        DefineAlarmsMacro.self
    ]
}
