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

##  Widget yang Digunakan (Penjelasan)

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

## Tampilan Aplikasi owner

###  Login Screen

<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/2075c152-41a1-4fd4-b2b0-de004837bdda" />

### Dasbhord 

<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/98f595b9-3337-41e6-8e15-825fa56afc89" />

-----------------------------------------------------------------------------------------------------------------------------------
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/e2e36770-9355-4d59-a4f8-851f30dc2253" />

-----------------------------------------------------------------------------------------------------------------------------------
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/3ca061fb-98b2-4720-8065-0b227c1d1fc0" />

-----------------------------------------------------------------------------------------------------------------------------------
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/9a2c512f-c50e-4933-b05e-90b06e93a068" />

---


###  Manajemen menu

<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/a5a3753d-27ab-425a-9198-ab7f662798c6" />

-----------------------------------------------------------------------------------------------------------------------------------
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/83464cdc-d490-4f95-a680-08ae72733390" />

-----------------------------------------------------------------------------------------------------------------------------------
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/63039ef5-425f-447d-beb6-8d84be629680" />

-----------------------------------------------------------------------------------------------------------------------------------
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/71f2db27-19cf-48a3-9648-720eb337918f" />

-----------------------------------------------------------------------------------------------------------------------------------
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/6edfdcbc-27cd-4d3e-88c4-c6a21bb73c79" />

-----------------------------------------------------------------------------------------------------------------------------------
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/3a0358b7-5684-461c-9bc9-7ef29be4af3f" />

---

### POS Screen

<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/33e64bc2-3ac2-49d6-8865-23abe69a89aa" />

-----------------------------------------------------------------------------------------------------------------------------------
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/522c52ec-34bf-4b69-8330-4e69238c06a4" />



---

### Stok Screen

<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/0ad55a1f-97ab-43c3-b278-03ec5c96db8b" />

-----------------------------------------------------------------------------------------------------------------------------------
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/fb0d0159-d03a-4f6e-8075-1791f829620c" />

---

### Riwayat transaksi

<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/a3656889-236b-4aae-99fe-8f697a6ea66a" />

-----------------------------------------------------------------------------------------------------------------------------------
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/26a794d9-7760-4386-97bc-60110d568036" />

---

### Manajemen user

<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/f6841a92-464e-4020-aaf6-6b528608aac6" />

-----------------------------------------------------------------------------------------------------------------------------------
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/805033f0-b922-4d2a-83ee-67558a1a6d9d" />

-----------------------------------------------------------------------------------------------------------------------------------
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/ed4dee88-d7de-4102-a3c1-29e4017da133" />


---

## Tampilan Aplikasi barista

### Login Screen

<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/f200e6de-6c78-4a6c-96bc-f82ca9de590b" />

---

### Barista Screen order

<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/51b8310a-6f5f-4ad0-8195-514d28af8068" />

---

### Stok Screen

<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/0ad55a1f-97ab-43c3-b278-03ec5c96db8b" />

-----------------------------------------------------------------------------------------------------------------------------------
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/fb0d0159-d03a-4f6e-8075-1791f829620c" />

---


## Tampilan Aplikasi kasir

### Login Screen


<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/93c4a857-9d67-4b0e-8301-8b97b7b30b51" />


---

###  Manajemen menu

<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/a5a3753d-27ab-425a-9198-ab7f662798c6" />

-----------------------------------------------------------------------------------------------------------------------------------
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/83464cdc-d490-4f95-a680-08ae72733390" />

-----------------------------------------------------------------------------------------------------------------------------------
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/63039ef5-425f-447d-beb6-8d84be629680" />

-----------------------------------------------------------------------------------------------------------------------------------
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/71f2db27-19cf-48a3-9648-720eb337918f" />

-----------------------------------------------------------------------------------------------------------------------------------
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/6edfdcbc-27cd-4d3e-88c4-c6a21bb73c79" />

-----------------------------------------------------------------------------------------------------------------------------------
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/3a0358b7-5684-461c-9bc9-7ef29be4af3f" />

---

### POS Screen

<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/33e64bc2-3ac2-49d6-8865-23abe69a89aa" />

-----------------------------------------------------------------------------------------------------------------------------------
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/522c52ec-34bf-4b69-8330-4e69238c06a4" />



---

### Riwayat transaksi

<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/a3656889-236b-4aae-99fe-8f697a6ea66a" />

-----------------------------------------------------------------------------------------------------------------------------------
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/26a794d9-7760-4386-97bc-60110d568036" />

---


