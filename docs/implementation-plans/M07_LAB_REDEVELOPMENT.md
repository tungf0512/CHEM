# M7 — CHEM Lab và non-destructive re-development

> Trạng thái: chưa triển khai · Phụ thuộc: M5 + M6 · Owner: FE + Imaging + iOS.
> Nguồn: engineering plan §21, §35, §71; PRD DEV-001/002, LAB-001…006, §69–70, §76.
> UI tham chiếu: `chem_darkroom_lab/code.html`, `screen.png`.

## Mục tiêu

Frame đã chụp mở trong Lab, đổi film/exposure/process/grain, before/after và reset, giữ nguyên source. M7 xuất được derived image nội bộ để chứng minh full-res integration. **Save to Photos và system Share hoàn tất M8**; nút chưa tích hợp không được giả báo thành công.

## Ticket

| ID | Owner | Công việc | Output / tiêu chí |
|---|---|---|---|
| M07-T01 | FE + iOS | Open frame từ library/thumbnail bằng ID, load DTO/source handle | Loading/missing/corrupt/source-safe-needs-development có UI rõ |
| M07-T02 | FE + Imaging | Fabric Lab surface, display-sized decode, immutable working descriptor | Giao diện interactive không cần full-res mỗi lần kéo |
| M07-T03 | FE + iOS | Film carousel, EV -2…+2, Pull -1/Normal/Push +1, Fine/Normal/Rough | Điều khiển cập nhật native render thật, state/labels accessible |
| M07-T04 | iOS + Imaging | Latest-request scheduler, cancel queued jobs, revision guard cho output | Kết quả cũ hoàn tất muộn không ghi đè preview mới |
| M07-T05 | FE + iOS | Autosave recipe revisions, dirty/saving/error, explicit retry | Chỉ báo saved sau native commit; reconnect đọc durable revision |
| M07-T06 | FE + Imaging | Hold original normalized + toggle thay thế cho VoiceOver | Cùng crop/orientation/color display; không simulated Bayer negative |
| M07-T07 | FE + iOS | Reset to captured recipe và reset to selected film defaults | Hai hành động khác nhau; source/seed policy rõ |
| M07-T08 | FE + Imaging | Aspect crop 4:3/3:2/1:1 theo contract, optional warmth giữ ẩn mặc định | Crop là recipe; không rewrite source; không thêm HSL/masks |
| M07-T09 | iOS + FE | Full-res render request freeze revision và handoff export flow M8 | Internal output tương ứng đúng revision, processing/error có thật |

## State và interaction contract

```text
loading → ready → editing → previewPending → ready
editing → recipeSaving → recipeSaved
previewPending → recoverableRenderError → retry
loading → sourceUnavailable → reselect/help nếu có thể
```

UI draft cập nhật ngay; dùng debounce/coalescing cho preview và writes, luôn có final flush khi gesture kết thúc. Native write acknowledgement quyết định durable state. Khi rời Lab, chờ write đang cần lưu hoặc hiện lựa chọn xử lý nếu lỗi; không giả định JS async task còn chạy sau process kill. Recipe chưa ack có thể mất khi kill, nhưng source/captured recipe luôn còn.

Mỗi preview job có frameID + recipe revision/draft token + request sequence + surface lease. GPU job đã submitted có thể không hủy vật lý; vẫn bỏ output stale. Khi đổi frame, release screen-size decoded input cũ theo resource lifetime, không giữ nhiều RAW/full-res buffers.

Before view là source-normalized representation, không đồng nghĩa RAW sensor bytes. UI ghi “Original”/“Bản gốc” rõ; không mặc định “ProRAW DNG” nếu source thực tế là HEIF/import JPEG.

## File dự kiến

- `src/features/lab/{LabScreen,LabController,LabControls,BeforeAfterControl,RecipeResetSheet}.tsx`.
- `specs/ChemLabNativeComponent.ts`, `specs/NativeChemRendering.ts`.
- `Imaging/Interactive/{InteractiveRenderSession,DisplaySourceCache}.swift`.
- `Domain/Recipes/RecipeEditingService.swift`.
- Lab state/component fixtures và native revision-order integration cases.

## Kế hoạch nghiệm thu

1. Capture DAY → mở Lab → SKIN → Push +1 → Rough → relaunch: recipe đã ack còn đúng.
2. Chuyển film và kéo sliders nhanh; inject render delay để ép out-of-order completion, chỉ newest hiển thị.
3. Checksum source không đổi qua edit/reset/crop; reset captured khôi phục đúng version/values ban đầu.
4. Before/after giữ geometry và dùng image data thật; accessible alternative hoạt động.
5. Render failure/out-of-memory có retry, nguồn an toàn; back về Camera giải phóng Lab jobs/resources phù hợp.
6. Đề xuất p95 interactive update ≤150 ms trên primary device với display-sized input; freeze sau M4 benchmark và ghi rõ đây là target bổ sung, không phải số từ PRD.

## Exit và bàn giao

- [ ] Film/exposure/process/grain thật, recipe autosave/reset đúng.
- [ ] Source immutable, revision race được xử lý, unsupported old version có error rõ.
- [ ] Lab responsive với bounded memory, UI portrait/landscape/VoiceOver phù hợp.
- [ ] Internal full-res output khớp selected revision; export boundary sẵn cho M8.
- [ ] Evidence `docs/evidence/M07/REPORT.md`; feature save/share chỉ được ký hoàn tất sau M8.
