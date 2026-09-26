# Neutral camera preview color baseline

This is a bounded SDR baseline for the camera foundation, not the future CHEM Film Engine color contract.

## Preview input pixel format

- `AVCaptureVideoDataOutput` requests `kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange` (8-bit bi-planar 4:2:0, video range).
- The Metal converter also handles the corresponding 8-bit full-range format if AVFoundation supplies it.
- The camera session disables automatic wide-color selection and locks the active physical capture device to `.sRGB` before starting. No HDR capture mode is requested.

## Range and YCbCr matrices supported

- Video range uses 16–235 luma and 16–240 chroma normalization; full range uses normalized luma and chroma centered at 0.5.
- BT.601 and BT.709 YCbCr matrices have explicit shader coefficients.
- Missing matrix metadata is treated as BT.709 only under the configured SDR/sRGB camera path.
- Any other matrix is rejected instead of silently falling through to BT.709.

## Working assumptions

- Input is SDR, non-linear sRGB/Rec.709-compatible camera video. The preview does not linearize light and does not apply a tone curve, LUT, device calibration, or artistic transform.
- The renderer accepts Rec.709 primaries and legacy SMPTE-C/BT.601 primaries. Unknown, P3, BT.2020, or otherwise unsupported color metadata stops neutral rendering and reports a renderer failure; it is not approximated as Rec.709.
- HLG, PQ, Apple Log, and other non-sRGB/Rec.709 transfer functions are unsupported. No HDR-to-SDR tone mapping is implemented.

## Drawable/output format

- Metal drawable: `.bgra8Unorm` (8-bit SDR).
- `CAMetalLayer.colorspace` is explicitly set to sRGB.
- The fragment shader clamps converted RGB into the SDR range. This is a neutral viewfinder baseline, not an export/color-management implementation.

## Unsupported/HDR behavior

BT.2020/P3 wide-gamut and HDR/Log attachments are not silently converted or clipped as if they were Rec.709. The renderer reports a typed error and the camera presents its unavailable state. Production HDR support requires an explicit input transform, transfer decode, working space, tone map, and device validation; it is deferred.

## Device-validation requirements

On the iPhone Air, compare neutral preview against a controlled SDR reference, confirm attached matrix/transfer/primaries values, verify switching 1× ↔ 2× does not change color space unexpectedly, and record display brightness/True Tone/Night Shift state. Repeat on an iPhone with Ultra Wide and a separate physical Telephoto. No color or physical-device behavior is verified by the Linux host or by simulator compilation.
