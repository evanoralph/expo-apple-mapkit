import ExpoModulesCore
import MapKit

public class ExpoAppleMapkitModule: Module {
  // Each module class must implement the definition function. The definition consists of components
  // that describes the module's functionality and behavior.
  // See https://docs.expo.dev/modules/module-api for more details about available components.
  public func definition() -> ModuleDefinition {
    // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
    // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
    // The module will be accessible from `requireNativeModule('ExpoAppleMapkit')` in JavaScript.
    Name("ExpoAppleMapkit")

    // Defines constant property on the module.
    Constant("PI") {
      Double.pi
    }

    // Defines event names that the module can send to JavaScript.
    Events("onChange")

    // Defines a JavaScript synchronous function that runs the native code on the JavaScript thread.
    Function("hello") {
      return "Hello world! 👋"
    }

    // Defines a JavaScript function that always returns a Promise and whose native code
    // is by default dispatched on the different thread than the JavaScript runtime runs on.
    AsyncFunction("setValueAsync") { (value: String) in
      // Send an event to JavaScript.
      self.sendEvent("onChange", [
        "value": value
      ])
    }

    // Defines a JavaScript function to search for locations using Apple MapKit
    AsyncFunction("searchLocation") { (query: String, options: [String: Any]?) -> [[String: Any]] in
      let request = MKLocalSearch.Request()
      request.naturalLanguageQuery = query
      
      // Handle optional region parameter
      if let options = options,
         let regionDict = options["region"] as? [String: Any] {
        // Extract Double values from the nested dictionary
        var centerLat: Double? = nil
        var centerLon: Double? = nil
        var latDelta: Double? = nil
        var lonDelta: Double? = nil
        
        if let lat = regionDict["latitude"] {
          if let latDouble = lat as? Double {
            centerLat = latDouble
          } else if let latNumber = lat as? NSNumber {
            centerLat = latNumber.doubleValue
          }
        }
        
        if let lon = regionDict["longitude"] {
          if let lonDouble = lon as? Double {
            centerLon = lonDouble
          } else if let lonNumber = lon as? NSNumber {
            centerLon = lonNumber.doubleValue
          }
        }
        
        if let deltaLat = regionDict["latitudeDelta"] {
          if let deltaLatDouble = deltaLat as? Double {
            latDelta = deltaLatDouble
          } else if let deltaLatNumber = deltaLat as? NSNumber {
            latDelta = deltaLatNumber.doubleValue
          }
        }
        
        if let deltaLon = regionDict["longitudeDelta"] {
          if let deltaLonDouble = deltaLon as? Double {
            lonDelta = deltaLonDouble
          } else if let deltaLonNumber = deltaLon as? NSNumber {
            lonDelta = deltaLonNumber.doubleValue
          }
        }
        
        if let lat = centerLat,
           let lon = centerLon,
           let dLat = latDelta,
           let dLon = lonDelta {
          let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
          let span = MKCoordinateSpan(latitudeDelta: dLat, longitudeDelta: dLon)
          request.region = MKCoordinateRegion(center: center, span: span)
        }
      }
      
      // Handle optional resultTypes
      if let options = options {
        var resultTypes: MKLocalSearch.ResultType = []
        
        if let includePOI = options["includePointsOfInterest"] as? Bool {
          if includePOI {
            resultTypes.insert(.pointOfInterest)
          }
        } else {
          // Default to including POIs if not specified
          resultTypes.insert(.pointOfInterest)
        }
        
        if let includeAddresses = options["includeQueries"] as? Bool {
          // Use includeQueries option to control address results
          if includeAddresses {
            resultTypes.insert(.address)
          }
        } else {
          // Default to including addresses if not specified
          resultTypes.insert(.address)
        }
        
        // Only set if we have types specified (should always be the case, but be safe)
        if !resultTypes.isEmpty {
          request.resultTypes = resultTypes
        }
      }
      
      let search = MKLocalSearch(request: request)
      
      return try await withCheckedThrowingContinuation { continuation in
        search.start { response, error in
          if let error = error {
            continuation.resume(throwing: error)
            return
          }
          
          guard let response = response else {
            continuation.resume(returning: [])
            return
          }
          
          // Get resultLimit from options if provided
          var resultLimit: Int? = nil
          if let options = options,
             let limitValue = options["resultLimit"] {
            var limit: Int? = nil
            if let limitInt = limitValue as? Int {
              limit = limitInt
            } else if let limitNumber = limitValue as? NSNumber {
              limit = limitNumber.intValue
            }
            if let limit = limit, limit > 0 {
              resultLimit = limit
            }
          }
          
          var mapItems = response.mapItems
          if let limit = resultLimit, mapItems.count > limit {
            mapItems = Array(mapItems.prefix(limit))
          }
          
          let results = mapItems.map { item -> [String: Any] in
            var result: [String: Any] = [:]
            
            result["name"] = item.name ?? ""
            var placemarkData: [String: Any] = [
              "coordinate": [
                "latitude": item.placemark.coordinate.latitude,
                "longitude": item.placemark.coordinate.longitude
              ],
              "countryCode": item.placemark.countryCode ?? "",
              "postalCode": item.placemark.postalCode ?? "",
              "administrativeArea": item.placemark.administrativeArea ?? "",
              "subAdministrativeArea": item.placemark.subAdministrativeArea ?? "",
              "locality": item.placemark.locality ?? "",
              "subLocality": item.placemark.subLocality ?? "",
              "thoroughfare": item.placemark.thoroughfare ?? "",
              "subThoroughfare": item.placemark.subThoroughfare ?? ""
            ]
            
            // Add region information if available
            if let region = item.placemark.region as? CLCircularRegion {
              placemarkData["region"] = [
                "center": [
                  "latitude": region.center.latitude,
                  "longitude": region.center.longitude
                ],
                "radius": region.radius
              ]
            }
            
            result["placemark"] = placemarkData
            
            if let phoneNumber = item.phoneNumber {
              result["phoneNumber"] = phoneNumber
            }
            
            if let url = item.url {
              result["url"] = url.absoluteString
            }
            
            return result
          }
          
          continuation.resume(returning: results)
        }
      }
    }

    // Defines a JavaScript function to get routes between two coordinates using Apple MapKit
    AsyncFunction("getRoute") { (origin: [String: Any], destination: [String: Any], options: [String: Any]?) -> [[String: Any]] in
      // Extract origin coordinates
      guard let originLat = origin["latitude"] as? Double ?? (origin["latitude"] as? NSNumber)?.doubleValue,
            let originLon = origin["longitude"] as? Double ?? (origin["longitude"] as? NSNumber)?.doubleValue else {
        throw NSError(domain: "ExpoAppleMapkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid origin coordinates"])
      }
      
      // Extract destination coordinates
      guard let destLat = destination["latitude"] as? Double ?? (destination["latitude"] as? NSNumber)?.doubleValue,
            let destLon = destination["longitude"] as? Double ?? (destination["longitude"] as? NSNumber)?.doubleValue else {
        throw NSError(domain: "ExpoAppleMapkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid destination coordinates"])
      }
      
      let originCoord = CLLocationCoordinate2D(latitude: originLat, longitude: originLon)
      let destCoord = CLLocationCoordinate2D(latitude: destLat, longitude: destLon)
      
      // Create placemarks for origin and destination
      let originPlacemark = MKPlacemark(coordinate: originCoord)
      let destPlacemark = MKPlacemark(coordinate: destCoord)
      
      // Create map items
      let originItem = MKMapItem(placemark: originPlacemark)
      let destItem = MKMapItem(placemark: destPlacemark)
      
      // Create directions request
      let request = MKDirections.Request()
      request.source = originItem
      request.destination = destItem
      
      // Handle transport type
      if let options = options,
         let transportTypeStr = options["transportType"] as? String {
        switch transportTypeStr {
        case "automobile":
          request.transportType = .automobile
        case "walking":
          request.transportType = .walking
        case "transit":
          request.transportType = .transit
        case "any":
          request.transportType = .any
        default:
          request.transportType = .automobile
        }
      } else {
        request.transportType = .automobile
      }
      
      // Handle requestsAlternateRoutes
      if let options = options,
         let requestsAlternate = options["requestsAlternateRoutes"] as? Bool {
        request.requestsAlternateRoutes = requestsAlternate
      } else {
        request.requestsAlternateRoutes = false
      }
      
      let directions = MKDirections(request: request)
      
      return try await withCheckedThrowingContinuation { continuation in
        directions.calculate { response, error in
          if let error = error {
            continuation.resume(throwing: error)
            return
          }
          
          guard let response = response else {
            continuation.resume(returning: [])
            return
          }
          
          let routes = response.routes.map { route -> [String: Any] in
            var routeData: [String: Any] = [:]
            
            routeData["distance"] = route.distance
            routeData["expectedTravelTime"] = route.expectedTravelTime
            routeData["name"] = route.name ?? ""
            
            // Convert polyline coordinates
            let pointCount = route.polyline.pointCount
            var polylineCoords: [[String: Any]] = []
            var coordinates = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: pointCount)
            route.polyline.getCoordinates(coordinates, range: NSRange(location: 0, length: pointCount))
            
            for i in 0..<pointCount {
              polylineCoords.append([
                "latitude": coordinates[i].latitude,
                "longitude": coordinates[i].longitude
              ])
            }
            coordinates.deallocate()
            
            routeData["polyline"] = polylineCoords
            
            // Convert steps
            let steps = route.steps.map { step -> [String: Any] in
              var stepData: [String: Any] = [:]
              
              stepData["instructions"] = step.instructions
              stepData["distance"] = step.distance
              
              // Convert transport type
              var transportTypeStr = "automobile"
              switch step.transportType {
              case .automobile:
                transportTypeStr = "automobile"
              case .walking:
                transportTypeStr = "walking"
              case .transit:
                transportTypeStr = "transit"
              default:
                transportTypeStr = "automobile"
              }
              stepData["transportType"] = transportTypeStr
              
              // Convert step polyline
              let stepPointCount = step.polyline.pointCount
              var stepPolylineCoords: [[String: Any]] = []
              var stepCoordinates = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: stepPointCount)
              step.polyline.getCoordinates(stepCoordinates, range: NSRange(location: 0, length: stepPointCount))
              
              for i in 0..<stepPointCount {
                stepPolylineCoords.append([
                  "latitude": stepCoordinates[i].latitude,
                  "longitude": stepCoordinates[i].longitude
                ])
              }
              
              // Get the first coordinate from the polyline as the step coordinate
              if stepPointCount > 0 {
                stepData["coordinate"] = [
                  "latitude": stepCoordinates[0].latitude,
                  "longitude": stepCoordinates[0].longitude
                ]
              } else {
                stepData["coordinate"] = [
                  "latitude": 0.0,
                  "longitude": 0.0
                ]
              }
              
              stepCoordinates.deallocate()
              
              stepData["polyline"] = stepPolylineCoords
              
              return stepData
            }
            
            routeData["steps"] = steps
            
            // Add advisory notices if available
            if !route.advisoryNotices.isEmpty {
              routeData["advisoryNotices"] = route.advisoryNotices
            }
            
            return routeData
          }
          
          continuation.resume(returning: routes)
        }
      }
    }

    // Enables the module to be used as a native view. Definition components that are accepted as part of the
    // view definition: Prop, Events.

  }
}
