import React from 'react';
import {Image, Pressable, StyleSheet, View} from 'react-native';
import {ChemText} from '../../../design-system/components/ChemText';
import {colors} from '../../../design-system/colors';
import {radius} from '../../../design-system/radius';
import {spacing} from '../../../design-system/spacing';
import type {CaptureMetadata} from '../camera.types';

export function LastCaptureButton({
  capture,
  onPress,
}: {
  capture: CaptureMetadata | null;
  onPress: () => void;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={capture === null ? 'No recent capture' : 'Open most recent capture'}
      accessibilityState={{disabled: capture === null}}
      disabled={capture === null}
      onPress={onPress}
      style={styles.container}>
      <View style={styles.thumbnail}>
        {capture?.thumbnailUri ? (
          <Image source={{uri: capture.thumbnailUri}} resizeMode="cover" style={styles.image} />
        ) : (
          <View style={styles.emptyMark} />
        )}
      </View>
      <ChemText variant="labelSmall" tone="muted">LAST FRAME</ChemText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {alignItems: 'center', gap: spacing.xs, width: 84},
  thumbnail: {
    width: 58,
    height: 58,
    overflow: 'hidden',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.surface,
    borderRadius: radius.card,
    borderWidth: 1,
    borderColor: colors.outline,
  },
  image: {width: '100%', height: '100%'},
  emptyMark: {
    width: spacing.lg,
    height: spacing.lg,
    borderWidth: 1,
    borderColor: colors.quiet,
    borderRadius: radius.pill,
  },
});
