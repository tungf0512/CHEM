# M1 — Reliable camera foundation

> Trạng thái: chưa triển khai · Phụ thuộc: M0 · Owner: iOS, FE tích hợp UI.
> Nguồn: engineering plan §11, §42, §56–59; PRD CAM-001, 003–008, §40, §68, §74–75.

## Mục tiêu và đầu vào

Camera thật mở, resume, chọn lens, focus/EV và chụp processed still ổn định. M1 chưa bật film effects. M0 phải bàn giao RN shell, module/view adapter và thiết bị test.

Session thuộc `CameraSessionController` với một serial execution context. `AVCaptureVideoDataOutput` cấp input cho preview; `AVCapturePhotoOutput` chụp still. Không lấy screenshot preview làm ảnh final. Debug baseline có thể dùng native preview layer tạm; M2 thay surface path bằng Metal, không tạo thêm camera session.

## Ticket

| ID | Owner | Công việc | Output / tiêu chí |
|---|---|---|---|
| M01-T01 | iOS + FE | Camera permission states và request đúng lúc; Info.plist usage text | Denied/restricted có Open Settings, Lab/Films vẫn truy cập |
| M01-T02 | iOS | Session state machine, input/output configuration, start/stop, owner serialization | Không mutation topology từ RN callbacks; observer đăng ký/hủy đúng lifecycle |
| M01-T03 | iOS | Catalog physical lenses + supported factors/ranges/capabilities | Chỉ hiện lựa chọn có thật; phân biệt physical lens và digital crop |
| M01-T04 | FE + iOS | Lens switch command/ack, loading state, duplicate request handling | UI chỉ đổi lens active sau ack; switch thất bại giữ last-valid lens |
| M01-T05 | iOS + FE | Focus/exposure point, RN layout → aspect-fill → sensor coordinates | Indicator đúng vị trí ở portrait và hai landscape; unsupported focus bị disable |
| M01-T06 | iOS + FE | Capture EV mặc định -2…+2 giao với range thực tế; flash Off/Auto/On nếu hỗ trợ; AE/AF lock | Applied values được trả về UI; unlock khi tap/lens/session reset |
| M01-T07 | iOS | Processed still capture, delegate lifetime theo requestID, metadata/dimensions/orientation | Ảnh decode được; capture không chờ animation; descriptor stub có version |
| M01-T08 | iOS + FE | Interruption, media-services reset, background/foreground, device unavailable | Recover state rõ; settings hợp lệ được restore; không infinite retry |
| M01-T09 | FE | Shutter press/haptic, current lens/EV, permission/recovery UI, grid Off/thirds | Nhãn và trạng thái disabled đúng; không toast “saved” trước durable source |

## State và capture baseline

```text
idle → requestingPermission → configuring → running
running → interrupted → recovering → running
configuring/recovering → failed → explicit retry
```

Không gọi `startRunning` đồng thời với session configuration. Ghi requested và applied camera controls riêng. Ngắt render/preview khi inactive phù hợp nhưng giữ delegate của capture đang xử lý đến kết thúc hoặc lỗi có báo cáo.

M1 ghi processed outputs vào vùng durable test-owned bằng FileStore tối thiểu và kiểm tra decode/count. Transaction/recovery hoàn chỉnh, receipt `sourceSafe` production nằm ở M3. UI Internal phải phân biệt “capture nhận được” và “đã lưu an toàn”; kết quả loop M1 không thay thế kill/recovery gate M3.

## File dự kiến

- `ios/ChemNative/CameraCore/{CameraSessionController,CameraDeviceCatalog,PhotoCaptureDelegate,CameraGeometry,SessionRecoveryController}.swift`.
- `ios/ChemNative/Platform/CameraPermissionService.swift`, `Persistence/FrameFileStore.swift` bản tối thiểu.
- `specs/NativeChemCamera.ts`, `specs/NativeChemCapture.ts` và Swift/ObjC++ adapters.
- `src/features/camera/{CameraScreen,CameraController,FocusOverlay,LensSelector,ExposureControl}.tsx`.

## Kế hoạch nghiệm thu

| Case | Cách kiểm tra | Pass |
|---|---|---|
| Cold/warm open | Ghi timings theo app/surface/camera stages | Camera tự sẵn sàng, không refresh thủ công |
| Lifecycle | App switch, lock/unlock, interruptions hệ thống thực tế | Resume khi platform cho phép; lỗi có đường retry |
| Lens | Chuyển liên tiếp qua mọi lens, thiếu tele/UW | Không crash/session thứ hai; UI phản ánh lens thật |
| Geometry | Tap focus ở center/corners, đổi orientation | Điểm focus khớp aspect/crop transform |
| Still | 100 capture bình thường trên mỗi nhóm thiết bị mục tiêu | Mọi accepted request có output decode được hoặc lỗi rõ; zero silently lost capture |
| Permissions | Fresh allow/deny/revoke | Camera và gallery-only state đúng; không request microphone |
| JS lifecycle | Remount Camera/JS reload | Không double session, snapshot tái lập state |

## Exit và bàn giao

- [ ] Baseline camera đạt trên recent Pro, recent non-Pro, intended minimum device.
- [ ] Portrait/landscape ảnh đúng orientation, dimensions và metadata thật.
- [ ] Focus, EV, flash/lock khi hỗ trợ và capability gating hoạt động.
- [ ] Lifecycle, errors, accessibility labels có evidence.
- [ ] Camera sample buffers cấp được cho M2; still-source contract bàn giao M3.

Evidence: `docs/evidence/M01/REPORT.md`, capture ledger và device matrix. Simulator chỉ kiểm UI; không đóng gate camera. Không claim ProRAW/manual controls đã xong từ khả năng hiển thị badge.
