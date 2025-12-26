# expo-apple-mapkit

Expo module for integrating Apple MapKit functionality into React Native applications. This library provides access to location search, route calculation, reverse geocoding, and map view capabilities using Apple's MapKit framework.

## Features

- 🔍 **Location Search**: Search for places, addresses, and points of interest using natural language queries
- 🗺️ **Route Calculation**: Get driving, walking, transit, or any route directions between two coordinates
- 📍 **Reverse Geocoding**: Convert coordinates (latitude/longitude) to human-readable addresses
- 🗺️ **Map View**: Display Apple MapKit maps in your React Native application
- ⚡ **TypeScript Support**: Full TypeScript definitions included
- 🍎 **iOS Native**: Built on top of Apple's native MapKit framework

## API Documentation

- [Documentation for the latest stable release](https://docs.expo.dev/versions/latest/sdk/apple-mapkit/)
- [Documentation for the main branch](https://docs.expo.dev/versions/unversioned/sdk/apple-mapkit/)

# Installation in managed Expo projects

For [managed](https://docs.expo.dev/archive/managed-vs-bare/) Expo projects, please follow the installation instructions in the [API documentation for the latest stable release](#api-documentation). If you follow the link and there is no documentation available then this library is not yet usable within managed projects &mdash; it is likely to be included in an upcoming Expo SDK release.

# Installation in bare React Native projects

For bare React Native projects, you must ensure that you have [installed and configured the `expo` package](https://docs.expo.dev/bare/installing-expo-modules/) before continuing.

### Add the package to your npm dependencies

```
npm install expo-apple-mapkit
```

### Configure for Android




### Configure for iOS

Run `npx pod-install` after installing the npm package.

## Usage

### Location Search

Search for places, addresses, and points of interest:

```typescript
import { searchLocation, LocationSearchOptions } from 'expo-apple-mapkit';

// Basic search
const results = await searchLocation('coffee shops near me');

// Search with region and options
const options: LocationSearchOptions = {
  region: {
    latitude: 37.7749,
    longitude: -122.4194,
    latitudeDelta: 0.1,
    longitudeDelta: 0.1,
  },
  resultLimit: 10,
  includePointsOfInterest: true,
  includeQueries: true,
};

const results = await searchLocation('restaurants', options);
console.log(results);
```

### Route Calculation

Get directions between two coordinates:

```typescript
import { getRoute, Coordinate, RouteOptions } from 'expo-apple-mapkit';

const origin: Coordinate = { latitude: 37.7749, longitude: -122.4194 };
const destination: Coordinate = { latitude: 37.7849, longitude: -122.4094 };

// Get driving route
const routes = await getRoute(origin, destination, {
  transportType: 'automobile',
  requestsAlternateRoutes: true,
});

// Get walking route
const walkingRoutes = await getRoute(origin, destination, {
  transportType: 'walking',
});

console.log(routes[0].distance); // Distance in meters
console.log(routes[0].expectedTravelTime); // Time in seconds
console.log(routes[0].steps); // Array of route steps
```

### Reverse Geocoding

Convert coordinates to addresses:

```typescript
import { reverseGeocode, Coordinate } from 'expo-apple-mapkit';

const coordinate: Coordinate = { latitude: 37.7749, longitude: -122.4194 };
const result = await reverseGeocode(coordinate);

if (result) {
  console.log(result.formattedAddress);
  console.log(result.placemark.locality); // City
  console.log(result.placemark.administrativeArea); // State/Province
  console.log(result.placemark.country); // Country
}
```

## API Reference

### Functions

#### `searchLocation(query: string, options?: LocationSearchOptions | LocationSearchRegion): Promise<LocationSearchResult[]>`

Searches for locations based on a query string.

**Parameters:**
- `query` (string): The search query (e.g., "coffee shops", "123 Main St")
- `options` (optional): Search options or region object for backward compatibility

**Returns:** Promise resolving to an array of search results

**Example:**
```typescript
const results = await searchLocation('Starbucks near San Francisco');
```

#### `getRoute(origin: Coordinate, destination: Coordinate, options?: RouteOptions): Promise<Route[]>`

Calculates routes between two coordinates.

**Parameters:**
- `origin` (Coordinate): Starting point coordinates
- `destination` (Coordinate): Destination coordinates
- `options` (optional): Route calculation options

**Returns:** Promise resolving to an array of possible routes

**Example:**
```typescript
const routes = await getRoute(
  { latitude: 37.7749, longitude: -122.4194 },
  { latitude: 37.7849, longitude: -122.4094 },
  { transportType: 'automobile' }
);
```

#### `reverseGeocode(coordinate: Coordinate): Promise<ReverseGeocodeResult | null>`

Converts coordinates to a human-readable address.

**Parameters:**
- `coordinate` (Coordinate): Latitude and longitude to geocode

**Returns:** Promise resolving to geocoding result or null if not found

**Example:**
```typescript
const result = await reverseGeocode({ latitude: 37.7749, longitude: -122.4194 });
```

#### `getMapkitToken(): string`

Returns the MapKit token (utility function).

**Returns:** MapKit token string

### Type Definitions

#### `Coordinate`
```typescript
interface Coordinate {
  latitude: number;  // -90 to 90
  longitude: number; // -180 to 180
}
```

#### `LocationSearchRegion`
```typescript
interface LocationSearchRegion {
  latitude: number;
  longitude: number;
  latitudeDelta: number;
  longitudeDelta: number;
}
```

#### `LocationSearchOptions`
```typescript
interface LocationSearchOptions {
  region?: LocationSearchRegion;
  resultLimit?: number;
  includePointsOfInterest?: boolean;
  includeQueries?: boolean;
}
```

#### `LocationSearchResult`
```typescript
interface LocationSearchResult {
  name: string;
  placemark: {
    coordinate: Coordinate;
    countryCode: string;
    postalCode: string;
    administrativeArea: string;
    subAdministrativeArea: string;
    locality: string;
    subLocality: string;
    thoroughfare: string;
    subThoroughfare: string;
    region?: {
      center: Coordinate;
      radius: number;
    };
  };
  phoneNumber?: string;
  url?: string;
}
```

#### `RouteOptions`
```typescript
interface RouteOptions {
  transportType?: 'automobile' | 'walking' | 'transit' | 'any';
  requestsAlternateRoutes?: boolean;
}
```

#### `Route`
```typescript
interface Route {
  distance: number;              // Distance in meters
  expectedTravelTime: number;    // Time in seconds
  name: string;
  steps: RouteStep[];
  polyline: Coordinate[];
  advisoryNotices?: string[];
}
```

#### `RouteStep`
```typescript
interface RouteStep {
  instructions: string;
  distance: number;
  transportType: string;
  coordinate: Coordinate;
  polyline: Coordinate[];
}
```

#### `ReverseGeocodeResult`
```typescript
interface ReverseGeocodeResult {
  formattedAddress: string;
  placemark: {
    coordinate: Coordinate;
    countryCode: string;
    postalCode: string;
    administrativeArea: string;
    subAdministrativeArea: string;
    locality: string;
    subLocality: string;
    thoroughfare: string;
    subThoroughfare: string;
    country: string;
    name: string;
    region?: {
      center: Coordinate;
      radius: number;
    };
    timeZone?: string;
  };
}
```

## Requirements

- iOS 13.0+
- Expo SDK 54+
- React Native 0.81.5+

## Platform Support

- ✅ iOS
- ❌ Android (Apple MapKit is iOS-only)

## Example

See the [example app](./example) directory for a complete working example demonstrating all features of this library.

## Contributing

Contributions are very welcome! Please refer to guidelines described in the [contributing guide]( https://github.com/expo/expo#contributing).
