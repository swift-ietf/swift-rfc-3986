#if Coder
    public import Byte
    public import Coder
    public import Cursor
    import Parser
    import Serializer

    extension RFC_3986.URI.Scheme {

        public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

            public typealias Output = RFC_3986.URI.Scheme

            public typealias Failure = RFC_3986.URI.Scheme.Error

            public init() {}

            public borrowing func parse(_ input: inout Input) throws(Failure) -> Output {
                let start = input.checkpoint
                guard let first = input.next() else {
                    throw .empty
                }
                guard RFC_3986.Grammar.isAlpha(first.bitPattern) else {
                    input.seek(to: start)
                    throw .invalidStart(String(decoding: [first], as: UTF8.self), byte: first)
                }
                let rest = Scan.run(&input, while: RFC_3986.Grammar.isSchemeChar)
                do throws(Failure) {
                    return try RFC_3986.URI.Scheme(ascii: [first] + rest)
                } catch {
                    input.seek(to: start)
                    throw error
                }
            }

            public borrowing func serialize(_ output: Output, into buffer: inout Buffer) throws(Failure) {
                Scan.append(output.rawValue, into: &buffer)
            }
        }

        public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }
    }
#endif
