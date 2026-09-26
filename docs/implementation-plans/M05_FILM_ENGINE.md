# M5 — Film engine V1 và ba film đầu tiên

> Trạng thái: chưa triển khai · Phụ thuộc: M4 · Owner: Imaging; Product/photographer duyệt look.
> Nguồn: engineering plan §15–19, §55, §74–75; PRD FILM-001…004, §18–19, ENG-004…007, §61–63, §110–121.

## Mục tiêu

DAY 200, SKIN 400 và NIGHT 800T có identity khác nhau, dùng một graph parametric và chạy từ live đến full-res. Đây là **ba film để kiểm chứng engine**. Free tier Public V1 là DAY/SKIN/MONO, hoàn thiện ở M12; NIGHT không mặc nhiên thành film miễn phí.

## Ticket

| ID | Owner | Công việc | Output / tiêu chí |
|---|---|---|---|
| M05-T01 | Imaging | FilmProfile manifest/schema, semantic validator và resource loader | ID/version duy nhất, tài nguyên tồn tại, range/decode hợp lệ; invalid resource fail build |
| M05-T02 | Imaging | Tone toe/midtone/shoulder, nonlinear color/highlight/shadow response | LUT là một component, không toàn bộ engine |
| M05-T03 | Imaging | Bloom/halation phụ thuộc highlights, grain theo seed/luminance/scale | Không static PNG tiling, global red overlay hay haze phủ vùng tối |
| M05-T04 | Imaging | Process Pull -1/Normal/Push +1 và grain Fine/Normal/Rough | Parameter mappings riêng từng film; development EV tách process |
| M05-T05 | Imaging + Product | Author/tune ba film theo bảng character dưới | Approved profile version + description + reference outputs |
| M05-T06 | FE + iOS | Film Shelf ba film, detail, favorite, camera swipe/selection ack | Curated order; current film visible; đổi film không reconfigure camera |
| M05-T07 | Imaging | Internal Film Playground và regression renderer | Load same source, tune, A/B, export validated profile; debug stage exports |
| M05-T08 | QA + photographer | Regression scenes, human review, cross-quality/performance | Evidence theo film/device/version; approval không chỉ screenshot đẹp |

## Character cần đạt

| Film | Định hướng từ PRD | Rủi ro cần review |
|---|---|---|
| DAY 200 | Warm-neutral, saturation vừa, fine grain, highlights nhẹ | Da cam quá mức, xanh lá giả, highlight clipping |
| SKIN 400 | Da tự nhiên, warmth tiết chế, contrast mềm, bảo vệ đỏ/cam | Chỉ tối ưu một màu da/ánh sáng; làm phẳng da |
| NIGHT 800T | Tungsten bias, cyan/blue shadows, grain rõ, neon/halation | Bệt biển neon, red glow toàn ảnh, grain chồng noise sensor |

Film ISO character chỉ là mô tả chất ảnh. Chọn SKIN 400 không tự buộc sensor ISO 400. Artist parameters nằm resource, shader là stage tái sử dụng; thêm film không sửa CameraCore/PhotoKit/frame schema.

## FE và tài nguyên

Shelf dùng RN virtualized list/card, sample được bundle hợp lệ và lazy-load thumbnails. Detail xem live scene nếu Camera được phép, dùng session chung từ M1; denied thì sample tĩnh và giải thích rõ. Favorite một film; last-used/favorite launch policy dùng settings, không hardcode.

Profile resources gồm schema, ID/version, name/category, tone/color/grain/bloom/halation/process/defaults, supported input ranges, checksums. Quản lý LUT/GPU textures theo bounded cache; preload active/adjacent film, không upload mọi resource lúc launch.

## File dự kiến

- `Resources/Films/{day200,skin400,night800t}/v1/` gồm manifest và tài nguyên.
- `Imaging/Film/{FilmProfile,FilmLibrary,FilmParameterResolver}.swift`.
- `Imaging/Metal/Shaders/{Bloom,Halation,Grain}.metal`.
- `src/features/films/{FilmShelfScreen,FilmDetailScreen,FilmCard,FilmSelector}.tsx`.
- `InternalTools/FilmPlayground/`, `tools/validate-film-resources.*`, regression fixtures/manifest có quyền sử dụng.

## Kế hoạch nghiệm thu

- Dataset có nhiều màu da, daylight/tungsten/LED/mixed, foliage/sky/red/neutral, bright/dark, neon, over/underexposure. Bốn PNG trong repo chỉ tham chiếu art direction, không thay dataset kiểm màu.
- Mỗi film × process × grain chạy parameter sanity, fixed-seed regression và cross-quality checks. Review chính các case stress, không phải duyệt mù hàng nghìn outputs.
- Kiểm blur/grain ở nhiều output size, crop, source noise và lens. Khi tile final, không seams và không đổi noise phase do tile origin.
- Human photographic review đi cùng histogram/patch/highlight metrics; threshold freeze qua M4.
- Chạy lại M2 FPS/memory với cả ba look; NIGHT có halation là stress case.

## Exit và bàn giao

- [ ] Ba film đạt review riêng với use case khác nhau và version frozen.
- [ ] Profile validation + regression tool hoạt động, resources offline.
- [ ] Camera selection/shelf/detail/favorite tích hợp native thật.
- [ ] Grain deterministic, process/grain mappings dùng được cho Lab.
- [ ] Evidence `docs/evidence/M05/REPORT.md`; M12 thêm năm film bằng cùng quy trình, không fork engine.
