//
//  AlarmTableHeaderView.swift
//  Weckr
//
//  Created by Tim Mewe on 09.12.18.
//  Copyright © 2018 Tim Lehmann. All rights reserved.
//

import Foundation
import UIKit

class AlarmTableHeaderView: UIView {
    private var safeArea = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(dateLabel)
        addSubview(titleLabel)
        setupConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if #available(iOS 11.0, *) {
            safeArea = safeAreaInsets
            setupConstraints()
        }
    }
    
    private func setupConstraints() {
        let insets = Constraints.Main.Header.self
        dateLabel.autoPinEdge(toSuperviewSafeArea: .top, withInset: insets.top)
        dateLabel.autoPinEdge(.left, to: .left, of: self, withOffset: insets.left)
        dateLabel.autoPinEdge(.right, to: .right, of: self)

        titleLabel.autoPinEdge(.top, to: .bottom, of: dateLabel, withOffset: insets.spacing)
        titleLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0,
                                                                   left: insets.left,
                                                                   bottom: insets.bottom,
                                                                   right: 0),
                                                excludingEdge: .top)
    }
    
    let dateLabel: UILabel = {
        let label = UILabel.newAutoLayout()
        label.font = UIFont.systemFont(ofSize: 13.0, weight: .medium)
        label.textColor = .darkGray
        label.text = "TUESDAY, JUNE 6"
        return label
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel.newAutoLayout()
        label.font = UIFont.systemFont(ofSize: 34.0, weight: .bold)
        label.textColor = .white
        label.text = "Tomorrow"
        return label
    }()
}