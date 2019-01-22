//
//  MainViewController.swift
//  GeoZone
//
//  Created by Mykola Golyash on 1/17/19.
//  Copyright © 2019 Mykola Golyash. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MainViewController: UIViewController {
   
   @IBOutlet weak var mapView: MKMapView!
   
   var geoItems: [GeoItem] = []
   var locationManager = CLLocationManager()
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      locationManager.delegate = self
      locationManager.requestAlwaysAuthorization()
      loadAllGeoItems()
   }
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      if segue.identifier == Constants.Segues.addGeoItem {
         let viewController = segue.destination as! AddGeoItemViewController
         viewController.delegate = self
      }
   }
   
   // MARK: -
   
   func loadAllGeoItems() {
      geoItems.removeAll()
      let allGeoItems = GeoItem.allGeoItems()
      allGeoItems.forEach { add($0) }
   }
   
   func saveAllGeoItems() {
      let encoder = JSONEncoder()
      do {
         let data = try encoder.encode(geoItems)
         UserDefaults.standard.set(data, forKey: Constants.Keys.savedGeoItems)
      } catch {
         print("Error encoding geoItems")
      }
   }
   
   func add(_ geoItem: GeoItem) {
      geoItems.append(geoItem)
      mapView.addAnnotation(geoItem)
      addRadiusOverlay(forGeoItem: geoItem)
      updateGeoItemsCount()
   }
   
   func remove(_ geoItem: GeoItem) {
      guard let index = geoItems.index(of: geoItem) else {
         return
      }
      
      geoItems.remove(at: index)
      mapView.removeAnnotation(geoItem)
      removeRadiusOverlay(forGeoItem: geoItem)
      updateGeoItemsCount()
   }
   
   func updateGeoItemsCount() {
      title = "GeoItems: \(geoItems.count)"
      navigationItem.rightBarButtonItem?.isEnabled = (geoItems.count < 20)
   }
   
   func addRadiusOverlay(forGeoItem geoItem: GeoItem) {
      mapView?.addOverlay(MKCircle(center: geoItem.coordinate, radius: geoItem.radius))
   }
   
   func removeRadiusOverlay(forGeoItem geoItem: GeoItem) {
      guard let overlays = mapView?.overlays else {
         return
      }
      
      for overlay in overlays {
         guard let circleOverlay = overlay as? MKCircle else {
            continue
         }
         
         let coord = circleOverlay.coordinate
         if coord.latitude == geoItem.coordinate.latitude && coord.longitude == geoItem.coordinate.longitude && circleOverlay.radius == geoItem.radius {
            mapView?.removeOverlay(circleOverlay)
            break
         }
      }
   }
   
   @IBAction func zoomToCurrentLocation(sender: AnyObject) {
      mapView.zoomToUserLocation()
   }
   
   func region(with geoItem: GeoItem) -> CLCircularRegion {
      let region = CLCircularRegion(center: geoItem.coordinate, radius: geoItem.radius, identifier: geoItem.identifier)
      region.notifyOnEntry = (geoItem.eventType == .onEntry)
      region.notifyOnExit = !region.notifyOnEntry
      return region
   }
   
   func startMonitoring(geoItem: GeoItem) {
      if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
         showAlert(withTitle:"Error", message: "Geofencing is not supported on this device!")
         return
      }
      
      if CLLocationManager.authorizationStatus() != .authorizedAlways {
         let message = """
      Your geoItem is saved but will only be activated once you grant
      GeoZone permission to access the device location.
      """
         showAlert(withTitle:"Warning", message: message)
      }
      
      let fenceRegion = region(with: geoItem)
      locationManager.startMonitoring(for: fenceRegion)
   }
   
   func stopMonitoring(geoItem: GeoItem) {
      for region in locationManager.monitoredRegions {
         guard let circularRegion = region as? CLCircularRegion, circularRegion.identifier == geoItem.identifier else {
            continue
         }
         
         locationManager.stopMonitoring(for: circularRegion)
      }
   }
}

// MARK: AddGeoItemViewControllerDelegate

extension MainViewController: AddGeoItemViewControllerDelegate {
   
   func addGeoItemViewController(_ controller: AddGeoItemViewController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: GeoItem.EventType) {
      let clampedRadius = min(radius, locationManager.maximumRegionMonitoringDistance)
      let geoItem = GeoItem(coordinate: coordinate, radius: clampedRadius, identifier: identifier, note: note, eventType: eventType)
      add(geoItem)
      startMonitoring(geoItem: geoItem)
      saveAllGeoItems()
   }
}

// MARK: - CLLocationManagerDelegate

extension MainViewController: CLLocationManagerDelegate {
   
   func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
      mapView.showsUserLocation = status == .authorizedAlways
   }
   
   func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
      print("Monitoring failed for region with identifier: \(region!.identifier)")
   }
   
   func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
      print("Location Manager failed with the following error: \(error)")
   }
}

// MARK: - MKMapViewDelegate

extension MainViewController: MKMapViewDelegate {
   
   func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
      let identifier = Constants.Identifiers.geoItem
      if annotation is GeoItem {
         var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
         if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            let removeButton = UIButton(type: .custom)
            removeButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
            removeButton.setImage(UIImage(named: "delete")!, for: .normal)
            annotationView?.leftCalloutAccessoryView = removeButton
         } else {
            annotationView?.annotation = annotation
         }
         return annotationView
      }
      return nil
   }
   
   func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
      if overlay is MKCircle {
         let circleRenderer = MKCircleRenderer(overlay: overlay)
         circleRenderer.lineWidth = 1.0
         circleRenderer.strokeColor = .purple
         circleRenderer.fillColor = UIColor.purple.withAlphaComponent(0.4)
         return circleRenderer
      }
      return MKOverlayRenderer(overlay: overlay)
   }
   
   func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
      let GeoItem = view.annotation as! GeoItem
      remove(GeoItem)
      saveAllGeoItems()
   }
}
