import React from 'react';
import {StyleSheet, View} from 'react-native';
import {ChemText} from '../../../design-system/components/ChemText';
import {colors} from '../../../design-system/colors';
import {spacing} from '../../../design-system/spacing';
import type {CameraTelemetry} from '../camera.types';

export function CameraTelemetry({value}: {value: CameraTelemetry | null}) {
  if (value === null) {
    return (
      <View style={styles.row}>
        <ChemText variant="labelSmall" tone="quiet">LIVE METERING</ChemText>
        <ChemText variant="labelSmall" tone="quiet">—</ChemText>
      </View>
    );
  }

  return (
    <View style={styles.row}>
      <Readout label="ISO" value={String(Math.round(value.iso))} />
      <Readout label="SHUTTER" value={formatShutter(value.shutterSeconds)} />
      <Readout label="LENS" value={value.lensDisplay} />
    </View>
  );
}

function Readout({label, value}: {label: string; value: string}) {
  return (
    <View style={styles.readout}>
      <ChemText variant="labelSmall" tone="quiet">{label}</ChemText>
      <ChemText variant="telemetrySmall">{value}</ChemText>
    </View>
  );
}

function formatShutter(seconds: number): string {
  if (!Number.isFinite(seconds) || seconds <= 0) {
    return '—';
  }
  if (seconds < 1) {
    return `1/${Math.max(1, Math.round(1 / seconds))}s`;
  }
  return `${seconds.toFixed(1)}s`;
}

const styles = StyleSheet.create({
  row: {
    minHeight: 44,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: spacing.sm,
    borderTopWidth: StyleSheet.hairlineWidth,
    borderColor: colors.outline,
  },
  readout: {gap: 2},
});
