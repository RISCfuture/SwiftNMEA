actor MessageParser {
  private let formatParsers: [MessageFormat] = [
    AAMParser(), ABKParser(), ABMParser(), ACAParser(), ACKParser(),
    ACSParser(), AIRParser(), AKDParser(), ALAParser(), ALRParser(),
    APBParser(), BBMParser(), BDWaypointParser(), BODParser(),
    BWWParser(), CBRParser(), CURParser(), DBTParser(), DDCParser(),
    DORParser(), DPTParser(), DSCParser(), DSEParser(), DTMParser(),
    ETLParser(), EVEParser(), FIRParser(), FSIParser(), GBSParser(),
    GENParser(), GFAParser(), GGAParser(), GLLParser(), GNSParser(),
    GRSParser(), GSAParser(), GSTParser(), GSVParser(), HBTParser(),
    HDGParser(), HDTParser(), HMRParser(), HMSParser(), HSCParser(),
    HSSParser(), HTCParser(), HTDParser(), LRIParser(), LRFParser(),
    MEBParser(), MSKParser(), MSSParser(), MTWParser(), MWDParser(),
    MWVParser(), NAKParser(), NRMParser(), NRXParser(), OSDParser(),
    POSParser(), PRCParser(), RMAParser(), RMBParser(), RMCParser(),
    RORParser(), ROTParser(), RPMParser(), RSAParser(), RSDParser(),
    RTEParser(), SFIParser(), SSDParser(), STNParser(), THSParser(),
    TLBParser(), TLLParser(), TRCParser(), TRDParser(), TTDParser(),
    TTMParser(), TUTParser(), TXTParser(), UIDParser(), VBWParser(),
    VDMParser(), VDOParser(), VDRParser(), VERParser(), VHWParser(),
    VLWParser(), VPWParser(), VSDParser(), VTGParser(), WATParser(),
    WCVParser(), WNCParser(), WPLParser(), XDRParser(), XTEParser(),
    XTRParser(), ZDAParser(), ZDLParser(), ZFOParser(), ZTGParser()
  ]

  func parse(sentence: ParametricSentence) throws -> Message? {
    let parsers = try formatParsers.filter { try $0.canParse(sentence: sentence) }
    guard !parsers.isEmpty else { return nil }

    guard let payload = try parsers.lazy.compactMap({ try $0.parse(sentence: sentence) }).first
    else { return nil }
    return .init(talker: sentence.talker, format: sentence.format, payload: payload)
  }

  func flush(talker: Talker?, format: Format?, includeIncomplete: Bool) throws -> [any Element] {
    try formatParsers.flatMap {
      try $0.flush(talker: talker, format: format, includeIncomplete: includeIncomplete)
    }
  }
}
