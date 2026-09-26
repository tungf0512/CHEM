import React, {useState} from 'react';
import {
  ActivityIndicator,
  Pressable,
  StyleSheet,
  View,
} from 'react-native';
import {useSafeAreaInsets} from 'react-native-safe-area-context';
import CameraPreview from '../../specs/CHEMCameraNativeComponent';
import {ChemText} from '../../design-system/components/ChemText';
import {CropMarks} from '../../design-system/components/CropMarks';
import {FocusIndicator} from '../../design-system/components/FocusIndicator';
import {ShutterButton} from '../../design-system/components/ShutterButton';
import {StatusDot} from '../../design-system/components/StatusDot';
import {colors} from '../../design-system/colors';
import {radius} from '../../design-system/radius';
import {spacing} from '../../design-system/spacing';
import {CameraTelemetry} from './components/CameraTelemetry';
import {CapturePreviewModal} from './components/CapturePreviewModal';
import {CameraDebugOverlay} from './components/CameraDebugOverlay';
import {CameraTopBar} from './components/CameraTopBar';
import {ExposureControl} from './components/ExposureControl';
import {LastCaptureButton} from './components/LastCaptureButton';
import {LensSelector} from './components/LensSelector';
import {errorLabel, useCameraController} from './useCameraController';

export function CameraScreen() {
  const insets = useSafeAreaInsets();
  const camera = useCameraController();
  const [showDebugMetrics, setShowDebugMetrics] = useState(false);
  const [showCapturePreview, setShowCapturePreview] = useState(false);
  const {state} = camera;

  return (
    <View style={[styles.screen, {paddingTop: insets.top, paddingBottom: insets.bottom}]}>
      <CameraTopBar
        connected={camera.cameraConnected}
        debugEnabled={showDebugMetrics}
        onToggleDebug={() => setShowDebugMetrics(value => !value)}
      />

      <View style={styles.viewfinderShell}>
        <View style={styles.preview} onLayout={camera.onPreviewLayout}>
          {camera.nativeCameraActive ? (
            <CameraPreview
              ref={camera.cameraRef}
              active={camera.nativeCameraActive}
              onCameraStateChanged={camera.onCameraStateChanged}
              onAvailableLensesChanged={camera.onAvailableLensesChanged}
              onActiveLensChanged={camera.onActiveLensChanged}
              onCaptureCompleted={camera.onCaptureCompleted}
              onCaptureFailed={camera.onCaptureFailed}
              onLensSelectionFailed={camera.onLensSelectionFailed}
              onCameraError={camera.onCameraError}
              onExposureChanged={camera.onExposureChanged}
              onTelemetryChanged={camera.onTelemetryChanged}
              onPerformanceMetricsChanged={__DEV__ ? camera.onPerformanceMetricsChanged : undefined}
              onTouchEnd={camera.onPreviewTouch}
              style={StyleSheet.absoluteFill}
            />
          ) : (
            <PermissionState
              state={camera.cameraNativeSupported ? camera.presentation : 'unsupported'}
              onRequest={camera.requestPermission}
              onOpenSettings={camera.openSettings}
            />
          )}
          <CropMarks />
          {camera.nativeCameraActive && state.lifecycle.type !== 'running' && (
            <View pointerEvents="none" style={styles.nativeStatus}>
              <StatusDot tone={state.lifecycle.type === 'failed' ? 'critical' : 'amber'} size={7} />
              <ChemText variant="labelSmall" tone={state.lifecycle.type === 'failed' ? 'critical' : 'muted'}>
                {camera.lifecycleLabel}
              </ChemText>
            </View>
          )}
          {camera.nativeCameraActive && state.lifecycle.type === 'failed' && (
            <View style={styles.unavailableOverlay} pointerEvents="none">
              <ChemText variant="label" tone="foreground">NATIVE CAMERA UNAVAILABLE</ChemText>
              <ChemText variant="bodySmall" tone="muted">{camera.lifecycleLabel}</ChemText>
            </View>
          )}
          <FocusIndicator point={camera.focusPoint} />
          {__DEV__ && showDebugMetrics && state.performance !== null && (
            <CameraDebugOverlay metrics={state.performance} />
          )}
          <View pointerEvents="none" style={styles.previewBadge}>
            <StatusDot tone="teal" size={6} />
            <ChemText variant="labelSmall" tone="muted">
              {camera.cameraConnected ? 'NEUTRAL PREVIEW' : 'PREVIEW NOT ACTIVE'}
            </ChemText>
          </View>
          <View pointerEvents="none" style={styles.filmNotice}>
            <ChemText variant="labelSmall" tone="quiet">FILM ENGINE NOT ACTIVE</ChemText>
          </View>
        </View>
      </View>

      <View style={styles.telemetryWrap}>
        <CameraTelemetry value={state.telemetry} />
      </View>
      <View style={styles.controls}>
        <View style={styles.lensRow}>
          <LensSelector
            lenses={state.lenses}
            selectedLensId={state.selectedLensId}
            pendingLensId={state.pendingLensId}
            disabled={!camera.cameraConnected}
            onSelect={camera.selectLens}
          />
        </View>
        <View style={styles.controlRow}>
          <LastCaptureButton capture={state.lastCapture} onPress={() => setShowCapturePreview(true)} />
          <ExposureControl
            exposure={state.exposure}
            pendingEV={state.pendingExposureEV}
            disabled={!camera.cameraConnected}
            onChange={camera.setExposure}
          />
          <ShutterButton
            disabled={!camera.cameraConnected || state.permission !== 'authorized'}
            busy={state.captureInProgress}
            onPress={camera.capture}
          />
        </View>
        {state.lastError !== null && (
          <ChemText accessibilityLiveRegion="polite" variant="labelSmall" tone="critical" style={styles.errorText}>
            {errorLabel(state.lastError)}
          </ChemText>
        )}
      </View>
      <CapturePreviewModal
        capture={state.lastCapture}
        visible={showCapturePreview}
        onClose={() => setShowCapturePreview(false)}
      />
    </View>
  );
}

function PermissionState({
  state,
  onRequest,
  onOpenSettings,
}: {
  state: 'loading' | 'request' | 'openSettings' | 'camera' | 'unsupported';
  onRequest: () => void;
  onOpenSettings: () => void;
}) {
  if (state === 'loading' || state === 'camera') {
    return (
      <View style={styles.permissionState}>
        <ActivityIndicator color={colors.amber} />
        <ChemText variant="labelSmall" tone="muted">CHECKING CAMERA</ChemText>
      </View>
    );
  }
  if (state === 'unsupported') {
    return (
      <View style={styles.permissionState}>
        <StatusDot tone="quiet" size={8} />
        <ChemText variant="label" tone="foreground">IOS CAMERA PREVIEW ONLY</ChemText>
        <ChemText variant="bodySmall" tone="muted" style={styles.permissionCopy}>
          The native camera foundation in this milestone is iOS-only.
        </ChemText>
      </View>
    );
  }
  const denied = state === 'openSettings';
  return (
    <View style={styles.permissionState}>
      <StatusDot tone={denied ? 'critical' : 'amber'} size={8} />
      <ChemText variant="label" tone="foreground">{denied ? 'CAMERA ACCESS REQUIRED' : 'ENABLE CAMERA'}</ChemText>
      <ChemText variant="bodySmall" tone="muted" style={styles.permissionCopy}>
        {denied
          ? 'Allow camera access in Settings to use the native viewfinder.'
          : 'CHEM uses the camera only for the live viewfinder and photos you choose to capture.'}
      </ChemText>
      <Pressable
        accessibilityRole="button"
        onPress={denied ? onOpenSettings : onRequest}
        style={styles.permissionButton}>
        <ChemText variant="labelSmall" tone="background">{denied ? 'OPEN SETTINGS' : 'ALLOW CAMERA'}</ChemText>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {flex: 1, backgroundColor: colors.background},
  viewfinderShell: {flex: 1, minHeight: 210, paddingHorizontal: spacing.md, paddingTop: spacing.sm},
  preview: {flex: 1, overflow: 'hidden', backgroundColor: colors.substrate, borderRadius: radius.viewfinder},
  previewBadge: {
    position: 'absolute', top: spacing.xl, left: spacing.xl,
    flexDirection: 'row', alignItems: 'center', gap: spacing.xs,
    paddingHorizontal: spacing.sm, paddingVertical: spacing.xs,
    backgroundColor: colors.scrimStrong, borderRadius: radius.standard,
  },
  filmNotice: {
    position: 'absolute', bottom: spacing.xl, alignSelf: 'center',
    paddingHorizontal: spacing.sm, paddingVertical: spacing.xs,
    backgroundColor: colors.scrim, borderRadius: radius.standard,
  },
  nativeStatus: {
    position: 'absolute', top: spacing.xl, right: spacing.xl,
    flexDirection: 'row', alignItems: 'center', gap: spacing.xs,
    paddingHorizontal: spacing.sm, paddingVertical: spacing.xs,
    backgroundColor: colors.scrimStrong, borderRadius: radius.standard,
  },
  unavailableOverlay: {
    ...StyleSheet.absoluteFill,
    alignItems: 'center', justifyContent: 'center', gap: spacing.sm,
    padding: spacing.xl,
  },
  permissionState: {
    ...StyleSheet.absoluteFill,
    alignItems: 'center', justifyContent: 'center', gap: spacing.md,
    padding: spacing.xxl, backgroundColor: colors.substrate,
  },
  permissionCopy: {maxWidth: 280, textAlign: 'center', lineHeight: 20},
  permissionButton: {
    minHeight: 44, paddingHorizontal: spacing.xl, alignItems: 'center', justifyContent: 'center',
    backgroundColor: colors.amber, borderRadius: radius.standard,
  },
  telemetryWrap: {paddingHorizontal: spacing.md},
  controls: {paddingHorizontal: spacing.base, paddingTop: spacing.sm, paddingBottom: spacing.md, gap: spacing.md},
  lensRow: {alignItems: 'center'},
  controlRow: {minHeight: 92, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between'},
  errorText: {textAlign: 'center', paddingBottom: spacing.xs},
});
