//
//  AddGeoItemViewController.swift
//  GeoZone
//
//  Created by Mykola Golyash on 1/18/19.
//  Copyright © 2019 Mykola Golyash. All rights reserved.
//

import UIKit
import MapKit

protocol AddGeoItemViewControllerDelegate {
   
   func addGeoItemViewController(_ controller: AddGeoItemViewController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: GeoItem.EventType)
}

class AddGeoItemViewController: UITableViewController {
   
   @IBOutlet var addButton: UIBarButtonItem!
   @IBOutlet var zoomButton: UIBarButtonItem!
   @IBOutlet weak var eventTypeSegmentedControl: UISegmentedControl!
   @IBOutlet weak var radiusTextField: UITextField!
   @IBOutlet weak var noteTextField: UITextField!
   @IBOutlet weak var mapView: MKMapView!
   
   var delegate: AddGeoItemViewControllerDelegate?
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      navigationItem.rightBarButtonItems = [addButton, zoomButton]
      
      addButton.isEnabled = false
   }
   
   // MARK: -
   
   @IBAction fileprivate func actionCancel(_ sender: Any? = nil) {
      navigationController?.popViewController(animated: true)
   }
   
   @IBAction fileprivate func actionAdd(_ sender: Any?) {
      let coordinate = mapView.centerCoordinate
      let radius = Double(radiusTextField.text!) ?? 0
      let identifier = NSUUID().uuidString
      let note = noteTextField.text
      let eventType: GeoItem.EventType = (eventTypeSegmentedControl.selectedSegmentIndex == 0) ? .onEntry : .onExit
      actionCancel()
      delegate?.addGeoItemViewController(self, didAddCoordinate: coordinate, radius: radius, identifier: identifier, note: note!, eventType: eventType)
   }
   
   @IBAction fileprivate func actionZoomToCurrentLocation(_ sender: Any?) {
      mapView.zoomToUserLocation()
   }
   
   @IBAction fileprivate func textFieldEditingChanged(sender: UITextField) {
      addButton.isEnabled = !radiusTextField.text!.isEmpty && !noteTextField.text!.isEmpty
   }
}
