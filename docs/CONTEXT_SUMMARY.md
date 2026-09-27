# Tóm tắt dự án — sau Task 7 Ngày 3

> Bản tóm tắt này ghi trạng thái đến hết Ngày 3 Task 7. Hướng dẫn chuẩn tắc vẫn nằm trong `AGENTS.md`; roadmap đầy đủ nằm trong `docs/CHALLENGE_VI_ROADMAP.md`. Cập nhật khi quyết định hoặc trạng thái triển khai đổi.

## Cập nhật Task 6 (2026-09-27)

Task 6 đã chạy lại kiểm tra format ở chế độ read-only (11 file, 0 thay đổi), `flutter analyze` (No issues) và `flutter test` (45/45 đạt). Bằng chứng request Gemini thật đầu-cuối với App Check hợp lệ đã được ghi ở Task 5; chủ dự án xác nhận bộ kiểm thử thủ công Task 5 đã PASS. Không có kết quả theo từng TC trong bảng thủ công. Phiên này không gửi request Gemini mới vì app đang có ảnh được chọn không rõ nội dung; quota hiện tại cũng chưa được truy vấn từ Console. Chi tiết ở cuối `docs/AI_WORKLOG.md`.

Task 7 chỉ đồng bộ tài liệu và rà Git; không thay đổi mã/config, chạy build/test hoặc tạo request Gemini. Bước sản phẩm kế tiếp là Day 4: chỉnh sửa/xác nhận draft, lưu cục bộ và hiển thị lịch sử.

## Người dùng và vấn đề

AI Field Assistant trước hết dành cho **nhân viên bảo trì tòa nhà** ghi nhận sự cố điện, nước, điều hòa và thiết bị. Biểu mẫu dài làm gián đoạn công việc; báo cáo có thể thiếu ảnh/bối cảnh hoặc cách ghi không thống nhất. Ứng dụng hướng tới chuyển mô tả/ảnh thành bản nháp có cấu trúc để nhân viên kiểm tra, chỉnh sửa và xác nhận trước khi lưu.

## Luồng màn hình đã thống nhất

```text
Tạo báo cáo → Xem/chỉnh sửa bản nháp → Lịch sử → Chi tiết báo cáo
```

Đây là luồng sản phẩm đã thống nhất; chưa có nghĩa tất cả màn hình đã được triển khai. Hiện **Tạo báo cáo** có nhập mô tả, chụp/chọn một ảnh, xem lại đầu vào cục bộ và **CTA "Phân tích bằng AI" đã nối thật với Gemini**; bấm xong mở màn hình **"Bản nháp AI — cần kiểm tra, chưa lưu"** (`ReportDraftScreen`) hiển thị draft, `needs_confirmation` và đầu vào gốc; **Lịch sử** vẫn là empty state. Service tạo draft AI đã nối UI và đã chạy request Gemini thật trên thiết bị Android; màn hình chỉnh sửa/lưu và chi tiết chưa được dựng hay giả lập bằng dữ liệu mẫu.

## Schema báo cáo đã thống nhất

Các trường nội dung lõi: `category`, `location`, `priority`, `issue`, `suggested_action`, `summary`. `needs_confirmation` là danh sách tên trường cần người dùng xem lại/bổ sung/xác nhận.

| Trường | Bản nháp | Trước khi lưu |
|---|---|---|
| `category` | Chuỗi rỗng nếu thiếu căn cứ phân loại. | Có thể giữ trống sau khi người dùng xác nhận không xác định được. |
| `location` | Chuỗi rỗng nếu đầu vào không nêu địa điểm; không tự suy đoán. | Có thể giữ trống sau khi người dùng xác nhận không có thông tin. |
| `priority` | Chỉ `low`, `medium`, `high` hoặc `null` khi chưa đủ căn cứ; không tự mặc định `medium`. | Có thể giữ `null` sau khi người dùng xác nhận chưa xác định được. |
| `issue` | Có thể rỗng nếu chưa rõ và khi đó cần xác nhận. | Bắt buộc có nội dung trước khi lưu. |
| `suggested_action` | Chuỗi rỗng nếu không có đề xuất đủ an toàn; nếu có thì chỉ là đề xuất, không phải việc đã thực hiện. | Có thể giữ trống sau khi người dùng xem lại. |
| `summary` | Có thể rỗng nếu chưa đủ dữ kiện; nếu có thì chỉ tóm tắt dữ kiện đã xác nhận. | Có thể giữ trống sau khi người dùng xem lại. |
| `needs_confirmation` | Danh sách tên trường đang cần người dùng xem lại. | Người dùng phải xử lý từng mục bằng cách bổ sung dữ liệu hoặc xác nhận dữ liệu đó không có; sau xác nhận trường được phép tiếp tục trống. |

`created_at`, đường dẫn ảnh và trạng thái báo cáo là metadata, không thuộc các trường nội dung lõi. Schema hiện có `ReportDraft` model/parser trong Dart và được `GeminiReportService` dùng qua `responseSchema` + parse/validate phía app. Request Gemini thật đã được xác minh đầu-cuối trên Android (bằng chứng lịch sử Task 5); draft chưa được xác nhận hoặc lưu thành báo cáo.

## Công nghệ, hiện trạng và giới hạn

- **Flutter/Dart**, Android-first; Web bật để xem trước giao diện. UI dùng Material 3, `NavigationBar` và `IndexedStack`.
- Image picker: `image_picker` 1.2.3; yêu cầu resize tối đa 1600×1600, JPEG quality 85 và giới hạn 10 MiB. Không thêm `permission_handler` hoặc quyền storage rộng.
- Điểm vào app shell: `lib/main.dart`; form: `lib/screens/create_report_screen.dart`; màn draft AI: `lib/screens/report_draft_screen.dart`; widget thông báo: `lib/widgets/status_notice.dart`; model: `lib/models/report_draft.dart`; prompt: `lib/services/report_draft_prompt.dart`; service AI: `lib/services/gemini_report_service.dart`; tests: `test/widget_test.dart`, `test/report_draft_test.dart`, `test/gemini_report_service_test.dart`.
- Ngày 2 đã thêm nhập mô tả, camera/gallery picker, preview cục bộ, validation đầu vào và thông báo lỗi. Task 2 Ngày 3 đã thêm `ReportDraft` model/parser và prompt. Task 3 Ngày 3 đã nối Firebase Core/App Check vào app. Task 4 Ngày 3 đã thêm `GeminiReportService` với `responseSchema`, seam inject fake, chặn đầu vào và ánh xạ lỗi. **Task 5 Ngày 3 đã nối service vào UI** (CTA/loading/lỗi/retry + màn draft) và **chạy request Gemini thật đầu-cuối trên thiết bị Android** (chi tiết `docs/SESSION_2026-09-26_TASK5.md`). Vẫn chưa có lưu trữ cục bộ, dữ liệu lịch sử hoặc màn hình chỉnh sửa/chi tiết hoạt động.
- Khi người dùng chủ động bấm **Phân tích bằng AI**, mô tả và/hoặc ảnh được gửi tới Gemini; trước thao tác đó form chỉ giữ đầu vào trong state và ảnh picker tạm. Draft trả về chưa được lưu thành báo cáo; đầu vào không đảm bảo còn sau khi app đóng.
- **Quyết định Task 1 sau khi đổi hướng:** Firebase AI Logic + Gemini Developer API trên Spark/free tier. **Model hiện tại (cập nhật Task 5):** chính `gemini-3.8-flash` (free 20 req/ngày/model, cạn khi test 27/09) + **fallback tự động `gemini-3.5-flash-lite`** (free 500 req/ngày) khi gặp lỗi quota; chất lượng fallback thấp hơn — draft có thể cần xác nhận nhiều hơn. Không có Cloud Run backend hoặc Secret Manager do dự án tự quản lý; Gemini key được Firebase proxy giữ phía server.
- Chủ dự án đã chọn Android/Web trong `flutterfire configure`; theo worklog, Firebase Console đã bật API/AI monitoring và dùng project Spark. Các cấu hình `lib/firebase_options.dart`, `firebase.json`, `android/app/google-services.json` đã được commit trong Task 3; bản clone dùng Firebase project khác cần cấu hình lại.
- Quota Firebase AI Logic `Generate content requests` đã được đặt 5 RPM cho 10 vùng Asia (per-user/per-region); quota Gemini Developer API free tier vẫn cần kiểm tra khi dùng. Bidi giữ 100 vì app không dùng streaming.
- **Firebase đã nối vào app (Task 3, 2026-09-26):** `pubspec.yaml` có `firebase_core` 4.15.0, `firebase_ai` 4.0.0, `firebase_app_check` 0.4.8; `lib/main.dart` khởi tạo Firebase và trong `kDebugMode` kích hoạt App Check debug provider (`AndroidDebugProvider`/`WebDebugProvider`). App Check debug token đã đăng ký trong Console và **được backend chấp nhận ở request Gemini thật** (27/09/2026). Lỗi cài đè/gỡ cài có thể đổi token → 403 "App attestation failed" (app giờ hiển thị đúng thông báo App Check cho lỗi này — bug ánh xạ đã fix ở Task 5). Web debug provider chưa verify; provider production (Play Integrity/reCAPTCHA Enterprise) chưa cấu hình.
- Build hiện dùng các file cấu hình FlutterFire (`lib/firebase_options.dart`, `firebase.json`, `android/app/google-services.json`) đã được commit từ Task 3; nếu clone sang project Firebase khác thì phải chạy lại `flutterfire configure` và thay `google-services.json`.
- Free-tier request có thể được dùng để cải thiện sản phẩm Google; chỉ thử với fixture tổng hợp, không gửi ảnh/mô tả hiện trường thật. Giới hạn AI Logic: tổng request 20 MB, ảnh inline base64 7 MB; service chặn ảnh gốc gửi đi ở 4 MiB. Form vẫn nhận tới 10 MiB; kiểm thử thiết bị thật cho thấy picker resize/nén nên ngưỡng 10 MiB thực tế khó kích hoạt (chi tiết `docs/MANUAL_TESTCASES_APK.md` TC-3.7).
- Không cần Cloud Billing cho Spark/free tier. Paid tier/chi phí USD 5/tháng ở quyết định Cloud Run trước đây đã bị thay thế; nếu cần paid tier sau này phải xác nhận lại billing/ngân sách. Chi tiết và nguồn tại `docs/implement_plan_day3.md`/`docs/AI_WORKLOG.md`.
- **Quota free tier Gemini Developer API là per-model-per-day:** `gemini-3.8-flash` chỉ **20 request/ngày** (cạn trong phiên Task 5, cả request 429 cũng bị đếm), `gemini-3.5-flash-lite` **500 request/ngày**. Reset ~midnight Pacific (≈14:00–15:00 giờ VN). Dòng "Request limit per model per day" trong Cloud Console có thể Edit (Adjustable: Yes). Quota Firebase AI Logic 5 RPM vùng Asia đã đặt ở Task 1 không phải thứ chặn thực tế. Model fallback tự động là giải pháp hiện tại (chi tiết `docs/SESSION_2026-09-26_TASK5.md` mục 5–6).
- Task 2 có `ReportDraft` model/parser và prompt; Task 4 có `GeminiReportService` với 27 service tests (gồm App Check mapping + 3 fallback tests); Task 5 có 13 widget tests (gồm luồng AI). Sau Task 5, `flutter test` toàn bộ đạt **45/45** và `flutter analyze` toàn dự án sạch — xác nhận 2026-09-27.
- App không khai báo quyền runtime camera/ảnh (xác minh bằng merged manifest APK): camera qua Intent hệ thống, ảnh qua Photo Picker; nhánh permission-denied trong mã là fallback.

## Chạy và kiểm chứng

```bash
flutter pub get
flutter devices
flutter run -d <device-id>
flutter analyze
flutter test
flutter build apk --debug
```

Sau Task 3 (26/09/2026), đã kiểm chứng trong môi trường agent: `dart format` không đổi; `flutter analyze` toàn dự án sạch; `flutter test` 13/13 đạt; `flutter build web --release` thành công. Sau Task 4 (26/09/2026, hai lần trong ngày): `flutter analyze` — No issues found; `flutter test` — 33/33 đạt; `flutter build web --release` và `flutter build apk --debug` thành công; `dart format` không đổi.

Sau Task 5 (26–27/09/2026): `dart format` sạch; `flutter analyze` — No issues; `flutter test` — **45/45 đạt** (13 widget + 5 model + 27 service); `flutter build web --release` + `flutter build apk --debug` thành công. **Đã gọi Gemini thật trên thiết bị Android:** agent cài APK và lái UI qua adb — luồng nhập mô tả → Phân tích → màn "Bản nháp AI" mở với response thật; mô tả mơ hồ → 6 trường rỗng + needs_confirmation (không bịa); mô tả rõ → draft đúng dữ kiện; fallback quota xác minh qua log. Lịch sử Ngày 2: `dart format lib test`, `flutter analyze`, `flutter test` (8 tests), `flutter build web --release` và `flutter build apk --debug` đều thành công; APK debug ở `build/app/outputs/flutter-apk/app-debug.apk`.

Sau Task 4, chủ dự án đã cài APK debug và chạy 20 test case thủ công (`docs/MANUAL_TESTCASES_APK.md`) trên Android thật: 18/20 PASS. TC-3.6 xác nhận app không xin quyền runtime nào nhưng camera/ảnh vẫn dùng được (đúng thiết kế — Intent camera + Photo Picker); TC-3.7 xác nhận ảnh 12 MB sau resize của picker còn dưới 10 MiB nên ngưỡng form không kích hoạt (mã chặn giữ lại; Task 5 đã thêm chặn bytes 4 MiB trước gọi service). Kiểm chứng Task 3 (thiết bị thật, `adb logcat`, Firebase/App Check init sạch) vẫn giữ giá trị.

Sau Task 5, agent tạo bộ test case thủ công riêng cho luồng AI: `docs/MANUAL_TESTCASES_TASK5.md` (31 case). Chủ dự án xác nhận đã kiểm thử Task 5 và toàn bộ đạt PASS. Bảng trong file vẫn chưa có kết quả theo từng TC, thiết bị/model và số request nên không tự suy ra trạng thái riêng của từng case. Hai sự cố vận hành (App Check token, quota 20/ngày) cùng một số kết quả E2E đã được ghi trong `docs/AI_WORKLOG.md` và `docs/SESSION_2026-09-26_TASK5.md`.

Trong Windows workspace này, Kotlin incremental cache từng lỗi khi project ở ổ `D:` và Pub Cache ở ổ `C:`. `android/gradle.properties` hiện đặt `kotlin.incremental=false`; build chuẩn `flutter build apk --debug` đã thành công. Kotlin compile có thể chậm hơn do không dùng incremental cache.

## Tài liệu liên quan

- `AGENTS.md` — hướng dẫn coding agent và các ràng buộc sản phẩm.
- `README.md` — giới thiệu, kiến trúc, schema, cách chạy và hạn chế.
- `docs/CHALLENGE_VI_ROADMAP.md` — đề bài và kế hoạch 7 ngày.
- `docs/PROMPT_01.md` — prompt khởi tạo nền tảng.
- `docs/AI_WORKLOG.md` — công cụ AI, lỗi thực tế và kiểm chứng.
- `docs/WALKTHROUGH.md` — cách chạy và kiểm tra giao diện hiện có.
- `docs/MANUAL_TESTCASES_APK.md` — test case thủ công APK debug trên thiết bị thật.
- `docs/MANUAL_TESTCASES_TASK5.md` — test case thủ công luồng AI (Task 5) trên thiết bị thật.
- `docs/SESSION_2026-09-26_TASK5.md` — tổng kết phiên triển khai Task 5, sự cố App Check/quota và model fallback.
- `docs/implement_plan_day2.md` — phạm vi và tiêu chí triển khai Ngày 2.
- `docs/implement_plan_day3.md` — kế hoạch Ngày 3 theo Firebase AI Logic và trạng thái Task 1–5.
