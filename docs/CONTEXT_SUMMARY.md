# Tóm tắt dự án — trạng thái sau Day 5 Task 5

> Trạng thái được đối chiếu ngày 30/09/2026: Day 5 Task 4 đã được commit tại `ec51214` (`feat(day5): complete task 4 resilience`) trên `codex/day5`, đồng bộ với `origin/codex/day5`. Trước lần cập nhật README/context trong phiên khảo sát, không có tracked changes; `docs/HOME_DEVICE_TEST_CHECKLIST.md` là tệp chưa được theo dõi. Checklist này được viết từ snapshot cũ và phần Task 4 của nó chưa phản ánh implementation hiện tại. Hướng dẫn chuẩn tắc nằm trong `AGENTS.md`; roadmap đầy đủ nằm trong `docs/CHALLENGE_VI_ROADMAP.md`. Các kết quả kiểm thử bên dưới là bằng chứng lịch sử theo từng task, không phải kiểm tra vừa chạy trong lượt khảo sát.

## Trạng thái hiện tại — Day 5 Task 1–5

- Luồng đang có trong ứng dụng: mô tả/chọn ảnh → người dùng chủ động gọi Firebase AI Logic → chỉnh sửa và xác nhận draft → lưu qua repository SQLite Android → History → chi tiết theo ID.
- **Task 1:** baseline lịch sử gồm 99/99 tests, analyzer sạch và APK debug build/cài trên emulator. Đây không phải kết quả build của Task 3.
- **Task 2:** fixture ảnh tổng hợp xuất hiện trong Photo Picker và preview được. Lần gọi AI trên emulator bị App Check chặn; chưa tạo report ảnh để xác minh persistence và chưa kiểm tra lưu/đọc offline. PHOTO-D5-02 và OFFLINE-D5-01 còn BLOCKED.
- **Task 3:** service chấp nhận JPEG/PNG/WebP, kiểm tra MIME khớp chữ ký bytes, kiểm tra PNG tối thiểu và chuẩn hóa lỗi đọc ảnh; parser giữ contract hiện tại. Ghi nhận của Task 3: format 26 file/0 thay đổi, `flutter analyze` sạch, service/parser 43/43 và full suite 113/113. Không gọi Gemini/App Check thật, không build APK.
- **Task 4 (30/09/2026):** form giới hạn ảnh phân tích ở JPEG/PNG/WebP, thông báo rõ khi loại ảnh không hỗ trợ và giữ preview trước. Tests bao phủ lỗi App Check/response/service/timeout/quota, giữ input và retry, loading/double tap, validation review/save, lỗi lưu/retry cùng ID, kết quả lưu mơ hồ khớp/conflict, Back khi có chỉnh sửa/đang save, và form chỉ xóa sau save thành công. Full suite đạt 117/117; `flutter analyze` sạch; format check 2 file Dart không đổi. Đây là kiểm chứng host/fake; không gọi Gemini thật, không build APK, không kiểm tra Android trong lượt này.
- **Task 5 (30/09/2026):** rà call site xác nhận yêu cầu AI chỉ phát sinh từ CTA phân tích, chỉ gửi mô tả/ảnh người dùng cùng prompt/schema cố định, không tự thêm GPS/tài khoản/report đã lưu. Đã bỏ log exception SDK thô; log fallback còn lại là thông báo tĩnh về chuyển model. Quét marker secret trong source/config/test/tài liệu hiện tại phát hiện cấu hình Firebase client; không phát hiện Gemini Developer API key/private key trong phạm vi quét. Chưa kiểm tra API restrictions trong Console, không quét lịch sử Git hoặc APK. Firebase App Check debug provider vẫn ghi debug token vào log cục bộ theo hành vi SDK; không chia sẻ raw log. Không gọi Gemini/App Check thật trong Task 5.

Khóa Firebase client trong cấu hình là để nhận diện project và không thay thế cơ chế authorization; cần giữ API restrictions phù hợp. Không tìm thấy Gemini Developer API key trong phạm vi quét. Phân loại dựa theo [Firebase API key guidance](https://firebase.google.com/docs/projects/api-keys) và [Firebase AI Logic security checklist](https://firebase.google.com/docs/ai-logic/security-checklist); cấu hình restrictions thực tế chưa được kiểm tra trong Console.
- **Giới hạn cần giữ:** preview vẫn có thể fallback nếu bytes không giải mã được dù chữ ký hợp lệ; ngưỡng preview là 10 MiB còn gửi AI là 4 MiB. Request Gemini thật từng thành công trên Android ngày 27/09/2026, nhưng không chứng minh lần gọi mới nhất hoạt động.

## Bằng chứng lịch sử — Ngày 4 Task 7 (đóng theo quyết định chủ dự án, 2026-09-29)

Trong lượt rà soát Day 4 Task 7, `dart format --output=none --set-exit-if-changed lib test` xét 26 file/0 đổi; `flutter analyze` sạch; toàn suite đạt 99/99; `local_report_repository_test.dart` đạt 10/10 với SQLite FFI host; APK debug build thành công. Trên PKG110 Android 16/API 36, một request AI với nội dung tổng hợp tạo draft text-only; report được review/lưu, mở đúng ở History/detail, rồi còn đọc được sau force-stop/relaunch. APK cài đặt được so hash trùng APK build. Logcat giới hạn 1.956 dòng có 0 match FATAL EXCEPTION và 0 match nhóm SQLite/plugin error đã lọc.

Theo quyết định của chủ dự án, Task 7 được đóng với ngoại lệ được chấp nhận; điều này không biến các case chưa chạy thành PASS và không đồng nghĩa nghiệm thu đầy đủ Ngày 4. Ảnh tổng hợp không xuất hiện trong Photo Picker nên chưa lưu/reopen report có ảnh; offline save/read chưa chạy vì chỉ có ADB Wireless transports và tắt Wi-Fi sẽ làm mất kênh điều khiển. Issue rỗng từng được thấy trong editor nhưng chưa thử nút lưu khi mọi field khác đã review; widget tests bao phủ validation. Model thực tế của request Gemini không được ghi nhận độc lập. Case-by-case ở docs/testcase_task7_persistence_day4.txt; ảnh/offline là follow-up khi có thiết bị/đường điều khiển phù hợp.

Một báo cáo tổng hợp Task 7 được giữ trên thiết bị để nhận diện kết quả sau restart; không xóa bản ghi hay đọc các report khác. Fixture ảnh/screenshot tạm trong thiết bị và Temp chưa dọn được sau khi automatic approval review chặn lệnh xóa kết hợp nhiều filesystem/shell; không có lệnh xóa nào chạy. Trước yêu cầu publish: nhánh codex/day4-preflight, HEAD đầu lượt da407b6; deletion có trước docs/PROMPT_01.md được giữ nguyên và không đưa vào commit Task 7.

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

**Bản ghi lịch sử trước lượt xác minh Task 7 ngày 29/09:** lượt đó chỉ đồng bộ tài liệu và rà Git; không thay đổi mã/config, chạy build/test hoặc tạo request Gemini. Bước sản phẩm kế tiếp khi ấy là Day 4: chỉnh sửa/xác nhận draft, lưu cục bộ và hiển thị lịch sử. Trạng thái mới nhất nằm ở phần đầu tài liệu.

## Người dùng và vấn đề

AI Field Assistant trước hết dành cho **nhân viên bảo trì tòa nhà** ghi nhận sự cố điện, nước, điều hòa và thiết bị. Biểu mẫu dài làm gián đoạn công việc; báo cáo có thể thiếu ảnh/bối cảnh hoặc cách ghi không thống nhất. Ứng dụng hướng tới chuyển mô tả/ảnh thành bản nháp có cấu trúc để nhân viên kiểm tra, chỉnh sửa và xác nhận trước khi lưu.

## Luồng màn hình đã thống nhất

```text
Tạo báo cáo → Xem/chỉnh sửa bản nháp → Lịch sử → Chi tiết báo cáo
```

Đây là luồng sản phẩm đã thống nhất; hiện **Tạo báo cáo** nhập mô tả/chọn ảnh, gọi Gemini để mở draft chưa lưu, cho review/chỉnh sửa rồi lưu qua repository. **Lịch sử** đọc danh sách từ repository; chạm report mở **chi tiết đã lưu** đọc theo ID. Widget tests dùng fake services/repositories; Task 7 đã xác minh một report text-only còn đọc được trên Android sau restart process. Ảnh và offline chưa xác minh.

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

`created_at`, đường dẫn ảnh và trạng thái báo cáo là metadata, không thuộc các trường nội dung lõi. Schema có `ReportDraft` parser và được `GeminiReportService` dùng qua `responseSchema` + parse/validate phía app. Request Gemini thật được xác minh đầu-cuối trên Android trong Task 5 lịch sử. Draft chỉ trở thành báo cáo sau khi người dùng hoàn thành review/xác nhận và repository trả kết quả lưu thành công. UI được kiểm tra bằng widget tests; chủ dự án xác nhận các PHONE case Task 4 PASS và ADB quan sát được một draft AI mở thành công. Task 7 đã xác minh một report text-only còn sau process restart trên Android; ảnh và offline chưa kiểm chứng.

## Công nghệ, hiện trạng và giới hạn

- **Flutter/Dart**, Android-first; Web bật để xem trước giao diện. UI dùng Material 3, `NavigationBar` và `IndexedStack`.
- Image picker: `image_picker` 1.2.3; yêu cầu resize tối đa 1600×1600, JPEG quality 85 và giới hạn 10 MiB. Không thêm `permission_handler` hoặc quyền storage rộng.
- Điểm vào app shell: `lib/main.dart`; form: `lib/screens/create_report_screen.dart`; editor/review: `lib/screens/report_draft_screen.dart`; lịch sử: `lib/screens/history_screen.dart`; chi tiết: `lib/screens/report_detail_screen.dart`; widget thông báo: `lib/widgets/status_notice.dart`; model draft: `lib/models/report_draft.dart`; model đã xác nhận: `lib/models/report.dart`; review state: `lib/models/report_review.dart`; priority dùng chung: `lib/models/report_priority.dart`; prompt: `lib/services/report_draft_prompt.dart`; service AI: `lib/services/gemini_report_service.dart`; repository contract/factory/SQLite: `lib/repositories/`; tests gồm `test/widget_test.dart`, `test/history_screen_test.dart`, `test/report_detail_screen_test.dart`, model/review tests, service tests và `test/local_report_repository_test.dart`.
- Ngày 2 đã thêm nhập mô tả, camera/gallery picker, preview cục bộ, validation đầu vào và thông báo lỗi. Task 2 Ngày 3 thêm `ReportDraft` model/parser và prompt; Task 2 Ngày 4 thêm model/state review; Task 3 Ngày 3 nối Firebase Core/App Check; Task 4 Ngày 3 thêm `GeminiReportService`; Task 5 Ngày 3 nối service vào UI và có bằng chứng request Gemini thật trên Android. Task 3 Ngày 4 thêm repository SQLite/lưu ảnh; Task 4 Ngày 4 nối editor/review/save vào form; Task 5–6 Ngày 4 nối màn lịch sử và chi tiết. Task 7 đã xác minh text-only persistence qua process restart; ảnh/offline còn thiếu.
- Khi người dùng chủ động bấm **Phân tích bằng AI**, mô tả và/hoặc ảnh được gửi tới Gemini; trước thao tác đó form chỉ giữ đầu vào trong state và ảnh picker tạm. Draft trả về chưa tự lưu; sau review/xác nhận, editor gọi repository Android SQLite. Chủ dự án xác nhận PHONE-D4-01–14 PASS ở Task 4 và PHONE-D4-HIS-01–09 PASS ở Task 5. ADB Task 5 đã chạy một luồng lưu rồi đọc danh sách trong cùng phiên app; widget tests dùng fake repository. Task 7 đã xác minh một report text-only còn ở History/detail sau force-stop/restart; report có ảnh và offline chưa xác minh.
- **AI:** Firebase AI Logic + Gemini Developer API trên Spark/free tier; model chính `gemini-3.8-flash`, fallback `gemini-3.5-flash-lite` khi gặp quota. Quota và cấu hình Console có thể đổi, chưa được truy vấn lại trong Task 3 Day 5 nên không coi các số cũ trong worklog là hiện trạng. Firebase-managed proxy được dùng; repo không có Cloud Run backend do dự án tự quản lý.
- Chủ dự án đã chọn Android/Web trong `flutterfire configure`; theo worklog, Firebase Console đã bật API/AI monitoring và dùng project Spark. Các cấu hình `lib/firebase_options.dart`, `firebase.json`, `android/app/google-services.json` đã được commit trong Task 3; bản clone dùng Firebase project khác cần cấu hình lại.
- Theo cấu hình được ghi trong worklog lịch sử, quota Firebase AI Logic `Generate content requests` từng được đặt 5 RPM cho 10 vùng Asia (per-user/per-region). Chưa kiểm tra cấu hình Console hiện tại; Bidi không dùng trong app.
- **Firebase/App Check:** `pubspec.yaml` khai báo `firebase_core` 4.15.0, `firebase_ai` 4.0.0, `firebase_app_check` 0.4.8; `lib/main.dart` khởi tạo Firebase và debug provider trong `kDebugMode`. Một request Android thật thành công ngày 27/09/2026 (bằng chứng lịch sử); lần thử mới hơn ở Day 5 Task 2 bị App Check từ chối. Web debug provider và provider production (Play Integrity/reCAPTCHA Enterprise) chưa được xác minh/cấu hình.
- Build hiện dùng các file cấu hình FlutterFire (`lib/firebase_options.dart`, `firebase.json`, `android/app/google-services.json`) đã được commit từ Task 3; nếu clone sang project Firebase khác thì phải chạy lại `flutterfire configure` và thay `google-services.json`.
- **Input ảnh AI:** Firebase AI Logic hỗ trợ inline JPEG/PNG/WebP; service kiểm tra MIME/signature, cấu trúc PNG tối thiểu và giới hạn bytes gốc 4 MiB. Form chỉ nhận ba loại này để phân tích; preview tối đa 10 MiB. Chỉ dùng fixture tổng hợp với free tier; không gửi dữ liệu hiện trường thật.
- Không cần Cloud Billing cho Spark/free tier. Paid tier/chi phí USD 5/tháng ở quyết định Cloud Run trước đây đã bị thay thế; nếu cần paid tier sau này phải xác nhận lại billing/ngân sách. Chi tiết và nguồn tại `docs/implement_plan_day3.md`/`docs/AI_WORKLOG.md`.
- Quota per-model, số lượng request/ngày và thiết lập Console ở các tài liệu phiên cũ chỉ là ảnh chụp lịch sử; kiểm tra Firebase/Google Cloud Console trước demo hoặc khi xử lý quota. Không dựa vào các con số lịch sử như cấu hình hiện tại.
- Lịch sử test Day 3 (`45/45`) vẫn được giữ ở phần kiểm chứng bên dưới; bằng chứng mới hơn của Day 5 Task 3 là full suite `113/113`, service/parser `43/43` và analyzer sạch, không có request Gemini thật trong lượt đó.
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
- docs/testcase_task7_persistence_day4.txt — kết quả từng case Task 7: automated checks, text-only Android persistence, restart và blocker ảnh/offline.
- `docs/MANUAL_TESTCASES_TASK5.md` — test case thủ công luồng AI (Task 5) trên thiết bị thật.
- `docs/SESSION_2026-09-26_TASK5.md` — tổng kết phiên triển khai Task 5, sự cố App Check/quota và model fallback.
- `docs/implement_plan_day2.md` — phạm vi và tiêu chí triển khai Ngày 2.
- `docs/implement_plan_day3.md` — kế hoạch Ngày 3 theo Firebase AI Logic và trạng thái Task 1–5.
- `docs/implement_plan_day4.md` — hợp đồng đã chốt ở Task 1 và kế hoạch Task 2–8, gồm tiến độ một phần của Task 7.
- `docs/implement_plan_day5.md` — kế hoạch Day 5; Task 1–5 có kết quả audit/host theo từng giới hạn, Task 2 còn blocker ảnh/offline; Task 6–8 chưa thực hiện.
- `docs/testcase_day5_resilience.txt` — evidence/case Day 5 Task 1–4, gồm kiểm tra host và blocker Android.
- `docs/PROMPT_01.md` — prompt onboarding coding agent theo trạng thái repo hiện tại.
