//
//  PositionChartData.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 18.04.23.
//

import Pinpoint_Easylocate_iOS_SDK
import Combine

struct PositionData: Identifiable, Equatable, Hashable {
    var id :UUID?
    var x : Double?
    var y : Double?
    var acc : Double?
}

class PositionFetcher: ObservableObject {
    
    static let shared = PositionFetcher()
    
    let api = EasylocateAPI.shared
    @Published var data = PositionData()
    private var cancellables: Set<AnyCancellable> = []
    
    private init() {
        // Set up observation for changes in api.localPosition
        api.$localPosition
            .sink { [weak self] newPosition in
                self?.updatePostionData()
            }
            .store(in: &cancellables)
    }
    
    // Store position data in array for later use
    func updatePostionData() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
           
                self.data = PositionData(
                    x: self.api.localPosition.xCoord,
                    y: self.api.localPosition.yCoord,
                    acc: self.api.localPosition.accuracy
                )
        }
    }
}
