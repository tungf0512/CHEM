# M10 — Device / lens normalization và calibration

> Trạng thái: chưa triển khai · Phụ thuộc: M4/M5/M8; RAW track cần M9 · Owner: Imaging + iOS + photographer.
> Nguồn: engineering plan §24, §65–67, §87; PRD §28–30, §61–66, ENG-003.

## Mục tiêu

Giảm lệch baseline giữa device/lens/input type trước film graph, có versioned measured profiles cho thiết bị ưu tiên và safe generic fallback. Không chỉ thêm trường `deviceProfileVersion` rồi tuyên bố đã calibrated.

## Ticket

| ID | Owner | Công việc | Output / tiêu chí |
|---|---|---|---|
| M10-T01 | iOS + Imaging | Profile identity/resolver: hardware family + camera/lens + input type + version | Đúng profile cho video/processed/RAW; generic fallback explicit |
| M10-T02 | Imaging | Calibration capture tool: chart/neutral/bracket/lighting metadata | Session dataset có device/lens/OS/build/illumination/source/checksum |
| M10-T03 | Product + QA | Chọn priority devices từ matrix M0 và lịch chụp controlled scenes | Ghi full-calibration vs generic support, không blanket “all calibrated” |
| M10-T04 | Imaging | Estimate color/tone/WB correction, validate trên held-out scenes | Normalization không thêm creative look; không overfit chart |
| M10-T05 | Imaging | Bundle profile resources/validation/versioning, golden outputs | Profile resource/version cũ còn resolve cho old frames |
| M10-T06 | iOS | Atomically cập nhật device+profile tại lens/config transition | Capture freeze đúng pair; không profile Wide áp cho Tele |
| M10-T07 | Imaging + QA | Cross-device/lens/OS/input regression, đo before/after | Improvement có evidence và không làm xấu da/highlight |
| M10-T08 | FE | Metadata detail/diagnostics phản ánh applied profile thật | User UI gọn, diagnostics không che Camera; source unknown có generic label đúng |

## Calibration protocol

1. Capture chart, neutral grayscale, saturation patches, highlight step/skin references.
2. Lighting gồm daylight, cloudy, tungsten, warm/cool LED, mixed indoor theo PRD; exposure brackets ghi giá trị thực tế.
3. Chụp real scenes: nhiều màu da, foliage/sky/red fabric, neon, reflective highlights/deep shadows.
4. Chia tuning set và held-out validation; lưu raw/processed associations và camera settings.
5. Apply normalization trước cùng film descriptor; compare cùng crop/output profile và ánh sáng kiểm soát.
6. Photographer review, metric review rồi freeze profile version và compatibility metadata.

Không áp cùng correction hai lần. Source imported có thể đã qua editor/ISP khác hoặc thiếu identity; dùng generic imported-input profile được định nghĩa ở M4, chỉ chọn device profile nếu input provenance đủ tin cậy. EXIF tên iPhone đơn thuần chưa chứng minh ảnh là source camera chưa chỉnh.

## Phiên bản và fallback

Frame cũ giữ reference profile lúc chụp. Profile mới dành cho capture mới; explicit re-develop/upgrade tạo revision, giữ captured baseline. Missing/invalid calibrated profile dùng generic cho **capture mới**; frame cũ thiếu version phải báo compatibility issue, không thay silently.

OS update có thể đổi ISP/RAW decode; lưu OS/build trong calibration evidence và chạy regression trước mở rộng support. Những model chưa đo dùng generic đã test, không bị khóa camera chỉ vì thiếu calibrated resource.

## File dự kiến

- `Imaging/Calibration/{DeviceProfile,DeviceProfileProvider,CalibrationSession,DeviceNormalizer}.swift`.
- `Resources/Calibration/<device>/<lens>/<inputType>/<version>/`.
- `InternalTools/CalibrationCapture/`, `tools/calibration/`.
- `docs/engineering/{DEVICE_CALIBRATION,CALIBRATION_DATASET_MANIFEST}.md`.

## Kế hoạch nghiệm thu

- Before/after normalization cùng scenes/lenses, color patch + neutral/WB + tone/clipping metrics cùng human review.
- Freeze numerical tolerances dựa baseline M4 và target quality trước approve; PRD chưa cung cấp ΔE threshold.
- Missing/corrupt profile fallback cho new capture; unavailable old version không làm mất old render/source.
- Switch lens nhanh và chụp: applied device/profile revisions luôn nhất quán.
- So sánh processed và RAW paths riêng, không chỉ chart daylight; M2 performance không bị profile lookup/IO per frame.

## Exit và bàn giao

- [ ] Ít nhất priority devices/lenses đã cam kết ở M0 có measured profile và coverage report.
- [ ] Generic-safe devices được phân loại riêng, không claim đã hiệu chuẩn.
- [ ] Versioned profiles persisted per frame và old-frame policy đúng.
- [ ] Calibration tool/dataset có metadata tái lập; skin/highlights/low light đã review.
- [ ] Evidence `docs/evidence/M10/REPORT.md`; capability/profile switching sẵn cho M11 và release matrix.
