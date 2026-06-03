/**
 Types associated with the transfer of a route between devices, as reported by
 the `RRT` sentence.

 - SeeAlso: ``Message/Payload-swift.enum/routeTransferReport(transferType:name:version:currentWaypoint:fileStatus:applicationStatus:)``
 */
public struct RouteTransfer {
  private init() {}

  /**
   The reported type of a transferred route.

   - SeeAlso: ``Message/Payload-swift.enum/routeTransferReport(transferType:name:version:currentWaypoint:fileStatus:applicationStatus:)``
   */
  public enum TransferType: Character, Sendable, Codable, Equatable {

    /// Monitored route
    case monitored = "M"

    /// Alternate route for editing
    case alternate = "A"

    /// Query for transmitting any monitored or alternative route for editing
    case query = "Q"
  }

  /**
   The status of a route file transfer, used when reporting the reception
   status of a route.

   - SeeAlso: ``Message/Payload-swift.enum/routeTransferReport(transferType:name:version:currentWaypoint:fileStatus:applicationStatus:)``
   */
  public enum FileStatus: Character, Sendable, Codable, Equatable {

    /// Successful reception of the route file transfer
    case success = "A"

    /// Error in reception of the route file transfer
    case error = "E"
  }

  /**
   The status of the intended application of a transferred route, used when
   reporting the reception status of a route.

   - SeeAlso: ``Message/Payload-swift.enum/routeTransferReport(transferType:name:version:currentWaypoint:fileStatus:applicationStatus:)``
   */
  public enum ApplicationStatus: Character, Sendable, Codable, Equatable {

    /// Content of the received route accepted and valid
    case accepted = "A"

    /// Content of received route rejected
    case rejected = "V"

    /// Pending: the application level has not yet evaluated the received route
    case pending = "P"

    /// Not applicable. Used when reporting the reception status and when the
    /// ``RouteTransfer/FileStatus`` of the transferred route indicated an
    /// ``RouteTransfer/FileStatus/error`` in the reception of the route file
    /// transfer.
    case notApplicable = "N"
  }
}
