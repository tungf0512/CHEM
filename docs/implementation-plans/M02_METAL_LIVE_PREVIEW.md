# M2 — Metal live preview trong React Native

> Trạng thái: chưa triển khai · Phụ thuộc: M1 · Owner: Imaging + iOS; FE quản lý overlay.
> Nguồn: engineering plan §12, §30–33, §44–45; PRD CAM-002, ENG-001/002/003, §33, §41–43.

## Mục tiêu

Render một transform film đơn giản trên camera feed thật qua Metal-backed Fabric view, đạt stable 30 fps baseline và hướng tới 60 fps trên primary recent devices. M2 chứng minh performance đường pixels; chưa phải ba production film.

## Ticket

| ID | Owner | Công việc | Output / tiêu chí |
|---|---|---|---|
| M02-T01 | Imaging | Tạo shared MTLDevice/queue/pipeline cache/texture cache và resource lifecycle | Pipeline state tái sử dụng; không compile mỗi frame |
| M02-T02 | Imaging + iOS | CVPixelBuffer → CVMetalTexture, xử lý pixel format, YCbCr range/matrix/transfer metadata | Test patterns không sai range/màu; buffer sống đủ đến GPU completion |
| M02-T03 | iOS | `ChemCameraView` Fabric host cho MTKView; attach/detach/resize | Orientation/scale/safe-area đúng; không UIImage per frame |
| M02-T04 | Imaging | Immutable preview parameters: exposure → tone → color → output | Một prototype DAY-like transform; film selection không restart camera |
| M02-T05 | Imaging | Latest-frame backpressure, bounded in-flight textures, drop stale buffers | Không tích lũy độ trễ/queue khi GPU chậm |
| M02-T06 | iOS + FE | Debug HUD: input/render FPS, CPU encode/GPU time, queue, memory, thermal | Metrics aggregate/throttle qua RN; HUD chỉ Internal |
| M02-T07 | Imaging | High/balanced/thermalReduced tiers; pause background work | Giảm resolution/kernel cost, giữ tone/color semantics |
| M02-T08 | FE | Film chip và lens/EV overlays không kích full React render mỗi camera frame | Gestures/control phản hồi trong lúc preview chạy |

## Native hot path

```text
AVCaptureVideoDataOutput → CVPixelBuffer → texture cache
→ immutable descriptor → Metal graph → geometry transform → MTKView
```

JS không nằm trên đường này. Native acquire descriptor snapshot theo revision ở frame boundary; giữ resources của revision cũ đến GPU hoàn tất. Khi view tái tạo, drawable mất hoặc app background: drop safely, tránh force unwrap/retaining surface đã chết. Release buffers trong completion hợp lệ, không recycle texture GPU còn sử dụng.

Geometry tách khỏi màu: portrait sensor, aspect-fill, crop, display orientation, mirroring nếu sau này hỗ trợ. M1 focus mapping và Metal view dùng chung transform contract, tránh preview nhìn một vùng còn focus vào vùng khác.

## File dự kiến

- `ios/ChemNative/Imaging/Renderer/{MetalContext,PreviewRenderer,PreviewFramePool}.swift`.
- `Imaging/Metal/Shaders/{InputConversion,Exposure,Tone,Color,Output}.metal`.
- `Adapters/Views/ChemCameraComponentView.mm`, Swift Metal host.
- `Platform/{ThermalController,PerformanceRecorder}.swift`.
- `src/features/camera/PreviewDiagnostics.tsx` và versioned metrics DTO.

## Kế hoạch đo và kiểm chứng

- Đo **Release build trên thiết bị**, có build/OS/device/resolution/tier/film trong báo cáo. Tách input FPS và presented FPS; median/p95 GPU frame time không đủ thay thế presented FPS.
- Đề xuất soak 10 phút mỗi tier/device, ghi FPS/drop count/queue/memory theo thời gian, test lens switching và background/resume trong session; freeze thời lượng chính thức trước test.
- Mục tiêu PRD: baseline stable 30 fps, preferred 60 fps. Frame interval tham chiếu lần lượt ~33,3 ms/~16,7 ms; budget GPU cụ thể cần chừa headroom cho camera/OS và chốt sau đo.
- Cố ý stall JS trong Internal harness: native preview vẫn chạy; UI điều khiển có thể chậm, không giả lập claim UI không phụ thuộc JS.
- Cố ý render chậm: drop stale preview, queue bounded; memory về mức ổn định sau repeated surface/lens cycles.
- Kiểm màu test ramps/charts, orientation, tap mapping và snapshot trước/sau lens switch.

## Exit và bàn giao

- [ ] Stable 30 fps baseline; report ghi rõ thiết bị nào đạt 60 fps, không khẳng định chung.
- [ ] Không pixel/base64 transfer qua JS; không IO/database/network trên preview hot path.
- [ ] Không leak camera buffers/Metal resources khi lens/surface đổi.
- [ ] Tier switching không flicker/oscillate bất thường; capture baseline M1 còn đúng.
- [ ] Evidence tại `docs/evidence/M02/REPORT.md`; shared input/geometry/descriptor foundation chuyển cho M4.

Nếu không đạt FPS, profile input conversion, drawable scheduling, copying và kernel cost trước khi thêm grain/bloom/halation. Không bỏ full native path để dùng CSS/filter UI.
