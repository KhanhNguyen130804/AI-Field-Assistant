# Kế hoạch triển khai — Ngày 5: Độ tin cậy, kiểm thử lỗi và hoàn thiện UX

> **Trạng thái:** Task 1 đã hoàn tất preflight; Task 2 kiểm tra được picker/preview nhưng persistence ảnh và offline còn BLOCKED; Task 3 đã triển khai và kiểm thử service/parser ngày 29/09/2026; Task 4 hoàn tất kiểm tra host ngày 30/09/2026 (full suite 117/117, analyzer sạch); Task 5 đã rà call site, dữ liệu/log và bỏ log exception SDK thô ngày 30/09/2026; Task 6 kiểm tra host đạt ngày 30/09/2026 nhưng kiểm tra Android chưa chạy vì build APK bị automatic approval review từ chối. Còn xác minh API restrictions trong Console; Firebase App Check debug provider vẫn ghi debug token vào log cục bộ. Task 7 tính năng cộng thêm chưa thực hiện. Ngày 4 Task 7 được chủ dự án đóng với ngoại lệ được chấp nhận; đây không phải nghiệm thu đầy đủ Ngày 4.
>
> **Baseline theo hồ sơ ngày 29/09/2026:** `flutter analyze` sạch, `flutter test` 99/99, SQLite FFI 10/10 và APK debug build thành công. Trên Android đã kiểm chứng một report text-only qua save → History → detail → force-stop/relaunch. Đây là kết quả lịch sử, không phải kiểm tra mới của kế hoạch này. Lưu/đọc report có ảnh trên Android và save/read offline chưa được xác minh.
>
> **Nguồn phạm vi:** `AGENTS.md`, Ngày 5 trong `docs/CHALLENGE_VI_ROADMAP.md`, mã nguồn hiện tại, `docs/AI_WORKLOG.md` và các phiếu Task 4–7. Giữ Flutter/Firebase AI Logic và schema hiện có. Không thêm voice-to-text/GPS trước khi luồng P0 ổn định.

## 1. Mục tiêu và kết quả mong đợi

Ngày 5 làm cho luồng MVP chịu được các lỗi thường gặp mà vẫn giữ quyền kiểm soát cho người dùng:

1. Đầu vào rỗng, ảnh không hợp lệ hoặc quá lớn bị chặn trước khi gửi.
2. Request AI có loading, timeout, lỗi dễ hiểu và retry chủ động.
3. Khi AI lỗi, mô tả và ảnh vẫn còn; khi AI thành công, kết quả vẫn là draft cần người dùng review.
4. Lỗi lưu cục bộ không làm mất editor, không gọi AI lại và không tạo report trùng khi retry.
5. Hành vi privacy, log và UX điện thoại được đối chiếu với mã và bằng chứng thực tế.
6. Các ngoại lệ persistence ảnh/offline từ Ngày 4 được kiểm tra nếu điều kiện thiết bị an toàn đáp ứng; nếu không thì ghi rõ `BLOCKED` hoặc `NOT RUN`.

Luồng cần giữ:

```text
Nhập mô tả / chọn ảnh
  → validation tại form và service
  → người dùng bấm “Phân tích bằng AI”
  → loading
      ├─ thành công: mở draft chưa xác nhận, chưa lưu
      └─ lỗi: hiện hướng dẫn, giữ nguyên đầu vào, cho người dùng retry
  → review/chỉnh sửa/xác nhận
  → lưu cục bộ bằng repository Android
  → History → detail
```

**Không thuộc mục tiêu Ngày 5:** đăng nhập, đồng bộ cloud, push, dashboard, backend mới, thay model/quota/billing, release signing hoặc thêm đồng thời nhiều tính năng cộng thêm.

## 2. Hiện trạng và ranh giới bằng chứng

- `GeminiReportService` hiện đặt timeout 60 giây, giới hạn ảnh gửi AI ở 4 MiB, dùng `responseSchema`, parse draft và ánh xạ lỗi timeout, quota, App Check, cấu hình, response và dịch vụ. Có primary model và fallback khi primary hết quota.
- Service tests dùng fake sender; widget tests dùng fake service/repository. Chúng xác minh logic app nhưng **không** chứng minh mạng, Gemini, App Check production hoặc plugin Android thật.
- Form có giới hạn ảnh 10 MiB sau picker; giới hạn gửi AI thấp hơn ở 4 MiB. Không đánh đồng hai giới hạn này.
- Repository SQLite chạy trên Android; test repository dùng SQLite FFI trên host Windows. FFI không thay thế kiểm tra `sqflite`/`path_provider` trên Android.
- Task 7 đã chứng minh một report text-only tồn tại sau process restart. Chưa có bằng chứng lưu/đọc ảnh sau restart hoặc save/read offline trên Android.
- Worklog ghi model thực tế của request Task 7 không được xác nhận độc lập. Không ghi model thành công của một request cụ thể chỉ dựa vào cấu hình trong source.
- Kiểm tra manual APK cũ, kết quả người dùng tự báo và test tự động phải tiếp tục được ghi thành các nguồn riêng; không nâng chúng thành kết quả vừa chạy.

## 3. Nguyên tắc thực hiện

1. Trước mỗi lát công việc, xem lại `git status`, diff và test liên quan. Bảo toàn toàn bộ thay đổi có trước, kể cả file chưa theo dõi hoặc file bị xóa; không reset, clean, stash, checkout hay stage ngoài phạm vi được yêu cầu.
2. Đối chiếu test hiện có trước khi thêm. Chỉ bổ sung test cho khoảng trống hoặc lỗi vừa xác định, không nhân bản coverage.
3. Dùng fake cho parser, timeout, lỗi server, App Check, quota và retry khi không cần kiểm chứng dịch vụ thật.
4. Dữ liệu kiểm tra Gemini/Android phải là dữ liệu tổng hợp. Mặc định không phát sinh request Gemini mới; nếu cần request thật để trả lời một câu hỏi cụ thể, giới hạn số lần, ghi mục đích và trạng thái quota/App Check, không lưu prompt/response hoặc log thô.
5. Không đọc database riêng tư, không dùng `run-as`, không gỡ app hoặc xóa dữ liệu để tạo trạng thái sạch, không chọn media cá nhân.
6. Không ngắt Wi-Fi khi ADB Wireless là kênh điều khiển duy nhất. Nếu không có kênh điều khiển độc lập, giữ nguyên mạng và ghi case offline là `BLOCKED`/`NOT RUN`.
7. Mã nguồn chứng minh hành vi được triển khai; chỉ test/runtime evidence chứng minh mức kiểm tra tương ứng. APK build thành công không chứng minh thiết bị, dịch vụ AI hoặc persistence hoạt động.

## 4. Thứ tự công việc

### Task 1 — Preflight và baseline trên đúng source

**Mục tiêu:** gắn mọi kết quả Ngày 5 với đúng working tree, source và APK.

**Các bước**

1. Ghi nhánh, HEAD, upstream và `git status --short --branch`; xác định file staged, modified, deleted và untracked. Không đưa thay đổi có trước vào scope.
2. Đọc lại `AGENTS.md`, plan Day 5, test record gần nhất và các vùng code dự kiến kiểm tra.
3. Xác nhận Flutter/Dart, Android SDK/platform-tools, thiết bị và cách điều khiển đang sẵn sàng. Chỉ tiếp tục ADB khi thiết bị đúng trạng thái `device`; không ghi serial/IP/pairing code vào tài liệu chia sẻ.
4. Chạy format check, analyzer, full test suite và repository test trên source baseline. Ghi chính xác lệnh, exit code, số test và cảnh báo. Không xem số liệu trong tài liệu lịch sử là kết quả của lượt này.
5. Nếu Android/SDK sẵn có, build APK debug từ source hiện tại; ghi version và SHA-256. Cài đè bằng `adb install -r` nếu phù hợp, không gỡ app/xóa dữ liệu.

**Tiêu chí hoàn tất:** baseline và giới hạn môi trường được ghi rõ; nếu Flutter, ADB hoặc thiết bị không sẵn sàng, đánh dấu phần tương ứng `BLOCKED`, rồi tiếp tục phần test host độc lập.

### Task 2 — Carry-over persistence Ngày 4

**Mục tiêu:** bổ sung bằng chứng Android cho ảnh và hành vi repository offline, không đọc vùng riêng tư của app.

#### 2.1 Lưu và đọc lại ảnh

1. Dùng fixture ảnh tổng hợp do dự án chuẩn bị, không dùng thư viện ảnh cá nhân.
2. Xác nhận fixture thực sự hiện trong Android Photo Picker. Nếu không hiện, dừng case; không chuyển sang ảnh người dùng hoặc dùng cách vượt quyền truy cập.
3. Nếu chọn được fixture, tạo tối đa một report test có ảnh bằng luồng UI, review và xác nhận lưu.
4. Mở report từ History/detail, xác nhận ảnh hiển thị; force-stop/mở lại app và xác nhận lại report cùng ảnh.
5. Chỉ ghi đúng phần đã thấy: chọn ảnh/preview, save, đọc trước restart, đọc sau restart. Không suy rộng một lần chạy thành cam kết cho mọi ảnh.

#### 2.2 Local save/read khi offline

1. Không gọi AI để kiểm tra storage. Tạo draft tổng hợp khi đang có mạng nếu cần; sau đó dùng report đã xác nhận hoặc thao tác UI không cần request mới.
2. Chỉ tắt mạng khi có tương tác vật lý hoặc kênh điều khiển độc lập với Wi-Fi. Nếu ADB Wireless là kênh duy nhất, không thay đổi trạng thái mạng.
3. Khi offline, kiểm tra riêng các thao tác cần đánh giá (save draft đã tạo, mở History, mở detail và đọc ảnh nếu ảnh đã lưu). Ghi thao tác nào chạy được và thao tác nào chưa chạy.
4. Bật lại mạng bằng đúng kênh đã tắt; xác nhận trạng thái thiết bị phục hồi trước khi kết thúc phiên.

**Tiêu chí hoàn tất:** mỗi case có `PASS`, `FAIL`, `PARTIAL`, `BLOCKED` hoặc `NOT RUN`, môi trường và bằng chứng tối thiểu. Không truy cập file database qua ADB. Nếu thiết bị/fixture không đáp ứng, ghi nguyên nhân và chuyển sang Task 3; không để blocker dừng test fake/widget độc lập.

### Task 3 — Audit và kiểm tra service/parser

**Mục tiêu:** xác minh input/response lỗi được từ chối an toàn và lỗi được ánh xạ đúng.

**Trước khi thêm test:** rà `test/gemini_report_service_test.dart`, `test/report_draft_test.dart` và `lib/models/report_draft.dart`. Các nhánh đã có coverage gồm input rỗng, ảnh rỗng/quá giới hạn/sai loại, JSON rỗng/sai/root sai, `needs_confirmation` thiếu, `priority: null`, timeout, lỗi server, App Check, quota và fallback.

| Nhóm | Ca cần xác nhận | Kỳ vọng |
|---|---|---|
| Input | Mô tả và ảnh đều rỗng | Báo lỗi validation; sender không được gọi. |
| Input | Ảnh đúng 4 MiB và quá giới hạn 1 byte | Đúng ngưỡng được chuyển cho fake sender; quá ngưỡng bị từ chối trước khi gửi. |
| Input | Bytes rỗng, MIME/signature không hỗ trợ hoặc đọc file lỗi | Lỗi input phù hợp; không có request; form không mất mô tả/ảnh trước đó. |
| Response | `null`, chuỗi rỗng, JSON sai hoặc root không phải object | Chuyển thành lỗi response đã định nghĩa; không crash. |
| Schema | Field text sai kiểu, `priority` lạ, confirmation list sai kiểu/field lạ | Không dùng response sai; ánh xạ lỗi response rõ ràng. |
| Schema | Field hợp lệ bị thiếu, `priority: null`, thiếu `needs_confirmation` | Tuân theo contract hiện tại: dữ kiện thiếu vẫn để trống/null và yêu cầu người dùng xác nhận khi cần. |
| Lỗi dịch vụ | Timeout, lỗi mạng/server, App Check, cấu hình, quota | Đúng exception/user message; fallback chỉ chạy khi primary lỗi quota. |

**Quyết định contract:** `ReportDraft.fromJson` cần được đọc trực tiếp trước khi chốt kỳ vọng cho field thiếu hoặc key thừa. Không tự đổi schema hay cách xử lý key thừa chỉ để test xanh; nếu cần đổi contract, mô tả thay đổi trước trong diff và kiểm tra tương thích prompt/responseSchema.

**Thực hiện:** bổ sung targeted service/model tests chỉ ở các khoảng trống. Sửa service/model chỉ khi có lỗi cụ thể và test tái hiện. Không cố tình cạn quota, không cần gửi request mạng thật cho các ca parser.

**Tiêu chí hoàn tất:** input không hợp lệ không gọi sender; JSON/schema sai không tạo draft đáng tin nhầm; timeout/quota/App Check/server được ánh xạ theo contract; không có unhandled exception.

**Kết quả thực hiện ngày 29/09/2026:**

- `GeminiReportService` chỉ gửi MIME inline `image/jpeg`, `image/png`, `image/webp`; chữ ký PNG/JPEG/WebP phải khớp MIME, PNG cần signature + IHDR tối thiểu, và lỗi đọc file được ánh xạ thành `InvalidReportDraftInputException` không kèm đường dẫn.
- Cơ sở allowlist là danh sách MIME Firebase AI Logic công bố cho Gemini inline input: [PNG, JPEG và WebP](https://firebase.google.com/docs/ai-logic/input-file-requirements). Parser/model không đổi contract: field text thiếu để chuỗi rỗng, priority thiếu/null là `null`, thiếu `needs_confirmation` thì yêu cầu review mọi field, key lạ vẫn bị bỏ qua, field đã biết sai kiểu bị từ chối.
- Bằng chứng lịch sử Task 3: test service/parser đạt 43/43; full suite đạt 113/113; `flutter analyze` sạch; format check toàn bộ 26 tệp Dart không đổi file. Chưa gọi Gemini/App Check thật, không build APK và không kiểm tra thiết bị.
- **Task 4 hoàn tất ở host (30/09/2026):** `CreateReportScreen` nhận JPEG/PNG/WebP, báo rõ khi chọn BMP/GIF/HEIF/AVIF và giữ ảnh hợp lệ trước đó; helper text tách ngưỡng preview 10 MiB và gửi AI 4 MiB. Widget tests xác nhận lỗi service/App Check/response/timeout/quota giữ input và cho retry; loading/double tap; review/issue bắt buộc; save lỗi giữ nội dung/ảnh và retry cùng ID; kết quả mơ hồ cùng ID khớp thì không lưu trùng, khác nội dung thì conflict; Back khi chỉnh sửa/đang save; form chỉ xóa sau save thành công. `flutter test --no-pub --reporter compact` đạt 117/117; `flutter analyze --no-pub` sạch; `dart format --output=none --set-exit-if-changed lib/screens/create_report_screen.dart test/widget_test.dart` không đổi file. Chỉ dùng fake/host; không gọi Gemini/App Check thật, không build APK, không kiểm tra thiết bị. Task 4 đã đạt tiêu chí của phần host; giới hạn thiết bị và App Check thuộc các mục Android còn BLOCKED.

### Task 4 — UI resilience, bảo toàn dữ liệu và retry

**Mục tiêu:** người dùng luôn biết app đang làm gì; lỗi không xóa đầu vào hoặc draft.

**Tại form tạo báo cáo**

1. Với fake service lần lượt trả timeout, lỗi dịch vụ/App Check và lỗi response: xác nhận mô tả, ảnh preview và thông báo còn nguyên.
2. Xác nhận loading kết thúc sau cả thành công và lỗi; nút bị khóa trong lúc request và dùng lại được sau khi hoàn tất.
3. Bấm hai lần nhanh: chỉ có số lời gọi dự kiến, không tạo request ngoài ý muốn.
4. Sau lỗi, khôi phục fake service rồi retry: request mới chỉ phát sinh do người dùng bấm lại và nhận đúng mô tả/ảnh ban đầu.
5. Khi request thành công, draft mở ở trạng thái chưa lưu; form chỉ được xóa sau khi editor trả về report lưu thành công.

**Tại editor/save**

1. Xác nhận field chưa review, field tùy chọn xác nhận vắng mặt, `issue` bắt buộc và yêu cầu review lại `summary` khi dữ kiện đổi.
2. Khi repository save lỗi, nội dung editor và ảnh giữ nguyên; retry save dùng cùng snapshot/ID, không gọi service AI lại.
3. Khi kết quả save mơ hồ, kiểm tra `findById` trước khi retry; cùng ID/nội dung khớp thì kết thúc như đã lưu, khác nội dung thì báo conflict, không tạo ID mới âm thầm.
4. Kiểm tra double tap, Back khi editor có thay đổi và Back trong lúc save theo hành vi hiện tại.

**Thực hiện:** ưu tiên các test đang có trong `test/widget_test.dart`; thêm assertions hoặc test mới chỉ nếu khoảng trống được xác nhận. Dùng fake service/repository và đếm call count/snapshot; không dùng Gemini hoặc SQLite Android cho các ca UI có thể mô phỏng.

**Tiêu chí hoàn tất:** lỗi không làm mất form/editor; spinner/nút có trạng thái kết thúc; retry có chủ đích; không gọi AI lại để retry save và không lưu trùng theo ID.

### Task 5 — Privacy, secrets và logging

**Mục tiêu:** dữ liệu chỉ rời thiết bị khi người dùng yêu cầu, và thông tin nhạy cảm không lọt vào repo/log chia sẻ.

1. Rà call site: Firebase AI Logic chỉ được gọi từ CTA phân tích, không gọi lúc khởi động, đổi tab, mở History hoặc save.
2. Xác nhận request chỉ gồm mô tả và ảnh người dùng gửi; không tự thêm vị trí, tài khoản hay dữ liệu khác.
3. Rà service/UI/logging: không log prompt, ảnh bytes, raw response, report field, debug token hoặc credential. Debug exception chỉ được giữ nếu nội dung log không chứa các dữ liệu trên; nếu nghi ngờ thì khử/giảm log thay vì sao chép raw log vào ticket.
4. Rà diff, file mới, fixture và tài liệu để tìm marker secret phổ biến. Nếu nghi ngờ credential, chỉ báo đường dẫn/loại phát hiện, không in giá trị.
5. Xác nhận test/demo chỉ dùng dữ liệu tổng hợp. Ghi rõ Firebase Spark/free-tier có giới hạn privacy/data-use trong tài liệu phù hợp; không khẳng định dịch vụ đã cấu hình production.

**Tiêu chí hoàn tất:** không phát hiện secret mới hoặc payload nhạy cảm trong diff/log kiểm tra; mọi request AI đều gắn với hành động người dùng. Ghi chính xác phạm vi quét, không tuyên bố bảo đảm tuyệt đối.

**Kết quả Task 5 (30/09/2026):** hoàn tất rà call site và bỏ log SDK exception thô. Chưa kiểm tra API-key restrictions trong Firebase/Google Cloud Console. Debug provider vẫn xuất token cục bộ theo hành vi SDK; không chia sẻ log/token, nên mục này là giới hạn còn cần ghi nhận thay vì tuyên bố log Android sạch hoàn toàn.

### Task 6 — UX regression trên viewport và Android

**Mục tiêu:** xác nhận form, editor, History/detail và trạng thái lỗi dùng được trên màn điện thoại.

**Widget/host**

1. Chạy kiểm tra viewport nhỏ hiện có (bao gồm 320×568) và các test bàn phím; kiểm tra form, draft, History, detail, snackbar/dialog và notice lỗi.
2. Nếu sửa layout hoặc phát hiện lỗi mới, thêm test widget có ý nghĩa đúng cho hành vi đó; không tạo test lặp nội dung implementation.
3. Kiểm tra trạng thái loading/error/empty/retry không bị che, không overflow và không mắc spinner sau khi future hoàn tất.

**Android thật, nếu có thiết bị**

1. Cài APK build từ source đang kiểm tra và ghi version/hash.
2. Dùng dữ liệu tổng hợp để kiểm tra vùng bấm, bàn phím, cuộn, cỡ chữ lớn, loading, lỗi và giữ input sau lỗi.
3. Ghi case theo từng bước nhìn thấy được; test widget không được tính là PASS thiết bị.
4. Nếu không thể tạo lỗi mạng an toàn hoặc không có control channel, dùng fake test cho nhánh code và để case Android ở trạng thái tương ứng; không phá dữ liệu thật để tạo lỗi.

**Tiêu chí hoàn tất:** không có lỗi layout chưa phân loại; các giới hạn thiết bị/ADB được ghi rõ; test host và Android evidence không bị nhập làm một.

**Kết quả cập nhật 30/09/2026:** phần host được kiểm tra trong phiên: `flutter --suppress-analytics analyze --no-pub` — PASS, No issues found; `flutter --suppress-analytics test --no-pub --reporter compact` — PASS, 117/117; `dart format --output=none --set-exit-if-changed lib test` — PASS, 26 file/0 đổi. `flutter devices` tìm thấy PKG110 Android 16/API 36 qua ADB Wireless. Build APK từ source hiện tại bị automatic approval review từ chối trước khi lệnh chạy; vì vậy không cài APK, không thao tác UI/ADB trên điện thoại và không có Android UX case nào được đánh dấu PASS trong Task 6. Task 6 **một phần**: host đạt, kiểm tra thiết bị còn chờ. Không phát hiện lỗi layout qua kiểm tra host; đây không phải xác nhận layout trên thiết bị.

### Task 7 — Quyết định tính năng cộng thêm

**Mặc định:** hoãn voice-to-text và GPS trong Ngày 5. Chỉ lập task riêng nếu Tasks 2–6 đạt, carry-over Ngày 4 đã được xác minh hoặc ngoại lệ được chủ dự án chấp nhận, quyền riêng tư/UX đã rõ và còn đủ thời gian kiểm thử.

Nếu được mở task riêng:

- Chọn tối đa một tính năng.
- Voice: người dùng chủ động ghi âm; transcript được hiển thị và có thể sửa trước khi gửi AI; có permission/error/cancel rõ.
- GPS: chỉ lấy vị trí khi người dùng yêu cầu; cho phép bỏ qua/chỉnh sửa/xác nhận; không suy ra địa điểm nếu không có quyền hoặc dữ liệu.
- Trước khi thêm dependency/quyền, viết scope, dữ liệu được thu thập, nền tảng hỗ trợ và bộ test riêng.

Không triển khai tính năng cộng thêm trong cùng lát sửa service, privacy hoặc persistence.

## 5. Kế hoạch chạy kiểm tra khi bắt đầu thực thi

Đây là lệnh dự kiến; **chưa chạy trong phiên lập kế hoạch này**. Chọn targeted tests sau mỗi thay đổi, rồi chạy suite cuối.

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --reporter compact
flutter test test/gemini_report_service_test.dart --reporter compact
flutter test test/report_draft_test.dart --reporter compact
flutter test test/widget_test.dart --reporter compact
flutter test test/local_report_repository_test.dart --reporter compact
flutter build apk --debug
flutter devices
```

- Không cần chạy toàn bộ targeted commands nếu không có thay đổi ở nhóm tương ứng; ghi lệnh nào thực sự chạy và kết quả từng lệnh.
- `test/local_report_repository_test.dart` dùng SQLite FFI trên host; không gọi đó là Android plugin test.
- Chỉ chạy `flutter build apk --debug`/ADB khi SDK và thiết bị sẵn sàng. Build exit 0 chỉ xác nhận compile APK.
- Không chạy request Gemini thật để kiểm tra parser, timeout hay retry có fake.
- Không chạy `flutter build apk --release` trong scope này; release signing và App Check production chưa phải mục tiêu Ngày 5.

## 6. Bằng chứng và cập nhật tài liệu

Khi bắt đầu thực thi, cập nhật evidence theo kết quả thật:

1. Tạo `docs/testcase_day5_resilience.txt` để ghi môi trường, source/commit, APK hash nếu có, mỗi bước test, trạng thái và giới hạn. Không ghi serial/IP, token, prompt/response, ảnh hoặc log thô.
2. Cập nhật `docs/AI_WORKLOG.md` với ngày, scope, công cụ, thay đổi thật, test thật, request Gemini (nếu có), sự cố và giới hạn. Không ghi hồi cứu hoặc nâng `PARTIAL` thành `PASS`.
3. Cập nhật `README.md`, `docs/CONTEXT_SUMMARY.md` và `docs/WALKTHROUGH.md` chỉ khi hành vi/giới hạn hiện tại thay đổi hoặc phát hiện mô tả sai. Sửa sơ đồ AI cũ trong README nếu nó còn nói History/detail chưa có hoặc Android runtime chưa được kiểm chứng.
4. Không cập nhật test record cũ như thể nó kiểm tra APK mới; thêm entry mới hoặc ghi rõ phiên bản/source được kiểm tra.
5. Sau thay đổi, rà diff, trạng thái Git, phạm vi file, secret markers và liên kết tài liệu. Không stage/commit/push trừ khi có yêu cầu riêng.

## 7. Tiêu chí nghiệm thu Ngày 5

- [ ] Baseline source/Git/môi trường đã được ghi; thay đổi có trước được giữ nguyên.
- [ ] Lỗi input/schema/service được xử lý theo contract; input lỗi không gọi sender và không làm app crash.
- [ ] Loading kết thúc ở success/error; retry do người dùng chủ động và dùng đúng dữ liệu.
- [ ] Mô tả/ảnh không mất khi AI lỗi; draft không tự lưu.
- [ ] Lỗi lưu giữ editor; retry save không gọi AI lại và dùng cùng ID/snapshot.
- [ ] Privacy/log review và secret scan có phạm vi, kết quả và giới hạn rõ.
- [ ] Widget/analyzer/repository tests được chạy đúng phạm vi thay đổi; kết quả từng lệnh được ghi chính xác.
- [ ] Android UX được kiểm tra nếu thiết bị sẵn có; nếu không, ghi `BLOCKED`/`NOT RUN` thay vì suy ra từ widget test.
- [ ] Lưu/đọc ảnh và local offline trên Android mỗi case có kết quả riêng; blocker không bị tính PASS.
- [ ] Voice/GPS được hoãn hoặc có task riêng với scope và test riêng; không thêm dependency/quyền ngoài gate.
- [ ] README, context, walkthrough, worklog và test record không còn mô tả cũ trái với mã hiện tại.

**Ngày 5 được xem là hoàn tất khi** các tiêu chí P0 đạt hoặc mọi ngoại lệ P0 còn lại được ghi đúng trạng thái và người chấp nhận ngoại lệ được nêu rõ. Việc đóng task không tự biến blocker thành nghiệm thu.

## 8. Điều kiện dừng

- Dừng phần thiết bị nếu ADB không thấy đúng thiết bị, app/APK không khớp source, hoặc control channel sẽ mất khi thao tác mạng.
- Dừng case ảnh nếu fixture tổng hợp không xuất hiện trong Photo Picker; không dùng media cá nhân để lấp fixture.
- Dừng request thật nếu App Check/quota không rõ hoặc lỗi quota bắt đầu; các test service/widget độc lập vẫn tiếp tục bằng fake.
- Dừng và báo blocker nếu phát hiện credential/token trong file hoặc log; không sao chép giá trị nhạy cảm vào chat/worklog.
- Không bắt đầu voice/GPS khi còn lỗi P0 về input, giữ dữ liệu, retry, save hoặc privacy.
- Chuyển sang Ngày 6 chỉ khi trạng thái code/test/APK/evidence rõ ràng; không mô tả offline, ảnh hoặc production-ready nếu chưa có bằng chứng tương ứng.
