# Prompt 01 — Khởi tạo nền tảng ứng dụng

Sao chép toàn bộ nội dung trong khung dưới đây và gửi cho coding agent đang làm việc trong thư mục dự án.

---

```text
Bạn là coding agent hỗ trợ tôi xây dựng ứng dụng di động AI Field Assistant cho thử thách 7 ngày.

Trước tiên, hãy đọc `AGENTS.md` và `docs/CHALLENGE_VI_ROADMAP.md`. Tuân thủ hướng dẫn trong `AGENTS.md`. Repo hiện có thể mới chỉ chứa tài liệu, vì vậy hãy kiểm tra trạng thái thực tế trước khi kết luận.

MỤC TIÊU CỦA LẦN LÀM VIỆC NÀY
Chỉ hoàn thành phần nền tảng của Ngày 1: xác nhận công nghệ/môi trường, khởi tạo ứng dụng chạy được, dựng khung điều hướng và giao diện cơ bản. Chưa tích hợp AI, camera, cơ sở dữ liệu, voice, GPS, đăng nhập hoặc cloud trong bước này.

QUY TRÌNH
1. Kiểm tra các tệp trong repo, đọc hướng dẫn dự án và xem có thay đổi người dùng nào cần giữ nguyên.
2. Kiểm tra công cụ Flutter/Dart và Android tooling có sẵn. Nếu repo đã có ứng dụng bằng công nghệ khác, không tạo một ứng dụng thứ hai; đề xuất và tiếp tục theo công nghệ hiện có.
3. Nếu repo chưa có ứng dụng và Flutter khả dụng, dùng Flutter cho Android-first MVP. Nếu Flutter không khả dụng, dừng trước khi tạo project, nêu rõ công cụ còn thiếu và đưa lệnh/các bước cài đặt phù hợp với môi trường hiện tại.
4. Trước khi sửa tệp, nêu ngắn gọn phát hiện, kế hoạch và giả định. Nếu không có blocker cần quyết định từ tôi, hãy tiến hành thực hiện trong phạm vi bên dưới, không chỉ trả về một bản kế hoạch.
5. Sau khi sửa, chạy các kiểm tra khả dụng và báo chính xác kết quả. Không tuyên bố build/test thành công nếu chưa chạy.

PHẠM VI TRIỂN KHAI
- Tạo một ứng dụng khởi chạy được với tên hiển thị “AI Field Assistant”.
- Giao diện ưu tiên điện thoại, ngôn ngữ tiếng Việt, bố cục đơn giản, dễ thao tác bằng một tay.
- Có hai khu vực điều hướng thật:
  1. “Tạo báo cáo”: màn hình khung giới thiệu ngắn mục đích ứng dụng và luồng chụp/nhập thông tin. Chưa hiển thị nút giả vờ gọi AI hoặc chụp ảnh.
  2. “Lịch sử”: trạng thái rỗng giải thích rằng báo cáo đã lưu sẽ xuất hiện tại đây.
- Điều hướng giữa hai khu vực phải hoạt động. Có trạng thái chọn tab rõ ràng và không bị tràn trên màn hình nhỏ.
- Dùng cấu trúc thư mục đơn giản, phù hợp quy mô prototype. Chưa tạo abstraction/dependency cho các tính năng chưa làm.
- Thêm README ngắn với tên sản phẩm, mục tiêu hiện tại, cách chạy theo đúng công nghệ được chọn và phần ghi rõ AI/camera/lưu trữ chưa tích hợp ở giai đoạn này.
- Không sửa nội dung `docs/CHALLENGE_VI_ROADMAP.md` hoặc `AGENTS.md` trừ khi phát hiện lỗi cần thiết; nếu cần sửa, giải thích lý do.

TIÊU CHÍ HOÀN THÀNH
- Ứng dụng khởi chạy và mở được hai khu vực điều hướng nêu trên.
- Không có nút cốt lõi giả hoặc nội dung khiến người xem tưởng AI đã chạy.
- Không thêm API key, token, dữ liệu cá nhân hoặc thông tin bí mật.
- README hướng dẫn chạy khớp với project thực tế.
- Báo cáo những tệp đã tạo/sửa, lệnh kiểm tra đã chạy, kết quả và việc cần làm ở bước tiếp theo.

Khi hoàn tất, dừng ở nền tảng Ngày 1. Không tự triển khai các ngày tiếp theo.
```

---

## Cách dùng

1. Mở thư mục dự án bằng coding agent (Cursor, Claude Code, Copilot Agent hoặc công cụ tương tự).
2. Đảm bảo agent nhìn thấy `AGENTS.md`, `docs/CHALLENGE_VI_ROADMAP.md` và `docs/PROMPT_01.md`.
3. Gửi phần prompt trong khung code. Sau khi agent hoàn tất, mở/chạy ứng dụng và kiểm tra kết quả trước khi yêu cầu bước tiếp theo.
