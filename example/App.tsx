import {
  LocationSearchOptions,
  LocationSearchResult,
  searchLocation,
  getRoute,
  ExpoAppleMapkitView,
  Coordinate,
  RouteOptions,
  Route,
  reverseGeocode,
  ReverseGeocodeResult,
} from 'expo-apple-mapkit';
import { useState } from 'react';
import { Button, SafeAreaView, ScrollView, Text, TextInput, View, StyleSheet } from 'react-native';

export default function App() {
  const [results, setResults] = useState<LocationSearchResult[]>([]);
  const [query, setQuery] = useState('');
  const [reverseGeocodeResult, setReverseGeocodeResult] = useState<ReverseGeocodeResult | null>(null);
  const [latitude, setLatitude] = useState('15.152870');
  const [longitude, setLongitude] = useState('120.599335');
  const [routes, setRoutes] = useState<Route[]>([]);
  const [routeCoordinates, setRouteCoordinates] = useState<Coordinate[]>([]);
  const [routeError, setRouteError] = useState<string | null>(null);
  const [isRouteLoading, setIsRouteLoading] = useState(false);
  const routeOrigin: Coordinate = { latitude: 15.1694, longitude: 120.5807 };
  const routeDestination: Coordinate = { latitude: 15.1529, longitude: 120.5993 };
  const routeStops: Coordinate[] = [
    { latitude: 15.1645, longitude: 120.5858 },
    { latitude: 15.1586, longitude: 120.5922 },
  ];


  const getRouteHandler = async () => {
    setIsRouteLoading(true);
    setRouteError(null);
    setRoutes([]);
    setRouteCoordinates([]);

    try {
      // Example multi-stop route in Pampanga, Philippines.
      const routeOptions: RouteOptions = {
        transportType: 'automobile',
        requestsAlternateRoutes: true,
        stops: routeStops,
      };
      const routeResults = await getRoute(routeOrigin, routeDestination, routeOptions);
      console.log('Route:', JSON.stringify(routeResults, null, 2));
      setRoutes(routeResults);
      setRouteCoordinates(routeResults[0]?.polyline ?? []);
    } catch (error) {
      console.error('Get route error:', error);
      setRouteError(error instanceof Error ? error.message : 'Unable to fetch route');
    } finally {
      setIsRouteLoading(false);
    }
  };
  
  // Sample coordinates: Latitude: 15.152870, Longitude: 120.599335
  const defaultOptions: LocationSearchOptions = {
    region: {
      latitude: 15.152870,
      longitude: 120.599335,
      latitudeDelta: 0.1, // ~11km
      longitudeDelta: 0.1, // ~11km
    }
  };
  
  const [options] = useState<LocationSearchOptions>(defaultOptions);

  const handleSearch = async () => {
    try {
      const searchResults = await searchLocation(query, options);
      console.log('Search Results:', JSON.stringify(searchResults, null, 2));
      setResults(searchResults);
    } catch (error) {
      console.error('Search error:', error);
    }
  };

  const handleReverseGeocode = async () => {
    try {
      const lat = parseFloat(latitude);
      const lon = parseFloat(longitude);
      
      if (isNaN(lat) || isNaN(lon)) {
        console.error('Invalid coordinates');
        return;
      }
      
      const result = await reverseGeocode({ latitude: lat, longitude: lon });
      console.log('Reverse Geocode Result:', JSON.stringify(result, null, 2));
      setReverseGeocodeResult(result);
    } catch (error) {
      console.error('Reverse geocode error:', error);
      setReverseGeocodeResult(null);
    }
  };

  const renderResult = (result: LocationSearchResult, index: number) => {
    const { name, placemark, phoneNumber, url } = result;
    const { coordinate, countryCode, postalCode, administrativeArea, subAdministrativeArea, locality, subLocality, thoroughfare, subThoroughfare, region } = placemark;

    return (
      <View key={`${result.name}-${index}`} style={styles.resultContainer}>
        <Text style={styles.resultTitle}>{name || 'Unnamed Location'}</Text>
        
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Coordinates:</Text>
          <Text style={styles.text}>Latitude: {coordinate.latitude}</Text>
          <Text style={styles.text}>Longitude: {coordinate.longitude}</Text>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Address:</Text>
          {thoroughfare && <Text style={styles.text}>Street: {thoroughfare} {subThoroughfare || ''}</Text>}
          {subLocality && <Text style={styles.text}>Sub-locality: {subLocality}</Text>}
          {locality && <Text style={styles.text}>Locality: {locality}</Text>}
          {subAdministrativeArea && <Text style={styles.text}>Sub-administrative Area: {subAdministrativeArea}</Text>}
          {administrativeArea && <Text style={styles.text}>Administrative Area: {administrativeArea}</Text>}
          {postalCode && <Text style={styles.text}>Postal Code: {postalCode}</Text>}
          {countryCode && <Text style={styles.text}>Country Code: {countryCode}</Text>}
        </View>

        {region && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Region:</Text>
            <Text style={styles.text}>Center: {region.center.latitude}, {region.center.longitude}</Text>
            <Text style={styles.text}>Radius: {region.radius}m</Text>
          </View>
        )}

        {phoneNumber && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Phone:</Text>
            <Text style={styles.text}>{phoneNumber}</Text>
          </View>
        )}

        {url && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>URL:</Text>
            <Text style={styles.text}>{url}</Text>
          </View>
        )}
      </View>
    );
  };

  const renderReverseGeocodeResult = () => {
    if (!reverseGeocodeResult) {
      return null;
    }

    const { formattedAddress, placemark } = reverseGeocodeResult;
    const { coordinate, countryCode, postalCode, administrativeArea, subAdministrativeArea, locality, subLocality, thoroughfare, subThoroughfare, country, name, region, timeZone } = placemark;

    return (
      <View style={styles.resultContainer}>
        <Text style={styles.resultTitle}>Reverse Geocode Result</Text>
        
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Formatted Address:</Text>
          <Text style={styles.text}>{formattedAddress}</Text>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Coordinates:</Text>
          <Text style={styles.text}>Latitude: {coordinate.latitude}</Text>
          <Text style={styles.text}>Longitude: {coordinate.longitude}</Text>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Address Details:</Text>
          {name && <Text style={styles.text}>Name: {name}</Text>}
          {thoroughfare && <Text style={styles.text}>Street: {thoroughfare} {subThoroughfare || ''}</Text>}
          {subLocality && <Text style={styles.text}>Sub-locality: {subLocality}</Text>}
          {locality && <Text style={styles.text}>Locality: {locality}</Text>}
          {subAdministrativeArea && <Text style={styles.text}>Sub-administrative Area: {subAdministrativeArea}</Text>}
          {administrativeArea && <Text style={styles.text}>Administrative Area: {administrativeArea}</Text>}
          {postalCode && <Text style={styles.text}>Postal Code: {postalCode}</Text>}
          {country && <Text style={styles.text}>Country: {country}</Text>}
          {countryCode && <Text style={styles.text}>Country Code: {countryCode}</Text>}
          {timeZone && <Text style={styles.text}>Time Zone: {timeZone}</Text>}
        </View>

        {region && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Region:</Text>
            <Text style={styles.text}>Center: {region.center.latitude}, {region.center.longitude}</Text>
            <Text style={styles.text}>Radius: {region.radius}m</Text>
          </View>
        )}
      </View>
    );
  };

  const renderRouteExampleResult = () => {
    if (isRouteLoading) {
      return (
        <View style={styles.resultContainer}>
          <Text style={styles.resultTitle}>Route Example</Text>
          <Text style={styles.text}>Loading route...</Text>
        </View>
      );
    }

    if (routeError) {
      return (
        <View style={styles.resultContainer}>
          <Text style={styles.resultTitle}>Route Example</Text>
          <Text style={styles.text}>Error: {routeError}</Text>
        </View>
      );
    }

    if (routes.length === 0) {
      return null;
    }

    const firstRoute = routes[0];

    return (
      <View style={styles.resultContainer}>
        <Text style={styles.resultTitle}>Route Example</Text>
        <ExpoAppleMapkitView
          style={styles.routeMap}
          origin={routeOrigin}
          destination={routeDestination}
          routeCoordinates={routeCoordinates}
        />
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Summary:</Text>
          <Text style={styles.text}>Routes found: {routes.length}</Text>
          <Text style={styles.text}>Stops: {routeStops.length}</Text>
          <Text style={styles.text}>Distance: {(firstRoute.distance / 1000).toFixed(2)} km</Text>
          <Text style={styles.text}>Travel time: {Math.round(firstRoute.expectedTravelTime / 60)} min</Text>
          <Text style={styles.text}>Route name: {firstRoute.name || 'Unnamed route'}</Text>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>First 5 Steps:</Text>
          {firstRoute.steps.slice(0, 5).map((step, index) => (
            <Text key={`step-${index}`} style={styles.text}>
              {index + 1}. {step.instructions || 'Continue'} ({Math.round(step.distance)}m)
            </Text>
          ))}
        </View>
      </View>
    );
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.scrollView}>
        <View style={styles.searchContainer}>
          <Text style={styles.label}>Get Route Example with Stops (SM City Clark to 2 stops to MarQuee Mall)</Text>
          <Button title="Get Route" onPress={getRouteHandler} />
        </View>

        {renderRouteExampleResult()}

        <View style={styles.searchContainer}>
          <Text style={styles.label}>Search Location (Sample Region: 15.152870, 120.599335)</Text>
          <TextInput 
            value={query} 
            onChangeText={setQuery} 
            placeholder="e.g., restaurants, coffee shops, hotels"
            style={styles.input}
          />
          <Button title="Search" onPress={handleSearch} />
          <Text style={styles.resultCount}>{results.length} result(s) found</Text>
        </View>

        <View style={styles.searchContainer}>
          <Text style={styles.label}>Reverse Geocoding</Text>
          <Text style={styles.sectionTitle}>Enter coordinates to get address:</Text>
          <TextInput 
            value={latitude} 
            onChangeText={setLatitude} 
            placeholder="Latitude (e.g., 15.152870)"
            style={styles.input}
            keyboardType="numeric"
          />
          <TextInput 
            value={longitude} 
            onChangeText={setLongitude} 
            placeholder="Longitude (e.g., 120.599335)"
            style={styles.input}
            keyboardType="numeric"
          />
          <Button title="Reverse Geocode" onPress={handleReverseGeocode} />
        </View>

        {renderReverseGeocodeResult()}
        
        {results.map((result, index) => renderResult(result, index))}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  searchContainer: {
    padding: 16,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  label: {
    fontSize: 14,
    color: '#666',
    marginBottom: 8,
  },
  input: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 12,
    marginBottom: 12,
    backgroundColor: '#fff',
  },
  resultCount: {
    marginTop: 8,
    fontSize: 14,
    color: '#666',
    fontWeight: '600',
  },
  scrollView: {
    flex: 1,
  },
  resultContainer: {
    backgroundColor: '#fff',
    margin: 16,
    padding: 16,
    borderRadius: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  routeMap: {
    width: '100%',
    height: 220,
    borderRadius: 8,
    marginBottom: 12,
    overflow: 'hidden',
  },
  resultTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 12,
  },
  section: {
    marginBottom: 12,
  },
  sectionTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: '#555',
    marginBottom: 4,
  },
  text: {
    fontSize: 14,
    color: '#666',
    marginBottom: 2,
  },
});
