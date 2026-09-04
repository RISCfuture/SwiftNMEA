import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SwiftNMEA_MacrosPlugin: CompilerPlugin {
  package let providingMacros: [any Macro.Type] = [
    DefineAlarmsMacro.self
  ]
}
