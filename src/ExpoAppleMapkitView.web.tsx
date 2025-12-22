import * as React from 'react';

import { ExpoAppleMapkitViewProps } from './ExpoAppleMapkit.types';

export default function ExpoAppleMapkitView(props: ExpoAppleMapkitViewProps) {
  return (
    <div>
      <iframe
        style={{ flex: 1 }}
        src={props.url}
        onLoad={() => props.onLoad({ nativeEvent: { url: props.url } })}
      />
    </div>
  );
}
