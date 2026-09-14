import RegexBuilder
import Synchronization

/// Serializes RegexBuilder → `Regex` construction process-wide. Building a `Regex`
/// from the RegexBuilder DSL touches non-thread-safe global state, so two regexes
/// must never be built at the same time. Matching an already-built `Regex` is
/// thread-safe, so this lock guards construction only — matching runs lock-free.
private let regexConstructionLock = Mutex<Void>(())

/**
 A lazily-built, cached `Regex` that can be shared across isolation domains.

 `Regex` is not `Sendable`, which is why the parsers that own one cannot simply store
 it in `let` storage that several tasks reach. Wrapping it here keeps the regex behind
 a lock instead of behind an actor, so matching stays synchronous: the parsers hold
 their regexes in `static let` storage, each regex is built exactly once per process
 under ``regexConstructionLock``, and every subsequent match reads the cached program
 without contending on any lock.
 */
final class LockedRegex<Output>: @unchecked Sendable {
  private let build: () -> Regex<Output>
  private let cache = Mutex<Regex<Output>?>(nil)

  /// The cached compiled regex, built once under the construction lock on first use.
  private var regex: Regex<Output> {
    if let cached = cache.withLock({ $0 }) { return cached }
    return regexConstructionLock.withLock { _ in
      cache.withLock { slot in
        if let cached = slot { return cached }
        let regex = build()
        slot = regex
        return regex
      }
    }
  }

  init(_ build: @autoclosure @escaping () -> Regex<Output>) {
    self.build = build
  }

  func wholeMatch(in string: String) throws -> Regex<Output>.Match? {
    try regex.wholeMatch(in: string)
  }

  func firstMatch(in string: String) throws -> Regex<Output>.Match? {
    try regex.firstMatch(in: string)
  }
}
