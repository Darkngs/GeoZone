// Developed by Mykola Darkngs Golyash
// 2019.01.14
// http://golyash.com

import UIKit
import MapKit
import SystemConfiguration.CaptiveNetwork

extension UIViewController {
   
   func showAlert(withTitle title: String?, message: String?) {
      let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
      let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
      alert.addAction(action)
      present(alert, animated: true, completion: nil)
   }
}

extension MKMapView {
   
   func zoomToUserLocation() {
      guard let coordinate = userLocation.location?.coordinate else {
         return
      }
      
      let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 10000, longitudinalMeters: 10000)
      setRegion(region, animated: true)
   }
}

extension UIColor {
   
   convenience init(red: UInt, green: UInt, blue: UInt) {
      self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
   }
   
   convenience init(hex:Int) {
      self.init(red: UInt((hex >> 16) & 0xff), green: UInt((hex >> 8) & 0xff), blue: UInt(hex & 0xff))
   }
}

extension Array where Element: Equatable {
   
   mutating func removeObject(_ object: Element) {
      if let index = self.index(of: object) {
         self.remove(at: index)
      }
   }
   
   mutating func removeObjectsInArray(_ array: [Element]) {
      for object in array {
         self.removeObject(object)
      }
   }
}

func currentSSIDs() -> [String] {
   guard let supportedInterfaces = CNCopySupportedInterfaces() as? [String] else {
      return []
   }
   
   return supportedInterfaces.compactMap { name in
      guard let info = CNCopyCurrentNetworkInfo(name as CFString) as? [String: Any] else {
         return nil
      }
      guard let ssid = info[kCNNetworkInfoKeySSID as String] as? String else {
         return nil
      }
      
      return ssid
   }
}
