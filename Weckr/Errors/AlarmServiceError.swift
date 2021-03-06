//
//  AlarmServiceError.swift
//  Weckr
//
//  Created by Tim Mewe on 28.11.18.
//  Copyright © 2018 Tim Lehmann. All rights reserved.
//

import Foundation

enum AlarmServiceError: Error {
    case creationFailed
    case updateFailed
    case deletionFailed(Alarm)
}
