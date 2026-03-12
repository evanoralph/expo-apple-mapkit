import ExpoModulesCore
import MapKit
import CoreLocation

final class ExpoAppleMapkitRouteView: ExpoView, MKMapViewDelegate {
  private let mapView = MKMapView()
  private var routeOverlay: MKPolyline?
  private var originAnnotation: MKPointAnnotation?
  private var destinationAnnotation: MKPointAnnotation?
  private var currentOrigin: CLLocationCoordinate2D?
  private var currentDestination: CLLocationCoordinate2D?

  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    setupMap()
  }

  private func setupMap() {
    mapView.delegate = self
    mapView.showsCompass = true
    mapView.showsScale = true
    addSubview(mapView)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    mapView.frame = bounds
  }

  func setOrigin(_ origin: [String: Any]?) {
    currentOrigin = coordinate(from: origin)
    updateEndpointAnnotation(kind: .origin, coordinate: currentOrigin)
    fitVisibleRegionIfNeeded()
  }

  func setDestination(_ destination: [String: Any]?) {
    currentDestination = coordinate(from: destination)
    updateEndpointAnnotation(kind: .destination, coordinate: currentDestination)
    fitVisibleRegionIfNeeded()
  }

  func setRouteCoordinates(_ coordinates: [[String: Any]]?) {
    if let existingOverlay = routeOverlay {
      mapView.removeOverlay(existingOverlay)
      routeOverlay = nil
    }

    guard let coordinates = coordinates else {
      fitVisibleRegionIfNeeded()
      return
    }

    let parsedCoordinates = coordinates.compactMap { coordinate(from: $0) }
    guard !parsedCoordinates.isEmpty else {
      fitVisibleRegionIfNeeded()
      return
    }

    var mutableCoordinates = parsedCoordinates
    let polyline = MKPolyline(coordinates: &mutableCoordinates, count: mutableCoordinates.count)
    routeOverlay = polyline
    mapView.addOverlay(polyline)
    fitVisibleRegionIfNeeded()
  }

  private enum EndpointKind {
    case origin
    case destination
  }

  private func updateEndpointAnnotation(kind: EndpointKind, coordinate: CLLocationCoordinate2D?) {
    switch kind {
    case .origin:
      if let existingAnnotation = originAnnotation {
        mapView.removeAnnotation(existingAnnotation)
        originAnnotation = nil
      }
      if let coordinate = coordinate {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Origin"
        originAnnotation = annotation
        mapView.addAnnotation(annotation)
      }
    case .destination:
      if let existingAnnotation = destinationAnnotation {
        mapView.removeAnnotation(existingAnnotation)
        destinationAnnotation = nil
      }
      if let coordinate = coordinate {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Destination"
        destinationAnnotation = annotation
        mapView.addAnnotation(annotation)
      }
    }
  }

  private func coordinate(from data: [String: Any]?) -> CLLocationCoordinate2D? {
    guard let data = data,
          let latitude = data["latitude"] as? Double ?? (data["latitude"] as? NSNumber)?.doubleValue,
          let longitude = data["longitude"] as? Double ?? (data["longitude"] as? NSNumber)?.doubleValue else {
      return nil
    }
    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }

  private func fitVisibleRegionIfNeeded() {
    if let routeOverlay = routeOverlay {
      let edgePadding = UIEdgeInsets(top: 40, left: 24, bottom: 40, right: 24)
      mapView.setVisibleMapRect(routeOverlay.boundingMapRect, edgePadding: edgePadding, animated: true)
      return
    }

    var points: [CLLocationCoordinate2D] = []
    if let origin = currentOrigin {
      points.append(origin)
    }
    if let destination = currentDestination {
      points.append(destination)
    }

    guard !points.isEmpty else {
      return
    }

    if points.count == 1, let point = points.first {
      let region = MKCoordinateRegion(
        center: point,
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
      )
      mapView.setRegion(region, animated: true)
      return
    }

    var minLat = points[0].latitude
    var maxLat = points[0].latitude
    var minLon = points[0].longitude
    var maxLon = points[0].longitude

    for point in points {
      minLat = min(minLat, point.latitude)
      maxLat = max(maxLat, point.latitude)
      minLon = min(minLon, point.longitude)
      maxLon = max(maxLon, point.longitude)
    }

    let center = CLLocationCoordinate2D(
      latitude: (minLat + maxLat) / 2,
      longitude: (minLon + maxLon) / 2
    )
    let latDelta = max((maxLat - minLat) * 1.5, 0.01)
    let lonDelta = max((maxLon - minLon) * 1.5, 0.01)
    let region = MKCoordinateRegion(
      center: center,
      span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
    )
    mapView.setRegion(region, animated: true)
  }

  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    guard let polyline = overlay as? MKPolyline else {
      return MKOverlayRenderer(overlay: overlay)
    }

    let renderer = MKPolylineRenderer(polyline: polyline)
    renderer.strokeColor = .systemBlue
    renderer.lineWidth = 5
    renderer.lineCap = .round
    renderer.lineJoin = .round
    return renderer
  }
}

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
      // ---------- Helpers ----------
      func readDouble(_ value: Any?) -> Double? {
        if let d = value as? Double { return d }
        if let n = value as? NSNumber { return n.doubleValue }
        return nil
      }

      func extractCoord(_ dict: [String: Any], label: String) throws -> CLLocationCoordinate2D {
        guard
          let lat = readDouble(dict["latitude"]),
          let lon = readDouble(dict["longitude"])
        else {
          throw NSError(
            domain: "ExpoAppleMapkit",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Invalid \(label) coordinates"]
          )
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
      }

      func transportType(from options: [String: Any]?) -> MKDirectionsTransportType {
        guard let t = options?["transportType"] as? String else { return .automobile }
        switch t {
        case "automobile": return .automobile
        case "walking": return .walking
        case "transit": return .transit
        case "any": return .any
        default: return .automobile
        }
      }

      func alternateRoutes(from options: [String: Any]?) -> Bool {
        return (options?["requestsAlternateRoutes"] as? Bool) ?? false
      }

      func polylineToCoords(_ polyline: MKPolyline, dropFirst: Bool) -> [[String: Any]] {
        let count = polyline.pointCount
        guard count > 0 else { return [] }

        var coords = Array(repeating: CLLocationCoordinate2D(), count: count)
        coords.withUnsafeMutableBufferPointer { buf in
          polyline.getCoordinates(buf.baseAddress!, range: NSRange(location: 0, length: count))
        }

        let startIndex = dropFirst ? 1 : 0
        guard startIndex < coords.count else { return [] }

        return coords[startIndex...].map { c in
          ["latitude": c.latitude, "longitude": c.longitude]
        }
      }

      func stepToDict(_ step: MKRoute.Step, legIndex: Int) -> [String: Any] {
        var stepData: [String: Any] = [:]
        stepData["instructions"] = step.instructions
        stepData["distance"] = step.distance
        stepData["legIndex"] = legIndex

        let t: String
        switch step.transportType {
        case .automobile: t = "automobile"
        case .walking: t = "walking"
        case .transit: t = "transit"
        default: t = "automobile"
        }
        stepData["transportType"] = t

        let stepPolyline = step.polyline
        let stepCoords = polylineToCoords(stepPolyline, dropFirst: false)
        stepData["polyline"] = stepCoords

        if let first = stepCoords.first,
           let lat = first["latitude"] as? Double,
           let lon = first["longitude"] as? Double {
          stepData["coordinate"] = ["latitude": lat, "longitude": lon]
        } else {
          stepData["coordinate"] = ["latitude": 0.0, "longitude": 0.0]
        }

        return stepData
      }

      func calculateDirections(_ request: MKDirections.Request) async throws -> MKDirections.Response {
        try await withCheckedThrowingContinuation { continuation in
          MKDirections(request: request).calculate { response, error in
            if let error = error {
              continuation.resume(throwing: error)
              return
            }
            guard let response = response else {
              continuation.resume(throwing: NSError(
                domain: "ExpoAppleMapkit",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "No directions response"]
              ))
              return
            }
            continuation.resume(returning: response)
          }
        }
      }

      // ---------- Parse inputs ----------
      let originCoord = try extractCoord(origin, label: "origin")
      let destCoord = try extractCoord(destination, label: "destination")

      let tType = transportType(from: options)
      let wantsAlternates = alternateRoutes(from: options)

      // Optional multi-stops from options["stops"]
      let stopsRaw = (options?["stops"] as? [[String: Any]]) ?? []
      let stopCoords: [CLLocationCoordinate2D] = try stopsRaw.enumerated().map { idx, dict in
        try extractCoord(dict, label: "stop[\(idx)]")
      }

      // ---------- If no stops, keep your existing behavior (including alternates) ----------
      if stopCoords.isEmpty {
        let originItem = MKMapItem(placemark: MKPlacemark(coordinate: originCoord))
        let destItem = MKMapItem(placemark: MKPlacemark(coordinate: destCoord))

        let request = MKDirections.Request()
        request.source = originItem
        request.destination = destItem
        request.transportType = tType
        request.requestsAlternateRoutes = wantsAlternates

        let response = try await calculateDirections(request)

        return response.routes.map { route in
          var routeData: [String: Any] = [:]
          routeData["distance"] = route.distance
          routeData["expectedTravelTime"] = route.expectedTravelTime
          routeData["name"] = route.name ?? ""
          routeData["polyline"] = polylineToCoords(route.polyline, dropFirst: false)

          let steps = route.steps.map { stepToDict($0, legIndex: 0) }
          routeData["steps"] = steps

          if !route.advisoryNotices.isEmpty {
            routeData["advisoryNotices"] = route.advisoryNotices
          }

          return routeData
        }
      }

      // ---------- Multi-stop: compute legs sequentially and combine ----------
      // NOTE: requestsAlternateRoutes across multiple legs can explode combinatorially.
      // We intentionally use the FIRST route of each leg to build one combined route.
      let allCoords = [originCoord] + stopCoords + [destCoord]

      var combinedPolyline: [[String: Any]] = []
      var combinedSteps: [[String: Any]] = []
      var totalDistance: CLLocationDistance = 0
      var totalExpectedTime: TimeInterval = 0
      var advisoryNotices: [String] = []

      for i in 0..<(allCoords.count - 1) {
        let from = allCoords[i]
        let to = allCoords[i + 1]

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        request.transportType = tType

        // Force alternates off for multi-stop to keep output predictable (one combined route)
        request.requestsAlternateRoutes = false

        let response = try await calculateDirections(request)
        guard let legRoute = response.routes.first else {
          throw NSError(
            domain: "ExpoAppleMapkit",
            code: 3,
            userInfo: [NSLocalizedDescriptionKey: "No route found for leg \(i)"]
          )
        }

        totalDistance += legRoute.distance
        totalExpectedTime += legRoute.expectedTravelTime

        // Append polyline, dropping first coord for all but the first leg to avoid duplicates
        combinedPolyline += polylineToCoords(legRoute.polyline, dropFirst: i > 0)

        // Append steps (tagged with legIndex)
        combinedSteps += legRoute.steps.map { stepToDict($0, legIndex: i) }

        // Collect notices
        if !legRoute.advisoryNotices.isEmpty {
          advisoryNotices.append(contentsOf: legRoute.advisoryNotices)
        }
      }

      // De-dupe notices
      let uniqueNotices = Array(Set(advisoryNotices))

      var combinedRouteData: [String: Any] = [:]
      combinedRouteData["distance"] = totalDistance
      combinedRouteData["expectedTravelTime"] = totalExpectedTime
      combinedRouteData["name"] = "Multi-stop route"
      combinedRouteData["polyline"] = combinedPolyline
      combinedRouteData["steps"] = combinedSteps

      if !uniqueNotices.isEmpty {
        combinedRouteData["advisoryNotices"] = uniqueNotices
      }

      // Helpful metadata for the caller
      combinedRouteData["legsCount"] = allCoords.count - 1
      combinedRouteData["usedStopsCount"] = stopCoords.count
      combinedRouteData["note"] = wantsAlternates
        ? "requestsAlternateRoutes is ignored when stops are provided; multi-stop returns a single combined route."
        : ""

      return [combinedRouteData]
    }

    // Defines a JavaScript function to reverse geocode coordinates using Apple MapKit
    AsyncFunction("reverseGeocode") { (coordinate: [String: Any]) -> [String: Any]? in
      // Extract coordinates
      guard let lat = coordinate["latitude"] as? Double ?? (coordinate["latitude"] as? NSNumber)?.doubleValue,
            let lon = coordinate["longitude"] as? Double ?? (coordinate["longitude"] as? NSNumber)?.doubleValue else {
        throw NSError(domain: "ExpoAppleMapkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid coordinates"])
      }
      
      let location = CLLocation(latitude: lat, longitude: lon)
      let geocoder = CLGeocoder()
      
      return try await withCheckedThrowingContinuation { continuation in
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
          if let error = error {
            continuation.resume(throwing: error)
            return
          }
          
          guard let placemark = placemarks?.first else {
            continuation.resume(returning: nil)
            return
          }
          
          var result: [String: Any] = [:]
          
          // Build address components
          var addressComponents: [String] = []
          
          if let subThoroughfare = placemark.subThoroughfare {
            addressComponents.append(subThoroughfare)
          }
          if let thoroughfare = placemark.thoroughfare {
            addressComponents.append(thoroughfare)
          }
          if let subLocality = placemark.subLocality {
            addressComponents.append(subLocality)
          }
          if let locality = placemark.locality {
            addressComponents.append(locality)
          }
          if let subAdministrativeArea = placemark.subAdministrativeArea {
            addressComponents.append(subAdministrativeArea)
          }
          if let administrativeArea = placemark.administrativeArea {
            addressComponents.append(administrativeArea)
          }
          if let postalCode = placemark.postalCode {
            addressComponents.append(postalCode)
          }
          if let country = placemark.country {
            addressComponents.append(country)
          }
          
          result["formattedAddress"] = addressComponents.joined(separator: ", ")
          
          // Build placemark data
          var placemarkData: [String: Any] = [
            "coordinate": [
              "latitude": placemark.location?.coordinate.latitude ?? lat,
              "longitude": placemark.location?.coordinate.longitude ?? lon
            ],
            "countryCode": placemark.isoCountryCode ?? "",
            "postalCode": placemark.postalCode ?? "",
            "administrativeArea": placemark.administrativeArea ?? "",
            "subAdministrativeArea": placemark.subAdministrativeArea ?? "",
            "locality": placemark.locality ?? "",
            "subLocality": placemark.subLocality ?? "",
            "thoroughfare": placemark.thoroughfare ?? "",
            "subThoroughfare": placemark.subThoroughfare ?? "",
            "country": placemark.country ?? "",
            "name": placemark.name ?? ""
          ]
          
          // Add region information if available
          if let region = placemark.region as? CLCircularRegion {
            placemarkData["region"] = [
              "center": [
                "latitude": region.center.latitude,
                "longitude": region.center.longitude
              ],
              "radius": region.radius
            ]
          }
          
          // Add timezone if available
          if let timeZone = placemark.timeZone {
            placemarkData["timeZone"] = timeZone.identifier
          }
          
          result["placemark"] = placemarkData
          
          continuation.resume(returning: result)
        }
      }
    }

    View(ExpoAppleMapkitRouteView.self) {
      Prop("origin") { (view: ExpoAppleMapkitRouteView, origin: [String: Any]?) in
        view.setOrigin(origin)
      }

      Prop("destination") { (view: ExpoAppleMapkitRouteView, destination: [String: Any]?) in
        view.setDestination(destination)
      }

      Prop("routeCoordinates") { (view: ExpoAppleMapkitRouteView, routeCoordinates: [[String: Any]]?) in
        view.setRouteCoordinates(routeCoordinates)
      }
    }

  }
}
