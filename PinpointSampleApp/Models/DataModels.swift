//
//  DataModels.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 28.08.23.
//

import Foundation


struct Position: Hashable {
    let x: CGFloat
    let y: CGFloat
    let acc: CGFloat
    var rawX:CGFloat = 0.0
    var rawY:CGFloat = 0.0
}


struct ImageGeometry {
    var xOrigin: CGFloat
    var yOrigin: CGFloat
    var imageSize: CGSize
    var imagePosition:CGPoint
}

struct Settings {
    var previousPositions: Int = 0
    var showRuler: Bool = false
    var showOrigin: Bool = false
    var showAccuracyRange:Bool = false
    var showSatlets:Bool = false
}

enum CustomError: Error {
    case statusNotFound
    case otherError(description: String)
}



