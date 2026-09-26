import React, {useCallback, useEffect, useMemo, useReducer, useRef, useState} from 'react';
import {
  AppState,
  Linking,
  Platform,
  type LayoutChangeEvent,
  type NativeSyntheticEvent,
  type NativeTouchEvent,
} from 'react-native';
import CameraModule from '../../specs/NativeCHEMCameraModule';
import CameraPreview, {
  Commands,
  type ActiveLensEvent,
  type CameraErrorEvent,
  type CameraLifecycleEvent,
  type CaptureCompletedEvent,
  type CaptureFailedEvent,
  type ExposureEvent,
  type LensSelectionFailedEvent,
  type LensesEvent,
  type PerformanceMetricsEvent,
  type TelemetryEvent,
} from '../../specs/CHEMCameraNativeComponent';
import {
  cameraLifecycleFromNative,
  cameraReducer,
  clampCaptureExposureEV,
  initialCameraState,
  mapAvailableLenses,
  parseCameraErrorCode,
  parseCameraCaptureMode,
  parseCaptureMetadata,
  parsePermissionStatus,
  permissionPresentation,
  type CameraErrorCode,
  type CameraLens,
} from './camera.types';
import {logCameraEvent} from './cameraLogger';

export function useCameraController() {
  const [state, dispatch] = useReducer(cameraReducer, initialCameraState);
  const cameraRef = useRef<React.ElementRef<typeof CameraPreview>>(null);
  const [appIsActive, setAppIsActive] = useState(AppState.currentState === 'active');
  const [previewSize, setPreviewSize] = useState({width: 0, height: 0});
  const [focusPoint, setFocusPoint] = useState<{x: number; y: number} | null>(null);
  const presentation = permissionPresentation(state.permission);
  const cameraNativeSupported = Platform.OS === 'ios' && CameraModule !== null;
  const nativeCameraActive = cameraNativeSupported && state.permission === 'authorized' && appIsActive;
  const cameraConnected = state.lifecycle.type === 'running';

  useEffect(() => {
    let mounted = true;
    if (CameraModule !== null && Platform.OS === 'ios') {
      CameraModule.getCameraPermissionStatus()
        .then(value => {
          if (mounted) {
            const permission = parsePermissionStatus(value);
            logCameraEvent('permission_status', {permission});
            dispatch({type: 'permissionChanged', value: permission});
          }
        })
        .catch(() => {
          if (mounted) {
            dispatch({type: 'permissionChanged', value: 'unknown'});
          }
        });
      CameraModule.getLastCapture()
        .then(raw => {
          if (!mounted || raw.length === 0) {
            return;
          }
          const capture = parseCaptureMetadata(raw);
          if (capture !== null) {
            logCameraEvent('capture_completed', {captureId: capture.id, restored: 1});
            dispatch({type: 'captureCompleted', value: capture});
          }
        })
        .catch(() => undefined);
    }
    const subscription = AppState.addEventListener('change', nextState => {
      setAppIsActive(nextState === 'active');
      if (nextState === 'active' && CameraModule !== null && Platform.OS === 'ios') {
        CameraModule.getCameraPermissionStatus()
          .then(value => {
            if (mounted) {
              const permission = parsePermissionStatus(value);
              logCameraEvent('permission_status', {permission});
              dispatch({type: 'permissionChanged', value: permission});
            }
          })
          .catch(() => undefined);
      }
    });
    return () => {
      mounted = false;
      subscription.remove();
    };
  }, []);

  const requestPermission = useCallback(async () => {
    logCameraEvent('permission_request');
    dispatch({type: 'permissionRequestStarted'});
    try {
      if (CameraModule === null || Platform.OS !== 'ios') {
        return;
      }
      const value = await CameraModule.requestCameraPermission();
      const permission = parsePermissionStatus(value);
      logCameraEvent('permission_status', {permission});
      dispatch({type: 'permissionChanged', value: permission});
    } catch {
      dispatch({type: 'permissionChanged', value: 'denied'});
    }
  }, []);

  const openSettings = useCallback(() => {
    Linking.openSettings().catch(() => undefined);
  }, []);

  const onCameraStateChanged = useCallback(
    (event: NativeSyntheticEvent<CameraLifecycleEvent>) => {
      const {state: nativeState, reason, code} = event.nativeEvent;
      logCameraEvent('lifecycle', {state: nativeState, code});
      dispatch({
        type: 'cameraLifecycleChanged',
        value: cameraLifecycleFromNative(nativeState, reason, code),
      });
    },
    [],
  );

  const onAvailableLensesChanged = useCallback(
    (event: NativeSyntheticEvent<LensesEvent>) => {
      dispatch({type: 'lensesChanged', value: mapAvailableLenses(event.nativeEvent.lenses)});
    },
    [],
  );

  const onActiveLensChanged = useCallback((event: NativeSyntheticEvent<ActiveLensEvent>) => {
    dispatch({type: 'activeLensChanged', id: event.nativeEvent.id});
  }, []);

  const onCaptureCompleted = useCallback(
    (event: NativeSyntheticEvent<CaptureCompletedEvent>) => {
      const capture: CaptureCompletedEvent = event.nativeEvent;
      logCameraEvent('capture_completed', {captureId: capture.id, restored: 0});
      dispatch({
        type: 'captureCompleted',
        value: {
          ...capture,
          thumbnailUri: capture.thumbnailUri || null,
          captureMode: parseCameraCaptureMode(capture.captureMode),
          recoverableError: capture.recoverableError || null,
        },
      });
    },
    [],
  );

  const onCaptureFailed = useCallback((event: NativeSyntheticEvent<CaptureFailedEvent>) => {
    const code = parseCameraErrorCode(event.nativeEvent.code, 'captureFailed');
    logCameraEvent('capture_failed', {code});
    dispatch({type: 'captureFailed', code});
  }, []);

  const onLensSelectionFailed = useCallback((event: NativeSyntheticEvent<LensSelectionFailedEvent>) => {
    dispatch({
      type: 'lensSelectionFailed',
      id: event.nativeEvent.id,
      code: parseCameraErrorCode(event.nativeEvent.code, 'lensSwitchFailed'),
    });
  }, []);

  const onCameraError = useCallback((event: NativeSyntheticEvent<CameraErrorEvent>) => {
    dispatch({type: 'cameraError', code: parseCameraErrorCode(event.nativeEvent.code, 'cameraUnavailable')});
  }, []);

  const onExposureChanged = useCallback((event: NativeSyntheticEvent<ExposureEvent>) => {
    dispatch({type: 'exposureChanged', value: event.nativeEvent});
  }, []);

  const onTelemetryChanged = useCallback((event: NativeSyntheticEvent<TelemetryEvent>) => {
    dispatch({
      type: 'telemetryChanged',
      value: {
        iso: event.nativeEvent.iso,
        shutterSeconds: event.nativeEvent.shutterSeconds,
        lensDisplay: event.nativeEvent.lensDisplay,
        captureExposureCompensationEV: event.nativeEvent.captureExposureCompensationEV,
      },
    });
  }, []);

  const onPerformanceMetricsChanged = useCallback(
    (event: NativeSyntheticEvent<PerformanceMetricsEvent>) => {
      dispatch({type: 'performanceChanged', value: event.nativeEvent});
    },
    [],
  );

  const selectLens = useCallback((lens: CameraLens) => {
    const ref = cameraRef.current;
    if (ref === null) {
      return;
    }
    dispatch({type: 'lensSelectionRequested', id: lens.id});
    Commands.selectLens(ref, lens.id);
  }, []);

  const setExposure = useCallback((value: number) => {
    const ref = cameraRef.current;
    if (ref === null || state.exposure === null) {
      return;
    }
    const ev = clampCaptureExposureEV(value, state.exposure.minimumEV, state.exposure.maximumEV);
    dispatch({type: 'exposureRequested', value: ev});
    Commands.setExposureCompensation(ref, ev);
  }, [state.exposure]);

  const capture = useCallback(() => {
    const ref = cameraRef.current;
    if (ref === null || !cameraConnected) {
      return;
    }
    logCameraEvent('capture_request');
    dispatch({type: 'captureRequested'});
    Commands.capture(ref);
  }, [cameraConnected]);

  const onPreviewLayout = useCallback((event: LayoutChangeEvent) => {
    const {width, height} = event.nativeEvent.layout;
    setPreviewSize({width, height});
  }, []);

  const onPreviewTouch = useCallback(
    (event: NativeSyntheticEvent<NativeTouchEvent>) => {
      if (!cameraConnected || previewSize.width <= 0 || previewSize.height <= 0) {
        return;
      }
      const {locationX, locationY} = event.nativeEvent;
      const x = Math.min(1, Math.max(0, locationX / previewSize.width));
      const y = Math.min(1, Math.max(0, locationY / previewSize.height));
      setFocusPoint({x, y});
      if (cameraRef.current !== null) {
        // Native maps these upright view coordinates through aspect-fill and sensor orientation.
        Commands.focusAndExpose(cameraRef.current, x, y);
      }
    },
    [cameraConnected, previewSize.height, previewSize.width],
  );

  const lifecycleLabel = useMemo(() => {
    if (state.lifecycle.type === 'interrupted') {
      return state.lifecycle.reason;
    }
    if (state.lifecycle.type === 'failed') {
      return errorLabel(state.lifecycle.code);
    }
    return state.lifecycle.type === 'running' ? 'CAMERA READY' : 'INITIALIZING NATIVE CAMERA';
  }, [state.lifecycle]);

  return {
    state,
    cameraRef,
    cameraNativeSupported,
    nativeCameraActive,
    cameraConnected,
    presentation,
    focusPoint,
    lifecycleLabel,
    requestPermission,
    openSettings,
    onCameraStateChanged,
    onAvailableLensesChanged,
    onActiveLensChanged,
    onCaptureCompleted,
    onCaptureFailed,
    onLensSelectionFailed,
    onCameraError,
    onExposureChanged,
    onTelemetryChanged,
    onPerformanceMetricsChanged,
    selectLens,
    setExposure,
    capture,
    onPreviewLayout,
    onPreviewTouch,
  };
}

export function errorLabel(code: CameraErrorCode): string {
  switch (code) {
    case 'permissionDenied': return 'CAMERA PERMISSION DENIED';
    case 'sessionConfigurationFailed': return 'CAMERA SETUP FAILED';
    case 'cameraUnavailable': return 'NO REAR CAMERA AVAILABLE';
    case 'lensSwitchFailed': return 'LENS SWITCH FAILED';
    case 'focusFailed': return 'FOCUS NOT APPLIED';
    case 'exposureFailed': return 'EXPOSURE NOT APPLIED';
    case 'captureFailed': return 'PHOTO CAPTURE FAILED';
    case 'sourcePersistenceFailed': return 'PHOTO COULD NOT BE SAVED';
    case 'rendererFailed': return 'PREVIEW RENDERER FAILED';
    case 'interrupted': return 'CAMERA INTERRUPTED';
  }
}
