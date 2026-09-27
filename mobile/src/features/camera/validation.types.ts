export type ValidationReport = Record<string, unknown>;

export function parseValidationReport(raw: string): ValidationReport | null {
  if (raw.trim().length === 0) {
    return null;
  }
  try {
    const value: unknown = JSON.parse(raw);
    if (value === null || typeof value !== 'object' || Array.isArray(value)) {
      return null;
    }
    return value as ValidationReport;
  } catch {
    return null;
  }
}

export function prettyValidationReport(raw: string): string {
  const parsed = parseValidationReport(raw);
  return parsed === null
    ? 'Validation report unavailable.'
    : JSON.stringify(parsed, null, 2);
}
