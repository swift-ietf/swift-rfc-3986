#if Coder
    public import Byte
    public import Coder
    public import Cursor
    import Parser
    import Serializer

    extension RFC_3986.URI {

        public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

            public typealias Output = RFC_3986.URI

            public typealias Failure = RFC_3986.Error

            public init() {}

            public borrowing func parse(_ input: inout Input) throws(Failure) -> Output {
                let start = input.checkpoint
                var text = ""

                do throws(RFC_3986.URI.Scheme.Error) {
                    text += try RFC_3986.URI.Scheme.Coder<Input, Buffer>().parse(&input).rawValue
                } catch {
                    throw .invalidComponent("scheme: \(error)")
                }

                guard let colon = input.next(), colon.bitPattern == 0x3A else {
                    input.seek(to: start)
                    throw .invalidURI(text)
                }
                text += ":"

                if Self.consume("//", &input) {
                    do throws(RFC_3986.URI.Authority.Error) {
                        let authority = try RFC_3986.URI.Authority.Coder<Input, Buffer>().parse(&input)
                        var bytes: [Byte] = []
                        RFC_3986.URI.Authority.serialize(authority, into: &bytes)
                        text += "//" + String(decoding: bytes, as: UTF8.self)
                    } catch {
                        input.seek(to: start)
                        throw .invalidComponent("authority: \(error)")
                    }
                }

                do throws(RFC_3986.URI.Path.Error) {
                    text += try RFC_3986.URI.Path.Coder<Input, Buffer>().parse(&input).description
                } catch {
                    input.seek(to: start)
                    throw .invalidComponent("path: \(error)")
                }

                if Self.consume("?", &input) {
                    do throws(RFC_3986.URI.Query.Error) {
                        text += "?" + (try RFC_3986.URI.Query.Coder<Input, Buffer>().parse(&input)).rawValue
                    } catch {
                        input.seek(to: start)
                        throw .invalidComponent("query: \(error)")
                    }
                }

                if Self.consume("#", &input) {
                    do throws(RFC_3986.URI.Fragment.Error) {
                        text += "#" + (try RFC_3986.URI.Fragment.Coder<Input, Buffer>().parse(&input)).rawValue
                    } catch {
                        input.seek(to: start)
                        throw .invalidComponent("fragment: \(error)")
                    }
                }

                do throws(Failure) {
                    return try RFC_3986.URI(text)
                } catch {
                    input.seek(to: start)
                    throw error
                }
            }

            public borrowing func serialize(_ output: Output, into buffer: inout Buffer) throws(Failure) {
                Scan.append(output.value, into: &buffer)
            }

            private static func consume(_ literal: String, _ input: inout Input) -> Bool {
                let mark = input.checkpoint
                for expected in literal.utf8 {
                    guard let byte = input.next(), byte.bitPattern == expected else {
                        input.seek(to: mark)
                        return false
                    }
                }
                return true
            }
        }

        public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }
    }
#endif
