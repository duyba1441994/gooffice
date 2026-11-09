# Hướng dẫn làm việc trên 2 máy (Dual-PC Guide)

> Áp dụng cho dự án GoOffice khi làm việc song song trên **PC cũ** và **PC mới**.
> Tạo ngày 2026-11-09. Nguyên tắc cốt lõi: **GitHub là nguồn chân lý duy nhất**.

## 1. Nguyên tắc vàng

1. **Mọi thứ sống trên GitHub** — code, patch, workflow CI, tài liệu. Máy chỉ là nơi làm việc tạm.
2. **Commit + push thường xuyên, commit nhỏ** — mất mát tối đa khi sự cố = 1 commit nhỏ.
3. **Chỉ MỘT máy chỉnh một khu vực tại một thời điểm** — đặc biệt `.github/workflows/build.yml` và `patches/` khi đang chạy vòng debug CI. Máy còn lại chỉ theo dõi (`gh run list`).
4. **Trước khi bắt đầu và trước khi rời máy: `git sync`** (xem §3).

## 2. Thiết lập mỗi máy (đã xong trên cả 2 máy)

```bash
git clone https://github.com/duyba144194/gooffice
gh auth login          # xong trên cả 2 máy (tài khoản duyba144194)
gh auth setup-git      # để git push dùng credential của gh

# Alias đồng bộ 1 lệnh:
git config --global alias.sync '!git pull --rebase --autostash && git push'
```

Lưu ý PC mới: `git`/`gh` cài qua winget có thể không có trong PATH của shell cũ — dùng đường dẫn đầy đủ
`"C:\Program Files\Git\bin\git.exe"` và `"C:\Program Files\GitHub CLI\gh.exe"`.

## 3. Quy trình hằng ngày

| Thời điểm | Lệnh | Tác dụng |
|---|---|---|
| Ngồi vào máy | `git sync` | Lấy toàn bộ công việc máy kia vừa đẩy lên |
| Trong lúc làm | `git add -A && git commit -m "..."` (nhiều commit nhỏ) | Lưu mốc an toàn |
| Rời máy / xong việc | `git sync` | Đẩy lên + chắc chắn không tụt hậu |

`git sync` = `git pull --rebase --autostash && git push`: tự cất thay đổi đang dở, rebase lên bản mới nhất của GitHub rồi đẩy lên.

## 4. Khi bị xung đột (conflict)

Xảy ra khi cả 2 máy sửa cùng chỗ và cùng đẩy gần như đồng thời:

```bash
git pull --rebase --autostash
# nếu báo CONFLICT:
git status                      # xem file xung đột, sửa tay các đoạn <<<<<<<
git add <file>
git rebase --continue
git push
```

Cách phòng: đúng nguyên tắc 3 ở §1 — trước khi đụng vào file, `git sync` trước.

## 5. Những thứ KHÔNG đồng bộ qua git (cẩn thận!)

- Thay đổi **chưa commit** / **stash** — chỉ nằm trên máy tạo ra nó.
- **Phiên làm việc của trợ lý AI (ZCode...)** — không đi theo repo.
- **Sản phẩm build, artifact CI, thư mục build tạm** (~hàng trăm GB) — mỗi máy tự có; artifact CI lấy qua `gh run download`.
- **Ghi nhớ (memory) của trợ lý** — nằm riêng theo máy.

## 6. Làm việc với CI (GitHub Actions)

```bash
# Chạy build cho một nền tảng (hoặc bấm nút Run workflow trên web):
gh workflow run build.yml --repo duyba144194/gooffice -f platforms=win-x64
# platforms: win-x64 | win-arm64 | macos-arm64 | macos-x64 | macos-x64-cross | linux-arm64

# Theo dõi:
gh run list --repo duyba144194/gooffice --limit 5
gh run watch                       # theo dõi run mới nhất
gh run view <run-id> --log-failed  # xem log bước bị lỗi
gh run download <run-id> --name <artifact>   # tải artifact (MSI/DMG/deb...)
```

Qui tắc: **chỉ một máy gánh vòng debug CI** (hiện PC cũ gánh Windows CI). Máy kia theo dõi và chẩn đoán hỗ trợ — không đẩy patch/commit trùng làm loạn vòng lặp.

## 7. Hiện trạng tham chiếu (cập nhật 2026-11-09)

- **win-x64 CI: XANH** từ 07/11 (run 42331838491, patch 0024 — 31 vòng debug, patch 0001–0024).
- **win-arm64 CI: đang port** (round 34+). Trước khi arm64 xanh, **KHÔNG xóa** `src/core` và `build-win-arm64` trên PC cũ (nguồn artifact pregen cho `generated/`).
- Release v1.0.0: 18 assets (Win x64/arm64 MSI, Linux deb, macOS DMG).
- Sau khi arm64 xanh: chạy checklist tắt PC cũ trong `MIGRATION.md` (git status sạch → không commit chưa push → xóa ~270GB theo mục 6).
