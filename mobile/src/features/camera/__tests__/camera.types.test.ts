import {
  cameraReducer,
  cameraLifecycleFromNative,
  initialCameraState,
  mapAvailableLenses,
  parseCaptureMetadata,
  parsePermissionStatus,
  permissionPresentation,
  type CaptureMetadata,
} from '../camera.types';

const captureOne: CaptureMetadata = {
  id: 'capture-1',
  sourceUri: 'file:///Application Support/CHEM/Captures/capture-1.heic',
  thumbnailUri: 'file:///Application Support/CHEM/Captures/capture-1-thumb.jpg',
  width: 4032,
  height: 3024,
  capturedAt: '2026-09-26T10:00:00.000Z',
  lensId: 'wide-camera::base',
  physicalDeviceId: 'wide-camera',
  captureMode: 'physicalCamera',
  deviceZoomFactor: 1,
  sourceSafe: true,
  complete: true,
  recoverableError: null,
};

describe('camera state and native boundary mapping', () => {
  it('maps native permission values to stable UI states', () => {
    expect(parsePermissionStatus('authorized')).toBe('authorized');
    expect(parsePermissionStatus('notDetermined')).toBe('notDetermined');
    expect(parsePermissionStatus('unknown-value')).toBe('unknown');
    expect(permissionPresentation('notDetermined')).toBe('request');
    expect(permissionPresentation('denied')).toBe('openSettings');
    expect(permissionPresentation('authorized')).toBe('camera');
    expect(cameraLifecycleFromNative('interrupted', '', 'interrupted')).toEqual({
      type: 'interrupted',
      reason: 'Camera interrupted',
    });
    expect(cameraLifecycleFromNative('unexpected-state', '', '')).toEqual({
      type: 'failed',
      code: 'cameraUnavailable',
    });
  });

  it('maps only lenses delivered by native into the selector model', () => {
    expect(mapAvailableLenses([
      {id: 'rear-main-crop-2x', physicalDeviceId: 'rear-main', role: 'wide', captureMode: 'mainSensorCrop', deviceZoomFactor: 2, displayZoom: '2×'},
      {id: 'rear-ultra', physicalDeviceId: 'rear-ultra', role: 'ultraWide', captureMode: 'physicalCamera', deviceZoomFactor: 1, displayZoom: '0.5×'},
      {id: 'rear-wide', physicalDeviceId: 'rear-main', role: 'wide', captureMode: 'physicalCamera', deviceZoomFactor: 1, displayZoom: '1×'},
      {id: 'second-2x', physicalDeviceId: 'rear-tele', role: 'telephoto', captureMode: 'physicalCamera', deviceZoomFactor: 1, displayZoom: '2×'},
    ])).toEqual([
      {id: 'rear-ultra', physicalDeviceId: 'rear-ultra', role: 'ultraWide', captureMode: 'physicalCamera', deviceZoomFactor: 1, displayZoom: '0.5×'},
      {id: 'rear-wide', physicalDeviceId: 'rear-main', role: 'wide', captureMode: 'physicalCamera', deviceZoomFactor: 1, displayZoom: '1×'},
      {id: 'rear-main-crop-2x', physicalDeviceId: 'rear-main', role: 'wide', captureMode: 'mainSensorCrop', deviceZoomFactor: 2, displayZoom: '2×'},
    ]);
  });

  it('requires native active-lens acknowledgement before changing selection', () => {
    const withLenses = cameraReducer(initialCameraState, {
      type: 'lensesChanged',
      value: [
        {id: 'wide-camera::base', physicalDeviceId: 'wide-camera', role: 'wide', captureMode: 'physicalCamera', deviceZoomFactor: 1, displayZoom: '1×'},
        {id: 'ultra-camera::base', physicalDeviceId: 'ultra-camera', role: 'ultraWide', captureMode: 'physicalCamera', deviceZoomFactor: 1, displayZoom: '0.5×'},
      ],
    });
    const requested = cameraReducer(withLenses, {type: 'lensSelectionRequested', id: 'ultra-camera::base'});
    expect(requested.selectedLensId).toBeNull();
    expect(requested.pendingLensId).toBe('ultra-camera::base');
    const acknowledged = cameraReducer(requested, {type: 'activeLensChanged', id: 'ultra-camera::base'});
    expect(acknowledged.selectedLensId).toBe('ultra-camera::base');
    expect(acknowledged.pendingLensId).toBeNull();
    const retry = cameraReducer(acknowledged, {type: 'lensSelectionRequested', id: 'wide-camera::base'});
    const rejected = cameraReducer(retry, {
      type: 'lensSelectionFailed',
      id: 'wide-camera::base',
      code: 'lensSwitchFailed',
    });
    expect(rejected.pendingLensId).toBeNull();
    expect(rejected.selectedLensId).toBe('ultra-camera::base');
  });

  it('applies capture metadata only after native success', () => {
    const current = cameraReducer(initialCameraState, {type: 'captureCompleted', value: captureOne});
    const failed = cameraReducer(current, {type: 'captureFailed', code: 'sourcePersistenceFailed'});
    expect(failed.lastCapture).toEqual(captureOne);
    expect(failed.captureInProgress).toBe(false);
    expect(failed.lastError).toBe('sourcePersistenceFailed');
    expect(parseCaptureMetadata(JSON.stringify(captureOne))).toEqual(captureOne);
    expect(parseCaptureMetadata('{"sourceUri":"https://example.invalid/photo.jpg"}')).toBeNull();
  });

  it('retains a source-safe capture when a derived thumbnail is unavailable', () => {
    const recoverable = {
      ...captureOne,
      thumbnailUri: null,
      width: 0,
      height: 0,
      complete: false,
      recoverableError: 'Metadata was reconstructed from the safe source.',
    };
    expect(parseCaptureMetadata(JSON.stringify(recoverable))).toEqual(recoverable);
    const state = cameraReducer(initialCameraState, {type: 'captureCompleted', value: recoverable});
    expect(state.lastCapture?.sourceSafe).toBe(true);
    expect(state.lastCapture?.thumbnailUri).toBeNull();
    expect(state.lastCapture?.complete).toBe(false);
  });

  it('clamps requested EV to the native device capability range', () => {
    const withExposure = cameraReducer(initialCameraState, {
      type: 'exposureChanged',
      value: {minimumEV: -2, maximumEV: 2, appliedEV: 0},
    });
    expect(cameraReducer(withExposure, {type: 'exposureRequested', value: 8}).pendingExposureEV).toBe(2);
    expect(cameraReducer(withExposure, {type: 'exposureRequested', value: -8}).pendingExposureEV).toBe(-2);
  });
});
