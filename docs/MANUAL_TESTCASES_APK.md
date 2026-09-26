# Test case thủ công — APK debug trên thiết bị Android thật

> Áp dụng cho bản build `ai-field-assistant-debug.apk` (debug, chứa App Check debug provider).
> Trạng thái app khi viết bộ test này: **chưa có nút gọi AI, chưa lưu báo cáo, tab Lịch sử chỉ là empty state.**
> Các test case AI/lưu trữ chỉ thêm được sau Task 5/6 — không ghi "PASS" cho tính năng chưa tồn tại.

## Chuẩn bị

- Điện thoại Android thật, bật "Cài đặt ứng dụng không rõ nguồn" cho file manager.
- Cài APK: `D:\Download\ai-field-assistant-debug.apk` (kích thước ~161 MB là bình thường với bản debug).
- Máy tính có `adb` nếu muốn kiểm tra log (mục 1.2). Có thể dùng `adb connect <ip:port>` không dây.
- Chuẩn bị sẵn 4 ảnh trong thư viện để test:
  - **A:** ảnh thường < 10 MiB (vd. chụp màn hình).
  - **B:** ảnh lớn hơn 10 MiB (chụp ở độ phân giải cao, hoặc copy ảnh gốc từ máy ảnh).
  - **C:** file đổi đuôi thành `.jpg` nhưng nội dung không phải ảnh (vd. file text) — dùng nếu thiết bị cho phép copy vào thư viện.
  - **D:** ảnh thứ hai để test thay ảnh.

---

## 1. Cài đặt và khởi động lần đầu

### TC-1.1 Cài và mở app
- **Bước:** Cài APK, mở app từ launcher.
- **Kỳ vọng:** App mở không crash. Màn hình "AI Field Assistant" hiện tab **Tạo báo cáo** với form mô tả + 2 nút Chụp ảnh / Chọn ảnh. Không có nút "Phân tích AI" nào.

### TC-1.2 Firebase + App Check khởi tạo (cần adb)
- **Bước:** Kết nối adb (dây hoặc không dây), chạy:
  ```
  adb logcat -c
  adb logcat | Select-String -Pattern "FirebaseInitProvider|AppCheck|FlutterActivity"
  ```
  rồi force-stop app và mở lại (cold start).
- **Kỳ vọng:** Log có `FirebaseApp initialization successful`; `DebugAppCheckProvider` in debug token; **không có** error/exception/crash từ Firebase, App Check hoặc Flutter.
- **Lưu ý:** Nếu gặp lỗi 403 "App Check" thì token chưa được đăng ký — vào Firebase Console (App Check → Apps → Manage debug tokens) đăng ký token in trong log. **Không chụp màn hình/ chia sẻ token.**

### TC-1.3 Mở lại app sau khi đã chạy
- **Bước:** Bấm Home, mở lại app (không force-stop).
- **Kỳ vọng:** App mở lại bình thường, không crash.

---

## 2. Form mô tả

### TC-2.1 Nhập mô tả
- **Bước:** Nhập vài dòng văn bản, vd. "Điều hòa ở khu vực lễ tân không chạy."
- **Kỳ vọng:** Text hiện đủ, xuống dòng được (Enter tạo dòng mới).

### TC-2.2 Xem lại đầu vào khi cả hai trống
- **Bước:** Xóa mô tả, chưa chọn ảnh, bấm **Xem lại đầu vào**.
- **Kỳ vọng:** Không mở sheet. Hiện thông báo lỗi "Nhập mô tả hoặc chọn ảnh trước khi xem lại đầu vào."

### TC-2.3 Xem lại đầu vào chỉ có mô tả
- **Bước:** Nhập mô tả, bấm **Xem lại đầu vào**.
- **Kỳ vọng:** Bottom sheet hiện đúng nội dung vừa nhập, kèm dòng cảnh báo "chưa được gửi tới AI và chưa được lưu". Bấm **Quay lại chỉnh sửa** đóng sheet, mô tả vẫn còn.

### TC-2.4 Bàn phím không che nội dung
- **Bước:** Gõ tới khi form dài, cuộn xuống cùng.
- **Kỳ vọng:** Bàn phím mở thì bottom navigation ẩn; nút **Xem lại đầu vào** cuộn tới được, không bị che.

### TC-2.5 Màn hình nhỏ không tràn
- **Bước:** (nếu có thiết bị nhỏ / chế độ hiển thị nhỏ nhất) Lặp TC-2.1–2.3.
- **Kỳ vọng:** Không có lỗi overflow (không dải vàng/xám "OVERFLOWED").

---

## 3. Chọn và chụp ảnh

### TC-3.1 Chọn ảnh từ thư viện
- **Bước:** Bấm **Chọn ảnh**, chọn ảnh **A**.
- **Kỳ vọng:** Preview ảnh hiện trong form với chú thích "Ảnh đã chọn. Chọn ảnh khác để thay thế."

### TC-3.2 Thay ảnh đã chọn
- **Bước:** Bấm **Chọn ảnh** lần nữa, chọn ảnh **D**.
- **Kỳ vọng:** Preview đổi sang ảnh **D**.

### TC-3.3 Hủy picker
- **Bước:** Bấm **Chọn ảnh**, bấm Back / nút hủy của picker.
- **Kỳ vọng:** Không hiện lỗi; mô tả và ảnh đang có **giữ nguyên**.

### TC-3.4 Chụp ảnh bằng camera
- **Bước:** Bấm **Chụp ảnh**, chụp 1 tấm, xác nhận.
- **Kỳ vọng:** Preview ảnh vừa chụp hiện trong form.
- **Ghi chú:** Kịch bản này chưa từng có bằng chứng test — ưu tiên chạy.

### TC-3.5 Hủy camera
- **Bước:** Bấm **Chụp ảnh**, hủy (Back) trước/sau khi chụp.
- **Kỳ vọng:** Không lỗi; mô tả + ảnh cũ giữ nguyên.

### TC-3.6 Từ chối quyền camera — thiết kế hiện tại: app không xin quyền runtime
- **Kết quả kiểm chứng 26/09/2026 (thiết bị thật):** App Cài đặt → Thông tin ứng dụng hiển thị "không có quyền nào được yêu cầu" và app vẫn mở được camera + photo picker. **Đây là hành vi đúng theo thiết kế, không phải bug.**
- **Giải thích kỹ thuật:** `image_picker` 1.2.3 không khai báo quyền CAMERA/READ_MEDIA_IMAGES trong manifest (đã xác minh bằng merged manifest của APK, chỉ có `INTERNET`, `ACCESS_NETWORK_STATE`, `READ_GSERVICES`). Camera được mở qua Intent hệ thống (`ACTION_IMAGE_CAPTURE` — app camera có quyền sẵn) và ảnh chọn qua **Photo Picker** của Android (picker chạy bằng quyền hệ thống). Quyền chỉ cần khi dùng `permission_handler` hoặc tự truy cập `CameraX` — dự án không dùng.
- **Bước xác nhận thêm (tùy chọn, vẫn đáng chạy):**
  1. Chụp ảnh qua Intent: tắt ứng dụng camera mặc định (không gỡ) hoặc chọn "Chỉ một lần" khi Android hỏi app camera nào, xác nhận picker/camera vẫn hoạt động.
  2. Thiết bị **không có** ứng dụng camera xử lý `ACTION_IMAGE_CAPTURE` (hiếm, máy ảo không có GApps): bấm **Chụp ảnh** phải hiện thông báo "Không thể mở camera. Bạn vẫn có thể nhập mô tả hoặc chọn ảnh." và không crash.
  3. Trên máy có Photo Picker module cũ: thử hủy picker ở trạng thái "Chỉ một lần" — mô tả/ảnh cũ phải giữ nguyên.

### TC-3.7 Ảnh quá lớn (> 10 MiB) — PHÁT HIỆN: giới hạn không có tác dụng trên thực tế
- **Kết quả kiểm chứng 26/09/2026 (thiết bị thật):** Ảnh 12 MB được chọn thay thế **vẫn hiện preview, không có thông báo nào** — khác kỳ vọng gốc.
- **Nguyên nhân đoán (cần xác nhận bằng log/debug):** `image_picker` với `imageQuality: 85` + `maxWidth/maxHeight: 1600` **nén lại ảnh trước khi trả về**; phần lớn ảnh 12 MB sau khi resize/compress xuống dưới 10 MiB nên nhánh chặn trong `_applySelectedImage` không bao giờ chạy với ảnh chụp thường. Code chặn 10 MiB vẫn đúng, nhưng **không thể kích hoạt** bằng ảnh gốc trên đa số thiết bị.
- **Bước thu hẹp khoảng trống (chạy tiếp trên thiết bị):**
  1. Tìm/copy vào thư viện một ảnh chụp ở độ phân giải cực cao, hoặc ảnh PNG ảnh chụp màn hình dài, sao cho **sau** resize 1600px/quality 85 vẫn > 10 MiB (hiếm, nhưng ảnh nhiều chi tiết có thể đạt).
  2. Kết quả dự kiến: khi file trả về > 10 MiB, app phải hiện "Ảnh vượt quá giới hạn 10 MiB. Hãy chọn ảnh nhỏ hơn rồi thử lại." và giữ ảnh cũ.
  3. Ghi nhận rõ: nếu **không thể** tạo ra ảnh sau-xử-lý > 10 MiB trên thiết bị, kết luận là "giới hạn 10 MiB trong thực tế không bao giờ bị vượt qua qua picker" — chấp nhận được cho MVP, nhưng **phải ghi vào README** (hiện README mô tả như thể người dùng có thể gặp lỗi 10 MiB).
- **Liên quan Task 5:** giới hạn gửi AI là **4 MiB** (`lib/services/gemini_report_service.dart`), trong khi form cho tới 10 MiB. Kết quả này cho thấy resize của picker có thể đưa ảnh về dưới 4 MiB ở đa số trường hợp, nhưng vẫn phải **kiểm tra bytes trước khi gửi** trong Task 5 — không thể bỏ nhánh chặn.

### TC-3.8 File không phải ảnh
- **Bước:** Chọn ảnh **C** (file giả mạo) từ thư viện.
- **Kỳ vọng:** Không nhận; thông báo "không đọc được"; ảnh cũ giữ nguyên.

### TC-3.9 Xem lại đầu vào có ảnh
- **Bước:** Nhập mô tả + chọn ảnh A, bấm **Xem lại đầu vào**.
- **Kỳ vọng:** Sheet hiện cả mô tả lẫn preview ảnh.

---

## 4. Điều hướng

### TC-4.1 Chuyển tab
- **Bước:** Bấm tab **Lịch sử**.
- **Kỳ vọng:** Hiện empty state "Chưa có báo cáo" với giải thích. Bấm lại tab **Tạo báo cáo**: **mô tả + ảnh vẫn còn** (IndexedStack giữ state).

### TC-4.2 Xoay màn hình
- **Bước:** Xoay ngang/dọc ở form và ở lịch sử.
- **Kỳ vọng:** Không crash, không overflow. (Cho phép mô tả/ảnh bị mất khi xoay — ghi nhận kết quả thật; app chưa xử lý state qua cấu hình lại Activity.)

### TC-4.3 App chạy nền lâu / Android kill process
- **Bước:** Mở app khác nặng hoặc bật màn hình tắt vài phút, quay lại app.
- **Kỳ vọng:** Không crash. (Nếu Android kill process thì app mở lại form trống — ghi nhận, không coi là bug vì chưa có persistence.)

---

## 5. Phạm vi KHÔNG test ở bản này

| Hạng mục | Lý do |
|---|---|
| Gọi AI tạo báo cáo | Service Gemini đã viết nhưng **chưa nối UI** (Task 5). App hiện không có nút nào gọi AI. |
| Lưu / sửa / xóa báo cáo, lịch sử | Chưa triển khai (Ngày 4). |
| Voice-to-text, GPS | Chưa triển khai. |
| Web (Chrome) | Bản APK là Android; Web App Check chưa verify. |

---

## Bảng ghi kết quả

| TC | Kết quả (PASS/FAIL/Blocked) | Ghi chú (model máy, Android version, lỗi nếu có) |
|---|---|---|
| 1.1 | | |
| 1.2 | | |
| 1.3 | | |
| 2.1 | | |
| 2.2 | | |
| 2.3 | | |
| 2.4 | | |
| 2.5 | | |
| 3.1 | | |
| 3.2 | | |
| 3.3 | | |
| 3.4 | | |
| 3.5 | | |
| 3.6 | PASS (theo thiết kế không xin quyền runtime) | App Settings hiện "không có quyền nào"; camera/ảnh vẫn mở qua Intent + Photo Picker. Đã xác minh merged manifest không có CAMERA/READ_MEDIA_* |
| 3.7 | PASS với kết quả khác kỳ vọng | Ảnh 12 MB được nhận sau resize của picker; nhánh chặn 10 MiB không kích hoạt được trên thực tế. Cần thử ảnh sau-resize > 10 MiB (hiếm) và ghi hạn chế vào README |
| 3.8 | | |
| 3.9 | | |
| 4.1 | | |
| 4.2 | | |
| 4.3 | | |
