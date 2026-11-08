#if Coder
    public import Byte
    public import Coder
    public import Cursor
    import Parser
    import Serializer

    extension RFC_3986.URI.Host {
        public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {
            public init() {}
        }

        public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }
    }

    extension RFC_3986.URI.Host.Coder {
        public typealias Output = RFC_3986.URI.Host

        public typealias Failure = RFC_3986.URI.Host.Error

        public borrowing func parse(_ input: inout Input) throws(Failure) -> Output {
            let start = input.checkpoint
            var bytes: [Byte] = []

            let mark = input.checkpoint
            if let first = input.next(), first.bitPattern == 0x5B {
                bytes.append(first)
                var terminated = false
                while let byte = input.next() {
                    bytes.append(byte)
                    if byte.bitPattern == 0x5D {
                        terminated = true
                        break
                    }
                }
                guard terminated else {
                    input.seek(to: start)
                    throw .invalidIPv6(String(decoding: bytes, as: UTF8.self), reason: "Missing closing bracket")
                }
            } else {
                input.seek(to: mark)
                bytes = Scan.run(&input, while: RFC_3986.Grammar.isRegNameChar)
            }

            do throws(Failure) {
                return try RFC_3986.URI.Host(ascii: bytes)
            } catch {
                input.seek(to: start)
                throw error
            }
        }

        public borrowing func serialize(_ output: Output, into buffer: inout Buffer) throws(Failure) {
            RFC_3986.URI.Host.serialize(output, into: &buffer)
        }
    }
#endif
