# Cài AI Field Assistant trên Android

Hướng dẫn cho người nhận APK, không yêu cầu Firebase Console, ADB hay đăng ký debug token.

1. Tải đúng tệp APK **0.2.0+2** từ link GitHub Release do chủ dự án cung cấp. APK local đã cài/mở và chạy request AI thật trên PKG110; link GitHub chưa được phát hành, kiểm tra SUBMISSION_STATUS trước khi chia sẻ.
2. Android có thể yêu cầu cho phép cài từ nguồn đang mở APK. Chỉ cấp quyền cho nguồn bạn tin tưởng; sau khi cài có thể tắt lại quyền đó.
3. Mở AI Field Assistant với Internet. Nhập mô tả sự cố; chọn/chụp ảnh khi cần, theo UI Android. Không dùng dữ liệu nhạy cảm để thử demo.
4. Bấm Phân tích bằng AI, kiểm tra bản nháp, sửa/xác nhận trường còn thiếu rồi lưu. Mở Lịch sử để xem lại; PDF chỉ xuất từ báo cáo đã xác nhận/lưu.

## Khi không cài được

- Nếu máy có bản debug hoặc bản ký bằng khóa khác, Android có thể chặn cập nhật dù package giống nhau. **Không tự gỡ app nếu cần giữ báo cáo**; liên hệ người cung cấp để chốt bảo toàn dữ liệu hoặc thử trên máy sạch.
- APK có thể không phù hợp Android/CPU của máy; cung cấp model/Android version và thông báo lỗi cho người phát triển. Không gửi token, ảnh hiện trường hoặc báo cáo cá nhân.
- Checksum SHA-256 ở gói nộp giúp đối chiếu đúng tệp tải; fingerprint chứng thư ký là thông tin khác.

## Khi AI không chạy

- Kiểm tra mạng, đợi một lần và thử lại khi UI cho phép. Không bấm liên tục nếu thông báo quota.
- Người nhận **không đăng ký debug token**. Nếu lỗi App Check vẫn xảy ra, báo model/Android/version app và thông báo lỗi; người phát triển kiểm tra provider/package/site key/quota.
- Màn không khởi động được có thể do mạng hoặc cấu hình bản build; retry không sửa được site key thiếu đã nhúng trong APK. Người phát triển phải cung cấp bản build đúng cấu hình.
- Lịch sử lưu cục bộ; không có đồng bộ cloud. AI cần Internet và quota; không cam kết dùng được trên mọi môi trường Android.

## Dành cho người phát triển

Signing riêng được tạo ngoài repo bằng `tools/New-ReleaseSigning.ps1`; mật khẩu lưu DPAPI cho tài khoản Windows hiện tại. Build bằng `tools/Build-Release.ps1 -SiteKey '<ANDROID_SITE_KEY_PUBLIC>'`. Không dùng API key/server secret/debug token ở tham số này. Không commit hoặc chia sẻ keystore/password; cần sao lưu độc lập an toàn trước khi mất tài khoản/máy Windows. File DPAPI không phải bản sao mật khẩu di chuyển được sang máy khác.
