package func parse(format: String, data: String?, isQuery: Bool) -> Message? {
  switch format {
    case "00":
      guard let data else { return .enhancedPositionResolution(.nilPlaceholder(isQuery: isQuery)) }
      guard let position = Content<PositionEnhancement>(rawValue: data) else {
        return nil
      }
      return .enhancedPositionResolution(position)

    case "01":
      guard let data else { return .positionSourceDatum(.nilPlaceholder(isQuery: isQuery)) }
      guard let sourceAndDatum = Content<PositionSourceDatum>(rawValue: data) else {
        return nil
      }
      return .positionSourceDatum(sourceAndDatum)

    case "02":
      guard let data else { return .speed(.nilPlaceholder(isQuery: isQuery)) }
      guard let speed = Content<Speed>(rawValue: data) else {
        return nil
      }
      return .speed(speed)

    case "03":
      guard let data else { return .course(.nilPlaceholder(isQuery: isQuery)) }
      guard let course = Content<Course>(rawValue: data) else {
        return nil
      }
      return .course(course)

    case "04":
      guard let data else { return .additionalID(.nilPlaceholder(isQuery: isQuery)) }
      guard let stationID = Content<Text>(rawValue: data) else {
        return nil
      }
      return .additionalID(stationID)

    case "05":
      guard let data else { return .enhnancedGeoArea(.nilPlaceholder(isQuery: isQuery)) }
      guard let area = Content<GeoAreaEnhancement>(rawValue: data) else {
        return nil
      }
      return .enhnancedGeoArea(area)

    case "06":
      guard let data else { return .personsOnboard(.nilPlaceholder(isQuery: isQuery)) }
      guard let soulsOnboard = Content<Number>(rawValue: data) else {
        return nil
      }
      return .personsOnboard(soulsOnboard)

    default: return nil
  }
}
