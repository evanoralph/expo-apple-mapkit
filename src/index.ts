import ExpoAppleMapkitModule, { LocationSearchRegion, LocationSearchResult, LocationSearchOptions, Coordinate, RouteOptions, Route } from './ExpoAppleMapkitModule';

export function getMapkitToken() {
    return ExpoAppleMapkitModule.hello();
}

export async function searchLocation(
    query: string, 
    optionsOrRegion?: LocationSearchOptions | LocationSearchRegion
): Promise<LocationSearchResult[]> {
    try {
        if (!query || query.trim().length === 0) {
            throw new Error('Search query cannot be empty');
        }
        
        // Handle backward compatibility: if second param is a region object (has latitude, longitude, etc.)
        // convert it to the new options format
        let options: LocationSearchOptions | undefined;
        if (optionsOrRegion) {
            if ('latitude' in optionsOrRegion && 'longitude' in optionsOrRegion) {
                // It's a LocationSearchRegion, convert to options
                options = { region: optionsOrRegion as LocationSearchRegion };
            } else {
                // It's already a LocationSearchOptions
                options = optionsOrRegion as LocationSearchOptions;
            }
        }
        
        return await ExpoAppleMapkitModule.searchLocation(query, options);
    } catch (error) {
        console.error('Error searching location:', error);
        throw error;
    }
}

export async function getRoute(
    origin: Coordinate,
    destination: Coordinate,
    options?: RouteOptions
): Promise<Route[]> {
    try {
        if (!origin || typeof origin.latitude !== 'number' || typeof origin.longitude !== 'number') {
            throw new Error('Invalid origin coordinates');
        }
        
        if (!destination || typeof destination.latitude !== 'number' || typeof destination.longitude !== 'number') {
            throw new Error('Invalid destination coordinates');
        }
        
        return await ExpoAppleMapkitModule.getRoute(origin, destination, options);
    } catch (error) {
        console.error('Error getting route:', error);
        throw error;
    }
}

export type { LocationSearchRegion, LocationSearchResult, LocationSearchOptions, Coordinate, RouteOptions, Route };