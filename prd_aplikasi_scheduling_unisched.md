# PRODUCT REQUIREMENTS DOCUMENT (PRD)
**Project Name:** UniSched (Aplikasi Manajemen Jadwal Kuliah & Pengingat Tugas)  
**Document Version:** 1.0 (AI-Agent Optimized Specification)  
**Architecture Paradigm:** Offline-First Mobile Application with Hybrid Cloud Sharing  
**Target Platform:** Android & iOS (Mobile)  

---

## 1. INSTRUKSI KONTEKS UNTUK AI AGENT (SYSTEM PROMPT GUIDELINES)
> **Perhatian untuk AI Coding Assistant (Gemini AI):**
> 1. Aplikasi ini menggunakan arsitektur **Offline-First**. Seluruh operasi CRUD utama (Jadwal Kuliah, KRS, Tugas, dan Alarm Lokal) **WAJIB** dieksekusi langsung ke database lokal (SQLite) di perangkat pengguna tanpa ketergantungan jaringan internet.
> 2. Koneksi internet (**Online Mode**) **HANYA** digunakan untuk:
>    - Mengunggah payload JSON saat berbagi jadwal/tugas via Link/Kode Unik ke grup/publik.
>    - Mengunduh data jadwal/tugas dari Link/Kode Unik yang dibagikan pengguna lain.
>    - Mengunduh koleksi suara alarm tambahan dari katalog *cloud* (opsional).
> 3. Berbagi 1 item tugas via **QR Code** dilakukan **100% Offline** dengan mengenkode *minified JSON* langsung ke dalam gambar QR Code.
> 4. Navigasi utama aplikasi dibatasi secara ketat hanya pada **3 Tab Utama (Bottom Navigation Bar)**: **Home**, **Jadwal**, dan **Tugas**. Fitur tambahan (Import, Share, Settings) wajib menggunakan *Modal Bottom Sheet*, *Dialog*, atau *Header Action Icon*.

---

## 2. RINGKASAN PRODUK & TUJUAN (PRODUCT OVERVIEW)
Aplikasi *scheduling* personal dan publik yang dirancang khusus untuk mahasiswa guna mengelola jadwal mata kuliah (KRS) dan tenggat waktu (*deadline*) tugas perkuliahan. Aplikasi ini memprioritaskan kecepatan akses secara *offline*, dilengkapi pengingat berjenjang (Notifikasi Sistem & Alarm Audio Kustom), serta fitur berbagi jadwal/tugas instan antar mahasiswa melalui QR Code, Kode Unik, dan Deep Link.

---

## 3. ARSITEKTUR TEKNIS & REKOMENDASI TECH STACK
*(Catatan untuk AI Agent: Gunakan stack di bawah ini kecuali diperintahkan berbeda oleh developer pada prompt selanjutnya)*
* **Local Database:** SQLite (menggunakan ORM/Wrapper seperti Room, Drift, atau Expo-SQLite).
* **Local File Storage:** Penyimpanan direktori internal aplikasi (`App Documents Directory`) untuk menyimpan salinan file audio alarm kustom yang diimpor pengguna dari penyimpanan HP.
* **Background Task & Alarm Engine:** Native Alarm Manager / WorkManager + Local Push Notification (mendukung *Full-Screen Intent* dan eksekusi saat aplikasi tertutup / *killed* serta melewati mode *Doze*).
* **QR Code Engine:** Local QR Generator & Barcode Scanner (berbasis kamera perangkat).
* **Backend / Cloud Service (Hanya untuk fitur Online):** REST API ringan (Node.js/Express atau Laravel) atau Serverless (Firebase/Supabase) untuk menyimpan *snapshot* JSON jadwal/tugas yang dibagikan via Link/Kode.

---

## 4. SKEMA DATABASE LOKAL (SQLITE SCHEMA)

AI Agent wajib mengimplementasikan struktur tabel relasional berikut secara presisi:

### 4.1. Tabel `courses` (Data Mata Kuliah / KRS)
```sql
CREATE TABLE courses (
    id TEXT PRIMARY KEY,               -- UUID v4
    course_name TEXT NOT NULL,         -- Nama Mata Kuliah (contoh: "Pemrograman Web")
    course_code TEXT,                  -- Kode Matkul / KRS (contoh: "IF204")
    sks INTEGER DEFAULT 0,             -- Jumlah SKS (contoh: 3)
    lecturer_name TEXT,                -- Nama Dosen Pengampu
    room TEXT,                         -- Ruangan Kelas (contoh: "Lab 3 / R. 402")
    day_of_week INTEGER NOT NULL,      -- Hari: 1 (Senin) s/d 7 (Minggu)
    start_time TEXT NOT NULL,          -- Format HH:mm (24-jam, contoh: "08:00")
    end_time TEXT NOT NULL,            -- Format HH:mm (24-jam, contoh: "10:30")
    color_hex TEXT DEFAULT '#3B82F6',  -- Warna label kartu mata kuliah
    created_at TEXT NOT NULL,          -- ISO 8601 Timestamp
    updated_at TEXT NOT NULL           -- ISO 8601 Timestamp
);
```

### 4.2. Tabel `tasks` (Data Tugas Kuliah)
```sql
CREATE TABLE tasks (
    id TEXT PRIMARY KEY,               -- UUID v4
    course_id TEXT,                    -- Foreign Key ke courses.id (Nullable jika tugas umum)
    title TEXT NOT NULL,               -- Nama Tugas
    description TEXT,                  -- Catatan / detail instruksi tugas
    deadline_datetime TEXT NOT NULL,   -- ISO 8601 (YYYY-MM-DDTHH:mm:00)
    reminder_datetime TEXT NOT NULL,   -- ISO 8601 (YYYY-MM-DDTHH:mm:00)
    is_alarm_enabled INTEGER DEFAULT 1,-- Boolean (0 = Hanya Notifikasi, 1 = Notifikasi + Alarm)
    alarm_sound_id TEXT,               -- Foreign Key ke alarm_sounds.id
    is_completed INTEGER DEFAULT 0,    -- Boolean (0 = Belum Selesai, 1 = Selesai)
    shared_origin_code TEXT,           -- Menyimpan ID/Kode unik jika tugas berasal dari hasil import
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE SET NULL
);
```

### 4.3. Tabel `alarm_sounds` (Manajemen Audio Alarm)
```sql
CREATE TABLE alarm_sounds (
    id TEXT PRIMARY KEY,               -- UUID v4
    title TEXT NOT NULL,               -- Nama tampilan audio
    source_type TEXT NOT NULL,         -- Enum: 'DEFAULT' | 'LOCAL_IMPORT' | 'CLOUD_DOWNLOAD'
    local_file_path TEXT NOT NULL,     -- Path absolut di local storage HP
    remote_url TEXT,                   -- URL sumber jika diunduh dari katalog online (Nullable)
    created_at TEXT NOT NULL
);
```

---

## 5. SPESIFIKASI 3 HALAMAN UTAMA (UI/UX & LOGIC FLOW)

Aplikasi memiliki **Bottom Navigation Bar** dengan 3 tab: **Home**, **Jadwal**, dan **Tugas**.

### 5.1. Halaman 1: HOME (Dashboard Hari Ini)
**Tujuan:** Memberikan ringkasan eksekutif mengenai aktivitas akademik hari ini dan tugas paling mendesak.
* **Header:**
  * Menampilkan sapaan, Hari, dan Tanggal hari ini.
  * **Ikon Pengaturan (Settings)** di pojok kanan atas (membuka Modal Pengaturan Alarm Default & Backup Data).
* **Section A: Kelas Selanjutnya (Next Class Highlight Card):**
  * Menampilkan 1 mata kuliah terdekat yang akan berlangsung hari ini berdasarkan jam saat ini (`current_time < start_time`).
  * Dilengkapi *countdown badge* (contoh: *"Mulai dalam 35 menit"*). Jika kelas sedang berlangsung (`start_time <= current_time <= end_time`), tampilkan badge *"Sedang Berlangsung"*.
* **Section B: Jadwal Mata Kuliah Hari Ini:**
  * Menampilkan daftar seluruh mata kuliah pada hari ini (`day_of_week == current_day`), diurutkan berdasarkan `start_time` paling pagi (`ASC`).
  * Jika tidak ada jadwal hari ini, tampilkan *Empty State*: *"Tidak ada jadwal kuliah hari ini. Waktunya istirahat atau cicil tugas!"*.
* **Section C: Tugas Deadline Terdekat (Urgent Tasks):**
  * Menampilkan maksimal **5 tugas aktif** (`is_completed == 0`) yang memiliki `deadline_datetime` paling dekat dari waktu sekarang.
  * Urutan wajib: `ORDER BY deadline_datetime ASC`.
  * Setiap kartu tugas menampilkan: Judul Tugas, Nama Mata Kuliah (badge warna), Sisa Waktu / Jam Deadline, Checkbox "Selesai", dan Ikon Share.

---

### 5.2. Halaman 2: JADWAL (Schedule & KRS Management)
**Tujuan:** Melihat jadwal mingguan per hari, mengelola daftar KRS, serta membagikan/mengimpor jadwal kelas.
* **Header & Action Bar:**
  * Judul Halaman: "Jadwal Kuliah".
  * **Action Icons (Pojok Kanan Atas):**
    1. `[Ikon QR/Import]`: Membuka *Modal Import Jadwal* (Scan QR / Input Kode Unik).
    2. `[Ikon Share]`: Membuka *Modal Bagikan Jadwal* (Nonaktif/*disabled* jika database `courses` masih kosong).
    3. `[Tombol KRS / Kelola]`: Membuka daftar seluruh mata kuliah dalam 1 semester (mode *list* lengkap untuk edit/hapus massal).
* **Komponen Utama: Horizontal Day Selector (Tab Hari):**
  * Berisi 7 tab hari: **Sen, Sel, Rab, Kam, Jum, Sab, Min**.
  * Secara *default*, tab yang aktif saat halaman dibuka adalah **hari ini**.
* **Daftar Jadwal Harian:**
  * Menampilkan kartu mata kuliah sesuai hari yang dipilih, diurutkan berdasarkan `start_time ASC`.
  * Informasi di dalam Card: Nama Matkul, Kode/KRS & SKS, Jam Mulai - Jam Selesai, Ruangan, dan Nama Dosen.
* **Empty State (Kondisi Awal Aplikasi Kosong):**
  * Jika belum ada mata kuliah sama sekali, tampilkan 2 tombol aksi utama di tengah layar:
    1. **`[ + Input Jadwal Manual ]`**
    2. **`[ 📷 Import Jadwal Teman (QR / Kode) ]`**
* **Floating Action Button (FAB):** Tombol `[ + ]` di kanan bawah untuk menambah mata kuliah baru.

---

### 5.3. Halaman 3: TUGAS (Task & Reminder Management)
**Tujuan:** Memantau tenggat waktu tugas dengan fokus utama pada tugas yang berjarak kurang dari 2 hari (< 48 jam).
* **Filter Bar (Horizontal Filter Chips di Bagian Atas):**
  1. **`[ Segera (< 2 Hari) ]` (DEFAULT AKTIF):** Menampilkan tugas dengan `is_completed == 0` DAN `deadline_datetime` berada dalam rentang waktu sekarang hingga **+48 jam ke depan** (`NOW() <= deadline <= NOW() + 48 hours`), termasuk tugas yang sudah *Overdue* (terlewat tapi belum dicentang selesai).
  2. **`[ Per Hari / Kalender ]`:** Memunculkan *horizontal date picker* (pemilih tanggal harian) sehingga pengguna bisa mengecek tugas spesifik pada tanggal tertentu.
  3. **`[ Semua Aktif ]`:** Menampilkan seluruh tugas yang belum selesai (`is_completed == 0`) tanpa batasan 2 hari, diurutkan dari *deadline* terdekat (`ASC`), agar tugas minggu depan tetap bisa dipantau.
  4. **`[ Selesai ]`:** Menampilkan riwayat tugas dengan `is_completed == 1`.
* **Komponen Task Card:**
  * Menampilkan: Judul Tugas, Label Mata Kuliah (otomatis terhubung dari tabel `courses`), Waktu Deadline, Waktu Pengingat & Ikon Status Alarm, Checkbox Selesai, serta **Ikon Share Tugas (Satuan)**.
  * Indikator Visual: Jika `deadline < 24 jam`, berikan aksen border/badge **Merah (Urgent)**. Jika `< 48 jam`, berikan aksen **Kuning/Oranye (Warning)**.
* **Floating Action Button (FAB) `[ + Tambah Tugas ]`:**
  * Saat diklik, menampilkan *Speed Dial / Bottom Sheet* dengan 2 opsi:
    1. **Input Tugas Baru (Manual):** Membuka form input (Pilih Matkul dari Dropdown KRS, Nama Tugas, Deskripsi, Tanggal & Jam Deadline, Tanggal & Jam Pengingat, Toggle Alarm On/Off, Pilih Suara Alarm).
    2. **Import Tugas Teman (Scan QR / Kode):** Membuka pemindai QR atau kolom input kode tugas.

---

## 6. SPESIFIKASI FITUR KHUSUS (CORE FUNCTIONAL MODULES)

### 6.1. Sistem Notifikasi, Alarm & Custom Audio
1. **Trigger Pengingat:** Saat `current_time == reminder_datetime` dan `is_completed == 0`:
   * Jika `is_alarm_enabled == 0`: Kirim *Standard Push Notification* ke sistem HP.
   * Jika `is_alarm_enabled == 1`: Picu *Full-Screen Alarm Intent* disertai pemutaran audio berulang (*looping*) dari `local_file_path` dan getaran (*vibration*) hingga pengguna menekan tombol **"Matikan (Dismiss)"** atau **"Tunda 10 Menit (Snooze)"**.
2. **Auto-Cancel Alarm:** Jika pengguna mencentang tugas menjadi **Selesai (`is_completed = 1`)** sebelum waktu pengingat tiba, sistem wajib membatalkan (*cancel*) jadwal alarm di *OS Alarm Manager*.
3. **Mekanisme Audio Alarm (Offline vs Online):**
   * **Import Manual Pribadi (Offline):** Pengguna memilih file `.mp3` / `.wav` / `.m4a` dari memori internal HP melalui *File Picker*. Aplikasi menyalin file tersebut ke direktori lokal aplikasi dan mencatatnya di tabel `alarm_sounds` dengan `source_type = 'LOCAL_IMPORT'`.
   * **Unduh Nada Alarm (Online):** Pengguna membuka katalog suara alarm online di dalam aplikasi (membutuhkan internet), memilih nada dering, lalu aplikasi mengunduh file tersebut ke penyimpanan lokal HP (`source_type = 'CLOUD_DOWNLOAD'`) agar saat alarm berbunyi tetap berjalan 100% *offline*.

### 6.2. Sistem Share & Import (Jadwal Kolektif & Tugas Satuan)

#### A. Aturan Pengirim (Sender Flow)
1. **Syarat Awal:** Pengirim wajib sudah memiliki data di database lokal (minimal 1 mata kuliah untuk *Share Jadwal*, atau 1 tugas untuk *Share Tugas*).
2. **Share Jadwal (KRS):**
   * Dari Halaman Jadwal, pengirim klik ikon **Share**, memilih mata kuliah mana saja yang ingin dibagikan (default: *Select All*).
   * **Opsi 1 (QR Code Lokal):** Menghasilkan QR Code di layar.
   * **Opsi 2 (Link / Kode Unik - Butuh Internet):** Aplikasi mengirim *payload* JSON ke server, lalu menerima Kode pendek (contoh: `KRS-7F9A`) dan Deep Link (`https://unisched.app/import?code=KRS-7F9A`) untuk dibagikan ke WhatsApp.
3. **Share Tugas (Satuan / Per Item):**
   * Pada setiap *card* tugas, pengirim menekan ikon **Share**.
   * Muncul *Pop-up Modal* yang langsung menampilkan **QR Code** (bisa di-*scan* teman sebangku secara *offline* tanpa internet) dan tombol **"Bagikan Link ke WhatsApp"** (mengunggah JSON tugas ke server untuk menghasilkan link/kode).

#### B. Aturan Penerima (Receiver Flow)
1. **Via Scan QR / Input Kode:** Penerima membuka menu Import di Halaman Jadwal atau Halaman Tugas, lalu memindai QR Code atau mengetik kode unik.
2. **Via Deep Link (Klik dari WhatsApp):** Saat penerima mengklik link berbagi, aplikasi otomatis terbuka dan menangkap parameter `code`, mengambil data JSON dari server, lalu menampilkan *Preview Dialog* ("Tambahkan 1 Tugas / 8 Mata Kuliah ke jadwalmu?").
3. **Resolusi Relasi Mata Kuliah Saat Import Tugas (Smart Matching):**
   * Ketika pengguna mengimpor 1 tugas dari teman, sistem mengecek apakah `course_code` atau `course_name` pada tugas tersebut sudah ada di tabel `courses` lokal milik penerima (pencocokan *case-insensitive*).
   * Jika **ADA**, otomatis hubungkan `course_id` tugas baru tersebut ke mata kuliah yang ada.
   * Jika **TIDAK ADA**, tawarkan opsi otomatis membuat entri mata kuliah baru atau menyimpannya sebagai tugas umum.
4. **Penyesuaian Pengingat Lokal:** Saat tugas berhasil diimpor, sistem otomatis mendaftarkan `reminder_datetime` ke *Alarm Manager* HP penerima menggunakan suara alarm *default* milik penerima.

#### C. Kontrak JSON Payload untuk Sharing (Standardized Data Exchange)
AI Agent wajib menggunakan struktur JSON berikut untuk proses *encode/decode* QR Code dan *API Payload*:

```json
{
  "schema_version": "1.0",
  "share_type": "SINGLE_TASK",
  "generated_at": "2026-10-19T08:00:00Z",
  "payload": {
    "courses": [
      {
        "course_name": "Pemrograman Web",
        "course_code": "IF204",
        "sks": 3,
        "lecturer_name": "Dosen Pengampu, M.Kom.",
        "room": "Lab Terpadu 3",
        "day_of_week": 1,
        "start_time": "08:00",
        "end_time": "10:30",
        "color_hex": "#3B82F6"
      }
    ],
    "tasks": [
      {
        "title": "Membuat REST API & Dokumentasi",
        "description": "Kumpulkan link repository di portal kampus",
        "course_code_ref": "IF204",
        "course_name_ref": "Pemrograman Web",
        "deadline_datetime": "2026-10-21T23:59:00",
        "reminder_datetime": "2026-10-21T19:00:00",
        "is_alarm_enabled": true
      }
    ]
  }
}
```

---

## 7. EDGE CASES & ATURAN VALIDASI (ACCEPTANCE CRITERIA)
1. **Validasi Bentrok Jadwal (Schedule Conflict Warning):** Saat pengguna menambah atau mengimpor mata kuliah baru pada hari yang sama (`day_of_week`) dengan irisan waktu (`start_time` dan `end_time` bertabrakan dengan mata kuliah lain), tampilkan *Warning Dialog* ("Jadwal bentrok dengan mata kuliah X, tetap simpan?").
2. **Validasi Waktu Pengingat Tugas:** Waktu `reminder_datetime` tidak boleh lebih lambat dari `deadline_datetime` (`reminder_datetime <= deadline_datetime`).
3. **Pencegahan Duplikasi Import:** Jika pengguna memindai QR Code atau mengklik link tugas yang memiliki `shared_origin_code` (atau kombinasi `title` + `deadline_datetime`) yang sudah ada di database lokal, tampilkan konfirmasi agar tugas tidak terduplikasi secara tidak sengaja.
4. **Offline Fallback:** Jika pengguna mencoba membuat **Link Share Online** saat tidak ada koneksi internet, tampilkan pesan *Toast/Snackbar* yang jelas: *"Tidak ada koneksi internet untuk membuat Link. Gunakan fitur QR Code di bawah ini untuk berbagi secara offline."*

---

## 8. TAHAPAN IMPLEMENTASI UNTUK AI AGENT (STEP-BY-STEP DEVELOPMENT PLAN)
Saat meminta AI Agent menulis kode dari PRD ini, instruksikan AI untuk mengerjakan secara bertahap per modul berikut:
* **Milestone 1 (Core Setup & Database):** Inisialisasi proyek, konfigurasi navigasi 3 tab (Home, Jadwal, Tugas), dan pembuatan helper database SQLite (`courses`, `tasks`, `alarm_sounds`).
* **Milestone 2 (CRUD Jadwal & KRS):** Implementasi UI Halaman Jadwal, filter tab per hari (Senin–Minggu), form input/edit mata kuliah, dan deteksi jadwal bentrok.
* **Milestone 3 (CRUD Tugas & Filter < 2 Hari):** Implementasi UI Halaman Tugas dengan logika *default filter* `< 48 jam`, filter per tanggal, *All Active*, serta integrasi *dropdown* mata kuliah.
* **Milestone 4 (Dashboard Home):** Implementasi agregasi data hari ini, algoritma *Next Class Countdown*, dan daftar tugas terdekat di Halaman Home.
* **Milestone 5 (Notification, Alarm & Custom Sound):** Integrasi *Native Alarm Manager*, *Local File Picker* untuk impor audio alarm, dan *katalog unduhan audio online*.
* **Milestone 6 (Share & Import Engine):** Implementasi generator/scanner QR Code *offline* serta *endpoint* integrasi API untuk berbagi via Link/Kode Unik dan *Deep Linking*.