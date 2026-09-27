import React from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { ChemText } from '../../../design-system/components/ChemText';
import { StatusDot } from '../../../design-system/components/StatusDot';
import { colors } from '../../../design-system/colors';
import { radius } from '../../../design-system/radius';
import { spacing } from '../../../design-system/spacing';

export function CameraTopBar({
  connected,
  debugEnabled,
  onToggleDebug,
  onLongPressInternal,
}: {
  connected: boolean;
  debugEnabled: boolean;
  onToggleDebug: () => void;
  onLongPressInternal?: () => void;
}) {
  return (
    <View style={styles.row}>
      <Pressable
        accessibilityRole={onLongPressInternal ? 'button' : undefined}
        accessibilityLabel={
          onLongPressInternal ? 'Open internal camera diagnostics' : undefined
        }
        delayLongPress={800}
        onLongPress={onLongPressInternal}
        style={styles.brand}
      >
        <StatusDot tone={connected ? 'amber' : 'quiet'} size={8} />
        <ChemText variant="labelSmall" tone="amber">
          CHEM//OS
        </ChemText>
        <ChemText variant="display">Viewfinder</ChemText>
      </Pressable>
      <View style={styles.modePill}>
        <StatusDot tone="teal" size={6} />
        <ChemText variant="labelSmall" tone="muted">
          AUTO EXPOSURE
        </ChemText>
      </View>
      {__DEV__ && (
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={
            debugEnabled
              ? 'Hide native camera metrics'
              : 'Show native camera metrics'
          }
          accessibilityState={{ selected: debugEnabled }}
          onPress={onToggleDebug}
          style={styles.debugButton}
        >
          <ChemText
            variant="labelSmall"
            tone={debugEnabled ? 'amber' : 'quiet'}
          >
            METRICS
          </ChemText>
        </Pressable>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    minHeight: 58,
    paddingHorizontal: spacing.base,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: colors.background,
  },
  debugButton: { paddingHorizontal: spacing.xs, paddingVertical: spacing.xs },
  brand: { flexDirection: 'row', alignItems: 'center', gap: spacing.sm },
  modePill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    backgroundColor: colors.surfaceRaised,
    borderRadius: radius.card,
  },
});
