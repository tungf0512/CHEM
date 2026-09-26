# M3 — Transactional capture và source safety

> Trạng thái: chưa triển khai · Phụ thuộc: M1; tích hợp với preview M2 · Owner: iOS.
> Nguồn: engineering plan §13, §34, §43, §60–61, INV-01/02; PRD NEG-001, REL-001…004, §88–90.

## Mục tiêu

Khi native báo `sourceSafe`, ảnh gốc và đủ metadata để phát triển lại phải sống qua app termination/render failure. M3 triển khai database/schema tối thiểu ngay tại đây; M6 mở rộng cùng store. Không trì hoãn persistence đến M6.

## Ticket

| ID | Owner | Công việc | Output / tiêu chí |
|---|---|---|---|
| M03-T01 | iOS | FrameDraft + schema v1 + unique requestID, descriptor/capture/roll snapshot | Draft durable trước sensor request; duplicate request không chụp lần hai |
| M03-T02 | iOS | FileStore: app-owned UUID paths, temp file, validate/flush/rename, checksum | Source hợp lệ nằm Application Support, không cache |
| M03-T03 | iOS | Recovery manifest cùng source bundle; DB sourceSafe commit sau file commit | Có thể phục hồi file đã rename nhưng DB chưa cập nhật |
| M03-T04 | iOS | CaptureCoordinator, delegate correlation và state transitions | Event và Promise sourceSafe chỉ phát sau durable commit |
| M03-T05 | iOS + Imaging | Native post-capture thumbnail/final job stub, bounded capture/render admission | Render failure không mất source; chưa có final engine thì giữ pending |
| M03-T06 | FE | Shutter feedback, saving/developing/retry, last-frame thumbnail | Không báo success từ animation hay lúc nhận sensor bytes |
| M03-T07 | iOS | Recovery scanner idempotent, classify drafts/orphans/corrupt data | Relaunch tiếp tục recover/render, không xóa nhầm source chưa được nhận diện |
| M03-T08 | iOS + QA | Failure injection tại từng điểm file/DB/state + low storage | Ledger đối soát mọi accepted request với durable source hoặc lỗi rõ |

## Trình tự và semantics

```text
requestCreated → sensorCapturing → sourceReceived → persistingSource
→ sourceSafe → previewGenerating → finalRenderPending → rendered
```

`captureFailed` chỉ dùng khi không có recoverable source. Lỗi sau sourceSafe là `recoverableError` của stage tương ứng, không đánh dấu toàn frame mất. Export là state độc lập để một frame chỉ giữ nội bộ vẫn hoàn tất capture/render.

Receipt có `frameID`, `requestID`, `state`, `sequence`, descriptor revision. Promise có thể resolve chậm/mất do JS restart; snapshot/query theo requestID là nguồn xác nhận. Freeze film/profile/renderer/seed/crop và lens/session revision trước chụp. Nếu lens hoặc film đang chuyển, reconcile/reject rõ; không chụp với metadata từ lens cũ.

SourceBundle có processed primary, optional RAW/companion slots từ đầu. M3 chỉ điền processed; M9 bổ sung capture paired, không đổi nguyên tắc durability.

## Recovery matrix bắt buộc

| Điểm dừng/lỗi | Durable state có thể có | Hành vi khi mở lại |
|---|---|---|
| Draft trước sensor callback | Draft, chưa file | Reconcile delegate không còn; mark failed rõ, không success giả |
| Đang ghi temp | Temp chưa validate | Không coi sourceSafe; giữ/quarantine theo policy và báo incomplete |
| Rename source xong, DB chưa commit | Source + recovery manifest | Validate rồi adopt vào DB với cùng frameID |
| DB sourceSafe, event JS chưa tới | Source + DB | Snapshot trả frame; không chụp lại vì mất event |
| Final render lỗi/app kill | Source + pending job | Requeue sau recovery, user vẫn thấy frame an toàn |
| Photos save lỗi | Internal source/render | Giữ retry export; không rollback capture |
| DB có sourceSafe nhưng file hỏng/mất | Metadata không khớp thực tế | Corruption/source-unavailable rõ; không crash/âm thầm remove record |
| Clear Cache | Chỉ derived outputs bị xóa | Recreate thumbnails/renders từ source |

File rename và DB commit không atomic chung; manifest/reconciliation là phần bắt buộc. DB migration lỗi không được tự reset store. Recovery có budget và chạy off-main, ưu tiên frame gần nhất; không scan toàn kho đồng bộ trước mở Camera.

## File dự kiến

- `Persistence/Models/{FrameRecord,SourceRecord}.swift`, `Persistence/Migrations/SchemaV1.swift`.
- `Persistence/Files/{FrameFileStore,SourceManifest}.swift`.
- `Persistence/Recovery/{FrameRecoveryService,OrphanReconciler}.swift`.
- `Domain/Capture/{CaptureIntent,CaptureReceipt}.swift`, `CameraCore/Capture/CaptureCoordinator.swift`.
- `src/features/camera/{CaptureState,LastFrameThumbnail}.tsx`; failure hooks Internal-only.

## Kế hoạch nghiệm thu

- Automated state/file/DB fault injection, gồm write/rename/commit failures và disk-full dù preflight báo đủ.
- Trên iPhone, terminate tại các boundary trong matrix; checksum source trước/sau relaunch và clear-cache không đổi.
- Rapid taps khi final queue chậm: tất cả accepted requests có ledger, admission reject rõ khi thiếu budget. Không cần Burst mode.
- JS reload ngay sau shutter: native không phụ thuộc RN promise để commit; reconnect không duplicate.
- Native haptic/visual feedback vẫn tức thì; source IO không chặn main thread/preview.

## Exit và bàn giao

- [ ] Mọi sourceSafe frame đọc được sau relaunch/failure scenarios.
- [ ] Recovery chạy lặp không nhân đôi frame/render job.
- [ ] Cache/source phân vùng và deletion semantics có tests.
- [ ] Không source loss đã biết; báo cáo ghi rõ cửa sổ trước sourceSafe không thể bảo đảm capture thành công.
- [ ] `docs/evidence/M03/REPORT.md` có failure ledger; bàn giao durable store cho M4/M6.
