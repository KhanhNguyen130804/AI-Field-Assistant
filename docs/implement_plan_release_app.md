# Kế hoạch triển khai — Phát hành APK và cấu hình App Check cho tính năng AI

> **Cập nhật mới nhất — Release Task 2 (01/10/2026): mã + kiểm tra liên quan đã hoàn tất, chưa nghiệm thu Android release.** Nhánh `codex/release-app-check` từ `6bb3a1e`; scope commit loại trừ hai test modified và checklist có trước. Android profile/release đã có reCAPTCHA với site key công khai truyền lúc build; debug giữ provider riêng. Task 1 vẫn PARTIAL, signing/build/token/AI trên máy mới chưa thực hiện. Snapshot Task 1 và các follow-up bên dưới là lịch sử trước triển khai Task 2.

> Cập nhật ngày 01/10/2026: **Task 1: PARTIAL**. Ảnh người dùng cung cấp xác nhận reCAPTCHA API Enabled, Android key đã tạo và Firebase App Check Android Fraud Defense Registered; agent chưa truy cập Console trực tiếp thành công. Baseline trước publication docs: `codex/day7`, HEAD `fa85658`; hai tệp test đang modified, checklist thiết bị và kế hoạch này đang untracked. Giữ nguyên các thay đổi có trước. Agent chỉ kiểm tra local/tài liệu công khai/ảnh và cập nhật docs; chưa sửa mã sản phẩm, tạo keystore, build APK, đổi Console hoặc chạy test/request AI. Kết quả chi tiết và phần chưa xác minh ở mục Task 1 bên dưới.
>
> Nguồn phạm vi: `AGENTS.md` (bảo mật/bí mật), `docs/CHALLENGE_VI_ROADMAP.md` (mục 6 sản phẩm cần nộp, mục 10 checklist), `lib/main.dart`, `lib/services/gemini_report_service.dart`, `android/app/build.gradle.kts`, `docs/AI_WORKLOG.md` và `docs/CONTEXT_SUMMARY.md`.

> **Thông tin chủ dự án đã chốt trong lượt này:** người nhận tải APK trực tiếp và phải dùng được AI; có quyền Firebase Console, chưa có Play Console. **Hướng đề xuất chính: E — reCAPTCHA Enterprise Android**, còn phụ thuộc preflight Google Cloud/quota/billing và kiểm chứng release. B1/B2 được giữ làm phương án đối chiếu; không yêu cầu mở Play Console để triển khai E.

## 1. Mục tiêu

Hai việc gắn chặt với nhau:

1. **Phát hành được app / tạo file APK** để nộp và để người khác cài: có version, có checksum, có cách phân phối rõ, có hướng dẫn cài.
2. **Đảm bảo tính năng "Phân tích bằng AI" chạy được trên bản được phân phối**, tránh lỗi App Check do chưa đăng ký debug token (hoặc do bản release không kích hoạt provider) khiến AI luôn báo lỗi.

Kết quả kỳ vọng: một APK/đường dẫn tải + hướng dẫn cài, kèm quy trình App Check đúng cho **từng loại build** (debug vs release), không có secret trong repo/APK, và ghi rõ giới hạn còn lại.

### 1.1 Làm rõ yêu cầu: người có APK cài vào dùng AI

Chủ dự án yêu cầu: **bất kỳ người nhận nào có file APK đều có thể cài và dùng tính năng AI**, không có danh sách máy được cấp quyền thủ công. Không yêu cầu người nhận có Firebase Console, lấy/đăng ký debug token, bật Developer options/ADB, tài khoản Google Play Console hoặc đăng nhập ứng dụng.

Phạm vi nghiệm thu thực tế: máy Android đáp ứng yêu cầu APK/SDK, có Internet và được production attestation chấp nhận; dịch vụ AI/quota còn khả dụng. Không tuyên bố mọi thiết bị đều được chấp nhận chỉ từ việc có APK: provider có thể từ chối một số môi trường. Hướng E là giải pháp đề xuất để bỏ đăng ký token thủ công, chưa phải bằng chứng đảm bảo trên mọi máy.

Nếu E từ chối một máy Android thuộc nhóm cần hỗ trợ, ghi lỗi release cần xử lý; không coi hướng dẫn đăng ký debug token là cách nghiệm thu. Nếu cần hỗ trợ cả môi trường bị production attestation từ chối, phải đánh giá lại kiến trúc truy cập AI/proxy và cơ chế chống lạm dụng trong một plan riêng trước khi mở rộng triển khai.

## 2. Hiện trạng và bằng chứng

- `lib/main.dart` chỉ gọi `FirebaseAppCheck.instance.activate(...)` **bên trong `if (kDebugMode)`**, dùng `AndroidDebugProvider` + `WebDebugProvider`. ⇒ Bản **release không kích hoạt provider nào**; nếu App Check đang bật enforcement thì request AI sẽ bị từ chối.
- App Check là điều kiện để Firebase AI Logic chấp nhận request: lịch sử ghi nhận đã từng bị `403 ... App attestation failed` khi debug token chưa được đăng ký; sau khi đăng ký mới có request thật đầu-cuối (27/09/2026).
- `android/app/build.gradle.kts` đặt `signingConfig = signingConfigs.getByName("debug")` cho release ⇒ APK release hiện **ký bằng debug key**, không phải bản phát hành production.
- Không có `android/key.properties`; chưa có cấu hình `signingConfigs.release` riêng. Task 1 chỉ kiểm tra thêm đường dẫn keystore dự kiến `$env:USERPROFILE\ai-field-release.jks` (chưa tồn tại), không kết luận mọi nơi trên máy đều không có keystore.
- `pubspec.yaml`: `version: 0.1.0+1`; chưa bump version trong lượt này, bước release tiếp theo nằm trong kế hoạch bên dưới.
- Dependencies App Check hiện tại: `firebase_app_check` 0.4.8 (dùng class provider mới `AndroidDebugProvider`/`AndroidPlayIntegrityProvider`).
- Lỗi App Check đã được ánh xạ thành thông báo tiếng Việt dễ hiểu (`ReportDraftAppCheckException`) — người dùng thấy hướng dẫn thay vì crash.
- Task 1 release vừa chạy `adb devices`, chỉ xuất số lượng: 0 online, 0 unauthorized, 0 offline. Chưa khởi động/kiểm tra AVD hoặc `ffmpeg` trong Task 1 này. SDK metadata đọc trong khảo sát trước ghi Flutter 3.47.1 / Dart 3.13.1; `FlutterExtension.kt` vừa đọc có `minSdkVersion = 24`, chưa phải metadata manifest của APK mới.
- Không có secret được in/ghi trong tài liệu này; các giá trị token/keystore **không** được đưa vào source, Git, log chia sẻ, ảnh chụp hay video.

## 3. Nguyên tắc an toàn và bí mật

1. **Không đưa token/keystore/mật khẩu vào** source, `git`, APK, README, worklog, ảnh chụp, video hoặc chat. Chỉ ghi đường dẫn/loại, không ghi giá trị.
2. **Không hardcode debug token** trong mã (kể cả để "cho tiện demo") — token trong APK/repo là rò rỉ.
3. Kiểm tra ignore **trước khi** tạo signing files: `android/.gitignore` đã chặn `key.properties`, `**/*.jks`, `**/*.keystore` trong cây Android. Root `.gitignore` chưa chặn keystore đặt ngoài cây Android; bổ sung khi triển khai signing nếu cần, không tạo keystore trong root repo.
4. Bản release **không dùng debug provider**; debug provider chỉ thuộc bản debug nội bộ. Source hiện tại không activate provider ở profile; không tự coi profile đã hỗ trợ AI.
5. Mọi kết luận "AI chạy được" phải đến từ **quan sát request thật trên đúng build**, không suy từ test fake hoặc từ build thành công.
6. Chỉ dùng **dữ liệu tổng hợp** khi thử AI (free tier có thể dùng dữ liệu để cải thiện sản phẩm Google).

## 4. Quyết định cần chốt trước khi làm

Bảng chọn mô hình phân phối + App Check (chủ dự án chọn 1 hướng chính):

| Hướng | Ai chạy được AI? | Cần gì | Rủi ro/ghi chú |
|---|---|---|---|
| **A. Debug APK + debug token** (nhẹ nhất, dùng cho demo nội bộ/quay video) | Chỉ thiết bị đã đăng ký debug token | Cài đặt giữ nguyên, đăng ký token mỗi máy | Token đổi khi cài lại/clear data; không hợp phát hành |
| **B1. Release APK + Play Integrity, ngoài Google Play** | Máy người nhận đạt điều kiện đã cấu hình; không đăng ký debug token từng máy | Signing riêng, SHA-256 chứng thư, setup Play Integrity/API/project và Console | Đặt policy đúng cho phân phối ngoài Play; phải thử sideload trên máy mới |
| **B2. Release AAB + Play Integrity, qua Google Play** | Người cài qua Play internal testing trên máy đáp ứng policy; không đăng ký debug token | Play Console, App Signing, liên kết Firebase project | Chứng thư Play App Signing có thể khác upload key; phải đăng ký đúng chứng thư bản được cài |
| **E. Release APK + reCAPTCHA Enterprise Android** | Máy người nhận được provider đánh giá hợp lệ; không đăng ký debug token | Firebase/GCP Console, Android site key đúng package, kiểm tra quota/chi phí | Provider Flutter đang Preview; cần kiểm tra native SDK/build và request thực tế |
| **D. Video demo AI + APK cho các phần không cần AI** (an toàn nhất cho challenge) | Không ai cần AI trên máy họ | Video quay trên máy đã đăng ký token | Không chứng minh AI chạy trên máy người đánh giá |

**Đề xuất đã thu hẹp theo trả lời của chủ dự án:** E cho APK trực tiếp; kiểm tra quyền Google Cloud, khả năng tạo Android key và điều kiện sử dụng trước khi triển khai. B1/B2 chỉ xem xét lại nếu thay đổi điều kiện Play Console. A phục vụ phát triển/demo riêng; D là dự phòng bài nộp, không đạt mục tiêu AI trên máy người nhận. Không dùng việc tắt enforcement hoặc nhúng token chung làm giải pháp release.

### 4.0 Quy trình chính cho hướng E

1. Trong Google Cloud Console của **đúng Firebase project**, kiểm tra quyền bật API/tạo Android-type reCAPTCHA key cho package hiện tại. Kiểm tra quota/tier/billing thực tế; bảng giá Google Cloud có điều kiện riêng cho Mobile SDK, nên không hứa mọi cấu hình mobile đều miễn phí. Nếu Console yêu cầu bật billing/nâng gói, ghi điều kiện và cần quyết định chi phí của chủ dự án trước; không tự bật.
2. Firebase Console > Security > App Check > Apps: cấu hình reCAPTCHA Enterprise cho app Android bằng key trên. Giữ enforcement Firebase AI Logic; dùng threshold khuyến nghị ban đầu, kiểm tra metrics nếu người dùng hợp lệ bị từ chối. Không bật replay protection nếu SDK/client chưa cấu hình limited-use token phù hợp.
3. Android release activate `AndroidReCaptchaProvider(siteKey)` sau Firebase init, trước khi tạo request AI; debug giữ `AndroidDebugProvider`. Provider được chọn rõ ràng, không âm thầm đổi sang debug khi attestation lỗi.
4. Tạo signing riêng, build đúng version, xác minh artifact và thử trên máy người nhận không có debug token. Tải APK qua link thực tế rồi cài/thử, thay vì chỉ chạy app qua Flutter CLI.
5. Nếu provider Preview không chạy hoặc điều kiện chi phí không phù hợp, ghi blocker cụ thể rồi đánh giá phương án khác trong task riêng. Không mở backend mới hoặc tự tắt App Check để làm demo thành công.

### 4.1 Điều kiện cho APK cài trực tiếp

- Play Integrity hỗ trợ cả phân phối ngoài Play. Trong Firebase App Check > Apps, policy cho app chỉ phân phối ngoài Play: không yêu cầu `PLAY_RECOGNIZED`, không yêu cầu `LICENSED`, yêu cầu Device integrity. Đây là cấu hình theo kênh phân phối, vẫn giữ App Check enforcement. Nếu phân phối cả hai kênh, dùng policy tương ứng trong tài liệu Firebase, không áp dụng máy móc policy sideload.
- Hoàn tất setup Play Integrity theo tài liệu, gồm liên kết đúng Cloud/Firebase project và quyền cần thiết. Không suy rằng APK sideload chỉ cần thêm provider vào Dart là chạy.
- SHA-256 **chứng thư ký** dùng để đăng ký app khác với SHA-256 **file APK** dùng để kiểm tra artifact. B1 dùng chứng thư ký APK trực tiếp; B2 dùng chứng thư Play App Signing của bản Play phân phối.
- Nhánh E dùng Android-type key cho đúng package và `AndroidReCaptchaProvider(siteKey)`. Site key là cấu hình client, không phải debug token hay server secret. Dependency hiện tại `firebase_app_check 0.4.8` đã export provider này và khai báo native reCAPTCHA; vẫn cần build/runtime proof. Chưa bật billing, nâng cấp dependency hoặc đổi policy trong bước plan.

### 4.2 Thứ tự thực hiện và đầu ra

| Bước | Việc sẽ thực hiện | Điều kiện qua bước |
|---|---|---|
| 1 | APK trực tiếp + Firebase Console đã chốt; preflight GCP/reCAPTCHA Android/quota/billing | Hướng E khả thi hoặc blocker cụ thể |
| 2 | Rà hai test modified với source; lưu baseline; tạo nhánh `codex/release-app-check` trước khi sửa sản phẩm nếu được giao triển khai | Không đảo/reset/stage các thay đổi có trước; xác định phạm vi sửa test với chủ dự án |
| 3 | Bảo vệ signing files, chọn chứng thư và cấu hình Console cho provider | Keystore ngoài Git; ghi loại policy/provider, không ghi bí mật |
| 4 | Activate App Check Android release sau Firebase init, trước AI; giữ debug provider cho debug | API đúng SDK; xử lý lỗi khởi tạo để có thông báo/retry phù hợp; không che lỗi bằng output giả |
| 5 | Format/analyze/test trên đúng working tree; kiểm tra release signing, manifest hợp nhất, `INTERNET` và version | Kiểm tra có kết quả thật; không dùng số 126/126 lịch sử thay thế |
| 6 | Build APK release hoặc AAB đúng kênh; kiểm tra chứng thư, version, size và checksum | Release không fallback debug key; artifact có provenance |
| 7 | Cài trên thiết bị người nhận chưa có debug token, thử AI và review/save/History | Request thật thành công; thêm một lần restart và kiểm tra refresh attestation khi phù hợp |
| 8 | Viết hướng dẫn cài/update/troubleshooting, kiểm tra link riêng tư và ghi worklog | APK + checksum + hướng dẫn + bằng chứng AI trên đúng build |

**Tệp sản phẩm dự kiến khi triển khai:** `lib/main.dart`, `.gitignore`, `android/app/build.gradle.kts`, `pubspec.yaml`; manifest chỉ sửa nếu kiểm tra release xác nhận thiếu quyền cần thiết. `gemini_report_service.dart` chỉ sửa khi có lỗi tái hiện liên quan provider/error mapping. README/worklog cập nhật sau kết quả thực thi; không mở rộng schema, storage hoặc tính năng khác.

**Đổi chứng thư ký:** bản debug đang cài có thể không update được bằng bản release ký keystore riêng dù package giống nhau. Không tự gỡ app/clear data để vượt lỗi vì có thể mất report cục bộ. Ưu tiên thiết bị khác cho cài mới; nếu phải chuyển máy đang dùng, chốt phương án bảo toàn dữ liệu trước. APK/AAB đưa qua Play có thể được Play ký lại; kiểm tra chứng thư thực tế, không dùng nhầm upload fingerprint.

### 4.3 Bộ nghiệm thu mục tiêu không cần debug token

- RELEASE-AI-01: đúng release provider được activate, không dùng debug provider hoặc token hardcode.
- RELEASE-AI-02: trên máy mới/chưa đăng ký debug token, cài đúng artifact qua đúng kênh; mô tả tổng hợp tạo draft thật.
- RELEASE-AI-02B: thử cùng APK trên ít nhất hai máy Android tương thích khác nhau chưa đăng ký debug token; người thử chỉ tải/cài/mở/nhập/bấm AI. Không dùng ADB hoặc quyền Console làm điều kiện sử dụng cho người nhận. Ghi máy/OS/build/provider và kết quả, không suy hai máy PASS thành mọi thiết bị PASS.
- RELEASE-AI-03: input và lỗi giữ nguyên khi mạng/App Check không hợp lệ; thông báo phân biệt attestation với quota/network/config. Không retry vòng lặp.
- RELEASE-AI-04: review/save/History hoạt động và report đọc lại sau restart. Ảnh/PDF/offline có case riêng; không tự đánh dấu đạt từ text-only.
- RELEASE-AI-05: APK có version/checksum/chứng thư đã kiểm tra; link tải dùng được; hướng dẫn không yêu cầu người nhận đăng ký debug token.
- RELEASE-AI-06: không có allowlist thiết bị thủ công hoặc đăng nhập bắt buộc; việc cấu hình production provider thực hiện ở cấp ứng dụng/project. Debug token tiếp tục chỉ phục vụ máy phát triển riêng.
- DEBUG-AI-01: máy phát triển dùng token đăng ký riêng; cài đè/restart được kiểm tra; token không nằm trong Git/APK chia sẻ.

Nếu RELEASE-AI-02 chưa đạt, mục tiêu phân phối APK dùng được AI **chưa hoàn thành**, kể cả build/install đã PASS hoặc có video.

## 5. Trình tự công việc

### Task 1 — Chốt mô hình phân phối và phạm vi App Check

1. Dùng quyết định đã có ở đầu plan: APK tải trực tiếp, người nhận dùng AI, có Firebase Console, chưa Play Console.
2. Xác minh GCP/reCAPTCHA Mobile/quota/billing; xác định signing riêng và thiết bị thử phù hợp mà không mất dữ liệu.
3. Ghi quyết định vào đầu file này trước khi sửa mã.

**Đầu ra:** mô hình phân phối + loại App Check đã chốt, gắn với HEAD.

#### Kết quả thực thi Task 1 — 01/10/2026

**Trạng thái: PARTIAL.** Đã chốt APK trực tiếp và yêu cầu không đăng ký debug token từng máy. E vẫn là **provider đề xuất có điều kiện**, chưa được xác nhận khả thi trên project thật; chưa chuyển sang Task 2.

| Gate | Kết quả vừa xác minh | Trạng thái |
|---|---|---|
| Phân phối | Người nhận tải APK, cài và gọi AI; không login hoặc allowlist thiết bị thủ công. Chủ dự án xác nhận có Firebase Console, chưa Play Console | CHỐT yêu cầu; quyền chưa được xác minh độc lập |
| Project/app | Code/config và ảnh Project settings do người dùng cung cấp cùng ghi `ai-field-assistant-7f9dc`, Android package `com.example.ai_field_assistant` | PASS local + ảnh Console |
| Provider/SDK | `firebase_app_check` lock 0.4.8 export `AndroidReCaptchaProvider`; native Gradle có `firebase-appcheck-recaptcha`; `main.dart` chỉ activate debug | PASS API tĩnh; chưa build/runtime |
| Quyền GCP/API/key | IAM có tài khoản cá nhân role Owner; reCAPTCHA API Enabled; ảnh Key details xác nhận key `ai-field-assistant-android-release` đã tạo, Integration Android app. Form trước đó đúng package/hỗ trợ ngoài Play; chưa có ảnh saved settings/fixed score | XÁC NHẬN API và key đã tạo qua ảnh; saved settings/mobile tier/runtime còn thiếu |
| Firebase App Check/AI enforcement | Ảnh Apps mới nhất: app Android `com.example.ai_field_assistant` Registered với Fraud Defense. Wizard trước đó baseline Enforced/replay Monitoring only; ảnh mới không hiển thị TTL/threshold hoặc xác nhận lưu wizard AI Logic | PASS đăng ký provider qua ảnh; saved TTL/threshold/replay và runtime chưa xác minh |
| Quota/billing | Project chưa liên kết billing. Ảnh Gemini API Enabled: request/ngày free tier `gemini-3.8-flash` giới hạn 20, usage 25, UI 100%; `gemini-3.5-flash-lite` giới hạn 500, usage 4, UI 0.8%. Chưa có quota/usage reCAPTCHA/mobile tier | XÁC NHẬN quota Gemini qua ảnh; primary đã vượt giới hạn hiển thị; reCAPTCHA/mobile còn thiếu |
| Signing | Release đang dùng debug signing; `android/key.properties` và keystore ở đường dẫn dự kiến chưa tồn tại; keytool không trên PATH nhưng có tại Android Studio JBR | Chưa tạo signing; tìm thấy tệp công cụ, chưa chạy |
| Máy kiểm thử | `adb devices`: 0 online/unauthorized/offline | Chưa có máy kết nối; không đủ gate thử trên hai máy mới |
| Bảo toàn dữ liệu | Không cài/gỡ/clear data, không đổi signing/provider, không reset/stash/checkout | PASS phạm vi Task 1 |

**Trở ngại Console:** ambient tab đang chỉ tới project StudyTrack, khác project trong repo. Automatic approval review từ chối chọn/đọc tab đó vì nội dung ngoài phạm vi AI Field Assistant; không đọc hoặc thay đổi StudyTrack. Phương án an toàn mở trực tiếp URL project đúng đã được thử nhưng công cụ trình duyệt lỗi `helper_unknown_error: setup refresh had errors`; sau reset một lần vẫn lỗi `trusted Node process exited unexpectedly`. Không có snapshot Console của project đúng được trả về. Đây là lỗi công cụ, không phải bằng chứng tài khoản thiếu quyền hoặc project chưa bật billing.

**Follow-up theo yêu cầu dùng skill computer-use (01/10/2026):** đã đọc SKILL, guidance, confirmations và API rồi thử initialize `@oai/sky` qua `node_repl`. Lần đầu lỗi `trusted Node process exited unexpectedly`; thử lại sau thông báo kernel reset lỗi `windows sandbox failed: helper_unknown_error: setup refresh had errors`. Chưa tới bước list apps/chọn cửa sổ/chụp Console, không có thao tác UI hoặc thay đổi cloud nào. Dừng retry theo hướng dẫn recovery của skill; các gate Console tiếp tục chưa xác minh. Cần khôi phục runtime computer-use hoặc kiểm tra Console thủ công để hoàn tất preflight.

**Follow-up với tab Browser được gắn trực tiếp:** sau reset, gọi `cua.getTab({mention: ...})` trên tab Google Cloud của AI Field Assistant vẫn lỗi `windows sandbox failed: helper_unknown_error: setup refresh had errors`, chưa trả về tài liệu UI. Tab Firebase người dùng gắn mang URL StudyTrack nên không dùng làm bằng chứng cấu hình AI Field Assistant. Kiểm tra local lại: `adb devices` vẫn 0 online/unauthorized/offline; chốt đường dẫn dự kiến giữ signing key là `C:\Users\khanh\ai-field-release.jks` ngoài repo (thư mục cha có sẵn, file chưa tồn tại). Chưa tạo key; nơi sao lưu riêng và hai máy clean-install còn cần chuẩn bị. Quyền/key/enforcement/quota/billing vẫn chưa xác minh; Task 1 chưa đóng.

**Bằng chứng mới từ sáu ảnh người dùng cung cấp:** ảnh 1 xác nhận project ID/package khớp source; ảnh 2 ghi Android app `Unregistered` và provider `-`, form Play Integrity chưa điền SHA-256; ảnh 3 có lựa chọn Fraud Defense (formerly known as reCAPTCHA Enterprise), Preview, site key trống. TTL 1 giờ đang nằm trong form chưa lưu, không phải cấu hình đã áp dụng. Ảnh 4 hiển thị Verified 153/153 (100%) trong khoảng ngày trên ảnh Sep 24–Oct 2, các nhóm unverified hiển thị 0; nhãn protection chỉ thấy `Basic - En...`, cần xem đầy đủ baseline/replay trước khi ghi Enforced chính thức. Ảnh 5/6 cùng thể hiện IAM có tài khoản cá nhân role Owner; không chép danh tính hoặc service account vào docs. Banner Start free không xác nhận project đã/chưa liên kết billing. Ảnh không có trang Android key/reCAPTCHA API/billing/quota. Đây là bằng chứng ảnh do người dùng gửi, không phải agent truy cập Console trực tiếp hoặc request AI mới. Verified requests không chứng minh APK release dùng AI trên máy chưa có debug token. Task 1 tiếp tục PARTIAL.

**Follow-up ba ảnh API/Billing/Baseline:** ảnh trang reCAPTCHA Enterprise API của project AI Field Assistant có nút Enable, xác nhận API chưa bật tại thời điểm ảnh. Billing ghi “This project has no billing account” và “This project is not linked to a billing account”. Wizard AI Logic bước Baseline protection chọn Enforced, phù hợp chỉ báo Basic - En...; chưa tới ảnh Replay protection hoặc Confirmation, không suy đã thay đổi/lưu cấu hình. Quota project và Android key vẫn chưa có bằng chứng. Task 1 tiếp tục PARTIAL.

**Ảnh Replay protection bổ sung:** wizard bước 2 đang chọn Monitoring only. Nội dung UI nói request tái sử dụng token chưa bị chặn, metrics được thu thập để xem tác động nếu enforce. Chưa có bằng chứng người dùng lưu Confirmation hoặc cấu hình replay đã được áp dụng; chỉ xác nhận lựa chọn trên form. Không yêu cầu chuyển Enforced hoặc lưu wizard trong Task 1 khảo sát. Android key/quota/mobile tier và thiết bị vẫn còn thiếu; Task 1 PARTIAL.

**Ảnh quota Gemini bổ sung:** đúng project AI Field Assistant, service `generativelanguage.googleapis.com` Status Enabled. Request limit per model per day for a project in the free tier: primary `gemini-3.8-flash` Value 20, Current usage 25, UI 100%; fallback `gemini-3.5-flash-lite` Value 500, usage 4, UI 0.8%. Đây là snapshot, không phải request AI mới hoặc bảo đảm còn quota khi dùng sau đó. Model primary đã vượt giới hạn hiển thị; chưa có lỗi quota mới được quan sát từ app trong phiên. Mã service đã có fallback sang lite khi lỗi được map thành ReportDraftQuotaException, không fallback mọi lỗi/App Check. Hai dòng input-token/ngày ghi Unlimited không làm quota request/ngày Unlimited. Chưa có quota theo phút/reCAPTCHA/mobile tier hoặc bằng chứng release AI. Không bấm Create credentials/Disable API/Start free để xử lý quota trong preflight.

**Ảnh sau bước người dùng bật API/mở form key:** reCAPTCHA Enterprise API đã Status Enabled, có nút Disable API; đây là thay đổi do người dùng thực hiện theo hướng dẫn, agent chưa thao tác Console. Form `ai-field-assistant-android-release` chọn Android, package `com.example.ai_field_assistant`, Disable package name verification tắt, Support applications distributed outside of the Google Play Store bật. Additional settings đang thu gọn nên chưa xác minh testing/fixed score. Chưa có bằng chứng Create key thành công, Firebase provider Registered, billing mới hoặc runtime release. Hướng dẫn mở Additional settings để giữ testing/fixed-score tắt trước khi người dùng Create key; nếu xuất hiện yêu cầu billing thì dừng để xem điều kiện, không tự link billing. Metrics không có dữ liệu với bộ lọc trên ảnh không chứng minh mobile runtime đã hoạt động.

**Ảnh Key details mới:** key tên `ai-field-assistant-android-release` đã tồn tại, có Integration Android app và thông báo Incomplete/request tokens, Scores chưa có dữ liệu cho khoảng chọn. Không ghi lại giá trị key ID vào docs; chưa có ảnh saved settings hoặc chứng minh runtime. Bước tiếp theo người dùng đăng ký key cho app Android trong Firebase App Check bằng Fraud Defense/reCAPTCHA Enterprise, TTL khuyến nghị 1 giờ và risk threshold khuyến nghị 0.5; giữ baseline/replay hiện có. Console Registered chưa thay thế Task 2 activate AndroidReCaptchaProvider trong Flutter/signing riêng/build/device proof. Chưa có bằng chứng Firebase Registered hoặc billing/quota Mobile mới; Task 1 còn PARTIAL.

**Ảnh Firebase Apps Registered mới nhất:** đúng app Android/package, Attestation provider Fraud Defense, Status Registered. Phần đăng ký production provider trên Console đã đạt; web app trong ảnh còn chưa đăng ký, ngoài phạm vi APK Android. Ảnh chưa hiển thị saved TTL/threshold/site-key mapping/settings hoặc runtime Mobile. Đọc lại `lib/main.dart` vẫn chỉ activate AndroidDebugProvider trong kDebugMode; chưa sửa code. Bước kế tiếp được đề xuất là Task 2 cấu hình AndroidReCaptchaProvider cho release, giữ debug nội bộ và không tự bật billing; chỉ triển khai khi người dùng giao task sửa mã. Signing/build/request thật trên máy mới là các gate tiếp theo, chưa hoàn tất mục tiêu phát APK dùng AI cho người nhận. Task 1 vẫn ghi PARTIAL cho các điều kiện/quota Mobile, saved settings và chuẩn bị thiết bị/bản sao signing chưa xác minh.

**Đối chiếu bổ sung:** [Prepare your environment](https://docs.cloud.google.com/recaptcha/docs/prepare-environment) ghi không cần bật billing để enable và bắt đầu dùng Fraud Defense nói chung; do đó thiếu billing không chứng minh nút Enable API sẽ bị chặn. Điều kiện Mobile SDK/tier vẫn phải kiểm tra riêng theo bảng giá và Console; chưa kết luận chạy Android miễn phí lâu dài. Khi được giao setup Android key cho APK sideload, kiểm tra tùy chọn “Support applications distributed outside of the Google Play Store” theo [hướng dẫn mobile key](https://docs.cloud.google.com/recaptcha/docs/create-key-mobile), giữ xác minh package, không chọn testing key fixed-score để nghiệm thu release. Chưa enable API hoặc tạo key trong Task 1 này.

**Đối chiếu điều kiện chi phí:** tài liệu Firebase Flutter mô tả reCAPTCHA trên Spark với một tập score giới hạn; bảng tier Google Cloud ghi Mobile SDK chỉ ở Premium/Enterprise, Premium cần billing instrument. Hai tài liệu nói các khía cạnh khác nhau và không chứng minh project này đang được dùng miễn phí hoặc buộc phải nâng Blaze. Phải xem điều kiện thực tế của project/API/mobile key trước khi quyết định chi phí. Provider Flutter đang Preview và risk threshold có thể từ chối môi trường; không có cam kết mọi máy đều PASS chỉ vì có APK. Nguồn chính thức ở mục 11.

**Phần phải hoàn tất để đóng Task 1 (chỉ đọc/ghi nhận, không tự bật billing):**

1. Mở [Firebase đúng project](https://console.firebase.google.com/project/ai-field-assistant-7f9dc/overview), kiểm tra Android app đúng package; Security > App Check > Apps/APIs: provider hiện tại và enforcement AI Logic. Không mở/copy danh sách giá trị debug token.
2. Mở [Google Cloud reCAPTCHA đúng project](https://console.cloud.google.com/security/recaptcha?project=ai-field-assistant-7f9dc), kiểm tra IAM/quyền, API đã bật hay chưa, Android key hiện có và package. Ghi key type/trạng thái; không sao chép credential/server secret.
3. Xem Billing/Quotas/Usage, ghi tier, quota và điều kiện Mobile SDK đang áp dụng. Nếu phải liên kết billing/nâng gói, trình chủ dự án điều kiện cụ thể trước khi phát sinh chi phí; budget alert không được coi là giới hạn chi tiêu cứng.
4. Đã chọn đường dẫn dự kiến ngoài repo `C:\Users\khanh\ai-field-release.jks`; chưa tạo key hoặc bản sao. Cần chốt nơi sao lưu riêng an toàn và chuẩn bị hai máy Android tương thích cho clean install, ưu tiên máy không có dữ liệu app cần bảo toàn. Máy đang có report không được tự uninstall/clear data.
5. Khi có bằng chứng Console và quyết định chi phí hợp lệ, cập nhật gate và chốt E hoặc ghi blocker/phương án khác. Không sửa `main.dart` chỉ dựa trên việc class provider có trong SDK.

**Lệnh/kiểm tra đã chạy:** Git status/branch/HEAD/diff; đọc source/config và SDK cache; `Test-Path` signing/keytool; `Get-Command keytool`; `git check-ignore` trên tên đường dẫn kiểm tra (không tạo file); `adb devices` lọc số lượng; SHA-256 các tệp có trước để bảo toàn. `keytool` chỉ kiểm tra tồn tại, chưa chạy sinh khóa. Không chạy formatter, analyzer, test, build, request AI hoặc xác minh remote Git; các số test/APK trong worklog cũ vẫn là lịch sử.

### Task 2 — Sửa App Check cho bản release (thay đổi mã sản phẩm)

#### Phạm vi triển khai được giao — 01/10/2026

- Người dùng chọn rõ **Release Task 2**, không phải Task 2 Day 7 build/demo. Baseline `6bb3a1e`; nhánh triển khai `codex/release-app-check`, giữ nguyên hai test modified và checklist untracked có trước.
- Chọn hướng E ở mức mã nguồn dựa trên bằng chứng Android Fraud Defense Registered và API đã có trong SDK. Đây chưa phải kết luận provider chạy được trên project/thiết bị; Task 1 vẫn PARTIAL ở saved settings/quota Mobile và chuẩn bị thiết bị/signing. Yêu cầu triển khai lần này cho phép chuẩn bị mã, không cho phép tự bật billing hoặc đổi Console.
- Thay đổi dự kiến: `main.dart`, helper khởi tạo App Check và màn chờ/lỗi khởi tạo có retry; test mới cho cấu hình, chặn mở app khi khởi tạo thất bại và retry. Giữ service AI/error mapping, schema, storage, dependency và signing.
- Android debug dùng Debug provider; Android profile/release dùng reCAPTCHA với site key công khai từ `--dart-define=APP_CHECK_ANDROID_SITE_KEY=...`. Thiếu key thì báo lỗi khởi tạo, không fallback debug. Web debug giữ nguyên; web production ngoài phạm vi.
- Kiểm tra: format các tệp mới/đổi, analyze, test mới + service/parser; có thể chạy suite để ghi rõ lỗi từ hai test có trước nhưng không sửa chúng. Không build release, tạo signing key hoặc thử AI trong Task 2.
- Một build debug đã khởi động trước khi người dùng trả lời lựa chọn Task 2; đã dừng sau khi nhận lựa chọn Release (exit 1), không có artifact PASS từ lượt đó. Không dùng artifact cũ làm bằng chứng mới.

#### Kết quả thực thi Task 2

- `lib/main.dart`: AppBootstrap chờ Firebase rồi initializeAppCheck trước xây app/services; retry sử dụng Firebase app đã khởi tạo. Helper mới chọn provider theo platform/build mode và trim site key công khai từ APP_CHECK_ANDROID_SITE_KEY; key rỗng hoặc activate lỗi được truyền tới startup UI, không fallback debug. Không gọi getToken để coi activate là bằng chứng attestation.
- `lib/widgets/app_bootstrap.dart`: loading, thông báo khởi tạo lỗi chung không lộ lỗi thô, retry một attempt; appBuilder chưa chạy nếu init pending/fail. `lib/services/app_check_initializer.dart` giữ web debug, không mở production web/Apple. Không sửa service AI/error mapping, signing, dependency, schema hoặc storage.
- 9 test mới: provider/config thiếu, lỗi không fallback, ranh giới web/non-Android, app không xây trước init, failure/retry và lỗi synchronous. Test lần đầu phát hiện callback setState trả Future; đổi sang callback void và test lại đạt.
- `dart format` trên 5 tệp mới/đổi; `flutter --suppress-analytics analyze --no-pub`: PASS, No issues (26.6 giây). `flutter --suppress-analytics test --no-pub test/app_check_initializer_test.dart test/app_bootstrap_test.dart test/gemini_report_service_test.dart test/report_draft_test.dart --reporter expanded`: PASS, 52/52 sau sửa retry.
- `flutter --suppress-analytics test --no-pub --reporter expanded`: 133 PASS/2 FAIL, exit 1. Fail: detail `loads the selected report and shows confirmed details` thiếu scroll tới suggested_action; widget `trong lúc phân tích: hiện loading, khóa nút, giữ input` cast FilledButton thay vì OutlinedButton. Cả hai ở test modified có trước, Task 2 không đổi những vùng UI/test đó; giữ nguyên và không tuyên bố suite sạch.
- Trạng thái: **hoàn tất phần mã + kiểm tra liên quan của Task 2**; full-suite chưa sạch do hai lỗi nêu trên. Chưa build/cài release, chưa cấp token hoặc gọi AI thật; site key thực tế cần được người build truyền đúng từ Console. Quota/billing/saved settings còn theo gate Task 1; không tự enable/link billing. Không chuyển Task 3–6 trong lượt này.

1. Sửa `lib/main.dart` để activate App Check trên Android cho debug và release, chọn provider theo build mode/kênh đã chốt (dùng class provider của `firebase_app_check` 0.4.8):
   - `kDebugMode` → `AndroidDebugProvider()` (và `WebDebugProvider()` nếu vẫn test web).
   - bản release B1/B2 → `AndroidPlayIntegrityProvider()`; nhánh E → `AndroidReCaptchaProvider(siteKey)`.
   - (Web production cần `ReCaptchaEnterpriseProvider` với site key công khai — **ngoài phạm vi** trừ khi chủ dự án yêu cầu.)
2. Giữ nguyên hành vi ánh xạ lỗi App Check trong `gemini_report_service.dart`.
3. Chạy format/analyze/test liên quan; ghi rõ thay đổi này **chưa** được xác minh trên thiết bị cho tới Task 6.
4. Nếu preflight provider release chưa đạt, giữ nguyên code và ghi blocker. Hướng A/D chỉ dùng demo nội bộ, không thay thế mục tiêu AI trên máy người nhận.

**Đầu ra:** diff `main.dart` nhỏ, có ghi chú rõ debug vs release; hoặc quyết định hoãn kèm lý do.

### Task 3 — Keystore và signing cho release

1. Xác minh lại quy tắc ignore theo vị trí signing files trước khi tạo: `android/.gitignore` đã có quy tắc trong cây Android; bổ sung root `.gitignore` nếu cần bảo vệ keystore ngoài cây Android. Keystore phát hành đặt ngoài repo.
2. Tạo keystore phát hành (ngoài repo, **không** commit):
   ```powershell
   keytool -genkeypair -v -keystore $env:USERPROFILE\ai-field-release.jks `
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
3. Tạo `android/key.properties` (không commit) trỏ tới keystore, alias và mật khẩu.
4. Sửa `android/app/build.gradle.kts`: đọc `key.properties` và dùng `signingConfigs.release`; nếu thiếu cấu hình khi build release, dừng với lỗi rõ ràng. Debug build vẫn dùng debug key, không âm thầm ký release bằng debug key.
5. Sao lưu keystore + mật khẩu ở nơi an toàn ngoài repo (mất keystore = không thể cập nhật app trên Play sau này).

**Đầu ra:** cấu hình signing release tách khỏi debug, không có bí mật trong Git.

### Task 4 — Build APK, version và checksum

1. Bump `version` trong `pubspec.yaml` (ví dụ `0.1.0+1` → `0.2.0+2` hoặc `1.0.0+3`) cho bản nộp.
2. Build:
   ```powershell
   flutter build apk --release --no-pub "--dart-define=APP_CHECK_ANDROID_SITE_KEY=<ANDROID_SITE_KEY_PUBLIC>"
   # (tùy chọn) flutter build apk --release --split-per-abi --no-pub "--dart-define=APP_CHECK_ANDROID_SITE_KEY=<ANDROID_SITE_KEY_PUBLIC>"
   # (tùy chọn cho Play) flutter build appbundle --release --no-pub "--dart-define=APP_CHECK_ANDROID_SITE_KEY=<ANDROID_SITE_KEY_PUBLIC>"
   ```
3. Ghi version, kích thước, SHA-256, cảnh báo build; đối chiếu artifact đích với output.
4. **Không commit** APK/AAB vào Git; lưu ở thư mục ngoài repo hoặc kênh phân phối.

**Đầu ra:** `build/app/outputs/flutter-apk/app-release.apk` (hoặc split ABI), kèm version + hash + ghi chú "release đã ký bằng keystore nào (không nêu mật khẩu)".

### Task 5 — App Check debug token: quy trình đăng ký và phục hồi (hướng A)

**Cơ chế:** bản debug dùng `AndroidDebugProvider`, SDK sinh một **debug token** cho từng lần cài app; token phải được đăng ký trong Firebase Console thì request AI mới được chấp nhận.

**Đăng ký lần đầu**

1. Chạy app debug trên thiết bị đúng (`flutter run -d <device>`), hoặc đọc log:
   ```powershell
   adb logcat | Select-String "App Check debug token"
   ```
2. Mở **Firebase Console → App Check → Apps → chọn app Android → Manage debug tokens → Add token**, dán token và đặt tên gợi nhớ (ví dụ tên thiết bị).
3. **Không** ghi giá trị token vào file/Git/chat/ảnh chụp. Chỉ ghi "đã đăng ký token cho thiết bị X ngày Y".
4. Mở lại app và thử AI một lần với dữ liệu tổng hợp.

**Tránh và phục hồi lỗi "thiếu debug token"**

- Token có thể cần đăng ký lại khi gỡ/cài lại, xóa dữ liệu hoặc đổi máy; không coi keystore là nguồn sinh debug token. Đổi signing key có thể gây lỗi update và dẫn tới cài mới. Cài đè cùng package/chứng thư thường giữ app data/token; luôn kiểm tra token của lần cài hiện tại nếu App Check vẫn báo lỗi.
- Biểu hiện: UI hiện thông báo App Check (`ReportDraftAppCheckException`); log có `403 ... App attestation failed`.
- Xử lý: lấy token hiện tại (bước 1) → đăng ký lại trong Console → thử lại. **Không** retry liên tục, **không** bật billing để "vượt".
- Quy tắc demo: đăng ký token của **đúng thiết bị dùng để quay/trình diễn** và **không cài lại** sau khi đăng ký; nếu buộc cài lại, lặp lại quy trình.
- Trước demo: kiểm tra đúng Firebase project/app đang được dùng (bản clone với project khác phải `flutterfire configure` lại).
- **Không** hardcode token vào `main.dart` hay bất kỳ file nào.

**Đầu ra:** hướng dẫn ngắn gọn, không chứa token; trạng thái "AI chạy được trên thiết bị demo" có bằng chứng quan sát.

### Task 6 — Kiểm chứng AI trên đúng build

1. Nếu theo hướng A: cài APK debug đúng HEAD, đăng ký token, chạy một request thật với dữ liệu tổng hợp; xác nhận mở được màn "Bản nháp AI".
2. Với B1/E: thử APK cài trực tiếp trên máy chưa đăng ký debug token. Với B2: thử từ Play internal testing. Xác nhận AI thực tế, đối chiếu metrics App Check đã khử nhạy cảm; không in token. Nếu thất bại, ghi `BLOCKED` và xử lý đúng provider/policy/chứng thư thay vì chuyển người nhận sang token chung.
3. Ghi kết quả vào phiếu kiểm thử (`docs/testcase_day7.txt` nếu có) kèm APK hash, model Android, thời điểm; **không** ghi token/prompt/response đầy đủ.
4. Nếu App Check/quota chặn, ghi `BLOCKED` trung thực và dùng nhánh demo dự phòng.

**Đầu ra:** một bằng chứng AI thật gắn với đúng build, hoặc `BLOCKED` có lý do.

### Task 7 — Hướng dẫn phân phối cho người nhận

1. Soạn hướng dẫn cài ngắn (README mục "Chạy và cài APK" hoặc `docs/RELEASE_NOTES.md`): nguồn APK, version, cách bật "Cài từ nguồn không xác định", yêu cầu Android tối thiểu.
2. Người nhận chỉ tải/cài/mở và dùng AI với Internet, không lấy/đăng ký debug token. Nếu APK release báo App Check, ghi lỗi provider/config/device và hướng dẫn báo lỗi cho chủ dự án; không chuyển người nhận sang đăng ký token thủ công để đánh dấu release đạt.
3. Kiểm tra link tải trong cửa sổ riêng tư/thiết bị khác; xác nhận mở được và checksum khớp.
4. Không đưa token/keystore/mật khẩu vào hướng dẫn.

**Đầu ra:** hướng dẫn cài + link đã kiểm tra + checksum.

### Task 8 — Tài liệu, bảo mật và dọn dẹp

1. Cập nhật `README.md`: mục build/install, trạng thái signing (debug key hay keystore riêng), giới hạn App Check, phân biệt debug vs release.
2. Thêm entry vào `docs/AI_WORKLOG.md`: công cụ, việc đã làm, App Check đã cấu hình ở mức nào, kết quả thật, giới hạn.
3. Rà `.gitignore` và `git status` xác nhận **không** có `key.properties`, `*.jks`, `*.keystore`, APK, token trong diff.
4. Rà lại tài liệu để không tuyên bố "AI chạy trên mọi máy" hoặc "production-ready" khi chưa có provider production đã kiểm chứng trên kênh APK trực tiếp và release signing riêng.

**Đầu ra:** tài liệu khớp build, không rò bí mật, Git sạch ngoài phạm vi.

## 6. Điều kiện nghiệm thu

- [x] Kênh APK trực tiếp + AI trên máy người nhận đã chốt; E là hướng đề xuất chính.
- [ ] Preflight quyền GCP/key/quota/billing xác nhận E khả thi; provider release được nghiệm thu trên thiết bị.
- [ ] APK release có version + SHA-256; cài được; **không** commit vào Git. APK debug nội bộ không đáp ứng nghiệm thu phân phối cho người nhận.
- [ ] Bản release B1/B2/E có signing riêng được kiểm tra và không có bí mật trong repo; A/D chỉ là demo, không nghiệm thu release dùng AI cho người nhận.
- [ ] `main.dart` kích hoạt provider đúng theo build mode/kênh B1/B2/E, hoặc quyết định hoãn có lý do (A/D).
- [ ] Quy trình đăng ký/phục hồi debug token được ghi lại, **không** chứa giá trị token.
- [ ] Có bằng chứng AI chạy trên đúng build (hoặc `BLOCKED` với lý do), chỉ dùng dữ liệu tổng hợp.
- [ ] Hướng dẫn cài cho người nhận + lưu ý App Check đã có; link đã kiểm tra quyền truy cập.
- [ ] README/worklog khớp thực tế; không rò token/keystore/mật khẩu.

## 7. Ranh giới bằng chứng

| Việc | Chứng minh được | Không chứng minh được |
|---|---|---|
| Build APK exit 0 | Compile/đóng gói, chữ ký | App chạy, AI hoạt động |
| Cài APK + mở form | App cài/chạy trên máy đó | AI/App Check/quota |
| Một request AI thật thành công | Dịch vụ + App Check + quota tại thời điểm đó | Ổn định lâu dài, mọi máy |
| Debug token đã đăng ký | Máy đã đăng ký chạy được | Máy chưa đăng ký cũng chạy được |
| Console/provider đã cấu hình | Có setup để kiểm chứng | AI trên mọi máy hoặc trên kênh phân phối chưa thử |

## 8. Rủi ro và phương án dự phòng

| Rủi ro | Phương án |
|---|---|
| Debug token đổi sau cài lại/clear data | Đăng ký lại (Task 5); tránh cài lại sau khi đăng ký; dùng `install -r` |
| Release build không kích hoạt provider → AI lỗi | Task 2 activate provider đã qua preflight (E: `AndroidReCaptchaProvider`); debug chỉ cho demo nội bộ |
| Play Integrity không đạt với APK sideload | Kiểm tra policy ngoài Play, chứng thư/project/device; hoặc đánh giá E/B2. Không hứa mọi máy đạt attestation |
| Chưa có keystore, không kịp tạo | Dùng debug key cho demo và ghi rõ "không phải bản production" |
| Quota free tier cạn khi demo | Fallback model lite; hoặc chờ reset; không bật billing tự ý |
| Hết thời gian (deadline 23:59 01/10) | Ưu tiên: bằng chứng AI trên máy demo + video + APK cài được > cấu hình Play Integrity đầy đủ |
| Nghi ngờ rò token/keystore | Dừng, kiểm tra diff/`.gitignore`, xoay token/keystore nếu cần; không copy giá trị vào chat |

## 9. Lệnh dự kiến (chưa chạy trong phiên lập kế hoạch)

```powershell
# Keystore (một lần, ngoài repo)
keytool -genkeypair -v -keystore $env:USERPROFILE\ai-field-release.jks `
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Lấy debug token trên thiết bị (không lưu giá trị)
adb logcat | Select-String "App Check debug token"

# Build
flutter build apk --release --no-pub "--dart-define=APP_CHECK_ANDROID_SITE_KEY=<ANDROID_SITE_KEY_PUBLIC>"
flutter build apk --release --split-per-abi --no-pub "--dart-define=APP_CHECK_ANDROID_SITE_KEY=<ANDROID_SITE_KEY_PUBLIC>"
flutter build appbundle --release --no-pub "--dart-define=APP_CHECK_ANDROID_SITE_KEY=<ANDROID_SITE_KEY_PUBLIC>"

# Checksum
Get-FileHash build\app\outputs\flutter-apk\app-release.apk -Algorithm SHA256

# Cài đè giữ dữ liệu (debug)
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

## 10. Quyết định đã có và điều kiện cần xác minh khi triển khai

- Đã có: APK tải trực tiếp, người nhận dùng được AI; chủ dự án có Firebase Console, chưa Play Console.
- Đã có bằng chứng ảnh: IAM Owner, Android key đã tạo và Firebase Fraud Defense Registered. Cần xác minh tiếp: saved settings, điều kiện/quota Mobile, nơi sao lưu signing key và máy thử cài mới; billing trong ảnh gần nhất chưa được liên kết.
- Nếu chuyển từ debug signing sang release signing trên máy đang có report, phải chốt bảo toàn dữ liệu trước; không tự uninstall/clear data.

> Yêu cầu release lần này mở phạm vi release/App Check ngoài feature freeze cũ. Đã thực hiện phần local/ảnh Console của Task 1 và triển khai mã Task 2 theo lựa chọn mới của người dùng; công cụ truy cập Console trực tiếp còn lỗi. Chưa có build release hoặc request AI mới. Không suy các gate Task 1 còn thiếu đã đạt từ host tests.

## 11. Nguồn đối chiếu ngày 01/10/2026

- [Firebase: Play Integrity và policy phân phối trong/ngoài Google Play](https://firebase.google.com/docs/app-check/android/play-integrity-provider).
- [Firebase: reCAPTCHA Enterprise Flutter/Android, Preview và chi phí assessment](https://firebase.google.com/docs/app-check/flutter/recaptcha-enterprise-provider).
- [Firebase: debug provider, đăng ký token và giới hạn sử dụng](https://firebase.google.com/docs/app-check/flutter/debug-provider).
- [Firebase AI Logic: enforcement và production attestation](https://firebase.google.com/docs/ai-logic/app-check).
- [Flutter: signing, APK/AAB và release Android](https://docs.flutter.dev/deployment/android).
- [Google Cloud: bảng giá/tier reCAPTCHA, điều kiện Mobile SDK](https://cloud.google.com/security/products/recaptcha#pricing).
- Source hiện tại: `lib/main.dart`, `lib/firebase_options.dart` (chỉ đối chiếu project ID), `android/app/google-services.json` (chỉ đọc project/package), `android/app/build.gradle.kts`, `pubspec.yaml`, `.gitignore`, `android/.gitignore`. Pub cache `firebase_app_check 0.4.8` xác nhận export provider Android và dependency native reCAPTCHA. Ảnh người dùng cung cấp xác nhận project/API/key/Registered và quota Gemini tại thời điểm chụp; chưa kiểm tra Console trực tiếp hoặc request AI từ APK release.
