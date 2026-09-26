# M0 — Project foundation: React Native + native iOS

> Trạng thái: chưa triển khai · Phụ thuộc: không · Owner: FE + iOS.
> Nguồn: engineering plan §3–10, §49; PRD §11–15, §65–66, §120, §124–125.

## Mục tiêu và phạm vi

Tạo app RN có thể build Release trên iPhone, app shell bám thiết kế, và chứng minh đường giao tiếp TypeScript → native service → native view. Đây là gate cho stack mới; chưa cần camera/film hoàn chỉnh.

Đầu vào là [kiến trúc](ARCHITECTURE.md), [UI mapping](UI_SOURCE_MAPPING.md), mockup root. Chốt RN/React/Hermes/Node, package manager, Xcode/Swift/CocoaPods và iOS floor thành một compatibility matrix. SwiftData phải dùng được trên OS floor; không chọn deployment target thấp hơn khả năng API đã dùng. Chưa cố định version số trong tài liệu này vì chưa có build spike.

## Ticket theo thứ tự

| ID | Owner | Việc thực hiện | Output / điều kiện pass |
|---|---|---|---|
| M00-T01 | FE + iOS | Khởi tạo bare RN TypeScript tại `apps/mobile`; pin versions/lockfiles, Debug/Release/Internal schemes, bundle IDs, signing hướng dẫn | Clean checkout build tái lập; Release có JS bundle, không phụ thuộc Metro |
| M00-T02 | FE | Tokens từ DESIGN YAML, typography local assets, RN primitives, safe area, layout portrait/landscape | Camera/Lab/Films/Settings shell; accessible button/dial/film chip |
| M00-T03 | FE | Typed navigation, Camera root, last-frame route bằng frameID, film sheet/detail | Back từ Lab/Films về đúng Camera; không tạo session trong từng route |
| M00-T04 | iOS + FE | Codegen spike: TurboModule async query + typed event + snapshot; Swift qua adapter phù hợp | Native error và event tới JS; unsubscribe/remount không leak |
| M00-T05 | iOS + Imaging | Fabric surface host `MTKView` vẽ màu/gradient test; lifecycle attach/detach | RN overlay hiển thị đúng, resize/rotate/remount không crash |
| M00-T06 | iOS + FE | Freeze DTO schemas, error taxonomy, service ownership, contractVersion, string seed, revision/requestID | Contract fixtures serialize/deserialize cùng semantics |
| M00-T07 | FE + iOS | Dependency container, feature fakes, explicit state reducers, OSLog categories/correlation, internal flags | UI fixture không cần camera; production báo lỗi rõ nếu native module thiếu |
| M00-T08 | FE + iOS | CI cho JS typecheck/lint/test, macOS native Debug/Release + Codegen/test targets; resource validator skeleton | Ghi command thực tế trong README dự án khi tạo scripts; không ghi command chưa tồn tại là đã pass |
| M00-T09 | Product + QA | Chốt device matrix, free/pro đề xuất, import copy, Rolls, front-camera scope, minimum OS | Decision log có owner/date; danh sách thiết bị thật cần mượn/mua |

Chọn navigation/gesture/animation package sau khi kiểm tra hỗ trợ RN version đã pin. UI style dùng tokens/StyleSheet, không chuyển Tailwind CDN hoặc HTML vào WebView. Bổ sung license cho font/icon; fallback system font trước khi asset hợp lệ được đưa vào bundle.

## File dự kiến

- `apps/mobile/src/app/{App,AppEnvironment,AppNavigator}.tsx`.
- `src/design-system/{tokens,typography}/`, `src/features/*/`, `src/locales/{en,vi}/`.
- `specs/NativeChemDiagnostics.ts`, `specs/ChemCameraNativeComponent.ts` và Codegen config.
- `ios/ChemNative/Adapters/`, `ios/ChemNative/Domain/` và test targets.
- `docs/decisions/ADR-001-react-native-ui.md`, `ADR-002-native-imaging.md`, `ADR-003-native-persistence.md`, `TOOLCHAIN.md`, `DEVICE_MATRIX.md`.

## Contract và lifecycle cần chứng minh

Một native application service tồn tại độc lập với React component. RN attach surface bằng token và gửi intent; unmount chỉ detach subscription/view. Service có explicit start/stop theo app foreground và route demand. Native diagnostics fake trả `contractVersion`, `sequence`, sample DTO và typed error, giúp xác nhận cả build lẫn runtime boundary.

Xác định ngay các màn cần fixture: camera denied/interrupted, source-saving, render-retry, Lab empty/loading/missing source, film locked, entitlement unknown. Prototype giữ label báo mock trong Internal build, tránh nhầm dữ liệu fake với sensor thật.

## Kế hoạch kiểm chứng khi triển khai

- Typecheck và unit test DTO/state; component tests navigation/labels, codegen schema compilation.
- Build Debug + Release trên macOS; launch Release trên iPhone với Metro tắt.
- Mount/unmount/rotate Fabric surface nhiều lần; reload JS rồi snapshot resync, không duplicate listener.
- Đo RN boot, native init và first surface; số liệu M0 là baseline, chưa claim startup camera đạt PRD.
- Kiểm tra main-thread instrumentation không có blocking service call.

## Exit checklist và bàn giao

- [ ] Toolchain/OS/device scope có decision log và clean build evidence.
- [ ] React Native là FE thực tế, Camera là default route.
- [ ] TurboModule + Swift service + Fabric Metal surface chạy thật.
- [ ] DTOs/event ordering/error/lifetime conventions đã được hai phía thống nhất.
- [ ] Design tokens và fixture states có thể review.
- [ ] CI/scripts có tên thật và hướng dẫn macOS; evidence tại `docs/evidence/M00/REPORT.md`.

Rủi ro chính: tương thích RN Codegen/Swift/Metal. Nếu spike thất bại, sửa adapter/build configuration tại M0 và ghi ADR trước khi mở M1; không thay frontend về SwiftUI để vượt gate. Bàn giao session/surface contracts và app shell cho M1.
