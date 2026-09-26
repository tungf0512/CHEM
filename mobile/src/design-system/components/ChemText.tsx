import React from 'react';
import {Text, type TextProps} from 'react-native';
import {colors} from '../colors';
import {typography} from '../typography';

type Variant = keyof typeof typography;

type ChemTextProps = TextProps & {
  variant?: Variant;
  tone?: keyof typeof colors;
};

export function ChemText({
  variant = 'body',
  tone = 'foreground',
  style,
  ...props
}: ChemTextProps) {
  return (
    <Text
      {...props}
      style={[typography[variant], {color: colors[tone]}, style]}
    />
  );
}
