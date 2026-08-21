extension String {

    public func percentEncoded(
        allowing characterSet: RFC_3986.CharacterSet = .unreserved
    ) -> String {
        RFC_3986.percentEncode(self, allowing: characterSet)
    }

    public func percentDecoded() -> String {
        RFC_3986.percentDecode(self)
    }

    public var uri: RFC_3986.URI? {
        do throws(RFC_3986.Error) {
            return try RFC_3986.URI(self)
        } catch {
            return nil
        }
    }
}
