export const colors = {
  background: '#111316',
  substrate: '#0c0e11',
  surface: '#1a1c1f',
  surfaceRaised: '#282a2d',
  surfaceHighest: '#333538',
  foreground: '#e2e2e6',
  muted: '#d9c2b2',
  quiet: '#8a8d95',
  outline: '#544437',
  amber: '#ffb77b',
  amberStrong: '#e58e3c',
  critical: '#ffb4ab',
  teal: '#69d9c5',
  black: '#000000',
  transparent: 'transparent',
  scrim: 'rgba(12, 14, 17, 0.72)',
  scrimStrong: 'rgba(12, 14, 17, 0.82)',
  outlineFaint: 'rgba(226, 226, 230, 0.18)',
  outlineSubtle: 'rgba(226, 226, 230, 0.4)',
} as const;

export type ChemColor = keyof typeof colors;
