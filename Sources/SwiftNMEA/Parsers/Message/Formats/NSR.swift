import Foundation

class NSRParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .navigationStatusReport
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let headingIntegrity = try sentence.fields.enumeration(
      at: 0,
      ofType: NavigationStatus.Integrity.self
    )!
    let headingPlausibility = try sentence.fields.enumeration(
      at: 1,
      ofType: NavigationStatus.Plausibility.self
    )!
    let positionIntegrity = try sentence.fields.enumeration(
      at: 2,
      ofType: NavigationStatus.Integrity.self
    )!
    let positionPlausibility = try sentence.fields.enumeration(
      at: 3,
      ofType: NavigationStatus.Plausibility.self
    )!
    let STWIntegrity = try sentence.fields.enumeration(
      at: 4,
      ofType: NavigationStatus.Integrity.self
    )!
    let STWPlausibility = try sentence.fields.enumeration(
      at: 5,
      ofType: NavigationStatus.Plausibility.self
    )!
    let SOGCOGIntegrity = try sentence.fields.enumeration(
      at: 6,
      ofType: NavigationStatus.Integrity.self
    )!
    let SOGCOGPlausibility = try sentence.fields.enumeration(
      at: 7,
      ofType: NavigationStatus.Plausibility.self
    )!
    let depthIntegrity = try sentence.fields.enumeration(
      at: 8,
      ofType: NavigationStatus.Integrity.self
    )!
    let depthPlausibility = try sentence.fields.enumeration(
      at: 9,
      ofType: NavigationStatus.Plausibility.self
    )!
    let STWMode = try sentence.fields.enumeration(at: 10, ofType: NavigationStatus.STWMode.self)!
    let timeIntegrity = try sentence.fields.enumeration(
      at: 11,
      ofType: NavigationStatus.Integrity.self
    )!
    let timePlausibility = try sentence.fields.enumeration(
      at: 12,
      ofType: NavigationStatus.Plausibility.self
    )!

    return .navigationStatusReport(
      headingIntegrity: headingIntegrity,
      headingPlausibility: headingPlausibility,
      positionIntegrity: positionIntegrity,
      positionPlausibility: positionPlausibility,
      STWIntegrity: STWIntegrity,
      STWPlausibility: STWPlausibility,
      SOGCOGIntegrity: SOGCOGIntegrity,
      SOGCOGPlausibility: SOGCOGPlausibility,
      depthIntegrity: depthIntegrity,
      depthPlausibility: depthPlausibility,
      STWMode: STWMode,
      timeIntegrity: timeIntegrity,
      timePlausibility: timePlausibility
    )
  }
}
