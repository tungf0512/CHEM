# M6 — CHEM frame, recipe và persistence lifecycle

> Trạng thái: chưa triển khai · Phụ thuộc: M3 + M4, tích hợp film M5 · Owner: iOS + FE.
> Nguồn: engineering plan §20, §28, §37–38, §60–61, §67; PRD §20–22, §26–27, §45–46, §76–84.

## Mục tiêu

Hoàn thiện repository trên store đã tạo ở M3 để frame có thể duyệt, mở lại, đổi recipe, xóa có chủ đích và migrate qua app update. Không tạo database JS thứ hai hoặc chờ M6 mới bảo vệ source.

## Data contract

| Entity | Trường/chức năng quan trọng |
|---|---|
| FrameRecord | UUID, timestamps, acquisition/import origin, source bundle/checksum, capture metadata, orientation/color/dimensions, optional Photos ID/rollID, state |
| RecipeRevision | Schema version, film/version, development EV, process/grain/warmth/crop, renderer/profile/scene references, seed, revision |
| CapturedRecipe | Immutable baseline riêng; Reset to captured không dùng current recipe đã sửa |
| RenderRecord | Frame/revision/descriptor hash, quality/output specs, checksum/path/state |
| ExportJob | RequestID/idempotency, frozen revision, destination/options, Photos result/state |
| RollRecord | ID/title/note/date range/default film; schema sẵn, CRUD UI triển khai M12 |

Tách capture metadata (ISO/shutter/WB/capture EV) khỏi recipe development exposure. Đường dẫn relative trong app container; không lưu absolute sandbox prefix thay đổi sau restore/update. File ảnh lớn ở filesystem, không image blob trong SwiftData.

## Ticket

| ID | Owner | Công việc | Output / tiêu chí |
|---|---|---|---|
| M06-T01 | iOS | Hoàn thiện schema/entities trên M3 store, constraints/indices | Frame và source associations không mất sau reopen |
| M06-T02 | iOS + FE | `listFrames(cursor, limit)`, detail DTO và native events | Pagination ổn định, không load toàn bộ ảnh/full-res vào JS |
| M06-T03 | iOS | Revisioned recipe update với baseRevision check, captured/default reset | Conflict có phản hồi; stale update không overwrite latest |
| M06-T04 | iOS | Derived cache fingerprint/eviction/rebuild và storage accounting | Clear Cache giữ source/recipe; thumbnails tạo lại được |
| M06-T05 | iOS | Delete tombstone → cancel/coordinate jobs → files → DB cleanup | Relaunch tiếp tục delete; late render không resurrect frame |
| M06-T06 | iOS | VersionedSchema/MigrationPlan, resource compatibility resolver | Nâng app giữ frame/revisions/roll refs; fail migration không reset DB |
| M06-T07 | FE | Lab frame grid/list, empty/loading/recoverable/missing source UI, last-frame routing | Sau launch/recovery last frame mở đúng ID |
| M06-T08 | QA + iOS | Seeded fixtures/migration/failure matrix | Chứng minh integrity bằng counts/checksums/foreign refs và readback |

## Quy tắc version và migration

Lưu film/profile/renderer version là điều kiện cần. Bundle hoặc có compatibility implementation cho những version public còn được tham chiếu. Không thay look cũ bằng newest khi resource thiếu. UI báo version unavailable nhưng giữ source/render hiện có; explicit upgrade tạo revision mới.

Trước public release, tạo fixture schema cũ bằng model thực tế và test upgrade vào model mới. Migration phải giữ source checksums, captured recipe, seed, Photos references, roll membership. Downgrade binary chưa hỗ trợ phải báo lỗi bảo toàn dữ liệu, không tự wipe. Recovery M3 chạy sau store mở/migrate thành công.

Xóa negative là destructive user intent rõ. “Clear Cache”, “Delete CHEM Frame” và “Manage Negatives” phải khác nhau. Đề xuất V1 chỉ cho xóa cả frame + negative sau giải thích, không thêm chế độ giữ frame nhưng mất source khi chưa có UX riêng. Photos copy đã export tồn tại độc lập.

## File dự kiến

- `Persistence/Models/{FrameRecord,RecipeRevisionRecord,RenderRecord,ExportJobRecord,RollRecord}.swift`.
- `Persistence/{FrameRepository,RecipeRepository,StorageAccounting,DeletionCoordinator}.swift`.
- `Persistence/Migrations/`, `ChemNativeTests/{Migration,Persistence}/`.
- `specs/NativeChemFrames.ts`, `src/native/FrameRepositoryAdapter.ts`.
- `src/features/lab/{FrameLibraryScreen,FrameGrid,FrameStatusBadge}.tsx`.

## Kế hoạch nghiệm thu

- Create/reopen/query/update/delete, reorder pages khi capture mới tới, paging không duplicate/skip do cursor lỗi.
- Hai update cùng base revision: một được accept, cái còn lại reconcile; out-of-order native events không đưa UI về cũ.
- Kill trong delete/migrate/recovery, missing cache, malformed metadata, disk-full khi update; source không bị clear-cache đụng tới.
- Đề xuất fixture 1.000 frame metadata và thumbnails bounded để đo scroll/memory/query latency; số lượng này là stress target bổ sung, không phải quota sản phẩm.
- Bridge UInt64 seed roundtrip qua string; source checksum trước/sau recipe edit/reset không đổi.

## Exit và bàn giao

- [ ] Repository/query/recipe revision dùng native source of truth.
- [ ] Relaunch phục hồi frame/recipe/version, pagination và last-frame đúng.
- [ ] Migration và deletion recovery có evidence, không known data-loss.
- [ ] Resource compatibility policy thực thi được, không chỉ có version string.
- [ ] Evidence `docs/evidence/M06/REPORT.md`; frame library và revision API sẵn cho M7.
