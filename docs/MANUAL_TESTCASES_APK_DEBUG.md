# Test case thủ công — APK debug trên Android thật

> Bộ test này dành cho APK debug hiện tại. Ngày 28/09/2026, chủ dự án xác nhận PHONE-01–PHONE-13 đã PASS trên máy thật; chưa có ghi chú/bằng chứng tách riêng từng case. Phần B ghi kết quả ADB thực sự chạy trong phiên hiện tại.
>
> APK sau khi build: `build\app\outputs\flutter-apk\app-debug.apk` trong thư mục dự án. Package Android: `com.example.ai_field_assistant`; version lấy từ `pubspec.yaml`/APK khi build.

**APK dùng cho ADB:** `D:\Documents\126\HocKyDoanhNghiep\project_pratice_mobile\build\app\outputs\flutter-apk\app-debug.apk` — 178,509,770 bytes, SHA-256 `F571DCAEDD34CFCE5CC1489455BE79D1D489E6B2E096E074D5FF96A399EC66DC`. Build lại ngày 28/09/2026 và cài đè thành công trên Android thật. Đây là APK debug, không dành cho phát hành production.

## Phạm vi và chuẩn bị

- Dùng mô tả/ảnh tổng hợp, không dùng tên người, vị trí hay dữ liệu sự cố của tòa nhà thật. Gemini được gọi khi bấm **Phân tích bằng AI**; số request có thể bị tính vào quota hiện hành.
- Cần điện thoại Android, Wi-Fi/mạng ổn định cho case AI, đủ dung lượng cài APK và quyền cài ứng dụng từ trình quản lý tệp nếu Android hỏi.
- Nếu Firebase App Check từ chối request, chủ dự án kiểm tra/đăng ký debug token trong Firebase Console bằng kênh riêng. Không đưa token vào ảnh chụp, log gửi đi, worklog hoặc Git.
- Draft hiện chỉ để xem. Chỉnh sửa, xác nhận, lưu vào SQLite và lịch sử chưa được nối vào UI; các thao tác đó không phải tiêu chí PASS của APK hiện tại.
- Không dùng `adb uninstall`, `pm clear` hoặc xóa dữ liệu ứng dụng trong buổi kiểm tra. Cài đè bằng `adb install -r` để giữ dữ liệu cấu hình hiện có.

### Ghi nhận môi trường

| Thông tin | Giá trị |
|---|---|
| Ngày kiểm tra ADB | 2026-09-28 |
| APK path / SHA-256 | `build\app\outputs\flutter-apk\app-debug.apk` / `F571DCAEDD34CFCE5CC1489455BE79D1D489E6B2E096E074D5FF96A399EC66DC` |
| Model điện thoại | PKG110 |
| Android/API | Android 16 / API 36 |
| Cài mới hay cài đè | Cài đè qua ADB không dây (`install -r`) |
| Mạng và trạng thái App Check | Không kiểm tra request AI/App Check trong phần B |
| Số request AI trong phần B | 0 |

## A. Test trực tiếp trên điện thoại

| ID | Thao tác | Kỳ vọng | Kết quả / ghi chú |
|---|---|---|---|
| PHONE-01 | Cài APK bằng trình quản lý tệp, mở ứng dụng. | Cài và mở được, không crash; thấy tab **Tạo báo cáo** và **Lịch sử**. Không tự gửi request AI khi khởi động. | PASS — chủ dự án xác nhận |
| PHONE-02 | Chuyển qua lại giữa hai tab khi form có mô tả chưa gửi. | Form vẫn giữ mô tả trong lần chạy hiện tại. Tab Lịch sử hiển thị empty state **Chưa có báo cáo**. | PASS — chủ dự án xác nhận |
| PHONE-03 | Để trống hoặc chỉ nhập khoảng trắng rồi bấm **Phân tích bằng AI**. | Báo cần nhập mô tả hoặc chọn ảnh; không hiện trạng thái loading; không crash. | PASS — chủ dự án xác nhận |
| PHONE-04 | Nhập mô tả tổng hợp, bấm **Xem lại đầu vào**, rồi quay lại chỉnh sửa. | Bottom sheet hiện đúng mô tả và ghi rõ đầu vào chưa gửi AI/chưa lưu; quay lại vẫn còn mô tả. | PASS — chủ dự án xác nhận |
| PHONE-05 | Chọn ảnh trong thư viện; hủy picker một lần rồi chọn ảnh hợp lệ. Thử thay bằng ảnh khác. | Hủy không xóa mô tả/ảnh trước; ảnh hợp lệ có preview; chọn ảnh khác thay preview. Nếu Android hiện hộp thoại quyền, từ chối không làm app crash và app báo lỗi/fallback dễ hiểu. | PASS — chủ dự án xác nhận |
| PHONE-06 | Bấm **Chụp ảnh**, chụp ảnh tổng hợp và xác nhận trong camera hệ thống. | Camera mở nếu thiết bị hỗ trợ; ảnh quay về app và hiện preview. Nếu không có camera/không hỗ trợ, app báo phù hợp và vẫn dùng được mô tả/chọn ảnh. | PASS — chủ dự án xác nhận |
| PHONE-07 | Chọn ảnh đầu vào lớn hơn giới hạn form nếu có fixture phù hợp (giới hạn sau xử lý là 10 MiB). | App từ chối ảnh vượt giới hạn, không crash và không làm mất ảnh trước đó. Ghi Blocked nếu không tạo được ảnh thử phù hợp. | PASS — chủ dự án xác nhận |
| PHONE-08 | Với mạng và App Check sẵn sàng, nhập mô tả tổng hợp rõ ràng rồi bấm **Phân tích bằng AI** một lần. | Có trạng thái chờ; không bấm tạo request thứ hai trong lúc chờ. Thành công mở **Bản nháp AI — cần kiểm tra, chưa lưu**, giữ đầu vào gốc, hiển thị các trường có nội dung và nhãn hành động đề xuất; draft vẫn ghi chưa xác nhận/chưa lưu. | PASS — chủ dự án xác nhận |
| PHONE-09 | (Tùy quota) Gửi mô tả mơ hồ, cố ý không nêu địa điểm. | Nếu AI không đủ căn cứ, địa điểm có thể trống và được đánh dấu cần xác nhận; không coi nội dung suy đoán là dữ kiện. Ghi sai lệch nội dung riêng, không lặp request nhiều lần. | PASS — chủ dự án xác nhận |
| PHONE-10 | (Tùy quota) Gửi mô tả tổng hợp cùng ảnh hợp lệ dưới giới hạn gửi AI. | Draft mở được; mô tả gốc và ảnh nguồn tương ứng được hiển thị. | PASS — chủ dự án xác nhận |
| PHONE-11 | Tắt mạng, nhập mô tả tổng hợp và thử phân tích; sau thông báo lỗi bật mạng rồi thử lại. | Lỗi được báo bằng giao diện, app không crash/treo vĩnh viễn; mô tả và ảnh vẫn còn; có thể thử lại. Retry thành công phụ thuộc mạng, App Check và quota. | PASS — chủ dự án xác nhận |
| PHONE-12 | Nhập nội dung chưa gửi, đóng hẳn app từ Android Settings rồi mở lại. | App khởi động được. Nội dung form/draft chưa lưu có thể mất: hiện chưa có persistence cho input/draft trong UI. Không đánh giá đây là lỗi SQLite Task 3. | PASS — chủ dự án xác nhận |
| PHONE-13 | Cuộn form khi bàn phím mở trên màn hình điện thoại nhỏ. | Có thể cuộn tới các nút; không thấy lỗi overflow; bàn phím không khóa app. | PASS — chủ dự án xác nhận |

### Dữ liệu tổng hợp gợi ý

- Rõ ràng: `Máy điều hòa tại khu vực lễ tân không hoạt động và phòng đang nóng.`
- Thiếu địa điểm: `Có tiếng kêu lớn từ một thiết bị, chưa xác định được nguồn.`
- Có ảnh: chụp một vật thể/bảng thử không chứa thông tin cá nhân hoặc địa điểm thật.

## B. Test khi điện thoại kết nối ADB với máy tính

Chạy lệnh trong PowerShell từ máy có Android Platform Tools. Nếu có nhiều thiết bị, dùng `-s <serial>` cho mọi lệnh. Không chạy lệnh gỡ app/xóa dữ liệu.

### ADB-01 — Xác nhận kết nối và cài đè APK

```powershell
$apkPath = 'D:\Documents\126\HocKyDoanhNghiep\project_pratice_mobile\build\app\outputs\flutter-apk\app-debug.apk'
$serial = '<serial từ adb devices -l>'
adb devices -l
adb -s $serial install -r $apkPath
```

**Kỳ vọng:** thiết bị xuất hiện trạng thái `device` (không phải `unauthorized`/`offline`); cài đè kết thúc với `Success`. Nếu APK path không tồn tại thì dừng, không thay bằng APK cũ.

**Kết quả 2026-09-28:** PASS — APK được build lại từ workspace; cài đè qua ADB không dây kết thúc `Success`. Lần thử `adb -d` đầu không chọn được thiết bị vì kết nối là Wi-Fi; lệnh sau chọn serial duy nhất từ danh sách ADB.

### ADB-02 — Kiểm tra package/version và mở app

```powershell
adb -s $serial shell dumpsys package com.example.ai_field_assistant | Select-String 'versionName|versionCode'
adb -s $serial shell am force-stop com.example.ai_field_assistant
adb -s $serial shell monkey -p com.example.ai_field_assistant 1
adb -s $serial shell pidof com.example.ai_field_assistant
```

**Kỳ vọng:** package/version khớp APK vừa cài; app mở foreground và có process ID. `force-stop` chỉ dừng app, không xóa dữ liệu.

**Kết quả 2026-09-28:** PASS — `versionName=0.1.0`, `versionCode=1`; Android 16/API 36, model PKG110; `.MainActivity` ở foreground và process chạy.

### ADB-03 — Thực hiện luồng UI khi đang nối cáp/ADB

Thực hiện PHONE-02 đến PHONE-11 trực tiếp trên điện thoại; quan sát màn hình khi thiết bị vẫn nối. ADB không tự động hóa các nút UI trong bộ test này. Ghi serial/model/Android cùng mỗi lỗi để dễ đối chiếu.

**Kỳ vọng:** giống cột kỳ vọng của từng PHONE case. Kết nối ADB không làm thay đổi cách chọn ảnh hoặc gọi Gemini.

**Kết quả 2026-09-28:** PARTIAL — khi ADB đang nối, input rỗng được chặn đúng, tab Lịch sử hiện empty state và mô tả thử vẫn còn sau khi chuyển tab qua lại. Các thao tác picker/camera, AI, ảnh lớn và mất mạng không được lặp trong lượt ADB này; PHONE cases tương ứng chỉ có xác nhận PASS của chủ dự án.

### ADB-04 — Kiểm tra cold start và crash buffer

Sau khi mở app và thực hiện một case, chạy:

```powershell
adb -s $serial logcat -d -b crash | Select-String 'FATAL EXCEPTION|com.example.ai_field_assistant'
```

**Kỳ vọng:** không có `FATAL EXCEPTION` của `com.example.ai_field_assistant`. Crash buffer có thể chứa thông tin chẩn đoán; chỉ chia sẻ đoạn đã rà và loại bỏ nội dung nhạy cảm.

**Kết quả 2026-09-28:** PASS — không tìm thấy `FATAL EXCEPTION` khớp package trong crash buffer sau các thao tác; app vẫn chạy foreground.

### ADB-05 — Kiểm tra vòng đời input chưa lưu

Nhập một mô tả tổng hợp nhưng chưa gửi; sau đó chạy:

```powershell
adb -s $serial shell am force-stop com.example.ai_field_assistant
adb -s $serial shell monkey -p com.example.ai_field_assistant 1
```

**Kỳ vọng:** app mở lại bình thường. Input chưa lưu có thể không còn vì form hiện giữ state trong bộ nhớ. Không dùng `pm clear` để kiểm tra điều này.

**Kết quả 2026-09-28:** PASS — chuỗi thử `ADB_TEST_LOSS_0928` hiện trước force-stop; sau force-stop/mở lại, trường mô tả còn trên UI nhưng rỗng; process app chạy lại.

### ADB-06 — Thu thập bằng chứng an toàn

Ghi lại ID test, thời điểm, model điện thoại/Android, kết quả, câu thông báo lỗi và số request AI. Nếu cần log rộng hơn crash buffer, chủ dự án rà log cục bộ trước khi chia sẻ: debug App Check có thể ghi token; không gửi token, API key, mô tả hiện trường, ảnh hoặc payload thô vào chat/ticket/Git.

**Kết quả 2026-09-28:** PASS — ghi nhận model/API, package/version, APK SHA-256 và trạng thái từng case tại đây; phần B không gửi request AI và không đưa serial/token vào tài liệu.

## C. Những gì APK hiện tại chưa thể xác nhận

- Sửa field của draft, xác nhận dữ kiện/field trống, lưu báo cáo và xem chi tiết/lịch sử từ SQLite: repository Task 3 chưa được nối vào UI (Task 4–6 chưa hoàn tất).
- Persistence qua `sqflite`/`path_provider` trên Android và dữ liệu còn sau khi đóng/mở app: APK build thành công không chứng minh plugin chạy trên thiết bị; cần tích hợp UI và chạy kiểm tra Android riêng.
- AI offline, quota hiện tại, App Check production/release signing và chất lượng AI như tiêu chí nội dung: chưa được khẳng định bởi bộ test này.

## Bảng kết quả

PHONE status là xác nhận của chủ dự án ngày 28/09/2026; ADB status là kết quả thực thi trong phiên này. `Partial` nghĩa case con của một nhóm chưa được chạy; không suy ra PASS từ test tự động hoặc lần test cũ.

| ID | PASS / FAIL / Blocked | Ghi chú và bằng chứng ngắn |
|---|---|---|
| PHONE-01–PHONE-13 | PASS (user-confirmed; no per-case evidence supplied) | |
| ADB-01 | PASS | Cài đè APK qua ADB không dây; `Success`. |
| ADB-02 | PASS | version 0.1.0+1; Android 16/API 36; MainActivity foreground. |
| ADB-03 | PARTIAL | Input rỗng, empty state lịch sử, giữ mô tả khi đổi tab; không lặp case AI/picker/camera/mạng. |
| ADB-04 | PASS | Không thấy app FATAL EXCEPTION trong crash buffer. |
| ADB-05 | PASS | Input thử mất sau force-stop/relaunch như dự kiến; app chạy lại. |
| ADB-06 | PASS | Môi trường/hash/kết quả ghi lại; không lưu serial hoặc token. |
