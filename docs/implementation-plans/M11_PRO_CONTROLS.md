# M11 — Pro Mode: manual camera controls

> Trạng thái: chưa triển khai · Phụ thuộc: M1/M8/M10; Negative integration cần M9 · Owner: iOS + FE.
> Nguồn: engineering plan §25; PRD PRO-001…006, CAM-006/007, §16, §75.
> UI tham chiếu: `chem_pro_mode_viewfinder/`.

## Mục tiêu

Pro Mode opt-in cho ISO/shutter/WB/focus có range từ camera đang active, preview film vẫn chạy. Default Camera giữ đơn giản. Entitlement enforcement thật hoàn thiện M12; Internal có override có kiểm soát.

## Ticket

| ID | Owner | Công việc | Output / tiêu chí |
|---|---|---|---|
| M11-T01 | iOS | Manual capabilities/ranges theo active device/config revision | Numeric ranges và flags gửi RN; no hardcode mockup |
| M11-T02 | FE | Pro strip, chọn ISO/SEC/WB/focus, stepped dial và Auto reset | Typography/touch targets/accessibility; không thêm dashboard mặc định |
| M11-T03 | iOS | Set manual ISO/exposure duration với safe range/rational duration | Ack applied values; UI phản ánh giá trị thật |
| M11-T04 | iOS + FE | WB Auto/Kelvin/Tint → valid device gains, clamp | Film warmth và capture WB tách model/nhãn |
| M11-T05 | iOS + FE | Manual focus normalized 0…1 nếu hỗ trợ, auto-focus reset | Không hiển thị số mét giả từ lensPosition chưa hiệu chuẩn |
| M11-T06 | iOS | Lens-change reconciliation, mode reset/clamp, interruption resume | Không áp range cũ; request stale capability revision bị reject/reconcile |
| M11-T07 | iOS + FE | Manual exposure vs capture EV vs AE/AF lock semantics | Disabled/explained khi xung đột; không cộng development EV vào sensor |
| M11-T08 | Imaging + FE | Optional histogram native aggregated/throttled, chỉ bật nếu đạt budget | Không fake bars; có thể defer histogram mà core manual vẫn đủ |
| M11-T09 | QA | Runtime matrix/manual capture metadata/performance tests | Manual settings đúng capture, auto path hồi phục đầy đủ |

## Camera-control contract

```text
Auto exposure: captureExposureCompensationEV áp dụng theo device limits
Manual exposure: ISO + duration được set cùng intent hợp lệ; EV bias UI tắt/giải thích
Capture WB/focus: acquisition settings lưu trong captureMetadata
Development EV/warmth/process: recipe trong renderer, không sửa acquisition history
```

Command mang `expectedCapabilityRevision`; native thực hiện trên session owner, trả `appliedControlState`. Coalesce khi kéo dial, giữ final gesture value. Không queue hàng trăm camera config requests; visual dial vẫn cập nhật mượt, native ack quyết định readout applied.

Khi lens switch: query capability → chuyển hardware → reset/clamp theo policy → atomically publish state/profile revision. Long exposure có thể làm preview FPS thấp theo vật lý; đo riêng manual long-exposure scenarios và ghi giới hạn thay vì báo đạt 30/60 fps mọi exposure.

AE/AF lock hiển thị khi phần auto được khóa thật. Manual exposure không dùng cùng badge để giả lock toàn camera. Pro badge cho UI mode không đồng nghĩa đang chụp RAW; RAW badge chỉ khi capture mode/capability thực tế phù hợp.

## File dự kiến

- `CameraCore/Controls/{ManualExposureController,WhiteBalanceController,ManualFocusController,ControlReconciler}.swift`.
- `Domain/Camera/{CaptureCapabilities,AppliedControlState}.swift`.
- `src/features/camera/pro/{ProControlStrip,SteppedDial,WhiteBalanceControls,FocusControl}.tsx`.
- Extension `NativeChemCamera` specs và native adapter; histogram optional native sampler.

## Kế hoạch nghiệm thu

- Min/max/near-boundary values, unsupported controls, stale revision, repeated drag, rapid lens switch.
- Capture rồi kiểm captureMetadata/EXIF với applied values; số đo có tolerance do sensor/platform được ghi rõ.
- Auto → manual → interruption → resume → lens khác → auto: không stuck camera, restore policy dễ hiểu.
- Camera denied/entitlement unknown/free và RAW unsupported cho UI đúng; không cho custom native command bypass khi M12 bật enforcement.
- VoiceOver adjustable actions cho dial, Increase/Decrease labels, landscape, larger text, Reduce Motion.
- Performance normal auto path không suy giảm; long-exposure limits được document riêng.

## Exit và bàn giao

- [ ] ISO/shutter/WB/focus thật và capability-gated, film preview hoạt động.
- [ ] Capture settings/version freeze đúng, no conflict capture EV/development EV.
- [ ] Lens/interrupt reconciliation và trở về Auto đáng tin cậy.
- [ ] Không hardcode meter/ISO/remaining-count fake từ mockup.
- [ ] Evidence `docs/evidence/M11/REPORT.md`; feature matrix/manual availability bàn giao M12.
