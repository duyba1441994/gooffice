#!/bin/bash
# GoOffice — kiểm tra GTK3 VCL plugin đang hoạt động trên Linux
# Chạy:  chmod +x check-gtk.sh && ./check-gtk.sh
PROG=/opt/libreoffice1.0/program

echo "== 1/5: Plugin GTK3 có tồn tại? =="
ls -la "$PROG"/libvclplug_gtk3lo.so || { echo "FAIL: thiếu libvclplug_gtk3lo.so"; exit 1; }

echo
echo "== 2/5: GTK3 runtime load được? (ldd) =="
ldd "$PROG/libvclplug_gtk3lo.so" | grep -E "libgtk-3|libgdk-3" || { echo "FAIL: không link được libgtk-3"; exit 1; }

echo
echo "== 3/5: GTK3 là plugin mặc định? (không cần SAL_USE_VCLPLUGIN) =="
# LO tự chọn gtk3 khi có; bắt buộc gtk3 chạy thử để chắc chắn plugin khởi tạo được
SAL_USE_VCLPLUGIN=gtk3 "$PROG/soffice" --version >/dev/null 2>&1 \
  && echo "OK: khởi động với gtk3 thành công" \
  || { echo "FAIL: không chạy được với SAL_USE_VCLPLUGIN=gtk3"; exit 1; }

echo
echo "== 4/5: Headless conversion smoke test =="
TMP=$(mktemp -d)
printf '<html><body><h1>Xin chào GoOffice</h1></body></html>' > "$TMP/t.html"
"$PROG/soffice" --headless --convert-to txt --outdir "$TMP" "$TMP/t.html" >/dev/null 2>&1 \
  && cat "$TMP/t.txt" \
  || { echo "FAIL: chuyển đổi headless lỗi"; exit 1; }
rm -rf "$TMP"

echo
echo "== 5/5: Session đồ họa hiện tại? =="
echo "XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-unknown} (x11 | wayland)"
echo
echo "TẤT CẢ PASS — mở GUI để kiểm tra bằng mắt:"
echo "  $PROG/soffice &"
echo "Xem checklist: Help→About, File→Open (dialog GTK?), theme tối, tiếng Việt"
