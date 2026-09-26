import React, {useEffect, useRef} from 'react';
import {Animated, StyleSheet, View} from 'react-native';
import {colors} from '../colors';
import {motion} from '../motion';
import {spacing} from '../spacing';

export function FocusIndicator({
  point,
}: {
  point: {x: number; y: number} | null;
}) {
  const opacity = useRef(new Animated.Value(0)).current;
  const scale = useRef(new Animated.Value(1.12)).current;

  useEffect(() => {
    if (point === null) {
      opacity.stopAnimation();
      opacity.setValue(0);
      return;
    }
    scale.setValue(1.12);
    Animated.parallel([
      Animated.timing(opacity, {
        toValue: 1,
        duration: motion.quickMs,
        useNativeDriver: true,
      }),
      Animated.spring(scale, {
        toValue: 1,
        speed: 20,
        bounciness: 3,
        useNativeDriver: true,
      }),
    ]).start();
    const timer = setTimeout(() => {
      Animated.timing(opacity, {
        toValue: 0,
        duration: motion.standardMs,
        useNativeDriver: true,
      }).start();
    }, motion.focusHoldMs);
    return () => clearTimeout(timer);
  }, [opacity, point, scale]);

  if (point === null) {
    return null;
  }

  return (
    <Animated.View
      pointerEvents="none"
      style={[
        styles.reticle,
        {
          left: `${point.x * 100}%`,
          top: `${point.y * 100}%`,
          opacity,
          transform: [{translateX: -28}, {translateY: -28}, {scale}],
        },
      ]}>
      <View style={[styles.corner, styles.topLeft]} />
      <View style={[styles.corner, styles.topRight]} />
      <View style={[styles.corner, styles.bottomLeft]} />
      <View style={[styles.corner, styles.bottomRight]} />
      <View style={styles.center} />
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  reticle: {
    position: 'absolute',
    width: 56,
    height: 56,
    borderColor: colors.amber,
  },
  corner: {
    position: 'absolute',
    width: spacing.sm,
    height: spacing.sm,
    borderColor: colors.amber,
  },
  topLeft: {
    top: 0,
    left: 0,
    borderTopWidth: 2,
    borderLeftWidth: 2,
  },
  topRight: {
    top: 0,
    right: 0,
    borderTopWidth: 2,
    borderRightWidth: 2,
  },
  bottomLeft: {
    bottom: 0,
    left: 0,
    borderBottomWidth: 2,
    borderLeftWidth: 2,
  },
  bottomRight: {
    bottom: 0,
    right: 0,
    borderBottomWidth: 2,
    borderRightWidth: 2,
  },
  center: {
    position: 'absolute',
    width: 4,
    height: 4,
    borderRadius: 2,
    left: 26,
    top: 26,
    backgroundColor: colors.amber,
  },
});
