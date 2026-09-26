import React from 'react';
import {Pressable, StyleSheet, View} from 'react-native';
import {ChemText} from '../../../design-system/components/ChemText';
import {colors} from '../../../design-system/colors';
import {radius} from '../../../design-system/radius';
import {spacing} from '../../../design-system/spacing';
import {clampCaptureExposureEV, type ExposureCapabilities} from '../camera.types';

const EV_STEP = 0.3;

export function ExposureControl({
  exposure,
  pendingEV,
  disabled,
  onChange,
}: {
  exposure: ExposureCapabilities | null;
  pendingEV: number | null;
  disabled: boolean;
  onChange: (value: number) => void;
}) {
  if (exposure === null) {
    return (
      <View style={styles.unavailable}>
        <ChemText variant="labelSmall" tone="quiet">EV CONTROL UNAVAILABLE</ChemText>
      </View>
    );
  }

  const current = pendingEV ?? exposure.appliedEV;
  const adjust = (direction: -1 | 1) => {
    onChange(
      clampCaptureExposureEV(
        current + direction * EV_STEP,
        exposure.minimumEV,
        exposure.maximumEV,
      ),
    );
  };

  return (
    <View style={styles.row}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Decrease capture exposure compensation"
        accessibilityState={{disabled: disabled || current <= exposure.minimumEV}}
        disabled={disabled || current <= exposure.minimumEV}
        onPress={() => adjust(-1)}
        style={styles.stepButton}>
        <ChemText variant="telemetry">−</ChemText>
      </Pressable>
      <View style={styles.value}>
        <ChemText variant="labelSmall" tone="quiet">CAPTURE EV</ChemText>
        <ChemText variant="telemetry" tone="amber">
          {pendingEV === null ? formatEV(exposure.appliedEV) : 'APPLYING'}
        </ChemText>
      </View>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel="Increase capture exposure compensation"
        accessibilityState={{disabled: disabled || current >= exposure.maximumEV}}
        disabled={disabled || current >= exposure.maximumEV}
        onPress={() => adjust(1)}
        style={styles.stepButton}>
        <ChemText variant="telemetry">+</ChemText>
      </Pressable>
    </View>
  );
}

function formatEV(value: number): string {
  const normalized = Math.abs(value) < 0.05 ? 0 : value;
  return `${normalized > 0 ? '+' : ''}${normalized.toFixed(1)} EV`;
}

const styles = StyleSheet.create({
  row: {flexDirection: 'row', alignItems: 'center', gap: spacing.sm},
  unavailable: {minHeight: 44, justifyContent: 'center'},
  stepButton: {
    width: 42,
    height: 42,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.surfaceRaised,
    borderRadius: radius.standard,
    borderWidth: 1,
    borderColor: colors.outline,
  },
  value: {minWidth: 96, alignItems: 'center', gap: 2},
});
