# Kế hoạch triển khai — Ngày 3: Firebase AI Logic và bản nháp báo cáo

> **Trạng thái:** Task 1 đã được điều chỉnh theo lựa chọn Firebase AI Logic trên Spark. Cấu hình Firebase Console/FlutterFire đã thực hiện theo thông tin chủ dự án cung cấp; chưa có SDK trong app, chưa gọi Gemini và chưa kiểm thử/build lại.
>
> **Quyết định hiện tại:** dùng Firebase AI Logic → Gemini Developer API → `gemini-3.8-flash`, trên Spark/free tier. Không tạo Cloud Run backend và không đưa Gemini API key vào app. Chỉ dùng dữ liệu tổng hợp vì free tier có thể dùng nội dung gửi lên để cải thiện sản phẩm Google.

## 1. Mục tiêu Ngày 3

Hoàn thiện lát chức năng có thể kiểm chứng:

```text
Người dùng nhập mô tả/chọn ảnh và chủ động bấm tạo
  → Flutter Firebase AI Logic SDK
  → Firebase proxy + Firebase App Check
  → Gemini Developer API (`gemini-3.8-flash`)
  → JSON theo schema, được app parse/validate
  → người dùng xem bản nháp AI chưa xác nhận/chưa lưu
```

Ngày 3 chưa làm lưu cục bộ, lịch sử có dữ liệu, đăng nhập hoặc Cloud Run backend. Không hiển thị dữ liệu giả như kết quả Gemini thật.

## 2. Hiện trạng và quyết định đã có

- Form nhập mô tả/ảnh hiện tại ở `lib/screens/create_report_screen.dart`; app shell ở `lib/main.dart`.
- Chủ dự án đã chạy `flutterfire configure`, chọn Android/Web và Firebase project `AI Field Assistant`; lệnh báo tạo `lib/firebase_options.dart`. Git hiện còn thấy các cấu hình Firebase mới chưa theo dõi: `firebase.json`, `android/app/google-services.json`, `lib/firebase_options.dart`. Không đọc/ghi đè các file cấu hình này trong Task 1.
- Firebase Console đã bật Gemini Developer API/Firebase AI Logic và AI monitoring; project hiển thị **Spark — No-cost**.
- Firebase Console liệt kê app Android và Web nhưng trạng thái App Check của cả hai là **Unregistered**. Chưa có Firebase SDK/App Check dependency trong `pubspec.yaml`, Firebase initialization trong `main.dart`, hoặc request Gemini.
- Model đã chọn cho prototype là `gemini-3.8-flash`. Firebase AI Logic liệt kê model này là không cần billing khi dùng Gemini Developer API; model nhận text/ảnh và hỗ trợ structured output. Firebase ghi đây là **short-term availability model**, nên kiểm tra model lifecycle trước khi duy trì lâu dài và giữ model name tập trung để có thể thay sau.
- Spark/free tier không cần thêm card hoặc Cloud Billing. Quota free tier vẫn áp dụng. Không dùng dữ liệu hiện trường thật: Gemini Developer API free tier có thể dùng input để cải thiện sản phẩm Google.
- Trước đây đã chọn Cloud Run, Secret Manager và paid-tier mục tiêu USD 5/tháng. Quyết định đó **đã được thay thế** cho prototype này: không dựng Cloud Run, không cấu hình Secret Manager, không dùng mục tiêu chi phí paid-tier khi chỉ chạy Spark/free tier. Nếu chuyển paid tier sau này, phải hỏi/chốt billing và ngân sách lại.

## 3. Quy tắc schema, dữ liệu và bảo mật

Schema đầu ra:

```json
{
  "category": "",
  "location": "",
  "priority": null,
  "issue": "",
  "suggested_action": "",
  "summary": "",
  "needs_confirmation": []
}
```

- `priority` chỉ nhận `low`, `medium`, `high` hoặc `null`; không mặc định `medium`.
- Field thiếu căn cứ được để rỗng/null và thêm vào `needs_confirmation`. `issue` có thể rỗng trong draft nhưng bắt buộc trước khi lưu ở bước sau.
- `suggested_action` là đề xuất, không mô tả việc đã thực hiện. Không bịa nguyên nhân, địa điểm hoặc mức độ hư hỏng.
- `summary` chỉ tóm tắt dữ kiện người dùng nêu rõ trong mô tả; thông tin chỉ thấy trong ảnh không được trình bày như dữ kiện đã xác nhận. Nếu không có dữ kiện mô tả rõ, để rỗng và đánh dấu cần xác nhận.
- Firebase AI Logic proxy giữ Gemini API key phía server. Không lấy key từ Console để dán vào Dart, không log/commit token. `firebase_options.dart` là cấu hình Firebase client đã được FlutterFire tạo; không gửi nội dung file vào chat.
- Trước CTA cần nói rõ mô tả/ảnh được gửi tới Gemini. Chỉ gửi sau khi người dùng chủ động bấm.
- Free tier: chỉ dùng fixture và ảnh tổng hợp, không chứa thông tin cá nhân, tòa nhà/khách hàng thật hoặc dữ liệu hiện trường.

## 4. Task triển khai

### Task 1 — Preflight, quyết định model/provider và Firebase project

**Trạng thái:** Phần preflight/quyết định Task 1 hoàn tất ngày 2026-09-26. Firebase project/app đã được tạo qua Console/FlutterFire và quota Firebase AI Logic đã được hạ. Chưa có request Gemini hoặc tích hợp Flutter; đó là việc của các task triển khai tiếp theo.

**Đã làm:**

- Đã đọc repo/Git, xác nhận chưa có backend/Firebase SDK trước khi chủ dự án chạy FlutterFire.
- Đã tra model, capabilities, giá/free tier, khu vực, App Check và Firebase AI Logic.
- Đã chọn `gemini-3.8-flash` qua Firebase AI Logic/Gemini Developer API trên Spark; tránh Cloud Run/Secret Manager ở hướng miễn phí.
- Chủ dự án xác nhận Firebase Console báo APIs enabled, AI monitoring enabled, project Spark no-cost; Android/Web app đã được đăng ký.

**Điều kiện cần xử lý ở các task tích hợp tiếp theo (không chặn quyết định Task 1):**

- App Check của Android/Web vẫn báo `Unregistered`. Guided setup đã bật enforcement; trước request app cần Firebase SDK và token hợp lệ. Task 3 sẽ cấu hình debug provider/token cho local; production cần provider/attestation riêng.
- Quota Firebase AI Logic đã được đặt 5 RPM per-user cho từng vùng Asia. Quota riêng của Gemini Developer API free tier chưa được xác minh bằng request; provider có thể áp dụng giới hạn thấp hơn.
- Không cần bật billing cho Spark/free tier. Không chạy lệnh lấy tài khoản Firebase, không truy cập/nhận API key và không gửi dữ liệu hiện trường thật.

**Quyết định giới hạn cho các task sau:**

- Firebase AI Logic có giới hạn tổng request 20 MB và ảnh inline base64 7 MB. Đặt ngưỡng an toàn ban đầu **tối đa 4 MiB bytes ảnh gốc gửi lên SDK** (để còn chỗ cho base64 overhead); prompt phải giữ ngắn. Đầu vào app hiện cho phép tới 10 MiB, nên service phải từ chối hoặc tạo bản sao ảnh đã giảm dung lượng trước khi gửi. Không thay/xóa ảnh preview của người dùng nếu xử lý gửi thất bại.
- Dùng timeout phía app ban đầu 60 giây, retry chỉ do người dùng bấm. Đây là giá trị khởi đầu để kiểm thử; không có Cloud Run/server timeout trong kiến trúc này.
- Firebase App Check + quota per-user của AI Logic. Chủ dự án đã đặt `Generate content requests` ở **5 RPM** cho 10 vùng Asia trong Firebase AI Logic API; các `Bidi generate content requests` giữ nguyên 100 vì app không dùng streaming. Quota này là mức per-user/per-region của Firebase proxy, không phải quota riêng của Gemini Developer API. App Check không phải xác thực người dùng và không loại trừ hoàn toàn lạm dụng.
- Spark/free tier không có mục tiêu USD 5/tháng; không thể coi quota là bảo đảm quyền riêng tư. Khi paid tier được đề xuất, phải dừng và xin xác nhận billing/ngân sách mới.

**File/kết quả:** `lib/firebase_options.dart`, `firebase.json`, `android/app/google-services.json` hiện là các file cấu hình Firebase trong working tree; chủ dự án tạo qua FlutterFire setup. Chủ dự án cũng đặt quota Firebase AI Logic như mô tả trên. `docs/AI_WORKLOG.md` ghi nguồn và kết quả. Chưa sửa App Check token hoặc secret.

**Tiêu chí Task 1:** đã chọn và ghi rõ provider/model/plan/đường bảo mật/quota/giới hạn đầu vào; trạng thái Console và điều kiện trước request thật được ghi trung thực. App Check runtime vẫn phải hoàn thành ở Task 3; không tuyên bố app đã gọi Gemini khi Console còn `Unregistered` và chưa có SDK.

### Task 2 — Chốt ReportDraft, schema JSON và prompt

**Mục tiêu:** định nghĩa hợp đồng output dùng thống nhất ở model, prompt và parser Dart.

**Trạng thái:** Đã triển khai ngày 2026-09-26; model/prompt chưa được nối vào Firebase AI Logic.

**Đã thực hiện:**

1. Tạo `ReportDraft` với bảy field ở Mục 3 và `ReportPriority` nullable enum rõ ràng.
2. Viết prompt tiếng Việt trong `lib/services/report_draft_prompt.dart`: chỉ dùng mô tả/ảnh làm căn cứ, không suy đoán thiếu dữ kiện, `suggested_action` là đề xuất, đánh dấu field cần xác nhận.
3. Thêm Dart JSON parser/serializer strict; field thiếu/rỗng/null được biểu diễn an toàn và đánh dấu trong `needs_confirmation`; sai type/enum/schema báo `FormatException` để service/UI xử lý.

Firebase `responseSchema`/JSON mode chưa được cấu hình vì Firebase AI Logic SDK chưa được tích hợp; Task 4 sẽ chuyển schema Dart sang cấu hình Firebase SDK và vẫn giữ parser validation phía app.

**Chuẩn bị:** schema dự án và fixture tổng hợp cho sự cố rõ ràng, thiếu địa điểm, mơ hồ, ảnh không liên quan, chỉ text/chỉ ảnh.

**File đã thêm:** `lib/models/report_draft.dart`, `lib/services/report_draft_prompt.dart`, `test/report_draft_test.dart`. Không thêm model persistence hoặc repository trong task này.

**Tránh:** dữ liệu hiện trường thật trong prompt/fixture; mặc định priority; coi JSON model là đáng tin chỉ vì có schema; prompt hoặc key nhạy cảm không được bảo vệ ở client.

**Kiểm thử đã chạy:** 5 model tests đạt: parse/serialize hợp lệ; field thiếu/rỗng được gắn confirmation; thiếu `needs_confirmation` thì mọi field cần review; JSON root sai; type/priority/confirmation không hợp lệ bị từ chối. Tests chỉ dùng fixture tổng hợp, không gọi Gemini thật. `flutter analyze` theo ba file Task 2 không có vấn đề.

### Task 3 — Nối Firebase Core và App Check debug provider

**Mục tiêu:** khởi tạo Firebase AI Logic trên Android/Web và giải quyết cấu hình App Check cho local development.

**Cần làm:**

1. Thêm dependencies theo Firebase Flutter docs: `firebase_core`, `firebase_ai`, `firebase_app_check`; chạy `flutter pub get`.
2. Dùng `DefaultFirebaseOptions.currentPlatform` từ file đã sinh; đổi `main()` sang async và gọi `WidgetsFlutterBinding.ensureInitialized()`/`Firebase.initializeApp()`.
3. Cấu hình App Check debug provider trong debug build cho Android và Web. Chạy app để lấy debug token, đăng ký token trong Firebase Console; không ghi token vào source, Git, ảnh chụp hoặc chia sẻ chat.
4. Xác nhận Console App Check thực sự nhận app/request hợp lệ; nếu `Unregistered` còn đó hoặc AI Logic báo 403, dừng và xử lý cấu hình thay vì tắt App Check.
5. Provider production (Android Play Integrity, Web reCAPTCHA Enterprise) chỉ cấu hình khi chuẩn bị phát hành; không dùng debug token trong release.

**File dự kiến:** `pubspec.yaml`, `pubspec.lock`, `lib/main.dart`, có thể `analysis_options.yaml` nếu sinh config cần ignore riêng; giữ mọi thay đổi hiện có. Không đọc hoặc in `google-services.json`/`firebase_options.dart` ra output.

**Tránh:** Cloud Run, `http` client gọi Gemini trực tiếp, Gemini API key trong APK, tắt App Check để vượt qua lỗi, commit debug token, thêm Analytics/Firestore không cần thiết.

**Kiểm thử:** `flutter analyze`; app khởi chạy trên Android/Web, Firebase initialize thành công; App Check debug request được chấp nhận, request không có token bị từ chối theo Console. Không gửi dữ liệu thật.

### Task 4 — Tạo Firebase AI Logic service, gọi Gemini và validate

**Mục tiêu:** gửi text/ảnh qua Firebase proxy và trả về `ReportDraft` an toàn.

**Cần làm:**

1. Tạo service Dart độc lập UI, dùng `FirebaseAI.googleAI()` với model `gemini-3.8-flash`; model name không dùng alias `-latest`.
2. Hỗ trợ mô tả, ảnh, cả hai hoặc một trong hai; từ chối nếu cả hai trống. Đọc bytes bằng `XFile.readAsBytes`; kiểm tra loại ảnh và ngưỡng 4 MiB cho request. Nếu cần nén/resize thêm, không làm mất ảnh gốc khi lỗi.
3. Thiết lập prompt, response MIME `application/json`/response schema phù hợp API. Parse text trả về, validate đủ type/enum/fields và `needs_confirmation`.
4. Map exception của Firebase AI Logic thành lỗi hiển thị được: invalid input, quota/rate limit, network, timeout, App Check/config và model response lỗi. Timeout client 60 giây, retry thủ công.
5. Không log prompt, ảnh, response hiện trường hoặc debug token. Mọi live smoke test chỉ dùng dữ liệu tổng hợp.

**File dự kiến:** `lib/services/gemini_report_service.dart`; có thể thêm interface mỏng để inject fake; model từ Task 2.

**Tránh:** tự tạo backend hoặc API key; gọi Gemini bằng HTTP trực tiếp; xem dữ liệu Spark/free là phù hợp cho field data; retry tự động gây gọi lặp/quota.

**Kiểm thử:** fake/injected model hoặc test parser cho hợp lệ, field thiếu, JSON sai, network, timeout, quota/App Check failure; text-only/image-only/multimodal; unit test không phụ thuộc Internet hay Firebase project.

### Task 5 — Nối service với form và hiển thị draft

**Mục tiêu:** người dùng chủ động gửi đầu vào và xem draft chưa xác nhận.

**Cần làm:**

1. Thêm CTA tạo bản nháp, chặn mô tả+ảnh rỗng và giới hạn ảnh trước khi gọi SDK.
2. Nói rõ text/ảnh sẽ được gửi tới Gemini qua Firebase AI Logic; trong Spark/free chỉ dùng dữ liệu tổng hợp.
3. Hiện loading, khóa gửi lặp, timeout/lỗi/quota dễ hiểu và nút retry thủ công; không mất mô tả/ảnh khi lỗi.
4. Hiện kết quả có nhãn “Bản nháp AI — cần kiểm tra, chưa lưu”; hiển thị `needs_confirmation`, phân biệt hành động đề xuất.
5. Chưa thêm lưu/xác nhận trong Task 5; phần đó thuộc ngày sau.

**File dự kiến:** sửa `lib/screens/create_report_screen.dart`, thêm `lib/screens/report_draft_screen.dart` hoặc widget tương đương, mở rộng `test/widget_test.dart`.

**Tránh:** nút giả, draft mẫu như thể là Gemini thật, tự lưu hoặc tuyên bố người dùng xác nhận, xoá input khi SDK lỗi.

**Kiểm thử:** widget tests với fake service cho empty input, loading, success, retry, lỗi giữ input; viewport 320×568 không overflow.

### Task 6 — Kiểm thử tự động và smoke test Firebase AI Logic

**Mục tiêu:** xác nhận code và cấu hình hoạt động trong giới hạn Spark/free.

**Cần làm:**

1. Chạy `dart format lib test`, `flutter analyze`, `flutter test`.
2. Dùng Android/Web debug provider và synthetic input; kiểm tra text-only, image-only, cả hai, input rỗng, ảnh >4 MiB, ảnh không phù hợp, thiếu địa điểm/mô tả mơ hồ.
3. Kiểm tra quota/rate-limit và App Check failure; không bật billing để vượt quota.
4. Ghi rõ lỗi/thời gian/response thực tế, không log payload; nếu quota hết thì dừng và ghi blocker.

**File dự kiến:** test model/service/widget; `docs/AI_WORKLOG.md` chỉ ghi kết quả thực đã quan sát.

**Tránh:** ảnh, mô tả hoặc tài sản của hiện trường thật; gửi debug token; đánh đồng test fake với Gemini E2E.

**Kiểm thử/tiêu chí hoàn thành:** các test tự động đạt; một synthetic end-to-end request chạy với App Check hợp lệ; không khẳng định chức năng hoạt động nếu chưa chạy request thật.

### Task 7 — Rà tài liệu và bàn giao Ngày 3

**Mục tiêu:** tài liệu khớp Firebase AI Logic/Spark và trạng thái triển khai.

**Cần làm:** cập nhật README, context, walkthrough và worklog về FlutterFire setup, Spark/free-tier, App Check, giới hạn data-use, quota, cách chạy và các phần chưa tích hợp; rà Git diff/status, giữ nguyên user changes.

**Tránh:** ghi Cloud Run/Secret Manager như kiến trúc đang chọn; nói AI hoạt động nếu chưa có SDK/API test; ghi prompt/output giả hoặc debug token.

**Kiểm thử:** đối chiếu mọi tuyên bố với code/Console/output test. Docs-only không cần chạy lại code tests; nếu có sửa code thì chạy kiểm tra liên quan.

## 5. Nghiệm thu Ngày 3

- [ ] Firebase AI Logic và App Check khởi tạo được trên Android/Web.
- [ ] Free-tier request dùng synthetic text/ảnh và không yêu cầu Cloud Billing.
- [ ] Ảnh gửi đi không vượt 4 MiB bytes; input rỗng/không hỗ trợ bị chặn.
- [ ] Output được parse/validate schema; thiếu/sai field được xử lý an toàn.
- [ ] Loading, timeout, lỗi/quota, retry thủ công; input không mất.
- [ ] Draft được ghi rõ chưa xác nhận/chưa lưu.
- [ ] App Check không còn lỗi Unregistered/403 trong luồng debug; debug token không bị commit.
- [ ] README/worklog mô tả free-tier data use và chưa tuyên bố hỗ trợ dữ liệu hiện trường thật.
- [ ] Chưa có persistence/history, voice, GPS hoặc đăng nhập.

## 6. Thứ tự ưu tiên và điều kiện dừng

1. Hoàn thiện App Check debug provider và Firebase initialization.
2. Model/schema/prompt/response validation.
3. Service + UI loading/error/retry + draft preview.
4. Tests và synthetic smoke test; kiểm tra quota trước mỗi request.
5. Tài liệu và ghi nhận kết quả thực.

Nếu free quota hết, App Check chưa hợp lệ hoặc Firebase AI Logic báo lỗi, dừng request và ghi blocker. Không bật paid tier/billing nếu chưa có chủ dự án xác nhận, không thay Gemini thật bằng kết quả giả.
