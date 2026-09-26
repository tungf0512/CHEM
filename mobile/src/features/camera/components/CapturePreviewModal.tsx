import React from 'react';
import {Image, Modal, Pressable, StyleSheet, View} from 'react-native';
import {ChemText} from '../../../design-system/components/ChemText';
import {colors} from '../../../design-system/colors';
import {radius} from '../../../design-system/radius';
import {spacing} from '../../../design-system/spacing';
import type {CaptureMetadata} from '../camera.types';

export function CapturePreviewModal({
  capture,
  visible,
  onClose,
}: {
  capture: CaptureMetadata | null;
  visible: boolean;
  onClose: () => void;
}) {
  if (capture === null) {
    return null;
  }

  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={onClose}
      statusBarTranslucent>
      <View style={styles.overlay}>
        <View style={styles.header}>
          <View style={styles.title}>
            <ChemText variant="labelSmall" tone="amber">LOCAL SOURCE · READ ONLY</ChemText>
            <ChemText variant="label" tone="foreground">{capture.capturedAt}</ChemText>
          </View>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Close capture preview"
            onPress={onClose}
            style={styles.closeButton}>
            <ChemText variant="labelSmall" tone="foreground">CLOSE</ChemText>
          </Pressable>
        </View>
        <Image source={{uri: capture.sourceUri}} resizeMode="contain" style={styles.image} />
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: {flex: 1, padding: spacing.base, backgroundColor: colors.substrate},
  header: {minHeight: 58, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between'},
  title: {gap: spacing.xs},
  closeButton: {
    minHeight: 42, paddingHorizontal: spacing.md, justifyContent: 'center',
    backgroundColor: colors.surfaceRaised, borderRadius: radius.standard,
  },
  image: {flex: 1, width: '100%'} ,
});
