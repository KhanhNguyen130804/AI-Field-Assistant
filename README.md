# AI Field Assistant

Ứng dụng Android-first dành trước hết cho nhân viên bảo trì tòa nhà ghi nhận sự cố điện, nước, điều hòa và thiết bị. Biểu mẫu dài làm gián đoạn công việc; báo cáo có thể thiếu ảnh/bối cảnh hoặc cách ghi không thống nhất. AI Field Assistant hướng tới chuyển mô tả/ảnh thành bản nháp có cấu trúc để nhân viên kiểm tra, chỉnh sửa và xác nhận trước khi lưu.

## Trạng thái hiện tại

Đã có hai khu vực điều hướng bằng tab tiếng Việt:

- **Tạo báo cáo:** nhập mô tả, chụp/chọn một ảnh, xem preview và xem lại đầu vào cục bộ.
- **Lịch sử:** trạng thái rỗng cho báo cáo đã lưu trong tương lai.

Mô tả nằm trong state của màn hình; ảnh dùng `XFile` tạm do picker cung cấp. Đầu vào không gửi qua mạng và chưa được lưu thành báo cáo. Từ Ngày 3 Task 3, app khởi tạo Firebase và App Check debug provider (chế độ debug) khi mở. Từ Ngày 3 Task 4, có sẵn service gọi Gemini (`lib/services/gemini_report_service.dart`) với unit test đầy đủ, nhưng **chưa được nối vào màn hình** — app chưa có nút gọi AI và chưa gửi request Gemini thật. Chưa tích hợp hiển thị/sửa báo cáo AI, lưu trữ, lịch sử có dữ liệu, voice-to-text, GPS, đăng nhập hoặc cloud; app không đảm bảo giữ đầu vào sau khi đóng.

## Kiến trúc hiện tại

```text
Flutter Material 3 app
└── lib/main.dart
    ├── AiFieldAssistantApp — theme và tên ứng dụng
    └── _HomeScreen — NavigationBar + IndexedStack
        ├── CreateReportScreen — mô tả, image picker và preview cục bộ
        └── _HistoryScreen — empty state
```

App shell ở `lib/main.dart` — `main()` async khởi tạo Firebase (`DefaultFirebaseOptions.currentPlatform`) và App Check debug provider trong `kDebugMode`. Form nằm trong `lib/screens/create_report_screen.dart`. Schema/parser bản nháp ở `lib/models/report_draft.dart`, prompt ở `lib/services/report_draft_prompt.dart`; service gọi Gemini qua Firebase AI Logic ở `lib/services/gemini_report_service.dart` (chưa nối UI). Widget tests ở `test/widget_test.dart`; model tests ở `test/report_draft_test.dart`; service tests ở `test/gemini_report_service_test.dart`.

## Luồng màn hình đã chốt

```text
Tạo báo cáo → Xem/chỉnh sửa bản nháp → Lịch sử → Chi tiết báo cáo
```

Đây là luồng sản phẩm đã thống nhất cho thiết kế. Hiện **Tạo báo cáo** cho nhập và xem lại đầu vào cục bộ; **Lịch sử** vẫn rỗng. AI draft, màn hình kết quả/chỉnh sửa, lưu và chi tiết chưa được dựng hay giả lập bằng dữ liệu mẫu.

## Quy trình AI dự kiến — chưa tích hợp

Khi triển khai, luồng mục tiêu là:

```text
Mô tả/ảnh
  → Firebase AI Logic SDK trong Flutter
  → Firebase-managed proxy + App Check
  → Gemini Developer API
  → parse và kiểm tra JSON/schema
  → người dùng xem, sửa và xác nhận bản nháp
  → lưu cục bộ
  → hiển thị trong Lịch sử
```

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

`created_at`, đường path ảnh và trạng thái báo cáo là metadata riêng, không phải trường nội dung cốt lõi. `ReportDraft` Dart model/parser và prompt đã được tạo và đã được nối vào `GeminiReportService` (Task 4 Ngày 3) với `responseSchema` ở phía SDK — nhưng service chưa gọi Gemini thật và chưa nối UI. Prompt yêu cầu summary chỉ tóm tắt dữ kiện người dùng nêu rõ. AI chỉ được phép tạo bản nháp, `suggested_action` không phải hành động đã thực hiện. Đã chọn Firebase AI Logic trên Spark với Gemini Developer API `gemini-3.8-flash`; Firebase Core/App Check đã được nối vào app (Task 3 Ngày 3); service + unit test đã có (Task 4 Ngày 3) nhưng chưa có màn hình draft, chưa có request thật và chưa có cơ sở dữ liệu.

## Quyết định kỹ thuật

- **Flutter/Dart:** ưu tiên một codebase Android-first phù hợp với prototype di động.
- **Web preview:** bật Web để xem giao diện trong môi trường chưa có Android device/emulator kết nối.
- **Material 3, `NavigationBar`, `IndexedStack`:** tạo điều hướng đơn giản, trạng thái chọn tab rõ ràng và chuyển màn hình không cần thư viện ngoài.
- **`image_picker` 1.2.3:** dùng system picker cho camera/thư viện; preview đọc bytes trong phiên hiện tại. Không thêm `permission_handler` hoặc quyền Android rộng trong bước này.
- Ảnh được yêu cầu resize tối đa 1600×1600, JPEG quality 85; kiểm tra file nhận được không quá 10 MiB. Đây là ngưỡng hiện tại của prototype.
- **AI đã chọn, chưa tích hợp:** Firebase AI Logic trên Spark, Gemini Developer API `gemini-3.8-flash`. Firebase-managed proxy giữ Gemini API key phía server; không có Cloud Run backend hoặc Secret Manager do dự án tự quản lý.
- Task 2 đã thêm `ReportDraft` schema/parser và prompt; Task 4 đã thêm service Firebase AI Logic với `responseSchema`, seam inject fake, chặn đầu vào (rỗng/ảnh > 4 MiB/loại lạ), timeout 60 giây và ánh xạ lỗi; smoke test với model thật chưa chạy.
- **Firebase trong app (Task 3):** `firebase_core` 4.15.0, `firebase_ai` 4.0.0, `firebase_app_check` 0.4.8 (`firebase_auth` 6.7.0 là dependency chuyển tiếp). `main()` async khởi tạo Firebase và kích hoạt App Check debug provider trong `kDebugMode`; API `firebase_app_check` 0.4.8 dùng class provider mới (`providerAndroid`/`providerWeb`), tham số enum cũ đã deprecated.
- Firebase Console đã bật API, AI monitoring và đăng ký app Android/Web; FlutterFire tạo `lib/firebase_options.dart`. App Check debug token của thiết bị Android thử nghiệm đã được đăng ký trong Console và khởi tạo đã kiểm chứng sạch trên thiết bị thật; Web chưa verify và provider production (Play Integrity/reCAPTCHA Enterprise) chưa cấu hình nên trang Apps của Console vẫn có thể hiển thị `Unregistered`.
- Firebase AI Logic quota `Generate content requests` đã được đặt 5 RPM cho từng vùng Asia trong bảng quota (per-user/per-region); quota riêng của Gemini Developer API free tier vẫn có thể thấp hơn. Quota Bidi chưa đổi vì app không dùng streaming.
- Spark/free tier không cần thẻ hoặc Cloud Billing. Free-tier input có thể được dùng để cải thiện sản phẩm Google, nên chỉ thử bằng mô tả/ảnh tổng hợp, không dùng dữ liệu hiện trường thật. Paid tier và mục tiêu USD 5/tháng chưa áp dụng; việc bật billing sau này cần xác nhận riêng.
- Firebase AI Logic giới hạn tổng request 20 MB và ảnh inline base64 7 MB. Ngưỡng gửi ảnh dự kiến tối đa 4 MiB bytes gốc để còn chỗ cho base64 overhead; form hiện vẫn cho chọn ảnh đến 10 MiB nên giới hạn gửi AI chưa được triển khai.

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

Sau Task 4 Ngày 3 (26/09/2026, xác nhận hai lần trong ngày — phiên triển khai và phiên rà soát): `dart format` không đổi; `flutter analyze` toàn dự án — No issues found; `flutter test` — 33/33 đạt (8 widget + 5 model + 20 service); `flutter build web --release` thành công; `flutter build apk --debug` thành công. Không gọi Gemini thật; mọi test dùng fixture tổng hợp với fake sender. Thay đổi Task 4 chưa commit (2 file mới + worklog) theo yêu cầu chủ dự án.

Kiểm thử thiết bị thật Task 4 (26/09/2026, APK debug do phiên rà soát build): chủ dự án chạy 20 test case thủ công (`docs/MANUAL_TESTCASES_APK.md`), 18/20 PASS; app không khai báo quyền runtime nào (camera qua Intent hệ thống, ảnh qua Photo Picker — đúng thiết kế); ảnh 12 MB sau resize của picker còn dưới 10 MiB nên ngưỡng 10 MiB của form thực tế khó kích hoạt (chi tiết TC-3.6/TC-3.7). Trước đó, sau thay đổi Ngày 2, `dart format lib test`, `flutter analyze`, `flutter test`, `flutter build web --release` và `flutter build apk --debug` đã thành công; chủ dự án cung cấp ảnh chụp xác nhận photo picker/chọn ảnh trên Android thật (ảnh nguồn trên 10 MiB vẫn hiện preview sau xử lý, không hiện số byte trước/sau).

## Hạn chế đã biết và hướng tiếp theo

- Nhập mô tả/chụp/chọn ảnh và xem lại đầu vào đã có; service Gemini đã viết và pass unit test nhưng chưa nối UI, chưa gọi model thật, chưa có chỉnh sửa/xác nhận báo cáo hay lưu trữ.
- Firebase AI Logic đã được bật trong Console nhưng Flutter chưa gửi request; chỉ dùng dữ liệu tổng hợp khi tích hợp free tier.
- App Check: debug provider Android đã cấu hình và debug token đã đăng ký/verify khởi tạo trên thiết bị thật; cần xác nhận token được backend chấp nhận ở request Gemini đầu tiên (Task 6). Web debug provider chưa verify; provider production (Play Integrity/reCAPTCHA Enterprise) chưa cấu hình trước khi phân phối, không dùng debug token trong release.
- Tab Lịch sử luôn rỗng; chưa có lưu trữ cục bộ hoặc dữ liệu lịch sử.
- `GeminiReportService` có trong mã với 20 unit test, nhưng chưa được gọi bởi bất kỳ màn hình nào; chưa có dữ liệu draft thực từ Gemini.
- Form cho phép ảnh tới 10 MiB nhưng kiểm thử thiết bị thật cho thấy picker resize/nén ảnh trước khi trả về nên ngưỡng này thực tế khó kích hoạt; giới hạn gửi AI là 4 MiB và sẽ được kiểm tra tại service (Task 5 phải giữ nhánh chặn này).
- App không khai báo quyền runtime camera/ảnh: camera mở qua Intent hệ thống, ảnh qua Photo Picker (xác minh bằng merged manifest APK). Nhánh xử lý permission-denied trong mã giữ lại làm fallback.
- Lỗi `flutter analyze` thiếu `firebase_core` sau khi FlutterFire tạo `lib/firebase_options.dart` đã được xử lý ở Task 3; analyze toàn dự án hiện sạch. Kết quả cụ thể theo từng task trong `docs/AI_WORKLOG.md`.

Ưu tiên tiếp theo là Task 5 Ngày 3: nối `GeminiReportService` vào form/màn hình draft (CTA, loading/error/retry, nhãn "Bản nháp AI — cần kiểm tra, chưa lưu", giới hạn ảnh 4 MiB trước khi gửi), rồi Task 6 smoke test synthetic; sau đó là lưu/đọc lịch sử cục bộ (Ngày 4). Chỉ cân nhắc voice/GPS sau khi luồng cốt lõi chạy ổn.

## Tài liệu dự án

- `AGENTS.md` — hướng dẫn dành cho coding agent.
- `docs/CHALLENGE_VI_ROADMAP.md` — đề bài và roadmap sản phẩm.
- `docs/PROMPT_01.md` — prompt khởi tạo nền tảng Ngày 1.
- `docs/AI_WORKLOG.md` — nhật ký sử dụng và kiểm chứng AI.
- `docs/CONTEXT_SUMMARY.md` — tóm tắt trạng thái để bàn giao coding agent.
- `docs/WALKTHROUGH.md` — hướng dẫn chạy và kiểm tra giao diện hiện tại.
- `docs/MANUAL_TESTCASES_APK.md` — test case thủ công cho APK debug trên thiết bị thật.
- `docs/implement_plan_day3.md` — kế hoạch tích hợp Firebase AI Logic và trạng thái Task 1–4.
