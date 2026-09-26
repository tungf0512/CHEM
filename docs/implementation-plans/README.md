# CHEM — Implementation roadmap với React Native

> Ngày lập: 2026-09-26 · Trạng thái: kế hoạch, chưa triển khai app.
> Frontend: React Native + TypeScript. Phạm vi phát hành: iPhone/iOS theo PRD.

## 1. Cách đọc và nguồn yêu cầu

Bộ tài liệu này chia công việc thành **14 milestone M0–M13**, giữ ID trong [engineering plan gốc](../../CHEM_iOS_Core_Features_Implementation_Plan_v1.0%20%281%29.md), §9–26 và §88–113. [PRD](../../chem_prd_v1.0.md) là nguồn yêu cầu sản phẩm. Yêu cầu mới của chủ repo về **React Native frontend** thay thế lựa chọn SwiftUI trong hai tài liệu gốc.

Thứ tự ưu tiên khi có mâu thuẫn: yêu cầu hiện tại của chủ repo → yêu cầu sản phẩm trong PRD → engineering plan về cách thực hiện → DESIGN.md/HTML/ảnh về giao diện. Những lựa chọn chưa được tài liệu chốt được ghi là **đề xuất**, có milestone và người phụ trách xác nhận; không coi đó là yêu cầu đã duyệt.

Đọc tiếp:

1. [Kiến trúc React Native và native contracts](ARCHITECTURE.md).
2. [Đối chiếu mockup, thiết kế và hành vi thật](UI_SOURCE_MAPPING.md).
3. [Ma trận yêu cầu → milestone](REQUIREMENTS_MATRIX.md).
4. File milestone tương ứng; thực hiện ticket theo thứ tự phụ thuộc, lưu bằng chứng nghiệm thu trước khi đánh dấu hoàn thành.

## 2. Hiện trạng repo đã kiểm tra

| Thành phần | Hiện có | Ý nghĩa với implementation |
|---|---|---|
| Hai Markdown ở root | PRD 4.363 dòng; engineering plan 3.932 dòng | Đặc tả và định hướng kỹ thuật, không phải code đã chạy |
| `chem_optical_emulsion_system/DESIGN.md` | Tokens, typography, component direction | Nguồn dựng design system RN |
| Camera, Darkroom Lab, Film Shelf, Pro Mode | Mỗi màn có `code.html` và `screen.png` | Mockup HTML với tương tác mô phỏng bằng DOM/CSS |
| `chem_optical_mark/` | SVG nằm trong `code.html`, ảnh icon | Asset tham chiếu thương hiệu |
| Bốn thư mục ảnh theo mô tả scene | PNG portrait/cafe/night/architecture | Ảnh minh họa; không đủ làm bộ đo màu hoặc ground truth |
| App/toolchain | Chưa có `package.json`, project Xcode, Swift/Metal source, test suite | Bắt đầu từ M0; không có app hiện hữu để migrate |

HTML có ảnh/font từ mạng, thông số hardcode và nút Save/Export chỉ đổi nhãn bằng timer. Không coi những hành vi đó là feature đã hoàn thành. Thư mục `.git` hiện không hoạt động như một Git repository; kế hoạch không dựa vào lịch sử commit.

## 3. Stack và phạm vi

| Lớp | Lựa chọn trong kế hoạch |
|---|---|
| FE | React Native, TypeScript strict, New Architecture, Hermes; bare RN có project `ios/` được quản lý trực tiếp |
| UI | RN components + StyleSheet/tokens; typed navigation; gesture/animation chạy phù hợp với UI thread, chốt package tương thích ở M0 |
| Native boundary | Turbo Native Modules cho commands/query/events; Fabric components cho camera/Lab Metal surface |
| Camera | Swift + AVFoundation, một session owner |
| Imaging | Metal + Core Image/ImageIO, chung graph cho preview/final/import |
| Dữ liệu | SwiftData metadata + filesystem cho pixels, native repository là nguồn dữ liệu bền vững |
| Platform | System photo picker/PhotoKit, StoreKit 2, OSLog, native haptics |
| Backend | Không cần cho luồng V1; không account, không upload ảnh |
| Validation khi triển khai | Typecheck/lint, JS component tests, native unit/integration/migration tests, regression ảnh, thiết bị iPhone thật |

React Native cung cấp typed native modules và native view integration; cách dùng chúng cho CHEM là quyết định kiến trúc của bộ plan. Tham khảo [Turbo Native Modules](https://reactnative.dev/docs/turbo-native-modules-introduction), [Fabric components](https://reactnative.dev/docs/fabric-native-components-introduction) và [Swift adapter](https://reactnative.dev/docs/the-new-architecture/turbo-modules-with-swift).

**React Native không tự mở rộng scope sang Android.** Android cần một camera/render/storage platform khác và roadmap riêng. Native build, Metal và camera QA yêu cầu macOS/Xcode cùng iPhone thật; môi trường Linux hiện tại chỉ đủ cho tài liệu và một phần công việc TypeScript.

## 4. Milestone và kết quả bàn giao

| ID | Plan | Phụ thuộc | Bằng chứng chính |
|---|---|---|---|
| M0 | [Project foundation](M00_PROJECT_FOUNDATION.md) | Không | RN app build được, native module/view spike, contracts và UI shell |
| M1 | [Reliable camera](M01_RELIABLE_CAMERA.md) | M0 | Camera thật, still capture, lifecycle, focus/EV/lens |
| M2 | [Metal live preview](M02_METAL_LIVE_PREVIEW.md) | M1 | GPU preview 30 fps baseline, mục tiêu 60 fps |
| M3 | [Transactional capture](M03_TRANSACTIONAL_CAPTURE.md) | M1; tích hợp M2 | Source an toàn trước render, recovery sau kill |
| M4 | [Shared renderer](M04_SHARED_RENDERER.md) | M2, M3 | Chung descriptor/graph cho preview và final |
| M5 | [Film engine](M05_FILM_ENGINE.md) | M4 | DAY 200, SKIN 400, NIGHT 800T đạt quality gate |
| M6 | [Frame persistence](M06_FRAME_PERSISTENCE.md) | M3, M4; tích hợp M5 | Frame/recipe/version lifecycle và migration |
| M7 | [Lab / re-development](M07_LAB_REDEVELOPMENT.md) | M5, M6 | Đổi film, exposure/process/grain, reset, không sửa source |
| M8 | [Photos import / export](M08_PHOTOS_WORKFLOW.md) | M7 | Import → Lab → Save Copy/Share |
| M9 | [RAW / ProRAW](M09_RAW_PRORAW.md) | M8 | Paired source, capability gating, decode/recovery |
| M10 | [Device normalization](M10_DEVICE_NORMALIZATION.md) | M4, M5, M8; M9 cho RAW | Profile thực nghiệm, generic fallback, regression |
| M11 | [Pro controls](M11_PRO_CONTROLS.md) | M1, M8, M10; M9 cho Negative | ISO/shutter/WB/focus và lens reconciliation |
| M12 | [Productization](M12_PRODUCTIZATION.md) | M5–M11 theo feature | 8 films, Rolls, Settings, onboarding, purchase, A11y |
| M13 | [Beta / release hardening](M13_BETA_RELEASE_HARDENING.md) | M12 | Device matrix, beta, migration/purchase/color gates |

Chuỗi bàn giao mặc định: **M0 → M1 → M2 → M3 → M4 → M5 → M6 → M7 → M8 → M9 → M10 → M11 → M12 → M13**. Có thể viết schema M6 tối thiểu ngay M3; M6 hoàn thiện repository thay vì tạo database thứ hai. Calibration processed-input có thể bắt đầu trước khi RAW hoàn thiện. Không chờ cuối dự án mới kiểm tra reliability/performance.

## 5. Đối chiếu với milestone trong PRD §107

| Milestone của PRD | Milestone ở bộ plan này |
|---|---|
| 0 — Spike | M0–M4: RN/native, camera, preview, source safety, final render |
| 1 — Renderer foundation | M4–M5 |
| 2 — Camera MVP | M1–M3; last-frame từ M3/M6, film selector từ M5 |
| 3 — Persistence | M3 + M6 |
| 4 — Lab | M7; save/share hoàn tất M8 |
| 5 — Gallery | M8 |
| 6 — RAW | M9 |
| 7 — Calibration | M10 |
| 8 — Productization | M11–M12 |
| 9 — Beta hardening | M13 |

## 6. Release gates

| Mốc sản phẩm | Khi nào có thể công bố hoàn thành |
|---|---|
| Technical prototype | M0–M5: live + final + 3 film, đã có source safety |
| Internal MVP / vertical slice | M0–M8: Camera → DAY → source safe → Lab → SKIN → export |
| Advanced technical alpha | M9–M11 đạt trên thiết bị hỗ trợ |
| External TestFlight | Gate đầu M13: camera/Lab/import/export ổn định, dữ liệu an toàn; feature chưa đạt có thể tắt với scope beta rõ ràng |
| Public V1 | M0–M13 đạt; 8 film, Free/Pro, capability-gated RAW/Pro, Rolls cơ bản và release checklist |

Không tự đổi định nghĩa V1 thành MVP khi thiếu thời gian. Nếu bỏ Rolls/RAW/Pro khỏi V1, Product cần ghi quyết định đổi scope; beta có thể hẹp hơn V1. V1.5 mới dự kiến batch, saved/import/export recipes, contact sheets, widgets/quick launch. V2/V3 trong PRD là candidate roadmap, chưa đủ đặc tả để cam kết implementation chi tiết ở đây.

## 7. Quyết định, giả định và điểm lệch đã xử lý

| Vấn đề | Cách lập kế hoạch | Chủ trì / hạn chốt |
|---|---|---|
| SwiftUI vs RN | RN sở hữu màn hình, Swift chỉ sở hữu native services/surfaces | Đã chốt theo yêu cầu người dùng |
| Minimum iOS / RN / Xcode | Pin bộ version tương thích, ghi OS floor thực tế; SwiftData phải tương thích deployment target | FE + iOS, M0 trước baseline build |
| Thiết bị hỗ trợ | Ít nhất recent Pro, recent base, intended baseline; ghi model/OS thật | Product + iOS + QA, M0 |
| Ba film prototype vs ba film free | Engine: DAY/SKIN/NIGHT ở M5. Free V1: DAY/SKIN/MONO theo PRD §54 | M5 và M12 |
| Imported source | Đề xuất managed copy mặc định cho frame đã nhập; chỉ copy ảnh được chọn. Reference-only là tùy chọn sau nếu recovery đủ | Product, M0 contract; M8 thực hiện |
| Rolls | V1 cơ bản ở M12 vì PRD §10.3 liệt kê; contact sheet ở V1.5 | Product xác nhận M0 |
| Push/pull trong Free/Pro | Đề xuất cho mọi người trong V1; PRD gọi đây là Pro candidate, cần chốt feature matrix | Product, trước M12 purchase integration |
| Favorite vs last film | Mặc định last valid film; setting cho favorite-at-launch, fallback DAY khi không còn quyền dùng | M5/M12 |
| Front camera / Live Photos | Đề xuất defer V1; rear + portrait/landscape ưu tiên | Product, M0 |
| Format / HDR | HEIF P3 và JPEG sRGB; output SDR có tone mapping HDR input được đặc tả; TIFF/film-baked DNG không thuộc V1 | Imaging, M4/M8 |
| RAW / Pro controls | Pro unlock kết hợp runtime support; môi trường internal có debug override | Product, M9–M12 |
| Giá / product ID / future packs | Giá hiển thị từ StoreKit; không hardcode giá minh họa PRD hay hứa mọi pack tương lai | Product, M12 |
| UI lệch PRD | Theo [UI mapping](UI_SOURCE_MAPPING.md): bỏ telemetry giả, giữ Camera đơn giản, format/process đúng V1 | Design + FE, từ M0 |

## 8. Quy tắc giao việc và Definition of Done

Mỗi ticket có ID `Mxx-Tnn`, owner theo vai trò, output và tiêu chí pass. Vai trò: **FE** (RN), **iOS** (camera/persistence/platform/adapter), **Imaging** (Metal/color), **QA**, **Product/Design**. Một người có thể giữ nhiều vai trò; đây không phải giả định về số nhân sự.

Các path trong phần “File dự kiến” của từng milestone là **file cần tạo khi implementation bắt đầu**, không phải file đang tồn tại. API mẫu là contract thiết kế; phải chuyển thành Codegen-compatible specs và build thật ở M0.

Milestone đạt khi có UI + domain behavior + native integration + lưu trữ/recovery + error states + accessibility liên quan + evidence thiết bị/performance. Mock hoặc screenshot chỉ chứng minh UI; không chứng minh camera, màu, RAW hay StoreKit. Tất cả checkbox trong bộ plan đang để trống có chủ đích.

Khi triển khai, lưu `docs/evidence/Mxx/REPORT.md` gồm build/toolchain, device/OS, test cases, kết quả, số liệu, artifact paths và vấn đề còn mở. Các threshold số liệu do team thêm ngoài PRD phải ghi “đề xuất” và freeze trước khi đo. Chưa có nhân lực/device matrix nên chưa ấn định ngày hay ước lượng tuần giả chính xác; chốt lịch sau spike M0–M2.
