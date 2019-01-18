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
    var viewWillAppear: PublishSubject<Void> { get }
    var createNewAlarm: PublishSubject<Void> { get }
}

protocol MainViewModelOutputsType {
    var sections: Observable<[AlarmSection]> { get }
    var dateString: Observable<String> { get }
    var dayString: Observable<String> { get }
    var errorOccurred: Observable<AppError?> { get }
}

protocol MainViewModelActionsType {
    var presentMorningRoutineEdit: CocoaAction { get }
    var presentTravelEdit: CocoaAction { get }
    var presentCalendarEdit: CocoaAction { get }
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
    var viewWillAppear: PublishSubject<Void>
    var createNewAlarm: PublishSubject<Void>
    
    //Outpus
    var sections: Observable<[AlarmSection]>
    var dateString: Observable<String>
    var dayString: Observable<String>
    var errorOccurred: Observable<AppError?>
    
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
        
        let alarmScheduler = serviceFactory.createAlarmScheduler()
        let authorizationService = serviceFactory.createAuthorizationStatus()
        let locationError: BehaviorSubject<AppError?> = BehaviorSubject(value: nil)
        let notificationError: BehaviorSubject<AppError?> = BehaviorSubject(value: nil)
        let calendarError: BehaviorSubject<AppError?> = BehaviorSubject(value: nil)
        
        let nextAlarm = alarmService.currentAlarmObservable().share(replay: 1, scope: .forever)
        
        let alarmItem = nextAlarm.map { [SectionItem.alarm(identity: "alarm", date: $0.date)] }
        let morningRoutineItem = nextAlarm
            .map { [SectionItem.morningRoutine(identity: "morningroutine", time: $0.morningRoutine)] }
        let eventItem = nextAlarm
            .map { [SectionItem.event(identity: "event",
                                      title: Strings.Cells.FirstEvent.title,
                                      selectedEvent: $0.selectedEvent)] }
        
        let currentLocation = locationManager.rx.location
            .filterNil()
            .map { ($0.coordinate.latitude, $0.coordinate.longitude) }
            .map(GeoCoordinate.init)
            .share(replay: 1, scope: .forever)
        
        //Inputs
        toggleRouteVisibility = PublishSubject()
        viewWillAppear = PublishSubject()
        createNewAlarm = PublishSubject()
        let routeVisiblity: Observable<Bool> = toggleRouteVisibility
            .scan(false) { state, _ in  !state}
            .startWith(false)
            .share(replay: 1, scope: .forever)
        
        let routeOverviewItem = nextAlarm
            .map { alarm -> [SectionItem] in
                let leaveDate = alarm.selectedEvent.startDate - alarm.route.summary.trafficTime.seconds
                return [SectionItem.routeOverview(identity: "3", route: alarm.route, leaveDate: leaveDate)]
            }
        
        //Car route
        
        let routeItemsCar: BehaviorSubject<[SectionItem]> = BehaviorSubject(value: [])
        
        let routeItemsExpanded = nextAlarm
            .map { alarm -> [SectionItem] in
                
                let route = alarm.route!
                let leaveDate = alarm.selectedEvent.startDate - alarm.route.summary.trafficTime.seconds
                var items = [SectionItem.routeOverview(identity: "3",
                                                       route: route,
                                                       leaveDate: leaveDate)]
                
                switch route.transportMode {
                case .car:
                    items.append(SectionItem.routeCar(identity: "4", route: route))
                    
                case .pedestrian, .transit:
                    
                    var maneuverDate = leaveDate //For transit departure and arrival
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
                                                                  date: maneuverDate,
                                                                  getOn: getOn,
                                                                  getOff: getOff,
                                                                  transitLines: route.transitLines.toArray()))
                        }
                        
                        maneuverDate = maneuverDate + maneuver.travelTime.seconds
                    }
                }
                return items
        }
        
        let routeRefreshTrigger = Observable
            .combineLatest(routeVisiblity, nextAlarm) { visbility, _ in visbility }
            .share(replay: 1, scope: .forever)
        
        routeRefreshTrigger
            .filter { $0 }
            .withLatestFrom(routeItemsExpanded)
            .bind(to: routeItemsCar)
            .disposed(by: disposeBag)
        
        routeRefreshTrigger
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
            .map { $0.toFormat("MMMM dd") }
            .map { $0.uppercased() }
        
        dayString = nextAlarm
            .map { $0.date }
            .map { $0.toFormat("EEEE") }
        
        //Location access status
        locationManager.rx.didChangeAuthorization
            .map { $0.1 }
            .map { status -> AppError? in
                switch status {
                case .restricted, .denied:
                    return AccessError.location
                default:
                    return nil
                }
            }
            .bind(to: locationError)
            .disposed(by: disposeBag)
        
        //Event store access status
        viewWillAppear
            .flatMapLatest { authorizationService.eventStoreAuthorization() }
            .bind(to: calendarError)
            .disposed(by: disposeBag)
        
        //Notification access status
        viewWillAppear
            .flatMapLatest { authorizationService.notificationAuthorization() }
            .bind(to: notificationError)
            .disposed(by: disposeBag)
        
        errorOccurred = Observable.combineLatest(locationError, notificationError, calendarError)
            .map { location, notification, event in
                if location != nil { return location }
                if notification != nil { return notification }
                if event != nil { return event }
                return nil
        }
        
        //User defaults
        //Morning routine
        userDefaults.rx.observe(TimeInterval.self, SettingsKeys.morningRoutineTime)
            .distinctUntilChanged()
            .filterNil()
            .withLatestFrom(nextAlarm) { ($0, $1) }
            .subscribe(onNext: alarmService.updateMorningRoutine)
            .disposed(by: disposeBag)
        
        //Transport mode
        userDefaults.rx.observe(Int.self, SettingsKeys.transportMode)
            .distinctUntilChanged()
            .filterNil()
            .map { TransportMode(mode: $0) }
            .withLatestFrom(nextAlarm) { ($0, $1) }
            .subscribe(onNext: { [weak self] mode, alarm in
                self?.alarmService.updateTransportMode(mode,
                                                       for: alarm,
                                                       serviceFactory: serviceFactory,
                                                       disposeBag: self!.disposeBag)
            })
            .disposed(by: disposeBag)
        
        // Notification for new alarm
        nextAlarm
            .map { $0.date }
            .subscribe(onNext: alarmScheduler.setAlarmNotification)
            .disposed(by: disposeBag)
        
        //Create new alarm (after notification)
        createNewAlarm.asObservable()
            .withLatestFrom(currentLocation)
            .subscribe(onNext: { self.alarmService
                .createAlarm(startLocation: $0, serviceFactory: self.serviceFactory) })
            .disposed(by: disposeBag)
    }
    
    //Actions
    
    lazy var presentMorningRoutineEdit: CocoaAction = {
        return CocoaAction {
            guard let alarm = self.alarmService.currentAlarm() else { return Observable.empty() }
            let viewModel = self.viewModelFactory
                .createMorningRoutineEdit(time: alarm.morningRoutine, coordinator: self.coordinator)
            return self.coordinator.transition(to: Scene.morningRoutingEdit(viewModel), withType: .modal)
        }
    }()
    
    lazy var presentTravelEdit: CocoaAction = {
        return CocoaAction {
            guard let alarm = self.alarmService.currentAlarm() else { return Observable.empty() }
            let viewModel = self.viewModelFactory
                .createTravelEdit(currentMode: alarm.route.transportMode, coordinator: self.coordinator)
            return self.coordinator.transition(to: Scene.travelEdit(viewModel), withType: .modal)
        }
    }()
    
    lazy var presentCalendarEdit: CocoaAction = {
        return CocoaAction {
            guard let alarm = self.alarmService.currentAlarm() else { return Observable.empty() }
            let viewModel = self.viewModelFactory.createCalendarEdit(alarm: alarm,
                                                                     coordinator: self.coordinator)
            return self.coordinator.transition(to: Scene.calendarEdit(viewModel), withType: .modal)
        }
    }()
}

extension MainViewModel: MainViewModelInputsType, MainViewModelOutputsType, MainViewModelActionsType {}
