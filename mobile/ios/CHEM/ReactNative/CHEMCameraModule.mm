#import <AVFoundation/AVFoundation.h>
#import <React/RCTLog.h>
#import <ReactCommon/RCTTurboModule.h>

#import "CHEM-Swift.h"
#import <CHEMNativeSpec/CHEMNativeSpec.h>

using namespace facebook::react;

@interface CHEMCameraModule : NativeCHEMCameraModuleSpecBase <NativeCHEMCameraModuleSpec>
@end

@implementation CHEMCameraModule

RCT_EXPORT_MODULE(CHEMCameraModule)

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

- (std::shared_ptr<TurboModule>)getTurboModule:(const ObjCTurboModule::InitParams &)params
{
  return std::make_shared<NativeCHEMCameraModuleSpecJSI>(params);
}

- (void)getCameraPermissionStatus:(RCTPromiseResolveBlock)resolve
                           reject:(RCTPromiseRejectBlock)reject
{
  resolve([self cameraPermissionStatus]);
}

- (void)requestCameraPermission:(RCTPromiseResolveBlock)resolve
                         reject:(RCTPromiseRejectBlock)reject
{
  AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
  if (status != AVAuthorizationStatusNotDetermined) {
    resolve([self cameraPermissionStatus]);
    return;
  }

  [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(__unused BOOL granted) {
    resolve([self cameraPermissionStatus]);
  }];
}

- (void)getLastCapture:(RCTPromiseResolveBlock)resolve
                reject:(RCTPromiseRejectBlock)reject
{
  // Metadata references only local Application Support files; photo bytes stay native.
  resolve([CHEMCaptureStore latestMetadataJSON]);
}

- (NSString *)cameraPermissionStatus
{
  switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
    case AVAuthorizationStatusNotDetermined:
      return @"notDetermined";
    case AVAuthorizationStatusAuthorized:
      return @"authorized";
    case AVAuthorizationStatusDenied:
      return @"denied";
    case AVAuthorizationStatusRestricted:
      return @"restricted";
  }
  return @"unknown";
}

@end
