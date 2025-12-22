import { registerWebModule, NativeModule } from 'expo';

import { ExpoAppleMapkitModuleEvents } from './ExpoAppleMapkit.types';

class ExpoAppleMapkitModule extends NativeModule<ExpoAppleMapkitModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
}

export default registerWebModule(ExpoAppleMapkitModule, 'ExpoAppleMapkitModule');
