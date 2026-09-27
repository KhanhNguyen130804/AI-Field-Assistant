# Test case thủ công — Task 5: luồng "Phân tích bằng AI" trên thiết bị Android thật

> Áp dụng cho bản build **Task 5** (code chưa commit ở thời điểm viết). Bản APK cũ `D:\Download\ai-field-assistant-debug.apk` (build trước Task 5) **không có nút "Phân tích bằng AI"** — phải build lại APK mới trước khi test.
> Bản test này bổ sung phần AI cho `docs/MANUAL_TESTCASES_APK.md` (mục 5 của file đó ghi "chưa có nút gọi AI" — hết đúng cho bản Task 5; các TC 1.x–4.x trong file cũ vẫn dùng lại được làm regression).
> **Chỉ dùng dữ liệu tổng hợp** (mô tả/ảnh tự tạo, không có thông tin tòa nhà/khách hàng thật): Firebase AI Logic free tier có thể dùng input để cải thiện sản phẩm Google.

## Chuẩn bị

1. **Build lại APK:**
   ```
   flutter build apk --debug
   ```
   APK: `build\app\outputs\flutter-apk\app-debug.apk`. Copy sang `D:\Download\ai-field-assistant-debug-task5.apk` để khỏi nhầm bản cũ (~161 MB là bình thường với debug).
2. **Cài lên điện thoại.** Lưu ý: nếu **gỡ bản cũ rồi cài mới**, App Check debug token có thể đổi (token lưu theo lần cài) — kiểm tra lại log (TC-5.0.2) và đăng ký token mới trong Console nếu khác. Cài đè (không gỡ) thường giữ nguyên token.
3. **adb không dây** đã kết nối (như các lần trước). Lệnh theo dõi log:
   ```
   adb logcat -c
   adb logcat | Select-String -Pattern "FirebaseInitProvider|AppCheck|FirebaseAI|FlutterActivity|Exception|Error"
   ```
4. **Ảnh tổng hợp trong thư viện:**
   - **A:** ảnh thường, sau resize của picker còn **dưới 4 MiB** (ảnh chụp màn hình thường đạt).
   - **B:** ảnh nhiều chi tiết độ phân giải cao (thử đạt 4–10 MiB **sau** resize — dùng cho TC-5.5.1; nếu không tạo được thì ghi Blocked).
   - **C:** file đổi đuôi `.jpg` nhưng nội dung không phải ảnh (từ file cũ).
   - **D:** ảnh thứ hai để test thay ảnh.
5. **Mô tả tổng hợp:**
   - **T1 (rõ ràng):** "Máy điều hòa ở khu vực lễ tân không hoạt động, phòng rất nóng, khách phàn nàn."
   - **T2 (mơ hồ, thiếu địa điểm):** "Có cái máy gì đó kêu to lắm, chắc hỏng rồi."
   - **T3 (chỉ mô tả sự cố nước):** "Rò rỉ nước ở trần nhà tầng 2."
6. **Mạng:** Wi-Fi ổn định; biết cách bật/tắt **Chế độ máy bay** nhanh.
7. **Quota:** Firebase AI Logic đã đặt 5 RPM/vùng. Các TC mục 3 và 5 tốn request thật; đếm và ghi lại tổng số request trong buổi. Nếu gặp 429, dừng 1 phút rồi chạy tiếp, không bật billing.

Ký hiệu expectation: chuỗi thông báo trong **đậm** phải khớp **nguyên văn** những gì app hiển thị.

---

## 0. Khởi động bản mới

### TC-5.0.1 Cài và mở bản Task 5
- **Bước:** Cài APK mới, mở app.
- **Kỳ vọng:** Không crash. Tab **Tạo báo cáo** có: form mô tả (helper text "Mô tả và ảnh chỉ được gửi khi bạn bấm "Phân tích bằng AI"."), 2 nút ảnh, nút **Phân tích bằng AI**, nút **Xem lại đầu vào**, và khối thông báo "Mô tả và ảnh được gửi tới Gemini qua Firebase…". **App không tự gọi AI** khi mở (không loading, log không có request).

### TC-5.0.2 Firebase + App Check khởi tạo sạch trên bản mới
- **Bước:** `adb logcat -c`, force-stop app, mở lại (cold start), xem log.
- **Kỳ vọng:** `FirebaseApp initialization successful`; `DebugAppCheckProvider` in debug token; không error/exception từ Firebase/App Check/Flutter. **So sánh token với token đã đăng ký trong Console** — nếu khác thì đăng ký token mới trước các TC mục 3/5. **Không chụp màn hình hay chia sẻ token.**

---

## 1. CTA và chặn đầu vào (không tốn quota)

### TC-5.1.1 Chặn khi mô tả và ảnh đều trống
- **Bước:** Mở app mới (form trống), bấm **Phân tích bằng AI**.
- **Kỳ vọng:** Không có loading, không gọi AI (log sạch). Hiện **"Nhập mô tả hoặc chọn ảnh trước khi phân tích."**

### TC-5.1.2 Chặn khi mô tả chỉ toàn khoảng trắng
- **Bước:** Nhập vài dấu cách/xuống dòng, bấm **Phân tích bằng AI**.
- **Kỳ vọng:** Như TC-5.1.1 — thông báo chặn, không request.

### TC-5.1.3 "Xem lại đầu vào" không gọi AI
- **Bước:** Nhập T1, bấm **Xem lại đầu vào**.
- **Kỳ vọng:** Bottom sheet như cũ với cảnh báo **"Đầu vào này chưa được gửi tới AI và chưa được lưu thành báo cáo."**; log không có request. **Quay lại chỉnh sửa** đóng sheet, mô tả còn nguyên.

### TC-5.1.4 Double-tap nút Phân tích khi input hợp lệ nhưng mạng tắt
- **Bước:** Bật chế độ máy bay, nhập T1, bấm **Phân tích bằng AI** hai lần liên tiếp nhanh.
- **Kỳ vọng:** Nút chuyển disabled ngay sau lần bấm đầu (không thể tap lần 2 có tác dụng); chỉ một chuỗi xử lý lỗi xuất hiện, không nhân đôi thông báo. (Ghi chú: nếu thấy 2 thông báo chồng nhau, ghi FAIL kèm ảnh chụp.)

---

## 2. Phân tích thành công (tốn request — chạy sau khi TC-5.0.2 sạch)

> Đây đồng thời là **smoke test App Check thật** (phần Task 6): request Gemini đầu tiên xác nhận token được backend chấp nhận. Ghi lại thời điểm, model trả gì, log ra sao để điền `docs/AI_WORKLOG.md`.

### TC-5.2.1 Chỉ mô tả, nội dung rõ ràng (T1)
- **Bước:** Nhập T1, bấm **Phân tích bằng AI**. Nhìn ngay màn hình, rồi chờ.
- **Kỳ vọng:**
  1. Trong lúc chờ: thanh tiến trình + dòng **"Đang phân tích… Không tắt ứng dụng, kết quả sẽ hiện sau ít phút."**; nút **Phân tích bằng AI**, **Xem lại đầu vào**, **Chụp ảnh**, **Chọn ảnh** đều mờ/không bấm được.
  2. Thành công: mở màn hình **"Bản nháp AI"** với tiêu đề **"Bản nháp AI — cần kiểm tra, chưa lưu"**, thông báo **"Bản nháp chưa được lưu và chưa được xác nhận. Tính năng chỉnh sửa và lưu sẽ có ở bước tiếp theo."**
  3. Draft có đủ các trường T1 gợi ý: **Sự cố**, **Danh mục**, **Địa điểm**, **Mức độ ưu tiên** (Thấp/Trung bình/Cao), **Hành động đề xuất** (kèm dòng **"Đây là hành động đề xuất, chưa phải việc đã thực hiện."**), **Tóm tắt**.
  4. **Không có** khối "Các trường AI chưa đủ căn cứ, cần bạn xem lại:" và không có badge "Cần xác nhận" (T1 đủ dữ kiện).
  5. Phần **"Mô tả bạn đã nhập"** hiện đúng T1; **không có** phần "Ảnh bạn đã chọn".
  6. Log: không có 403/AppCheck error; có request Firebase AI Logic thành công (FirebaseAI logging tùy mức).
  7. **Kiểm chứng nội dung AI:** so từng trường với T1 — AI có **bịa** địa điểm/nguyên nhân không? priority có hợp lý không? summary có thêm dữ kiện ngoài T1 không? Ghi lại mọi sai số cho worklog.

### TC-5.2.2 Quay lại từ draft giữ nguyên input; phân tích lại được
- **Bước:** Từ draft của TC-5.2.1, bấm Back. Bấm **Phân tích bằng AI** lần nữa.
- **Kỳ vọng:** Về form: T1 và mọi nút hoạt động bình thường (không kẹt loading). Lần 2: mở lại draft mới thành công (tổng cộng ≥ 2 request; ghi số request).

### TC-5.2.3 Mô tả + ảnh (T3 + ảnh A)
- **Bước:** Nhập T3, chọn ảnh A, bấm **Phân tích bằng AI**.
- **Kỳ vọng:** Draft có phần **"Ảnh bạn đã chọn"** hiện đúng ảnh A; các trường phản ánh T3; thông tin có trong ảnh (nếu AI nêu) phải không mâu thuẫn với mô tả — ghi nhận nếu AI gán dữ kiện chỉ có trong ảnh vào summary (vi phạm quy tắc prompt).

### TC-5.2.4 Chỉ ảnh, không mô tả
- **Bước:** Xóa mô tả, chỉ để ảnh A (ảnh chụp màn hình bảng điều khiển/dụng cụ tổng hợp), bấm **Phân tích bằng AI**.
- **Kỳ vọng:** Vẫn gọi được (image-only được hỗ trợ). Draft: **Sự cố** có thể rỗng → khi đó **phải** xuất hiện khối needs_confirmation; trường rỗng **không được hiển thị** như dữ kiện. Ghi nhận AI có bịa bối cảnh từ ảnh không.

### TC-5.2.5 Mô tả mơ hồ (T2) — needs_confirmation
- **Bước:** Nhập T2 (không ảnh), bấm **Phân tích bằng AI**.
- **Kỳ vọng:** Draft hiện khối **"Các trường AI chưa đủ căn cứ, cần bạn xem lại:"** với bullet từng trường (ví dụ "• Địa điểm"); trường thiếu căn cứ có badge **"Cần xác nhận"** ngay trên giá trị nếu trường đó có nội dung nhưng AI đánh dấu; **priority phải là null hoặc được đánh dấu cần xác nhận — không tự thành "Trung bình" khi mô tả mơ hồ**. Trường rỗng không hiện khối giá trị. Ghi lại đúng danh sách AI trả về.

### TC-5.2.6 Ảnh không liên quan với mô tả
- **Bước:** Nhập T3 (rò rỉ nước) + chọn ảnh D là ảnh chụp màn hình điện thoại, bấm **Phân tích bằng AI**.
- **Kỳ vọng:** Draft không được khẳng định ảnh D là bằng chứng của rò rỉ (theo quy tắc prompt). Ghi nhận thực tế AI xử lý ra sao — đây là bằng chứng kiểm chứng AI cho worklog.

### TC-5.2.7 Draft không có nút lưu/sửa
- **Bước:** Ở màn draft (từ bất kỳ TC thành công), rà toàn màn hình.
- **Kỳ vọng:** Không có nút Lưu/Sửa/Xác nhận nào; chỉ có nút Back trên AppBar. Đúng phạm vi Task 5 (lưu/sửa thuộc ngày sau).

---

## 3. Loading và gián đoạn giữa request

### TC-5.3.1 Chuyển tab trong lúc loading
- **Bước:** Nhập T1, bấm **Phân tích bằng AI**, ngay lập tức bấm tab **Lịch sử**.
- **Kỳ vọng ghi nhận (chưa chốt hành vi đúng):** Tab chuyển bình thường; khi response về, màn draft **push đè lên tab đang mở** hay chỉ hiện khi quay lại tab Tạo báo cáo? Ghi lại hành vi thật + ảnh chụp. Không crash là điều kiện bắt buộc.

### TC-5.3.2 Xoay màn hình trong lúc loading
- **Bước:** Bấm **Phân tích bằng AI**, xoay ngang → dọc trong lúc chờ.
- **Kỳ vọng ghi nhận:** Không crash là bắt buộc. Request/state có thể mất khi Activity dựng lại (hạn chế đã biết của app, chưa có xử lý config) — ghi nhận kết quả thật: loading tiếp tục? draft hiện? hay app về form trống?

### TC-5.3.3 Home giữa request rồi quay lại
- **Bước:** Bấm **Phân tích bằng AI**, bấm Home, chờ ~10 giây, mở lại app.
- **Kỳ vọng ghi nhận:** Không crash; request có hoàn tất và hiện draft khi quay lại không (tùy Android giữ process). Nếu app bị kill và mở lại form trống — ghi nhận, đúng giới hạn "không giữ input sau khi đóng".

### TC-5.3.4 Bật/tắt bàn phím trong lúc loading
- **Bước:** Trong lúc loading, bấm vào ô mô tả để mở bàn phím, thu bàn phím.
- **Kỳ vọng:** Không crash; mô tả vẫn hiện đủ; bottom navigation ẩn/hiện theo bàn phím như cũ; nút vẫn khóa tới khi xong.

---

## 4. Xử lý lỗi (mỗi case tốn tối đa 1 request; input phải luôn được giữ)

### TC-5.4.1 Không có mạng ngay từ đầu
- **Bước:** Bật chế độ máy bay (Wi-Fi + data tắt), nhập T1, bấm **Phân tích bằng AI**.
- **Kỳ vọng:** Không crash, loading có thể hiện ngắn rồi hiện thông báo lỗi (thường là **"Không thể phân tích lúc này. Kiểm tra kết nối mạng rồi thử lại."** hoặc thông báo cấu hình nếu SDK báo khác — ghi đúng chuỗi thật). **T1 vẫn còn trong ô mô tả.** Nút Phân tích bật lại sau lỗi.
- **Bước tiếp:** Tắt chế độ máy bay, chờ Wi-Fi nối lại, bấm **Phân tích bằng AI**.
- **Kỳ vọng:** Retry thành công mở draft (input cũ dùng lại, không phải gõ lại).

### TC-5.4.2 Mất mạng GIỮA request
- **Bước:** Tắt Wi-Fi (Wi-Fi-only) hoặc chế độ máy bay **sau khi** đã bấm Phân tích ~2 giây.
- **Kỳ vọng ghi nhận:** Sau tối đa 60 giây (timeout client) phải hiện thông báo lỗi (mạng hoặc timeout **"Phân tích mất quá nhiều thời gian. Bạn thử lại giúp mình nhé."**), không treo loading vĩnh viễn, không crash. Ghi thời gian đợi thực tế — kết quả này xác nhận hành vi `Future.timeout` mà docs còn đánh dấu chưa kiểm chứng.

### TC-5.4.3 App Check bị từ chối (403)
- **Điều kiện:** Chỉ chạy được nếu chủ động tạo tình huống: đăng ký token sai/xóa token trong Console, hoặc thiết bị mới chưa đăng ký. Nếu không ép được, ghi Blocked.
- **Bước:** Nhập T1, bấm **Phân tích bằng AI**; xem `adb logcat` đồng thời.
- **Kỳ vọng:** App hiện **"Ứng dụng chưa được xác minh với dịch vụ AI (App Check). Bạn báo lại cho người quản trị ứng dụng."**; log có 403/token invalid; input giữ nguyên. **Xử lý: đăng ký đúng token trong Console rồi thử lại — không tắt App Check.** Kết quả xác nhận cách ánh xạ lỗi App Check (hiện đang dựa trên đoán message SDK).

### TC-5.4.4 Timeout 60 giây
- **Bước (nếu ép được):** Dùng cách giới hạn băng thông rất thấp (router/tethering chậm) hoặc ghi Blocked nếu không tạo được.
- **Kỳ vọng:** Sau ~60 giây hiện **"Phân tích mất quá nhiều thời gian. Bạn thử lại giúp mình nhé."**; input giữ; retry được.

### TC-5.4.5 Quota 429 (tùy chọn, tốn quota)
- **Bước:** Bấm Phân tích liên tục (mỗi lần xong bấm tiếp) vượt 5 lần trong 1 phút.
- **Kỳ vọng:** Khi vượt quota hiện **"Đã đạt giới hạn số lần phân tích trong lúc này. Bạn thử lại sau ít phút."**; sau ~1 phút retry được. Không bật billing để "chữa".

### TC-5.4.6 Phản hồi bị block / JSON sai (tùy chọn, khó ép)
- **Bước:** Thử mô tả nội dung dễ trigger safety filter (vẫn tổng hợp, không nhạy cảm thật), hoặc ghi Blocked.
- **Kỳ vọng:** Thông báo **"AI không trả về kết quả dùng được. Bạn thử lại hoặc chỉnh mô tả."**; không hiển thị raw response; không crash.

---

## 5. Ảnh và giới hạn gửi 4 MiB

### TC-5.5.1 Ảnh 4–10 MiB sau resize của picker (nếu tạo được — ảnh B)
- **Bước:** Chọn ảnh B (>4 MiB sau xử lý), nhập T3, bấm **Phân tích bằng AI**.
- **Kỳ vọng:** Form phải chặn **trước khi gửi**: hiện **"Ảnh vượt quá giới hạn 4 MiB để gửi phân tích. Hãy chọn ảnh nhỏ hơn hoặc chụp lại."**; không loading, không request (log sạch); **preview ảnh B và T3 giữ nguyên**. Đây chính là nhánh "Task 5 phải kiểm tra bytes trước khi gọi service".
- **Nếu không tạo được ảnh >4 MiB sau resize picker:** ghi Blocked cho bước chặn, nhưng chạy TC-5.5.2.

### TC-5.5.2 Ảnh thường gửi thành công không lỗi giới hạn
- **Bước:** Chọn ảnh A (<4 MiB), T3, Phân tích.
- **Kỳ vọng:** Không có thông báo 4 MiB; request đi bình thường, draft có ảnh.

### TC-5.5.3 File giả mạo (ảnh C) với phân tích
- **Bước:** Chọn ảnh C (nếu picker cho chọn). Nếu form đã chặn ngay ở preview (không thể chọn), ghi kết quả đó.
- **Kỳ vọng:** Không bao giờ tới được bước gửi; thông báo từ form ("không đọc được") hoặc từ service **"Loại ảnh không được hỗ trợ. Hãy dùng ảnh JPEG, PNG, WebP, GIF hoặc HEIC."**; không crash, ảnh khác vẫn chọn được sau đó.

---

## 6. Regression trên bản Task 5 (không tốn quota)

### TC-5.6.1 Xem lại đầu vào đầy đủ
- **Bước:** Lặp TC-2.2/2.3/3.9 của `MANUAL_TESTCASES_APK.md` (rỗng, chỉ mô tả, mô tả + ảnh).
- **Kỳ vọng:** Không đổi so với bản trước.

### TC-5.6.2 Picker: hủy, thay ảnh, ảnh quá lớn, file lỗi
- **Bước:** Lặp TC-3.1/3.2/3.3/3.7/3.8 file cũ.
- **Kỳ vọng:** Không đổi; message 10 MiB của form vẫn "Ảnh vượt quá giới hạn 10 MiB…" (giới hạn form và giới hạn gửi AI là hai ngưỡng khác nhau — 10 MiB nhận vào, 4 MiB gửi đi).

### TC-5.6.3 Điều hướng giữ state
- **Bước:** Lặp TC-4.1: sang Lịch sử rồi về Tạo báo cáo.
- **Kỳ vọng:** Mô tả + ảnh còn; Lịch sử vẫn empty state **"Chưa có báo cáo"** (chưa có lưu trữ — đúng phạm vi).

### TC-5.6.4 Màn hình hẹp / bàn phím che nút
- **Bước:** Ở thiết bị/màn nhỏ nhất có sẵn: cuộn tới **Phân tích bằng AI** với bàn phím mở.
- **Kỳ vọng:** Không overflow (không dải vàng "OVERFLOWED"); nút cuộn tới được.

### TC-5.6.5 Quyền: app vẫn không xin quyền runtime nào
- **Bước:** Cài đặt → Thông tin ứng dụng.
- **Kỳ vọng:** "Không có quyền nào" (như TC-3.6 cũ — camera qua Intent, ảnh qua Photo Picker).

---

## 7. Quyền riêng tư khi test

- **Chỉ nhập mô tả/ảnh tổng hợp** (T1–T3, ảnh chụp đồ vật/screen tổng hợp). Không nhập tên, địa chỉ, mã tòa nhà thật.
- Log không được chứa prompt/ảnh/response: rà `adb logcat` các đoạn capture ở trên — nếu thấy nội dung mô tả in ra log, ghi FAIL kèm chi tiết (vi phạm "không log nội dung hiện trường").
- Không chụp màn hình debug token; không commit token.

## 8. Phạm vi KHÔNG test ở bản này

| Hạng mục | Lý do |
|---|---|
| Sửa từng trường draft, xác nhận, lưu báo cáo, lịch sử | Chưa triển khai (Ngày 4). Draft chỉ xem. |
| Voice-to-text, GPS | Chưa triển khai. |
| Web (Chrome) | App Check Web debug chưa verify; bản test này là APK Android. |
| App Check production (Play Integrity/reCAPTCHA) | Thuộc bước phát hành. |
| Độ chính xác AI làm tiêu chí PASS/FAIL | Chất lượng AI ghi nhận làm bằng chứng worklog; chỉ crash/hiển thị sai schema mới là FAIL kỹ thuật. |

---

## Bảng ghi kết quả

| TC | Kết quả (PASS/FAIL/Blocked) | Ghi chú (model máy, Android version, chuỗi lỗi thật, số request, thời gian chờ) |
|---|---|---|
| 5.0.1 | | |
| 5.0.2 | | |
| 5.1.1 | | |
| 5.1.2 | | |
| 5.1.3 | | |
| 5.1.4 | | |
| 5.2.1 | | |
| 5.2.2 | | |
| 5.2.3 | | |
| 5.2.4 | | |
| 5.2.5 | | |
| 5.2.6 | | |
| 5.2.7 | | |
| 5.3.1 | | |
| 5.3.2 | | |
| 5.3.3 | | |
| 5.3.4 | | |
| 5.4.1 | | |
| 5.4.2 | | |
| 5.4.3 | | |
| 5.4.4 | | |
| 5.4.5 | | |
| 5.4.6 | | |
| 5.5.1 | | |
| 5.5.2 | | |
| 5.5.3 | | |
| 5.6.1 | | |
| 5.6.2 | | |
| 5.6.3 | | |
| 5.6.4 | | |
| 5.6.5 | | |

Tổng số request Gemini đã dùng trong buổi: ……
