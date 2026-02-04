# 🔐 QE3 SSH Bruteforce Auto Blocker

QE3 SSH Bruteforce Auto Blocker adalah script keamanan ringan berbasis **Bash** untuk melindungi server Linux dari serangan **brute-force SSH** secara otomatis tanpa dependency tambahan seperti Fail2Ban.

- VPS & Dedicated Server
- Server produksi minimalis

---

## 🚀 Fitur Utama

- ✅ Auto block brute-force SSH
- ✅ 3x gagal login → IP langsung diblok
- ✅ Durasi block default 24 jam (86400 detik)
- ✅ Deteksi semua pola serangan SSH:
  - Failed password
  - Invalid user
  - Authentication failure
- ✅ Auto-run saat reboot (systemd)
- ✅ All-in-one script (1 file)
- ✅ Tanpa Python / Fail2Ban
- ✅ Ringan & stabil (iptables)

---

## 🧠 Cara Kerja

1. Script memonitor log SSH:
   - `/var/log/auth.log` (Debian / Ubuntu)
   - `/var/log/secure` (CentOS / RHEL)
2. Setiap IP dicatat jumlah kegagalan login
3. Jika gagal ≥ **3 kali**:
   - IP diblok via `iptables`
   - Timestamp disimpan
4. Setelah **24 jam**:
   - IP otomatis di-unblock

---

## 📦 Instalasi (One Command)

Clone repository:
```bash
git clone https://github.com/Sincan2/QE3-SSH-Bruteforce-Auto-Blocker.git
cd QE3-SSH-Bruteforce-Auto-Blocker
bash qe3.sh install
tail -f /var/log/qe3-ssh-block.log
qe3.sh unblock-all
iptables -L -n --line-numbers
