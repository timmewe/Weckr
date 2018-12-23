//
//  RouteCell.swift
//  Weckr
//
//  Created by Tim Mewe on 13.12.18.
//  Copyright © 2018 Tim Lehmann. All rights reserved.
//

import Foundation
import FoldingCell
import UIKit
import SwiftDate

class RouteOverviewTableViewCell: TileTableViewCell, BasicInfoDisplayable {
    
    typealias Configuration = (Route, Date)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        gradient = (UIColor.routeCellLeft.cgColor, UIColor.routeCellRight.cgColor)
        
        addSubviews()
        setupConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func configure(with configuration: (Route, Date)) {
        
        let route = configuration.0
        let leaveDate = configuration.1
        
        var duration = Int(route.summary.trafficTime/60)
        if duration < 1 {
            duration = Int(route.summary.travelTime/60)
        }
        
        let regionalDate = DateInRegion(leaveDate, region: Region.current)
        let dateText = regionalDate.toFormat("HH:mm")
        
        infoView.headerInfoView.leftLabel.text = "TRAVEL"
        infoView.headerInfoView.rightLabel.text = "\(Int(route.summary.travelTime/60)) min".uppercased()
        infoView.infoLabel.text = "Leave at " + dateText
    }
    
    var infoView: BasicInfoView = {
        let view = BasicInfoView.newAutoLayout()
        return view
    }()
}