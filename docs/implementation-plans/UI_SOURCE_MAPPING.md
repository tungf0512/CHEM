# CHEM — Mapping thiết kế hiện có sang React Native

> Mục đích: giữ visual direction và sửa những điểm mockup không phản ánh hành vi sản phẩm.
> Nguồn: [DESIGN.md](../../chem_optical_emulsion_system/DESIGN.md), bốn mockup màn hình, icon và PRD.

## 1. Inventory và milestone sở hữu

| Source hiện có | RN screen/components dự kiến | Milestone | Thiếu trạng thái cần thiết kế thêm |
|---|---|---|---|
| [Camera HTML](../../chem_camera_viewfinder/code.html) · [ảnh](../../chem_camera_viewfinder/screen.png) | CameraScreen, FocusOverlay, LensSelector, ShutterButton, FilmChip, LastFrameThumbnail | M0 shell; M1–M3 behavior; M5 film | Permission denied/restricted, interrupted/recovering, source-save failure, queue pressure, low storage |
| [Lab HTML](../../chem_darkroom_lab/code.html) · [ảnh](../../chem_darkroom_lab/screen.png) | LabScreen, ChemLabView, FilmCarousel, ProcessControl, GrainControl, ExposureDial, ExportSheet | M7–M8 | Library empty, loading, source unavailable, old-version unavailable, render failed, recipe-save failed, export pending/failed/unknown |
| [Film Shelf HTML](../../chem_film_shelf/code.html) · [ảnh](../../chem_film_shelf/screen.png) | FilmShelfScreen, FilmCard, FilmDetailScreen, favorite/locked state | M5/M12 | Three-film stage, premium locked, unavailable profile, denied live-preview permission |
| [Pro HTML](../../chem_pro_mode_viewfinder/code.html) · [ảnh](../../chem_pro_mode_viewfinder/screen.png) | ProControlStrip, SteppedDial, WB/Focus controls | M9/M11/M12 | Unsupported lens/manual/RAW, applying controls, stale ranges, auto reset, entitlement unknown |
| [Optical mark SVG](../../chem_optical_mark/code.html) · [ảnh](../../chem_optical_mark/screen.png) | Bundled icon/brand asset | M0/M12/M13 | App icon export sizes/build asset catalog và license/source tracking |
| Bốn thư mục ảnh cafe/portrait/neon/architecture | Bundled sample candidates | M5/M12 | Quyền sử dụng, full-res reference data, color profile/provenance |

Chưa có mockup riêng cho Onboarding, Settings, Paywall/Restore, Lab library, Film Detail đầy đủ, Rolls, Storage và permission/error sheets. Đây là deliverables M0/M6/M12, không phải màn đã tồn tại trong code.

## 2. Tokens React Native

`DESIGN.md` có hai palette: YAML tokens ở đầu và narrative values ở dưới. HTML chủ yếu dùng palette YAML nhưng có override spacing/radius. **Đề xuất dùng YAML làm source của token v1**, dùng narrative cho component intent; Design review screenshot ở M0 trước freeze. Không trộn giá trị tùy màn.

| Nhóm | Baseline từ YAML / cách chuyển |
|---|---|
| Surface | `#111316`; lowest `#0c0e11`; low `#1a1c1f`; high `#282a2d` |
| Text | on-surface `#e2e2e6`, secondary `#d9c2b2`; verify contrast ở size thực |
| Accents | primary `#ffb77b`, primary-container `#e58e3c`, tertiary `#69d9c5`, error `#ffb4ab` |
| Font | Inter cho body/headings; JetBrains Mono cho numeric/labels; local files + license/fallback |
| Type | Heading 32/38, 24/30, 20/26; body 16/24, 14/20, 12/16; telemetry 18/22 |
| Spacing | 4, 8, 12, 16, 20, 32 logical points là baseline tương ứng rem theo 16 px của mockup |
| Radius | 2/4/6/8/12, circle dùng radius theo measured size; không copy `rounded-full=0.75rem` HTML thành shutter vuông |
| Layout | Safe area thực, đo viewport, không giữ fixed 884px height / screenshot pixel width |

Label 10px trong mockup là tham chiếu mật độ; không ép chữ sản phẩm khó đọc để pixel-match. Numeric tabular figures/font features phải kiểm trên font thực, đơn vị và screen reader đọc đúng. Shutter theo DESIGN là hình tròn; screenshot/render HTML có cạnh vuông là điểm cần sửa trong component v1.

RN primitives đề xuất: `View/Text/Pressable`, virtualized list cho Shelf/library, native Metal surface cho image viewport, reusable sheet/segmented control/adjustable dial. Chốt library navigation/gestures/animation ở M0 sau compatibility test. Không dùng DOM handlers, CSS filter, Tailwind CDN hay `navigator.vibrate` trong app.

## 3. Quyết định xử lý mockup lệch PRD

| Chi tiết trong mockup | Xung đột / lý do | Hành vi production trong plan |
|---|---|---|
| Save Copy “DNG+TIFF”, export button giả bằng timer | PRD EXP-003: HEIF/JPEG; RAW source khác rendered output | M8 export thật HEIF P3/JPEG sRGB; không timer báo success |
| “RAW LINEAR SENSOR BUFFER” overlay khi hold | HTML chỉ layer mô phỏng, không raw decode | M7 normalized original cùng geometry/color; M9 RAW decode thật |
| “20.4°C BATH”, “36 EXP LOADED”, “12/36” | Không có nguồn telemetry và PRD không giới hạn lượt chụp kiểu cuộn 36 | Bỏ khỏi default Camera; nếu Roll counter thì đếm frames thật, không quota giả |
| Sony IMX903, 48MP, 24mm, ISO/WB/ProRAW hardcode | Không chứng minh được trên mọi thiết bị/ảnh | M1/M9/M11 dùng metadata có thật, missing thì ẩn/unknown |
| “1.8 m” manual focus | Normalized lens position không tự là khoảng cách đo theo mét | M11 normalized focus/Near–Far; chỉ mét nếu có calibration đáng tin |
| `.5×/1×/2×/5×` | Không phải mọi model có đủ physical lenses; 2× có thể là crop | M1 dynamic catalog; zoom/crop không giả physical camera |
| “8 Calibrated Profiles • Metal Pipeline” | Shelf là UI, chưa có calibration evidence; PRD muốn user language đơn giản | Số film theo manifest; diagnostics ở Internal/About, không claim calibration thiếu bằng chứng |
| Push/Pull sheet -2…+3 bước 0.5 | PRD V1 chỉ Pull -1/Normal/Push +1 | M5/M7 ba giá trị; không triển khai advanced authoring sheet cho user |
| Spectral warmth “-4 K” | HTML là số tùy ý, không absolute Kelvin camera WB | M7 warmth optional, ghi Warmth với scale có định nghĩa; M11 WB Kelvin riêng |
| Account avatar / CHEM//OS nhiều telemetry | PRD no mandatory account, default Camera ít controls | Avatar thay brand/settings nếu cần; không tạo login/profile feature |
| Four-tab nav luôn chiếm nhiều chỗ | PRD Camera-root, Lab/Films nhẹ, Settings từ top | M0 typed camera-root navigation, compact actions/sheets; Design review layout mới |
| 3:2/4:5 trong DESIGN narrative | PRD 4:3 default, 3:2/1:1 | M4 crop semantics + M7/M12 controls theo PRD |
| Brand names PORTRA/TRI-X trong DESIGN | PRD dùng CHEM own film identities | Film manifest tám tên CHEM; không tự đưa branded film stock vào catalog |
| Baked vignette/gradient trên ảnh trong mockup | Decorative overlay có thể làm viewfinder khác output | Overlays chỉ chrome/legibility; không thêm artistic transform ngoài shared renderer |
| Grain/film change chỉ CSS/class updates | Không thực hiện color pipeline | M5/M7 native render, acknowledged state và processing errors |

## 4. Interaction mapping

- **Shutter:** press visual/haptic ngay, gửi intent không chờ animation; success sau sourceSafe M3.
- **Film selection:** RN selection intent → native validate/load → descriptor ack → label active. Film detail preview không tạo session mới.
- **EV/focus:** gesture coordinates theo actual surface geometry; conflict horizontal film swipe/vertical EV/tap focus được thiết kế và test.
- **Lab controls:** draft update → coalesced interactive render → revision guard → durable recipe ack. Hold-to-original có toggle accessible thay thế.
- **Load stock/Simulate:** Load stock áp film hợp lệ; Simulate trở thành preview/detail bằng shared engine, không “Apply Calibration” chỉnh device profile từ user UI.
- **Pro dials:** commanded vs applied values riêng; numeric ranges runtime, accessibility Increase/Decrease.
- **Export:** frozen recipe revision và output options → real job; user có retry hoặc source-safe message nếu lỗi.

## 5. Visual review gates

M0 kiểm hierarchy/tokens/navigation/state fixtures. M7 kiểm Lab/interactive states. M12 kiểm fonts/local assets, color contrast, English/Vietnamese, safe area, small/large display và landscape. M13 dùng Release build/device screenshots của app thật để làm App Store assets.

Mockup screenshot là visual reference, không chứng minh effect accuracy. Các PNG minh họa không dùng làm golden baseline film engine nếu không có source/recipe/color metadata để tái lập. Không tải lại ảnh từ Google URLs mỗi lần mở app; chỉ bundle asset có quyền sử dụng và provenance rõ.
