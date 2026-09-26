# M13 — Beta hardening và Public V1 release

> Trạng thái: chưa triển khai · Phụ thuộc: M12 và evidence các milestone trước.
> Owner: QA + FE + iOS + Imaging; Product quyết định release.
> Nguồn: engineering plan §88–95, §110–113, Appendix I; PRD §41–43, §61–66, §97–103, §118, §123.

## Mục tiêu

Chứng minh app đáng tin trên matrix thiết bị/OS thực, hoàn thiện beta feedback và artifact phát hành. M13 tích hợp/retest các thay đổi cuối; reliability, imaging và migration phải đã được làm từ milestone sở hữu chúng.

## Entry gate external beta

- Camera/resume/capture ổn định, không known source-loss; M3 kill/recovery evidence có thật.
- Ba đến năm film mạnh, Lab/import/export/color ổn định, common full-res input không gây memory crash.
- M12 accessibility/privacy baseline, build được ký, support/feedback mechanism rõ.
- Có feature readiness matrix và flags; RAW có thể tắt trong beta nếu chưa đạt nhưng phải ghi scope beta khác Public V1.
- Không phát hành debug flags gây fault injection hoặc giả entitlement cho người dùng ngoài.

## Ticket

| ID | Owner | Công việc | Output / pass |
|---|---|---|---|
| M13-T01 | QA + Product | Freeze device/OS/capability matrix, beta scope, severity/quality thresholds | Model/OS/build thật, owner cho từng ô; không chỉ ghi “recent device” |
| M13-T02 | QA + iOS | Capture/lifecycle/storage/recovery soak, 100-frame loops, fault injection | Zero silently lost sourceSafe frames, exact request ledger |
| M13-T03 | Imaging + QA | 8 films × representative scenes/lenses/input paths, output metadata | Approved look, no severe mismatch/profile/orientation bugs |
| M13-T04 | FE + iOS + Imaging | Release performance, startup decomposition, JS/UI/GPU profiling, memory/thermal tuning | PRD targets và per-device exceptions được review |
| M13-T05 | QA + iOS | Upgrade/migration/delete/cache/entitlement/offline matrix | Existing frames/recipes/rolls/source/verified rights không mất |
| M13-T06 | FE + QA | Full UX/accessibility/localization on small/large/landscape screens | Không overlap shutter, controls usable với VoiceOver/larger text |
| M13-T07 | Product + QA | TestFlight cohort, feedback issues về trust/speed/color, triage và regressions | Beta exit report có denominator/sample, không tỷ lệ mơ hồ |
| M13-T08 | Product + Design + iOS | App icon/screenshots/copy/privacy/support/licenses, store listing/purchase config | Metadata khớp feature thật, chính sách platform được rà ở thời điểm nộp |
| M13-T09 | iOS + QA | Freeze RC binary/resources, release smoke, symbols và version manifest | Build có thể tái lập/trace về source và film/profile versions |
| M13-T10 | Product + iOS | Release checklist/sign-off, rollout/incident plan | Quyết định release dựa evidence; monitor/patch bảo toàn dữ liệu |

## Device / OS / capability matrix phải điền

| Thiết bị thật | OS version | Lens/format khả dụng | Profile tier | Camera/RAW/Pro | Lab/import/export | Startup/FPS/memory/thermal | Evidence |
|---|---|---|---|---|---|---|---|
| Recent Pro: chốt M0 | Minimum + target nếu có máy tương ứng | Discover runtime | Calibrated/generic | Chưa chạy | Chưa chạy | Chưa đo | Chưa có |
| Recent base: chốt M0 | Trong supported OS range | Discover runtime | Calibrated/generic | Chưa chạy | Chưa chạy | Chưa đo | Chưa có |
| Intended baseline: chốt M0 | Minimum supported OS | Discover runtime | Calibrated/generic | Chưa chạy | Chưa chạy | Chưa đo | Chưa có |

Một thiết bị không nhất thiết cài được mọi OS; chuẩn bị máy riêng cho coverage cần thiết. Full suite trên main/UW/tele có thật; RAW/manual rows capability-gated. Thêm front-camera row chỉ khi Product đổi scope và có test riêng. Simulator không thay device QA.

## Performance gates

| Chỉ số | Mục tiêu / cách ghi |
|---|---|
| Cold usable camera | PRD <1,5 s trên baseline target; đo Release, không tính prompt permission lần đầu |
| Warm perceived ready | PRD <500 ms khi feasible; phân biệt resume và full process launch |
| Shutter UI feedback | PRD <50 ms perceived; tách khỏi sensor/sourceSafe/final latency |
| Live preview | Stable ≥30 fps baseline, ưu tiên 60 fps recent devices; report resolution/tier/thermal/drop rate |
| Interactive Lab | Target đề xuất M7 được freeze; không ghi như PRD requirement |
| Full-res render | 12/24/48 MP where supported; p50/p95 latency và peak memory, không invented universal SLA |
| Memory/queue | Không unbounded growth; per-device caps/admission M2/M4 được đo và freeze |
| Thermal | Sustained session, tier fallback ổn định; không mất source/âm thầm giảm final quality |

Ghi sample count, warmup, build, device/OS, source size, film/effect workload, p50/p95. Minimum FPS baseline đo ở normal auto capture; long manual exposures có giới hạn riêng M11. Nếu mục tiêu không đạt, tối ưu hoặc thay supported-device policy có quyết định Product; không tự đánh dấu pass.

## Reliability, upgrade và privacy scenarios

1. Fresh install → onboarding allow/deny → Camera hoặc Gallery-only.
2. 100 normal/repeated captures per representative device, all available lenses, rotate, background/resume, interruption.
3. Terminate sau file rename/trước DB commit, sau sourceSafe/trước JS receipt, trong final/export/delete; relaunch đối chiếu ledger/checksum.
4. Low storage/disk-full race, missing cache, corrupt import/RAW, memory warning/thermal pressure; recovery hoặc actionable error.
5. Camera DAY → Lab SKIN/Push +1 → reset/crop → export HEIF P3/JPEG sRGB; nhận đúng orientation/metadata.
6. Import local/cloud-only/unsupported/corrupt, revoke Photos, saveOutcomeUnknown và retry không mù.
7. Upgrade từ mọi schema public/fixture bắt buộc; source/recipes/rolls và versioned look còn đúng; không tự xóa DB khi migration fail.
8. Free/Pro purchase/restore/pending/revoked/offline với known/unknown entitlement; Camera free không block.
9. JS restart, route remount, surface recycling, late/stale events; không double capture/session, UI resync snapshot.
10. Telemetry off, location strip, no image upload; release binary không debug HUD/fake purchase/fault flags.

## Release blockers

Bất kỳ known source loss/corruption, camera deadlock/common crash, sai orientation/color-profile tag, severe preview/final mismatch, Photos save silent failure, invalid RAW, broken restore/entitlement, migration data loss, cache cleanup đụng source đều chặn release. Không dùng trung bình crash-free tốt để miễn trừ một lỗi mất ảnh đã biết.

PRD chưa chốt tỷ lệ crash-free, số beta users hay thời gian beta. M13-T01 phải đặt threshold trước beta, ghi sample/coverage đủ để đánh giá; không tự thêm một con số rồi xem là bằng chứng đã đạt. Mục tiêu qualitative: ít nhất ba stock được beta users ưa thích cho use case khác nhau, camera reliability và color trust đạt review.

## Release artifacts và vận hành

- `docs/evidence/M13/REPORT.md`, device matrix, benchmark/regression manifests, migration/purchase reports, known-issues list.
- `docs/release/V1_CHECKLIST.md`, actual version/build, signed archive/symbols, resource hashes, privacy/support URLs và screenshots đã duyệt.
- Xác nhận bundle ID/signing/product ID/localized price/config tại App Store Connect; kiểm tra yêu cầu Apple hiện hành lúc submit, không coi checklist tại ngày viết plan thay chính sách tương lai.
- Rollout theo quy trình Product chốt; khi lỗi nghiêm trọng thì dừng rollout, giữ data, hotfix forward. Không giả định App Store cho rollback binary tức thời, không chạy destructive migration để “fix” crash.
- Sau release theo dõi capture/source-safe/export success, crash/performance với consent policy; patch phải chạy lại relevant gates nếu đổi camera/render/schema.

## Exit Public V1

- [ ] M0–M12 có evidence; không unresolved release blocker.
- [ ] Tám film, camera/Lab/gallery, RAW/pro nơi hỗ trợ, Rolls cơ bản đúng scope đã chốt.
- [ ] Device/OS matrix, color, migration, offline, purchase/restore, accessibility/localization đạt.
- [ ] Beta exit report và RC smoke được sign-off; store/privacy/support assets hoàn chỉnh.
- [ ] Release decision và incident plan được ghi; rollout là bước triển khai về sau, tài liệu này chưa thực hiện publish.
