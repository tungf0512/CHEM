import React from 'react';
import {StyleSheet, View} from 'react-native';
import {colors} from '../colors';
import {spacing} from '../spacing';

export function CropMarks() {
  return (
    <View pointerEvents="none" style={styles.frame}>
      <View style={[styles.corner, styles.topLeft]} />
      <View style={[styles.corner, styles.topRight]} />
      <View style={[styles.corner, styles.bottomLeft]} />
      <View style={[styles.corner, styles.bottomRight]} />
      <View style={styles.midLeft} />
      <View style={styles.midRight} />
    </View>
  );
}

const length = spacing.lg;
const corner = {
  position: 'absolute' as const,
  width: length,
  height: length,
  borderColor: colors.foreground,
};

const styles = StyleSheet.create({
  frame: {
    ...StyleSheet.absoluteFill,
    margin: spacing.md,
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: colors.outlineFaint,
  },
  corner: {...corner},
  topLeft: {
    top: -1,
    left: -1,
    borderTopWidth: 2,
    borderLeftWidth: 2,
  },
  topRight: {
    top: -1,
    right: -1,
    borderTopWidth: 2,
    borderRightWidth: 2,
  },
  bottomLeft: {
    bottom: -1,
    left: -1,
    borderBottomWidth: 2,
    borderLeftWidth: 2,
  },
  bottomRight: {
    bottom: -1,
    right: -1,
    borderBottomWidth: 2,
    borderRightWidth: 2,
  },
  midLeft: {
    position: 'absolute',
    left: 0,
    top: '50%',
    width: spacing.sm,
    height: StyleSheet.hairlineWidth,
    backgroundColor: colors.outlineSubtle,
  },
  midRight: {
    position: 'absolute',
    right: 0,
    top: '50%',
    width: spacing.sm,
    height: StyleSheet.hairlineWidth,
    backgroundColor: colors.outlineSubtle,
  },
});
