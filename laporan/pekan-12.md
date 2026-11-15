# Laporan Steering Review Pekan 12 — Implementasi DDL Idempotent, Uji Constraint Fisik, Kamus Data, dan Reverse Engineering ERD

## Proyek Data Warehouse AdventureWorks — Penjualan Online

**Mata kuliah:** Data Warehouse  
**Program studi:** Sistem Informasi, Fakultas Ilmu Komputer, UPN "Veteran" Jawa Timur  
**Periode:** Semester Ganjil 2026/2027  
**Proses bisnis:** Penjualan Online (*Online Sales* — `OnlineOrderFlag = 1`)  
**Database sumber:** `adventureworks` (MySQL/MariaDB melalui XAMPP, *read-only*)  
**Database target DW:** `adventureworks_dw` (MySQL/MariaDB)  
**Project sponsor:** Dosen pengampu mata kuliah  
**Status dokumen:** Final — Laporan Progres untuk Steering Review Pekan 12.

---

## 1. Tim dan Pembagian Peran

| No. | Nama | NPM | Peran Utama | Fokus Kontribusi Pekan 11–12 |
|---:|---|---|---|---|
| 1 | Dea Kusuma Ningrum | 23082010048 | Project Manager & Business Analyst | Koordinasi deliverable Steering Review Pekan 12, validasi Change Request, dan review laporan |
| 2 | Fivediniar Edra Primaulidina | 23082010046 | Data Engineer & ETL Developer | Penulisan DDL idempotent (`sql/ddl.sql`), pengujian constraint database, dan verifikasi staging |
| 3 | Siti Anisa Safitri | 23082010045 | Data Warehouse & Dimensional Modeler | Pemasangan `dim_tanggal` v1.0 standar, penyusunan kamus data (`docs/kamus-data.md`), dan update mapping |
| 4 | Haura Taqiya Azza Nabila | 23082010165 | OLAP & Dashboard Developer | Reverse engineering ERD DBeaver, evaluasi konsistensi Star Schema V2, dan penyelarasan visual |
| 5 | Alifa Zuriyatul Haq | 23082010050 | Data Quality, Testing & Documentation | Pelaksanaan 3 uji constraint (PK, FK, NOT NULL), dokumentasi screenshot error, dan audit kualitas data |

---

## 2. Ringkasan Eksekutif Pekan 12

Pada siklus pengembangan Pekan 11 menuju **Steering Review Pekan 12**, Tim Kelompok 2 berfokus pada penguatan fondasi fisik basis data Data Warehouse (`adventureworks_dw`) agar memenuhi standar integritas data relasional formal, *reproducibility*, dan dokumentasi arsitektur data.

Seluruh target penugasan Pekan 11 telah diselesaikan secara tuntas dan terverifikasi:
1. **Pemasangan `dim_tanggal` Standar Versi 1.0:** Telah aktif di database dengan kunci utama `tanggal_key` integer `YYYYMMDD`, 11 atribut kalender standar berbahasa Indonesia, baris khusus `-1` (*Unknown Date*), dan rentang transaksi tervalidasi 31 Mei 2011 s.d. 30 Juni 2014 (1.127 hari).
2. **Penyusunan Skrip DDL Idempotent (`sql/ddl.sql`):** Seluruh 7 tabel dimensi dan 1 tabel fakta telah didefinisikan secara presisi beserta relasi *Foreign Key* dan indeksnya. Skrip telah diuji dan **berhasil dijalankan dua kali berturut-turut tanpa menghasilkan error apapun (*zero errors*)**.
3. **Pengujian Constraint Fisik Database:** Tiga skenario pengujian integritas (*Primary Key Uniqueness*, *Foreign Key Integrity*, dan *NOT NULL Violation*) telah dieksekusi, dengan bukti tangkapan layar penolakan error resmi dari mesin MySQL (`#1062`, `#1452`, `#1048`).
4. **Penyusunan Kamus Data Lengkap (`docs/kamus-data.md`):** Mendokumentasikan seluruh atribut, tipe data, aturan NULL, SCD, peran kolom, dan penjelasan logis dimensi tanggal dengan bahasa sendiri.
5. **Reverse Engineering ERD via DBeaver:** Membuktikan bahwa diagram fisik yang digenerate dari database target `adventureworks_dw` telah **100% identik dan konsisten** terhadap rancangan Star Schema V2.
6. **Dokumentasi Tabel Staging (`docs/mapping.md`):** Pemetaan lengkap lapisan staging ke target DW telah ditambahkan untuk menjembatani pipeline ETL Pentaho PDI.

---

## 3. Pemasangan `dim_tanggal` Standar Versi 1.0

Sesuai instruksi sponsor proyek, tabel tanggal di database `adventureworks_dw` telah menggunakan struktur **`dim_date` / `dim_tanggal` Standar Versi 1.0** dengan karakteristik teknis:
* **Primary Key:** `tanggal_key` bertipe `INT(11)` berformat `YYYYMMDD` (contoh: `20110531`).
* **11 Atribut Kalender Standar:** `tanggal` (`DATE`), `tahun`, `semester`, `kuartal`, `bulan`, `nama_bulan` (Indonesia), `minggu_dalam_tahun`, `tanggal_dalam_bulan`, `hari_dalam_minggu`, `nama_hari` (Indonesia), dan `is_akhir_pekan` (`TINYINT(1)`).
* **Baris Khusus / Unknown Member:** Injeksi baris default `tanggal_key = -1` (`1900-01-01`) untuk mencegah hilangnya transaksi jika terdapat tanggal yang tidak valid.

### Hasil Kueri Pemeriksaan Integritas `dim_date`:
```sql
-- 1. Cek keberadaan baris default -1
SELECT * FROM dim_date WHERE tanggal_key = -1;
-- Hasil: 1 baris ditemukan (-1, '1900-01-01', 1900, 1, 1, 1, 'Unknown', 1, 1, 1, 'Unknown', 0).

-- 2. Cek rentang tanggal, total hari kalender, dan kontrol keunikan key
SELECT 
    MIN(tanggal) AS tanggal_awal,
    MAX(tanggal) AS tanggal_akhir,
    COUNT(*) AS total_baris,
    COUNT(DISTINCT tanggal_key) AS key_unik
FROM dim_date 
WHERE tanggal_key <> -1;
-- Hasil: tanggal_awal = 2011-05-31, tanggal_akhir = 2014-06-30, total_baris = 1.127, key_unik = 1.127.
```

*Bukti visual tersimpan pada [`bukti/database/11-pemeriksaan-dim-tanggal-standar.png`](../bukti/database/11-pemeriksaan-dim-tanggal-standar.png) dan DDL pada [`sql/ddl.sql`](../sql/ddl.sql).*

---

## 4. Skrip DDL Idempotent (`sql/ddl.sql`) dan Bukti Eksekusi

Berkas [`sql/ddl.sql`](../sql/ddl.sql) telah disusun sebagai cetak biru (*blueprint*) pembangunan database Data Warehouse. Skrip ini dirancang dengan prinsip **idempotensi** (dapat dieksekusi berkali-kali tanpa error) dengan mekanisme:

1. **Urutan DROP TABLE yang Aman:**
   Menghindari pelanggaran *foreign key constraint* dengan mematikan sementara pengecekan relasi dan menjatuhkan tabel fakta terlebih dahulu sebelum tabel dimensi:
   ```sql
   SET FOREIGN_KEY_CHECKS = 0;
   DROP TABLE IF EXISTS fact_online_sales;
   DROP TABLE IF EXISTS dim_ship_method;
   DROP TABLE IF EXISTS dim_currency;
   DROP TABLE IF EXISTS dim_promotion;
   DROP TABLE IF EXISTS dim_territory;
   DROP TABLE IF EXISTS dim_customer;
   DROP TABLE IF EXISTS dim_product;
   DROP TABLE IF EXISTS dim_date;
   SET FOREIGN_KEY_CHECKS = 1;
   ```
2. **Urutan CREATE TABLE:**
   Membuat 7 tabel dimensi terlebih dahulu, lalu membuat tabel fakta `fact_online_sales` yang mendefinisikan 7 relasi *Foreign Key* resmi:
   * `fk_fact_tanggal` $\rightarrow$ `dim_date(tanggal_key)`
   * `fk_fact_product` $\rightarrow$ `dim_product(product_key)`
   * `fk_fact_customer` $\rightarrow$ `dim_customer(customer_key)`
   * `fk_fact_territory` $\rightarrow$ `dim_territory(territory_key)`
   * `fk_fact_promotion` $\rightarrow$ `dim_promotion(promotion_key)`
   * `fk_fact_currency` $\rightarrow$ `dim_currency(currency_key)`
   * `fk_fact_ship_method` $\rightarrow$ `dim_ship_method(ship_method_key)`
3. **Injeksi Anggota Unknown (`-1`) pada Seluruh Dimensi:**
   Menyertakan perintah `INSERT INTO` baris default `-1` untuk memastikan seluruh tabel dimensi siap menerima transaksi anomali/kurs kosong dari awal.

### Bukti Pengujian Idempotensi (Eksekusi 2 Kali Berturut-turut):
* **Eksekusi 1:** Seluruh tabel berhasil dibuat dan baris `-1` terinjeksi sempurna.  
  *Bukti Tangkapan Layar:* [`bukti/database/15-eksekusi-ddl-sukses 1.png`](../bukti/database/15-eksekusi-ddl-sukses%201.png).
* **Eksekusi 2:** Skrip dijalankan ulang seketika di DBeaver/phpMyAdmin; tabel lama berhasil di-drop dan dibangun kembali dengan status **0 errors / Success**.  
  *Bukti Tangkapan Layar:* [`bukti/database/16-eksekusi-ddl-sukses 2.png`](../bukti/database/16-eksekusi-ddl-sukses%202.png).

---

## 5. Hasil Pengujian Tiga Constraint Database (Data Integrity Tests)

Untuk membuktikan bahwa mekanisme integritas fisik basis data aktif dan mampu mencegah masuknya data anomali ke Data Warehouse, tim menjalankan tiga uji constraint:

| No. Uji | Jenis Constraint yang Diuji | Skenario Pengujian SQL | Pesan Error Mesin Database (Bukti Validasi) | Berkas Tangkapan Layar |
|:---:|---|---|---|:---:|
| **Uji 1** | **Primary Key Uniqueness** (Keunikan Kunci Utama) | Memasukkan baris baru ke `dim_customer` dengan `customer_key = -1` (duplikat PK yang sudah ada). | `#1062 - Duplicate entry '-1' for key 'PRIMARY'` | [`bukti/database/12-uji-constraint-pk.png`](../bukti/database/12-uji-constraint-pk.png) |
| **Uji 2** | **Foreign Key Referential Integrity** (Integritas Relasi FK) | Memasukkan baris transaksi fakta ke `fact_online_sales` dengan `product_key = 999999` (produk fiktif yang tidak terdaftar di `dim_product`). | `#1452 - Cannot add or update a child row: a foreign key constraint fails (..., CONSTRAINT fk_fact_product FOREIGN KEY (product_key) REFERENCES dim_product (product_key))` | [`bukti/database/13-uji-constraint-fk.png`](../bukti/database/13-uji-constraint-fk.png) |
| **Uji 3** | **NOT NULL Constraint** (Keharusan Pengisian Nilai Kritis) | Memasukkan baris fakta ke `fact_online_sales` dengan nilai ukuran penjualan `line_total = NULL`. | `#1048 - Column 'line_total' cannot be null` | [`bukti/database/14-uji-constraint-not-null.png`](../bukti/database/14-uji-constraint-not-null.png) |

**Kesimpulan Pengujian:** Seluruh constraint database berfungsi 100% menolak operasi *invalid data*, menjamin kebersihan data di level penyimpanan fisik.

---

## 6. Kamus Data dan Penjelasan Logis `dim_tanggal`

Dokumen kamus data lengkap telah dipublikasikan pada [`docs/kamus-data.md`](../docs/kamus-data.md), mencakup spesifikasi 8 tabel Data Warehouse (7 dimensi + 1 fakta) serta 4 tabel staging perantara.

### Intisari Penjelasan `dim_tanggal` Standar v1.0 (Bahasa Tim):
1. **Mengapa Integer `YYYYMMDD` (Bukan `DATE`):** Tipe integer memangkas beban I/O mesin saat melakukan operasi *index scanning* dan *hash-join* ke tabel fakta yang berisi puluhan ribu hingga jutaan baris, serta memungkinkan penampungan nilai khusus `-1`.
2. **Peran Baris `-1`:** Transaksi yang tanggalnya hilang di sistem operasional tetap dapat dicatat di tabel fakta tanpa melanggar batasan Foreign Key (*zero data loss*).
3. **Hierarki Kalender:** Membentuk jalur agregasi OLAP otomatis: `Tahun` $\rightarrow$ `Semester` $\rightarrow$ `Kuartal` $\rightarrow$ `Bulan` $\rightarrow$ `Tanggal`.
4. **Atribut `is_akhir_pekan`:** Memberikan kemampuan analitik instan bagi tim bisnis untuk mengidentifikasi elastisitas belanja online pada hari kerja vs akhir pekan.

---

## 7. Validasi Reverse Engineering ERD DBeaver vs Star Schema V2

Tim melakukan *reverse engineering* skema fisik langsung dari database `adventureworks_dw` menggunakan peranti **DBeaver** dan menyimpannya pada [`docs/erd-dbeaver-reverse-engineering.png`](../docs/erd-dbeaver-reverse-engineering.png) serta menyandingkannya dengan [`docs/Star-Schema-V2.png`](../docs/Star-Schema-V2.png).

### Hasil Komparasi:
* **Struktur Pola Bintang:** Tabel fakta `fact_online_sales` terletak tepat di tengah dengan 7 relasi garis kardinalitas 1-to-many ($\text{1} : \text{N}$) menghubungkan ke seluruh tabel dimensi di sekelilingnya.
* **Kesesuaian Tipe Data:** Seluruh tipe data fisik (seperti `decimal(19,4)` untuk measures keuangan dan `int(11)` untuk surrogate keys) identik 100% antara skrip DDL, database MySQL, dan diagram ERD.
* **Ketiadaan Anomali:** Tidak ditemukan tabel yatim (*orphan table*) maupun relasi ganda (*circular relationship*).

---

## 8. Pembaruan Tabel Staging pada Dokumen Mapping

Pada [`docs/mapping.md`](../docs/mapping.md), tim telah menambahkan bab khusus **`## 3. Daftar Tabel Staging (Staging Layer Mapping)`** yang mendokumentasikan:
* Pemetaan alur data dari tabel operasional OLTP (`sales_salesorderheader`, `sales_salesorderdetail`, `production_product`, dll.) menuju lapisan perantara staging.
* Penerapan filter wajib `OnlineOrderFlag = 1` pada tahap ekstraksi awal.
* Penjelasan arsitektur: Penggunaan aliran *in-memory streaming* Pentaho PDI (Spoon) yang mengolah data staging langsung di RAM, serta kesiapan skema jika diimplementasikan sebagai tabel fisik staging (`stg_*`).

---

## 9. Tabel Permintaan Perubahan (Change Request)

Berikut rekapitulasi penyesuaian teknis yang dilakukan tim berdasarkan arahan sponsor dan hasil pengujian Pekan 11–12:

| No. CR | Komponen yang Berubah | Kondisi Lama (Pekan 10) | Kondisi Baru yang Disetujui (Pekan 12) | Alasan / Justifikasi Bisnis | Status Persetujuan |
|:---:|---|---|---|---|:---:|
| **CR-01** | Kunci Tanggal di Tabel Fakta | Bernama `date_key` | Diseragamkan menjadi `tanggal_key` | Menyelaraskan nama kolom Foreign Key di `fact_online_sales` dengan Primary Key pada `dim_date.tanggal_key` standar v1.0. | ✅ Disetujui Sponsor |
| **CR-02** | Struktur `dim_date` | Struktur bebas bahasa Inggris (8 kolom) | Struktur standar v1.0 bahasa Indonesia (12 kolom lengkap) | Standarisasi dimensi kalender agar seragam dengan template universitas dan mendukung flag akhir pekan. | ✅ Disetujui Sponsor |
| **CR-03** | Penanganan Kurs Kosong | Berpotensi menyebabkan baris tertolak | Injeksi baris default `currency_key = -1` (USD Base) | Menyelamatkan 14.860 transaksi online (53,73%) yang tidak memiliki `CurrencyRateID` di OLTP agar tidak hilang. | ✅ Disetujui Sponsor |
| **CR-04** | DDL Database Target | Dump statis phpMyAdmin | Skrip DDL idempotent mandiri di [`sql/ddl.sql`](../sql/ddl.sql) | Menjamin skema database target dapat dibangun ulang secara otomatis dan aman kapan saja. | ✅ Disetujui Sponsor |

---

## 10. Checklist Deliverable Pekan 12

| No. | Kriteria Deliverable Pekan 12 | Status | Berkas Bukti di Repositori |
|---:|---|---|---|
| 1 | Pemasangan `dim_tanggal` standar v1.0 & query verifikasi | **Selesai** | [`sql/ddl.sql`](../sql/ddl.sql), [`bukti/database/11-pemeriksaan-dim-tanggal-standar.png`](../bukti/database/11-pemeriksaan-dim-tanggal-standar.png) |
| 2 | Berkas `sql/ddl.sql` lengkap dengan baris `-1`, FK, dan indeks (lolos run 2x) | **Selesai** | [`sql/ddl.sql`](../sql/ddl.sql), [`bukti/database/15-eksekusi-ddl-sukses 1.png`](../bukti/database/15-eksekusi-ddl-sukses%201.png), [`bukti/database/16-eksekusi-ddl-sukses 2.png`](../bukti/database/16-eksekusi-ddl-sukses%202.png) |
| 3 | Tiga tangkapan layar pengujian constraint (PK, FK, NOT NULL) | **Selesai** | [`bukti/database/12-uji-constraint-pk.png`](../bukti/database/12-uji-constraint-pk.png), [`bukti/database/13-uji-constraint-fk.png`](../bukti/database/13-uji-constraint-fk.png), [`bukti/database/14-uji-constraint-not-null.png`](../bukti/database/14-uji-constraint-not-null.png) |
| 4 | Dokumen kamus data lengkap dengan penjelasan `dim_tanggal` bahasa sendiri | **Selesai** | [`docs/kamus-data.md`](../docs/kamus-data.md) |
| 5 | ERD reverse engineering DBeaver (identik dengan Star Schema V2) | **Selesai** | [`docs/erd-dbeaver-reverse-engineering.png`](../docs/erd-dbeaver-reverse-engineering.png), [`docs/Star-Schema-V2.png`](../docs/Star-Schema-V2.png) |
| 6 | Penambahan daftar tabel staging pada dokumen pemetaan | **Selesai** | [`docs/mapping.md`](../docs/mapping.md) (Bab 3) |
| 7 | Laporan progres Steering Review Pekan 12 siap beserta tabel Change Request | **Selesai** | [`laporan/pekan-12.md`](pekan-12.md) |

---

## 11. Rencana Tindak Lanjut Pekan 13

1. **Pembangunan Kubus OLAP Fisik (`olap/`):** Menyusun berkas skema Mondrian XML (`adventureworks_online_sales.xml`) mengacu pada rancangan [`docs/desain-cube-online-sales-bus-matrix-v1.1.xlsx`](../docs/desain-cube-online-sales-bus-matrix-v1.1.xlsx).
2. **Pengujian Kueri MDX:** Menguji kalkulasi *calculated member* (AOV `$1.061,45`, rasio promo, dan proporsi kurs) melalui Pentaho Schema Workbench / JPivot.
3. **Persiapan Backend API Dashboard (Pekan 14):** Menyiapkan endpoint JSON kueri analitik untuk menghubungkan tabel DW target ke visual dashboard [`dashboard/wireframe-dashboard.html`](../dashboard/wireframe-dashboard.html).

---

**Disusun oleh:** Kelompok 2 — Tim Data Warehouse Penjualan Online  
**Tanggal:** 16 November 2026  
**Status:** Siap untuk Steering Review Pekan 12.

