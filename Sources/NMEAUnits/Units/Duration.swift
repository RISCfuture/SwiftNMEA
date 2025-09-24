extension Duration {
  package static func hours<T: BinaryInteger>(_ hours: T) -> Self { .seconds(hours * 60 * 60) }
  package static func minutes<T: BinaryInteger>(_ minutes: T) -> Self { .seconds(minutes * 60) }
}
