import RegexBuilder

// `Reference` is not yet `Sendable` in the standard library, but the parsers hold their
// capture references in immutable `static let` storage: a `Reference` is an immutable
// identity token used only as a capture key, so sharing one across isolation domains is
// safe. The `@retroactive` annotation marks this conformance for removal once the
// standard library conforms the type itself.
extension Reference: @retroactive @unchecked Sendable {}
