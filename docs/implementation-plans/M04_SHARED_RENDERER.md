# M4 — Shared preview / final renderer

> Trạng thái: chưa triển khai · Phụ thuộc: M2 + M3 · Owner: Imaging + iOS.
> Nguồn: engineering plan §14, §27–40; PRD DEV-002, ENG-001…003, §31–35, §38, §43, §77–84.

## Mục tiêu

Cùng một immutable descriptor và film graph tạo camera preview, Lab preview và final full resolution. M4 tích hợp final render vào transaction M3; chất lượng ba film hoàn tất M5.

## Ticket

| ID | Owner | Công việc | Output / tiêu chí |
|---|---|---|---|
| M04-T01 | Imaging + iOS | Freeze RenderDescriptor, RenderInput, quality/output policies và version references | Không global mutable artistic state; native ack descriptor revision |
| M04-T02 | Imaging | Input adapters cho camera YCbCr/processed HEIF/JPEG; RAW adapter interface | Orientation/color/range rõ; processed input không bị decode như RAW |
| M04-T03 | Imaging | Chốt color working-space contract, normalization, SDR output/HDR input policy | Spec ghi primaries/transfer/precision/stage spaces, có test charts |
| M04-T04 | Imaging | Unified graph, shared tone/color stages, extensible bloom/halation/grain slots | Preview/interactive/final không có hai bộ look constants |
| M04-T05 | Imaging + iOS | Full-resolution source → graph → encoded derived asset | Renderer off-main; M3 job chuyển rendered khi file đã commit |
| M04-T06 | iOS | Scheduler priorities, cancellation, dedupe, admission/memory/thermal | Preview latest-only; full-res concurrency khởi đầu 1; stale jobs không overwrite |
| M04-T07 | Imaging | Comparator: freeze preview + capture, align geometry, color-managed A/B/diff | Phân biệt input ISP mismatch và renderer mismatch |
| M04-T08 | iOS | Versioned cache key + old resource resolution; atomic output write | Cache invalidation đúng descriptor/quality; source không cache |

## Contracts

`RenderDescriptor` gồm film/recipe/profile/renderer versions, scene parameters/model version, seed, source fingerprint, crop và output policy. Job có `jobID`, `frameID`, `recipeRevision`, priority, quality, dimensions. Output có format, color profile, dimensions, checksum và relative asset path.

Native renderer resolve đúng version, không fallback silent sang latest. SceneAnalyzer ban đầu có thể chỉ thống kê luminance/highlights/chroma deterministic. Nếu parameter ảnh hưởng look, lưu/version hóa để tái lập; preview smoothing temporal chỉ là presentation, không được thành hidden state của final.

Quy ước proposed working representation: floating point wide-gamut, linear-light cho stage cần đúng năng lượng. M04-T03 xác định cụ thể mỗi phép biến đổi; không gọi cả graph “linear” trong khi LUT được author ở không gian khác. Device normalization trước film character; generic profile versioned có sẵn trước M10.

Crop lưu normalized rect trên source đã diễn giải orientation; source giữ tối đa vùng hữu dụng. Hỗ trợ contract 4:3, 3:2, 1:1 ngay đây; FE control hoàn thiện ở M7/M12. Blur/halation/grain phải scale theo kích thước ảnh, không chỉ viewport pixels.

## File dự kiến

- `Domain/Rendering/{RenderDescriptor,RenderJob,RenderOutput}.swift`.
- `Imaging/{InputDecoder,WorkingColorPolicy,DeviceNormalizer,ChemRenderer,RenderScheduler}.swift`.
- `Imaging/Output/{OutputTransform,ImageEncoder}.swift`.
- `Persistence/RenderCache.swift`, `InternalTools/PreviewFinalComparator/`.
- `docs/engineering/{RENDERER_SPEC,COLOR_PIPELINE}.md` khi triển khai.

## Kế hoạch kiểm chứng

1. **Same-input cross-quality:** dùng cùng source/descriptor để đo khác biệt approximation giữa preview, interactive và final, loại bỏ biến đổi scene/camera.
2. **Live-vs-still:** tripod/static scenes, freeze preview/capture gần nhau, align crop, đọc exposure/WB/ISP khác biệt; review color/tone/highlights riêng với stochastic grain.
3. **Color/orientation:** sRGB/P3, grayscale/color ramps, highlight clipping, portrait/landscape, source EXIF orientation. Verify pixel conversion và embedded profile.
4. **Determinism:** cùng input/version/seed cho kết quả pixel/perceptual trong tolerance; không bắt buộc HEIF bytes giống nhau.
5. **Load/failure:** memory cho 12/24/48 MP khi có nguồn/thiết bị phù hợp; render fail giữ source; stale completion không thay current recipe preview.

Threshold perceptual/memory chưa có trong PRD: Imaging + QA freeze comparator protocol/tolerance theo device trước approve output. Không tự đặt SSIM/ΔE tùy ý rồi xem như yêu cầu PRD. Final tiling nếu cần phải tính halo cho blur/halation để không seam.

## Exit và bàn giao

- [ ] Một graph thực sự dùng chung preview/final, final output mở được.
- [ ] Color pipeline/crop/version/cache contracts có fixtures và documentation.
- [ ] Comparator chạy; mismatch lớn được giải thích và sửa trước film tuning.
- [ ] Full-res render không chặn source capture/JS/main thread, memory bounded.
- [ ] Evidence `docs/evidence/M04/REPORT.md`; graph và authoring schema bàn giao M5, interactive API cho M7.
