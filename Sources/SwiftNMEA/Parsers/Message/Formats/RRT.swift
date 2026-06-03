import Foundation

class RRTParser: MessageFormat {
  func canParse(sentence: ParametricSentence) throws -> Bool {
    sentence.delimiter == .parametric && sentence.format == .routeTransferReport
  }

  func parse(sentence: ParametricSentence) throws -> Message.Payload? {
    let transferType = try sentence.fields.enumeration(
      at: 0,
      ofType: RouteTransfer.TransferType.self
    )!
    let name = try sentence.fields.string(at: 1, optional: true)
    let version = try sentence.fields.string(at: 2, optional: true)
    let currentWaypoint = try sentence.fields.string(at: 3, optional: true)
    let fileTransferStatus = try sentence.fields.enumeration(
      at: 4,
      ofType: RouteTransfer.FileStatus.self,
      optional: true
    )
    let applicationStatus = try sentence.fields.enumeration(
      at: 5,
      ofType: RouteTransfer.ApplicationStatus.self,
      optional: true
    )

    return .routeTransferReport(
      transferType: transferType,
      name: name,
      version: version,
      currentWaypoint: currentWaypoint,
      fileStatus: fileTransferStatus,
      applicationStatus: applicationStatus
    )
  }
}
