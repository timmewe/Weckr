//
//  WalkthroughPageController.swift
//  Weckr
//
//  Created by Tim Lehmann on 16.11.18.
//  Copyright © 2018 Tim Lehmann. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class WalkthroughPageViewController: UIViewController {
    var viewModel: WalkthroughSlideableType!
    private let disposeBag: DisposeBag = DisposeBag()
    
    init(viewModel: WalkthroughSlideableType) {
        super.init(nibName: nil, bundle: nil)
        self.viewModel = viewModel
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        bindViewModel()
    }
    
    private func setupViews() {
        view.backgroundColor = .backgroundColor
        view.addSubview(topLabel)
        view.addSubview(bottomLabel)
        
        if viewModel.inputs.vehicle != nil {
            setupSegmentedControl()
        }
        
        if viewModel.inputs.morningRoutineTime != nil {
            setupDatePicker()
        }
    }
    
    private func setupConstraints() {
        topLabel.autoPinEdge(.top, to: .top, of: view, withOffset: Constraints.Walkthrough.Title.title1Top)
        topLabel.autoPinEdge(.left, to: .left, of: view, withOffset: Constraints.Walkthrough.Title.horizontalSides)
        topLabel.autoSetDimension(.width, toSize: Constraints.Walkthrough.Title.width)
        
        bottomLabel.autoAlignAxis(.horizontal, toSameAxisOf: view, withOffset: Constraints.Walkthrough.Title.title2Offset)
        bottomLabel.autoPinEdge(.right, to: .right, of: view, withOffset: -Constraints.Walkthrough.Title.horizontalSides)
        bottomLabel.autoSetDimension(.width, toSize: Constraints.Walkthrough.Title.width)
    }
    
    private func bindViewModel() {
        
        Observable.combineLatest(viewModel.outputs.topLabelText, viewModel.outputs.topLabelColoredText, viewModel.outputs.accentColor)
            .asDriver(onErrorJustReturn: ("", "", UIColor.white.cgColor))
            .drive(onNext: { [weak self] (t,c,a) in
                self?.topLabel.setTextWithColoredPart(text: t, coloredText: c, textColor: .white, coloredColor: UIColor(cgColor: a))
            })
            .disposed(by: disposeBag)
        
        Observable.combineLatest(viewModel.outputs.bottomLabelText, viewModel.outputs.bottomLabelColoredText, viewModel.outputs.accentColor)
            .asDriver(onErrorJustReturn: ("", "", UIColor.white.cgColor))
            .drive(onNext: { [weak self] (t,c,a) in
                self?.bottomLabel.setTextWithColoredPart(text: t, coloredText: c, textColor: .white, coloredColor: UIColor(cgColor: a))
            })
            .disposed(by: disposeBag)
    }
    
    private func setupSegmentedControl() {
        view.addSubview(segmentedControl)
        segmentedControl.autoCenterInSuperview()
        segmentedControl.rx.selectedSegmentIndex
            .map { Vehicle(rawValue: $0) ?? Vehicle.car }
            .bind(to: viewModel.inputs.vehicle!)
            .disposed(by: disposeBag)
    }
    
    private func setupDatePicker() {
        view.addSubview(datePicker)
        datePicker.autoCenterInSuperview()
        datePicker.rx.countDownDuration
            .bind(to: viewModel.inputs.morningRoutineTime!)
            .disposed(by: disposeBag)
    }
    
    let topLabel: UILabel = {
        var label = UILabel.newAutoLayout()
        label.textColor = .white
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.numberOfLines = 0
        return label
    }()
    
    let bottomLabel: UILabel = {
        var label = UILabel.newAutoLayout()
        label.textColor = .white
        label.textAlignment = .right
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.numberOfLines = 0
        return label
    }()
    
    let segmentedControl: UISegmentedControl = {
        let items = ["Car", "Feet", "Transit"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        return control
    }()
    
    let datePicker: UIDatePicker = {
       let picker = UIDatePicker.newAutoLayout()
        picker.datePickerMode = .countDownTimer
        picker.setValue(UIColor.textColor, forKeyPath: "textColor")
        return picker
    }()
}