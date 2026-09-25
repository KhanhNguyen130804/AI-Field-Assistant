---
name: git-workflow
description: Use for Git workflows including git status, diff, branch, stage, commit, push, merge, conflict handling, and GitHub pull requests; follow a review-first workflow that protects existing work and repository history.
---

# Git Workflow

Áp dụng quy trình này khi người dùng yêu cầu kiểm tra hoặc thay đổi trạng thái Git. Giữ nguyên thay đổi có sẵn của người dùng; không commit, push, rebase, merge hoặc tạo pull request nếu chưa được yêu cầu rõ ràng.

## 1. Xác định trạng thái trước khi làm

Trong thư mục dự án, kiểm tra tối thiểu:

```bash
git status --short --branch
git branch --show-current
git remote -v
git log --oneline -10
git diff --stat
git diff --cached --stat
```

- Nếu thư mục không phải Git repository, không tự chạy `git init` hoặc gắn remote; chỉ làm khi người dùng yêu cầu khởi tạo/kết nối Git.
- Phân biệt thay đổi đã commit, thay đổi chưa stage, thay đổi đã stage, file mới và file bị `.gitignore` bỏ qua.
- Đọc diff và các file liên quan trước khi sửa hoặc stage. Giữ lại thay đổi người dùng có sẵn, kể cả khi chúng không thuộc yêu cầu hiện tại.
- Nếu repo có quy ước nhánh hoặc commit message, làm theo lịch sử hiện có. Không tự áp đặt GitFlow hoặc tạo nhánh nếu dự án không yêu cầu.

## 2. Chỉnh sửa và stage

- Chỉ stage các file cần cho yêu cầu hiện tại. Ưu tiên đường dẫn tường minh:

  ```bash
  git add path/to/file1 path/to/file2
  ```

- Chỉ dùng `git add -A` khi người dùng yêu cầu đưa toàn bộ thay đổi hiện tại vào commit và đã kiểm tra mọi file mới, file sửa/xóa, cùng file bị bỏ qua.
- Không stage file build/cache, cấu hình cục bộ, dữ liệu cá nhân, `.env`, API key/token, keystore hoặc thông tin xác thực. Kiểm tra `.gitignore`; không force-add file bị ignore nếu chưa xác định rõ nội dung và lý do.
- Không dùng `git stash`, `git checkout` để bỏ thay đổi, `git restore`, `git reset --hard` hoặc `git clean` nhằm xử lý tình cờ các thay đổi sẵn có. Nếu cần thao tác có thể làm mất dữ liệu, dừng và xin xác nhận.

## 3. Rà soát trước commit

Chỉ commit khi người dùng yêu cầu. Trước đó, xem lại:

```bash
git status --short
git diff --cached --check
git diff --cached --stat
git diff --cached
```

- Xác nhận diff đã stage chỉ chứa phần việc được yêu cầu; kiểm tra đặc biệt file xóa, file nhị phân, cấu hình và secret.
- Chạy kiểm tra phù hợp với thay đổi. Báo lỗi kiểm tra trung thực; không che lỗi bằng cách bỏ test/hook.
- Viết commit message ngắn, mô tả thay đổi và theo style của `git log`.
- Nếu Git chưa có author/committer identity, kiểm tra metadata commit gần nhất. Chỉ được tái sử dụng identity đã được xác minh là chủ repo/người dùng hiện tại trong thao tác trước, truyền tạm bằng `git -c` và không lưu vào `git config`; không suy đoán từ tên máy/tài khoản hệ điều hành. Nếu chưa xác minh được identity, hỏi người dùng cung cấp/cấu hình trước khi commit.
- Không tạo commit rỗng, không amend commit đã tồn tại và không dùng `--no-verify`/bỏ qua hooks.

## 4. Push an toàn

Chỉ push khi người dùng yêu cầu. Trước khi push:

1. Xác nhận remote, nhánh hiện tại và upstream đúng với đích người dùng muốn.
2. Fetch remote để cập nhật thông tin theo dõi; xem các commit local/remote và kiểm tra repo không có thay đổi cần giữ lại.
3. Nếu nhánh chỉ cần fast-forward an toàn, cập nhật theo cách không viết lại lịch sử rồi push.
4. Nếu hai nhánh đã phân kỳ, có conflict, hoặc remote có nội dung chưa được xem xét, không force-push và không tự xóa/viết lại lịch sử; báo tình trạng và hỏi cách xử lý.
5. Với nhánh mới, đặt upstream tới đúng remote/branch. Không đoán tên remote hoặc đẩy lên `main` nếu đích chưa rõ.

Sau thao tác, xác nhận bằng `git status --short --branch`, `git log --oneline -3` và trạng thái upstream/remote. Nêu chính xác branch, commit và kết quả push.

## 5. GitHub và lỗi thường gặp

- Dùng `gh` cho GitHub pull request, issue, checks và release khi các tác vụ đó được yêu cầu.
- Không đưa token vào command line, remote URL, file dự án hoặc output. Không in lại thông tin xác thực nếu lệnh Git hiển thị chúng.
- Nếu thiếu quyền/authentication, dừng và báo cách người dùng cần xác thực; không tìm hoặc đọc token từ máy người dùng.
- Nếu có conflict, bảo toàn cả hai phía và chỉ giải quyết khi ý định rõ. Với conflict ngữ nghĩa hoặc dữ liệu người dùng, trình bày các lựa chọn và hỏi trước.
- Nếu lệnh Git thất bại, giữ nguyên trạng thái; đọc lỗi và kiểm tra repository trước khi thử lại. Không lặp lệnh destructive để ép thành công.

## Checklist nhanh

- [ ] Đã kiểm tra branch, status, remote, history và diff ban đầu.
- [ ] Đã giữ nguyên thay đổi có sẵn không thuộc yêu cầu.
- [ ] Chỉ stage đúng file; không có secret, cấu hình cục bộ hoặc artifact.
- [ ] Đã review staged diff và chạy checks phù hợp trước commit.
- [ ] Chỉ commit/push/tạo PR khi được yêu cầu rõ ràng.
- [ ] Đã kiểm tra trạng thái cuối và báo kết quả chính xác.
