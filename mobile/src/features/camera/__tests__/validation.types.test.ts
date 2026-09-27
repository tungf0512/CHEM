import {
  parseValidationReport,
  prettyValidationReport,
} from '../validation.types';

describe('internal validation report formatting', () => {
  it('accepts a JSON object and formats it deterministically', () => {
    const raw = '{"preview":{"renderedFPS":30},"enabled":true}';
    expect(parseValidationReport(raw)).toEqual({
      preview: { renderedFPS: 30 },
      enabled: true,
    });
    expect(prettyValidationReport(raw)).toBe(`{
  "preview": {
    "renderedFPS": 30
  },
  "enabled": true
}`);
  });

  it('rejects malformed, empty, and non-object reports', () => {
    expect(parseValidationReport('')).toBeNull();
    expect(parseValidationReport('not-json')).toBeNull();
    expect(parseValidationReport('[]')).toBeNull();
    expect(prettyValidationReport('')).toBe('Validation report unavailable.');
  });
});
