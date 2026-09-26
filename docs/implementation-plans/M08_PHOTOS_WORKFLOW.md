# M8 — Photos import, export và share

> Trạng thái: chưa triển khai · Phụ thuộc: M7 · Owner: iOS + FE + Imaging.
> Nguồn: engineering plan §22, §36, §62; PRD GAL-001…004, LAB-006, EXP-001…003, PRIV-005, §71–72, §87, §91–94.

## Mục tiêu

Khép kín vertical slice: Camera → source safe → Lab → đổi film → Save Copy/Share; ảnh Photos import đi qua cùng engine. JPEG/HEIF hoàn chỉnh ở M8, RAW import đi qua decoder M9.

## Ticket

| ID | Owner | Công việc | Output / tiêu chí |
|---|---|---|---|
| M08-T01 | iOS + FE | Present system photo picker qua native adapter từ RN | Scoped selection; cancel không tạo frame lỗi/không xin full-library vô cớ |
| M08-T02 | iOS | Resolve selected asset/file representation, asynchronous iCloud progress/cancel | Local asset offline chạy; cloud-only unavailable có trạng thái rõ |
| M08-T03 | iOS | Import validator + managed source copy qua transaction M3 | Copy đúng ảnh được chọn vào UUID path, retain checksum/metadata, không copy cả thư viện |
| M08-T04 | Imaging | sRGB/P3 JPEG/HEIF input, orientation, HDR→SDR policy M4 | Không giả định mọi ảnh sRGB hoặc double-normalize camera profile |
| M08-T05 | iOS + Imaging | ExportCoordinator snapshot revision/options, full-res render + HEIF/JPEG encode | HEIF P3/JPEG sRGB đúng transform/tag; nguồn không bị overwrite |
| M08-T06 | iOS + FE | Photos add permission, Save Copy, optional auto-save policy | UI success sau Photos commit; denied/save-failed giữ frame và file render |
| M08-T07 | iOS + FE | System share sheet, export job progress/cancel/retry | Temp output sống đủ khi share; dismissed không báo đã chia sẻ thành công |
| M08-T08 | iOS | Export job durability/idempotency và recovery | Retry không tạo duplicate trong các đường đã nhận diện; trạng thái uncertain được xử lý rõ |
| M08-T09 | FE + QA | Gallery-only flow, import/export errors, metadata preferences UI | Camera denied vẫn import/develop/export; Photos denied vẫn chụp nội bộ |

## Import contract và quyết định lưu source

Đề xuất managed copy mặc định cho frame đã import, giữ Photos reference nếu có. Lựa chọn này ưu tiên re-development bền vững theo engineering plan §22, được ghi khác với PRD GAL-004 đề xuất reference-first. Product chốt ở M0; M8 không tự âm thầm đổi policy.

Native API trả import job ID/progress/frameID; selected file URL từ picker có lifetime/scope hạn chế, phải copy xong trước khi coi imported frame sourceSafe. Kiểm magic/format, dimensions, decode, pixel budget và disk space; không dùng external filename làm internal path. RAW unsupported cho tới M9 trả message rõ, không giả JPEG decode thành công.

Ảnh iCloud-only có thể cần tải mạng: offline guarantee áp dụng source đang local/đã managed copy. Không hứa download từ iCloud khi offline. Import xử lý user-edited Photos representation hay original phải được ghi explicit trong job metadata; V1 đề xuất representation người dùng chọn/nhìn thấy, không âm thầm bỏ edits.

## Export contract

Options gồm HEIF/JPEG, profile policy, crop/dimensions, metadata policy và destination. V1 full-resolution không watermark ở cả Free. Không TIFF hoặc “film-baked DNG”; source RAW preservation khác rendered export.

Location mặc định đề xuất strip trên export; preserve chỉ khi người dùng chọn, và không xin location mới chỉ để xử lý metadata GPS đã có trong ảnh. Camera/date/film metadata có setting rõ, không ghi model sensor giả hay EXIF máy film.

Photos transaction nằm ngoài DB của CHEM: persist export intent trước request, ghi Photos local identifier khi có và reconcile sau restart trong phạm vi permission cho phép. Nếu app chết đúng cửa sổ commit mà không xác minh được với add-only access, đánh dấu `saveOutcomeUnknown`, giải thích trước khi user retry có thể tạo copy nữa. Không hứa exactly-once không có bằng chứng, không xin full-library chỉ để che lấp vấn đề này.

## File dự kiến

- `Platform/Photos/{SystemPhotoPicker,PhotoImportService,PhotoLibraryService,SharePresenter}.swift`.
- `Domain/Export/{ExportCoordinator,ExportOptions,ExportResult}.swift`, `Persistence/ExportJobRepository.swift`.
- `Imaging/Input/ImportedImageAdapter.swift`, `Imaging/Output/MetadataPolicy.swift`.
- `specs/NativeChemPhotos.ts`, `src/features/gallery/`, `src/features/lab/ExportSheet.tsx`.

## Kế hoạch nghiệm thu

| Nhóm | Cases |
|---|---|
| Permission | Picker cancel, selected-only access, Photos add denied/revoked, Camera denied gallery-only |
| Inputs | JPEG sRGB, HEIF P3, EXIF orientations, HDR input, malformed/huge image, local/cloud-only |
| Durability | Xóa Photos original sau managed import vẫn Lab được; kill lúc copy/export; low storage |
| Output | Pixel dimensions/crop, orientation/profile, metadata strip/preserve, full-res/no watermark |
| Consistency | Export revision A đang chạy, user sửa revision B; file A và UI B không bị trộn |
| Recovery | Photos save failed/uncertain, cancel share, repeated requestID, offline workflow |

## Exit và bàn giao

- [ ] Camera→Lab→Save Copy/Share và Photos→Lab→Export hoàn chỉnh trên thiết bị.
- [ ] Import source durable; iCloud-only/unsupported/raw-pending/corrupt có states đúng.
- [ ] Export color/orientation/metadata đúng, no watermark, source không đổi.
- [ ] Save failure không mất frame; unknown outcome không auto retry mù.
- [ ] Evidence `docs/evidence/M08/REPORT.md`; đủ gate Internal MVP, giao input/export adapters cho M9.
