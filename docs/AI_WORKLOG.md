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

## 2026-09-26/27 — Task 5 Ngày 3: nối UI, request Gemini thật đầu tiên, fallback model

### Công cụ và phạm vi

- **AI coding agent:** ZCode (model GLM); Flutter CLI; `adb` (logcat, input, uiautomator dump) để lái UI điện thoại thật từ xa.
- **Yêu cầu:** thực hiện Task 5 trong `docs/implement_plan_day3.md`: CTA tạo draft, loading/lỗi/retry giữ input, màn "Bản nháp AI — cần kiểm tra, chưa lưu" với `needs_confirmation`; chưa lưu/xác nhận. Sau đó chẩn đoán 2 sự cố chủ dự án gặp khi test trên điện thoại và cập nhật docs.

### Đã làm (code)

- `lib/screens/report_draft_screen.dart` (mới): màn draft chỉ xem — tiêu đề "Bản nháp AI — cần kiểm tra, chưa lưu"; chỉ hiện trường có nội dung; `needs_confirmation` thành khối cảnh báo + badge "Cần xác nhận" từng trường; `suggested_action` kèm dòng "Đây là hành động đề xuất, chưa phải việc đã thực hiện."; hiển thị đầu vào gốc; không có nút lưu/sửa.
- `lib/widgets/status_notice.dart` (mới): thông báo dùng chung, trích từ `_StatusNotice` cục bộ.
- `lib/screens/create_report_screen.dart`: CTA "Phân tích bằng AI" — chặn input rỗng, chặn ảnh > 4 MiB trước gọi service (`maxImageBytesForAi` public); loading + khóa 4 nút; lỗi giữ mô tả + ảnh, retry bấm lại; helper text + khối thông báo ghi rõ dữ liệu gửi tới Gemini.
- `lib/main.dart`: seam `reportService` qua app widget cho test.
- `lib/services/gemini_report_service.dart`: log chẩn đoán debug-only tại điểm bắt lỗi (`ReportDraft request failed: …`, không log prompt/ảnh); fix ánh xạ lỗi App Check; model fallback (chi tiết bên dưới); seam `senderFactory(String)` thay `modelFactory`.
- Tests: widget_test.dart +8 (luồng AI, `_FakeReportService` extend service override `createReportDraft`); gemini_report_service_test.dart +4 (FirebaseException App Check thật + 3 fallback) → tổng **45/45**.

### Sự cố 1 — "Không thể phân tích lúc này" dù có mạng (đã fix)

- **Tái hiện:** agent build APK có log chẩn đoán, cài qua adb, lái UI (`input tap/text`), bắt logcat: `ReportDraft request failed: [firebase_app_check/unknown] Error returned from API. code: 403 body: App attestation failed.` kèm `DebugAppCheckProvider: Failed to exchange debug token (4ce5d93c-…)`.
- **Nguyên nhân:** (a) App Check debug token của lần cài hiện tại chưa đăng ký trong Console (cài đè/gỡ cài có thể đổi token); (b) bug ánh xạ: exception là `FirebaseException` của plugin `firebase_app_check` (không phải `FirebaseAIException`), message chứa `app_check`/`App attestation` nhưng `_mentionsAppCheck` cũ chỉ tìm `appcheck`/`app check` → rơi vào nhánh lỗi mạng, gây hiểu nhầm.
- **Fix:** `_mapError` thêm case `FirebaseException(plugin/message)` → `ReportDraftAppCheckException`; `_mentionsAppCheck` nhận nullable, normalize cả `-`/`_`, nhận diện "app attestation". Chủ dự án đăng ký token trong Console; xác minh sau fix: lỗi hiển thị đúng thông báo App Check; khi token hợp lệ request đi được.
- **Bài học:** "điện thoại có internet" không loại trừ lỗi phía Firebase; log chẩn đoán debug-only là công cụ quyết định — giữ lại vĩnh viễn.

### Sự cố 2 — "Đã đạt giới hạn số lần phân tích" (quota, đã xử lý bằng fallback)

- **Tái hiện:** bấm Phân tích nhiều lần → thông báo quota (ánh xạ đúng lỗi 429 thật). Log một lần thành công giữa các lần chờ xác nhận request thật đi được đầu-cuối (màn "Bản nháp AI" mở, draft trả đủ 6 trường rỗng + needs_confirmation cho mô tả vô nghĩa "Mayg" — AI không bịa dữ kiện).
- **Bằng chứng Console (screenshot chủ dự án):** quota chặn là **"Request limit per model per day for a project in the free tier" — `gemini-3.8-flash`, limit 20, usage 24 (100%)**; các dòng RPM vùng Asia đều Unlimited. Kết luận: chặn thực tế là **quota ngày theo model** của Gemini Developer API free tier, không phải RPM Firebase AI Logic đã hạ ở Task 1; request 429 cũng bị đếm usage; không thể sửa từ mã.
- **Giải pháp — model fallback tự động:** chính `gemini-3.8-flash` (chất lượng tốt nhất, 20/ngày); gặp quota → tự thử `gemini-3.5-flash-lite` (500/ngày) trong cùng lần bấm; lỗi không phải quota (blocked/App Check/500/timeout) không fallback; fallback cũng 429 → báo quota. Log debug từng bước. Mỗi model một `_GenerativeModelSender` tạo lười; seam `senderFactory`.
- **Xác minh trên thiết bị (log 27/09 04:24):** `limit: 20, model: gemini-3.8-flash` → `trying fallback (gemini-3.5-flash-lite)` → màn draft mở với response thật từ lite model.
- **Trade-off ghi nhận:** fallback chất lượng thấp hơn (draft có badge cần xác nhận nhiều hơn); demo quan trọng nên chạy khi 3.8-flash còn quota (reset midnight Pacific ≈ 14:00–15:00 giờ VN) hoặc chủ dự án Edit quota "Request limit per model per day" trong Console (Adjustable: Yes).

### Kiểm chứng agent đã chạy

- `dart format lib test` — sạch; `flutter analyze` — No issues; `flutter test` — **45/45 đạt** (13 widget + 5 model + 27 service); `flutter build web --release` + `flutter build apk --debug` thành công (lặp lại nhiều lần trong phiên sau mỗi fix).
- **Request Gemini thật đầu-cuối trên thiết bị Android (2026-09-26/27, agent tự lái qua adb):** nhập mô tả → Phân tích → màn "Bản nháp AI" mở. Case mô tả rõ ("Máy lạnh ở khu vực lễ tân không hoạt động"): draft Sự cố/Địa điểm/Hành động đề xuất đúng, priority null + needs_confirmation (không tự mặc định). Case mô tả mơ hồ/ vô nghĩa: 6 trường rỗng + needs_confirmation toàn bộ, không bịa. Back về form giữ input. Đây là bằng chứng "backend chấp nhận App Check token" mà Task 3/4 để dành — **một phần tiêu chí Task 6 đã có bằng chứng thật**.
- Chủ dự án xác nhận riêng: cùng ảnh đầu vào, `gemini-3.8-flash` nhận đúng sự cố/danh mục/hành động đề xuất, `gemini-3.5-flash-lite` kém hơn rõ — cơ sở chọn fallback thay vì đổi hẳn model.

### Sửa lỗi AI trong lúc triển khai

- `FirebaseException.message` nullable — `_mentionsAppCheck` phải nhận `String?`.
- `GenerativeModel` là final class — không mock implements được; đổi seam sang `senderFactory(String)` trả `ReportDraftRequestSender`.
- `_FakeReportService` ban đầu `implements GeminiReportService` lỗi vì private member — đổi sang `extends`.
- Widget test sau push route: form nguồn offstage — kiểm tra giữ input phải trước khi bấm hoặc sau pageBack.
- `responseText` final không gán được trong catch của fallback — đổi khai báo biến.
- `Candidate`/`GenerateContentResponse` constructor positional 5/2 tham số (đối chiếu source firebase_ai 4.0.0 trong pub cache).
- Lưu ý adb: `input text` không gõ dấu cách — dùng `%s`; logcat buffer điện thoại test 256 KiB trôi nhanh — cần streaming.

### Giới hạn kiểm chứng còn lại

- Chưa chạy đủ 31 test case trong `docs/MANUAL_TESTCASES_TASK5.md`; case gián đoạn giữa loading (tab/xoay/Home) mới ghi hành vi thật, chưa chốt chuẩn.
- Chất lượng prompt với 3.8-flash trên đầu vào ảnh thật: chỉ có nhận định chủ dự án (tốt hơn lite rõ rệt), chưa có bộ benchmark.
- Chưa commit Task 5 (code + docs) theo yêu cầu chủ dự án; Web debug provider và provider production vẫn như Task 3.

## 2026-09-27 — Task 6: kiểm thử tự động và xác nhận bằng chứng E2E

### Xác nhận phạm vi và bằng chứng Task 5

- Chủ dự án xác nhận Task 5 đã được kiểm thử thủ công và PASS. Không có bảng kết quả theo từng TC, model/Android version hoặc số request được cung cấp; vì vậy đây là xác nhận tổng thể của chủ dự án, không tự điền PASS cho từng hàng trong `docs/MANUAL_TESTCASES_TASK5.md`.
- Đối chiếu mã hiện tại với bằng chứng lịch sử trong mục Task 5 phía trên: UI gọi `GeminiReportService`; tài liệu ghi request Gemini thật trên Android với App Check hợp lệ, input mô tả rõ và mơ hồ, giữ input khi Back, và fallback sau quota. Task 5 cũng ghi `flutter test` 45/45 cùng `flutter analyze` sạch.
- Khi khảo sát thiết bị hiện tại, app đã cài trên Android 16 (model PKG110), đang chạy nền và form còn một ảnh đã chọn không rõ nội dung. Không gửi lại ảnh đó, không xóa trạng thái trong app và không tạo request Gemini mới. Smoke test E2E dùng input tổng hợp đã có bằng chứng ngày 26–27/09 ở phần Task 5; không coi đó là request vừa chạy hôm nay.

### Kiểm tra vừa chạy trong phiên này

- `dart format --output=none --set-exit-if-changed lib test` — exit 0; 11 file được kiểm tra, 0 file cần format.
- `flutter analyze` — No issues found (5,0 giây).
- `flutter test` — **45/45 đạt**: 5 model, 27 service, 13 widget. Bao gồm parse/validate schema, giới hạn ảnh/input, lỗi timeout/quota/App Check, fallback model và UI loading/lỗi/retry.
- `adb devices -l` — ban đầu không có thiết bị trong phiên ADB mới; sau đó thiết bị Android 16 đã tự xuất hiện qua kết nối ADB Wi‑Fi. Đã mở app xem UI tree, không đọc/chia sẻ token hoặc gửi request; app foreground ban đầu được khôi phục, UI dump tạm do phiên tạo đã xóa, AVD phụ đã tắt.
- Không chạy build trong Task 6 vì không nằm trong bước kiểm chứng của Task 6 và không có sửa mã. Không gửi request mới; quota hiện tại không được truy vấn từ Firebase Console. Không bật billing.
- Thử `dart format lib test` ở chế độ ghi bị auto-review từ chối do lệnh có thể sửa tệp trong bối cảnh trước đó yêu cầu chỉ khảo sát; dry-run read-only đã xác nhận không có thay đổi định dạng. Git vẫn được kiểm tra sau các lệnh.
- Git trước khi cập nhật worklog đang sạch tại `c440da4`; sau Task 6 chỉ các tài liệu ghi nhận/plan được sửa, không sửa mã nguồn hay cấu hình.

### Kết luận Task 6

- Kiểm tra tự động hiện tại đạt. Tiêu chí có ít nhất một request E2E synthetic với App Check hợp lệ được đáp ứng bằng bằng chứng Android thật đã ghi trong Task 5; lời xác nhận của chủ dự án củng cố kết quả kiểm thử thủ công Task 5.
- Không có benchmark chất lượng model, test Web/App Check production, quota hiện thời hoặc bảng PASS theo từng TC trong hồ sơ. Các giới hạn này vẫn cần giữ rõ trong README/worklog; không suy diễn từ 45 unit/widget/service tests.

## 2026-09-27 — Task 7: rà tài liệu và bàn giao Ngày 3

### Phạm vi và đối chiếu

- Rà `README.md`, `docs/CONTEXT_SUMMARY.md`, `docs/WALKTHROUGH.md`, `docs/implement_plan_day3.md` cùng worklog hiện có; đối chiếu với trạng thái mã nguồn và bằng chứng Task 5–6 đã ghi. Kiểm tra Git trước cập nhật: nhánh `task/day3-firebase-ai-logic`, working tree sạch, HEAD `b7155fd` đồng bộ với `origin`.
- Không sửa code/config, không chạy build/test và không gửi request Gemini trong Task 7.

### Tài liệu đã đồng bộ

- Cập nhật ưu tiên tiếp theo sang Day 4; phân biệt Task 6 kiểm thử đã hoàn tất và Task 7 rà soát/bàn giao tài liệu.
- Làm rõ Firebase AI Logic trên Spark là kiến trúc hiện tại; Cloud Run/Secret Manager là phương án cũ, không phải dịch vụ đang chạy.
- Ghi rõ mô tả/ảnh được gửi tới Gemini khi người dùng chủ động bấm CTA; draft chưa được xác nhận/lưu thành báo cáo.
- Giữ kết quả 45/45, analyze và format dưới dạng lịch sử Task 6; request Gemini thật và fallback là bằng chứng Task 5. Không gán PASS riêng cho các test case thủ công khi bảng chi tiết chưa được điền.
- Nêu lại giới hạn: quota hiện tại chưa truy vấn, Web debug/production App Check chưa xác minh, lưu trữ/lịch sử/voice/GPS chưa triển khai; chỉ dùng dữ liệu tổng hợp trên free tier.

### Kết quả và giới hạn

- Đây là lượt cập nhật tài liệu; không xác minh lại trạng thái Firebase Console hoặc chạy kiểm thử phần mềm.
- Thay đổi Task 7 chưa được commit/push; chủ dự án sẽ tự thực hiện.

## 2026-09-27 — Ngày 4 Task 1: preflight và chốt hợp đồng lưu cục bộ

### Công cụ, yêu cầu và phạm vi

- **AI coding agent:** Codex; PowerShell/Git, Flutter/Dart CLI, adb và tra cứu tài liệu maintainer trên pub.dev.
- **Prompt chính:** chủ dự án yêu cầu “bắt đầu thực hiện task 1 day 4”, theo `docs/implement_plan_day4.md`; chỉ preflight/chốt contract và quyết định storage, chưa thực hiện Task 2–8.
- Git đầu phiên: nhánh `task/day3-firebase-ai-logic`, HEAD `d4e6cc1`; `docs/implement_plan_day4.md` untracked từ phiên lập kế hoạch, không có thay đổi tracked. Giữ nguyên file và không stage/commit/push/reset/checkout/stash.

### Quyết định đã chốt

- Tách `ReportDraft` (AI), `ReportReview` (giá trị đang sửa + pending/confirmedValue/confirmedAbsent) và `Report` immutable đã xác nhận. Review tất cả field; issue bắt buộc, field trống tùy chọn cần xác nhận riêng. Sửa dữ kiện hủy xác nhận summary; xác nhận ngữ nghĩa vẫn do người dùng.
- SQLite schema v1 lưu sáu field, ID, thời gian UTC, trạng thái confirmed, mô tả gốc, photo path tương đối và JSON danh sách field xác nhận không có thông tin. SQL mới là hợp đồng, chưa execute.
- Repository tối thiểu save/list/findById/close; snapshot có ID/thời gian ổn định, retry không replace/ghi đè record; copy ảnh vào application support trước commit, cleanup chỉ khi biết rollback và không xóa ảnh của record đã commit. DB/filesystem không có chung transaction.
- Chọn Android persistence, Web preview với capability thông báo không hỗ trợ lưu; không thêm Web database/RAM fallback. Test repository dự kiến SQLite thật qua FFI với root tạm inject, còn plugin/restart kiểm chứng Android.
- Bộ phiên bản chốt theo dry-run: `sqflite 2.4.4`, `path_provider 2.1.6`, `path 1.9.1`; dev-only `sqflite_common_ffi 2.4.3`. Đợi Task 3 sử dụng mới thêm vào app; không tạo dependency chưa được dùng trong Task 1.
- Nguồn đã đọc: [sqflite](https://pub.dev/packages/sqflite/versions/2.4.4), [path_provider](https://pub.dev/packages/path_provider/versions/2.1.6), [path](https://pub.dev/packages/path/versions/1.9.1), [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi/versions/2.4.3); đối chiếu source pubspec/Android Gradle của package đã tải trong Pub Cache và Flutter SDK.

### Kiểm tra thực sự đã chạy

- `flutter --version`: Flutter 3.47.1 stable; `dart --version`: Dart 3.13.1.
- `flutter doctor -v`: Android SDK 36.0.0, Android Studio Java runtime 25.0.2; cảnh báo Android license status unknown và thiếu Visual Studio Desktop C++ workload. Không chấp nhận licenses hoặc cài toolchain trong phiên này.
- `flutter devices`/`adb devices -l`: thấy PKG110 Android 16/API 36 qua Wi-Fi, cùng Windows/Chrome/Edge; `adb version`: 1.0.41, platform-tools 37.0.1. Chỉ kiểm tra inventory, không mở app hoặc đọc log/token.
- `flutter pub add --help`: xác nhận hỗ trợ dry-run; `flutter pub add --dry-run 'sqflite:^2.4.4' 'path_provider:^2.1.6' 'path:^1.9.1' 'dev:sqflite_common_ffi:^2.4.3'`: exit 0, “Would change 33 dependencies”, FFI resolve `sqlite3 3.5.2`. Không sửa pubspec/lockfile; đã kiểm tra bằng Git diff.
- Yêu cầu SDK/config từ source package phù hợp Flutter 3.47.1/Dart 3.13.1, AGP 9.1.0, target Java 17 và minSdk Flutter 24. Resolver/config compatibility không thay bằng chứng build plugin hoặc FFI runtime.

### Lỗi thao tác và cách xử lý

- Lệnh Flutter ban đầu trong sandbox không trả output; adb và đọc file package vừa tải bị Access denied. Dừng session treo do task tạo, chạy lại các kiểm tra cần thiết ngoài sandbox sau automatic approval, thành công. Không dừng/xóa process hoặc dữ liệu của người dùng.
- Đường dẫn tra cứu pub.dev dạng `/versions/<version>/versions` không mở được; dùng trang version của maintainer và source package cục bộ để đối chiếu. Không dùng lỗi tra cứu để kết luận package thiếu hỗ trợ.

### Kết quả và giới hạn

- Cập nhật kế hoạch Ngày 4, README và context; chỉ tài liệu, không sửa mã/config/dependency. Task 1 hoàn tất preflight/hợp đồng; Task 2–8 chưa triển khai.
- Không chạy format/analyze/test/build/Gemini hoặc truy vấn Firebase Console/quota. Kết quả test/build Ngày 3 vẫn là lịch sử, không phải kết quả phiên này.
- SQLite FFI 2.4.x dùng sqlite3 v3/native hooks; runtime DLL/toolchain cần xác minh ở Task 3. Nếu bị chặn thì ghi blocker hoặc test repository thực trên Android, không tự coi fake là database test.
- Android licenses cần xử lý nếu build báo chặn; thiết bị nhìn thấy không chứng minh app/persistence chạy được. Bước tiếp theo là Task 2: model/validation review.

## 2026-09-27 — Rà cuối Task 1 Ngày 4 trước commit

- **Yêu cầu của chủ dự án:** kiểm tra Task 1 đã hoàn tất, sau đó tạo nhánh Ngày 4, commit và push. Công cụ: Codex, PowerShell/Git.
- Đối chiếu đủ bảy việc của Task 1 với kết quả A–E trong kế hoạch: preflight, phân tách draft/review/report, schema v1, ID/timestamp/ảnh, API repository, dependency và test storage thực, factory Android/Web đều có quyết định và bằng chứng phù hợp phạm vi.
- Kết luận Task 1 hoàn tất ở mức preflight/hợp đồng; Task 2–8 chưa triển khai. Native build/FFI runtime và Android licenses chưa xác minh hoàn toàn, không chuyển các giới hạn này thành tuyên bố đã có persistence.
- Kiểm tra Git diff: chỉ README, context, worklog và kế hoạch Ngày 4; không có thay đổi mã/test/config/pubspec/lockfile. `git diff --check` đạt; kế hoạch có 8 task, code fences cân bằng, không có trailing whitespace. Rà mẫu credential trong bốn tài liệu không có kết quả; đây không phải audit toàn bộ lịch sử Git.
- Không chạy lại format/analyze/test/build hoặc request Gemini trong lượt rà tài liệu. Preflight SDK/device/pub resolver vẫn là kết quả của phiên Task 1 trước đó.

## 2026-09-27 — Ngày 4 Task 2: model báo cáo và review state

### Công cụ, yêu cầu và phạm vi

- **AI coding agent:** Codex; PowerShell, Dart formatter, Flutter analyzer và test runner.
- **Yêu cầu chính:** triển khai Task 2 theo `docs/implement_plan_day4.md`, giữ `ReportDraft` là draft AI, tạo model báo cáo đã xác nhận và review state; chưa nối nút lưu/UI.
- Kiểm tra Git trước sửa: nhánh `codex/day4-preflight`, working tree sạch ở `846cf96`. Không stage/commit/push.
- Chỉ làm Task 2. Không thêm dependency, database/repository, UI, request Gemini hoặc build APK.

### Đã triển khai

- Tách `ReportPriority` dùng chung sang `lib/models/report_priority.dart`; `report_draft.dart` re-export enum để giữ cách import hiện có.
- Thêm `Report` immutable trong `lib/models/report.dart`: ID base64url 22 ký tự từ 16 byte ngẫu nhiên bảo mật, timestamp UTC, status confirmed, sáu field, mô tả gốc, photo path nullable và field đã được xác nhận vắng mặt. Ràng buộc kiểm tra issue không rỗng, photo path tương đối dưới `report_photos/` và danh sách absent khớp chính xác các field tùy chọn rỗng/null. JSON strict giữ timestamp milliseconds, Unicode và priority null; schema lỗi ném `FormatException`.
- Thêm `ReportReview` trong `lib/models/report_review.dart`: mọi field bắt đầu pending bất kể cờ AI; giữ `aiNeedsReview` riêng; chỉ cho xác nhận vắng mặt với field tùy chọn rỗng/null; sửa giá trị đưa field về pending và hủy xác nhận summary; summary chỉ được xác nhận sau các field khác. Chỉ tạo `Report` khi toàn bộ field đã review hợp lệ.
- Thêm `test/report_test.dart` và `test/report_review_test.dart`; kiểm tra serialization, trạng thái review, xác nhận trống, sửa dữ kiện, summary và điều kiện issue.

### Kiểm chứng thực sự đã chạy

- `dart format` trên sáu file Dart liên quan — exit 0; lần chạy rà cuối báo 0 file cần format. SDK phát cảnh báo không đọc được cấu hình `flutter_lints` trong Pub Cache do giới hạn sandbox; formatter vẫn hoàn tất.
- `flutter analyze` — **No issues found!**
- `flutter test` — **67/67 đạt** (toàn bộ test suite, gồm test model/review mới).
- Do sandbox chặn đọc Pub Cache và ghi lockfile cache của Flutter SDK, analyze/test được gọi qua `flutter_tools.snapshot` với quyền chạy đã được duyệt; không chỉnh sửa cache hoặc cấu hình dự án.
- Không chạy `flutter build apk`, không cài/mở app trên thiết bị và không gửi request Gemini. Test service AI dùng seam/fake như trước; không phải kiểm chứng AI E2E mới.

### Kết quả và giới hạn

- Task 2 hoàn tất ở mức model/validation và test. Task 3 (SQLite/ảnh), Task 4 (editor/lưu UI), lịch sử và chi tiết vẫn chưa triển khai.
- Dependency SQLite vẫn chỉ là kết quả dry-run của Task 1; chưa thêm vào pubspec/lockfile. Build native và FFI runtime chưa được xác minh.
- Một fixture test ban đầu không đúng với quy tắc constructor tự đánh dấu field rỗng; fixture đã được sửa theo contract, sau đó test liên quan và toàn bộ suite đều đạt. Không có request hoặc dữ liệu hiện trường thật được dùng.

## 2026-09-27 — Ngày 4 Task 3: repository SQLite và ảnh bền vững

### Công cụ, yêu cầu và phạm vi

- **AI coding agent:** Codex; PowerShell, Dart formatter, Flutter analyzer/test runner và Git.
- **Yêu cầu:** triển khai Task 3 theo `docs/implement_plan_day4.md`: SQLite repository Android, sao chép ảnh bền vững, retry an toàn và kiểm thử repository bằng SQLite thật. Chưa nối editor/lưu/lịch sử vào UI; không gọi Gemini.
- Git trước khi làm: nhánh `codex/day4-preflight`, working tree sạch tại `155c223`. Không stage/commit/push/reset/checkout/stash.

### Đã triển khai

- Thêm `lib/repositories/report_repository.dart`: contract `save/listReports/findById/readPhotoBytes/close`, lỗi storage typed và thông báo không đưa raw path/payload ra UI.
- Thêm factory conditional import: Android tạo `LocalReportRepository`; Web và nền tảng khác trả `UnsupportedReportRepository`, không có lưu RAM giả.
- Thêm `lib/repositories/local_report_repository.dart`: schema SQLite v1 trong application support; serialize report với JSON `confirmed_absent_fields`; query theo `created_at DESC, id DESC`; đọc/deserialize chặt và chuyển lỗi DB/ảnh thành lỗi storage.
- Ảnh được ghi vào staging trong thư mục app rồi đổi tên thành file do app đặt dưới `report_photos/`; DB chỉ lưu path tương đối. Retry cùng ID chỉ trả bản ghi hiện có khi các field/timestamp và bytes ảnh khớp; nội dung khác bị conflict. Cleanup chỉ xóa file do attempt này tạo khi xác định bản ghi chưa commit; kết quả transaction chưa rõ thì giữ file.
- Thêm dependency `sqflite 2.4.4`, `path_provider 2.1.6`, `path 1.9.1`, dev dependency `sqflite_common_ffi 2.4.3`.
- Thêm `test/local_report_repository_test.dart` với SQLite FFI thật trong thư mục tạm: round-trip, reopen, ảnh, sort/tie-break, retry/conflict, missing/unsafe photo, lỗi ghi ảnh/DB, cleanup và dữ liệu JSON hỏng.
- Cập nhật README, context summary, walkthrough, kế hoạch Ngày 4 và worklog để nêu rõ repository đã có nhưng UI chưa kết nối.

### Kiểm chứng vừa chạy

- `dart format lib/repositories test/local_report_repository_test.dart` — lần đầu format 3 file trong 6 file; lần rà cuối 0 file cần thay đổi.
- `flutter analyze` — No issues found.
- `flutter test test/local_report_repository_test.dart` — 10/10 đạt trên SQLite FFI thật.
- `flutter test` — 77/77 đạt.
- `flutter build apk --debug` — thành công, APK tại `build/app/outputs/flutter-apk/app-debug.apk`; Gradle cảnh báo Firebase plugins hiện áp dụng Kotlin Gradle Plugin và Java restricted native access.
- `flutter build web --release` — thành công; có cảnh báo không blocking về Cupertino icon font và Wasm dry-run.
- Flutter CLI ban đầu không trả output trong sandbox khi chạy `pub add`/`--version`; các lệnh dependency, format, analyze và test sau đó chạy thành công với quyền ngoài sandbox. Không sửa cấu hình hệ thống/cache.
- Test cleanup ban đầu dùng hai SQLite connection mở đồng thời trong fixture; đã điều chỉnh fixture đóng repository trước khi tạo trigger, test cô lập và toàn suite sau đó đạt. Không sửa DB ứng dụng người dùng.
- Không cài/mở APK trên thiết bị Android, không gửi Gemini request và không kiểm chứng persistence qua `sqflite`/`path_provider` trên Android. Không dùng dữ liệu hiện trường thật.

### Kết quả và giới hạn

- Task 3 hoàn tất ở mức repository Android + test host. Task 4 editor/lưu UI, Task 5 lịch sử và các task sau chưa triển khai. Người dùng chưa thể lưu báo cáo từ app; tab Lịch sử vẫn rỗng.
- APK/Web build đã xác minh compile thành công, nhưng chưa kiểm chứng persistence qua app restart trên Android. SQLite FFI Windows không thay thế kiểm chứng plugin Android; việc này vẫn cần trong bước tích hợp thiết bị Task 7.
- Filesystem và DB không chung transaction. Nếu process dừng giữa ghi ảnh và insert, có thể để lại file mồ côi; chưa có job quét/dọn file mồ côi.

## 2026-09-27 — Tạo APK debug và test case thiết bị

### Yêu cầu và phạm vi

- **AI coding agent:** Codex; PowerShell và Flutter CLI.
- **Yêu cầu:** tạo APK debug trên ổ D: và viết test case cho kiểm tra trực tiếp trên Android thật cũng như khi điện thoại nối ADB với máy tính.
- Trước khi làm, Git có các thay đổi Task 3 chưa commit (README/docs/pubspec và repository/test mới). Giữ nguyên; không stage/commit/reset/checkout/stash. Chỉ thêm `docs/MANUAL_TESTCASES_APK_DEBUG.md`; `build/` được Git ignore.

### Kiểm chứng trong phiên

- Lần đầu `flutter build apk --debug` chạy hơn 5 phút nhưng không xuất log/tiến độ và chưa cập nhật output. Dừng riêng tiến trình build do phiên này khởi chạy, sau đó chạy lại cùng lệnh với quyền truy cập Flutter/Gradle cache.
- Lần chạy lại **thành công**: `flutter build apk --debug`; Flutter báo `Built build\app\outputs\flutter-apk\app-debug.apk`. APK: 178,509,770 bytes; SHA-256 `F571DCAEDD34CFCE5CC1489455BE79D1D489E6B2E096E074D5FF96A399EC66DC`; package `com.example.ai_field_assistant`; version theo pubspec `0.1.0+1`.
- Gradle phát cảnh báo restricted Java native access và Firebase plugins hiện áp dụng Kotlin Gradle Plugin, có thể không tương thích các phiên bản Flutter tương lai. Build vẫn exit 0.
- Thêm `docs/MANUAL_TESTCASES_APK_DEBUG.md`: test cài/mở, form/picker/camera, gọi AI có điều kiện mạng/App Check/quota, lỗi mạng, vòng đời app và các lệnh ADB an toàn. Kết quả từng test để trống đến khi người dùng chạy trên thiết bị.

### Chưa kiểm chứng

- Không cài hoặc mở APK trên điện thoại; không chạy `adb devices`, `adb install`, `flutter analyze` hay `flutter test` trong phiên này.
- Không gửi request Gemini; quota/App Check hiện tại và SQLite/path_provider trên runtime Android chưa được kiểm tra. Build APK chỉ xác nhận compile Android thành công.
- Không dùng dữ liệu hiện trường thật và không đọc/ghi App Check token.

## 2026-09-28 — Kiểm tra ADB cho APK debug

### Yêu cầu và phạm vi

- **AI coding agent:** Codex; PowerShell, Flutter CLI và Android Platform Tools.
- **Yêu cầu:** chủ dự án báo PHONE-01–PHONE-13 đã PASS trên máy thật và yêu cầu tiếp tục phần B của `docs/MANUAL_TESTCASES_APK_DEBUG.md`.
- Git đầu phiên còn các thay đổi Task 3 chưa commit và test case APK chưa theo dõi. Giữ nguyên thay đổi đó; cập nhật kết quả test case và worklog. Không stage/commit/reset/checkout/stash.

### Thực hiện và bằng chứng

- `adb` không có trong `PATH`; SDK tại `C:\Users\khanh\AppData\Local\Android\Sdk` bị sandbox từ chối đọc. Sau khi được phép truy cập, Android Platform Tools `1.0.41` phát hiện đúng một thiết bị ADB không dây ở trạng thái `device` (không lưu serial vào tài liệu).
- APK không còn ở output path đầu phiên nên chạy lại `flutter build apk --debug` với quyền truy cập SDK/Gradle. Build exit 0; Gradle có cảnh báo Java restricted native access và KGP của Firebase plugins. APK mới 178,509,770 bytes, SHA-256 `F571DCAEDD34CFCE5CC1489455BE79D1D489E6B2E096E074D5FF96A399EC66DC`.
- **ADB-01 PASS:** `adb install -r` trả `Success`. Một lần thử `adb -d` không thấy thiết bị vì kết nối là không dây; đã chọn serial duy nhất lấy từ `adb devices -l` rồi cài thành công. Không gỡ app hoặc xóa dữ liệu.
- **ADB-02 PASS:** package `com.example.ai_field_assistant`, versionName `0.1.0`, versionCode `1`, minSdk `24`, targetSdk `36`; thiết bị model `PKG110`, Android `16`, API `36`. Force-stop/monkey mở lại app; process tồn tại và `.MainActivity` ở foreground.
- **ADB-03 PARTIAL:** qua ADB xác minh input rỗng bị chặn, Lịch sử hiển thị empty state và mô tả tổng hợp còn nguyên sau khi chuyển tab. Không chạy lặp picker/camera/giới hạn ảnh/mất mạng và không gửi các request AI trong lượt này; các PHONE case tương ứng là kết quả chủ dự án báo PASS, chưa có bằng chứng riêng.
- **ADB-04 PASS:** sau cold start và UI checks, crash buffer không có `FATAL EXCEPTION` khớp package; app còn foreground. Không clear log.
- **ADB-05 PASS:** chuỗi tổng hợp `ADB_TEST_LOSS_0928` hiện trong trường mô tả trước force-stop; sau force-stop/mở lại field còn trên form nhưng rỗng và process chạy. Chỉ input chưa lưu bị mất như thiết kế hiện tại.
- **ADB-06 PASS:** ghi model/API, package/version, APK hash, kết quả và số request AI bằng 0; không lưu serial/token. Các XML hierarchy tạm ở `/data/local/tmp` do test tạo đã được xóa sau khi đọc; không đọc/ghi nội dung cá nhân.
- Ghi PHONE-01–PHONE-13 là PASS theo xác nhận của chủ dự án ngày 28/09; không ghi như kết quả Codex tự quan sát.

### Giới hạn còn lại

- ADB-03 chưa chạy hết PHONE-02–PHONE-11 trong lúc nối ADB; phần AI được bỏ qua để tránh gọi lại và tiêu quota không cần thiết. Bộ test ghi trạng thái PARTIAL, không nâng thành PASS.
- Không gửi request Gemini; không kiểm tra mạng/App Check/quota hiện tại.
- APK hiện có repository SQLite trong source nhưng chưa nối vào UI. Cài/mở APK không chứng minh `sqflite`/`path_provider` chạy trên Android, và chưa thể tạo/đọc report qua giao diện. Đây vẫn là phần kiểm chứng storage Android còn thiếu; test FFI host trong Task 3 là bằng chứng riêng.
- Không chạy `flutter analyze` hoặc `flutter test` trong lượt này; chỉ build APK và test ADB nêu trên.

## 2026-09-28 — Ngày 4 Task 4: editor, review và lưu báo cáo

### Yêu cầu và phạm vi

- **AI coding agent:** Codex; PowerShell, Dart/Flutter CLI.
- **Yêu cầu:** triển khai Day 4 Task 4 theo `docs/implement_plan_day4.md`: editor/review draft, xác nhận người dùng trước lưu, gọi repository đã có, giữ dữ liệu khi lỗi và xử lý Back.
- Chỉ làm trong checkout hiện tại; không stage/commit/push và không build APK/chạy thiết bị hay gửi Gemini request.

### Thực hiện

- Chuyển `ReportDraftScreen` từ màn chỉ xem thành editor cho sáu trường. Review người dùng được tách khỏi `needs_confirmation` của AI; field tùy chọn có thể xác nhận chưa có thông tin; `issue` phải có nội dung; sau khi dữ kiện đổi cần review lại `summary`.
- Thêm xác nhận lưu, khóa thao tác trong lúc save, retry cùng `Report` ID, xử lý kết quả lưu không chắc chắn bằng `findById`, cảnh báo Back khi review đã đổi, và chỉ xóa form nguồn sau save thành công. Inject repository từ app shell vào form/editor; nếu lưu xong, báo thành công và nêu rõ tab Lịch sử chưa hiển thị báo cáo.
- `_analyzeWithAi` khóa thao tác trước điểm async và bắt lỗi đọc kích thước ảnh trong ranh giới xử lý lỗi, giữ đầu vào khi thất bại.
- Bổ sung widget tests với fake repository cho save thành công, nội dung/ảnh và optional absence, `issue` rỗng, lỗi/retry cùng ID, kết quả mơ hồ, Back, double-tap và viewport hẹp/bàn phím. Các lượt kiểm tra đầu phát hiện expectation cũ của empty state, test chưa review `summary`, thao tác Back khi bàn phím còn mở và control tràn trên viewport hẹp; cập nhật test/layout trước khi chạy toàn suite.
- Cập nhật README, context summary, walkthrough, kế hoạch Ngày 4 và ghi chú phạm vi của manual test APK cũ để không hiểu nhầm chúng là kết quả kiểm chứng Task 4.

### Kiểm chứng vừa chạy trong phiên

- `dart format lib/main.dart lib/screens/create_report_screen.dart lib/screens/report_draft_screen.dart test/widget_test.dart` — hoàn tất, exit 0.
- `flutter analyze` — **No issues found!**
- `flutter test` — **85/85 đạt** (`+85: All tests passed!`). Lưu qua UI được test bằng fake repository; SQLite FFI thật trên Windows 10/10 là bằng chứng Task 3, không chạy lại trong Task 4.
- Không chạy `flutter build apk --debug`, `flutter build web --release`, ADB/device test hoặc request Gemini trong phiên này. APK/ADB được ghi ở entry trước là trước thay đổi Task 4; plugin SQLite/path_provider và persistence trên Android vẫn chưa kiểm chứng.

### Giới hạn còn lại

- Tab Lịch sử chưa truy vấn repository và màn chi tiết chưa triển khai; điều hướng/refresh sau lưu phụ thuộc Task 5–6.
- Cần Task 7 build/cài phiên bản source mới, xác minh `sqflite`/`path_provider`, save thật, đọc lại ảnh/báo cáo sau force-stop/mở lại và ghi kết quả từng test case. Không suy ra persistence Android từ widget tests hoặc SQLite FFI host test.

## 2026-09-28 — Task 4: build và cài APK qua Wireless debugging

- **Yêu cầu:** build APK Task 4 mới và cài lên điện thoại Android đang kết nối Wireless debugging để chủ dự án tự chạy các manual test case.
- **Môi trường/cách chọn thiết bị:** `adb` không có trong `PATH`; dùng Android SDK Platform Tools tại `C:\Users\khanh\AppData\Local\Android\Sdk\platform-tools\adb.exe`. ADB báo một thiết bị online; serial có dạng mDNS Wireless debugging. Không ghi serial hoặc thông tin ghép đôi vào worklog.
- **Build:** `flutter build apk --debug` — exit 0, tạo `build\app\outputs\flutter-apk\app-debug.apk`. Gradle có cảnh báo restricted Java native access và các Firebase plugins đang dùng Kotlin Gradle Plugin; build vẫn thành công. APK 178,580,797 bytes, SHA-256 `0821D28C488C77B9C3EB2419A47F835341C3320452E00BC7EFC6D4F3FA5686F8`.
- **Cài/mở:** `adb install -r` trả `Success` (cài đè, không gỡ app hoặc xóa dữ liệu); mở bằng `adb shell monkey -p com.example.ai_field_assistant 1`; xác nhận process chạy và activity foreground. Không đọc logcat, không gửi Gemini request và không thao tác editor/save thay chủ dự án.
- Cập nhật `docs/testcase_task4_day4.txt`: ADB-D4-01, ADB-D4-03, ADB-D4-04 được đánh dấu PASS theo bằng chứng vừa quan sát; các UI/editor/save/persistence case còn lại chưa chạy. APK mở được không xác minh plugin SQLite hoặc dữ liệu đọc lại sau restart.
- `flutter analyze` và `flutter test` không chạy lại trong lượt build/cài; bằng chứng 85/85 và analyzer sạch thuộc lượt triển khai Task 4 trước đó. Build APK không thay thế Task 7 test lưu/đọc Android đầu-cuối.

## 2026-09-29 — ADB kiểm thử Task 4 qua Wireless debugging

- **Yêu cầu:** chạy các test case Wireless debugging trong `docs/testcase_task4_day4.txt`; giữ nguyên dữ liệu app và không thay chủ dự án lưu report.
- **Môi trường:** Android SDK `adb.exe` dùng trực tiếp từ `C:\Users\khanh\AppData\Local\Android\Sdk\platform-tools\adb.exe` vì không có trong `PATH`. Xác nhận một thiết bị Wireless mDNS online; model PKG110, Android 16/API 36. Không ghi serial, IP hoặc thông tin ghép đôi.
- **APK:** file debug có sẵn, 178,580,797 bytes, SHA-256 `0821D28C488C77B9C3EB2419A47F835341C3320452E00BC7EFC6D4F3FA5686F8`; hash/size đối chiếu được với build lịch sử. Cài đè bằng `adb install -r`, rồi mở app bằng `monkey`; process và foreground được xác nhận. `flutter build apk --debug` không chạy lại trong lượt này.
- **Case vừa kiểm chứng:** ADB-D4-01–06 PASS: kết nối một thiết bị, môi trường, APK/cài đặt, launch, validation input rỗng và một lần Gemini draft thành công (editor mở, dấu hiệu mô tả gốc còn hiển thị). ADB-D4-09 chỉ PASS giới hạn: 1.500 dòng logcat gần nhất không có match `FATAL EXCEPTION` hoặc nhóm lỗi SQLite/plugin; đây không phải xác minh save.
- **Chưa chạy:** ADB-D4-07–08, 10–11. Lượt nhập thử đầu bị app rời form khi ẩn bàn phím; sau khi mở lại, nhập lại dữ liệu tổng hợp và gửi đúng một request, editor draft mở. Không review/save/force-stop/ngắt kết nối. Wireless debugging vẫn được giữ kết nối, draft tổng hợp đang mở để chủ dự án tiếp tục kiểm tra.
- **Kết quả cập nhật:** testcase ghi PASS/NOT RUN theo từng ADB case, giữ lại ghi chú của lần thử đầu trong ngày khi chưa có thiết bị; README và worklog trỏ tới đúng tên `.txt`. Không chạy Flutter test/analyze/build trong lượt kiểm thử ADB này.
## 2026-09-29 — Chốt Task 4 và kiểm tra trước khi xuất bản

- **Phạm vi:** hoàn tất Day 4 Task 4; cập nhật code editor/review/save, test, README/context/walkthrough/plan và test case theo trạng thái thực tế. Chủ dự án xác nhận PHONE-D4-01–14 PASS trên thiết bị thật.
- **Kiểm tra vừa chạy:** `dart format --set-exit-if-changed lib/main.dart lib/screens/create_report_screen.dart lib/screens/report_draft_screen.dart test/widget_test.dart` — exit 0, 0 file đổi; `flutter analyze` — No issues found; `flutter test` — **85/85 đạt**.
- **ADB và giới hạn:** ADB-D4-01–06 PASS, ADB-D4-09 là lọc log giới hạn; một request Gemini tổng hợp mở draft. ADB-D4-07–08, 10–11 chưa chạy; không lưu qua ADB, force-stop hoặc ngắt kết nối. Đọc lại report/ảnh từ SQLite Android sau restart chưa được xác minh độc lập. Không chạy APK/Web build trong lượt chốt này; APK hiện tại là artifact đã build ngày 28/09 và cài lại ngày 29/09.
- **Bàn giao:** Task 4 được chốt. Task 5 (Lịch sử), Task 6 (chi tiết) và Task 7 (kiểm chứng persistence Android đầu-cuối) còn lại. Không đưa credential/token/serial vào tài liệu.

## 2026-09-29 — Ngày 4 Task 5: nối màn Lịch sử với repository

- **Yêu cầu/prompt:** triển khai phần tiếp theo theo kế hoạch Task 5 Ngày 4: dùng chung repository, hiển thị loading/empty/error/retry, refresh khi mở tab và sau save, chuyển report ID khi chọn dòng; giữ các thay đổi có sẵn.
- **Công cụ:** Codex hỗ trợ đọc và sửa mã/tài liệu; Dart formatter, Flutter analyzer và Flutter test dùng để kiểm tra. Không gọi Gemini trong lượt này.
- **Thay đổi:** thêm `HistoryScreen` với danh sách, ngày giờ địa phương, priority, địa điểm, nhãn đã xác nhận, pull-to-refresh và xử lý nền tảng không hỗ trợ. `main.dart` dùng repository chung, kích hoạt refresh khi vào tab/sau save và nhận ID dòng được chọn. `CreateReportScreen` phát callback sau khi save thành công. Thêm 5 widget tests; cập nhật test điều hướng và tài liệu. Tap dòng hiện thông báo rõ màn chi tiết được bổ sung ở Task 6; chưa có màn chi tiết.
- **Vấn đề gặp và cách xử lý:** test ban đầu cần xác nhận field priority khi fixture để null; cập nhật fixture theo hợp đồng model. Expectation cũ của test điều hướng còn tìm placeholder nên chuyển sang empty-state key mới. Widget test không settle khi tab ẩn vẫn chạy spinner; màn chưa mở không khởi động tải/animation nền. Viewport 320×568 phát hiện tràn ở empty state; chuyển nội dung sang vùng cuộn. Analyzer báo import không dùng; đã bỏ import đó.

### Kiểm chứng vừa chạy trong phiên

- `dart format --output=none --set-exit-if-changed lib/main.dart lib/screens/create_report_screen.dart lib/screens/history_screen.dart test/history_screen_test.dart test/widget_test.dart` — exit 0; 5 file, 0 thay đổi.
- `flutter analyze` — **No issues found!**
- `flutter test test/history_screen_test.dart` — **5/5 đạt**; kiểm tra widget điều hướng/viewport 320×568 — đạt.
- `flutter test --reporter compact` — **90/90 đạt** (`+90: All tests passed!`).
- Không chạy APK/Web build, ADB/device test, request Gemini hoặc runtime SQLite/path_provider trên Android. Widget tests dùng fake repository; không chứng minh persistence trên thiết bị.

### Còn lại

- Task 6 vẫn cần màn chi tiết đọc report theo ID từ repository; hiện tap chỉ phát ID rồi thông báo placeholder.
- Task 7 cần build/cài bản source mới, kiểm tra SQLite/path_provider, lưu/đọc report và ảnh sau force-stop/mở lại trên Android. Các bằng chứng build/APK/ADB cũ thuộc Task 3–4 và không được chạy lại ở Task 5.

## 2026-09-29 — Soạn test case thủ công cho Ngày 4 Task 5

- **Yêu cầu:** chuẩn bị test case cho các chức năng Lịch sử, chạy trực tiếp trên điện thoại Android thật và quan sát qua ADB Wireless debugging.
- **Tài liệu tạo:** `docs/testcase_task5_history_day4.txt`, gồm 9 PHONE cases và 6 ADB cases cho tải/rỗng/danh sách/thứ tự/refresh/sau save/giữ form/chọn dòng/lỗi retry, cùng hướng dẫn build APK, cài đè an toàn và thu thập log đã lọc.
- Tất cả case trong tài liệu được ghi `NOT RUN`. Không build/cài APK, kết nối thiết bị, chạy manual test hoặc thay đổi dữ liệu Android trong lượt soạn này. Kết quả automated 90/90 ở entry phía trên không được dùng làm PASS cho các case điện thoại/ADB.

## 2026-09-29 — Kiểm thử ADB Wireless cho màn Lịch sử Task 5

- **Yêu cầu:** chủ dự án báo đã PASS toàn bộ phần kiểm thử trực tiếp trên Android thật và yêu cầu Codex chạy toàn bộ phần ADB Wireless debugging trong `docs/testcase_task5_history_day4.txt`.
- **Thiết bị/kết nối:** Android thật PKG110, Android 16/API 36; `adb devices -l` có một thiết bị trạng thái `device` với serial mDNS Wireless debugging, `flutter devices --machine` nhận một Android device. Không ghi serial/IP/pairing code.
- **Build/cài:** `flutter build apk --debug` exit 0; APK 178,592,675 bytes, SHA-256 `62A896D0F98EDFD19CBBA01016A67A347A393B02046EBF51ADC339E6B0C3B41`; versionName `0.1.0`, versionCode `1`. `adb install -r` trả `Success`; các report đã có vẫn hiển thị sau cài đè. Có cảnh báo Gradle về Java restricted access và Kotlin Gradle Plugin compatibility; build vẫn thành công.
- **Source:** HEAD `18ca30808b20bde8926138d0ad2eb9803f66edd9` cùng các thay đổi working tree Task 5 chưa commit; không stage/commit. Giữ nguyên các thay đổi có sẵn và file bị xóa/chưa theo dõi.
- **ADB-D4-HIS-01–05 PASS:** xác nhận kết nối không dây và Flutter nhận thiết bị; cài APK; mở bằng `monkey`, xác minh PID/foreground; mở Lịch sử có dữ liệu, pull-to-refresh không crash; tap dòng hiện snackbar placeholder Task 6; mô tả tổng hợp chưa lưu được giữ sau khi đổi tab. Tạo một draft tổng hợp bằng đúng một Gemini request, xem/xác nhận các trường, xác nhận lưu; sau khi quay lại Lịch sử, report mới ở đầu danh sách mà không restart app. Process/foreground vẫn hoạt động.
- **ADB-D4-HIS-06 BLOCKED:** không gặp lỗi đọc tự nhiên; không làm hỏng/xóa database để tạo điều kiện thử retry. Không đọc DB riêng tư hoặc kiểm tra lưu sau force-stop/restart (thuộc Task 7).
- **Log:** xem 1.200 dòng gần nhất bằng `adb logcat -d -t 1200` và bộ lọc đã nêu trong test case; có 0 match `FATAL EXCEPTION` và 0 match nhóm SQLite/plugin. Không chạy `adb logcat -c`; đây chỉ là kiểm tra log giới hạn.
- **Tác động dữ liệu/giới hạn:** một báo cáo tổng hợp mới được lưu vào app để kiểm tra luồng save → history và vẫn để lại trên thiết bị; không xóa dữ liệu. Android keyboard tự sửa một phần mô tả tổng hợp khi nhập. Không dùng screenshot/log thô trong tài liệu. Không chạy Flutter test/analyze trong lượt kiểm thử này.
- **Kết quả test case:** cập nhật riêng từng dòng PHONE/ADB trong `docs/testcase_task5_history_day4.txt`. PHONE-D4-HIS-01–09 là trạng thái người dùng báo PASS, không phải kết quả Codex tái kiểm tra; ADB-D4-HIS-01–05 PASS, ADB-D4-HIS-06 BLOCKED.

## 2026-09-29 — Ngày 4 Task 6: chi tiết báo cáo đã lưu

- **Yêu cầu/prompt:** triển khai Task 6 theo roadmap, rà lại như senior, sửa thông báo cũ “Lịch sử chưa hiển thị báo cáo ở bước này” và báo cáo chi tiết. Không đụng các thay đổi có trước; không commit/push.
- **Công cụ:** Codex đọc/sửa mã và tài liệu; Dart formatter, Flutter analyzer/test, Android Gradle build. Không gọi Gemini/Firebase AI Logic; APK build chỉ là kiểm tra compile, không phải runtime network test.
- **Thay đổi mã:** thêm `ReportDetailScreen`, đọc report bằng `ReportRepository.findById(reportId)`, đọc ảnh bằng `readPhotoBytes`; hiển thị field đã xác nhận, trạng thái/thời gian, mô tả gốc và ảnh. Có loading, lỗi/retry, not-found, nhãn cho field đã xác nhận là không có, ghi rõ `suggested_action` là đề xuất, fallback/retry ảnh khi thiếu/lỗi/bytes hỏng, và Back về History. `main.dart` chuyển ID từ History qua route với cùng repository. Thông báo sau lưu giờ hướng người dùng mở tab Lịch sử. Thêm 9 widget tests cho nội dung, trạng thái bất đồng bộ/lỗi, ảnh và điều hướng; cập nhật assertion snackbar. Không thêm edit/delete/share/PDF.
- **Vấn đề gặp và cách xử lý:** widget tests ban đầu tìm phần tử nằm ngoài vùng `ListView` lazy chưa được build; cập nhật helper test cuộn đến phần tử trước khi assert. Đây là điều chỉnh cách kiểm tra viewport, không phải thay đổi logic sản phẩm. Rà race async: kết quả report/ảnh cũ bị bỏ qua khi ID/repository đổi; lỗi retry report không làm mất một lần đọc ảnh đang chạy.
- **Tài liệu:** cập nhật `README.md`, `docs/CONTEXT_SUMMARY.md`, `docs/WALKTHROUGH.md` và `docs/implement_plan_day4.md` để đánh dấu Task 6, ghi rõ fake repository/build provenance và giữ Task 7 Android persistence ở trạng thái chưa xác minh.

### Kiểm chứng vừa chạy trong phiên

- `dart format lib/main.dart lib/screens/create_report_screen.dart lib/screens/report_detail_screen.dart test/report_detail_screen_test.dart test/widget_test.dart` — exit 0; 5 file xem xét, formatter thay đổi 1 file (`test/widget_test.dart`).
- `flutter analyze` — **No issues found**.
- `flutter test --reporter compact` — **99/99 đạt**. 9 test mới cho detail dùng fake repository; các tests không chứng minh SQLite/path_provider trên Android hoặc request AI thật.
- `flutter build apk --debug` — exit 0, tạo `build/app/outputs/flutter-apk/app-debug.apk`. Build phát cảnh báo Java restricted native access và các plugin Firebase dùng Kotlin Gradle Plugin cần theo dõi chuyển sang Built-in Kotlin ở Flutter tương lai; hiện build thành công.
- Không cài/chạy APK qua ADB, không thử trên thiết bị/emulator, không kiểm tra force-stop/restart, không gọi Gemini. Vì vậy Task 7 persistence Android sau restart vẫn chưa hoàn thành.
- Không stage/commit/push. Giữ nguyên deletion có sẵn docs/PROMPT_01.md.

## 2026-09-29 — Soạn test case thủ công cho Ngày 4 Task 6

- **Yêu cầu:** viết test case để kiểm tra chức năng chính của màn chi tiết trên điện thoại Android thật và qua ADB Wireless debugging.
- **Tài liệu tạo:** `docs/testcase_task6_detail_day4.txt`, gồm 10 PHONE cases và 6 ADB cases. Bao gồm fixture report có ảnh/text-only/null và field xác nhận không có; điều hướng History → detail → Back; field/mô tả gốc/thời gian/ảnh; build/cài APK an toàn, launch/process/logcat giới hạn.
- **Giới hạn/an toàn:** tất cả case được để `NOT RUN`. Ưu tiên report tổng hợp sẵn có; nếu cần tạo fixture mới thì tối đa hai report/AI request. Không xóa dữ liệu, không cố tình làm hỏng DB/ảnh, không đọc vùng riêng tư hoặc ghi serial/IP/token/log thô. Not-found và lỗi ảnh/repository nhân tạo đã có widget coverage; chỉ đánh dấu BLOCKED nếu không xảy ra lỗi tự nhiên trên thiết bị.
- Không chạy build/test, không kết nối ADB, không cài APK, không thay đổi dữ liệu thiết bị và không gọi Gemini trong lượt soạn test case này. Cập nhật liên kết tài liệu trong README, context summary và walkthrough.

## 2026-09-29 — ADB Wireless kiểm tra Task 6 trên thiết bị

- **Phạm vi:** chạy build/cài APK Task 6, mở History và detail, quan sát trạng thái ảnh/mô tả, điều hướng Back, process và logcat. Không tạo Gemini request, không sửa/xóa report, không đọc database/vùng riêng tư, không dùng `force-stop`.
- **Thiết bị/kết nối:** một thiết bị Android mDNS Wireless online, PKG110, Android 16/API 36. Một lần `flutter devices --machine` liệt kê hai mục Android tên PKG110 với ID khác nhau; lần đọc sau còn một mục. Dùng duy nhất thiết bị online được ADB liệt kê, không lưu serial/IP.
- **Build/cài:** `flutter build apk --debug` exit 0. `adb install -r` trả `Success`; version 0.1.0 (versionCode 1), APK 178,604,382 bytes, SHA-256 `6E84D74E20027B08CE7A04B0E93626A00AB872D8064B89D62E97D2DBD9A59804`. Report đã có vẫn hiển thị sau cài đè.
- **Quan sát UI:** mở History, vào các report đã có, xem trạng thái/field đã xác nhận, mô tả gốc, ghi chú hành động đề xuất, trạng thái không có ảnh và một ảnh đã lưu; Back quay lại History. Cỡ chữ hệ thống lớn đang bật; nội dung cuộn được, không thấy overflow. Nguồn/độ an toàn của fixture có sẵn chưa xác minh; không ghi/chụp nội dung hoặc ảnh vào tài liệu.
- **ADB sau thao tác:** app process có PID và resumed activity; Back từ detail về History, process tiếp tục chạy. Đọc `adb logcat -d -t 1500` trong bộ nhớ, 0 match `FATAL EXCEPTION` và 0 match nhóm SQLite/plugin; không xóa logcat buffer và không chép log thô.
- **Kết quả test case:** ghi riêng PHONE/ADB cases trong `docs/testcase_task6_detail_day4.txt`. ADB build/install/launch/log scan/Back đạt; Flutter discovery được PARTIAL do danh sách trùng tạm thời. UI cases bị giới hạn do không xác minh fixture, null/absence fixture chưa được kiểm tra, cùng-report reopen chưa được kiểm tra; lỗi retry tự nhiên không gặp nên BLOCKED.
- **Giới hạn:** lượt này không kiểm tra save mới hoặc độ bền sau force-stop/restart; Task 7 persistence trên Android vẫn cần xác minh riêng. Không chạy analyze/widget tests trong lượt ADB này. Giữ nguyên mọi thay đổi Git chưa commit và deletion có trước docs/PROMPT_01.md; không stage/commit/push.

## 2026-09-29 — Ngày 4 Task 7: xác minh persistence Android (một phần)

- **Yêu cầu:** tiếp tục Task 7, kiểm tra implementation như senior và báo cáo kết quả chi tiết; không commit/push.
- **Công cụ:** Codex dùng PowerShell, Flutter/Dart, ADB Wireless và UIAutomator. Ứng dụng gửi một request tổng hợp qua Firebase AI Logic; không ghi prompt đầy đủ hay nội dung raw của phản hồi. Model thực tế của request không được ghi nhận độc lập; mã service cấu hình gemini-3.8-flash primary và gemini-3.5-flash-lite fallback.
- **Kiểm tra tự động vừa chạy:** dart format --output=none --set-exit-if-changed lib test — exit 0, 26 file/0 đổi; flutter analyze — No issues found; flutter test --reporter compact — 99/99; flutter test test/local_report_repository_test.dart --reporter compact — 10/10; flutter build apk --debug — exit 0. Test repository dùng SQLite FFI trên host Windows, gồm close/reopen ảnh và các nhánh lỗi/missing/corrupt; không phải Android plugin test. Build có cảnh báo Java restricted native access và Firebase plugin Kotlin Gradle Plugin migration.
- **APK/thiết bị:** version 0.1.0/code 1, 178,604,382 bytes, SHA-256 6E84D74E20027B08CE7A04B0E93626A00AB872D8064B89D62E97D2DBD9A59804. APK cài đặt được pull/so hash trùng APK build; không cần cài đè. PKG110 Android 16/API 36, điều khiển qua ADB Wireless. ADB liệt kê hai wireless transports; không ghi serial/IP.
- **Luồng đã xác minh:** tạo draft text-only với dữ liệu tổng hợp → chỉnh sửa/review → xác nhận priority null là chưa có → xác nhận các field → lưu cuối → marker test hiện trong History → mở detail. Force-stop làm process kết thúc; mở lại app và marker vẫn đọc được ở History/detail. Một report test được giữ lại trên thiết bị để không xóa dữ liệu.
- **Case một phần/chưa chạy:** editor từng có issue rỗng nhưng chưa kiểm tra nút lưu khi các field khác đã review hết. Photo Picker không liệt kê fixture tổng hợp sau media-scan, nên không chọn media có sẵn và không tạo report có ảnh. Offline save/read chưa chạy: chỉ có ADB Wireless transports và không đổi trạng thái Wi-Fi để giữ kênh điều khiển. Case chi tiết ở docs/testcase_task7_persistence_day4.txt.
- **Log/giới hạn:** adb logcat -d -t 1800 đọc trong bộ nhớ, 1.956 dòng; 0 match FATAL EXCEPTION và 0 match nhóm SQLite/plugin error đã lọc. Không xuất raw logs, không xóa log buffer. Kiểm tra này không chứng minh ảnh persistence/offline.
- **Fixture dọn dở:** một lệnh dọn ảnh/screenshot tổng hợp trong Temp và trên Android qua ADB bị automatic approval review chặn với trạng thái blocked by policy; lệnh không chạy. Fixture còn lại do phiên test tạo; không đụng file/media khác. Report tổng hợp đã lưu cũng còn trong app.
- **Tình trạng Task:** Task 7 một phần, chưa đạt nghiệm thu Ngày 4 vì thiếu ảnh persistence và offline test. Task 8 chỉ được đồng bộ hiện trạng tài liệu một phần; chưa commit/push. Giữ nguyên deletion có trước docs/PROMPT_01.md.

## 2026-09-29 — Chủ dự án đóng Task 7 với ngoại lệ và yêu cầu publish

- **Quyết định/phạm vi:** chủ dự án yêu cầu đánh dấu Task 7 hoàn thành và commit/push. Task được ghi là đóng theo quyết định chủ dự án với ngoại lệ được chấp nhận; điều này không biến ảnh/offline PARTIAL/BLOCKED/NOT RUN thành PASS và Day 4 vẫn chưa nghiệm thu đầy đủ.
- **Cập nhật:** README, CONTEXT_SUMMARY, WALKTHROUGH, implement_plan_day4, phiếu Task 7 và worklog đồng bộ quyết định đóng cùng các ngoại lệ. Không đổi mã nguồn, cấu hình hay dependency.
- **Kiểm chứng:** không chạy lại Flutter tests/analyzer/build vì đây là lượt tài liệu-only; kết quả tự động/thiết bị tham chiếu từ mục kiểm chứng Task 7 ngay trước đó. `git diff --check` được chạy trước staging; nội dung staging và kết quả publish được xác minh riêng.
- **Git:** chỉ stage tài liệu thuộc Task 7/Task 8; không stage deletion có trước `docs/PROMPT_01.md`. Không xóa report test hay fixture còn lại.

## 2026-09-29 — Ngày 4 Task 8: rà soát tài liệu và bàn giao

- **Yêu cầu/phạm vi:** lập plan chi tiết và hoàn tất Task 8. Đây là công việc docs-only; không mở rộng sang thay đổi mã, kiểm thử thiết bị, offline hoặc xác minh ảnh.
- **Đối chiếu:** đọc `AGENTS.md`, roadmap Ngày 4, Task 8 plan, README, context, walkthrough, worklog và test records Task 4–7. Kiểm tra các mô tả hiện tại với mã repository/editor/history/detail và bằng chứng đã ghi. Các test count 85/90/99, repository FFI 10/10, ADB/PHONE và user-reported được giữ đúng nguồn/lượt; Task 5 AI manual cases vẫn được đánh dấu là tài liệu lịch sử.
- **Kiểm tra tài liệu:** rà liên kết Markdown cục bộ trong README/docs — tất cả resolve; rà mẫu API token/private key phổ biến trên các tài liệu bàn giao — không có kết quả khớp. Không lưu giá trị nhạy cảm hoặc raw logs.
- **Công cụ/kiểm chứng:** Codex, PowerShell và Git; không gọi Firebase/Gemini, không kết nối ADB và không chạy Flutter build/analyze/test trong lượt này. Chạy `git diff --check`; các test/build gần nhất vẫn là bằng chứng Task 7 trong entry ngay phía trên, không được chạy lại trong Task 8.
- **Kết quả:** checklist Task 8 trong `docs/implement_plan_day4.md` đã hoàn tất. Task 7 vẫn được đóng theo quyết định chủ dự án với ngoại lệ được chấp nhận; ảnh/offline còn chưa xác minh và Day 4 chưa nghiệm thu đầy đủ.
- **Git:** giữ nguyên deletion có trước `docs/PROMPT_01.md`; không commit/push trong yêu cầu Task 8 này.

## 2026-09-29 — Ngày 5 Task 1: preflight và baseline APK

- **Yêu cầu/phạm vi:** chủ dự án yêu cầu bắt đầu Task 1 và hoàn tất toàn bộ phần có thể kiểm chứng. Đối chiếu Git/source, chạy format check, analyzer, full tests và repository FFI; build APK debug và cài lên Android emulator nếu khả dụng. Không sửa mã, không xóa app data, không gọi Gemini.
- **Công cụ:** Codex, PowerShell, Git, Dart/Flutter CLI và Android Platform Tools. Lượt `dart format` thường trong sandbox không xuất tiến độ hơn một phút; lệnh không ghi file nên được dừng an toàn, rồi chạy lại với quyền SDK/cache và `--output=none`.
- **Baseline Git trước khi kiểm tra:** nhánh `codex/day4-preflight`, HEAD `37c0b0c` đồng bộ với `origin/codex/day4-preflight`. Có sẵn README và CONTEXT_SUMMARY sửa, `docs/PROMPT_01.md` bị xóa, `docs/implement_plan_day5.md` chưa theo dõi; tất cả được giữ nguyên. Không có thay đổi mã/config/test trước lượt này.
- **Kiểm tra source vừa chạy:** `dart format --output=none --set-exit-if-changed lib test` — PASS, 26 file/0 đổi; `flutter analyze` — PASS, No issues found; `flutter test --reporter compact` — PASS, 99/99; `flutter test test/local_report_repository_test.dart --reporter compact` — PASS, 10/10 với SQLite FFI trên host Windows. Đây là kiểm tra code/host, không phải Gemini E2E hay SQLite plugin test trên Android.
- **Build/APK:** `flutter build apk --debug` — PASS, APK 178,604,382 bytes, SHA-256 `6E84D74E20027B08CE7A04B0E93626A00AB872D8064B89D62E97D2DBD9A59804`. Build có cảnh báo Java restricted native access và Firebase plugins còn dùng Kotlin Gradle Plugin; build vẫn exit 0.
- **Thiết bị:** lúc đầu không có Android device online; Flutter liệt kê Windows/Chrome/Edge. Khởi chạy AVD API 35 sẵn có, ADB báo `device`, `sys.boot_completed=1`, Flutter nhận `sdk gphone64 x86 64`. Package chưa cài trước đó; `adb install -r` trả `Success`. Xác nhận package versionName `0.1.0`, versionCode `1`. Không gỡ app, xóa dữ liệu, force-stop hay mở app để test UI. AVD được để chạy để tiếp tục kiểm tra sau.
- **Kết luận/giới hạn:** Task 1 hoàn tất theo scope: baseline tự động, FFI host, APK build và cài đặt emulator đều có kết quả. Chưa xác minh UI/runtime, Android SQLite/photo persistence, offline hoặc real Gemini request; các mục đó không được suy ra từ build/cài đặt. Không có serial/IP, token, prompt/response hoặc log thô được ghi. Chi tiết ở `docs/testcase_day5_resilience.txt`.

## 2026-09-29 — Ngày 5 Task 2: carry-over persistence Android

- **Phạm vi:** thực hiện phần lưu/đọc ảnh và save/read offline theo `docs/implement_plan_day5.md`; giới hạn ở report tổng hợp, Android Photo Picker và UI thông thường. Giữ nguyên thay đổi có trước; không đổi source/config/test.
- **Baseline:** nhánh `codex/day5`, HEAD `1b53614`; Android emulator API 35 (x86_64), boot completed, ADB local. Package `com.example.ai_field_assistant` báo versionName `0.1.0`, versionCode `1`. SHA-256 APK host khớp Task 1 (`6E84D74E20027B08CE7A04B0E93626A00AB872D8064B89D62E97D2DBD9A59804`); APK không được build/cài lại hoặc pull/hash độc lập trong lượt này.
- **UI/fixture:** app mở được; History tải xong và hiện empty state “Chưa có báo cáo đã lưu”. Photo Picker ban đầu trống. Fixture PNG host `ai_field_task7_synthetic.png` được kiểm tra bằng hình ảnh, có nhãn TEST ONLY; chép một bản dưới tên mới `/sdcard/Pictures/AI_Field_Day5_Task2_Synthetic.png`, yêu cầu MediaScanner index, sau đó chọn bằng Photo Picker chuẩn. Preview ảnh hiển thị. Fixture này được giữ trên emulator; không dùng media cá nhân hoặc quyền truy cập vượt picker.
- **AI-D5-01:** nhập mô tả synthetic nêu rõ không phải sự cố thật, rồi bấm CTA **Phân tích bằng AI** một lần. UI báo ứng dụng chưa được xác minh với dịch vụ AI (App Check), form còn giữ mô tả/ảnh; không retry. Ghi nhận một lần user-initiated attempt, không khẳng định Gemini model đã nhận/xử lý nội dung; không đọc hoặc ghi token.
- **PHOTO-D5-02:** **BLOCKED** — App Check không trả draft nên chưa có report ảnh để save, mở History/detail hoặc kiểm tra sau force-stop/relaunch.
- **OFFLINE-D5-01:** **BLOCKED** — History không có report test sẵn và không có draft do App Check chặn. Không thay đổi trạng thái mạng và không đọc database/app-private data. Local save/read offline chưa được thử.
- **Kiểm chứng trong lượt:** ADB local báo emulator (`ro.kernel.qemu=1`), Android API 35, boot completed; package `0.1.0`/versionCode `1`; hash APK host khớp Task 1. `uiautomator dump /dev/stdout` không trả root node; quan sát UI qua screenshot tạm rồi xóa screenshot do lượt này tạo. Không chạy Flutter formatter/analyze/test/build; không đổi source/config. Không lưu serial/IP, debug token, prompt/response hoặc log thô.
- **Kết luận:** PHOTO-D5-01 đạt chọn/preview fixture tổng hợp qua picker. Persistence ảnh, save/read offline còn **BLOCKED**; AI-D5-01 bị App Check từ chối. Cần đăng ký debug token riêng của emulator trong Firebase App Check trước khi có thể thử lại một lần tạo draft. Không coi các bước chưa chạy là PASS.

## 2026-09-29 — Ngày 5 Task 3: audit service/parser

- **Yêu cầu/phạm vi:** triển khai Task 3 theo `docs/implement_plan_day5.md`; chỉ sửa lỗi service/parser có test tái hiện, giữ contract schema hiện tại. Không gọi Gemini/App Check thật, không build APK, không commit/push.
- **Baseline Git:** `codex/day5`, HEAD `077c943`. Trước Task 3 đã có README và CONTEXT_SUMMARY sửa, `docs/PROMPT_01.md` bị xóa và `docs/implement_plan_day5.md` chưa theo dõi. Giữ nguyên các thay đổi đó.
- **Phát hiện trước khi sửa:** service tin mọi `XFile.mimeType` bắt đầu bằng `image/`, nên fake sender nhận được PNG gắn MIME JPEG và SVG; lỗi `XFile.readAsBytes()` ném `PathNotFoundException` ra ngoài service. Test mới tái hiện cả ba lỗi.
- **Thay đổi:** giới hạn inline input ở `image/jpeg`, `image/png`, `image/webp` theo [Firebase AI Logic input-file requirements](https://firebase.google.com/docs/ai-logic/input-file-requirements); nhận dạng signature và từ chối MIME không hỗ trợ hoặc không khớp bytes; yêu cầu PNG có magic + IHDR tối thiểu; hỗ trợ suy MIME khi metadata null/rỗng hoặc `application/octet-stream`; map lỗi đọc ảnh sang `InvalidReportDraftInputException` không chứa đường dẫn. Cập nhật message định dạng. Không đổi `ReportDraft` contract.
- **Coverage thêm:** đúng 4 MiB được gửi, hơn ngưỡng 1 byte bị chặn; MIME chung, JPEG/WebP, PNG thiếu IHDR, MIME không hỗ trợ/mismatch, lỗi đọc file, response `null`, phần tử confirmation sai kiểu, field thiếu + thiếu confirmation, key lạ và key map không phải chuỗi. Unknown response key tiếp tục bị bỏ qua theo hành vi hiện có.
- **Kiểm chứng vừa chạy:** `dart format` ba file Dart; `dart format --output=none --set-exit-if-changed lib test` PASS, 26 file/0 đổi; `flutter analyze` PASS (`No issues found`); test service/model PASS 43/43; full `flutter test --reporter compact` PASS 113/113. Chạy test bằng fake/local trên Windows, không xác minh request mạng, Firebase App Check, model thực tế hay plugin Android.
- **Giới hạn cần nối tiếp:** `CreateReportScreen._hasSupportedImageSignature` vẫn preview được BMP/GIF/HEIF/AVIF trong khi service inline hiện chỉ chấp nhận PNG/JPEG/WebP. Task 4 nên căn form/picker/thông báo với allowlist dịch vụ. Task 2 PHOTO-D5-02 và OFFLINE-D5-01 vẫn BLOCKED do App Check chặn việc tạo draft có ảnh; Task 3 không thay đổi kết quả này.
- **Git:** chưa stage/commit/push; các thay đổi được giữ để review cùng trạng thái có trước.
