import Foundation

/**
 Add class-level ISO-8601 formatting shorthand function to `Formatter`.
 */
extension Formatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
}

/**
 Add ISO-8601 formatting shorthand function to all `Date` objects.
 */
extension Date {
    var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }
}

/**
 Add ISO-8601 parsing shorthand function to all `String` objects.
 */
extension String {
    var iso8601: Date? {
        return Formatter.iso8601.date(from: self)
    }
}
