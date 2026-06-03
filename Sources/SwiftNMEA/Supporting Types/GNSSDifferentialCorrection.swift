import Foundation

extension GNSS {

  /**
   DGNSS differential correction data for a single satellite, as reported by
   the `GDC` sentence (IEC 61162-1 ed.6.0 8.3.39). Each `GDC` sentence carries
   the correction for exactly one satellite; a complete message reports the
   corrections for all satellites currently in use.

   - SeeAlso: ``Message/Payload-swift.enum/GNSSDifferentialCorrection(_:totalSatellites:)``
   */
  public struct DifferentialCorrection: Sendable, Codable, Equatable, Hashable {

    /// The satellite whose differential correction this is. The GNSS system is
    /// identified by the sentence's talker ID, the satellite by its ID number,
    /// and the observation type by the signal ID.
    public let satellite: SatelliteID

    /// DGNSS pseudorange correction, in metres. The signal ID of ``satellite``
    /// indicates the observation type (frequency, code range, or carrier
    /// phase).
    public let pseudorangeCorrection: Measurement<UnitLength>

    /// The Issue of DGNSS correction data. This is a unitless value. For BDS
    /// `B1I`/`B2I`/`B3I` it is `mod(toc / 720, 240)`; for BDS
    /// `B1C`/`B2a`/`B2b` it is the IODE.
    public let issueOfData: Int

    /// Epoch time of the GNSS, as a time-of-week (or, for GLONASS, a
    /// time-of-day). The starting epoch depends on the GNSS system, which is
    /// identified by ``satellite``.
    public let epochTime: Measurement<UnitDuration>

    /// Modified Z-Count, ranging from 0 s to 3 599,4 s.
    public let modifiedZCount: Measurement<UnitDuration>

    /// User differential range error (UDRE), ranging from 0 m to 150 m.
    public let UDRE: Measurement<UnitLength>

    /// Memberwise initializer.
    public init(
      satellite: SatelliteID,
      pseudorangeCorrection: Measurement<UnitLength>,
      issueOfData: Int,
      epochTime: Measurement<UnitDuration>,
      modifiedZCount: Measurement<UnitDuration>,
      UDRE: Measurement<UnitLength>
    ) {
      self.satellite = satellite
      self.pseudorangeCorrection = pseudorangeCorrection
      self.issueOfData = issueOfData
      self.epochTime = epochTime
      self.modifiedZCount = modifiedZCount
      self.UDRE = UDRE
    }
  }
}
