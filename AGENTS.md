# AGENTS.md — Hướng dẫn cho coding agent

## Mục tiêu dự án

Xây dựng **AI Field Assistant**, ứng dụng mobile-first giúp nhân viên hiện trường ghi nhận sự cố bằng ảnh, văn bản hoặc giọng nói; dùng AI tạo báo cáo có cấu trúc; cho người dùng kiểm tra/chỉnh sửa trước khi lưu; và xem lại báo cáo trong lịch sử.

Ưu tiên Android để tạo demo/APK trong thời gian thử thách. Giao diện và tài liệu mặc định dùng tiếng Việt; giữ các thuật ngữ kỹ thuật tiếng Anh cần thiết.

## Trạng thái và nguồn yêu cầu

- Đọc `CHALLENGE_VI_ROADMAP.md` trước khi thực hiện thay đổi liên quan phạm vi sản phẩm.
- Thư mục này có thể còn trống ngoài các tài liệu kế hoạch. Không giả định đã có Flutter project, backend, API key hoặc dịch vụ được cấu hình.
- Nếu chưa có quyết định công nghệ và Flutter được cài đặt, ưu tiên Flutter để tạo bản Android. Nếu repo đã có công nghệ hoặc người dùng đã chọn công nghệ khác, tiếp tục theo lựa chọn đó thay vì tạo ứng dụng thứ hai.
- Nếu môi trường thiếu công cụ cần thiết, báo rõ trở ngại và đề xuất bước tiếp theo; không tạo các tệp giả như thể ứng dụng đã chạy.

## Thứ tự ưu tiên sản phẩm

1. Luồng MVP hoạt động đầu-cuối: nhập mô tả/chọn ảnh → tạo báo cáo → xem và sửa → lưu cục bộ → xem lịch sử.
2. Trạng thái loading, lỗi, timeout, thử lại và kiểm tra dữ liệu đầu vào.
3. Khả năng kiểm chứng nội dung AI và trải nghiệm dùng được trên màn hình điện thoại.
4. Tính năng cộng thêm như voice-to-text hoặc GPS chỉ sau khi MVP ổn định.

Không mở rộng phạm vi sang đăng nhập, đồng bộ cloud, push notification hay dashboard nếu chưa được yêu cầu rõ ràng.

## Quy tắc triển khai

- Trước khi sửa, kiểm tra cấu trúc repo, tài liệu hướng dẫn và thay đổi hiện có. Không ghi đè hoặc xóa công việc của người dùng.
- Làm theo từng lát chức năng nhỏ, chạy được; không tạo toàn bộ sản phẩm trong một lần nếu yêu cầu chỉ là một bước của roadmap.
- Dùng kiến trúc đơn giản, dễ giải thích. Tách tối thiểu model báo cáo, dịch vụ AI và nơi lưu báo cáo khi các phần đó được triển khai; tránh framework/abstraction không cần thiết.
- Giữ schema báo cáo thống nhất. Các trường cốt lõi: `category`, `location`, `priority`, `issue`, `suggested_action`, `summary`; có thể bổ sung thời gian tạo, trạng thái, đường dẫn ảnh và danh sách nội dung cần xác nhận.
- AI chỉ tạo **bản nháp đề xuất**. Không lưu báo cáo AI như nội dung đã xác nhận nếu chưa cho người dùng xem lại/chỉnh sửa/xác nhận.
- Không cho AI tự bịa thông tin thiếu. Biểu thị dữ liệu thiếu hoặc không chắc chắn để người dùng xác nhận; không trình bày `suggested_action` như hành động đã thực hiện.
- Parse và kiểm tra cấu trúc phản hồi AI trước khi dùng. Xử lý JSON sai định dạng, trường thiếu, API lỗi, mất mạng, timeout và đầu vào rỗng mà không làm ứng dụng crash hoặc mất nội dung người dùng nhập.
- Không giả lập tính năng cốt lõi như thể nó đang hoạt động. Nếu có placeholder, ghi rõ là placeholder và không mô tả trong README/demo như tính năng hoàn tất.
- Xin quyền camera/ảnh/vị trí đúng lúc cần dùng; hỗ trợ trường hợp người dùng từ chối quyền và cung cấp thông báo dễ hiểu.
- Lưu cục bộ phải dùng cơ chế phù hợp với dữ liệu có cấu trúc; không tuyên bố hỗ trợ offline vượt quá hành vi thực tế.

## Bảo mật và dữ liệu

- Không đưa API key, token, mật khẩu, dữ liệu cá nhân hoặc thông tin xác thực vào source code, Git, APK, log, ảnh chụp màn hình hay video.
- Không coi biến môi trường được nhúng lúc build mobile là nơi bảo vệ bí mật: giá trị trong ứng dụng phát hành có thể bị trích xuất.
- Tích hợp AI qua backend/proxy hoặc cơ chế dành cho ứng dụng khách có xác thực và giới hạn phù hợp. Nếu chưa thể cấu hình dịch vụ thật, nói rõ điều gì còn thiếu; không bịa phản hồi AI để tạo cảm giác đã tích hợp.
- Chỉ gửi dữ liệu cần thiết đến dịch vụ AI. Không log ảnh/nội dung hiện trường nếu không cần cho chẩn đoán.
- Không ghi dữ liệu nhạy cảm vào fixture, screenshot hoặc dữ liệu demo.

## Chất lượng và kiểm chứng

- Viết mã theo quy ước của công nghệ hiện có; giữ dependency ở mức tối thiểu và giải thích dependency mới khi cần.
- Với Flutter: format Dart, chạy `flutter analyze`, chạy các test liên quan và thử ứng dụng trên emulator/thiết bị nếu môi trường hỗ trợ.
- Ưu tiên kiểm tra có ý nghĩa cho model/schema, parse phản hồi AI, lưu/đọc báo cáo và các trạng thái lỗi. Không thêm test chỉ lặp lại chi tiết triển khai.
- Không tuyên bố đã chạy lệnh/test/build nếu thực tế chưa chạy. Nêu chính xác lệnh đã chạy, kết quả và phần chưa kiểm chứng.
- Sau thay đổi, tóm tắt các tệp/chức năng đã đổi, cách chạy/kiểm tra và trở ngại còn lại.

## Tài liệu và giao tiếp

- Trả lời người dùng bằng tiếng Việt, ngắn gọn và cụ thể; giữ nguyên tên API, lệnh, field hoặc thuật ngữ tiếng Anh khi cần.
- Cập nhật README khi có quyết định kiến trúc, bước chạy hoặc giới hạn sản phẩm mới.
- Ghi lại công cụ AI đã dùng, prompt quan trọng, lỗi/đề xuất sai của AI và cách kiểm chứng trong `AI_WORKLOG.md` khi bắt đầu có quá trình phát triển thực tế. Không bịa nhật ký hồi cứu.
- README và demo phải phân biệt rõ tính năng hoàn thành, tính năng chưa hoàn thành và giới hạn.
