import Foundation
import NMEACommon
import NMEAUnits

let lengthUnits: [String: UnitLength] = [
  "M": .meters,
  "N": .nauticalMiles,
  "F": .fathoms,
  "I": .inches,
  "K": .kilometers,
  "S": .miles,
  "f": .feet
]

let currentUnits: [String: UnitElectricCurrent] = [
  "A": .amperes
]

let potentialUnits: [String: UnitElectricPotentialDifference] = [
  "V": .volts
]

let pressureUnits: [String: UnitPressure] = [
  "B": .bars,
  "P": .pascals
]

let temperatureUnits: [String: UnitTemperature] = [
  "C": .celsius,
  "F": .fahrenheit
]

let angleUnits: [String: UnitAngle] = [
  "D": .degrees
]

let frequencyUnits: [String: UnitFrequency] = [
  "H": .hertz
]

let speedUnits: [String: UnitSpeed] = [
  "K": .kilometersPerHour,
  "M": .metersPerSecond,
  "N": .knots,
  "S": .milesPerHour
]

let densityUnits: [String: UnitDensity] = [
  "K": .kilogramsPerCubicMeter
]

let massUnits: [String: UnitMass] = [
  "k": .kilograms
]

let durationUnits: [String: UnitDuration] = [
  "h": .hours,
  "m": .minutes,
  "s": .seconds
]

let volumeUnits: [String: UnitVolume] = [
  "l": .liters,
  "M": .cubicMeters
]

let flowUnits: [String: UnitFlow] = [
  "l": .litersPerSecond
]

let forceUnits: [String: UnitForce] = [
  "N": .newtons
]

let angularVelocityUnits: [String: UnitAngularVelocity] = [
  "R": .revolutionsPerMinute
]

let dispersionUnits: [String: UnitDispersion] = [
  "S": .partsPerThousand
]
