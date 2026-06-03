actor MessageParser {
  private let formatParsers: [MessageFormat] = [
    AAMParser(), ABKParser(), ABMParser(), ACAParser(), ACKParser(),
    ACNParser(), ACSParser(), AGLParser(), AIRParser(), AKDParser(),
    ALAParser(), ALCParser(), ALFParser(), ALRParser(), APBParser(),
    ARCParser(), BBMParser(), BDWaypointParser(), BODParser(),
    BWWParser(), CBRParser(), CURParser(), DBTParser(), DDCParser(),
    DORParser(), DPTParser(), DSCParser(), DSEParser(), DTMParser(),
    EPMParser(), EPVParser(), ETLParser(), EVEParser(), FIRParser(),
    FSIParser(), GBSParser(), GDCParser(), GENParser(), GFAParser(),
    GGAParser(), GLLParser(), GNSParser(), GRSParser(), GSAParser(),
    GSTParser(), GSVParser(), HBTParser(), HCRParser(), HDGParser(),
    HDTParser(), HMRParser(), HMSParser(), HRMParser(), HSCParser(),
    HSSParser(), HTCParser(), HTDParser(), LRIParser(), LRFParser(),
    MEBParser(), MOBParser(), MSKParser(), MSSParser(), MTWParser(),
    MWDParser(), MWVParser(), NAKParser(), NLSParser(), NRMParser(),
    NRXParser(), NSRParser(), OSDParser(), POSParser(), PRCParser(),
    RLMParser(), RMAParser(), RMBParser(), RMCParser(), RORParser(),
    ROTParser(), RPMParser(), RRTParser(), RSAParser(), RSDParser(),
    RTEParser(), SELParser(), SFIParser(), SLMParser(), SM1Parser(),
    SM2Parser(), SM3Parser(), SM4Parser(), SMBParser(), SMVParser(),
    SPWParser(), SSDParser(), STNParser(), THSParser(), TLBParser(),
    TLLParser(), TRCParser(), TRDParser(), TRLParser(), TTDParser(),
    TTMParser(), TUTParser(), TXTParser(), UIDParser(), VBCParser(),
    VBWParser(), VDMParser(), VDOParser(), VDRParser(), VERParser(),
    VHWParser(), VLWParser(), VPWParser(), VSDParser(), VTGParser(),
    WATParser(), WCVParser(), WNCParser(), WPLParser(), XDRParser(),
    XTEParser(), XTRParser(), ZDAParser(), ZDLParser(), ZFOParser(),
    ZTGParser()
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
