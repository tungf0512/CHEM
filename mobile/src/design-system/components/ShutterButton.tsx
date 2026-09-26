import React from 'react';
import {Pressable, StyleSheet, View} from 'react-native';
import {colors} from '../colors';
import {radius} from '../radius';
import {spacing} from '../spacing';

export function ShutterButton({
  disabled,
  busy,
  onPress,
}: {
  disabled: boolean;
  busy: boolean;
  onPress: () => void;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={busy ? 'Capturing photo' : 'Take photo'}
      accessibilityState={{disabled, busy}}
      disabled={disabled || busy}
      onPress={onPress}
      style={({pressed}) => [styles.shell, pressed && styles.pressed, disabled && styles.disabled]}>
      <View style={styles.innerRing}>
        <View style={[styles.core, busy && styles.busyCore]}>
          <View style={styles.centerMark} />
        </View>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  shell: {
    width: 84,
    height: 84,
    borderRadius: radius.pill,
    padding: spacing.xs,
    backgroundColor: colors.surfaceRaised,
    borderWidth: 1,
    borderColor: colors.outline,
  },
  pressed: {transform: [{scale: 0.94}]},
  disabled: {opacity: 0.45},
  innerRing: {
    flex: 1,
    borderRadius: radius.pill,
    padding: spacing.xs,
    backgroundColor: colors.substrate,
  },
  core: {
    flex: 1,
    borderRadius: radius.pill,
    backgroundColor: colors.foreground,
    alignItems: 'center',
    justifyContent: 'center',
  },
  busyCore: {backgroundColor: colors.amber},
  centerMark: {
    width: 24,
    height: 24,
    borderRadius: radius.pill,
    backgroundColor: colors.surfaceHighest,
  },
});
