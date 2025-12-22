import { useEvent } from 'expo';
import {getMapkitToken, LocationSearchOptions, LocationSearchResult, searchLocation, getRoute, Coordinate, RouteOptions} from 'expo-apple-mapkit';
import { useEffect, useState } from 'react';
import { Button, SafeAreaView, ScrollView, Text, TextInput, View, StyleSheet } from 'react-native';

export default function App() {
  const [results, setResults] = useState<LocationSearchResult[]>([]);
  const [query, setQuery] = useState('');


  const getRouteHandler = async () => {
    const route = await getRoute(
      { latitude: 15.152870, longitude: 120.599335 } as Coordinate,
      { latitude: 15.152870, longitude: 120.599335 } as Coordinate,
      { transportType: 'automobile' } as RouteOptions
    );
    console.log('Route:', JSON.stringify(route, null, 2));
  };

  useEffect(() => {
    getRouteHandler();
  }, []);
  
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

  return (
    <SafeAreaView style={styles.container}>
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
      <ScrollView style={styles.scrollView}>
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
