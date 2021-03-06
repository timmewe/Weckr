//
//  WalkthroughViewModel.swift
//  Weckr
//
//  Created by Tim Mewe on 03.11.18.
//  Copyright © 2018 Tim Lehmann. All rights reserved.
//

import Foundation
import RxSwift
import RxOptional
import RxCoreLocation
import CoreLocation
import SwiftDate

protocol WalkthroughViewModelInputsType {
    var nextPage: PublishSubject<Void> { get }
    var previousPage: PublishSubject<Void> { get }
    var scrollAmount: PublishSubject<CGFloat> { get }
    var viewWillAppear: PublishSubject<Void> { get }
}

protocol WalkthroughViewModelOutputsType {
    var pageNumber : Observable<Int> { get }
    var slides : Observable<[WalkthroughPageViewController]> { get }
    var buttonColor: Observable<CGColor> { get }
    var buttonText: Observable<String> { get }
    var errorOccurred: Observable<AppError?> { get }
    var showAlert: Observable<AlertInfo> { get }
    var showLoading: Observable<Bool> { get }
}

protocol WalkthroughViewModelType {
    var inputs : WalkthroughViewModelInputsType { get }
    var outputs : WalkthroughViewModelOutputsType { get }
}

class WalkthroughViewModel: WalkthroughViewModelType {
    
    var inputs: WalkthroughViewModelInputsType { return self }
    var outputs: WalkthroughViewModelOutputsType { return self }
    
    //Setup
    private let serviceFactory: ServiceFactoryProtocol
    private let viewModelFactory: ViewModelFactoryProtocol
    private let realmService: RealmServiceType
    private let authorizationService: AuthorizationStatusServiceType
    private let locationManager = CLLocationManager()
    private var coordinator: SceneCoordinatorType!
    private let disposeBag = DisposeBag()
    
    //Inputs
    var nextPage: PublishSubject<Void>
    var previousPage: PublishSubject<Void>
    var scrollAmount: PublishSubject<CGFloat>
    var viewWillAppear: PublishSubject<Void>
    
    //Outputs
    var pageNumber: Observable<Int>
    var slides: Observable<[WalkthroughPageViewController]>
    var buttonColor: Observable<CGColor>
    var buttonText: Observable<String>
    var errorOccurred: Observable<AppError?>
    var showAlert: Observable<AlertInfo>
    var showLoading: Observable<Bool>
    
    init(pages: [WalkthroughPageViewController],
         viewModelFactory: ViewModelFactoryProtocol,
         serviceFactory: ServiceFactoryProtocol,
         coordinator: SceneCoordinatorType) {
        
        //Setup
        self.coordinator = coordinator
        self.viewModelFactory = viewModelFactory
        self.serviceFactory = serviceFactory
        
        self.realmService = serviceFactory.createRealm()
        self.authorizationService = serviceFactory.createAuthorizationStatus()
        
        let internalPageNumber = BehaviorSubject(value: 0)
        
        let locationError: BehaviorSubject<AppError?> = BehaviorSubject(value: nil)
        let notificationError: BehaviorSubject<AppError?> = BehaviorSubject(value: nil)
        let calendarError: BehaviorSubject<AppError?> = BehaviorSubject(value: nil)
        
        let alertInfo: PublishSubject<AlertInfo> = PublishSubject()
        let loadingInfo: PublishSubject<Bool> = PublishSubject()
        
        locationManager.startUpdatingLocation()
        
        //Inputs
        nextPage = PublishSubject()
        previousPage = PublishSubject()
        scrollAmount = PublishSubject()
        viewWillAppear = PublishSubject()
        
        //Outputs
        pageNumber = internalPageNumber.asObservable()
        slides = Observable.of(pages)
        showAlert = alertInfo.asObservable()
        showLoading = loadingInfo.asObservable()
            .startWith(false)
            .share(replay: 1, scope: .forever)
        
        let currentPageController = scrollAmount
            .withLatestFrom(slides) { ($0, $1) }
            .map { $0.1[Int(floor($0.0))] }
            .startWith(pages.first)
            .distinctUntilChanged()
            .filterNil()
            .share()
        
        buttonColor = currentPageController
            .map { $0.viewModel.outputs.accentColor }
            .flatMap { $0 }
            .startWith(UIColor.walkthroughPurpleAccent.cgColor)

        buttonText = currentPageController
            .map { $0.viewModel.outputs.buttonText }
            .flatMap { $0 }
        
        nextPage
            .withLatestFrom(internalPageNumber)
            .map { $0 + 1 }
            .withLatestFrom(slides) {($0, $1)}
            .filter { $0.0 <= $0.1.count }
            .map { $0.0 }
            .bind(to: internalPageNumber)
            .disposed(by: disposeBag)
        
        previousPage
            .withLatestFrom(internalPageNumber)
            .map { $0 - 1 }
            .filter { $0 >= 0 }
            .bind(to: internalPageNumber)
            .disposed(by: disposeBag)
        
        nextPage
            .withLatestFrom(currentPageController)
            .subscribe(onNext: { $0.viewModel.actions.continueAction?.execute(Void()) })
            .disposed(by: disposeBag)
        
        let createTrigger = nextPage
            .withLatestFrom(internalPageNumber)
            .filter { pages[$0-1].viewModel is DonePageViewModel }
            .map { _ in }
            .do(onNext: previousPage.onNext)
            .share(replay: 1, scope: .forever)
        
        let triggerViewModel = internalPageNumber
            .filter { $0 > 1 }
            .map { pages[$0-1].viewModel }
            .share(replay: 1, scope: .forever)
        
        let notificationTrigger = triggerViewModel
            .filter { $0 is NotificationPageViewModel }
            .take(1)
        
        let calendarTrigger = triggerViewModel
            .filter { $0 is CalendarPageViewModel }
            .take(1)
        
        let startLocation = locationManager.rx.location
            .filterNil()
            .take(1)
            .map { ($0.coordinate.latitude, $0.coordinate.longitude) }
            .map(GeoCoordinate.init)
            .share(replay: 1, scope: .forever)
        
        errorOccurred = Observable.combineLatest(locationError, notificationError, calendarError)
            .map { location, notification, event in
                if location != nil { return location }
                if notification != nil { return notification }
                if event != nil { return event }
                return nil
        }
        
        //Location access status
        locationManager.rx.didChangeAuthorization
            .map { $0.1 }
            .map { status -> AppError? in
                switch status {
                case .restricted, .denied:
                    return AccessError.location
                default:
                    self.locationManager.startUpdatingLocation()
                    return nil
                }
            }
            .bind(to: locationError)
            .disposed(by: disposeBag)
        
        //Notification access status
        let notificationPage = pages.filter { $0.viewModel is NotificationPageViewModel }.first
        notificationPage!.viewModel.outputs.actionSuccesful
            .map { $0 ? nil : AccessError.notification }
            .bind(to: notificationError)
            .disposed(by: disposeBag)
        
        viewWillAppear
            .skipUntil(notificationTrigger)
            .flatMapLatest { self.authorizationService.notificationAuthorization() }
            .bind(to: notificationError)
            .disposed(by: disposeBag)
        
        //Event store access status
        let eventPage = pages.filter { $0.viewModel is CalendarPageViewModel }.first
        eventPage!.viewModel.outputs.actionSuccesful
            .map { $0 ? nil : AccessError.calendar }
            .bind(to: calendarError)
            .disposed(by: disposeBag)
        
        viewWillAppear
            .skipUntil(calendarTrigger)
            .flatMapLatest { self.authorizationService.eventStoreAuthorization() }
            .bind(to: calendarError)
            .disposed(by: disposeBag)
        
        createTrigger
            .do(onNext: { loadingInfo.onNext(true) })
            .withLatestFrom(startLocation)
            .flatMap { self.realmService.createFirstAlarm(startLocation: $0, serviceFactory: serviceFactory) }
            .subscribe(onNext: { result in
                switch result {
                    case .Success(_):
                        coordinator.transition(to: Scene.main(viewModelFactory
                            .createMain(coordinator: coordinator)),
                                               withType: .modal)
                        UserDefaults.standard.set(true, forKey: SettingsKeys.appHasBeenStarted)
                    
                    case let .Failure(error):
                        loadingInfo.onNext(false)
                        let info = AlertInfo(title: error.localizedTitle,
                                             message: error.localizedMessage,
                                             button: Strings.Error.gotit)
                        alertInfo.onNext(info)
                }
            })
            .disposed(by: disposeBag)
    }
}

extension WalkthroughViewModel: WalkthroughViewModelInputsType, WalkthroughViewModelOutputsType {}
