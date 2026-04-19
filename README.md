# ☕ Nol Persen Cafe App

Aplikasi mobile berbasis Flutter yang dirancang untuk membantu digitalisasi operasional cafe secara terintegrasi, realtime, dan efisien.

---

## Deskripsi Aplikasi

**Nol Persen Cafe App** merupakan solusi digital untuk mengelola operasional cafe yang sebelumnya masih dilakukan secara manual. Sistem manual seperti pencatatan transaksi, pengecekan stok bahan, dan komunikasi pesanan seringkali menyebabkan keterlambatan, kesalahan data, serta kurangnya efisiensi kerja.

Melalui aplikasi ini, seluruh proses operasional diintegrasikan ke dalam satu sistem berbasis mobile yang mampu:

* Mengelola transaksi penjualan secara otomatis
* Memantau stok bahan baku secara realtime
* Menghubungkan kasir dan barista melalui sistem notifikasi
* Menyediakan riwayat dan rekapan data secara akurat

Aplikasi ini menggunakan pendekatan **role-based system**, sehingga setiap pengguna memiliki akses sesuai dengan perannya dalam operasional cafe.

---

##  Tujuan Pengembangan

Tujuan utama dari pengembangan aplikasi ini adalah:

1. Mengurangi kesalahan pencatatan transaksi
2. Mempercepat proses pelayanan pelanggan
3. Mempermudah monitoring stok bahan baku
4. Meningkatkan efisiensi kerja antar staff
5. Menyediakan sistem digital yang scalable

---

##  Role & Hak Akses

### Owner

Memiliki akses penuh terhadap seluruh fitur:

* Dashboard
* Manajemen menu
* Transaksi
* Stok bahan
* Riwayat penjualan
* Manajemen pengguna

###  Kasir

Fokus pada transaksi:

* Melihat menu
* Input pesanan (POS)
* Melihat riwayat transaksi
* Menerima notifikasi saat pesanan selesai

### Barista

Fokus pada produksi:

* Melihat pesanan masuk
* Update status pesanan
* Melihat stok bahan
* Menerima notifikasi pesanan baru

---

## Fitur Aplikasi 

###  1. Sistem Login & Manajemen User (CRUD User)
Aplikasi menyediakan sistem autentikasi menggunakan Supabase serta fitur manajemen pengguna (staf).

Fitur yang tersedia:
- Login pengguna
- Menampilkan data user
- Menambahkan user (staf)
- Mengubah role user (Owner / Kasir / Barista)
- Menghapus user

Fitur ini memungkinkan pengelolaan akses berdasarkan peran masing-masing pengguna.

---

###  2. Manajemen Menu (CRUD)

Fitur ini memungkinkan admin untuk:

* Menambahkan menu baru
* Mengubah informasi menu
* Menghapus menu
* Mengunggah gambar menu

Setiap menu memiliki atribut seperti nama, harga, kategori, dan status ketersediaan.

---

###  3. Sistem POS (Point of Sale)

Kasir dapat melakukan transaksi secara langsung melalui aplikasi:

* Memilih menu
* Menentukan jumlah pesanan
* Menghitung total otomatis (termasuk pajak)
* Menyimpan transaksi ke database

---



### 4.  Manajemen Stok

Sistem secara otomatis:

* Mengurangi stok bahan saat transaksi terjadi
* Mencatat log penggunaan bahan
* Menampilkan kondisi stok secara realtime

---

### 5.  Riwayat & Rekapan Transaksi

* Menampilkan semua transaksi yang pernah terjadi
* Menyediakan detail item setiap transaksi
* Membantu proses audit dan pengecekan data

---

### 6. Manajemen Order Barista
Fitur khusus untuk barista dalam mengelola pesanan:

- Melihat pesanan masuk secara realtime
- Melihat detail pesanan
- Mengubah status pesanan:
  - Baru → Diproses → Selesai

Fitur ini menjadi penghubung utama antara kasir dan barista dalam proses produksi minuman.

##  Widget yang Digunakan 

Aplikasi ini menggunakan berbagai widget Flutter untuk membangun UI yang responsif:

* `Scaffold` → struktur dasar halaman
* `AppBar` → navigasi atas
* `ListView` → menampilkan data dinamis
* `Card` → menampilkan item menu/transaksi
* `FutureBuilder` → menangani async data
* `IndexedStack` → navigasi multi-role
* `Dialog` → konfirmasi aksi
* `SnackBar` → feedback ke user

---

## Teknologi yang Digunakan

| Teknologi  | Penjelasan                   |
| ---------- | ---------------------------- |
| Flutter    | Framework frontend           |
| Supabase   | Backend (Auth, DB, Realtime) |


---

## Package 

### flutter_local_notifications

Digunakan untuk menampilkan notifikasi secara lokal setelah menerima event dari Supabase realtime.

---

### flutter_secure_storage

Digunakan untuk menyimpan session login secara aman di device.

---

### fancy_shimmer_image

Digunakan untuk memberikan efek loading saat gambar sedang dimuat.

---

### flutter_native_splash

Digunakan untuk menampilkan splash screen saat aplikasi dibuka.

---


## Struktur Folder Project

```
lib/
├── models/                # Model data (role, menu, dll)
│   └── role_config.dart
│
├── services/              # Logic backend (Supabase, notif, transaksi)
│   ├── auth_service.dart
│   ├── dashboard_service.dart
│   ├── history_service.dart
│   ├── ingredient_service.dart
│   ├── logout_service.dart
│   ├── menu_service.dart
│   ├── notification_service.dart
│   ├── order_realtime_service.dart
│   ├── secure_storage_service.dart
│   ├── storage_service.dart
│   ├── supabase_service.dart
│   ├── transaction_service.dart
│   └── user_service.dart
│
├── screens/               # UI halaman utama
│   ├── barista_orders_screen.dart
│   ├── dashboard_screen.dart
│   ├── login_screen.dart
│   ├── main_shell.dart
│   ├── menu_screen.dart
│   ├── pos_screen.dart
│   ├── register_screen.dart
│   ├── riwayat_screen.dart
│   ├── staff_screen.dart
│   └── stok_screen.dart
│
├── widgets/               # Komponen reusable
│   ├── app_alert.dart
│   ├── app_network_image.dart
│   ├── bottom_nav.dart
│   └── top_bar.dart
│
├── theme/                 # Styling aplikasi
│   └── app_theme.dart
│
└── main.dart              # Entry point aplikasi
```

## Tampilan Aplikasi Owner

### Login Screen
<p align="center">
  <img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/9092da66-1b6c-4337-96b7-7b56bb0a33d8" />
</p>

---

### Dashboard

<p align="center">
  <img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/e4bb5baa-e361-4d44-8892-39f421ee6dc6" />
</p>

---

### Manajemen Menu

<p align="center">
  <img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/5f66121f-d29f-4b15-9282-bdebfaa177cd" />
</p>



---

### POS Screen

<p align="center">
  <img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/344552b1-599c-472b-8751-ef9092d91812" />
</p>


---

### Stok Screen

<p align="center">
  <img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/fe94f2c4-f523-42e7-a94d-ab508aeed762" />
</p>


---

### Riwayat Transaksi

<p align="center">
  <img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/18027633-504a-48a2-ab08-4c2541ffbc24" />
</p>


---

### Manajemen User

<p align="center">
  <img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/dcf11caa-06f6-41d7-9541-64df6ba8d7f1" />
</p>


---

## Tampilan Aplikasi Barista

### Login Screen
<p align="center">
  <img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/1f8126d2-eff5-4919-9656-498b2c3d1837" />
</p>

---

### Barista Screen Order
<p align="center">
  <img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/606ced2e-1f2d-4f0f-b22e-e49213fed81f" />
</p>

---

### Stok Screen

<p align="center">
  <img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/4572d9b7-7fc2-4915-83ae-e0c4a399a1fc" />
</p>

<br><br>

<p align="center">
  <img src="https://github.com/user-attachments/assets/fb0d0159-d03a-4f6e-8075-1791f829620c" width="250"/>
</p>

---

## Tampilan Aplikasi Kasir

### Login Screen
<p align="center">
  <img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/101e3d7e-7c28-4373-b4f9-0c72acd879e6" />
</p>

---

### Manajemen Menu

<p align="center">
  <img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/f058c8ce-045a-46a3-91fc-58bdae8f8668" />
</p>


---

### POS Screen

<p align="center">
  <img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/073880fa-f0fa-48d2-b2db-31c0be87d304" />
</p>



---

### Riwayat Transaksi

<p align="center">
  <img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/8ec8cc11-0ec8-4ff1-a2e2-0a4cd3e0392c" />
</p>

