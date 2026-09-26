import React from 'react';
import {StyleSheet, View} from 'react-native';
import {ChemText} from '../../../design-system/components/ChemText';
import {colors} from '../../../design-system/colors';
import {radius} from '../../../design-system/radius';
import {spacing} from '../../../design-system/spacing';
import type {CameraPerformanceMetrics} from '../camera.types';

export function CameraDebugOverlay({metrics}: {metrics: CameraPerformanceMetrics}) {
  return (
    <View pointerEvents="none" style={styles.panel}>
      <ChemText variant="labelSmall" tone="amber">NATIVE PREVIEW METRICS · DEV</ChemText>
      <View style={styles.row}>
        <Value label="PREVIEW" value={`${metrics.previewFPS} FPS`} />
        <Value label="RENDER" value={`${metrics.renderFPS} FPS`} />
        <Value label="GPU" value={`${metrics.renderMilliseconds.toFixed(1)} ms`} />
        <Value label="DROPPED" value={String(metrics.droppedFrames)} />
      </View>
      <ChemText variant="labelSmall" tone="quiet">
        {metrics.cameraState.toUpperCase()} · {metrics.activeLens || 'LENS —'}
      </ChemText>
    </View>
  );
}

function Value({label, value}: {label: string; value: string}) {
  return (
    <View style={styles.value}>
      <ChemText variant="labelSmall" tone="quiet">{label}</ChemText>
      <ChemText variant="telemetrySmall">{value}</ChemText>
    </View>
  );
}

const styles = StyleSheet.create({
  panel: {
    position: 'absolute',
    right: spacing.xl,
    bottom: spacing.xxl,
    left: spacing.xl,
    gap: spacing.xs,
    padding: spacing.sm,
    backgroundColor: colors.scrimStrong,
    borderWidth: 1,
    borderColor: colors.outline,
    borderRadius: radius.standard,
  },
  row: {flexDirection: 'row', justifyContent: 'space-between'},
  value: {gap: 2},
});
