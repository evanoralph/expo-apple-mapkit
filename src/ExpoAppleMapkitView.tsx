import { requireNativeView } from 'expo';
import * as React from 'react';

import { ExpoAppleMapkitViewProps } from './ExpoAppleMapkit.types';

const NativeView: React.ComponentType<ExpoAppleMapkitViewProps> =
  requireNativeView('ExpoAppleMapkit');

export default function ExpoAppleMapkitView(props: ExpoAppleMapkitViewProps) {
  return <NativeView {...props} />;
}
