# AI Field Assistant

Ứng dụng Android-first dành trước hết cho nhân viên bảo trì tòa nhà ghi nhận sự cố điện, nước, điều hòa và thiết bị. Biểu mẫu dài làm gián đoạn công việc; báo cáo có thể thiếu ảnh/bối cảnh hoặc cách ghi không thống nhất. AI Field Assistant hướng tới chuyển mô tả/ảnh thành bản nháp có cấu trúc để nhân viên kiểm tra, chỉnh sửa và xác nhận trước khi lưu.

## Trạng thái hiện tại

Đã có hai khu vực điều hướng bằng tab tiếng Việt:

- **Tạo báo cáo:** nhập mô tả, chụp/chọn một ảnh, xem preview, xem lại đầu vào cục bộ và bấm **"Phân tích bằng AI"** để tạo bản nháp.
- **Lịch sử:** trạng thái rỗng cho báo cáo đã lưu trong tương lai.

Từ Ngày 3 Task 3, app khởi tạo Firebase và App Check debug provider (chế độ debug) khi mở. Từ Ngày 3 Task 4, có service gọi Gemini (`lib/services/gemini_report_service.dart`) với unit test đầy đủ. **Từ Ngày 3 Task 5, CTA "Phân tích bằng AI" đã nối thật với Gemini**: gửi mô tả/ảnh qua Firebase AI Logic, hiện loading/khóa nút khi chờ, xử lý lỗi giữ nguyên đầu vào, và mở màn hình **"Bản nháp AI — cần kiểm tra, chưa lưu"** hiển thị draft có `needs_confirmation` và nhãn hành động đề xuất. **Request Gemini thật đã chạy đầu-cuối trên thiết bị Android (27/09/2026).** Draft chỉ xem — chưa có chỉnh sửa/xác nhận/lưu. Chưa tích hợp lưu trữ, lịch sử có dữ liệu, voice-to-text, GPS, đăng nhập hoặc cloud; app không đảm bảo giữ đầu vào sau khi đóng.

## Kiến trúc hiện tại

```text
Flutter Material 3 app
└── lib/main.dart
    ├── AiFieldAssistantApp — theme và tên ứng dụng
    └── _HomeScreen — NavigationBar + IndexedStack
        ├── CreateReportScreen — mô tả, image picker, preview và CTA "Phân tích bằng AI"
        │   └── ReportDraftScreen — bản nháp AI chỉ xem (push khi có kết quả)
        └── _HistoryScreen — empty state
```

App shell ở `lib/main.dart` — `main()` async khởi tạo Firebase (`DefaultFirebaseOptions.currentPlatform`) và App Check debug provider trong `kDebugMode`. Form nằm trong `lib/screens/create_report_screen.dart`; màn bản nháp AI ở `lib/screens/report_draft_screen.dart`; widget thông báo ở `lib/widgets/status_notice.dart`. Schema/parser bản nháp ở `lib/models/report_draft.dart`, prompt ở `lib/services/report_draft_prompt.dart`; service gọi Gemini qua Firebase AI Logic ở `lib/services/gemini_report_service.dart` (đã nối UI từ Task 5). Widget tests ở `test/widget_test.dart`; model tests ở `test/report_draft_test.dart`; service tests ở `test/gemini_report_service_test.dart`.

## Luồng màn hình đã chốt

```text
Tạo báo cáo → Xem/chỉnh sửa bản nháp → Lịch sử → Chi tiết báo cáo
```

Đây là luồng sản phẩm đã thống nhất cho thiết kế. Hiện **Tạo báo cáo** cho nhập, xem lại đầu vào và tạo bản nháp AI thật; màn **"Bản nháp AI"** hiển thị draft chưa xác nhận (chỉ xem); **Lịch sử** vẫn rỗng. Chỉnh sửa/xác nhận draft, lưu và chi tiết chưa được dựng hay giả lập bằng dữ liệu mẫu.

## Quy trình AI — đã tích hợp ở mức draft (Task 5 Ngày 3)

Luồng đang chạy trong app:

```text
Mô tả/ảnh
  → CTA "Phân tích bằng AI" (người dùng chủ động bấm)
  → Firebase AI Logic SDK trong Flutter
  → Firebase-managed proxy + App Check
  → Gemini Developer API (chính `gemini-3.8-flash`; tự fallback `gemini-3.5-flash-lite` khi hết quota)
  → parse và kiểm tra JSON/schema
  → người dùng xem bản nháp AI chưa xác nhận/chưa lưu
  → (chưa có) sửa, xác nhận, lưu cục bộ, hiển thị trong Lịch sử
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

`created_at`, đường path ảnh và trạng thái báo cáo là metadata riêng, không phải trường nội dung cốt lõi. `ReportDraft` Dart model/parser và prompt đã được tạo và đã được nối vào `GeminiReportService` (Task 4 Ngày 3) với `responseSchema` ở phía SDK. Prompt yêu cầu summary chỉ tóm tắt dữ kiện người dùng nêu rõ. AI chỉ được phép tạo bản nháp, `suggested_action` không phải hành động đã thực hiện. Kiến trúc AI hiện tại: Firebase AI Logic trên Spark với Gemini Developer API, **model chính `gemini-3.8-flash` + fallback tự động `gemini-3.5-flash-lite`** khi gặp lỗi quota (chi tiết `docs/SESSION_2026-09-26_TASK5.md`); Firebase Core/App Check đã nối (Task 3); service + 27 service test (Task 4) đã nối UI (Task 5) và request Gemini thật đã chạy đầu-cuối trên thiết bị. Chưa có màn hình chỉnh sửa draft, lưu, lịch sử hoặc cơ sở dữ liệu.

## Quyết định kỹ thuật

- **Flutter/Dart:** ưu tiên một codebase Android-first phù hợp với prototype di động.
- **Web preview:** bật Web để xem giao diện trong môi trường chưa có Android device/emulator kết nối.
- **Material 3, `NavigationBar`, `IndexedStack`:** tạo điều hướng đơn giản, trạng thái chọn tab rõ ràng và chuyển màn hình không cần thư viện ngoài.
- **`image_picker` 1.2.3:** dùng system picker cho camera/thư viện; preview đọc bytes trong phiên hiện tại. Không thêm `permission_handler` hoặc quyền Android rộng trong bước này.
- Ảnh được yêu cầu resize tối đa 1600×1600, JPEG quality 85; kiểm tra file nhận được không quá 10 MiB. Đây là ngưỡng hiện tại của prototype.
- **AI đã tích hợp (Task 4–5):** Firebase AI Logic trên Spark, Gemini Developer API. **Model chính `gemini-3.8-flash` (free 20 req/ngày) + fallback tự động `gemini-3.5-flash-lite` (free 500 req/ngày) khi gặp lỗi quota** — chất lượng fallback thấp hơn nên draft có thể cần xác nhận nhiều hơn. Firebase-managed proxy giữ Gemini API key phía server; không có Cloud Run backend hoặc Secret Manager do dự án tự quản lý.
- Task 2 đã thêm `ReportDraft` schema/parser và prompt; Task 4 đã thêm service Firebase AI Logic với `responseSchema`, seam inject fake, chặn đầu vào (rỗng/ảnh > 4 MiB/loại lạ), timeout 60 giây và ánh xạ lỗi; **Task 5 đã nối CTA/loading/lỗi/retry/màn draft và chạy request Gemini thật đầu-cuối trên thiết bị Android (27/09/2026)**, kèm sửa bug ánh xạ lỗi App Check (`FirebaseException` plugin `firebase_app_check` → `ReportDraftAppCheckException`).
- **Firebase trong app (Task 3):** `firebase_core` 4.15.0, `firebase_ai` 4.0.0, `firebase_app_check` 0.4.8 (`firebase_auth` 6.7.0 là dependency chuyển tiếp). `main()` async khởi tạo Firebase và kích hoạt App Check debug provider trong `kDebugMode`; API `firebase_app_check` 0.4.8 dùng class provider mới (`providerAndroid`/`providerWeb`), tham số enum cũ đã deprecated.
- Firebase Console đã bật API, AI monitoring và đăng ký app Android/Web; FlutterFire tạo `lib/firebase_options.dart`. App Check debug token của thiết bị Android thử nghiệm đã được đăng ký trong Console và khởi tạo đã kiểm chứng sạch trên thiết bị thật; Web chưa verify và provider production (Play Integrity/reCAPTCHA Enterprise) chưa cấu hình nên trang Apps của Console vẫn có thể hiển thị `Unregistered`.
- Firebase AI Logic quota `Generate content requests` đã được đặt 5 RPM cho từng vùng Asia trong bảng quota (per-user/per-region). **Thứ chặn thực tế trong phiên Task 5 là quota ngày của Gemini Developer API free tier: `gemini-3.8-flash` 20 request/ngày (cạn khi test 27/09), `gemini-3.5-flash-lite` 500 request/ngày**; reset ~midnight Pacific (≈14:00–15:00 giờ VN); request 429 cũng bị đếm. Model fallback tự động là giải pháp hiện tại; dòng "Request limit per model per day" trong Cloud Console có thể Edit khi cần. Quota Bidi chưa đổi vì app không dùng streaming.
- Spark/free tier không cần thẻ hoặc Cloud Billing. Free-tier input có thể được dùng để cải thiện sản phẩm Google, nên chỉ thử bằng mô tả/ảnh tổng hợp, không dùng dữ liệu hiện trường thật. Paid tier và mục tiêu USD 5/tháng chưa áp dụng; việc bật billing sau này cần xác nhận riêng.
- Firebase AI Logic giới hạn tổng request 20 MB và ảnh inline base64 7 MB. Ngưỡng gửi ảnh là **4 MiB bytes gốc** để còn chỗ cho base64 overhead — được kiểm tra ở cả form (trước khi gọi service) và service; form vẫn cho chọn ảnh đến 10 MiB để xem lại cục bộ.

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

Kiểm thử thiết bị thật Task 4 (26/09/2026, APK debug do phiên rà soát build): chủ dự án chạy 20 test case thủ công (`docs/MANUAL_TESTCASES_APK.md`), 18/20 PASS; app không khai báo quyền runtime nào (camera qua Intent hệ thống, ảnh qua Photo Picker — đúng thiết kế); ảnh 12 MB sau resize của picker còn dưới 10 MiB nên ngưỡng 10 MiB của form thực tế khó kích hoạt (chi tiết TC-3.6/TC-3.7). Trước đó, sau thay đổi Ngày 2, `dart format lib test`, `flutter analyze`, `flutter test`, `flutter build web --release` và `flutter build apk --debug` đã thành công; chủ dự án cung cấp ảnh chụp xác nhận photo picker/chọn ảnh trên Android thật (ảnh nguồn trên 10 MiB vẫn hiện preview sau xử lý, không hiện số byte trước/sau).

## Hạn chế đã biết và hướng tiếp theo

- Nhập mô tả/chụp/chọn ảnh, xem lại đầu vào và **tạo bản nháp AI thật** đã có; màn "Bản nháp AI" chỉ xem — **chưa có chỉnh sửa/xác nhận draft, lưu trữ, lịch sử có dữ liệu**.
- Model fallback tự động: khi `gemini-3.8-flash` hết quota ngày (20), app dùng `gemini-3.5-flash-lite` (500/ngày) có chất lượng thấp hơn — draft có thể cần xác nhận nhiều hơn; demo quan trọng nên chạy khi model chính còn quota.
- App Check: debug token đã được backend chấp nhận ở request Gemini thật (27/09/2026). Cài đè/gỡ cài app có thể đổi token → 403 "App attestation failed" (app hiển thị đúng thông báo App Check); đăng ký lại token trong Console. Web debug provider chưa verify; provider production (Play Integrity/reCAPTCHA Enterprise) chưa cấu hình trước khi phân phối, không dùng debug token trong release.
- Tab Lịch sử luôn rỗng; chưa có lưu trữ cục bộ hoặc dữ liệu lịch sử.
- Form cho phép ảnh tới 10 MiB nhưng picker resize/nén trước khi trả về nên ngưỡng này thực tế khó kích hoạt; giới hạn gửi AI 4 MiB được kiểm tra ở cả form và service (Task 5).
- App không khai báo quyền runtime camera/ảnh: camera mở qua Intent hệ thống, ảnh qua Photo Picker (xác minh bằng merged manifest APK). Nhánh xử lý permission-denied trong mã giữ lại làm fallback.
- Kết quả cụ thể theo từng task trong `docs/AI_WORKLOG.md`; tổng kết phiên Task 5 và các sự cố vận hành ở `docs/SESSION_2026-09-26_TASK5.md`.

Task 6 kiểm tra tự động đã hoàn tất ngày 27/09/2026; Task 7 là lượt rà soát tài liệu/bàn giao. **Ưu tiên sản phẩm tiếp theo là Ngày 4:** cho phép người dùng chỉnh sửa và xác nhận draft, lưu báo cáo cục bộ rồi mở lại trong lịch sử. Chưa có kết quả theo từng dòng cho 31 test case Task 5; không suy ra PASS từng case từ xác nhận PASS tổng thể của chủ dự án. Chỉ cân nhắc voice/GPS sau khi luồng cốt lõi chạy ổn.

## Tài liệu dự án

- `AGENTS.md` — hướng dẫn dành cho coding agent.
- `docs/CHALLENGE_VI_ROADMAP.md` — đề bài và roadmap sản phẩm.
- `docs/PROMPT_01.md` — prompt khởi tạo nền tảng Ngày 1.
- `docs/AI_WORKLOG.md` — nhật ký sử dụng và kiểm chứng AI.
- `docs/CONTEXT_SUMMARY.md` — tóm tắt trạng thái để bàn giao coding agent.
- `docs/WALKTHROUGH.md` — hướng dẫn chạy và kiểm tra giao diện hiện tại.
- `docs/MANUAL_TESTCASES_APK.md` — test case thủ công cho APK debug trên thiết bị thật.
- `docs/MANUAL_TESTCASES_TASK5.md` — test case thủ công cho luồng AI (Task 5) trên thiết bị thật.
- `docs/SESSION_2026-09-26_TASK5.md` — tổng kết phiên Task 5: triển khai, sự cố App Check/quota, model fallback.
- `docs/implement_plan_day3.md` — kế hoạch tích hợp Firebase AI Logic và trạng thái Task 1–7.
