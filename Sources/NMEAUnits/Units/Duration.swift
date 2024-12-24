package extension Duration {
    static func hours<T: BinaryInteger>(_ hours: T) -> Self { .seconds(hours * 60 * 60) }
    static func minutes<T: BinaryInteger>(_ minutes: T) -> Self { .seconds(minutes * 60) }
}
