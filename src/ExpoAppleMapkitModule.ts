import { NativeModule, requireNativeModule } from 'expo';

export interface LocationSearchRegion {
  latitude: number;
  longitude: number;
  latitudeDelta: number;
  longitudeDelta: number;
}

export interface LocationSearchOptions {
  region?: LocationSearchRegion;
  resultLimit?: number;
  includePointsOfInterest?: boolean;
  includeQueries?: boolean;
}

export interface LocationSearchResult {
  name: string;
  placemark: {
    coordinate: {
      latitude: number;
      longitude: number;
    };
    countryCode: string;
    postalCode: string;
    administrativeArea: string;
    subAdministrativeArea: string;
    locality: string;
    subLocality: string;
    thoroughfare: string;
    subThoroughfare: string;
    region?: {
      center: {
        latitude: number;
        longitude: number;
      };
      radius: number;
    };
  };
  phoneNumber?: string;
  url?: string;
}

export interface Coordinate {
  latitude: number;
  longitude: number;
}

export interface RouteOptions {
  transportType?: 'automobile' | 'walking' | 'transit' | 'any';
  requestsAlternateRoutes?: boolean;
}

export interface RouteStep {
  instructions: string;
  distance: number;
  transportType: string;
  coordinate: Coordinate;
  polyline: Coordinate[];
}

export interface Route {
  distance: number;
  expectedTravelTime: number;
  name: string;
  steps: RouteStep[];
  polyline: Coordinate[];
  advisoryNotices?: string[];
}

export interface ReverseGeocodeResult {
  formattedAddress: string;
  placemark: {
    coordinate: {
      latitude: number;
      longitude: number;
    };
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
      center: {
        latitude: number;
        longitude: number;
      };
      radius: number;
    };
    timeZone?: string;
  };
}

declare class ExpoAppleMapkitModule extends NativeModule<any> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
  searchLocation(query: string, options?: LocationSearchOptions): Promise<LocationSearchResult[]>;
  getRoute(origin: Coordinate, destination: Coordinate, options?: RouteOptions): Promise<Route[]>;
  reverseGeocode(coordinate: Coordinate): Promise<ReverseGeocodeResult | null>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ExpoAppleMapkitModule>('ExpoAppleMapkit');
