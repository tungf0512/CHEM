export type CameraLogEvent =
  | 'permission_request'
  | 'permission_status'
  | 'lifecycle'
  | 'capture_request'
  | 'capture_completed'
  | 'capture_failed';

export function logCameraEvent(
  event: CameraLogEvent,
  fields: Readonly<Record<string, string | number>> = {},
): void {
  if (!__DEV__) {
    return;
  }
  console.debug(`[CHEM Camera] ${event}`, fields);
}
