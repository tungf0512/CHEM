import type {TextStyle} from 'react-native';

// CHEM uses the platform sans face and Menlo until licensed Inter/JetBrains Mono assets exist.
const mono = 'Menlo';

export const typography = {
  display: {
    fontSize: 20,
    lineHeight: 26,
    fontWeight: '600',
  } satisfies TextStyle,
  body: {
    fontSize: 14,
    lineHeight: 20,
    fontWeight: '400',
  } satisfies TextStyle,
  bodySmall: {
    fontSize: 12,
    lineHeight: 16,
    fontWeight: '400',
  } satisfies TextStyle,
  label: {
    fontFamily: mono,
    fontSize: 12,
    lineHeight: 16,
    fontWeight: '500',
    letterSpacing: 0.8,
  } satisfies TextStyle,
  labelSmall: {
    fontFamily: mono,
    fontSize: 10,
    lineHeight: 14,
    fontWeight: '600',
    letterSpacing: 0.8,
  } satisfies TextStyle,
  telemetry: {
    fontFamily: mono,
    fontSize: 18,
    lineHeight: 22,
    fontWeight: '600',
    fontVariant: ['tabular-nums'],
  } satisfies TextStyle,
  telemetrySmall: {
    fontFamily: mono,
    fontSize: 14,
    lineHeight: 18,
    fontWeight: '600',
    fontVariant: ['tabular-nums'],
  } satisfies TextStyle,
} as const;
