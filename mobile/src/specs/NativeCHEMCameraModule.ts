import type {TurboModule} from 'react-native';
import {TurboModuleRegistry} from 'react-native';

export interface Spec extends TurboModule {
  getCameraPermissionStatus(): Promise<string>;
  requestCameraPermission(): Promise<string>;
  /** JSON metadata for the newest recoverable source-safe local capture. */
  getLastCapture(): Promise<string>;
}

export default TurboModuleRegistry.get<Spec>('CHEMCameraModule');
