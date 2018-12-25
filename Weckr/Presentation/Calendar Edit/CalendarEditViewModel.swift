//
//  CalendarEditViewModel.swift
//  Weckr
//
//  Created by Tim Mewe on 25.12.18.
//  Copyright © 2018 Tim Lehmann. All rights reserved.
//

import Foundation
import RxDataSources
import RxSwift
import Action

typealias EventsSection = SectionModel<String, CalendarEntry>

protocol CalendarEditViewModelInputsType {
}

protocol CalendarEditViewModelOutputsType {
    var events: Observable<[EventsSection]> { get }
}

protocol CalendarEditViewModelActionsType {
    var dismiss: Action<TimeInterval, Void> { get }
}

protocol CalendarEditViewModelType {
    var inputs: CalendarEditViewModelInputsType { get }
    var outputs: CalendarEditViewModelOutputsType { get }
    var actions: CalendarEditViewModelActionsType { get }
}

class CalendarEditViewModel: CalendarEditViewModelType {
    var inputs: CalendarEditViewModelInputsType { return self }
    var outputs: CalendarEditViewModelOutputsType { return self }
    var actions: CalendarEditViewModelActionsType { return self }
    
    //Inputs
    
    //Outputs
    var events: Observable<[EventsSection]>
    
    //Setup
    private let alarm: Alarm
    private let alarmService: AlarmServiceType
    private let coordinator: SceneCoordinatorType
    
    init(alarm: Alarm, serviceFactory: ServiceFactoryProtocol, coordinator: SceneCoordinatorType) {
        self.alarm = alarm
        self.alarmService = serviceFactory.createAlarm()
        self.coordinator = coordinator
        
        //Inputs
        
        //Outputs
        events = Observable.just(alarm.otherEvents.toArray())
            .map { [EventsSection(model: "Events", items: $0)] }
    }
    
    //Actions
    lazy var dismiss: Action<TimeInterval, Void> = { [weak self] this in
        return Action { time in
            return this.coordinator.pop(animated: true)
        }
        }(self)
}

extension CalendarEditViewModel: CalendarEditViewModelInputsType, CalendarEditViewModelOutputsType, CalendarEditViewModelActionsType {}