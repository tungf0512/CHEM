import React from 'react';
import {View, type ViewStyle} from 'react-native';
import {colors, type ChemColor} from '../colors';
import {radius} from '../radius';

export function StatusDot({
  tone = 'amber',
  size = 7,
  style,
}: {
  tone?: ChemColor;
  size?: number;
  style?: ViewStyle;
}) {
  return (
    <View
      style={[
        {
          width: size,
          height: size,
          borderRadius: radius.pill,
          backgroundColor: colors[tone],
        },
        style,
      ]}
    />
  );
}
