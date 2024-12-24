import Foundation

class ACAParser: MessageFormat {
    func canParse(sentence: ParametricSentence) throws -> Bool {
        sentence.delimiter == .parametric && sentence.format == .AISChannelAssignment
    }

    func parse(sentence: ParametricSentence) throws -> Message.Payload? {
        let sequenceNumber = try sentence.fields.int(at: 0, optional: true),
            northeastCorner = try sentence.fields.position(latitudeIndex: (1, 2), longitudeIndex: (3, 4))!,
            southwestCorner = try sentence.fields.position(latitudeIndex: (5, 6), longitudeIndex: (7, 8))!,
            transitionZoneSize = try sentence.fields.measurement(at: 9, valueType: .integer, units: UnitLength.nauticalMiles)!,
            channelA = try sentence.fields.int(at: 10)!,
            channelABandwidth = try sentence.fields.enumeration(at: 11, ofType: AIS.ChannelBandwidth.self)!,
            channelB = try sentence.fields.int(at: 12)!,
            channelBBandwidth = try sentence.fields.enumeration(at: 13, ofType: AIS.ChannelBandwidth.self)!,
            txRxMode = try sentence.fields.enumeration(at: 14, ofType: AIS.TransmitReceiveMode.self)!,
            powerLevel = try sentence.fields.enumeration(at: 15, ofType: AIS.PowerLevel.self)!,
            source = try sentence.fields.enumeration(at: 16, ofType: AIS.InformationSource.self, optional: true),
            inUseFlag = try sentence.fields.bool(at: 17, trueValue: "1", falseValue: "0", optional: true),
            inUseChanged = try sentence.fields.hmsDecimal(at: 18, searchDirection: .backward, optional: true)

        return .AISChannelAssignment(sequenceNumber: sequenceNumber,
                                     northeastCorner: northeastCorner,
                                     southwestCorner: southwestCorner,
                                     transitionZoneSize: transitionZoneSize,
                                     channelA: channelA,
                                     channelABandwidth: channelABandwidth,
                                     channelB: channelB,
                                     channelBBandwidth: channelBBandwidth,
                                     txRxMode: txRxMode,
                                     powerLevel: powerLevel,
                                     source: source,
                                     inUse: inUseFlag,
                                     inUseChanged: inUseChanged)
    }
}
