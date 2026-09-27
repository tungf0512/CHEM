import React, { useCallback, useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  View,
} from 'react-native';
import CameraModule from '../../../specs/NativeCHEMCameraModule';
import { ChemText } from '../../../design-system/components/ChemText';
import { colors } from '../../../design-system/colors';
import { radius } from '../../../design-system/radius';
import { spacing } from '../../../design-system/spacing';
import { prettyValidationReport } from '../validation.types';

const FAULTS = [
  { point: 'thumbnail', label: 'THUMBNAIL FAILURE' },
  { point: 'metadata', label: 'METADATA FAILURE' },
  { point: 'latestPointer', label: 'LATEST POINTER FAILURE' },
  { point: 'none', label: 'CLEAR FAULT' },
] as const;

export function InternalDiagnosticsPanel({
  visible,
  onClose,
}: {
  visible: boolean;
  onClose: () => void;
}) {
  const [rawReport, setRawReport] = useState('');
  const [busy, setBusy] = useState(false);
  const [copied, setCopied] = useState(false);

  const refresh = useCallback(async () => {
    if (CameraModule === null) {
      return;
    }
    setBusy(true);
    try {
      setRawReport(await CameraModule.getValidationReport());
    } finally {
      setBusy(false);
    }
  }, []);

  useEffect(() => {
    if (visible) {
      setCopied(false);
      refresh();
    }
  }, [refresh, visible]);

  const copyReport = useCallback(async () => {
    if (CameraModule === null) {
      return;
    }
    await CameraModule.copyValidationReport();
    setCopied(true);
  }, []);

  const setFault = useCallback(
    async (point: string) => {
      if (CameraModule === null) {
        return;
      }
      setBusy(true);
      try {
        await CameraModule.setValidationFault(point);
        await refresh();
      } finally {
        setBusy(false);
      }
    },
    [refresh],
  );

  return (
    <Modal
      animationType="slide"
      transparent
      visible={visible}
      onRequestClose={onClose}
    >
      <View style={styles.scrim}>
        <View style={styles.panel}>
          <View style={styles.header}>
            <View>
              <ChemText variant="label" tone="foreground">
                INTERNAL CAMERA DIAGNOSTICS
              </ChemText>
              <ChemText variant="bodySmall" tone="muted">
                Local metadata only. No frames or account data.
              </ChemText>
            </View>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Close diagnostics"
              onPress={onClose}
              style={styles.closeButton}
            >
              <ChemText variant="labelSmall" tone="amber">
                CLOSE
              </ChemText>
            </Pressable>
          </View>
          <ScrollView
            style={styles.report}
            contentContainerStyle={styles.reportContent}
          >
            {busy && rawReport.length === 0 ? (
              <ActivityIndicator color={colors.amber} />
            ) : (
              <ChemText
                selectable
                variant="labelSmall"
                tone="muted"
                style={styles.reportText}
              >
                {prettyValidationReport(rawReport)}
              </ChemText>
            )}
          </ScrollView>
          <View style={styles.actions}>
            <Pressable
              accessibilityRole="button"
              onPress={copyReport}
              style={styles.primaryButton}
            >
              <ChemText variant="labelSmall" tone="background">
                {copied ? 'COPIED' : 'COPY VALIDATION REPORT'}
              </ChemText>
            </Pressable>
            {FAULTS.map(({ point, label }) => (
              <Pressable
                key={point}
                accessibilityRole="button"
                onPress={() => setFault(point)}
                style={styles.secondaryButton}
              >
                <ChemText
                  variant="labelSmall"
                  tone={point === 'none' ? 'teal' : 'amber'}
                >
                  {label}
                </ChemText>
              </Pressable>
            ))}
          </View>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  scrim: {
    flex: 1,
    justifyContent: 'flex-end',
    backgroundColor: colors.scrimStrong,
  },
  panel: {
    maxHeight: '88%',
    padding: spacing.base,
    gap: spacing.md,
    backgroundColor: colors.background,
    borderTopLeftRadius: radius.viewfinder,
    borderTopRightRadius: radius.viewfinder,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    gap: spacing.md,
  },
  closeButton: { padding: spacing.xs },
  report: {
    minHeight: 180,
    maxHeight: 360,
    backgroundColor: colors.substrate,
    borderRadius: radius.standard,
  },
  reportContent: { padding: spacing.md },
  reportText: { fontFamily: 'Menlo', fontSize: 11, lineHeight: 16 },
  actions: { gap: spacing.xs },
  primaryButton: {
    minHeight: 44,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.amber,
    borderRadius: radius.standard,
  },
  secondaryButton: {
    minHeight: 36,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.surfaceRaised,
    borderRadius: radius.standard,
  },
});
