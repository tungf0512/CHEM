import {
  codegenNativeCommands,
  codegenNativeComponent,
  type CodegenTypes,
  type HostComponent,
  type ViewProps,
} from 'react-native';
import type React from 'react';

export type CameraLifecycleEvent = Readonly<{
  state: string;
  reason: string;
  code: string;
}>;

export type LensesEvent = Readonly<{
  lenses: {id: string; role: string; displayZoom: string}[];
}>;

export type ActiveLensEvent = Readonly<{
  id: string;
}>;

export type CaptureCompletedEvent = Readonly<{
  id: string;
  sourceUri: string;
  thumbnailUri: string;
  width: CodegenTypes.Int32;
  height: CodegenTypes.Int32;
  capturedAt: string;
  lensId: string;
}>;

export type CaptureFailedEvent = Readonly<{
  code: string;
  message: string;
}>;

export type LensSelectionFailedEvent = Readonly<{
  id: string;
  code: string;
  message: string;
}>;

export type CameraErrorEvent = Readonly<{
  code: string;
  message: string;
}>;

export type ExposureEvent = Readonly<{
  minimumEV: CodegenTypes.Float;
  maximumEV: CodegenTypes.Float;
  appliedEV: CodegenTypes.Float;
}>;

export type TelemetryEvent = Readonly<{
  iso: CodegenTypes.Float;
  shutterSeconds: CodegenTypes.Float;
  lensDisplay: string;
  captureExposureCompensationEV: CodegenTypes.Float;
}>;

export type PerformanceMetricsEvent = Readonly<{
  previewFPS: CodegenTypes.Int32;
  renderFPS: CodegenTypes.Int32;
  renderMilliseconds: CodegenTypes.Float;
  droppedFrames: CodegenTypes.Int32;
  activeLens: string;
  cameraState: string;
}>;

export interface NativeProps extends ViewProps {
  active?: boolean;
  onCameraStateChanged?: CodegenTypes.DirectEventHandler<CameraLifecycleEvent>;
  onAvailableLensesChanged?: CodegenTypes.DirectEventHandler<LensesEvent>;
  onActiveLensChanged?: CodegenTypes.DirectEventHandler<ActiveLensEvent>;
  onCaptureCompleted?: CodegenTypes.DirectEventHandler<CaptureCompletedEvent>;
  onCaptureFailed?: CodegenTypes.DirectEventHandler<CaptureFailedEvent>;
  onLensSelectionFailed?: CodegenTypes.DirectEventHandler<LensSelectionFailedEvent>;
  onCameraError?: CodegenTypes.DirectEventHandler<CameraErrorEvent>;
  onExposureChanged?: CodegenTypes.DirectEventHandler<ExposureEvent>;
  onTelemetryChanged?: CodegenTypes.DirectEventHandler<TelemetryEvent>;
  onPerformanceMetricsChanged?: CodegenTypes.DirectEventHandler<PerformanceMetricsEvent>;
}

interface NativeCommands {
  start(viewRef: React.ElementRef<HostComponent<NativeProps>>): void;
  stop(viewRef: React.ElementRef<HostComponent<NativeProps>>): void;
  selectLens(viewRef: React.ElementRef<HostComponent<NativeProps>>, deviceId: string): void;
  focusAndExpose(
    viewRef: React.ElementRef<HostComponent<NativeProps>>,
    normalizedX: CodegenTypes.Float,
    normalizedY: CodegenTypes.Float,
  ): void;
  setExposureCompensation(
    viewRef: React.ElementRef<HostComponent<NativeProps>>,
    ev: CodegenTypes.Float,
  ): void;
  capture(viewRef: React.ElementRef<HostComponent<NativeProps>>): void;
}

export const Commands: NativeCommands = codegenNativeCommands<NativeCommands>({
  supportedCommands: [
    'start',
    'stop',
    'selectLens',
    'focusAndExpose',
    'setExposureCompensation',
    'capture',
  ],
});

export default codegenNativeComponent<NativeProps>(
  'CHEMCameraPreview',
);
