import { requireNativeView } from 'expo';
import * as React from 'react';
import { ViewProps } from 'react-native';
import { Coordinate } from './ExpoAppleMapkitModule';

export interface ExpoAppleMapkitViewProps extends ViewProps {
  origin?: Coordinate;
  destination?: Coordinate;
  routeCoordinates?: Coordinate[];
}

const NativeView: React.ComponentType<ExpoAppleMapkitViewProps> =
  requireNativeView('ExpoAppleMapkit');

export default function ExpoAppleMapkitView(props: ExpoAppleMapkitViewProps) {
  return <NativeView {...props} />;
}
