//
//  AlarmSectionModel.swift
//  Weckr
//
//  Created by Tim Mewe on 03.12.18.
//  Copyright © 2018 Tim Lehmann. All rights reserved.
//

import Foundation
import RxDataSources

enum AlarmSectionModel {
    case alarm(title: String, items: [SectionItem])
    case route(title: String, items: [SectionItem])
    case event(title: String, items: [SectionItem])
}

enum SectionItem {
    case alarmSectionItem(identity: String, date: Date)
    case eventSectionItem(identity: String, selectedEvent: CalendarEntry, otherEvents: [CalendarEntry])
}

extension SectionItem: IdentifiableType, Equatable {
    typealias Identity = String
    
    var identity: String {
        return ""
    }
}

extension AlarmSectionModel: AnimatableSectionModelType {
    typealias Item = SectionItem
    typealias Identity = String
    var identity: String { return title }
    
    var items: [SectionItem] {
        switch self {
        case let .alarm(_, items), let .route(_, items), let .event(_, items):
            return items
        }
    }
    
    init(original: AlarmSectionModel, items: [SectionItem]) {
        switch original {
        case let .alarm(title, items):
            self = .alarm(title: title, items: items)
        case let .route(title, items):
            self = .route(title: title, items: items)
        case let .event(title, items):
            self = .event(title: title, items: items)
        }
    }
}

extension AlarmSectionModel {
    var title: String {
        switch self {
        case let .alarm(title, _), let .route(title, _), let .event(title, _):
            return title
        }
    }
}