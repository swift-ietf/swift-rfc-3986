#if Coder
    import Byte
    import Cursor

    enum Scan {
    }

    extension Scan {
        static func run<Input: Cursor.`Protocol`<Byte, Never>>(
            _ input: inout Input,
            while predicate: (UInt8) -> Bool
        ) -> [Byte] {
            var bytes: [Byte] = []
            while true {
                let mark = input.checkpoint
                guard let byte = input.next(), predicate(byte.bitPattern) else {
                    input.seek(to: mark)
                    return bytes
                }
                bytes.append(byte)
            }
        }

        static func append<Buffer: RangeReplaceableCollection<Byte>>(_ string: String, into buffer: inout Buffer) {
            buffer.append(contentsOf: string.utf8.lazy.map(Byte.init(bitPattern:)))
        }
    }
#endif
