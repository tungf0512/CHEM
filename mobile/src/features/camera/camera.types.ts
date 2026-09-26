export type CameraPermissionStatus =
  | 'unknown'
  | 'requesting'
  | 'notDetermined'
  | 'authorized'
  | 'denied'
  | 'restricted';

export type CameraErrorCode =
  | 'permissionDenied'
  | 'sessionConfigurationFailed'
  | 'cameraUnavailable'
  | 'lensSwitchFailed'
  | 'focusFailed'
  | 'exposureFailed'
  | 'captureFailed'
  | 'sourcePersistenceFailed'
  | 'rendererFailed'
  | 'interrupted';

export type CameraLifecycle =
  | {type: 'idle'}
  | {type: 'configuring'}
  | {type: 'running'}
  | {type: 'interrupted'; reason: string}
  | {type: 'failed'; code: CameraErrorCode};

export type LensRole = 'ultraWide' | 'wide' | 'telephoto';
export type CameraCaptureMode = 'physicalCamera' | 'mainSensorCrop';

export type CameraLens = {
  id: string;
  physicalDeviceId: string;
  role: LensRole;
  captureMode: CameraCaptureMode;
  deviceZoomFactor: number;
  displayZoom: string;
};

export type NativeLensPayload = {
  id: string;
  physicalDeviceId: string;
  role: string;
  captureMode: string;
  deviceZoomFactor: number;
  displayZoom: string;
};

export type CaptureMetadata = {
  id: string;
  sourceUri: string;
  thumbnailUri: string | null;
  width: number;
  height: number;
  capturedAt: string;
  lensId: string;
  physicalDeviceId: string;
  captureMode: CameraCaptureMode;
  deviceZoomFactor: number;
  sourceSafe: boolean;
  complete: boolean;
  recoverableError: string | null;
};

export type CameraTelemetry = {
  iso: number;
  shutterSeconds: number;
  lensDisplay: string;
  captureExposureCompensationEV: number;
};

export type CameraPerformanceMetrics = {
  previewFPS: number;
  renderFPS: number;
  renderMilliseconds: number;
  droppedFrames: number;
  activeLens: string;
  cameraState: string;
};

export type ExposureCapabilities = {
  minimumEV: number;
  maximumEV: number;
  appliedEV: number;
};

export type CameraViewState = {
  permission: CameraPermissionStatus;
  lifecycle: CameraLifecycle;
  lenses: CameraLens[];
  selectedLensId: string | null;
  pendingLensId: string | null;
  exposure: ExposureCapabilities | null;
  pendingExposureEV: number | null;
  captureInProgress: boolean;
  lastCapture: CaptureMetadata | null;
  telemetry: CameraTelemetry | null;
  performance: CameraPerformanceMetrics | null;
  lastError: CameraErrorCode | null;
};

export type CameraAction =
  | {type: 'permissionRequestStarted'}
  | {type: 'permissionChanged'; value: CameraPermissionStatus}
  | {type: 'cameraLifecycleChanged'; value: CameraLifecycle}
  | {type: 'lensesChanged'; value: CameraLens[]}
  | {type: 'lensSelectionRequested'; id: string}
  | {type: 'lensSelectionFailed'; id: string; code: CameraErrorCode}
  | {type: 'cameraError'; code: CameraErrorCode}
  | {type: 'activeLensChanged'; id: string}
  | {type: 'exposureChanged'; value: ExposureCapabilities}
  | {type: 'exposureRequested'; value: number}
  | {type: 'captureRequested'}
  | {type: 'captureCompleted'; value: CaptureMetadata}
  | {type: 'captureFailed'; code: CameraErrorCode}
  | {type: 'telemetryChanged'; value: CameraTelemetry}
  | {type: 'performanceChanged'; value: CameraPerformanceMetrics};

export const initialCameraState: CameraViewState = {
  permission: 'unknown',
  lifecycle: {type: 'idle'},
  lenses: [],
  selectedLensId: null,
  pendingLensId: null,
  exposure: null,
  pendingExposureEV: null,
  captureInProgress: false,
  lastCapture: null,
  telemetry: null,
  performance: null,
  lastError: null,
};

export function parsePermissionStatus(value: string): CameraPermissionStatus {
  switch (value) {
    case 'notDetermined':
    case 'authorized':
    case 'denied':
    case 'restricted':
      return value;
    default:
      return 'unknown';
  }
}

const CAMERA_ERROR_CODES: CameraErrorCode[] = [
  'permissionDenied',
  'sessionConfigurationFailed',
  'cameraUnavailable',
  'lensSwitchFailed',
  'focusFailed',
  'exposureFailed',
  'captureFailed',
  'sourcePersistenceFailed',
  'rendererFailed',
  'interrupted',
];

export function parseCameraErrorCode(value: string, fallback: CameraErrorCode): CameraErrorCode {
  return CAMERA_ERROR_CODES.includes(value as CameraErrorCode) ? (value as CameraErrorCode) : fallback;
}

export function cameraLifecycleFromNative(
  state: string,
  reason: string,
  code: string,
): CameraLifecycle {
  switch (state) {
    case 'configuring': return {type: 'configuring'};
    case 'running': return {type: 'running'};
    case 'interrupted': return {type: 'interrupted', reason: reason || 'Camera interrupted'};
    case 'idle': return {type: 'idle'};
    case 'failed': return {type: 'failed', code: parseCameraErrorCode(code, 'cameraUnavailable')};
    default: return {type: 'failed', code: 'cameraUnavailable'};
  }
}

export function parseCaptureMetadata(raw: string): CaptureMetadata | null {
  try {
    const value: unknown = JSON.parse(raw);
    if (typeof value !== 'object' || value === null) {
      return null;
    }
    const capture = value as Partial<CaptureMetadata>;
    const width = typeof capture.width === 'number' && Number.isFinite(capture.width)
      ? capture.width
      : -1;
    const height = typeof capture.height === 'number' && Number.isFinite(capture.height)
      ? capture.height
      : -1;
    const sourceSafe = capture.sourceSafe !== false;
    const complete = capture.complete !== false;
    const captureMode = capture.captureMode === 'mainSensorCrop'
      ? 'mainSensorCrop'
      : 'physicalCamera';
    const deviceZoomFactor = typeof capture.deviceZoomFactor === 'number' &&
      Number.isFinite(capture.deviceZoomFactor) && capture.deviceZoomFactor > 0
      ? capture.deviceZoomFactor
      : 1;
    if (
      typeof capture.id !== 'string' ||
      typeof capture.sourceUri !== 'string' ||
      !capture.sourceUri.startsWith('file://') ||
      width < 0 || height < 0 || (complete && (width === 0 || height === 0)) ||
      typeof capture.capturedAt !== 'string' ||
      typeof capture.lensId !== 'string' ||
      !sourceSafe
    ) {
      return null;
    }
    return {
      id: capture.id,
      sourceUri: capture.sourceUri,
      thumbnailUri: typeof capture.thumbnailUri === 'string' && capture.thumbnailUri.length > 0
        ? capture.thumbnailUri
        : null,
      width,
      height,
      capturedAt: capture.capturedAt,
      lensId: capture.lensId,
      physicalDeviceId: typeof capture.physicalDeviceId === 'string' ? capture.physicalDeviceId : '',
      captureMode,
      deviceZoomFactor,
      sourceSafe,
      complete,
      recoverableError: typeof capture.recoverableError === 'string' && capture.recoverableError.length > 0
        ? capture.recoverableError
        : null,
    };
  } catch {
    return null;
  }
}

export function clampCaptureExposureEV(
  value: number,
  minimumEV: number,
  maximumEV: number,
): number {
  if (!Number.isFinite(value)) {
    return Math.min(maximumEV, Math.max(minimumEV, 0));
  }
  return Math.min(maximumEV, Math.max(minimumEV, value));
}

export function permissionPresentation(
  permission: CameraPermissionStatus,
): 'loading' | 'request' | 'openSettings' | 'camera' {
  switch (permission) {
    case 'unknown':
    case 'requesting':
      return 'loading';
    case 'notDetermined':
      return 'request';
    case 'denied':
    case 'restricted':
      return 'openSettings';
    case 'authorized':
      return 'camera';
  }
}

export function mapAvailableLenses(lenses: NativeLensPayload[]): CameraLens[] {
  const mapped = lenses.flatMap(lens => {
    if (
      !lens.id || !lens.physicalDeviceId || !lens.displayZoom ||
      !Number.isFinite(lens.deviceZoomFactor) || lens.deviceZoomFactor <= 0 ||
      !isCaptureMode(lens.captureMode)
    ) {
      return [];
    }
    return [{
      id: lens.id,
      physicalDeviceId: lens.physicalDeviceId,
      role: isLensRole(lens.role) ? lens.role : 'wide',
      captureMode: lens.captureMode,
      deviceZoomFactor: lens.deviceZoomFactor,
      displayZoom: lens.displayZoom,
    }];
  });
  mapped.sort((left, right) =>
    zoomValue(left.displayZoom) - zoomValue(right.displayZoom) ||
    left.physicalDeviceId.localeCompare(right.physicalDeviceId) ||
    left.id.localeCompare(right.id),
  );
  const seenModes = new Set<string>();
  return mapped.filter(lens => {
    const semanticButton = lens.displayZoom;
    if (seenModes.has(semanticButton)) {
      return false;
    }
    seenModes.add(semanticButton);
    return true;
  });
}

function isLensRole(value: string): value is LensRole {
  return value === 'ultraWide' || value === 'wide' || value === 'telephoto';
}

function isCaptureMode(value: string): value is CameraCaptureMode {
  return value === 'physicalCamera' || value === 'mainSensorCrop';
}

export function parseCameraCaptureMode(value: string): CameraCaptureMode {
  return isCaptureMode(value) ? value : 'physicalCamera';
}

function zoomValue(label: string): number {
  const parsed = Number(label.replace('×', ''));
  return Number.isFinite(parsed) ? parsed : Number.MAX_SAFE_INTEGER;
}

export function cameraReducer(
  state: CameraViewState,
  action: CameraAction,
): CameraViewState {
  switch (action.type) {
    case 'permissionRequestStarted':
      return {...state, permission: 'requesting'};
    case 'permissionChanged':
      return {...state, permission: action.value};
    case 'cameraLifecycleChanged':
      return {
        ...state,
        lifecycle: action.value,
        lastError: action.value.type === 'failed' ? action.value.code : null,
      };
    case 'lensesChanged': {
      const lenses = action.value;
      const retainedActiveLens = lenses.some(lens => lens.id === state.selectedLensId)
        ? state.selectedLensId
        : null;
      const retainedPendingLens = lenses.some(lens => lens.id === state.pendingLensId)
        ? state.pendingLensId
        : null;
      return {
        ...state,
        lenses,
        selectedLensId: retainedActiveLens,
        pendingLensId: retainedPendingLens,
      };
    }
    case 'lensSelectionRequested':
      return state.lenses.some(lens => lens.id === action.id)
        ? {...state, pendingLensId: action.id}
        : state;
    case 'lensSelectionFailed':
      return state.pendingLensId === action.id
        ? {...state, pendingLensId: null, lastError: action.code}
        : state;
    case 'cameraError':
      return {
        ...state,
        lastError: action.code,
        pendingExposureEV: action.code === 'exposureFailed' ? null : state.pendingExposureEV,
      };
    case 'activeLensChanged':
      return state.lenses.some(lens => lens.id === action.id)
        ? {...state, selectedLensId: action.id, pendingLensId: null, lastError: null}
        : state;
    case 'exposureChanged':
      return {
        ...state,
        exposure: action.value,
        pendingExposureEV: null,
        lastError: null,
      };
    case 'exposureRequested':
      if (state.exposure === null) {
        return state;
      }
      return {
        ...state,
        pendingExposureEV: clampCaptureExposureEV(
          action.value,
          state.exposure.minimumEV,
          state.exposure.maximumEV,
        ),
      };
    case 'captureRequested':
      return {...state, captureInProgress: true, lastError: null};
    case 'captureCompleted':
      return {
        ...state,
        captureInProgress: false,
        lastCapture: action.value,
        lastError: null,
      };
    case 'captureFailed':
      return {
        ...state,
        captureInProgress: false,
        lastError: action.code,
      };
    case 'telemetryChanged':
      return {...state, telemetry: action.value};
    case 'performanceChanged':
      return {...state, performance: action.value};
  }
}
