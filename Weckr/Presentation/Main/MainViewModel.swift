//
//  MainViewModel.swift
//  Weckr
//
//  Created by Tim Lehmann on 01.11.18.
//  Copyright © 2018 Tim Lehmann. All rights reserved.
//

import Foundation
import RxSwift
import RxDataSources
import SwiftDate

protocol MainViewModelInputsType {
    var routeExpanded: PublishSubject<Bool> { get }
}

protocol MainViewModelOutputsType {
    var sections: Observable<[AlarmSection]> { get }
    var dateString: Observable<String> { get }
}

protocol MainViewModelActionsType {
    
}

protocol MainViewModelType {
    var inputs : MainViewModelInputsType { get }
    var outputs : MainViewModelOutputsType { get }
    var actions : MainViewModelActionsType { get }
}

class MainViewModel: MainViewModelType {
    
    var inputs : MainViewModelInputsType { return self }
    var outputs : MainViewModelOutputsType { return self }
    var actions : MainViewModelActionsType { return self }
    
    //Inputs
    var routeExpanded: PublishSubject<Bool>
    
    //Outpus
    var sections: Observable<[AlarmSection]>
    var dateString: Observable<String>
    
    //Setup
    private let serviceFactory: ServiceFactoryProtocol

    init(serviceFactory: ServiceFactoryProtocol) {
        
        //Setup
        self.serviceFactory = serviceFactory
        
        let alarmService = serviceFactory.createAlarm()
        let nextAlarm = alarmService.nextAlarm().share(replay: 1, scope: .forever)
        
        //Inputs
        routeExpanded = PublishSubject()
        
        //Outputs
        sections = nextAlarm
            .map { [
                SectionItem.alarmItem(identity: "", date: $0.date),
                SectionItem.morningRoutineItem(identity: "", time: $0.morningRoutine),
                SectionItem.routeItem(identity: "", route: $0.route),
                SectionItem.eventItem(identity: "", title: "FIRST EVENT", selectedEvent: $0.selectedEvent)
                ]
            }
            .map { [AlarmSection(header: "", items: $0)] }
        
        dateString = nextAlarm
            .map { $0.date }
            .map { $0.toFormat("EEEE, MMMM dd") }
            .map { $0.uppercased() }
    }
}

extension MainViewModel: MainViewModelInputsType, MainViewModelOutputsType, MainViewModelActionsType {}
