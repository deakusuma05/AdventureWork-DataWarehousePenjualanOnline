# Risiko Awal — AdventureWorks Online Sales Data Warehouse

**Mata kuliah:** Data Warehouse  
**Proses bisnis:** Penjualan Online (`OnlineOrderFlag = 1`)  
**DBMS sumber:** MySQL/MariaDB (XAMPP), database `adventureworks`  
**Tahap:** Perencanaan Pekan 9 / Steering Review Pekan 10

## Dasar temuan profiling

- 27.659 pesanan online, 60.398 baris detail, 130 produk unik (rentang transaksi Mei 2011 – Juni 2014).
- Grain v1: satu baris fakta per `SalesOrderDetailID` dari transaksi `OnlineOrderFlag = 1`.
- `OrderQty = 1` pada seluruh 60.398 baris detail online hasil query distribusi.
- `SUM(LineTotal) = 29.358.677,22` pada baris detail online (baseline numerik, bukan otomatis pendapatan lintas mata uang terkonversi).
- `CurrencyRateID` NULL pada 33.400 baris detail (55,3%) atau 14.860 pesanan unik (53,73%).
- Profil NULL pada kolom `CustomerID`, `TerritoryID`, `ShipMethodID`, `ProductID`, `SpecialOfferID`, dan `LineTotal` menghasilkan 0 baris detail NULL (`SalesPersonID` bernilai NULL pada seluruh 60.398 baris detail karena pesanan dilakukan secara online).
- Pemeriksaan relasi pada dimensi tanggal, produk, pelanggan, wilayah, promosi, mata uang terisi, dan metode kirim tidak menemukan referensi yang hilang. Penafsiran mata uang untuk baris dengan `CurrencyRateID` NULL belum dipastikan.

## Register risiko

| ID | Risiko | Bukti/pemicu | Dampak | Tingkat awal | Mitigasi dan pengujian | PIC usulan |
|---|---|---|---|---|---|---|
| R01 | Mata uang transaksi tidak dapat diidentifikasi untuk sebagian baris | `CurrencyRateID` NULL pada 33.400/60.398 detail | Perbandingan nilai penjualan antar mata uang dapat menyesatkan | Tinggi | Profil `CurrencyRateID` pada tingkat pesanan; telusuri metadata dan aturan sumber; gunakan anggota `Unknown` pada DW sampai bukti mata uang dasar tersedia; jangan konversi nilai tanpa aturan | Alifa (QA), Siti (model) |
| R02 | Penggandaan baris fakta akibat join ETL | Baseline 60.398 detail unik | Nilai penjualan dan kuantitas menjadi terlalu besar | Tinggi | Tetapkan grain `SalesOrderDetailID`; periksa cardinality join; validasi `COUNT(*)` dan `COUNT(DISTINCT SalesOrderDetailID)` serta `SUM(LineTotal)` sebelum/sesudah ETL | Fivediniar (ETL), Alifa (QA) |
| R03 | Penghitungan jumlah pesanan keliru karena memakai jumlah detail | 27.659 order berbeda dari 60.398 detail | Dashboard menampilkan jumlah pesanan berlebihan | Sedang | Gunakan `COUNT(DISTINCT SalesOrderID)` untuk pesanan; simpan ID pesanan sebagai degenerate dimension | Haura (dashboard), Siti (model) |
| R04 | Dimensi lintas tim tidak konsisten | Tujuh dimensi kandidat conformed | Integrasi lintas proses dan OLAP tidak konsisten | Sedang | Sepakati nama, business key, atribut, surrogate key, dan aturan Unknown dengan tim lain; catat keputusan di bus matrix | Dea (koordinasi), Siti (model) |
| R05 | Nilai penjualan salah dihitung akibat diskon, pajak, ongkir, atau kurs | `LineTotal` merupakan nilai baris detail; `TotalDue` tingkat header | KPI tidak cocok dan terjadi double counting | Tinggi | Definisikan KPI `sales_amount = SUM(LineTotal)`; pisahkan pajak/ongkir tingkat pesanan; jangan hitung diskon dua kali; validasi agregasi terhadap sumber | Siti (model), Alifa (QA) |
| R06 | Hasil dan bukti proyek tidak dapat direproduksi | Proyek dikerjakan bertahap di beberapa laptop | Review dan penilaian sulit diverifikasi | Sedang | Simpan SQL, output CSV, screenshot, definisi metrik, dan catatan konfigurasi dalam repositori; jangan commit password/dump besar tanpa izin | Alifa (dokumentasi), Dea (PM) |

**Catatan:** Tingkat risiko merupakan penilaian awal tim dan dapat diperbarui setelah validasi berikutnya. PIC disesuaikan dengan pembagian peran pada `README.md`.

## Kriteria penerimaan desain v1

1. Query fakta online tanpa dimensi menghasilkan 60.398 baris detail dan 60.398 ID detail unik.
2. Jumlah pesanan dihitung sebagai 27.659 `SalesOrderID` unik.
3. Agregasi `LineTotal` mentah mempertahankan baseline 29.358.677,22, dengan definisi mata uang dan pembulatan yang terdokumentasi.
4. Semua tujuh FK dimensi memiliki pasangan DW atau anggota `Unknown` yang transparan, tanpa mengarang nilai sumber.
5. Database sumber `adventureworks` tetap **read-only**; tabel fakta dan dimensi hanya dibuat dalam database DW terpisah.

## Bukti yang disimpan di repositori

- `bukti/database/08-profiling-null-online-sales.png`
- `hasil-profiling/08-profiling-null-online-sales.csv`
- `sql/profiling/08-profiling-null-online-sales.sql`
- `bukti/database/09-profiling-currency-online.png`
- `hasil-profiling/09-profiling-currency-online.csv`
- `sql/profiling/09-profiling-currency-online.sql`
- Hasil uji join dimensi (`bukti/database/06-validasi-tujuh-dimensi.png`) dan validasi grain (`bukti/database/04-validasi-grain.png`).

## Tindak lanjut prioritas

Profil mata uang pada tingkat pesanan dan dokumentasikan definisi mata uang dasar sebelum menetapkan KPI nominal lintas mata uang.
