# Walkthrough — luồng hiện tại, Task 7 đóng với ngoại lệ được chấp nhận

Hướng dẫn kiểm tra nhập mô tả/chọn ảnh, Firebase/App Check, Gemini draft, review/save, History và detail theo ID. Widget tests History/detail dùng fake repository. Theo quyết định của chủ dự án, Task 7 được đóng với ngoại lệ được chấp nhận: đã xác minh một report text-only còn ở History/detail sau force-stop/relaunch trên PKG110 Android 16/API 36, nhưng ảnh sau restart và offline save/read chưa được kiểm chứng. Fixture ảnh không xuất hiện trong Photo Picker; thiết bị chỉ có ADB Wireless. Day 4 chưa được nghiệm thu đầy đủ.

## 1. Chuẩn bị và khởi chạy

```bash
flutter pub get
flutter devices
flutter run -d <device-id>
```

Nếu Flutter yêu cầu Android SDK licenses, chạy `flutter doctor --android-licenses`. Web preview có thể mở bằng `flutter run -d chrome`; camera và permission cần kiểm tra riêng trên Android.

## 2. Thử nhập đầu vào

1. Ở tab **Tạo báo cáo**, nhập mô tả vào **Mô tả sự cố**.
2. Chọn **Chụp ảnh** để mở camera hoặc **Chọn ảnh** để mở photo picker.
3. Hủy picker: ứng dụng giữ nguyên mô tả và ảnh đã có.
4. Chọn ảnh: xem preview trong form. Chọn ảnh khác để thay ảnh hiện tại.
5. Chạm **Xem lại đầu vào**. Bottom sheet hiển thị mô tả/ảnh và thông báo đầu vào chưa gửi AI, chưa lưu.
6. Thử khi cả mô tả và ảnh đều trống; form phải yêu cầu nhập mô tả hoặc chọn ảnh.
7. Khi quyền bị từ chối hoặc picker lỗi, đọc hướng dẫn trên màn hình; mô tả vẫn được giữ và có thể tiếp tục nhập.

Ảnh tối đa một file, được yêu cầu resize tới 1600×1600 với JPEG quality 85 và bị từ chối nếu file nhận được vượt 10 MiB. Ảnh rỗng, quá lớn hoặc không có signature phổ biến được từ chối và không làm mất ảnh hiện có. Nếu Flutter decoder không render được ảnh dù signature hợp lệ, giao diện hiện fallback; cần kiểm tra nhánh này trên thiết bị.

## 3. Kiểm tra tự động

```bash
dart format lib test
flutter analyze
flutter test
```

Widget tests bao gồm điều hướng, validation đầu vào rỗng, form/input, permission/picker, ảnh lỗi, editor/review/save, retry, Back, double-tap và viewport 320×568/bàn phím. `test/history_screen_test.dart` kiểm tra loading/empty/error/retry, refresh, ID được chọn và save → refresh bằng fake repository. `test/report_detail_screen_test.dart` kiểm tra đọc report theo ID, thông tin đã xác nhận, field trống, loading/not-found/error/retry, ảnh và điều hướng Back bằng fake repository. Service tests ở `test/gemini_report_service_test.dart` dùng fake sender, không cần Firebase/network. `test/local_report_repository_test.dart` kiểm tra repository bằng SQLite FFI thật trên Windows. Bằng chứng **Day 4 Task 6 (29/09/2026)** là `flutter analyze` sạch và toàn suite `flutter test --reporter compact` 99/99. Task 5 trước đó đạt 90/90; lượt ADB Wireless của Task 5 build/cài APK và kiểm tra thao tác thiết bị, nhưng không chạy lại Flutter test/analyze. Task 4 đạt 85/85; repository FFI 10/10, suite 77/77 và các con số 45/45 bên dưới là bằng chứng lịch sử.

## 4. Build APK debug

Project config tắt Kotlin incremental để tránh lỗi cache của Windows khi project và Pub Cache ở hai ổ khác nhau. Build APK bằng lệnh chuẩn:

```bash
flutter build apk --debug
```

APK ở `build/app/outputs/flutter-apk/app-debug.apk`. Đổi lại, các lần build Kotlin có thể lâu hơn.

Bản APK debug đã được chủ dự án kiểm thử thủ công trên thiết bị thật theo `docs/MANUAL_TESTCASES_APK.md` (18/20 PASS ngày 26/09/2026). Lưu ý từ kiểm thử thực tế: app không khai báo quyền runtime nào — camera mở qua Intent hệ thống và ảnh qua Photo Picker của Android, nên màn Thông tin ứng dụng hiển thị "không có quyền nào" nhưng camera/ảnh vẫn hoạt động (đúng thiết kế); và photo picker tự resize/nén ảnh (1600px, JPEG q85) nên ảnh gốc > 10 MiB thường về dưới ngưỡng trước khi app kiểm tra.

## 5. Khởi tạo Firebase và App Check debug (Ngày 3 Task 3)

- App hiện khởi tạo Firebase khi mở và ở chế độ debug kích hoạt App Check debug provider (Android/Web).
- Build cần các file cấu hình FlutterFire (`lib/firebase_options.dart`, `android/app/google-services.json`, `firebase.json`); các file này đã được commit từ Task 3, nhưng nếu dùng project Firebase khác phải chạy lại `flutterfire configure`.
- Ứng dụng hiện gọi Firebase AI Logic trên Spark/free tier; không có Cloud Run backend hay Secret Manager do dự án tự quản lý. Free-tier data có thể được dùng để cải thiện sản phẩm Google, vì vậy chỉ kiểm thử bằng mô tả/ảnh tổng hợp, không gửi dữ liệu hiện trường thật. Không cần bật Cloud Billing cho luồng Spark hiện tại.
- Lần chạy debug đầu, log (`flutter run` hoặc `adb logcat`) có dòng `Firebase App Check debug token: <token>`. Đăng ký token này trong Firebase Console (App Check → Apps → Manage debug tokens); không commit hay chụp màn hình token.
- Sau khi đăng ký, chạy lại app: log cold start phải có `FirebaseApp initialization successful` và không có error/exception của Firebase/App Check. Đã kiểm chứng như vậy trên điện thoại Android thật ngày 26/09/2026 (agent bắt log qua `adb logcat`, điện thoại kết nối adb không dây).
- Token được backend chấp nhận đã được xác nhận bằng request Gemini thật đầu tiên (Task 5, 27/09/2026). Lưu ý: cài đè/gỡ cài app có thể đổi debug token → 403 "App attestation failed"; app giờ hiển thị đúng thông báo App Check cho lỗi này — đăng ký lại token trong Console. Web debug provider chưa verify trên Chrome.

## 6. Luồng "Phân tích bằng AI" và màn bản nháp (Ngày 3 Task 5)

1. Ở tab **Tạo báo cáo**, nhập mô tả và/hoặc chọn ảnh, rồi bấm **Phân tích bằng AI**.
2. Trong lúc chờ: thanh tiến trình + dòng "Đang phân tích…"; cả 4 nút (Phân tích/Chụp ảnh/Chọn ảnh/Xem lại) bị khóa; mô tả và ảnh giữ nguyên.
3. Thành công: mở màn **"Bản nháp AI"** với draft chưa lưu; sáu trường có thể sửa, từng trường cần người dùng xác nhận dù AI không gắn `needs_confirmation`; badge AI và trạng thái review của người dùng hiển thị riêng. Trường tùy chọn có thể xác nhận chưa có dữ liệu; `issue` cần nội dung; sau khi sửa dữ kiện phải review lại `summary`. `suggested_action` luôn được ghi rõ là đề xuất; màn giữ mô tả/ảnh gốc.
4. Lỗi (mạng/timeout/quota/App Check/JSON sai): thông báo tiếng Việt ở form, mô tả + ảnh giữ nguyên, bấm lại được.
5. Bấm Back khi có review/chỉnh sửa: app hỏi có bỏ phần đã xem lại không. Chọn ở lại giữ editor; chọn bỏ quay về form nguồn chưa bị xóa.
6. Trong editor, hoàn tất review sáu trường rồi bấm **Xác nhận và lưu báo cáo**; xác nhận ở hộp thoại cuối. Khi lưu thành công, về form và hiện thông báo lưu trên thiết bị. Nếu storage lỗi, editor giữ nội dung và cho thử lại; nếu kết quả lưu không chắc chắn, dùng **Kiểm tra kết quả lưu** trước khi thử lại để tránh bản ghi trùng.
7. Tab **Lịch sử** tải dữ liệu khi mở tab; có thể kéo xuống để refresh. Empty state chỉ xuất hiện sau khi repository trả danh sách rỗng thành công; lỗi đọc có thông báo và nút **Thử lại**. Danh sách hiển thị sự cố, địa điểm nếu có, priority, ngày giờ địa phương và nhãn đã xác nhận. Chạm một dòng mở **Chi tiết báo cáo**, truy vấn repository theo ID. Chi tiết hiển thị metadata, field đã xác nhận, mô tả gốc và ảnh nếu có; field đã xác nhận không có được ghi rõ, còn hành động vẫn được gọi là đề xuất. Nếu report không tồn tại hoặc đọc lỗi, màn hiện trạng thái tương ứng và cho retry. Nếu ảnh thiếu/hỏng/không đọc được, text vẫn còn và ảnh có fallback/retry. Back quay lại danh sách. Widget tests dùng fake repository; repository FFI tests chạy trên host. Task 7 đã xác minh report text-only trên Android qua save → History → detail → force-stop/relaunch → History/detail. Ảnh và offline chưa được kiểm chứng trên Android.

Model dùng: **chính `gemini-3.8-flash`** (chất lượng cao, free 20 request/ngày/model); khi hết quota tự thử **`gemini-3.5-flash-lite`** (500 request/ngày, chất lượng thấp hơn — draft có thể cần xác nhận nhiều hơn) trong cùng lần bấm. Lỗi không phải quota không kích hoạt fallback. Chi tiết và bằng chứng log ở `docs/SESSION_2026-09-26_TASK5.md` mục 4–6; bộ test case thủ công cho luồng này ở `docs/MANUAL_TESTCASES_TASK5.md`.

Service không còn ghi exception SDK thô vào log; lỗi được ánh xạ sang thông báo chung trong UI. Debug App Check provider có thể ghi debug token cục bộ theo hành vi SDK. Không chia sẻ raw log/token; chỉ kiểm tra log có mục đích và giới hạn khi cần.

## 7. Service Gemini (Ngày 3 Task 4, đã nối UI từ Task 5)

- `lib/services/gemini_report_service.dart` gửi text/ảnh tới Gemini qua Firebase AI Logic với `responseSchema`, parse/validate qua `ReportDraft.fromJson`, timeout 60 giây, chặn đầu vào rỗng/ảnh > 4 MiB/loại lạ và ánh xạ lỗi sang thông báo tiếng Việt. Model chính `gemini-3.8-flash`, fallback `gemini-3.5-flash-lite` khi quota.
- Service đã được nối vào form từ Task 5 (mục 6); request Gemini thật đã chạy đầu-cuối trên thiết bị (27/09/2026).
- Unit test (27 case, fake sender/factory) nằm ở `test/gemini_report_service_test.dart`; chạy bằng `flutter test test/gemini_report_service_test.dart`.

## Giới hạn kiểm chứng và bước tiếp theo

Task 7 (2026-09-29) vừa chạy format check (26 file/0 đổi), flutter analyze (No issues), flutter test --reporter compact (99/99), repository FFI tests (10/10) và flutter build apk --debug (exit 0). Một request Gemini tổng hợp tạo report text-only; save → History → detail đạt. Force-stop/relaunch rồi đọc lại đúng marker ở History/detail cũng đạt. Logcat giới hạn: 1.956 dòng, không có match FATAL EXCEPTION hoặc nhóm SQLite/plugin error đã lọc. Không ghi nhận model cụ thể thực tế của request. Chủ dự án đã đóng Task 7 với ngoại lệ: persistence ảnh và offline chưa được kiểm chứng; xem phiếu test để biết từng trạng thái. Đây không phải bằng chứng nghiệm thu đầy đủ Ngày 4.

Task 3–6 là lịch sử theo từng entry trong worklog: SQLite FFI, editor/review/save, History và detail đã được triển khai; các kết quả PHONE do chủ dự án báo và ADB smoke của từng lượt không thay thế nhau. ADB Task 5 khi đó xác minh save → History trong cùng phiên; Task 6 xác minh điều hướng History → detail. Task 7 hiện đã chứng minh text-only persistence sau restart process nhưng chưa xác minh ảnh hoặc offline; bước tiếp theo là xử lý hai trường hợp này mà không dùng media người dùng hay mất kiểm soát thiết bị. Voice-to-text và GPS chưa triển khai.

Day 5 Task 6 (30/09/2026) vừa chạy lại trên host: `flutter analyze` sạch, `flutter test` 117/117 và format check 26 file/0 đổi. Flutter nhận PKG110 Android 16/API 36 qua ADB Wireless, nhưng build APK từ source hiện tại bị automatic approval review chặn trước khi chạy. Vì vậy chưa cài APK hoặc kiểm tra giao diện trên thiết bị; các kết quả Task 7 Android text-only là bằng chứng lịch sử source/APK trước Day 5, không phải xác minh UX hiện tại. Ảnh persistence và offline vẫn chưa được kiểm chứng.

## Xuất PDF báo cáo đã xác nhận (nhánh `codex/report-pdf-export`)

Trong màn **Chi tiết báo cáo**, hai nút **Lưu PDF** và **Chia sẻ PDF** xuất report đã lưu, gồm các trường đã xác nhận, thời gian, mô tả gốc và ảnh nếu có. Tệp sinh cục bộ; khi ảnh có lỗi, app yêu cầu xác nhận trước khi tạo PDF không ảnh. Lưu mở document picker Android; chia sẻ mở Android share sheet, nơi có thể chọn Zalo nếu thiết bị đã cài và liệt kê Zalo cho MIME PDF.

Kiểm tra host vừa chạy trên nhánh này: `flutter test --no-pub --reporter compact` 126/126; `flutter analyze --no-pub` sạch; format check 29 file/0 đổi. `flutter build apk --debug --no-pub` thành công. `flutter devices` trong cùng lượt chỉ nhận Windows, Chrome và Edge; chưa cài APK hoặc thử lưu/mở/chia sẻ PDF trên Android. Vì vậy share sheet, document picker, xem PDF và Zalo vẫn cần kiểm tra trên điện thoại thật.

### Kết quả kiểm tra/build đã ghi nhận

`flutter build web --release` và APK debug build đã thành công ở các task trước (lịch sử Ngày 2–3). Ngày 3 Task 3: analyze sạch, `flutter test` 13/13, build web thành công, khởi tạo Firebase/App Check kiểm chứng trên Android thật qua `adb logcat`. Ngày 3 Task 4: analyze sạch, `flutter test` 33/33, build web + APK thành công. Ngày 3 Task 5 (26–27/09/2026): analyze sạch, `flutter test` **45/45**, build web + APK thành công; **request Gemini thật đã chạy đầu-cuối trên thiết bị Android** (agent lái qua adb) — draft mở, không bịa trường, fallback quota hoạt động theo log. Chủ dự án xác nhận kiểm thử thủ công Task 5 PASS; bảng 31 case chưa được điền chi tiết. Task 5 đã commit tại `c440da4`. Task 6 (27/09/2026): format dry-run 11 file/0 thay đổi, `flutter analyze` No issues, `flutter test` 45/45; không gửi request mới vì đã có bằng chứng E2E và thiết bị đang giữ ảnh không rõ nội dung. Đây đều là kết quả lịch sử ghi nhận trong tài liệu; mô tả/ảnh chưa lưu khi draft chưa được xác nhận/lưu.
