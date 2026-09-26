# AI Worklog

## 2026-09-25 — Dựng nền tảng Ngày 1

### Công cụ và prompt

- **AI coding agent:** OpenCode, model gpt-6-luna.
- **Công cụ phát triển khác:** Flutter CLI tạo khung Android/Web; Dart/Flutter dùng để format, analyze, test và build.
- **Prompt chính:** `docs/PROMPT_01.md` — khởi tạo nền tảng Ngày 1, hai tab tiếng Việt, chưa tích hợp AI/camera/lưu trữ, cập nhật README và kiểm tra kết quả.

### AI hỗ trợ như thế nào

- Rà soát hướng dẫn và roadmap, xác nhận repo ban đầu chỉ có tài liệu và Flutter/Android tooling có sẵn.
- Hỗ trợ dựng giao diện Flutter cho hai tab, tên ứng dụng, test điều hướng, README và tài liệu cấu hình dự án.
- Rà soát những gì cần đưa vào GitHub, giữ lịch sử remote ban đầu và kiểm tra để không đưa build artifacts hoặc đường dẫn SDK cục bộ lên repo.

### Kết quả chưa chính xác và cách sửa

- Khi bổ sung kiểm thử viewport hẹp, test dùng `Size(320, 568)` nhưng thiếu import `dart:ui`; `flutter analyze` và `flutter test` báo không nhận diện `Size`. Đã thêm import, chạy lại format/analyze/test và cả ba đều thành công.
- Scaffold Android ban đầu có rule ignore Gradle wrapper. Nếu giữ nguyên khi commit, repo clone có thể thiếu wrapper cần cho build Android. Đã kiểm tra trạng thái Git, thêm rule cho phép commit `gradlew`, `gradlew.bat` và `gradle-wrapper.jar`, đồng thời tiếp tục loại `android/local.properties` khỏi Git.
- **AI trong sản phẩm:** chưa tích hợp model/API, nên chưa có kết quả phân tích sự cố nào để đánh giá là đúng hoặc sai. Chưa tạo ví dụ AI giả; cần ghi lại các kết quả thực tế và cách kiểm chứng sau khi tích hợp.

### Kiểm chứng đã chạy

- `dart format lib test` — hoàn tất.
- `flutter analyze` — không có vấn đề.
- `flutter test` — đạt; test chuyển tab trên viewport 320×568 không phát hiện lỗi render.
- `flutter build web --release` — build thành công.
- `flutter build apk --debug` — build thành công; lúc kiểm tra coding agent chưa có Android device để cài/chạy.
- **Bổ sung xác nhận của chủ dự án:** APK Ngày 1 đã được mở qua Android Studio và chạy trên điện thoại Android thật; hai ảnh đính kèm cho thấy hai tab. Coding agent không thể tự kiểm chứng thiết bị trong phiên do `flutter devices` không thấy Android device.

### Nếu có thêm 7 ngày

1. **Ngày 1–2:** Làm nhập mô tả, chọn/chụp ảnh, xem trước ảnh, kiểm tra nội dung rỗng/kích thước và xử lý quyền bị từ chối.
2. **Ngày 3:** Chọn dịch vụ AI và cách gọi an toàn qua backend/proxy; viết prompt có quy tắc không suy đoán và chốt schema báo cáo.
3. **Ngày 4:** Parse/validate phản hồi; xử lý JSON lỗi, trường thiếu, timeout, lỗi mạng; đánh dấu dữ liệu cần người dùng xác nhận.
4. **Ngày 5:** Làm màn hình sửa/xác nhận, lưu cục bộ và đọc lại lịch sử; không coi bản nháp AI là báo cáo đã xác nhận.
5. **Ngày 6:** Kiểm thử các tình huống rõ ràng, mơ hồ/thiếu địa điểm, ảnh không liên quan, mất mạng và dữ liệu sai schema; chạy trên thiết bị Android.
6. **Ngày 7:** Sửa lỗi, build APK, rà soát secret/quyền riêng tư, hoàn thiện README/worklog và chuẩn bị demo trung thực theo tính năng đã chạy.

Voice/GPS chỉ được cân nhắc sau khi luồng tạo → kiểm tra/chỉnh sửa → xác nhận → lưu → xem lịch sử hoạt động ổn định.

## 2026-09-25 — Ngày 2: nhập mô tả và ảnh

### Công cụ và yêu cầu

- **AI coding agent:** OpenCode, model gpt-6-luna.
- **Công cụ:** Flutter CLI; dependency `image_picker` 1.2.3 được thêm bằng `flutter pub add image_picker`.
- **Yêu cầu:** Thực hiện `docs/implement_plan_day2.md`, làm form nhập mô tả/ảnh, validation và preview; chưa tích hợp AI hoặc lưu trữ.

### AI hỗ trợ như thế nào

- Đọc roadmap và plan Ngày 2, triển khai `CreateReportScreen`, picker camera/gallery, preview cục bộ, validation và widget tests.
- Giữ picker dependency ở mức tối thiểu; không thêm `permission_handler`, permission storage rộng, AI service hoặc cơ sở dữ liệu.

### Kết quả chưa chính xác và cách sửa

- Test ban đầu dùng `find.text` cho mô tả xuất hiện ở cả `EditableText` lẫn preview; chuyển sang key riêng. Test CTA ở ngoài viewport được sửa bằng cách cuộn tới nút trước khi tap.
- Thử pre-decode bằng `ui.instantiateImageCodec` khiến widget test không hoàn tất; bỏ pre-decode đó. Thay vào đó kiểm tra kích thước/bytes/signature và dùng `Image.errorBuilder` làm fallback để không crash khi Flutter không render được ảnh; nhánh decoder-error chưa kiểm chứng trên thiết bị.
- APK build đầu tiên lỗi Kotlin incremental cache do source plugin ở ổ `C:` còn project ở ổ `D:`. Tham số `--android-project-arg=kotlin.incremental=false` xác nhận workaround; sau đó đặt `kotlin.incremental=false` trong `android/gradle.properties` để Android Studio/Flutter dùng chung fix. Build chuẩn thành công; tradeoff là Kotlin có thể biên dịch lâu hơn.
- AI chưa được tích hợp; chưa có đầu ra AI trong sản phẩm để đánh giá.

### Kiểm chứng Ngày 2

- `dart format lib test` — hoàn tất.
- `flutter analyze` — không có vấn đề.
- `flutter test --reporter expanded` — 8 tests đạt: điều hướng/màn hình hẹp, validation rỗng, xem lại mô tả/ảnh, camera/gallery source, hủy picker, permission error, ảnh quá lớn và ảnh không hợp lệ.
- `flutter build web --release` — thành công; có cảnh báo không blocking về Cupertino icon font và Wasm dry-run.
- `flutter build apk --debug` — sau khi đặt `kotlin.incremental=false` trong project config, build thành công. Gradle có cảnh báo non-blocking về restricted Java API.
- `flutter devices` ở agent chỉ thấy Windows, Chrome và Edge. Chủ dự án gửi hai ảnh từ điện thoại Android thật: một ảnh cuộn của form có mô tả và ảnh đã chọn; ảnh kia là system photo picker. Chủ dự án báo ảnh nguồn lớn hơn 10 MiB; ảnh chụp không cho biết dung lượng file sau resize/compress. Điều này xác nhận gallery selection/preview theo báo cáo chủ dự án, không xác nhận camera hoặc từ chối quyền.

## 2026-09-26 — Task 1 Ngày 3: chọn Gemini và backend (chưa tích hợp)

### Công cụ và yêu cầu

- **AI coding agent:** OpenCode, model gpt-6-luna.
- **Tra cứu:** web search/fetch tài liệu chính thức của Google AI for Developers, Google One, Google Cloud và Firebase; kiểm tra Git/repo và phiên bản CLI cục bộ.
- **Yêu cầu:** thực hiện preflight Task 1 trong `docs/implement_plan_day3.md`; không gọi API, tạo project, lưu credential hay deploy khi tài khoản/billing chưa được xác nhận.
- **Prompt/câu hỏi chính:** đối chiếu model Gemini hiện hành có nhận text+image và structured output, giá/data-use, phương án Cloud Run/Secret Manager/App Check; hỏi chủ dự án về hosting, billing, ngân sách và endpoint protection trước khi chốt.

### Kết quả và quyết định

- Chọn model **`gemini-3.8-flash`**: tài liệu model chính thức ghi stable, nhận Text/Image, hỗ trợ Structured outputs, context input 1,048,576 tokens và output 65,536 tokens; deprecations page chưa công bố ngày shutdown. Chọn vì hợp với phân tích mô tả/ảnh thành schema, không cần model tạo ảnh.
- Theo pricing page tại ngày tra cứu, paid tier hiện là USD 0.75/1M input tokens và USD 3.75/1M output tokens đến hết 2026-12-31; từ 2027-01-01 là USD 1.50/1M input và USD 7.50/1M output. Free tier đánh dấu dữ liệu có thể được dùng để cải thiện sản phẩm; paid tier đánh dấu không dùng cho mục đích đó. Chủ dự án đồng ý paid tier và **mục tiêu** USD 5/tháng cho Gemini API; đây không phải hard cap đã kiểm chứng.
- Chọn **Node.js service trên Cloud Run**, secret Gemini trong **Google Cloud Secret Manager**, và **Firebase App Check** xác minh token tại backend. App Check không phải đăng nhập và không thay thế quota/rate limit; Cloud Run có thể được gọi qua HTTPS nhưng request phải qua xác minh App Check.
- Giới hạn khởi đầu được ghi cho bước triển khai: một ảnh tối đa 10 MiB; timeout Gemini/Cloud Run/client lần lượt 45/60/65 giây; Cloud Run max instances ban đầu 1; đặt Gemini project quota thấp cho kiểm thử thủ công. Các quota thực tế và khả năng kiểm soát USD 5/tháng cần xác minh trong project trước request thật; không coi budget alert là hard cap.
- Chủ dự án đồng ý Cloud Run/App Check và hiện cho biết chỉ có Google AI Pro, chưa có GCP project/billing. Trang Google AI Pro benefits nêu USD 10/tháng Google Cloud credits qua Google Developer Program Premium khi membership đang hoạt động và liên kết Google Developer profile; chưa xác minh quyền lợi đã được kích hoạt/credit còn lại. Không mặc định Pro subscription bao gồm Gemini Developer API paid billing.
- Trước request thật/deploy: chủ dự án cần xác nhận Cloud project/credit/billing, Gemini API paid tier và quota; nếu không thể đặt giới hạn sử dụng phù hợp mục tiêu USD 5/tháng thì dừng và hỏi lại. Không yêu cầu/chứa API key.
- Môi trường: Node.js v24.19.0, npm 11.17.0, Firebase CLI 15.28.1, Google Cloud SDK 581.0.0. Chạy shim PowerShell `npm` bị execution policy chặn; các lệnh `.cmd` tương ứng cho npm/Firebase/gcloud trả phiên bản. Không truy vấn danh sách tài khoản đăng nhập.

### Nguồn chính thức đã tra cứu

- [Gemini 3.8 Flash model](https://ai.google.dev/gemini-api/docs/models/gemini-3.8-flash) và [model lifecycle/deprecations](https://ai.google.dev/gemini-api/docs/deprecations).
- [Structured outputs](https://ai.google.dev/gemini-api/docs/structured-output), [Gemini API pricing](https://ai.google.dev/gemini-api/docs/pricing), [API key security](https://ai.google.dev/gemini-api/docs/api-key), [available regions](https://ai.google.dev/gemini-api/docs/available-regions) (Việt Nam được liệt kê).
- [Google AI Pro benefits](https://support.google.com/googleone/answer/14534406?hl=en), gồm điều kiện liên kết Google Developer Program Premium và Cloud credits.
- [Cloud Run configuration](https://docs.cloud.google.com/run/docs/configuring) và [Cloud Run secrets](https://docs.cloud.google.com/run/docs/configuring/services/secrets).
- [Firebase App Check cho custom backend](https://firebase.google.com/docs/app-check/custom-resource-backend).

### Giới hạn kiểm chứng

- Đây là quyết định kỹ thuật dựa trên tài liệu và lựa chọn của chủ dự án; chưa có Gemini API request, chất lượng model chưa được benchmark với dữ liệu thử, chưa cấu hình billing/quota, chưa tạo Secret Manager entry, Firebase project, App Check hoặc Cloud Run service.
- Không chạy formatter, analyzer, test hay build trong Task 1. Không có đầu ra AI của sản phẩm để đánh giá đúng/sai.

> **Cập nhật sau đó trong cùng ngày:** lựa chọn Cloud Run/Secret Manager/paid-tier ở entry trên đã được chủ dự án thay bằng Firebase AI Logic trên Spark/free tier do chưa thêm được payment method. Xem kết quả hiện tại bên dưới; không dùng Cloud Run entry cũ làm kiến trúc đang chọn.

## 2026-09-26 — Thay phương án bằng Firebase AI Logic trên Spark

### Lý do và quyết định hiện tại

- Chủ dự án gặp lỗi khi thêm payment method cho Google Cloud và yêu cầu hướng khác. Sau khi đối chiếu tài liệu Firebase, phương án được chọn là **Firebase AI Logic + Gemini Developer API Free tier trên Spark**, model `gemini-3.8-flash`; không dựng Cloud Run và không tự quản lý Gemini API key trong Secret Manager.
- Firebase AI Logic có SDK Flutter, managed proxy giữ Gemini Developer API key server-side, hỗ trợ App Check, multimodal input và structured output. Firebase ghi `gemini-3.8-flash` không cần billing khi dùng Gemini Developer API; Spark không yêu cầu Cloud Billing/payment method.
- Firebase xếp `gemini-3.8-flash` vào stable nhưng short-term availability; cần kiểm tra lifecycle trước khi duy trì dài hạn và giữ model name có thể đổi.
- Free-tier input có thể được dùng để cải thiện sản phẩm Google; vì vậy chỉ gửi fixture/ảnh tổng hợp, không gửi dữ liệu hiện trường thật. Paid tier/budget USD 5/tháng không còn là lựa chọn hiện tại; nếu quay lại paid tier phải xác nhận billing/ngân sách mới.
- Firebase AI Logic docs nêu giới hạn tổng request 20 MB và ảnh inline base64 7 MB. Đặt giới hạn bytes ảnh gốc ban đầu 4 MiB để dành chỗ cho base64 overhead; form hiện tại vẫn cho phép ảnh đến 10 MiB nên phải kiểm tra/nén/giới hạn trước khi gửi.
- Firebase AI Logic có per-user rate limits mặc định và có thể cấu hình. App Check được enforcement trong setup mới, nhưng ảnh Console hiện tại cho thấy cả Android/Web đang `Unregistered`; chưa gọi Gemini cho tới khi app có debug provider/token hợp lệ.

### Trạng thái setup do chủ dự án báo

- Chủ dự án chạy `firebase.cmd login` (CLI báo đã đăng nhập), `dart pub global activate flutterfire_cli` và `dart pub global run flutterfire_cli:flutterfire configure`; chọn Android/Web cho Firebase project.
- CLI báo tạo `lib/firebase_options.dart`; Git sau đó thấy thêm `firebase.json`, `android/app/google-services.json`, `lib/firebase_options.dart`. Không đọc nội dung các file Firebase config và không sao chép key/token vào worklog.
- Ảnh Console cho thấy Gemini Developer API/Firebase AI Logic APIs enabled, AI monitoring enabled, Spark no-cost, hai app Android/Web có trong AI Logic nhưng App Check là `Unregistered`.
- Đây chưa chứng minh app đã gọi Gemini: `pubspec.yaml` vẫn chưa có Firebase dependencies và `lib/main.dart` chưa khởi tạo Firebase/AI Logic/App Check.

### Nguồn chính thức

- [Firebase AI Logic overview](https://firebase.google.com/docs/ai-logic) và [Get started for Flutter](https://firebase.google.com/docs/ai-logic/get-started).
- [Firebase AI Logic pricing/free-tier requirements](https://firebase.google.com/docs/ai-logic/pricing), [supported models](https://firebase.google.com/docs/ai-logic/models), [structured output](https://firebase.google.com/docs/ai-logic/generate-structured-output), [App Check](https://firebase.google.com/docs/ai-logic/app-check).
- [Firebase AI Logic quotas](https://firebase.google.com/docs/ai-logic/quotas), [input file requirements](https://firebase.google.com/docs/ai-logic/input-file-requirements), [Gemini API pricing and data-use](https://ai.google.dev/gemini-api/docs/pricing).

### Giới hạn kiểm chứng

- Chưa cài Firebase SDK dependencies vào app, chưa cấu hình App Check debug provider/token, chưa chọn model trong Dart và chưa gửi request Gemini. Chưa chạy format/analyze/test/build sau `flutterfire configure`.
- `AI monitoring` đã được bật trong Console; chưa kiểm tra dashboard hoặc có request/usage nào.

### Bổ sung Task 1 — quota Firebase AI Logic

- Chủ dự án lọc `Generate content requests` + `Dimension:region:asia` trong Firebase AI Logic API > Quotas & System Limits.
- Ảnh Console xác nhận quota `Generate content requests` được đặt **5 RPM** ở 10 vùng Asia (`asia-east1`, `asia-east2`, `asia-northeast1/2/3`, `asia-south1/2`, `asia-southeast1/2/3`). Các dòng `Bidi generate content requests` vẫn 100; app hiện không dùng Bidi/streaming.
- Đây là quota per-user/per-region của Firebase AI Logic API, áp dụng cho các app trong project; không thay thế các giới hạn riêng của Gemini Developer API free tier. Chưa có request Gemini để kiểm tra 429/usage, và chưa đổi các quota provider khác.
- Quyết định/preflight Task 1 được xem là hoàn tất: model/provider/Spark, đường proxy/App Check, giới hạn request, quota và free-tier data-use đã được chốt/ghi nhận. App Check SDK/debug provider và kiểm tra quota bằng request synthetic thuộc các task tích hợp sau; chưa có request, build hoặc test.

## 2026-09-26 — Task 2 Ngày 3: ReportDraft schema và prompt

### Công cụ và phạm vi

- **AI coding agent:** OpenCode, model gpt-6-luna.
- **Yêu cầu:** triển khai Task 2 trong `docs/implement_plan_day3.md`: tạo report model/parser, prompt và tests; chưa nối Firebase AI Logic hoặc gửi request model.
- **Prompt triển khai tóm tắt:** giữ schema bảy field của `AGENTS.md`; missing/empty values phải hiện rõ trong `needs_confirmation`; `priority` chỉ `low`/`medium`/`high`/`null`; `suggested_action` là đề xuất; summary chỉ nhắc dữ kiện người dùng nêu rõ; output JSON tiếng Việt.

### Kết quả và sửa lỗi

- Thêm `lib/models/report_draft.dart` với `ReportPriority`, strict type/enum parsing, serializer, defaults an toàn cho field thiếu và tự đưa field rỗng/null vào `needs_confirmation`; thiếu cả confirmation list thì yêu cầu review toàn bộ field.
- Thêm `lib/services/report_draft_prompt.dart`. Prompt chỉ là constant; chưa gửi tới Gemini.
- Thêm `test/report_draft_test.dart` với 5 tests cho parse/serialize hợp lệ, field thiếu/rỗng, thiếu confirmation list, JSON root sai, type sai và priority/confirmation không hợp lệ.
- Lần test đầu báo lỗi compile vì Dart final fields được gán trong constructor body. Đổi các field đó sang `late final`, format lại và chạy lại tests thành công.

### Kiểm chứng

- `dart format lib/models/report_draft.dart lib/services/report_draft_prompt.dart test/report_draft_test.dart` — hoàn tất.
- `flutter test test/report_draft_test.dart` — 5 tests đạt.
- `flutter test` — 13 tests đạt (5 model + 8 widget).
- `flutter analyze lib/models/report_draft.dart lib/services/report_draft_prompt.dart test/report_draft_test.dart` — không có vấn đề.
- `flutter analyze` toàn dự án — thất bại với 5 diagnostics từ `lib/firebase_options.dart`: không tìm thấy `package:firebase_core/firebase_core.dart` và symbol `FirebaseOptions`, do Firebase dependencies chưa được thêm. Khắc phục thuộc Task 3; không ẩn hoặc loại trừ file cấu hình.
- Không gọi Firebase/Gemini API, không có output model thật, không chạy build.

## 2026-09-26 — Task 3 Ngày 3: Firebase Core + App Check debug provider

### Công cụ và phạm vi

- **AI coding agent:** ZCode (model GLM); Flutter CLI; `adb logcat` để kiểm tra log thiết bị thật.
- **Yêu cầu:** thực hiện Task 3 trong `docs/implement_plan_day3.md`: thêm Firebase dependencies, khởi tạo Firebase, cấu hình App Check debug provider cho Android/Web; không gọi Gemini (thuộc Task 4), không tắt App Check.

### Đã làm

- `flutter pub add firebase_core firebase_ai firebase_app_check` → `firebase_core` 4.15.0, `firebase_ai` 4.0.0, `firebase_app_check` 0.4.8; `firebase_auth` 6.7.0 là dependency chuyển tiếp.
- `lib/main.dart`: chuyển `main()` sang async, thêm `WidgetsFlutterBinding.ensureInitialized()`, `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` và trong `kDebugMode` gọi `FirebaseAppCheck.instance.activate(providerAndroid: AndroidDebugProvider(), providerWeb: WebDebugProvider())`.
- Đối chiếu API trực tiếp với source `firebase_app_check` 0.4.8 trong pub cache: tham số enum cũ `androidProvider`/`webProvider` đã deprecated, dùng class provider mới `providerAndroid`/`providerWeb`. Không copy token hay nội dung file cấu hình Firebase vào worklog này.

### Kiểm chứng agent đã chạy

- `dart format lib/main.dart` — không đổi.
- `flutter analyze` toàn dự án — **No issues found**; 5 diagnostics cũ từ `lib/firebase_options.dart` đã hết sau khi thêm `firebase_core`.
- `flutter test` — 13/13 đạt (8 widget + 5 model).
- `flutter build web --release` — thành công; cảnh báo Cupertino icon font non-blocking, đã có từ Ngày 2.

### Kiểm chứng trên thiết bị thật (cùng chủ dự án)

- Chủ dự án chạy app debug trên điện thoại Android thật (adb không dây), lấy được App Check debug token và tự đăng ký token đó trong Firebase Console (App Check → Apps → Manage debug tokens). Giá trị token không ghi lại ở đây và không đưa vào source/Git.
- Agent kiểm tra log bằng `adb logcat` sau một lần cold start sạch: `FirebaseInitProvider: FirebaseApp initialization successful`; `DebugAppCheckProvider` hoạt động và in debug token của thiết bị (đã che khi xem); Flutter engine/Dart VM khởi động bình thường; không có error/exception từ Firebase, App Check hay Flutter; không có crash.

### Giới hạn kiểm chứng còn lại

- Token có được backend chấp nhận hay chưa chỉ quan sát được ở request backend đầu tiên (gọi Gemini ở Task 4/6); Console App Check chưa có metric vì app chưa gửi request nào. Nếu gặp 403/unregistered ở Task 4, quay lại kiểm tra đăng ký token thay vì tắt App Check.
- Web debug provider chưa chạy verify trên Chrome (tùy chọn); provider production (Play Integrity/reCAPTCHA Enterprise) để dành cho bước phát hành, không dùng debug token trong release.
- Chưa commit thay đổi Task 3 (`lib/main.dart`, `pubspec.yaml`, `pubspec.lock` cùng 2 file Gradle cấu hình google-services và 3 file Firebase config chưa theo dõi).

## 2026-09-26 — Task 4 Ngày 3: service gọi Gemini và validate (chưa smoke test thật)

### Công cụ và phạm vi

- **AI coding agent:** ZCode (model GLM); Flutter CLI.
- **Yêu cầu:** thực hiện Task 4 trong `docs/implement_plan_day3.md`: tạo service gọi Gemini qua Firebase AI Logic, trả về `ReportDraft` an toàn; chưa nối UI (Task 5), chưa smoke test thật (Task 6).
- **Chuẩn bị:** đối chiếu trực tiếp source `firebase_ai` 4.0.0 trong pub cache (factory `FirebaseAI.googleAI()`, `generativeModel()`, `GenerationConfig(responseMimeType, responseSchema)`, `Schema.object/enumString(nullable)`, `Content.multi/TextPart/InlineDataPart`, các class exception trong `error.dart`, getter `response.text`). Lưu ý API: App Check instance truyền vào `googleAI()` đã deprecated — SDK tự lấy từ app.

### Đã làm

- Thêm `lib/services/gemini_report_service.dart`:
  - Model `gemini-3.8-flash` (không dùng alias `-latest`), prompt tiếng Việt từ Task 2 đặt làm `systemInstruction`, `responseMimeType: 'application/json'` và `responseSchema` dựng bằng `Schema` với `priority` là `enumString(nullable: true)` — không cho model tự mặc định `medium`.
  - Seam `ReportDraftRequestSender` (interface mỏng) để unit test inject fake không cần Firebase/network; mặc định lazy tạo `GenerativeModel` từ `FirebaseAI.googleAI()` chỉ khi gửi request đầu tiên.
  - Hỗ trợ text-only/image-only/multimodal; chặn trước khi gửi: cả hai trống, ảnh rỗng, ảnh > 4 MiB bytes, loại ảnh không nhận diện được (dựa `XFile.mimeType` hoặc signature PNG/JPEG/GIF/BMP/WebP/HEIC).
  - Timeout client 60 giây qua `Future.timeout`; retry hoàn toàn do người dùng.
  - Ánh xạ lỗi: `TimeoutException` → timeout; `QuotaExceeded` → quota; `ServiceApiNotEnabled`/`InvalidApiKey`/`UnsupportedUserLocation`/`FirebaseAISdkException` → cấu hình; `FirebaseAIException` có message nhắc App Check → App Check; message "blocked" → phản hồi AI; còn lại (kể cả `ServerException`) → dịch vụ/mạng. Parse `response.text` qua `jsonDecode` + `ReportDraft.fromJson`; JSON sai/rỗng/root không phải object → lỗi phản hồi AI. Thông báo lỗi chỉ mang cấu trúc, không chứa prompt/ảnh/response.
- Thêm `test/gemini_report_service_test.dart` — 20 tests với fake sender: 4 biến thể đầu vào, MIME sniffing, 4 trường hợp chặn đầu vào, response rỗng/JSON sai/root sai, thiếu `needs_confirmation`, `priority` null, timeout (cả throw lẫn treo thật 50ms), quota, cấu hình, App Check, block, server error.

### Sửa lỗi AI trong lúc triển khai

- Dart 3.13 không chấp nhận `case final Type(subPattern):` (khai báo final với object pattern); sửa thành `case Type(field: final x) when ...:` và bỏ case `ServerException _` dư thừa (đã được `FirebaseAIException _` phủ vì là subtype).
- Thiếu import `image_picker` cho `XFile`; lint `prefer_initializing_formals` yêu cầu đổi constructor sang initializing formals.

### Kiểm chứng agent đã chạy

- `dart format` — hoàn tất; `flutter analyze` toàn dự án — không có vấn đề; `flutter test` — **33/33 đạt** (13 cũ + 20 service); `flutter build web --release` — thành công.
- Không gọi Gemini thật, không có response model thật; mọi test dùng fixture tổng hợp.

### Kiểm chứng độc lập lần 2 (cùng ngày, phiên rà soát — ZCode/model GLM)

- Một phiên agent khác rà lại Task 4 theo tiêu chí trong `docs/implement_plan_day3.md` và **chạy lại toàn bộ kiểm chứng**, kết quả trùng khớp: `flutter analyze` — No issues found (5,2s); `flutter test` — 33/33 đạt (8 widget + 5 model + 20 service, đếm tĩnh khớp tuyên bố trong worklog); `dart format --output=none --set-exit-if-changed lib test` — 0 file cần format; `flutter build web --release` — thành công (44s, cảnh báo non-blocking CupertinoIcons font + Wasm dry-run đã có từ Ngày 2); `flutter build apk --debug` — thành công (65,8s).
- Đối chiếu Git: `lib/services/gemini_report_service.dart` + `test/gemini_report_service_test.dart` untracked, `docs/AI_WORKLOG.md` modified — **Task 4 chưa commit theo yêu cầu của chủ dự án, giữ nguyên trạng thái**.
- Phát hiện mâu thuẫn tài liệu (đã xử lý ở mục Task 7 nội bộ phiên này): README/CONTEXT_SUMMARY/WALKTHROUGH vẫn ghi "chưa có service gọi Gemini" và "ưu tiên tiếp theo là Task 4" trong khi working tree đã có service; đồng thời ba file cấu hình Firebase (`lib/firebase_options.dart`, `android/app/google-services.json`, `firebase.json`) **đã được commit trong HEAD `5b495d6` (Task 3)** nhưng các tài liệu này vẫn ghi "chưa commit". Tài liệu đã được cập nhật lại trong phiên rà soát.

### Kiểm thử thiết bị thật do chủ dự án thực hiện (26/09/2026, APK debug)

- Chủ dự án cài `app-debug.apk` (bản build của phiên rà soát, copy sang `D:\Download\ai-field-assistant-debug.apk`) và chạy bộ test case thủ công `docs/MANUAL_TESTCASES_APK.md`: **18/20 PASS**.
- **TC-3.6 quyền:** Thông tin ứng dụng trên điện thoại hiển thị "không có quyền nào được yêu cầu" nhưng camera và chọn ảnh vẫn hoạt động. Xác minh bằng merged manifest của APK (`build/app/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml`): chỉ có `INTERNET`, `ACCESS_NETWORK_STATE`, `READ_GSERVICES`, không có `CAMERA`/`READ_MEDIA_*`. Kết luận: **đúng thiết kế** — `image_picker` mở camera qua Intent hệ thống (`ACTION_IMAGE_CAPTURE`) và ảnh qua Photo Picker của Android, app không cần quyền runtime; các nhánh xử lý permission-denied trong mã giữ lại làm fallback.
- **TC-3.7 giới hạn 10 MiB:** ảnh 12 MB được chọn thay thế **vẫn hiển thị preview, không có thông báo** — khác kỳ vọng. Nguyên nhân: picker gọi với `maxWidth/maxHeight: 1600, imageQuality: 85` nên ảnh gốc bị resize/nén trước khi trả về; file sau xử lý thường dưới 10 MiB nên nhánh chặn trong `_applySelectedImage` thực tế khó kích hoạt. Mã chặn vẫn đúng và giữ lại; Task 5 phải kiểm tra bytes trước khi gọi service (ngưỡng gửi 4 MiB) và không giả định resize của picker luôn đủ. Ghi nhận thêm vào mục Task 5 của `docs/implement_plan_day3.md`.
- 18 test case còn lại (khởi động, form, hủy picker, thay ảnh, xem lại đầu vào, điều hướng, giữ state giữa tab) đều đạt; chi tiết kỳ vọng/bước ở `docs/MANUAL_TESTCASES_APK.md`.

### Giới hạn kiểm chứng còn lại

- **Chưa có request Gemini thật:** chất lượng schema/prompt với model thực tế, và việc App Check token được backend chấp nhận, chỉ xác nhận được ở smoke test synthetic (Task 6). Cách ánh xạ lỗi App Check dựa trên đoán message của SDK — cần xác nhận bằng lỗi thật nếu gặp.
- `Future.timeout` không hủy request đang chạy phía SDK; hành vi khi thiết bị mất mạng giữa request cần xác nhận ở Task 5/6.
- Service chưa nối vào UI; chưa có loading/error state trên màn hình (Task 5).
