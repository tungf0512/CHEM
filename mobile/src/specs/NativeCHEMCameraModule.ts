import type {TurboModule} from 'react-native';
import {TurboModuleRegistry} from 'react-native';

export interface Spec extends TurboModule {
  getCameraPermissionStatus(): Promise<string>;
  requestCameraPermission(): Promise<string>;
  /** JSON-encoded metadata for the last atomically committed local capture. */
  getLastCapture(): Promise<string>;
}

export default TurboModuleRegistry.get<Spec>('CHEMCameraModule');
