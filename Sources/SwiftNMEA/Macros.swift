typealias Subsystem = (name: String?, id: String?, codes: [String: Int])
typealias System = (name: String, id: String, subsystems: [Subsystem])

@freestanding(declaration, names: named(Alarm), named(AlarmSystem))
macro defineAlarms(_ systems: [System]) = #externalMacro(module: "SwiftNMEA_Macros", type: "DefineAlarmsMacro")
