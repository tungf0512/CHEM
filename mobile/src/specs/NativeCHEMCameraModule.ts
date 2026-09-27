import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  getCameraPermissionStatus(): Promise<string>;
  requestCameraPermission(): Promise<string>;
  /** JSON metadata for the newest recoverable source-safe local capture. */
  getLastCapture(): Promise<string>;
  /** Local-only metadata; never contains photo pixels, GPS, or account data. */
  getValidationReport(): Promise<string>;
  /** Copies the local-only validation report to the system pasteboard. */
  copyValidationReport(): Promise<string>;
  isInternalValidationEnabled(): Promise<boolean>;
  setValidationFault(point: string): Promise<boolean>;
}

export default TurboModuleRegistry.get<Spec>('CHEMCameraModule');
