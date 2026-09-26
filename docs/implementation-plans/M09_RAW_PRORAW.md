# M9 — RAW / ProRAW và Negative mode

> Trạng thái: chưa triển khai · Phụ thuộc: M8 · Owner: iOS + Imaging.
> Nguồn: engineering plan §23, §29, §86; PRD NEG-002/003, RAW-001…004, GAL-002, §44, §90.

## Mục tiêu

Capability-gated RAW/ProRAW capture, paired source durability, decode vào shared engine, import RAW được hỗ trợ, re-development và storage UX. Standard HEIF/JPEG phải tiếp tục ổn định trên máy/lens không hỗ trợ.

## Ticket

| ID | Owner | Công việc | Output / tiêu chí |
|---|---|---|---|
| M09-T01 | iOS | Query support cho device/lens/session format hiện tại, supported RAW formats/dimensions | Capability DTO cập nhật khi lens/config đổi; không suy từ tên máy |
| M09-T02 | FE + iOS | Standard/Negative settings, availability reasons, expected storage cost | Mode chỉ active sau native ack; Internal override tách Release entitlement |
| M09-T03 | iOS | RAW/ProRAW + processed companion capture, delegate correlation | Mỗi component gắn đúng request/frameID; retain lifetime đến hoàn tất |
| M09-T04 | iOS | SourceBundle multi-file transaction/manifest và recovery | sourceSafe(mode=Negative) chỉ sau required components validate/commit |
| M09-T05 | Imaging | RawSourceDecoder, decode defaults/version và working-space adapter | Cùng film graph, không tạo renderer nghệ thuật riêng cho RAW |
| M09-T06 | iOS + Imaging | System picker RAW/DNG import support matrix | File readable được managed copy/develop; unsupported format giải thích rõ |
| M09-T07 | FE + iOS | Negative storage accounting/management, low-storage preflight | Không xóa RAW qua clear-cache; đổi mode cần thể hiện cho user |
| M09-T08 | QA + Imaging | RAW fixtures, paired-failure/relaunch/performance/preview-final tests | DNG hợp lệ, association đúng, known limitations được ghi |

## Capture semantics

Schema M3/M6 đã có source components; thêm role/format/decode metadata nếu cần qua migration. Required components của mỗi capture mode phải freeze trong intent. Không mark toàn Negative capture thành công khi mới nhận processed companion.

Nếu RAW fail nhưng processed component đã durable: bảo toàn processed source, báo `negativeUnavailable` và cho tiếp tục Standard/development theo policy rõ; không bỏ file cứu được, không báo “RAW saved”. Nếu hết dung lượng trước chụp, đề nghị Standard hoặc storage management; không đổi mode âm thầm. Race lens switch phải invalidate capability revision trước capture.

RAW decoder output lưu nguồn gốc/input type, decode settings và version/platform context cần thiết. Các decoder hệ thống có thể thay đổi theo OS: regression qua OS là bắt buộc; nếu không thể tái lập pixel chính xác, giữ rendered artifact, báo giới hạn và cân nhắc normalized intermediate có version thay vì hứa bit-exact.

RAW final và live processed video có ISP khác nhau. Dùng comparator M4 để tune normalization và đánh giá perceptual consistency; không giả định cùng descriptor làm hai nguồn đầu vào giống tuyệt đối.

## RN/native và file dự kiến

JS chỉ nhận support flags/mode/size estimate/frame metadata; DNG không đi qua bridge.

- `CameraCore/Capture/{RawCaptureCapabilities,RawCaptureCoordinator}.swift`.
- `Imaging/RAW/{RawSourceDecoder,RawDecodePolicy}.swift`.
- `Persistence/Files/SourceBundleManifest.swift`, schema migration nếu thêm fields.
- `src/features/settings/NegativeModeSettings.tsx`, `src/features/settings/NegativeStorageScreen.tsx`.
- RAW test assets manifest + `docs/engineering/RAW_SUPPORT_MATRIX.md`.

## Kế hoạch nghiệm thu

- Thiết bị có ProRAW, có/không RAW theo lens, thiết bị không hỗ trợ; query lại sau lens/format change.
- Capture Negative → terminate → reopen → đổi film → HEIF/JPEG export. Verify RAW checksum, dimensions, readable metadata, companion association.
- Inject lỗi một component, low disk giữa hai files, DB commit fail, missing companion cache; không false sourceSafe Negative.
- Imported supported DNG, unsupported RAW, corrupted DNG, oversized dimensions và decoder memory pressure.
- Peak memory/decode time/full-res render, thermal load, preview/final mismatch theo input type.

## Exit và bàn giao

- [ ] Supported RAW/ProRAW files decode được sau relaunch, đủ association và recovery.
- [ ] Unsupported lens/device/format không hiện mode sai; Standard còn dùng được.
- [ ] Lab/export dùng shared graph; RAW regression tách processed regression.
- [ ] Storage UX và partial failure rõ, source được giữ.
- [ ] Evidence `docs/evidence/M09/REPORT.md`; raw input/profile identity bàn giao M10.

RAW có thể tắt ở beta nếu chưa đạt, nhưng Public V1 scope thay đổi phải ghi lại theo roadmap; không dùng một toggle disabled để đánh dấu milestone hoàn thành.
