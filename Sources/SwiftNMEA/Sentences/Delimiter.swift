/// Delimiters indicating sentence structure.
public enum Delimiter: Character, Sendable, Codable, Equatable {

  /**
   These sentences start with the "$" delimiter, and indicate the
   majority of sentences defined by this standard (``ParametricSentence``,
   ``Query``, and ``ProprietarySentence``). This sentence structure, with
   delimited and defined data fields, is the preferred method for conveying
   information.
   */
  case parametric = "$"

  /**
   These sentences start with the "!" delimiter. The function of this
   special-purpose sentence structure is to provide a means to convey
   information, when the specific data content is unknown or greater
   information bandwidth is needed. This is similar to a modem that
   transfers information without knowing how the information is to be
   decoded or interpreted. Only ``ParametricSentence``s can be encapsulated.
   */
  case encapsulated = "!"
}
