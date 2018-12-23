//
//  RouteCarTableViewCell.swift
//  Weckr
//
//  Created by Tim Mewe on 23.12.18.
//  Copyright © 2018 Tim Lehmann. All rights reserved.
//

import Foundation
import UIKit

class RouteCarTableViewCell: TileTableViewCell, BasicInfoSubtitleDisplayable {
    
    typealias Configuration = Route
    
    var infoView = BasicInfoView()
    var distanceLabel = SmallLabel.newAutoLayout()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        gradient = Gradient(left: UIColor.routeCellLeft.cgColor,
                            right: UIColor.routeCellRight.cgColor)
        
        addSubviews()
        setupConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func configure(with configuration: Route) {
        let distance = configuration.summary!.distance/1000
        
        infoView.headerInfoView.leftLabel.text = Strings.Directions.drive.uppercased()
        infoView.infoLabel.text = configuration.legs.last!.end.label
        distanceLabel.text = "\(distance) kilometers".lowercased()
    }
}
