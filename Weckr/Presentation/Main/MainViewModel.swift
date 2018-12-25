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
import Action
import RxCoreLocation
import CoreLocation

protocol MainViewModelInputsType {
    var toggleRouteVisibility: PublishSubject<Void> { get }
}

protocol MainViewModelOutputsType {
    var sections: Observable<[AlarmSection]> { get }
    var dateString: Observable<String> { get }
}

protocol MainViewModelActionsType {
    var presentMorningRoutineEdit: CocoaAction { get }
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
    var toggleRouteVisibility: PublishSubject<Void>
    
    //Outpus
    var sections: Observable<[AlarmSection]>
    var dateString: Observable<String>
    
    //Setup
    private let coordinator: SceneCoordinatorType
    private let serviceFactory: ServiceFactoryProtocol
    private let viewModelFactory: ViewModelFactoryProtocol
    private let alarmService: AlarmServiceType
    private let userDefaults = UserDefaults.standard
    private let locationManager = CLLocationManager()
    private let disposeBag = DisposeBag()

    init(serviceFactory: ServiceFactoryProtocol,
         viewModelFactory: ViewModelFactoryProtocol,
         coordinator: SceneCoordinatorType) {
        
        //Setup
        self.serviceFactory = serviceFactory
        self.viewModelFactory = viewModelFactory
        self.coordinator = coordinator
        self.alarmService = serviceFactory.createAlarm()
        
        let nextAlarm = alarmService.currentAlarmObservable().share(replay: 1, scope: .forever)
        
        let alarmItem = nextAlarm.map { [SectionItem.alarm(identity: "alarm", date: $0.date)] }
        let morningRoutineItem = nextAlarm
            .map { [SectionItem.morningRoutine(identity: "morningroutine", time: $0.morningRoutine)] }
        let eventItem = nextAlarm
            .map { [SectionItem.event(identity: "event",
                                          title: "FIRST EVENT",
                                          selectedEvent: $0.selectedEvent)] }
        
        //Inputs
        toggleRouteVisibility = PublishSubject()
        let routeVisiblity: Observable<Bool> = toggleRouteVisibility
            .scan(false) { state, _ in  !state}
            .startWith(false)
            .share(replay: 1, scope: .forever)
        
        let routeOverviewItem = nextAlarm
            .map { alarm -> [SectionItem] in
                let leaveDate = alarm.date.addingTimeInterval(alarm.morningRoutine)
                return [SectionItem.routeOverview(identity: "3", route: alarm.route, leaveDate: leaveDate)]
            }
        
        //Car route
        
        let routeItemsCar: BehaviorSubject<[SectionItem]> = BehaviorSubject(value: [])
        
        let routeItemsExpanded = nextAlarm
            .map { alarm -> [SectionItem] in
                
                let route = alarm.route!
                let leaveDate = alarm.date.addingTimeInterval(alarm.morningRoutine)
                var items = [SectionItem.routeOverview(identity: "3",
                                                       route: route,
                                                       leaveDate: leaveDate)]
                
                switch route.transportMode {
                case .car:
                    items.append(SectionItem.routeCar(identity: "4", route: route))
                    
                case .pedestrian, .transit:
                    
                    var skipNext = false
                    let maneuvers = route.legs.first!.maneuvers.dropLast()
                    for (index, maneuver) in maneuvers.enumerated() {
                        
                        guard !skipNext else {
                            skipNext = false
                            continue
                        }
                        
                        switch maneuver.transportType {
                            
                        case .privateTransport:
                            items.append(SectionItem.routePedestrian(
                                identity: maneuver.id,
                                maneuver: maneuver))
                            
                        case .publicTransport:
                            skipNext = true
                            let getOn = maneuver
                            let getOff = maneuvers[index + 1]
                            items.append(SectionItem.routeTransit(identity: maneuver.id,
                                                                  getOn: getOn,
                                                                  getOff: getOff,
                                                                  transitLines: route.transitLines.toArray()))
                        }
                    }
                }
                return items
            }
        
        routeVisiblity
            .filter { $0 }
            .withLatestFrom(routeItemsExpanded)
            .bind(to: routeItemsCar)
            .disposed(by: disposeBag)
        
        routeVisiblity
            .filter { !$0 }
            .withLatestFrom(routeOverviewItem)
            .bind(to: routeItemsCar)
            .disposed(by: disposeBag)
        
        //Outputs
        sections = Observable.combineLatest(alarmItem,
                                            morningRoutineItem,
                                            routeItemsCar,
                                            eventItem)
            .map { $0.0 + $0.1 + $0.2 + $0.3 }
            .map { [AlarmSection(header: "", items: $0)] }
            .startWith([])
        
        dateString = nextAlarm
            .map { $0.date }
            .map { $0.toFormat("EEEE, MMMM dd") }
            .map { $0.uppercased() }
        
        //User defaults
        let startLocation = locationManager.rx.location
            .filterNil()
            .take(1)
            .map { ($0.coordinate.latitude, $0.coordinate.longitude) }
            .map(GeoCoordinate.init)
            .share(replay: 1, scope: .forever)
        
        let morningRoutine = userDefaults.rx.observe(TimeInterval.self, SettingsKeys.morningRoutineTime)
            .distinctUntilChanged()
            .filterNil()
        
        let travelMode = userDefaults.rx.observe(Int.self, SettingsKeys.travelMode)
            .distinctUntilChanged()
            .filterNil()
            .map { Vehicle(rawValue: $0) ?? Vehicle.car }
        
        morningRoutine
            .withLatestFrom(nextAlarm) { ($0, $1) }
            .subscribe(onNext: { [weak self] time, alarm in
                self?.alarmService.update(alarm: alarm, with: time)
            })
            .disposed(by: disposeBag)
    }
    
    //Actions
    
    lazy var presentMorningRoutineEdit: CocoaAction = {
        return CocoaAction {
            guard let alarm = self.alarmService.currentAlarm() else { return Observable.empty() }
            let viewModel = self.viewModelFactory
                .createMorningRoutineEdit(alarm: alarm, coordinator: self.coordinator)
            return self.coordinator.transition(to: Scene.morningRoutingEdit(viewModel), withType: .modal)
        }
    }()
}

extension MainViewModel: MainViewModelInputsType, MainViewModelOutputsType, MainViewModelActionsType {}
