func calculateChecksum(for string: any StringProtocol) -> UInt8 {
  string.utf8.reduce(0) { $0 ^ $1 }
}
