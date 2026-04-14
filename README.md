# ☕ Nol Persen Cafe App

Aplikasi mobile berbasis Flutter untuk digitalisasi operasional cafe secara modern, cepat, dan realtime.

---

## Tentang Aplikasi

**Nol Persen Cafe App** merupakan aplikasi mobile yang dikembangkan untuk membantu pengelolaan operasional cafe secara terintegrasi, mulai dari transaksi penjualan hingga manajemen stok bahan baku.

Aplikasi ini dibangun sebagai solusi atas permasalahan operasional manual seperti:
- Rekapan penjualan yang memakan waktu
- Ketidaksesuaian data transaksi
- Tidak adanya monitoring stok yang sistematis
- Komunikasi pesanan yang tidak efektif

Dengan mengintegrasikan teknologi modern, aplikasi ini menghadirkan sistem yang:

 **Efisien** → Semua proses otomatis  
 **Realtime** → Update langsung tanpa refresh  
 **Akurat** → Minim kesalahan manusia  
 **Aman** → Autentikasi berbasis role  

---

## Role Pengguna

Aplikasi menggunakan sistem role-based:

| Role | Akses |
|------|------|
| Owner | Dashboard, Menu, POS, Stok, Riwayat, Pengguna |
| Kasir | Menu, POS, Riwayat |
| Barista | Order, Stok |

---

## Fitur Aplikasi

### Autentikasi
- Login menggunakan Supabase Auth
- Penyimpanan session menggunakan Secure Storage
- Role-based access control

---

### CRUD Data Menu
- Tambah menu
- Edit menu
- Hapus menu
- Upload gambar menu
- Status aktif/nonaktif menu

---

### Sistem POS (Transaksi)
- Input pesanan pelanggan
- Pilih metode pembayaran (Tunai / QRIS)
- Hitung otomatis subtotal, pajak, total
- Simpan transaksi ke database


---

### 📦 Manajemen Stok
- Monitoring stok bahan baku
- Update stok otomatis saat transaksi
- Log penggunaan bahan (stock_logs)

---

###  Rekapan & Riwayat
- Melihat semua transaksi
- Detail item transaksi
- Monitoring penjualan

---

##  Widget yang Digunakan

Aplikasi menggunakan berbagai widget Flutter:

- `MaterialApp`
- `Scaffold`
- `AppBar`
- `BottomNavigationBar`
- `ListView`
- `Card`
- `TextField`
- `DropdownButton`
- `FutureBuilder`
- `IndexedStack`
- `Dialog`
- `SnackBar`
- `GestureDetector`

---

## Teknologi

| Teknologi | Kegunaan |
|----------|--------|
| Flutter | Frontend mobile |
| Supabase | Backend (Auth, DB, Realtime) |

---

## 📦 Package yang Digunakan

### Wajib
- `supabase_flutter`
- `flutter_dotenv`

---

### Nilai Tambah

#### flutter_local_notifications
Menampilkan notifikasi 

#### 🔐 flutter_secure_storage
Menyimpan session login secara aman

#### 🖼 fancy_shimmer_image
Animasi loading gambar menu

#### 🚀 flutter_native_splash
Splash screen saat aplikasi dibuka

---

##  Keamanan

- Menggunakan `.env` untuk menyimpan:
  - Supabase URL
  - Supabase API Key
- API Key tidak ditulis langsung di kode

---

## Struktur Project
