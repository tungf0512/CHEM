# CHEM — Requirement traceability và scope coverage

> Tất cả ở trạng thái planned. ID bên dưới lấy từ [PRD](../../chem_prd_v1.0.md); chỗ không có ID dùng số section, không tự tạo ID giả.
> Mỗi dòng có milestone triển khai chính và nơi kiểm chứng cuối. Xem [README](README.md) để đối chiếu hệ milestone PRD với engineering plan.

## 1. Core features

| Requirement / nguồn | Công việc chủ đạo | Plan sở hữu | Evidence / gate |
|---|---|---|---|
| CAM-001 launch camera | Camera root, restore last valid film/lens | [M0](M00_PROJECT_FOUNDATION.md), [M1](M01_RELIABLE_CAMERA.md), [M12](M12_PRODUCTIZATION.md) | Cold/warm launch + fallback |
| CAM-002 live film | Native GPU preview, shared graph | [M2](M02_METAL_LIVE_PREVIEW.md), [M4](M04_SHARED_RENDERER.md), [M5](M05_FILM_ENGINE.md) | FPS + preview/final comparator |
| CAM-003 shutter | Immediate intent/feedback, sourceSafe receipt | [M1](M01_RELIABLE_CAMERA.md), [M3](M03_TRANSACTIONAL_CAPTURE.md) | Capture ledger/kill recovery |
| CAM-004 lens | Runtime catalog, ack/profile/capability reconciliation | [M1](M01_RELIABLE_CAMERA.md), [M10](M10_DEVICE_NORMALIZATION.md), [M11](M11_PRO_CONTROLS.md) | All available lens switching |
| CAM-005 focus/expose | Geometry mapping | [M1](M01_RELIABLE_CAMERA.md), [M2](M02_METAL_LIVE_PREVIEW.md) | Portrait/landscape corner taps |
| CAM-006 lock | Long press lock/unlock/lens reset | [M1](M01_RELIABLE_CAMERA.md), [M11](M11_PRO_CONTROLS.md) | Auto/manual interaction matrix |
| CAM-007 capture EV | Runtime range clamp + metadata | [M1](M01_RELIABLE_CAMERA.md), [M11](M11_PRO_CONTROLS.md) | Applied state/capture metadata |
| CAM-008 flash | Off/Auto/On if supported | [M1](M01_RELIABLE_CAMERA.md) | Supported/unsupported device |
| CAM-009 last frame | Thumbnail after source-safe, open Lab | [M3](M03_TRANSACTIONAL_CAPTURE.md), [M6](M06_FRAME_PERSISTENCE.md), [M7](M07_LAB_REDEVELOPMENT.md) | Correct ID after relaunch |
| CAM-010 film select | Active label, tap Shelf, swipe films | [M5](M05_FILM_ENGINE.md) | Descriptor ack matches capture |
| PRO-001…005 | Opt-in ISO/shutter/WB/focus | [M11](M11_PRO_CONTROLS.md), [M12](M12_PRODUCTIZATION.md) | Hardware + entitlement gates |
| PRO-006 histogram | Optional throttled native histogram | [M11](M11_PRO_CONTROLS.md) | Ship only if performance allows |
| FILM-001 | Three engine films → eight V1 films | [M5](M05_FILM_ENGINE.md), [M12](M12_PRODUCTIZATION.md) | Eight profile approvals before V1 |
| FILM-002 detail | Identity/character/use/live preview | [M5](M05_FILM_ENGINE.md), [M12](M12_PRODUCTIZATION.md) | Same scene renderer; denied fallback |
| FILM-003/004 | One favorite, curated ordering | [M5](M05_FILM_ENGINE.md), [M12](M12_PRODUCTIZATION.md) | Persisted favorite/launch policy |
| NEG-001 | Durable source immutable | [M3](M03_TRANSACTIONAL_CAPTURE.md), [M6](M06_FRAME_PERSISTENCE.md) | Checksums/recovery/cache safety |
| NEG-002/003 | Standard/Negative, storage transparency | [M9](M09_RAW_PRORAW.md), [M12](M12_PRODUCTIZATION.md) | Paired-source and storage UX |
| DEV-001/002 | Re-develop/determinism/versioning | [M4](M04_SHARED_RENDERER.md), [M6](M06_FRAME_PERSISTENCE.md), [M7](M07_LAB_REDEVELOPMENT.md) | Revision/seed/old-version tests |
| LAB-001…005 | Film/EV/process/grain/before-after | [M7](M07_LAB_REDEVELOPMENT.md) | Real renders, latest revision only |
| LAB-006 / EXP-001…003 | Save Copy/share/HEIF/JPEG | [M8](M08_PHOTOS_WORKFLOW.md) | Photos + system share + color/metadata |
| GAL-001/003 | Scoped picker/shared engine | [M8](M08_PHOTOS_WORKFLOW.md) | Gallery-only vertical slice |
| GAL-002 | HEIF/JPEG + supported RAW | [M8](M08_PHOTOS_WORKFLOW.md), [M9](M09_RAW_PRORAW.md) | Input-format support matrix |
| GAL-004 | Source strategy | [M8](M08_PHOTOS_WORKFLOW.md) | Managed-copy proposal recorded, source access loss |
| ROLL-001…003 | Create/activate/default film/per-frame override | [M6](M06_FRAME_PERSISTENCE.md), [M12](M12_PRODUCTIZATION.md) | Membership at shutter + safe roll delete |
| ROLL-004 | Contact sheets | V1.5 backlog | Không chặn V1 |
| RAW-001…004 | Runtime RAW/pro support, paired bundle/decode | [M9](M09_RAW_PRORAW.md) | Native files valid after restart |

## 2. Imaging, reliability và cross-cutting requirements

| Requirement / nguồn | Owner milestone | Chứng minh |
|---|---|---|
| ENG-001 shared semantics | M4/M5 | Same-input cross-quality và live-vs-still |
| ENG-002 precision / ENG-003 gamut | M2/M4/M8 | Ramps, floating point pipeline, output profile |
| ENG-004 grain | M5 | Fixed seed, scale-aware, no tiling |
| ENG-005/006 halation/bloom | M5 | Highlight-dependent, shadow không haze |
| ENG-007 toe/shoulder | M4/M5 | Tone response regression |
| §28–30 calibration/scene analyzer | M4 generic/statistics; M10 real profiles | Versioned deterministic context, on-device |
| REL-001…004 source first/no silent loss | M3/M6/M8/M13 | Fault matrix + capture/export ledger |
| §38 scheduling, §79 concurrency | M2/M3/M4 | Native bounded queue, source IO priority, off-main |
| §40 lifecycle | M1/M2/M11/M13 | Interrupt/resume/manual reset |
| §41 performance | M0 baseline, M2/M4/M7, M13 final | Measured device/build p50/p95, documented targets |
| §42 thermal | M2/M4/M9/M13 | Tier fallback, final quality intact |
| §43 color management | M4/M8/M13 | HEIF P3/JPEG sRGB transform + tag |
| §45–46 storage/deletion | M3/M6/M12 | Source/cache split, tombstone/recovery, Photos independence |
| PRIV-001…006 | M0/M8/M12/M13 | No account/upload/ad SDK/tracking, scoped Photos, minimized diagnostics |
| §48–49 analytics | M0 local logs, M12 telemetry | No image/sensitive payload, opt policy |
| A11Y-001…005 | M0 components, every feature, M12/M13 audit | Labels/targets/color independence/Reduce Motion/haptic alternatives |
| §51 localization | M0 scaffold, M12/M13 | en/vi complete + locale layout |
| §52 errors, §88–92 safety/permission | M1/M3/M6/M8/M9/M12 | User-actionable typed errors and recovery |
| §53 offline | M0 architecture, M8/M12/M13 | Local camera/import/develop/export, known entitlement handling |
| PAY-001…005 / §54 Free–Pro | M12/M13 | Verified purchase/restore, no watermark/countdown, localized price |
| §57–60 design/icon/haptics/sound | M0/M12/M13 | UI mapping, local assets, platform sound behavior |
| §61–66 regression/device/OS policy | M0/M4/M5/M10/M13 | Calibration tiers, real hardware evidence |
| §67 front camera | Deferred proposed | Nếu đưa V1 phải mở lại scope/orientation/mirror/color tests |
| §68 orientation / §69–70 aspect/crop | M1/M2/M4/M7/M12 | Portrait/landscape, 4:3/3:2/1:1 non-destructive |
| §71–72 metadata/location | M8/M12 | Truthful metadata, export strip preference |
| §73–76 settings/grid/reset | M1/M6/M7/M12 | Persistent settings; two reset actions |
| §77–85 jobs/cache/schema/versions | M3/M4/M6/M8 | Frozen revision, deterministic key, migration + old resources |
| §86–87 import/parse security | M5/M8/M9 | Validate resources/formats/dimensions/memory/owned paths |
| §97–103 beta/release | M13 | Beta exit + zero blockers + actual store assets |

## 3. Roadmap ngoài V1

| Scope | Định hướng từ PRD | Foundation đã chuẩn bị |
|---|---|---|
| Batch develop/safety | V1.5 §95–96 | Native job states/priority và per-frame failure |
| Saved/import/export recipes | V1.5 §10.4; sharing V2 candidate | Recipe schema/version/revision |
| Widgets / Lock Screen launch | V1.5 candidate | Camera-root navigation, cần native extension plan riêng |
| Contact sheets | V1 optional, đề xuất V1.5 | Rolls và frame thumbnails |
| Recipe ecosystem / Film Maker / iCloud | V2 candidate | Không thêm cloud dependency vào V1 |
| Video / temporal effects / Apple Log | V3 candidate | Shared renderer là foundation, chưa cam kết video pipeline |

Không có implementation milestone sau M13 trong engineering plan gốc. Những candidate tương lai cần PRD cập nhật, acceptance criteria và platform scope trước khi tách plan triển khai cụ thể.

## 4. Checklist tránh bỏ sót lúc review

- [ ] Ba prototype film không bị nhầm thành ba free film.
- [ ] Eight-stock approval, Rolls V1 cơ bản và en/vi được tính trong productization.
- [ ] Save/Share không ký xong ở M7 khi chưa có Photos integration M8.
- [ ] Persistence/source safety bắt đầu M3, không đợi M6.
- [ ] RN bridge/events/surface lifecycle và JS restart có test riêng ngoài camera tests gốc.
- [ ] RAW paired source, old renderer compatibility và color transform có behavior thật.
- [ ] Mockup dữ liệu giả/format sai được sửa theo UI mapping.
- [ ] M13 có entry beta và exit Public V1 riêng, không đổi scope âm thầm.
