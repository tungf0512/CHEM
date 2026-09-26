# M12 — Productization: 8 films, Rolls, Pro unlock và UX hoàn chỉnh

> Trạng thái: chưa triển khai · Phụ thuộc: M5–M11 theo feature · Owner: FE + iOS + Imaging + Product/Design.
> Nguồn: engineering plan §26, §55, §63–64, §68–71; PRD §10.3, §13, §17–19, ROLL-001…003, PRIV/A11Y/PAY requirements, §51–59, §73.

## Mục tiêu

Đưa core workflow thành sản phẩm V1 có tám film, Rolls cơ bản, onboarding/Settings/storage, verified one-time Pro unlock, accessibility/localization/privacy. Các nhánh dưới có thể thực hiện khi dependency tương ứng sẵn sàng; không mở purchase trước khi vertical slice M8 được chứng minh.

## Ticket và thứ tự tích hợp

| ID | Owner | Công việc | Output / điều kiện |
|---|---|---|---|
| M12-T01 | Product + FE + iOS | Freeze Free/Pro matrix, product ID, copy, entitlement/capability policy | Một shared policy, không hardcode product IDs trong views |
| M12-T02 | Imaging + photographer | Thêm STREET 400, SOFT 160, CINE 250D, SLIDE 50, MONO 400 qua M5 authoring/review | Tổng 8 approved/versioned profiles, no remote dependency |
| M12-T03 | FE | Complete Shelf/detail/favorite/locked state, preview availability | Curated PRD order; free/pro states đúng, support live scene nếu camera được phép |
| M12-T04 | iOS + FE | StoreKit products/current entitlements/transaction updates, purchase/restore | Verified entitlement, pending/cancel/error/revoked/unknown đầy đủ |
| M12-T05 | iOS + FE | Enforce feature availability cả native và UI | Không bypass premium capture bằng gọi module; core camera không bị StoreKit chặn |
| M12-T06 | FE + iOS | Onboarding bốn bước, context permissions, Gallery-only fallback | Không account, target <30 giây theo PRD, skip repeat sau completed |
| M12-T07 | FE + iOS | Settings camera/capture/export/privacy/storage/about và persistence | Defaults/restore/validation, meaningful settings có behavior thật |
| M12-T08 | FE + iOS | Rolls list/create/detail/active roll/default film/rename/delete | ROLL-001…003; membership snapshot tại shutter, delete roll không delete frames |
| M12-T09 | FE + QA | VoiceOver, Dynamic Type, target sizes, Reduce Motion, contrast, haptics | Mỗi flow chính usable, selected/error state không chỉ dựa màu |
| M12-T10 | FE + Product | English/Vietnamese strings, plural/date/number, tone/copy | Film brand names giữ nguyên; không chuỗi hardcode còn sót trong flow chính |
| M12-T11 | iOS + Product | Privacy-safe diagnostics/optional telemetry + settings, privacy policy inventory | Không pixels/GPS/full EXIF; off switch đúng behavior |
| M12-T12 | FE + Design | Visual fidelity pass, local licensed assets/font/icons/app icon, missing screens | Empty/error/settings/paywall/roll screens đủ, không dùng remote mockup URLs lúc launch |
| M12-T13 | QA + iOS | Product integration matrix, offline launch/known entitlement, capture regression | Store unavailable không ảnh hưởng Camera/Lab/export free |

## 1. Film library và monetization policy

| Feature | Free V1 | Pro V1 | Trạng thái quyết định |
|---|---|---|---|
| Camera, gallery, Lab cơ bản, full-res/no watermark | Có | Có | PRD bắt buộc |
| DAY 200, SKIN 400, MONO 400 | Có | Có | PRD §54.1 |
| STREET, SOFT, CINE, NIGHT, SLIDE | Không chọn để chụp/develop mới | Có | Theo all-8 Pro boundary |
| RAW/ProRAW, manual controls | Không | Có khi hardware hỗ trợ | Default đề xuất từ engineering plan |
| Exposure/grain Lab | Có | Có | Đề xuất giữ core Lab hữu dụng |
| Push/pull | Đề xuất có | Có | Product chốt, vì PRD chỉ liệt kê Pro candidate |
| Rolls cơ bản | Đề xuất có | Có | Product chốt pricing; giữ V1 scope |
| Batch/saved recipes/contact sheets | Chưa thuộc V1 | Chưa thuộc V1 | V1.5, không quảng cáo là feature đang có |

Technical prototype NIGHT ở M5 không thay free-film list. Tất cả tám film phải dùng đúng PRD character, có regression theo M5/M10. Film metadata có `isoCharacter`; UI không lẫn với sensor ISO.

Giá lấy localized StoreKit product display; USD 19.99/29.99 trong PRD chỉ là candidate, không hardcode và không đưa countdown giả. Product description chỉ hứa quyền của core library theo quyết định đã chốt, không tự hứa future packs vô thời hạn.

## 2. Purchase và offline state

Entitlement state `unknown/free/pro`; transaction operation state tách `loading/purchasing/pending/cancelled/failed/success`. Native listener sống theo app, khởi động async, đọc verified current entitlement và cập nhật khi purchase/revoke/restore. Không dùng local Boolean vĩnh viễn làm bằng chứng quyền mua.

Khi StoreKit chưa xác định hoặc offline, xử lý thông tin entitlement đã verify theo policy được test; không mở khóa chỉ vì JS flag. New install offline chưa có bằng chứng không hứa khôi phục Pro. Camera free vẫn sẵn sàng, không spinner chặn launch.

Nếu mất quyền premium hoặc transaction bị revoke: bảo toàn tất cả source/captured recipes/renders cũ; đề xuất vẫn cho xem/export rendered copy cũ, còn premium re-render mới theo policy Product chốt. Khi active film không còn dùng được cho capture mới, chuyển sang free film với thông báo rõ; không rewrite old-frame recipe. Internal override bị compile/config gate ra khỏi Release.

## 3. Rolls cơ bản

Roll: title, note optional, date range, default film, createdAt. UI vào Rolls từ Lab để Camera không nặng thêm destination. Chọn active roll áp default film như một acknowledged selection; user có thể override film cho từng frame. FrameDraft snapshot rollID/film tại shutter; đổi active roll trong lúc render không chuyển frame sang roll mới.

Delete Roll mặc định chỉ bỏ container/membership, giữ frames; hành động xóa frames nếu có phải là flow khác được xác nhận. Roll không giới hạn 36 ảnh, không fake film expiration. Contact sheet giữ ở V1.5. Tên/ghi chú do user nhập chỉ lưu local, không telemetry.

## 4. Settings và onboarding

- Camera: preserve last film/favorite-at-launch, default lens hợp lệ, grid Off/thirds, haptics, Pro toggle.
- Capture: Standard/Negative có runtime support/entitlement, HEIF/JPEG, crop ratio 4:3/3:2/1:1.
- Lab/export: default format, managed import-source policy hiển thị rõ; không thêm reference-only switch nếu M8 chưa triển khai recovery tương ứng.
- Storage: source/RAW/render/cache usage, Clear Cache, manage/delete frames/negatives với hậu quả rõ.
- Privacy: telemetry choice, location metadata export policy; About: app/renderer version, licenses/privacy/support/Restore Purchases.

Onboarding giải thích Choose film → Shoot what you see → Negative preserved → contextual Camera permission. Không xin Photos/location/microphone ngay onboarding. Camera denied đưa vào Gallery-only; Photos save permission xin lúc save.

## 5. Accessibility / localization / privacy

Design đề xuất minimum touch area 44×44 pt kể cả icon nhỏ; Dynamic Type không để controls che shutter, layout landscape reflow. Dials có adjustable actions, before/after có toggle cho người không giữ nút được. Selected state có text/icon/accessibility state ngoài accent màu. Haptics có visual alternative và setting tắt.

Chuẩn bị en/vi localization và review bản dịch; typography monospace chỉ dùng telemetry phù hợp, có font fallback/license. Loại copy “Sony IMX903”, “20.4°C BATH”, “DNG+TIFF”, “8 calibrated” khi dữ liệu không chứng minh. Không đưa renderer/debug metrics vào flow người dùng trừ About hoặc detail hữu ích.

Telemetry đề xuất opt-in, schema events: camera_ready/capture_requested/capture_source_safe/capture_complete/capture_failed/film_selected/lab_opened/film_redeveloped/import_completed/export_completed/raw_enabled/pro_purchase_completed. Có thể chỉ ghi aggregate local V1; nếu chọn crash/analytics SDK cần owner/config/privacy disclosure cụ thể trước tích hợp. Telemetry failure không được ảnh hưởng correctness.

## File dự kiến

- `src/features/{onboarding,settings,rolls,paywall}/`, completion pass `features/films/`.
- `Platform/Store/{EntitlementStore,PurchaseService,FeatureAvailability}.swift` và NativeChemEntitlements.
- `Persistence/{SettingsRepository,RollRepository}.swift`, source/schema additions có migration.
- `Resources/Films/` đủ tám stock; `src/locales/en/`, `vi/`, local fonts/icons/assets.
- `docs/engineering/{FEATURE_MATRIX,PRIVACY_INVENTORY}.md`, StoreKit test configuration.

## Kế hoạch nghiệm thu và exit

- [ ] Tám film có M5 quality evidence; free chỉ DAY/SKIN/MONO, policy đã freeze.
- [ ] StoreKit test configuration + sandbox purchase/restore/pending/cancel/revoke/offline được kiểm; native/UI gating đồng nhất.
- [ ] Rolls create/activate/override/relaunch/delete-container giữ frame đúng.
- [ ] Settings effects thật; Clear Cache/Manage Negatives không lẫn nhau.
- [ ] Onboarding, Camera/Gallery-only, en/vi và accessibility review đạt.
- [ ] Không network dependency trong core, tài nguyên bundle đủ, no watermark.
- [ ] Evidence `docs/evidence/M12/REPORT.md`; giao beta candidate cho M13, chưa coi là App Store release.
