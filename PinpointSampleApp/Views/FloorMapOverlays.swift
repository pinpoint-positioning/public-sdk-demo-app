//
//  FloorMapOverlays.swift
//  PinpointSampleApp
//
//  Created by Christoph Scherbeck on 28.08.23.
//
import SwiftUI
import Pinpoint_Easylocate_iOS_SDK

// Constants
let SATLET_CIRCLE_SIZE: CGFloat = UIScreen.main.bounds.height / 8
let POSITION_CIRCLE_SIZE: CGFloat = UIScreen.main.bounds.height / 10


struct SatletView: View {
    @ObservedObject var api = EasylocateAPI.shared
    @Binding var imageGeo: ImageGeometry
    @Binding var siteFile: SiteData

    var body: some View {
        let satletPositions = siteFile.satlets.map { satlet in
            CGPoint(
                x: (satlet.xCoordinate + siteFile.map.mapFileOriginX) * siteFile.map.mapFileRes,
                y: imageGeo.imageSize.height - ((satlet.yCoordinate + siteFile.map.mapFileOriginY) * siteFile.map.mapFileRes)
            )
        }

        ForEach(satletPositions.indices, id: \.self) { index in
            let coords = satletPositions[index]
            Image(systemName: "wave.3.right.circle.fill")
                .resizable()
                .foregroundColor(.yellow)
                .frame(width: SATLET_CIRCLE_SIZE, height: SATLET_CIRCLE_SIZE)
                .position(coords)
        }
    }
}

struct PositionTraceView: View {
    @ObservedObject var pos = PositionFetcher.shared
    @ObservedObject var api =  EasylocateAPI.shared
    @Binding var meterToPixelRatio: CGFloat
    @Binding var imageGeo: ImageGeometry
    @Binding var settings: Settings
    @Binding var circlePos: CGPoint

    @State private var positions: [Position] = []
    @State private var latestPositionIndex: Int?
    @GestureState private var gestureScale: CGFloat = 1.0
    @State private var finalScale: CGFloat = 1.0
    @StateObject var storage = LocalStorageManager.shared

    var body: some View {
        ZStack {
            ForEach(positions.indices, id: \.self) { index in
                let coords = makeCoordinates(with: index)
                if index > 0 {
                    drawPath(from: makeCoordinates(with: index - 1), to: coords)
                }
                drawPositionCircle(at: coords, index: index)
            }
        }
        .onChange(of:pos.data ) { newPosition in
            handleNewPosition(newPosition)
        }
    }

    private func drawPath(from start: Position, to end: Position) -> some View {
        Path { path in
            path.move(to: CGPoint(x: start.x, y: start.y))
            path.addLine(to: CGPoint(x: end.x, y: end.y))
        }
        .stroke(Color.orange, style: StrokeStyle(lineWidth: 1, lineCap: .round))
    }

    private func drawPositionCircle(at coords: Position, index: Int) -> some View {
        Image("pinpoint-circle")
            .resizable()
            .frame(width: POSITION_CIRCLE_SIZE, height: POSITION_CIRCLE_SIZE)
            .aspectRatio(contentMode: .fit)
            .position(x: coords.x, y: coords.y)
            .id("position")
            .overlay {
                if settings.showAccuracyRange && index == latestPositionIndex {
                    AccuracyCircle(coords: coords, meterToPixelRatio: meterToPixelRatio)
                        .position(x: coords.x, y: coords.y)
                }
            }
    }

    private func handleNewPosition(_ newPosition: PositionData?) {
        if let newPosition = newPosition,
           let x = newPosition.x,
           let y = newPosition.y,
           let acc = newPosition.acc {
            let newPositionObject = Position(x: x, y: y, acc: acc)
            positions.append(newPositionObject)
            if positions.count > settings.previousPositions + 1 {
                positions.removeFirst()
            }
        }
    }


    private func makeCoordinates(with index: Int) -> Position {
        let scaledX = (positions[index].x + imageGeo.xOrigin) * meterToPixelRatio
        let scaledY = imageGeo.imageSize.height - ((positions[index].y + imageGeo.yOrigin) * meterToPixelRatio)
        let acc = positions[index].acc
        let rawX = positions[index].x
        let rawY = positions[index].y

        DispatchQueue.main.async {
            circlePos = CGPoint(x: scaledX, y: scaledY)
        }

        return Position(x: scaledX, y: scaledY, acc: acc, rawX: rawX, rawY: rawY)
    }
}

struct OriginIndicator: View {
    var body: some View {
        ZStack {
            Rectangle()
                .frame(width: 20, height: 100)
                .foregroundColor(.red)
            Rectangle()
                .frame(width: 100, height: 20)
                .foregroundColor(.red)
        }
    }
}

struct AccuracyCircle: View {
    var coords: Position
    var meterToPixelRatio: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                .frame(width: coords.acc * meterToPixelRatio, height: coords.acc * meterToPixelRatio)
            
            VStack {
                Text("acc: \(String(format: "%.1f", coords.acc))")
            }
            .foregroundColor(.blue)
            .font(.footnote)
            .offset(y: 30)
        }
    }
}
