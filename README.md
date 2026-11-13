# GoOffice

## Cấu trúc repo

```
branding/          Bộ nhận diện GoOffice (intro.png, logo*.svg, about.svg, donate*.png)
autogen/           File autogen.input cho từng nền tảng build
scripts/           Script build local (Windows x64, Linux x64)
patches/           Patch riêng cho source LibreOffice (nếu cần)
patches/translations/  Patch bổ sung bản dịch tiếng Việt (áp vào repo LibreOffice/translations)
.github/workflows/ CI GitHub Actions cho macOS arm64/x64, Windows arm64, Linux arm64
```

## Build local

- **Windows amd64**: `scripts/build-win-x64.sh` (từ Git Bash; cần VS2022 + WSL Ubuntu như đã setup)
- **Linux amd64**: `scripts/build-linux-x64.sh` (trong WSL Ubuntu-24.04)

## Bản release (GitHub Actions)

Workflows build và xuất artifact: MSI (Windows), DMG (macOS), deb/rpm (Linux).

## Pháp lý / MPL 2.0

- GoOffice theo giấy phép **MPL 2.0**.
- Tên và logo "LibreOffice" là trademark của The Document Foundation — GoOffice không sử dụng các trademark đó; mọi nhận diện hiển thị là GoOffice.
- Các văn bản license gốc (COPYING.MPL, COPYING, COPYING.LGPL...) được giữ nguyên trong bản phân phối.
- GoOffice không dùng cơ chế online-update/breakpad (crash report) của TDF.
