//
//  Formatter+Extensions.swift
//  Weckr
//
//  Created by Tim Mewe on 25.11.18.
//  Copyright © 2018 Tim Lehmann. All rights reserved.
//

import Foundation

extension Formatter {
    struct Date {
        static let xsDateTime: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            return formatter
        }()
        
        static let dayMonthLong: DateFormatter = {
            let formatter = DateFormatter();
            formatter.locale = Locale.autoupdatingCurrent
            formatter.setLocalizedDateFormatFromTemplate("MMMMd")
            return formatter
        }()
        
        static let timeShort: DateFormatter = {
            let formatter = DateFormatter();
            formatter.locale = Locale.autoupdatingCurrent
            formatter.setLocalizedDateFormatFromTemplate("HH:mm")
            return formatter;
        }()
        
        static let dayText: DateFormatter = {
            let formatter = DateFormatter();
            formatter.locale = Locale.autoupdatingCurrent
            formatter.setLocalizedDateFormatFromTemplate("EEEE")
            return formatter;
        }()
        
    }
    struct TimeInterval {
        static let timeSpan : DateComponentsFormatter = {
            let formatter = DateComponentsFormatter();
            formatter.allowedUnits = [.day, .hour, .minute]
            formatter.unitsStyle = .short
            return formatter
        }()
    }
}
