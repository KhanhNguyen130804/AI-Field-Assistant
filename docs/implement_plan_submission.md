# Chuẩn bị sản phẩm nộp — 01/10/2026

## Phạm vi đã giao

Người dùng yêu cầu chuẩn bị tất cả trước khi nộp; chọn GitHub Release cho APK, Google Drive cho video và sẽ kết nối USB/ADB. Link đề bài đã được cung cấp, nhưng web tool không đọc được và browser runtime lỗi trước khi có UI. Nội dung đề bài dùng bản ghi trong CHALLENGE_VI_ROADMAP, không coi deadline/form live đã được xác minh. Chưa bấm nộp, bật billing hoặc đăng bản release công khai.

Baseline: nhánh codex/release-app-check, HEAD 28b0a9c. Giữ nguyên hai test modified và HOME_DEVICE_TEST_CHECKLIST untracked. android/.kotlin xuất hiện như cache mới có trước lượt này, không xóa hoặc đưa vào Git. Máy PKG110 API 36 đang online và có app debug 0.1.0; không tự uninstall/clear data.

## Thứ tự thực hiện

1. Signing: tạo keystore riêng ngoài repo, lưu mật khẩu mã hóa Windows DPAPI ngoài repo, không in mật khẩu; Gradle nhận bí mật qua environment, không fallback debug khi thiếu. Thêm helper PowerShell để người phát triển build lại. Không ghi key/token thực tế vào source/docs.
2. Bump 0.2.0+2 cho artifact mới; khai báo INTERNET rõ trong main manifest, rồi kiểm tra merged manifest thật. Giữ dependency/schema/service/storage.
3. Host: format/analyze và tests. Hai test có trước được giữ nguyên; nếu kiểm tra bộ intended submission, dùng bản chính xác từ HEAD cho hai test đó trong thư mục sinh tự động và ghi rõ việc thay thế đường dẫn test, không mô tả working tree dirty là sạch.
4. Build release với Android reCAPTCHA site key công khai đã có trong ảnh người dùng gửi. Xác minh package/version/INTERNET/debuggable, chữ ký khác debug, kích thước/SHA-256; tạo bundle local trong build/submission, không commit APK/video/private signing.
5. Thiết bị: xác minh đúng artifact; chỉ install -r khi chữ ký tương thích hoặc cài trên máy sạch. Máy hiện có debug app cần người dùng chốt bảo toàn dữ liệu trước khi gỡ. Thử một request AI tổng hợp, review/xác nhận/save/History/restart, PDF và nhánh lỗi; không giả output hoặc retry AI liên tục khi quota/App Check lỗi.
6. Video: kịch bản <=4:40 và lời dẫn tiếng Việt, quay thao tác thật nếu thiết bị sẵn sàng; xem lại trước khi chia sẻ. Không quay Console/token/media cá nhân.
7. Hồ sơ: hướng dẫn cài, prompt thật từ source, mô tả quy trình, kiến trúc/giới hạn, checklist, bản nháp release notes và form. Showcase và chia sẻ prompt đã được cho phép; số giờ tiết kiệm còn cần ước lượng có căn cứ.
8. Sau khi gói hoàn chỉnh để review, xác nhận kênh phát hành/source GitHub/link tải/video/form; không tự bấm nộp hoặc chọn các mục chia sẻ thay người dùng.

## Gate nghiệm thu và trạng thái sau lượt chuẩn bị

- [x] Keystore ngoài Git, mật khẩu không vào command output/source/APK; backup độc lập chưa xác nhận, gate backup còn mở.
- [x] Format/analyze + tests intended submission 135/135; thay đổi có trước được bảo toàn.
- [x] APK release đúng version, ký riêng, có checksum và metadata nguồn.
- [x] AI thật trên artifact release: hai case synthetic pass trên một máy sau cài mới, không đăng ký debug token trong lượt này. Không chứng minh mọi máy hoặc cấu hình/quota bền vững.
- [x] Save/History/restart/PDF có bằng chứng riêng; ảnh qua restart, offline và nhánh lỗi trên thiết bị còn NOT RUN.
- [ ] Video thật dưới 5 phút được xem lại; không có thông tin cá nhân/secret.
- [x] Hồ sơ nộp soạn; các mục chưa chứng minh mang nhãn BLOCKED/NOT RUN. Giờ tiết kiệm cần điền.
- [ ] GitHub Release/Drive có link đã kiểm tra bằng người nhận chưa đăng nhập.
- [ ] Chủ dự án review trước thao tác phát hành/nộp cuối.

## Kết quả

Gói review local đã được chuẩn bị. Người dùng tự quay video theo script; trước khi phát hành cần sao lưu signing, điền ước lượng giờ tiết kiệm, review artifact/source và link. Chưa publish hoặc submit.
