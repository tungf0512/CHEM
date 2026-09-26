/**
 * @format
 */

import React from 'react';
import ReactTestRenderer from 'react-test-renderer';
import App from '../App';

jest.mock('react-native-safe-area-context', () => ({
  SafeAreaProvider: ({children}: {children: React.ReactNode}) => children,
  useSafeAreaInsets: () => ({top: 0, right: 0, bottom: 0, left: 0}),
}));

jest.mock('../src/specs/NativeCHEMCameraModule', () => ({
  __esModule: true,
  default: null,
}));

jest.mock('../src/specs/CHEMCameraNativeComponent', () => {
  const {View: NativeView} = require('react-native');
  return {
    __esModule: true,
    default: NativeView,
    Commands: {
      start: jest.fn(),
      stop: jest.fn(),
      selectLens: jest.fn(),
      focusAndExpose: jest.fn(),
      setExposureCompensation: jest.fn(),
      capture: jest.fn(),
    },
  };
});

test('renders the camera-only placeholder when the iOS native module is unavailable', async () => {
  let renderer: ReactTestRenderer.ReactTestRenderer;
  await ReactTestRenderer.act(() => {
    renderer = ReactTestRenderer.create(<App />);
  });

  const renderedTree = JSON.stringify(renderer!.toJSON());
  expect(renderedTree).toContain('PREVIEW NOT ACTIVE');
  expect(renderedTree).toContain('FILM ENGINE NOT ACTIVE');
});
