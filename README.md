# AI Field Assistant

Ứng dụng Android-first dành trước hết cho nhân viên bảo trì tòa nhà ghi nhận sự cố điện, nước, điều hòa và thiết bị. Biểu mẫu dài làm gián đoạn công việc; báo cáo có thể thiếu ảnh/bối cảnh hoặc cách ghi không thống nhất. AI Field Assistant hướng tới chuyển mô tả/ảnh thành bản nháp có cấu trúc để nhân viên kiểm tra, chỉnh sửa và xác nhận trước khi lưu.

## Trạng thái hiện tại

Snapshot lịch sử của Day 5 được đối chiếu ngày 30/09/2026 trên `codex/day5`; Task 7 sau đó được ghi ở commit `eb54b34`. Công việc PDF hiện tiếp tục trên nhánh chưa commit `codex/report-pdf-export`, được tạo từ `eb54b34`. `docs/HOME_DEVICE_TEST_CHECKLIST.md` vẫn là tệp chưa được theo dõi, được giữ nguyên.

- Luồng hiện có: nhập mô tả/chọn ảnh → người dùng chủ động gọi AI → xem/sửa/xác nhận draft → lưu cục bộ → History → chi tiết report. Service AI, parser, SQLite repository và các màn UI đã được nối trong app.
- **Day 5 Task 1:** baseline lịch sử gồm 99/99 test, analyzer sạch, APK debug build/cài trên emulator. Đây là kết quả của Task 1, không phải build mới sau Task 3.
- **Day 5 Task 2:** đã chọn ảnh synthetic qua Photo Picker và xem preview. Lần thử AI trên emulator bị App Check chặn; chưa tạo report ảnh để xác minh persistence và chưa thử lưu/đọc offline. Hai phần persistence ảnh và offline vẫn BLOCKED.
- **Day 5 Task 3:** service từ chối MIME không hỗ trợ hoặc không khớp signature, chuẩn hóa lỗi đọc ảnh và giữ contract parser. Format check 26 file không đổi, analyzer sạch, test service/parser 43/43 và full suite 113/113 đạt; đây là kiểm tra host/fake, không phải Gemini thật.
- **Day 5 Task 4 hoàn tất ở host:** form giới hạn phân tích ở JPEG/PNG/WebP; ảnh BMP/GIF/HEIF/AVIF bị từ chối và ảnh hợp lệ trước đó được giữ. Widget tests bao phủ lỗi service/App Check/response, loading/retry, lưu lỗi/mơ hồ, double tap và Back. Ngày 30/09/2026, full suite đạt 117/117, `flutter analyze` sạch, format check 2 file Dart không đổi. Không build APK hoặc kiểm tra thiết bị trong Task 4.
- **Day 5 Task 5:** rà soát call site và dữ liệu gửi; service không còn log exception SDK thô. Analyzer và format check service sạch trong lượt này. Firebase debug provider vẫn ghi debug token vào log cục bộ; API-key restrictions chưa được kiểm tra trong Console, và không gọi Gemini thật.
- **Day 5 Task 6 (30/09/2026):** kiểm tra hiện có trên host đạt `flutter analyze` (No issues), `flutter test` 117/117 và format check 26 file/0 đổi. Flutter nhận điện thoại PKG110 Android 16/API 36 qua ADB Wireless, nhưng build APK từ source hiện tại bị automatic approval review từ chối trước khi lệnh chạy; vì vậy chưa cài APK mới hay kiểm tra UI Android cho source này. Task 6 mới hoàn tất phần host, phần thiết bị còn chờ.
- **Day 5 Task 7 (30/09/2026):** quyết định hoãn voice-to-text và GPS. PHOTO-D5-02/OFFLINE-D5-01 vẫn BLOCKED, còn Android UX Task 6 chưa chạy; gate P0 của kế hoạch chưa đạt. Không thêm dependency, quyền hay tính năng cộng thêm.
- **PDF export trên `codex/report-pdf-export`:** màn chi tiết hiện có thao tác tạo PDF bản đầy đủ cho report đã xác nhận, lưu qua Android document picker và mở Android share sheet. Host suite đạt 126/126, analyzer sạch, format check 29 file/0 đổi và APK debug build thành công. Lượt này không phát hiện Android device; lưu tệp trên máy, gửi qua share sheet và Zalo chưa được kiểm tra thiết bị.
- **Ngày 4 Task 7:** trên Android đã xác minh một report text-only còn ở History/detail sau force-stop/relaunch. Day 4 được đóng theo quyết định của chủ dự án với ngoại lệ; ảnh và offline chưa được nghiệm thu.

Firebase và App Check debug được khởi tạo khi mở app; lần gọi thật ngày 27/09/2026 từng trả draft trên Android. Lần thử gần nhất ghi trong Task 2 bị App Check chặn, nên không khẳng định dịch vụ hiện đang thông suốt. Chưa có voice-to-text, GPS, đăng nhập, cloud sync hoặc dashboard.

Task 5 privacy review: request chỉ được tạo sau khi người dùng bấm **Phân tích bằng AI**, gồm mô tả/ảnh đã chọn cùng system prompt/schema cố định; app không tự thêm GPS, tài khoản hay report đã lưu. Service không log prompt, ảnh, raw response hoặc exception SDK; lỗi được ánh xạ thành thông báo chung. App Check debug provider vẫn ghi debug token vào log cục bộ; không chụp/chia sẻ raw log. Chỉ dùng dữ liệu tổng hợp khi demo free tier.

## Kiến trúc hiện tại

```text
Flutter Material 3 app
└── lib/main.dart
    ├── AiFieldAssistantApp — theme và tên ứng dụng
    └── _HomeScreen — NavigationBar + IndexedStack
        ├── CreateReportScreen — mô tả, image picker, preview và CTA "Phân tích bằng AI"
        │   └── ReportDraftScreen — editor/review, xác nhận và gọi repository để lưu
        └── HistoryScreen — danh sách từ repository, trạng thái tải/lỗi/rỗng và chọn ID
            └── ReportDetailScreen — đọc report/ảnh đã lưu theo ID, có fallback lỗi và thao tác PDF
```

App shell ở `lib/main.dart` — `main()` async khởi tạo Firebase (`DefaultFirebaseOptions.currentPlatform`) và App Check debug provider trong `kDebugMode`; shell tạo một repository dùng chung cho form, lịch sử và màn chi tiết. Form nằm trong `lib/screens/create_report_screen.dart`; màn draft/editor ở `lib/screens/report_draft_screen.dart`; lịch sử ở `lib/screens/history_screen.dart`; chi tiết ở `lib/screens/report_detail_screen.dart`; widget thông báo ở `lib/widgets/status_notice.dart`. PDF được dựng bởi `lib/services/report_pdf_service.dart`; lưu/chia sẻ qua `lib/services/report_pdf_actions.dart`. Font Roboto tiếng Việt được bundle ở `assets/fonts/` cùng license. Schema/parser draft ở `lib/models/report_draft.dart`; model đã xác nhận, review state và priority ở `lib/models/report.dart`, `lib/models/report_review.dart`, `lib/models/report_priority.dart`. Prompt ở `lib/services/report_draft_prompt.dart`; service gọi Gemini qua Firebase AI Logic ở `lib/services/gemini_report_service.dart` (đã nối UI từ Task 5 Ngày 3). Repository contract, factory Android/Web và SQLite implementation ở `lib/repositories/`. Widget tests liên quan ở `test/widget_test.dart`, `test/history_screen_test.dart` và `test/report_detail_screen_test.dart`; model/review tests ở `test/report_draft_test.dart`, `test/report_test.dart`, `test/report_review_test.dart`; service tests ở `test/gemini_report_service_test.dart`, `test/report_pdf_service_test.dart`; SQLite repository tests ở `test/local_report_repository_test.dart`.

## Xuất PDF báo cáo đã lưu

Trên nhánh `codex/report-pdf-export`, màn **Chi tiết báo cáo** có nút **Lưu PDF** và **Chia sẻ PDF** cho report đã xác nhận/lưu. Tệp gồm sáu trường, thời gian tạo, mô tả gốc và ảnh nếu có; các giá trị đã xác nhận không có được ghi rõ, còn `suggested_action` luôn được gắn nhãn đề xuất. PDF được tạo cục bộ, hỗ trợ tiếng Việt qua font Roboto kèm theo, và chuyển ảnh WebP sang định dạng PDF hỗ trợ. Nếu ảnh không đọc được, người dùng phải xác nhận trước khi xuất bản không kèm ảnh.

Lưu mở Android document picker để người dùng chọn vị trí/tên. Chia sẻ mở bảng chia sẻ Android; ứng dụng đích (ví dụ Zalo) chỉ hiện nếu đã cài và hệ điều hành hỗ trợ nhận PDF. APK debug đã build và host tests đã đạt, nhưng lượt triển khai chưa có thiết bị Android kết nối; thao tác lưu/mở/chia sẻ thực tế và Zalo chưa được xác minh. Web repository hiện không hỗ trợ báo cáo cục bộ.

## Ngày 4 — editor/review/save, lịch sử và chi tiết đã triển khai

Task 1 đã chốt lưu báo cáo bằng SQLite trên Android và lưu bản sao ảnh trong thư mục application support; database giữ đường dẫn tương đối. Task 2 thêm `Report` immutable và `ReportReview`; Task 4 nối chúng vào editor. Sáu field bắt đầu pending dù AI không yêu cầu review; `issue` phải có nội dung; field tùy chọn rỗng cần xác nhận không có. Sửa field hủy xác nhận của field đó và summary. Editor có tiến độ review, xác nhận cuối, trạng thái lưu, xử lý lỗi/retry cùng ID và cảnh báo khi Back có thay đổi chưa lưu. Form nguồn chỉ được xóa sau khi save thành công.

Report kiểm tra ID, issue, đường dẫn ảnh tương đối và danh sách field xác nhận trống; serializer dùng timestamp UTC milliseconds và parse lỗi có kiểm soát. Task 3 thêm ReportRepository, SQLite Android schema v1, lưu ảnh trong application support, xử lý retry ID/lỗi storage; Web không hỗ trợ persistence. Task 4 nối repository vào màn lưu; Task 5 thêm History; Task 6 thêm chi tiết theo ID. Repository FFI được kiểm tra trên Windows. Task 7 vừa xác minh một report text-only còn trong History/detail sau force-stop/relaunch trên Android. Chưa xác minh lưu ảnh trên Android, hoạt động khi offline, mã hóa/backup hoặc giữ dữ liệu sau gỡ app.

Chi tiết tại docs/implement_plan_day4.md. Task 3 repository tests 10/10, suite 77/77 và APK/Web build thành công. Task 4 lịch sử có 85/85 tests; Task 5 có 90/90 tests; Task 6 có 99/99 tests và APK debug build. Task 7 vừa chạy lại 99/99 tests và repository FFI 10/10; APK debug build thành công. Android đã xác minh text-only report qua save → History → detail → force-stop/relaunch → History/detail. ADB không truy cập database riêng tư. Ảnh và offline còn cần kiểm tra.

## Luồng màn hình đã chốt

```text
Tạo báo cáo → Xem/chỉnh sửa bản nháp → Lịch sử → Chi tiết báo cáo
```

Đây là luồng sản phẩm đã thống nhất và các màn hiện đã được nối: **Tạo báo cáo** nhận mô tả/ảnh và tạo bản nháp AI; màn **"Bản nháp AI"** cho sửa/review và gọi repository để lưu sau xác nhận; tab **Lịch sử** đọc danh sách; chạm dòng mở **Chi tiết báo cáo** theo ID. Android đã xác minh end-to-end một report text-only còn đọc được sau restart process; luồng ảnh bền vững và lưu/đọc offline chưa được chứng minh.

## Quy trình AI — đã tích hợp ở mức draft (Task 5 Ngày 3)

Luồng đang chạy trong app:

```text
Mô tả/ảnh
  → CTA "Phân tích bằng AI" (người dùng chủ động bấm)
  → Firebase AI Logic SDK trong Flutter
  → Firebase-managed proxy + App Check
  → Gemini Developer API (chính `gemini-3.8-flash`; tự fallback `gemini-3.5-flash-lite` khi hết quota)
  → parse và kiểm tra JSON/schema
  → người dùng sửa/review bản nháp AI và xác nhận
  → lưu qua repository Android SQLite
  → hiển thị danh sách trong Lịch sử
  → mở Chi tiết báo cáo theo ID
```

SQLite/repository và màn hình đã được nối. Android đã kiểm chứng một report text-only sau restart process; lưu/đọc ảnh sau restart và lưu/đọc offline chưa được xác minh.

Schema thiết kế cho báo cáo gồm `category`, `location`, `priority`, `issue`, `suggested_action`, `summary` và `needs_confirmation`. Quy tắc giá trị trống:

| Trường | Quy tắc trong bản nháp | Điều kiện trước khi lưu |
|---|---|---|
| `category` | Chuỗi rỗng nếu không đủ căn cứ phân loại. | Có thể để trống sau khi người dùng xác nhận không xác định được. |
| `location` | Chuỗi rỗng nếu mô tả/ảnh không cung cấp địa điểm; không tự suy đoán. | Có thể để trống sau khi người dùng xác nhận không có thông tin. |
| `priority` | `low`, `medium`, `high` hoặc `null` nếu chưa đủ căn cứ; không tự mặc định `medium`. | Có thể để `null` sau khi người dùng xác nhận chưa xác định được. |
| `issue` | Có thể rỗng trong bản nháp và khi đó cần xác nhận. | Bắt buộc có nội dung trước khi lưu. |
| `suggested_action` | Chuỗi rỗng nếu không thể đề xuất an toàn. Đây luôn là đề xuất, không phải việc đã làm. | Có thể để trống sau khi người dùng xem lại. |
| `summary` | Có thể rỗng nếu chưa đủ dữ kiện; nếu có nội dung, chỉ tóm tắt dữ kiện đã xác nhận. | Có thể để trống sau khi người dùng xem lại. |
| `needs_confirmation` | Danh sách tên các trường cần bổ sung hoặc xác nhận. | Người dùng phải xem từng mục; có thể xác nhận trường không có dữ liệu và giữ trống. |

`created_at`, đường path ảnh và trạng thái báo cáo là metadata riêng, không phải trường nội dung cốt lõi. `ReportDraft` Dart model/parser và prompt được `GeminiReportService` dùng qua `responseSchema`. Prompt yêu cầu summary chỉ tóm tắt dữ kiện người dùng nêu rõ. AI chỉ tạo draft, `suggested_action` không phải hành động đã thực hiện. Kiến trúc AI: Firebase AI Logic trên Spark với Gemini Developer API, **model chính `gemini-3.8-flash` + fallback tự động `gemini-3.5-flash-lite`** khi gặp lỗi quota; request Gemini thật đã chạy đầu-cuối trên Android trong Task 5 Ngày 3 (lịch sử). Task 4 thêm editor/lưu; Task 5 Ngày 4 nối màn Lịch sử; Task 6 nối màn chi tiết. Task 7 đã xác minh report text-only còn sau process restart trên Android; ảnh Android và khả năng lưu/đọc offline chưa được xác minh.

## Quyết định kỹ thuật

- **Flutter/Dart:** ưu tiên một codebase Android-first phù hợp với prototype di động.
- **Web preview:** bật Web để xem giao diện trong môi trường chưa có Android device/emulator kết nối.
- **Material 3, `NavigationBar`, `IndexedStack`:** tạo điều hướng đơn giản, trạng thái chọn tab rõ ràng và chuyển màn hình không cần thư viện ngoài.
- **`image_picker` 1.2.3:** dùng system picker cho camera/thư viện; preview đọc bytes trong phiên hiện tại. Không thêm `permission_handler` hoặc quyền Android rộng trong bước này.
- Ảnh được yêu cầu resize tối đa 1600×1600, JPEG quality 85; kiểm tra file nhận được không quá 10 MiB. Đây là ngưỡng hiện tại của prototype.
- **AI đã tích hợp:** Firebase AI Logic gọi Gemini Developer API khi người dùng bấm CTA; model chính `gemini-3.8-flash`, fallback `gemini-3.5-flash-lite` chỉ khi model chính báo quota. Quota thay đổi theo project/thời gian; cần kiểm tra Console trước demo, không dựa vào số cũ trong tài liệu lịch sử. Firebase-managed proxy được dùng; dự án không tự quản lý backend/proxy riêng.
- **Input ảnh gửi AI:** service và form nhận `image/jpeg`, `image/png`, `image/webp` để phân tích; form giới hạn preview 10 MiB, service giới hạn bytes gửi 4 MiB. [Firebase AI Logic liệt kê ba MIME này cho ảnh inline](https://firebase.google.com/docs/ai-logic/input-file-requirements). Task 4 đã được kiểm tra bằng widget test host; chưa xác minh trên Android trong lượt này.
- Task 2 Ngày 3 thêm `ReportDraft` schema/parser và prompt; Task 4 Ngày 3 thêm service Firebase AI Logic với `responseSchema`, fake sender, timeout và ánh xạ lỗi; Task 5 Ngày 3 nối CTA/loading/lỗi/retry. Task 3 Ngày 5 bổ sung kiểm tra MIME/signature, lỗi đọc ảnh và test parser mà không đổi schema.
- **Firebase trong app (Task 3):** `firebase_core` 4.15.0, `firebase_ai` 4.0.0, `firebase_app_check` 0.4.8 (`firebase_auth` 6.7.0 là dependency chuyển tiếp). `main()` async khởi tạo Firebase và kích hoạt App Check debug provider trong `kDebugMode`; API `firebase_app_check` 0.4.8 dùng class provider mới (`providerAndroid`/`providerWeb`), tham số enum cũ đã deprecated.
- Firebase Console/App Check đã hoạt động cho lần request Android thật ngày 27/09/2026. Tuy nhiên, một lần thử khác trên emulator trong Task 2 Day 5 bị App Check từ chối; debug token có thể khác giữa thiết bị/cài đặt. Web và provider production (Play Integrity/reCAPTCHA Enterprise) chưa được xác minh/cấu hình. Firebase debug provider ghi token vào log cục bộ; không chụp/chia sẻ raw log hoặc đưa token vào tài liệu.
- Các khóa Firebase trong `firebase_options.dart`/`google-services.json` là cấu hình client nhận diện project, không phải Gemini Developer API key. Chưa kiểm tra API restrictions của project trong Google Cloud Console; không phát hiện Gemini Developer API key trong lần quét source/config Task 5. Xem [Firebase API key guidance](https://firebase.google.com/docs/projects/api-keys) và [Firebase AI Logic security checklist](https://firebase.google.com/docs/ai-logic/security-checklist).
- Các con số quota và trạng thái Console được ghi trong log theo thời điểm quan sát, không được truy vấn lại trong Task 3 Day 5. Quota có thể thay đổi; kiểm tra Firebase/Google Cloud Console trước request demo.
- Spark/free tier không cần thẻ hoặc Cloud Billing. Free-tier input có thể được dùng để cải thiện sản phẩm Google, nên chỉ thử bằng mô tả/ảnh tổng hợp, không dùng dữ liệu hiện trường thật. Paid tier và mục tiêu USD 5/tháng chưa áp dụng; việc bật billing sau này cần xác nhận riêng.
- Ứng dụng chặn ảnh gửi AI ở **4 MiB bytes gốc** tại form và service; form có thể giữ ảnh tới 10 MiB để preview cục bộ. Giới hạn của Firebase AI Logic phụ thuộc phiên bản/dịch vụ, nên cần kiểm tra tài liệu hiện hành nếu thay đổi ngưỡng.

## Chạy ứng dụng

Cần cài Flutter và Android SDK (để chạy Android). Lấy device ID bằng `flutter devices`.

```bash
flutter pub get
flutter run -d <device-id>
```

App khởi tạo Firebase khi mở. Build cần các file cấu hình FlutterFire (`lib/firebase_options.dart`, `firebase.json`, `android/app/google-services.json`); các file này đã được commit từ Task 3 Ngày 3, tuy nhiên project Firebase là tài nguyên cá nhân — bản clone với project Firebase khác phải chạy lại `flutterfire configure` và thay `google-services.json` tương ứng. Ở chế độ debug, log lần chạy đầu có dòng App Check debug token; token phải được đăng ký trong Firebase Console (App Check → Apps → Manage debug tokens) thì request backend sau này mới được chấp nhận. Không commit hay chia sẻ token.

Xem trước trên Chrome bằng `flutter run -d chrome`. Nếu Flutter yêu cầu chấp nhận Android SDK licenses, chạy `flutter doctor --android-licenses`. Tạo APK debug bằng:

```bash
flutter build apk --debug
```

`android/gradle.properties` tắt Kotlin incremental để tránh lỗi cache khi project Windows và Pub Cache nằm ở hai ổ đĩa khác nhau. Điều này làm một số lần build Kotlin biên dịch lại lâu hơn, nhưng không cần thêm tham số cho Android Studio hoặc `flutter run`. APK được tạo tại `build/app/outputs/flutter-apk/app-debug.apk`.

## Kiểm tra

```bash
dart format lib test
flutter analyze
flutter test
flutter build web --release
```

Sau Task 3 Ngày 3 (26/09/2026): `flutter analyze` toàn dự án sạch (hết 5 lỗi thiếu `firebase_core` trước đó), `flutter test` 13/13 đạt, `flutter build web --release` thành công, và app debug đã chạy trên điện thoại Android thật với Firebase khởi tạo thành công, App Check debug provider hoạt động, không error/crash trong log cold start (agent bắt log qua `adb logcat`; điện thoại kết nối adb không dây).

Sau Task 4 Ngày 3 (26/09/2026, xác nhận hai lần trong ngày — phiên triển khai và phiên rà soát): `dart format` không đổi; `flutter analyze` toàn dự án — No issues found; `flutter test` — 33/33 đạt (8 widget + 5 model + 20 service); `flutter build web --release` thành công; `flutter build apk --debug` thành công. Không gọi Gemini thật; mọi test dùng fixture tổng hợp với fake sender. **Tại thời điểm ghi nhận Task 4**, thay đổi service/test còn chưa commit; các bước Task 5 và Task 6 được ghi nhận sau đó.

Sau Task 5 Ngày 3 (26–27/09/2026): `dart format` sạch; `flutter analyze` — No issues; `flutter test` — **45/45 đạt** (13 widget + 5 model + 27 service); `flutter build web --release` + `flutter build apk --debug` thành công. **Request Gemini thật đã chạy đầu-cuối trên thiết bị Android** (agent cài APK và lái UI qua adb): nhập mô tả → Phân tích → màn "Bản nháp AI" mở với response thật; mô tả mơ hồ → draft giữ các trường rỗng + `needs_confirmation` (không bịa); fallback quota hoạt động theo log. Task 5 sau đó đã commit tại `c440da4`.

Task 6 (27/09/2026): `dart format --output=none --set-exit-if-changed lib test` — 11 file, 0 thay đổi; `flutter analyze` — No issues; `flutter test` — 45/45 đạt. Chủ dự án xác nhận kiểm thử thủ công Task 5 PASS. Không chạy build hoặc gửi request Gemini mới trong phiên Task 6; E2E thật được dẫn chiếu từ bằng chứng Task 5.

Task 5 Ngày 4 (2026-09-29): `dart format` chạy trên các file Dart đổi; `flutter analyze` — **No issues found!**; `flutter test test/history_screen_test.dart` — **5/5 đạt**; kiểm tra widget viewport 320×568 đạt; toàn suite `flutter test --reporter compact` — **90/90 đạt**. Không chạy APK/Web build, ADB/device test hoặc request Gemini. Widget tests dùng fake repository, nên không xác minh plugin SQLite/path_provider hoặc persistence Android.

Day 5 Task 3 (2026-09-29, theo ghi nhận của task trên host): `dart format --output=none --set-exit-if-changed lib test` — 26 file/0 đổi; `flutter analyze` — No issues; service/parser tests 43/43; `flutter test --reporter compact` — 113/113. Không gọi Gemini/App Check thật, không chạy APK build trong Task 3.

Kiểm thử thiết bị thật Task 4 (26/09/2026, APK debug do phiên rà soát build): chủ dự án chạy 20 test case thủ công (`docs/MANUAL_TESTCASES_APK.md`), 18/20 PASS; app không khai báo quyền runtime nào (camera qua Intent hệ thống, ảnh qua Photo Picker — đúng thiết kế); ảnh 12 MB sau resize của picker còn dưới 10 MiB nên ngưỡng 10 MiB của form thực tế khó kích hoạt (chi tiết TC-3.6/TC-3.7). Trước đó, sau thay đổi Ngày 2, `dart format lib test`, `flutter analyze`, `flutter test`, `flutter build web --release` và `flutter build apk --debug` đã thành công; chủ dự án cung cấp ảnh chụp xác nhận photo picker/chọn ảnh trên Android thật (ảnh nguồn trên 10 MiB vẫn hiện preview sau xử lý, không hiện số byte trước/sau).

## Hạn chế đã biết và hướng tiếp theo

- Một request Gemini thật đã thành công trong lịch sử 27/09; lần thử gần nhất ở Day 5 Task 2 bị App Check chặn. Chưa xác minh lại dịch vụ thật trong Task 3.
- Report text-only đã được xác minh sau restart process trên Android ở Day 4 Task 7. PHOTO-D5-02 và OFFLINE-D5-01 vẫn BLOCKED: chưa lưu/đọc report có ảnh sau restart, chưa thử save/read khi offline.
- Form và service hiện dùng chung allowlist JPEG/PNG/WebP; widget tests host đã kiểm tra phản hồi với BMP/GIF/HEIF/AVIF. Quota Firebase/Gemini là thông tin thay đổi theo thời điểm; xác minh Console trước demo.
- App Check production (Play Integrity/reCAPTCHA Enterprise) và Web provider chưa được xác minh/cấu hình cho phát hành. Không đưa debug token vào source, tài liệu chia sẻ, log hoặc APK release.
- Tab Lịch sử có loading, empty, lỗi/thử lại, refresh và chi tiết theo ID. Task 7 chứng minh report text-only đọc lại sau restart; lỗi SQLite/path_provider được kiểm tra trong test FFI/widget trên host, không được cố tình tạo trên điện thoại. ADB-D4-HIS-06 của Task 5 vẫn BLOCKED vì không có lỗi đọc tự nhiên. Ảnh và offline chưa xác minh.
- Form cho phép ảnh tới 10 MiB nhưng picker resize/nén trước khi trả về nên ngưỡng này thực tế khó kích hoạt; giới hạn gửi AI 4 MiB được kiểm tra ở cả form và service (Task 5).
- App không khai báo quyền runtime camera/ảnh: camera mở qua Intent hệ thống, ảnh qua Photo Picker (xác minh bằng merged manifest APK). Nhánh xử lý permission-denied trong mã giữ lại làm fallback.
- Kết quả cụ thể theo từng task trong `docs/AI_WORKLOG.md`; tổng kết phiên Task 5 và các sự cố vận hành ở `docs/SESSION_2026-09-26_TASK5.md`.

Task 6 kiểm tra tự động và Task 7 rà soát tài liệu Ngày 3 hoàn tất ngày 27/09/2026. Ngày 4 Task 2–6 đã triển khai. Theo quyết định chủ dự án, Task 7 Ngày 4 được đóng với ngoại lệ được chấp nhận; ảnh Android/offline vẫn chưa được xác minh và Day 4 chưa nghiệm thu đầy đủ. Task 2 Ngày 5 đã thử fixture qua Photo Picker, nhưng App Check chặn tạo draft nên các case persistence ảnh/offline vẫn BLOCKED. Day 5 Task 6 mới đạt host; UX trên thiết bị cần build/cài đúng source trước khi có thể kết luận. Task 7 tính năng cộng thêm tiếp tục hoãn. Chưa có kết quả theo từng dòng cho 31 test case AI Task 5 Ngày 3; không suy ra PASS từng case từ xác nhận PASS tổng thể của chủ dự án.

## Tài liệu dự án

- `AGENTS.md` — hướng dẫn dành cho coding agent.
- `docs/CHALLENGE_VI_ROADMAP.md` — đề bài và roadmap sản phẩm.
- `docs/AI_WORKLOG.md` — nhật ký sử dụng và kiểm chứng AI.
- `docs/CONTEXT_SUMMARY.md` — tóm tắt trạng thái để bàn giao coding agent.
- `docs/WALKTHROUGH.md` — hướng dẫn chạy và kiểm tra giao diện hiện tại.
- `docs/MANUAL_TESTCASES_APK.md` — test case thủ công cho APK debug trên thiết bị thật.
- `docs/testcase_task4_day4.txt` — test case Task 4 Ngày 4: thao tác trên điện thoại thật và qua ADB Wireless debugging.
- `docs/testcase_task5_history_day4.txt` — test case thủ công Task 5 Ngày 4 cho tab Lịch sử trên điện thoại Android và qua ADB Wireless debugging.
- `docs/testcase_task6_detail_day4.txt` — 10 PHONE cases và 6 ADB Wireless cases cho chi tiết report Task 6; kết quả lần lượt 2 PASS / 6 PARTIAL / 0 FAIL / 1 BLOCKED / 1 NOT RUN và 4 PASS / 2 PARTIAL / 0 FAIL / 0 BLOCKED / 0 NOT RUN.
- docs/testcase_task7_persistence_day4.txt — kết quả từng case Task 7: automated checks, text-only Android persistence, restart và blocker ảnh/offline.
- `docs/MANUAL_TESTCASES_TASK5.md` — test case thủ công cho luồng AI (Task 5) trên thiết bị thật.
- `docs/SESSION_2026-09-26_TASK5.md` — tổng kết phiên Task 5: triển khai, sự cố App Check/quota, model fallback.
- `docs/implement_plan_day3.md` — kế hoạch tích hợp Firebase AI Logic và trạng thái Task 1–7.
- `docs/implement_plan_day4.md` — task chỉnh sửa/xác nhận, persistence, lịch sử/chi tiết; Task 7 được đóng theo quyết định chủ dự án với ngoại lệ ảnh/offline; Day 4 chưa nghiệm thu đầy đủ.
- `docs/implement_plan_day5.md` — kế hoạch Day 5; Task 6 đạt kiểm tra host nhưng Android còn blocked; Task 2 còn blocker ảnh/offline; voice/GPS hoãn.
- `docs/implement_plan_pdf_export.md` — kế hoạch và trạng thái triển khai xuất PDF cho report đã xác nhận, lưu qua document picker và chia sẻ Android.
- `docs/testcase_day5_resilience.txt` — kết quả riêng của Day 5 Task 1–6, gồm test host và blocker Android.
- `docs/PROMPT_01.md` — prompt onboarding cho coding agent theo trạng thái dự án hiện tại.
