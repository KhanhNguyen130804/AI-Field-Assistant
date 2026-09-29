# Tóm tắt dự án — sau Task 6 Ngày 4

> Bản tóm tắt cập nhật sau khi hoàn tất Task 6 ngày 29/09/2026. Hướng dẫn chuẩn tắc vẫn nằm trong `AGENTS.md`; roadmap đầy đủ nằm trong `docs/CHALLENGE_VI_ROADMAP.md`. Các lần kiểm tra/build lịch sử, lượt triển khai và lượt ADB được phân biệt bên dưới.

## Cập nhật mới nhất — Ngày 4 Task 6 (2026-09-29)

`HistoryScreen` dùng cùng `ReportRepository` với form lưu. Màn tải khi vào tab Lịch sử và khi refresh token tăng sau save; có loading, empty state chỉ sau lần đọc thành công, lỗi/thử lại, pull-to-refresh và trạng thái nền tảng không hỗ trợ. Chạm một dòng mở `ReportDetailScreen` theo ID, màn này gọi `findById`, hiển thị report đã xác nhận, mô tả gốc, metadata và ảnh qua `readPhotoBytes`. Field được xác nhận là không có được gắn nhãn rõ; hành động đề xuất không bị mô tả như việc đã làm. Lỗi/không tìm thấy có trạng thái riêng; lỗi hoặc bytes ảnh hỏng có fallback/retry và không che nội dung report. Back quay về danh sách. Thông báo sau lưu đã được sửa thành hướng dẫn mở tab Lịch sử.

**Kiểm chứng vừa chạy trong Task 6:** `dart format` trên file Dart đổi; `flutter analyze` — No issues found; `flutter test --reporter compact` — **99/99 đạt**; `flutter build apk --debug` — exit 0, APK debug tạo được. 9 widget tests mới dùng fake repository, gồm điều hướng History → chi tiết → Back, nội dung/field trống đã xác nhận, loading, not-found, lỗi/retry và ảnh đọc/giải mã lỗi. Lượt ADB Wireless ngày 29/09 sau đó build/cài/chạy APK Task 6 và quan sát UI; test case thủ công có 4 ADB PASS/2 PARTIAL và 2 PHONE PASS/6 PARTIAL/1 BLOCKED/1 NOT RUN. Fixture sẵn có chưa xác minh. Không xác minh SQLite/path_provider sau force-stop/restart; đó là Task 7.

**Bằng chứng ADB của Task 5 (lịch sử, trước khi có màn chi tiết):** ngày 29/09, build APK debug thành công và `adb install -r` trả `Success` trên thiết bị PKG110 Android 16/API 36. ADB-D4-HIS-01–05 PASS; ADB-D4-HIS-06 BLOCKED do không gặp lỗi đọc tự nhiên. Đã kiểm tra tap dòng khi đó còn hiện placeholder, giữ mô tả khi đổi tab và một luồng Gemini tổng hợp → review → save → hiện report đầu danh sách. Không kiểm tra report/ảnh sau force-stop/restart; đây vẫn là việc của Task 7. Hash APK, log-filter, giới hạn và kết quả từng case nằm trong `docs/testcase_task5_history_day4.txt` và `docs/AI_WORKLOG.md`.

## Bối cảnh trước Task 5 — Ngày 4 Task 4 (2026-09-29)

Task 4 đã chuyển `ReportDraftScreen` thành editor/review: sửa sáu trường, review từng trường độc lập với badge AI, xác nhận field tùy chọn trống, bắt buộc `issue`, và yêu cầu review lại `summary` sau thay đổi dữ kiện. Trước khi lưu có xác nhận cuối; thao tác lưu khóa điều khiển, lỗi giữ snapshot/nội dung và cho retry cùng ID; trường hợp kết quả mơ hồ có thể tra `findById` để tránh lưu lặp. Back hỏi trước khi bỏ review; form gốc chỉ xóa sau kết quả lưu thành công. `main.dart` tạo/inject repository; tại thời điểm Task 4, màn Lịch sử/chi tiết chưa được nối.

Chi tiết repository Task 3: SQLite Android `reports.db` schema v1, serialize report, truy vấn mới nhất trước, sao chép ảnh vào thư mục app với đường dẫn tương đối; retry cùng ID chỉ nhận snapshot report/ảnh khớp; lỗi đọc/ghi dùng `ReportStorageException`; Web không hỗ trợ persistence. Dependencies: `sqflite 2.4.4`, `path_provider 2.1.6`, `path 1.9.1`, và dev-only `sqflite_common_ffi 2.4.3`.

**Kiểm chứng Task 4 (2026-09-29, lịch sử):** `dart format --set-exit-if-changed` trên bốn file Dart — exit 0, 0 file đổi; `flutter analyze` — No issues found; `flutter test` — **85/85 đạt**. Widget save tests dùng fake repository. Chủ dự án xác nhận PHONE-D4-01–14 PASS trên thiết bị thật; ADB Wireless debugging xác minh case 01–06 và 09 (một Gemini request tổng hợp mở draft; case 09 chỉ lọc log). ADB review/save, force-stop và disconnect chưa chạy. APK đã build ngày 28/09, cài đè và chạy lại ngày 29/09; lượt Task 4 không build APK/Web. Chưa xác minh độc lập plugin SQLite/path_provider hoặc đọc lại persistence Android sau restart. Thời điểm đó bước tiếp theo là Task 5; hiện Task 5–6 đã có màn danh sách/chi tiết, Task 7 xác minh persistence đầu-cuối vẫn còn.

## Cập nhật Ngày 4 Task 2 (lịch sử, 2026-09-27)

Đã thêm `Report` immutable cho báo cáo đã xác nhận, `ReportReview` cho state editor và `ReportPriority` dùng chung với draft. State review khởi tạo cả sáu field ở `pending`, tách cờ AI cần xem lại khỏi xác nhận của người dùng, kiểm tra field tùy chọn được xác nhận vắng mặt, bắt buộc issue, và hủy xác nhận summary khi dữ kiện đổi. Serializer kiểm tra schema, giữ Unicode/priority null/UTC milliseconds và từ chối dữ liệu sai. Chi tiết tại `docs/implement_plan_day4.md` và cuối `docs/AI_WORKLOG.md`.

Task 1 vẫn là quyết định thiết kế: SQLite trên Android, đường dẫn ảnh tương đối và bản sao ảnh thuộc app. Dependency `sqflite 2.4.4`, `path_provider 2.1.6`, `path 1.9.1` và dev-only `sqflite_common_ffi 2.4.3` mới chỉ resolve bằng dry-run, chưa thêm vào app. Chưa có database/repository, lưu ảnh, UI editor/lưu hoặc lịch sử; không có RAM fallback giả trên Web. Test repository dự kiến dùng SQLite FFI thật trên Windows rồi kiểm chứng plugin/restart trên Android.

Trong phiên Task 2, `dart format` trên 6 file liên quan kết thúc exit 0 (lần rà cuối 0 file cần format), `flutter analyze` — No issues found, `flutter test` — **67/67 đạt**. Dùng Flutter SDK snapshot để chạy analyze/test vì sandbox chặn cache/lock mặc định. Không chạy APK/build, thiết bị hoặc request Gemini; các kết quả 45/45 và build ở dưới là lịch sử Ngày 3. Bước tiếp theo: **Task 3 Ngày 4 — repository SQLite và lưu ảnh bền vững**.

## Quyết định Ngày 4 Task 1 (lịch sử)

Task 1 đã chốt hợp đồng `ReportReview`/`Report`, SQLite schema v1, repository lưu/list/findById, ID ổn định khi retry và bản sao ảnh trong application support. Khi Task 1 kết thúc, model/state review chưa có; Task 2 ở trên đã triển khai model/state nhưng không database/editor UI. Dry-run dependency, adb/doctor và các giới hạn preflight là kết quả lịch sử của Task 1.

## Cập nhật Task 6 (2026-09-27)

Task 6 đã chạy lại kiểm tra format ở chế độ read-only (11 file, 0 thay đổi), `flutter analyze` (No issues) và `flutter test` (45/45 đạt). Bằng chứng request Gemini thật đầu-cuối với App Check hợp lệ đã được ghi ở Task 5; chủ dự án xác nhận bộ kiểm thử thủ công Task 5 đã PASS. Không có kết quả theo từng TC trong bảng thủ công. Phiên này không gửi request Gemini mới vì app đang có ảnh được chọn không rõ nội dung; quota hiện tại cũng chưa được truy vấn từ Console. Chi tiết ở cuối `docs/AI_WORKLOG.md`.

Task 7 chỉ đồng bộ tài liệu và rà Git; không thay đổi mã/config, chạy build/test hoặc tạo request Gemini. Bước sản phẩm kế tiếp là Day 4: chỉnh sửa/xác nhận draft, lưu cục bộ và hiển thị lịch sử.

## Người dùng và vấn đề

AI Field Assistant trước hết dành cho **nhân viên bảo trì tòa nhà** ghi nhận sự cố điện, nước, điều hòa và thiết bị. Biểu mẫu dài làm gián đoạn công việc; báo cáo có thể thiếu ảnh/bối cảnh hoặc cách ghi không thống nhất. Ứng dụng hướng tới chuyển mô tả/ảnh thành bản nháp có cấu trúc để nhân viên kiểm tra, chỉnh sửa và xác nhận trước khi lưu.

## Luồng màn hình đã thống nhất

```text
Tạo báo cáo → Xem/chỉnh sửa bản nháp → Lịch sử → Chi tiết báo cáo
```

Đây là luồng sản phẩm đã thống nhất; hiện **Tạo báo cáo** nhập mô tả/chọn ảnh, gọi Gemini để mở draft chưa lưu, cho review/chỉnh sửa rồi lưu qua repository. **Lịch sử** đọc danh sách từ repository; chạm report mở **chi tiết đã lưu** đọc theo ID. Các widget tests dùng fake services/repositories và không chứng minh SQLite Android hoạt động sau restart.

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

`created_at`, đường dẫn ảnh và trạng thái báo cáo là metadata, không thuộc các trường nội dung lõi. Schema có `ReportDraft` parser và được `GeminiReportService` dùng qua `responseSchema` + parse/validate phía app. Request Gemini thật được xác minh đầu-cuối trên Android trong Task 5 lịch sử. Draft chỉ trở thành báo cáo sau khi người dùng hoàn thành review/xác nhận và repository trả kết quả lưu thành công. UI được kiểm tra bằng widget tests; chủ dự án xác nhận các PHONE case Task 4 PASS và ADB quan sát được một draft AI mở thành công. Đọc lại báo cáo/ảnh từ SQLite sau restart chưa được kiểm chứng.

## Công nghệ, hiện trạng và giới hạn

- **Flutter/Dart**, Android-first; Web bật để xem trước giao diện. UI dùng Material 3, `NavigationBar` và `IndexedStack`.
- Image picker: `image_picker` 1.2.3; yêu cầu resize tối đa 1600×1600, JPEG quality 85 và giới hạn 10 MiB. Không thêm `permission_handler` hoặc quyền storage rộng.
- Điểm vào app shell: `lib/main.dart`; form: `lib/screens/create_report_screen.dart`; editor/review: `lib/screens/report_draft_screen.dart`; lịch sử: `lib/screens/history_screen.dart`; chi tiết: `lib/screens/report_detail_screen.dart`; widget thông báo: `lib/widgets/status_notice.dart`; model draft: `lib/models/report_draft.dart`; model đã xác nhận: `lib/models/report.dart`; review state: `lib/models/report_review.dart`; priority dùng chung: `lib/models/report_priority.dart`; prompt: `lib/services/report_draft_prompt.dart`; service AI: `lib/services/gemini_report_service.dart`; repository contract/factory/SQLite: `lib/repositories/`; tests gồm `test/widget_test.dart`, `test/history_screen_test.dart`, `test/report_detail_screen_test.dart`, model/review tests, service tests và `test/local_report_repository_test.dart`.
- Ngày 2 đã thêm nhập mô tả, camera/gallery picker, preview cục bộ, validation đầu vào và thông báo lỗi. Task 2 Ngày 3 thêm `ReportDraft` model/parser và prompt; Task 2 Ngày 4 thêm model/state review; Task 3 Ngày 3 nối Firebase Core/App Check; Task 4 Ngày 3 thêm `GeminiReportService`; Task 5 Ngày 3 nối service vào UI và có bằng chứng request Gemini thật trên Android. Task 3 Ngày 4 thêm repository SQLite/lưu ảnh; Task 4 Ngày 4 nối editor/review/save vào form; Task 5–6 Ngày 4 nối màn lịch sử và chi tiết. **Persistence report/ảnh sau restart Android chưa được kiểm chứng.**
- Khi người dùng chủ động bấm **Phân tích bằng AI**, mô tả và/hoặc ảnh được gửi tới Gemini; trước thao tác đó form chỉ giữ đầu vào trong state và ảnh picker tạm. Draft trả về chưa tự lưu; sau review/xác nhận, editor gọi repository Android SQLite. Chủ dự án xác nhận PHONE-D4-01–14 PASS ở Task 4 và PHONE-D4-HIS-01–09 PASS ở Task 5. ADB Task 5 đã chạy một luồng lưu rồi đọc danh sách trong cùng phiên app; widget tests dùng fake repository. Chưa kiểm tra độc lập việc report/ảnh còn sau force-stop/restart.
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
- `docs/AI_WORKLOG.md` — công cụ AI, lỗi thực tế và kiểm chứng.
- `docs/WALKTHROUGH.md` — cách chạy và kiểm tra giao diện hiện có.
- `docs/MANUAL_TESTCASES_APK.md` — test case thủ công APK debug trên thiết bị thật.
- `docs/testcase_task5_history_day4.txt` — kết quả theo từng case Task 5 Ngày 4: PHONE 9/9 PASS theo báo cáo người dùng; ADB 5 PASS, 1 BLOCKED.
- `docs/testcase_task6_detail_day4.txt` — 10 PHONE cases và 6 ADB Wireless cases cho màn chi tiết Task 6; kết quả hiện tại: PHONE 2 PASS / 6 PARTIAL / 0 FAIL / 1 BLOCKED / 1 NOT RUN; ADB 4 PASS / 2 PARTIAL / 0 FAIL / 0 BLOCKED / 0 NOT RUN. Fixture thiết bị chưa xác minh nguồn.
- `docs/MANUAL_TESTCASES_TASK5.md` — test case thủ công luồng AI (Task 5) trên thiết bị thật.
- `docs/SESSION_2026-09-26_TASK5.md` — tổng kết phiên triển khai Task 5, sự cố App Check/quota và model fallback.
- `docs/implement_plan_day2.md` — phạm vi và tiêu chí triển khai Ngày 2.
- `docs/implement_plan_day3.md` — kế hoạch Ngày 3 theo Firebase AI Logic và trạng thái Task 1–5.
- `docs/implement_plan_day4.md` — hợp đồng đã chốt ở Task 1 và kế hoạch Task 2–8.
