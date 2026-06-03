/**
 Types describing return link messages (`RLM`) transferred from a return link
 service provider (RLSP) to a Cospas-Sarsat 406 MHz beacon by way of a return
 link service (RLS) compatible GNSS receiver.

 - SeeAlso: ``Message/Payload-swift.enum/returnLink(beacon:time:messageCode:messageBody:)``
 */
public enum ReturnLink {

  /**
   The type of return link message service identified by the `RLM` message
   code field.

   The default value is ``acknowledgement`` when the message code is not
   received.

   - SeeAlso: IEC 61162-1 ed.6.0 § 8.3.78
   */
  public enum MessageCode: Character, Sendable, Codable, Equatable {

    /// Reserved for future RLM services
    case reserved0 = "0"

    /// Acknowledgement service RLM (default value if message code not received)
    case acknowledgement = "1"

    /// Command service RLM
    case command = "2"

    /// Message service RLM
    case message = "3"

    /// Test service RLM (currently used only by the Galileo program)
    case test = "F"
  }
}
