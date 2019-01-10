//
//  TravelPageViewModel.swift
//  Weckr
//
//  Created by Tim Mewe on 21.11.18.
//  Copyright © 2018 Tim Lehmann. All rights reserved.
//

import Foundation
import RxSwift
import Action

class TravelPageViewModel : WalkthroughSlideableType {
    
    var inputs: WalkthroughSlideableInputsType { return self }
    var outputs: WalkthroughSlideableOutputsType { return self }
    var actions: WalkthroughSlideableActionsType { return self }
    
    //Inputs
    var transportMode: PublishSubject<TransportMode>?
    var morningRoutineTime: PublishSubject<TimeInterval>?
    
    //Outputs
    var accentColor: Observable<CGColor>
    var buttonText: Observable<String>
    var topLabelText: Observable<String>
    var topLabelColoredText: Observable<String>
    var bottomLabelText: Observable<String>
    var bottomLabelColoredText: Observable<String>
    var actionSuccesful: Observable<Bool>

    init() {
        
        //Setup
        let strings = Strings.Walkthrough.Travel.self
        
        //Inputs
        transportMode = PublishSubject()
        
        //Outputs
        accentColor = Observable.just(UIColor.walkthroughOrangeAccent.cgColor)
        buttonText = Observable.just(strings.buttonTitle)
        topLabelText = Observable.just(strings.title)
        topLabelColoredText = Observable.just(strings.titleColored)
        bottomLabelText = Observable.just(strings.subtitle)
        bottomLabelColoredText = Observable.just(strings.subtitleColored)
        actionSuccesful = Observable.empty()
    }
    
    //Actions
    lazy var continueAction: CocoaAction? = {
        return CocoaAction {
            let userDefaults = UserDefaults.standard
            userDefaults.set(true, forKey: SettingsKeys.adjustForWeather)
            userDefaults.synchronize()
            return Observable.empty()
        }
    }()
}

extension TravelPageViewModel : WalkthroughSlideableOutputsType, WalkthroughSlideableActionsType, WalkthroughSlideableInputsType {}

