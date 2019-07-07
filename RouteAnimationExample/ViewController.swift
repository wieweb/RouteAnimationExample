//
//  ViewController.swift
//  RouteAnimationExample
//
//  Created by Stefan Wieland on 07.07.19.
//  Copyright © 2019 allaboutapps GmbH. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    
    let routeSource = CLLocationCoordinate2D(latitude: 48.187651, longitude: 16.359166)
    let routeDestination = CLLocationCoordinate2D(latitude: 52.522107, longitude: 13.413230)

    @IBOutlet private weak var mapView: MKMapView!

    private var animationLayer: AnimatedMapRouteLayer?
    private var route: MKRoute?
    
    // region observation
    private var displayLink: CADisplayLink?
    private var prevRegion: MKCoordinateRegion?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        calculateRoute { [unowned self] (response, error) in
            guard let route = response?.routes.first else { return }
            self.route = route
            self.mapView.addOverlay(route.polyline)
            self.addAnimatedRoute(route: route)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        animationLayer?.stopAnimation()
        stopRegionObservation()
    }
    
    private func addAnimatedRoute(route: MKRoute) {
        let layer = AnimatedMapRouteLayer(path: route.polyline.cgPath(for: mapView))
        mapView.layer.addSublayer(layer)
        animationLayer = layer
        animationLayer?.startAnimation()
        startRegionObservation()
    }
    
    private func updateAnimatedRoute() {
        guard let layer = animationLayer, let route = route else { return }
        layer.path = route.polyline.cgPath(for: mapView)
    }

}

// MARK: Region Observation via DisplayLink

extension ViewController {
    
    private func startRegionObservation() {
        guard displayLink == nil else { return }
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkUpdate))
        displayLink?.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
    }
    
    private func stopRegionObservation() {
        displayLink?.remove(from: RunLoop.main, forMode: RunLoop.Mode.common)
        displayLink = nil
    }
    
    @objc private func displayLinkUpdate() {
        if let region = prevRegion, region == mapView.region {
            return
        }
        
        prevRegion = mapView.region
        updateAnimatedRoute()
    }
}

// MARK: - Directions

extension ViewController {
    
    private func calculateRoute(_ completionHandler: @escaping MKDirections.DirectionsHandler) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: routeSource, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: routeDestination, addressDictionary: nil))
        request.transportType = .automobile
        
        MKDirections(request: request).calculate(completionHandler: completionHandler)
    }
    
}

// MARK: - MKMapViewDelegate

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard overlay is MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
        
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.lineWidth = 8
        renderer.strokeColor = .blue
        renderer.alpha = 0.5
        
        return renderer
    }
    
}

// MARK: - MKMultiPoint

extension MKMultiPoint {
    
    /// convert MKPolyline into array of coordinates
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
    
}

// MARK: - MKPolyline

private extension MKPolyline {
    
    /// convert polyline to coordinates, CGPoints and finaly to CGPath
    func cgPath(for mapView: MKMapView) -> CGPath {
        // convert into cgPoints
        let points = coordinates.map { (coord) -> CGPoint in
            return mapView.convert(coord, toPointTo: mapView)
        }
        // make cgPath
        let path = CGMutablePath()
        for (index, point) in points.enumerated() {
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        return path
    }
    
}

// MARK: - Equatables

extension CLLocationCoordinate2D: Equatable {
    
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.longitude == rhs.longitude && lhs.latitude == rhs.latitude
    }
    
}

extension MKCoordinateRegion: Equatable {
    
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        return lhs.center == rhs.center && lhs.span.latitudeDelta == rhs.span.latitudeDelta && lhs.span.longitudeDelta == rhs.span.longitudeDelta
    }
    
}
