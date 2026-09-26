#import "CHEMCameraPreviewComponentView.h"

#import <react/renderer/components/CHEMNativeSpec/ComponentDescriptors.h>
#import <react/renderer/components/CHEMNativeSpec/EventEmitters.h>
#import <react/renderer/components/CHEMNativeSpec/Props.h>
#import <react/renderer/components/CHEMNativeSpec/RCTComponentViewHelpers.h>
#import <React/RCTFabricComponentsPlugins.h>

#import "CHEM-Swift.h"

using namespace facebook::react;

@interface CHEMCameraPreviewComponentView () <RCTCHEMCameraPreviewViewProtocol, CHEMCameraEngineDelegate>
@property (nonatomic, strong) CHEMCameraPreviewView *previewView;
@end

@implementation CHEMCameraPreviewComponentView

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<CHEMCameraPreviewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const CHEMCameraPreviewProps>();
    _props = defaultProps;

    _previewView = [[CHEMCameraPreviewView alloc] initWithFrame:CGRectZero];
    _previewView.cameraEngine.delegate = self;
    self.contentView = _previewView;
  }
  return self;
}

- (void)updateProps:(const Props::Shared &)props oldProps:(const Props::Shared &)oldProps
{
  const auto &newProps = static_cast<const CHEMCameraPreviewProps &>(*props);
  [super updateProps:props oldProps:oldProps];
  _previewView.cameraEngine.delegate = self;
  [_previewView setPreviewActive:newProps.active];
}

- (void)prepareForRecycle
{
  [_previewView setPreviewActive:NO];
  _previewView.cameraEngine.delegate = nil;
  [super prepareForRecycle];
}

#pragma mark - Generated Fabric commands

- (void)start
{
  [_previewView setPreviewActive:YES];
}

- (void)stop
{
  [_previewView setPreviewActive:NO];
}

- (void)selectLens:(NSString *)deviceId
{
  [_previewView.cameraEngine selectLensWithId:deviceId];
}

- (void)focusAndExpose:(float)normalizedX normalizedY:(float)normalizedY
{
  [_previewView.cameraEngine focusAndExposeWithNormalizedX:normalizedX normalizedY:normalizedY];
}

- (void)setExposureCompensation:(float)ev
{
  [_previewView.cameraEngine setExposureCompensation:ev];
}

- (void)capture
{
  [_previewView.cameraEngine capture];
}

#pragma mark - Native engine events to Codegen Fabric event emitters

- (void)cameraEngineDidChangeState:(NSString *)state reason:(NSString *)reason code:(NSString *)code
{
  auto eventEmitter = std::static_pointer_cast<const CHEMCameraPreviewEventEmitter>(_eventEmitter);
  if (!eventEmitter) return;
  CHEMCameraPreviewEventEmitter::OnCameraStateChanged event;
  event.state = state.UTF8String ?: "";
  event.reason = reason.UTF8String ?: "";
  event.code = code.UTF8String ?: "";
  eventEmitter->onCameraStateChanged(event);
}

- (void)cameraEngineDidChangeLenses:(NSArray<NSDictionary<NSString *, NSString *> *> *)lenses
{
  auto eventEmitter = std::static_pointer_cast<const CHEMCameraPreviewEventEmitter>(_eventEmitter);
  if (!eventEmitter) return;
  CHEMCameraPreviewEventEmitter::OnAvailableLensesChanged event;
  for (NSDictionary<NSString *, NSString *> *lens in lenses) {
    CHEMCameraPreviewEventEmitter::OnAvailableLensesChangedLenses value;
    value.id = [lens[@"id"] UTF8String] ?: "";
    value.role = [lens[@"role"] UTF8String] ?: "wide";
    value.displayZoom = [lens[@"displayZoom"] UTF8String] ?: "OPTICAL";
    event.lenses.push_back(value);
  }
  eventEmitter->onAvailableLensesChanged(event);
}

- (void)cameraEngineDidActivateLens:(NSDictionary<NSString *, NSString *> *)lens
{
  auto eventEmitter = std::static_pointer_cast<const CHEMCameraPreviewEventEmitter>(_eventEmitter);
  if (!eventEmitter) return;
  CHEMCameraPreviewEventEmitter::OnActiveLensChanged event;
  event.id = [lens[@"id"] UTF8String] ?: "";
  eventEmitter->onActiveLensChanged(event);
}

- (void)cameraEngineDidChangeExposure:(NSDictionary<NSString *, NSNumber *> *)exposure
{
  auto eventEmitter = std::static_pointer_cast<const CHEMCameraPreviewEventEmitter>(_eventEmitter);
  if (!eventEmitter) return;
  CHEMCameraPreviewEventEmitter::OnExposureChanged event;
  event.minimumEV = exposure[@"minimumEV"].floatValue;
  event.maximumEV = exposure[@"maximumEV"].floatValue;
  event.appliedEV = exposure[@"appliedEV"].floatValue;
  eventEmitter->onExposureChanged(event);
}

- (void)cameraEngineDidChangeTelemetry:(NSDictionary<NSString *, id> *)telemetry
{
  auto eventEmitter = std::static_pointer_cast<const CHEMCameraPreviewEventEmitter>(_eventEmitter);
  if (!eventEmitter) return;
  CHEMCameraPreviewEventEmitter::OnTelemetryChanged event;
  event.iso = [telemetry[@"iso"] floatValue];
  event.shutterSeconds = [telemetry[@"shutterSeconds"] floatValue];
  event.lensDisplay = [telemetry[@"lensDisplay"] UTF8String] ?: "";
  event.captureExposureCompensationEV = [telemetry[@"captureExposureCompensationEV"] floatValue];
  eventEmitter->onTelemetryChanged(event);
}

- (void)cameraEngineDidChangePerformanceMetrics:(NSDictionary<NSString *, id> *)metrics
{
  auto eventEmitter = std::static_pointer_cast<const CHEMCameraPreviewEventEmitter>(_eventEmitter);
  if (!eventEmitter) return;
  CHEMCameraPreviewEventEmitter::OnPerformanceMetricsChanged event;
  event.previewFPS = [metrics[@"previewFPS"] intValue];
  event.renderFPS = [metrics[@"renderFPS"] intValue];
  event.renderMilliseconds = [metrics[@"renderMilliseconds"] floatValue];
  event.droppedFrames = [metrics[@"droppedFrames"] intValue];
  event.activeLens = [metrics[@"activeLens"] UTF8String] ?: "";
  event.cameraState = [metrics[@"cameraState"] UTF8String] ?: "idle";
  eventEmitter->onPerformanceMetricsChanged(event);
}

- (void)cameraEngineDidFailCapture:(NSDictionary<NSString *, NSString *> *)failure
{
  auto eventEmitter = std::static_pointer_cast<const CHEMCameraPreviewEventEmitter>(_eventEmitter);
  if (!eventEmitter) return;
  CHEMCameraPreviewEventEmitter::OnCaptureFailed event;
  event.code = [failure[@"code"] UTF8String] ?: "captureFailed";
  event.message = [failure[@"message"] UTF8String] ?: "The photo could not be captured.";
  eventEmitter->onCaptureFailed(event);
}

- (void)cameraEngineDidFailLens:(NSDictionary<NSString *, NSString *> *)failure
{
  auto eventEmitter = std::static_pointer_cast<const CHEMCameraPreviewEventEmitter>(_eventEmitter);
  if (!eventEmitter) return;
  CHEMCameraPreviewEventEmitter::OnLensSelectionFailed event;
  event.id = [failure[@"id"] UTF8String] ?: "";
  event.code = [failure[@"code"] UTF8String] ?: "lensSwitchFailed";
  event.message = [failure[@"message"] UTF8String] ?: "The lens could not be selected.";
  eventEmitter->onLensSelectionFailed(event);
}

- (void)cameraEngineDidReportError:(NSDictionary<NSString *, NSString *> *)failure
{
  auto eventEmitter = std::static_pointer_cast<const CHEMCameraPreviewEventEmitter>(_eventEmitter);
  if (!eventEmitter) return;
  CHEMCameraPreviewEventEmitter::OnCameraError event;
  event.code = [failure[@"code"] UTF8String] ?: "cameraUnavailable";
  event.message = [failure[@"message"] UTF8String] ?: "A camera operation failed.";
  eventEmitter->onCameraError(event);
}

- (void)cameraEngineDidCompleteCapture:(NSDictionary<NSString *, id> *)metadata
{
  auto eventEmitter = std::static_pointer_cast<const CHEMCameraPreviewEventEmitter>(_eventEmitter);
  if (!eventEmitter) return;
  CHEMCameraPreviewEventEmitter::OnCaptureCompleted event;
  event.id = [metadata[@"id"] UTF8String] ?: "";
  event.sourceUri = [metadata[@"sourceUri"] UTF8String] ?: "";
  event.thumbnailUri = [metadata[@"thumbnailUri"] UTF8String] ?: "";
  event.width = [metadata[@"width"] intValue];
  event.height = [metadata[@"height"] intValue];
  event.capturedAt = [metadata[@"capturedAt"] UTF8String] ?: "";
  event.lensId = [metadata[@"lensId"] UTF8String] ?: "";
  eventEmitter->onCaptureCompleted(event);
}

@end
