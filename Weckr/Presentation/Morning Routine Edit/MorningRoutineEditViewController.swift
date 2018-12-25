//
//  MorningRoutineEditViewController.swift
//  Weckr
//
//  Created by Tim Mewe on 23.12.18.
//  Copyright © 2018 Tim Lehmann. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

class MorningRoutineEditViewController: UIViewController, BindableType {
    
    typealias ViewModelType = MorningRoutineEditViewModelType
    
    private var editView = MorningRoutineEditView()
    private let disposeBag = DisposeBag()
    private let gradient = Gradient(left: UIColor.walkthroughRedAccent.cgColor,
                                          right: UIColor.backGroundColorTransparent.cgColor)
    var viewModel: ViewModelType!
    
    init(viewModel: ViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    private func setupViews() {
        view.isOpaque = false
        view.backgroundColor = .clear
        view.addSubview(editView)
        editView.autoPinEdgesToSuperviewEdges()
        editView.button.setGradientForButton(gradient)
        
        let strings = Strings.Walkthrough.MorningRoutine.self
        editView.topLabel.setTextWithColoredPart(text: strings.title,
                                                 coloredText: strings.titleColored,
                                                 textColor: .white,
                                                 coloredColor: UIColor.walkthroughRedAccent)
    }
    
    func bindViewModel() {
        editView.button.rx.tap
            .withLatestFrom(editView.picker.rx.countDownDuration)
            .bind(to: viewModel.actions.dismiss.inputs)
            .disposed(by: disposeBag)
        
        viewModel.outputs.currentTime
            .asDriver(onErrorJustReturn: 60)
            .drive(editView.picker.rx.countDownDuration)
            .disposed(by: disposeBag)
    }
}