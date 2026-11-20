# GoOffice — Kiểm tra GTK3 trên Ubuntu 24.04 Desktop

> Tạo 20/11. GTK3 VCL plugin đã bật sẵn trong mọi bản Linux (`--enable-gtk3` trong
> `autogen/linux-*.input` + `libgtk-3-dev` trong CI). Tài liệu này là checklist
> xác minh trên desktop thật/VM — gap duy nhất chưa QA (QA cũ chỉ headless).

## Trạng thái tích hợp (khảo sát 20/11)

| Thành phần | Trạng thái |
|---|---|
| `--enable-gtk3` + `--enable-gio` + `--enable-dbus` | có trong cả 3 autogen Linux |
| CI deps `libgtk-3-dev` | có (`build.yml` linux-arm64) |
| Gói `libobasis1.0-gnome-integration` trong bộ deb | có (chứa `libvclplug_gtk3lo.so`) |
| `Depends: libgtk-3-0` trong control deb | **KHÔNG có** — giống hệt upstream TDF; Ubuntu Desktop luôn có sẵn GTK3 nên không ảnh hưởng. Nếu sau này hỗ trợ Ubuntu minimal/server: cân nhắc post-process thêm `Recommends`. |

## Cài + check tự động

```bash
# trong thư mục chứa GoOffice_1.0.0.0_Linux_x86-64_deb.tar.gz
tar -xzf GoOffice_1.0.0.0_Linux_x86-64_deb.tar.gz   # được DEBS/ + langpack-vi/
sudo apt-get update && sudo apt-get install -y ./DEBS/*.deb ./langpack-vi/*.deb
bash setup/check-gtk-linux.sh                        # 5 bước tự động
```

Lưu ý đường dẫn cài: `/opt/libreoffice1.0/program/` (tên basis nội bộ — không đổi
theo product name).

## Checklist bằng mắt (tóm tắt)

1. **GTK active**: đổi GNOME sang theme tối → menu/cửa sổ GoOffice theo theme tối
   (plugin `gen` sẽ không theo).
2. **File dialog native**: File→Open có sidebar kiểu GNOME (Places/Bookmarks).
3. **Wayland + X11**: kéo thả cửa sổ, menu chuột phải đúng vị trí; nếu Wayland lỗi
   thì thử `GDK_BACKEND=x11 soffice` và ghi chú.
4. **Tiếng Việt**: menu VI, gõ UniKey đúng, dict-vi gạch đỏ từ sai, export PDF không vỡ font.
5. **Icon/entry**: Activities hiện icon GoOffice (không phải LibreOffice).
6. **Gỡ sạch**: `sudo apt-get purge 'gooffice1.0*' 'libobasis1.0*' 'libreoffice1.0*'` → hết dấu vết.

## Quan hệ với GTK4

LO 26.8 có vclplug gtk4 nhưng gtk3 vẫn là mặc định của TDF và ổn định hơn.
Quyết định 20/11: **giữ gtk3**, không bật `--enable-gtk4` — theo dõi upstream,
xem xét lại khi TDF chuyển gtk4 làm mặc định.
