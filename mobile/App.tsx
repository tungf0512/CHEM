import React from 'react';
import {StatusBar} from 'react-native';
import {SafeAreaProvider} from 'react-native-safe-area-context';
import {CameraScreen} from './src/features/camera/CameraScreen';
import {colors} from './src/design-system/colors';

function App() {
  return (
    <SafeAreaProvider>
      <StatusBar barStyle="light-content" backgroundColor={colors.background} />
      <CameraScreen />
    </SafeAreaProvider>
  );
}

export default App;
