import { requireNativeView } from 'expo';
import * as React from 'react';



const NativeView: React.ComponentType<any> =
  requireNativeView('ExpoAppleMapkit');

export default function ExpoAppleMapkitView(props: any) {
  return <NativeView {...props} />;
}
