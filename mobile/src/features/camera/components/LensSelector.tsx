import React from 'react';
import {Pressable, ScrollView, StyleSheet, View} from 'react-native';
import {ChemText} from '../../../design-system/components/ChemText';
import {colors} from '../../../design-system/colors';
import {radius} from '../../../design-system/radius';
import {spacing} from '../../../design-system/spacing';
import type {CameraLens} from '../camera.types';

export function LensSelector({
  lenses,
  selectedLensId,
  pendingLensId,
  disabled,
  onSelect,
}: {
  lenses: CameraLens[];
  selectedLensId: string | null;
  pendingLensId: string | null;
  disabled: boolean;
  onSelect: (lens: CameraLens) => void;
}) {
  if (lenses.length === 0) {
    return <ChemText variant="labelSmall" tone="quiet">LENSES UNAVAILABLE</ChemText>;
  }

  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      contentContainerStyle={styles.container}
      accessibilityLabel="Available camera lenses">
      {lenses.map(lens => {
        const selected = selectedLensId === lens.id;
        const pending = pendingLensId === lens.id;
        return (
          <Pressable
            key={lens.id}
            accessibilityRole="button"
            accessibilityLabel={`${lens.displayZoom} lens`}
            accessibilityState={{selected, disabled: disabled || pending}}
            disabled={disabled || pending}
            onPress={() => onSelect(lens)}
            style={[styles.button, selected && styles.selected, pending && styles.pending]}>
            <ChemText variant="label" tone={selected ? 'foreground' : 'muted'}>
              {lens.displayZoom}
            </ChemText>
          </Pressable>
        );
      })}
      <View style={styles.roleHint}>
        <ChemText variant="labelSmall" tone="quiet">LENS</ChemText>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    padding: spacing.xs,
    gap: spacing.xs,
    backgroundColor: colors.substrate,
    borderRadius: radius.pill,
  },
  button: {
    minWidth: 44,
    height: 38,
    paddingHorizontal: spacing.sm,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: radius.pill,
    borderWidth: 1,
    borderColor: colors.transparent,
  },
  selected: {
    backgroundColor: colors.surfaceHighest,
    borderColor: colors.outlineFaint,
  },
  pending: {opacity: 0.55},
  roleHint: {paddingHorizontal: spacing.xs},
});
