// Reexport the native module. On web, it will be resolved to ExpoAppleMapkitModule.web.ts
// and on native platforms to ExpoAppleMapkitModule.ts
export { default } from './ExpoAppleMapkitModule';
export { default as ExpoAppleMapkitView } from './ExpoAppleMapkitView';
export * from  './ExpoAppleMapkit.types';
