# Laporan Steering Review Pekan 10

## Proyek Data Warehouse AdventureWorks — Penjualan Online

**Mata kuliah:** Data Warehouse  
**Program studi:** Sistem Informasi, Fakultas Ilmu Komputer, UPN "Veteran" Jawa Timur  
**Periode:** Semester Ganjil 2026/2027  
**Proses bisnis:** Penjualan Online (*Online Sales*)  
**Database sumber:** `adventureworks` (MySQL/MariaDB melalui XAMPP dan phpMyAdmin)  
**Project sponsor:** Dosen pengampu mata kuliah (nama diisi tim)  
**Status dokumen:** Draf Steering Review; lampiran dan persetujuan yang belum tersedia harus dilengkapi tim.

## 1. Tim dan Pembagian Peran

| No. | Nama | NPM | Peran utama |
|---:|---|---|---|
| 1 | Dea Kusuma Ningrum | 23082010048 | Project Manager & Business Analyst |
| 2 | Fivediniar Edra Primaulidina | 23082010046 | Data Engineer & ETL Developer |
| 3 | Siti Anisa Safitri | 23082010045 | Data Warehouse & Dimensional Modeler |
| 4 | Haura Taqiya Azza Nabila | 23082010165 | OLAP & Dashboard Developer |
| 5 | Alifa Zuriyatul Haq | 23082010050 | Data Quality, Testing & Documentation |

Pembagian peran ini merupakan rancangan tim; konfirmasi akhir serta bukti undangan dosen perlu dicantumkan di piagam proyek dan repositori.

## 2. Ringkasan Eksekutif

Tim memilih proses bisnis **Penjualan Online** dari database AdventureWorks. Filter proses yang digunakan adalah `OnlineOrderFlag = 1` pada tabel `sales_salesorderheader`. Database sumber telah diimpor ke MySQL pada XAMPP, dan tim melaporkan verifikasi 71 tabel serta keberadaan data transaksi utama. Pengolahan Data Warehouse nantinya dilakukan pada database terpisah; database sumber hanya dibaca.

Profiling mengidentifikasi **27.659 pesanan online**, **60.398 baris detail online**, **130 produk unik terjual**, **60.398 unit**, dan **total `LineTotal` sebesar 29.358.677,22** (satuan mata uang serta interpretasi konsolidasi masih perlu divalidasi). Seluruh baris detail online memiliki `OrderQty = 1` dan `SalesOrderDetailID` unik pada hasil pemeriksaan. Temuan data terpenting adalah **14.860 dari 27.659 pesanan** tidak memiliki `CurrencyRateID`, setara **33.400 dari 60.398 baris detail**. Ini dicatat sebagai isu interpretasi mata uang, bukan otomatis sebagai kerusakan data.

## 3. Infrastruktur dan Database Sumber

| Komponen | Kondisi |
|---|---|
| DBMS | MySQL/MariaDB |
| Lingkungan lokal | XAMPP |
| Antarmuka query | phpMyAdmin |
| Database | `adventureworks` |
| Sumber | Dump MySQL `dump-adventureworks2-202509271927.sql` |
| Impor | Dilaporkan berhasil |
| Jumlah tabel | 71, sesuai hasil verifikasi tim |
| Kebijakan sumber | Read-only sesudah impor |

> Persetujuan penggunaan MySQL sebagai pengganti PostgreSQL telah diinformasikan oleh tim. Simpan bukti persetujuan dosen bila diperlukan.

**Bukti yang dilampirkan:** screenshot database (`bukti/database/01-verifikasi-database.png`), jumlah tabel, dan hasil query verifikasi; file dump database diabaikan melalui `.gitignore` agar tidak masuk ke repositori.

## 4. Proses Bisnis dan Pertanyaan Bisnis

**Proses bisnis:** Penjualan Online. **Filter:** `sales_salesorderheader.OnlineOrderFlag = 1`.

| No. | Pertanyaan yang terukur | Fakta/ukuran | Dimensi |
|---:|---|---|---|
| 1 | Bagaimana perubahan nilai penjualan online per bulan? | `SUM(LineTotal)`, jumlah pesanan unik, jumlah unit | Tanggal |
| 2 | Produk, subkategori, dan kategori apa yang menghasilkan nilai penjualan online tertinggi? | `SUM(LineTotal)`, `SUM(OrderQty)` | Produk |
| 3 | Pelanggan mana yang memberikan kontribusi terbesar pada penjualan online? | `SUM(LineTotal)`, jumlah pesanan unik | Pelanggan |
| 4 | Wilayah mana yang mencatat transaksi dan nilai penjualan online terbesar? | `SUM(LineTotal)`, jumlah pesanan unik | Wilayah |
| 5 | Bagaimana distribusi nilai penjualan online menurut penawaran/promosi? | `SUM(LineTotal)`, nilai diskon dan jumlah detail | Promosi |
| 6 | Bagaimana kelengkapan informasi mata uang dan distribusi transaksi menurut kode mata uang yang diketahui? | jumlah pesanan, jumlah detail, proporsi `CurrencyRateID` NULL | Mata Uang |
| 7 | Bagaimana jumlah pesanan dan nilai penjualan online menurut metode kirim? | jumlah pesanan unik, `SUM(LineTotal)` | Metode Kirim |

**Batasan pengukuran:** `SUM(LineTotal)` merupakan subtotal detail; jangan menghitung `TotalDue` pada grain detail karena dapat menggandakan komponen tingkat header. Perbandingan nilai antar-mata-uang harus mengikuti definisi basis nilai yang disepakati.

## 5. Hasil Profiling Data Sumber

### 5.1 Volume dan Grain

| Indikator | Hasil |
|---|---:|
| Total pesanan online (`COUNT(DISTINCT SalesOrderID)`) | 27.659 |
| Total baris detail online | 60.398 |
| ID detail unik | 60.398 |
| Produk unik terjual online | 130 |
| Total kuantitas terjual (`SUM(OrderQty)`) | 60.398 |
| Nilai penjualan detail (`SUM(LineTotal)`) | 29.358.677,22 |
| Distribusi `OrderQty` | Semua detail online bernilai 1 |

**Interpretasi:** identitas baris detail tidak terduplikasi pada hasil join header–detail yang diperiksa. Jumlah 60.398 adalah baseline calon baris tabel fakta pada grain detail pesanan, sepanjang ETL tidak menghapus/menduplikasi baris.

### 5.2 Kualitas Klasifikasi Produk

| Indikator | Hasil |
|---|---:|
| Produk katalog | 504 |
| Produk katalog tanpa subkategori | 209 |
| Produk katalog dengan kategori lengkap | 295 |
| Relasi subkategori rusak | 0 |
| Relasi kategori rusak | 0 |
| Produk unik terjual online tanpa subkategori | 0 |
| Produk unik terjual online dengan kategori lengkap | 130 |

Produk katalog tanpa subkategori tidak muncul di antara produk unik yang terjual online pada hasil profiling ini. Nilai NULL sumber tetap harus dipertahankan untuk audit dan untuk antisipasi data baru.

### 5.3 Kelengkapan Kolom pada Detail Online

Semua angka NULL di bawah dihitung setelah join header–detail, yaitu pada tingkat **baris detail**, bukan pesanan unik (`hasil-profiling/08-profiling-null-online-sales.csv`).

| Atribut | NULL pada 60.398 baris detail |
|---|---:|
| `CustomerID` | 0 |
| `SalesPersonID` | 60.398 |
| `TerritoryID` | 0 |
| `CurrencyRateID` | **33.400** |
| `ShipMethodID` | 0 |
| `ProductID` | 0 |
| `SpecialOfferID` | 0 |
| `LineTotal` | 0 |

Pemeriksaan relasi dimensi menunjukkan 0 pasangan hilang untuk produk, pelanggan, wilayah, promosi, `CurrencyRateID` yang terisi, dan metode kirim (`SalesPersonID` bernilai NULL pada seluruh transaksi online karena dipesan langsung oleh pelanggan tanpa tenaga penjual). Ini membuktikan keterhubungan pada data yang diperiksa, bukan menjamin seluruh definisi bisnis final.

### 5.4 Profil Mata Uang pada Tingkat Pesanan

| Indikator | Hasil |
|---|---:|
| Total pesanan online | 27.659 |
| Pesanan tanpa `CurrencyRateID` | 14.860 (53,73%) |
| Pesanan dengan `CurrencyRateID` | 12.799 (46,27%) |
| ID kurs unik yang digunakan | 2.466 |
| Detail online tanpa `CurrencyRateID` | 33.400 (55,30%) |

**Rekonsiliasi:** 14.860 + 12.799 = 27.659 pesanan (`hasil-profiling/09-profiling-currency-online.csv`). Sebanyak 2.466 **ID kurs** tidak sama dengan jumlah jenis mata uang.

**Kebijakan sementara:** nilai `CurrencyRateID` NULL dipetakan ke anggota `Unknown / Not Identified` pada dimensi mata uang DW, tidak otomatis menjadi USD; catat ID sumber dan status kelengkapan, serta verifikasi aturan mata uang dasar dan kurs sebelum konversi atau analisis nilai lintas mata uang.

### 5.5 Profil Rentang Tanggal

Berdasarkan hasil profiling pada `hasil-profiling/10-profiling-rentang-tanggal.csv` dan `bukti/database/10-profiling-rentang-tanggal.png`:

| Indikator | Hasil |
|---|---:|
| Total pesanan online | 27.659 |
| Tanggal awal (`MIN(OrderDate)`) | `2011-05-31 01:30:00` |
| Tanggal akhir (`MAX(OrderDate)`) | `2014-06-30 01:30:00` |
| Cakupan tahun (`jumlah_tahun`) | 4 tahun (Mei 2011 – Juni 2014) |

Tren penjualan online bulanan tersimpan pada `hasil-profiling/07-penjualan-online-per-bulan.csv` dan `bukti/database/07-penjualan-online-per-bulan.png`.

## 6. Desain Dimensional — Star Schema v1

### 6.1 Empat Langkah Desain

1. **Proses bisnis:** Penjualan Online.
2. **Grain:** satu baris detail produk dalam satu pesanan online.
3. **Dimensi:** Tanggal, Produk, Pelanggan, Wilayah, Promosi, Mata Uang, Metode Kirim.
4. **Fakta/measures:** `OrderQty`, `UnitPrice`, `UnitPriceDiscount`, `LineTotal`; metrik turunan dihitung berdasarkan aturan yang terdokumentasi.

### 6.2 Pernyataan Grain (Satu Kalimat)

> Satu baris pada tabel `fact_online_sales` merepresentasikan satu baris detail produk (`SalesOrderDetailID`) dari satu pesanan penjualan online (`OnlineOrderFlag = 1`) dalam database AdventureWorks.

### 6.3 Tabel Fakta dan Dimensi

**Fakta utama:** `fact_online_sales` dengan kunci teknis atau pengenal unik `SalesOrderDetailID`, `SalesOrderID` sebagai *degenerate dimension*, tujuh foreign key menuju dimensi, dan measures pada tingkat detail.

| Dimensi | Nama rancangan | Kunci utama DW | Identitas sumber / atribut utama |
|---|---|---|---|
| Tanggal | `dim_date` | `date_key` | `OrderDate`, hari, bulan, kuartal, tahun |
| Produk | `dim_product` | `product_key` | `ProductID`, nama, kategori, subkategori |
| Pelanggan | `dim_customer` | `customer_key` | `CustomerID`, atribut pelanggan yang lolos validasi |
| Wilayah | `dim_territory` | `territory_key` | `TerritoryID`, nama, grup, negara/wilayah |
| Promosi | `dim_promotion` | `promotion_key` | `SpecialOfferID`, deskripsi, diskon, periode |
| Mata Uang | `dim_currency` | `currency_key` | kode mata uang dari relasi kurs, anggota Unknown |
| Metode Kirim | `dim_ship_method` | `ship_method_key` | `ShipMethodID`, nama metode |

**Aturan desain:** PK/FK DW tidak dibuat di database sumber. `LineTotal` digunakan sebagai subtotal detail; hindari menghitung ulang diskon apabila sudah tercermin pada nilai tersebut. Atribut mata uang masih memerlukan verifikasi bisnis.

**Lampiran:** `docs/star-schema-v1.png`.

## 7. Bus Matrix Tim

| Proses bisnis | Tanggal | Produk | Pelanggan | Wilayah | Promosi | Mata Uang | Metode Kirim |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Penjualan Online | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

Ketujuh dimensi merupakan **kandidat conformed dimension** sesuai bus matrix kelas; status conformed final memerlukan persetujuan definisi, kunci, dan hierarki lintas tim.

## 8. Risiko Awal dan Mitigasi

| Risiko | Dampak | Penanganan | Penanggung jawab utama |
|---|---|---|---|
| Interpretasi mata uang tidak tepat karena `CurrencyRateID` NULL | Agregasi lintas mata uang menyesatkan | Anggota Unknown; validasi kurs serta basis nilai sebelum konversi | Fivediniar, Alifa |
| Duplikasi fakta akibat join/ETL | Jumlah baris dan nilai penjualan meningkat salah | Tetapkan grain; uji keunikan `SalesOrderDetailID` dan baseline 60.398 | Siti Anisa, Fivediniar |
| Menghitung jumlah pesanan dari `COUNT(*)` detail | KPI order membesar | Gunakan `COUNT(DISTINCT SalesOrderID)` | Dea, Haura |
| Definisi dimensi tidak konsisten lintas tim | Sulit menggabungkan data mart | Sepakati bus matrix dan definisi conformed dimension bersama sponsor | Dea, Siti Anisa |
| Agregasi total header pada grain detail | Pajak/ongkir terduplikasi | Gunakan `LineTotal` untuk nilai detail; definisikan alokasi jika perlu | Siti Anisa, Alifa |
| Kekurangan bukti di GitHub | Steering Review tidak dapat diverifikasi | Simpan SQL, CSV, screenshot, dan catat commit yang relevan | Alifa, Dea |

Lampiran: `docs/risiko-awal.md`.

## 9. Progres Checklist Pekan 9

| Kebutuhan tugas | Status saat penyusunan | Bukti/aksi lanjutan |
|---|---|---|
| Repositori dan undangan dosen | **Repositori aktif; menunggu bukti undangan** | Tautan repo, screenshot anggota/undangan di `bukti/github/` |
| Piagam proyek dan peran | **Tersedia di README dan laporan** | Pembagian peran 5 anggota telah ditetapkan |
| Database AdventureWorks berjalan | **Terverifikasi** | `bukti/database/01-verifikasi-database.png` |
| ≥5 pertanyaan bisnis | **7 pertanyaan disusun** | Tercantum pada README & Bagian 4 laporan ini |
| Profil data tersimpan | **Lengkap (SQL, CSV, PNG)** | `sql/profiling/`, `hasil-profiling/`, `bukti/database/` |
| Grain satu kalimat | **Selesai** | Tercantum pada README & Bagian 6.2 laporan ini |
| Star Schema v1 | **Selesai** | `docs/star-schema-v1.png` |
| Bus matrix tim | **Selesai** | Tercantum pada Bagian 7 laporan ini |
| ≥3 risiko beserta mitigasi | **Enam risiko disusun** | `docs/risiko-awal.md` |
| Laporan pekan 10 | **Tersedia** | `laporan/pekan-10.md` |

## 10. Hambatan dan Keputusan

1. Upload dump berukuran sekitar 98 MB melalui phpMyAdmin melebihi batas unggah PHP; tim berhasil mengimpor melalui MySQL CLI di XAMPP.
2. Sebagian produk katalog tidak memiliki subkategori, namun seluruh 130 produk unik yang terjual online memiliki kategori lengkap pada data yang diuji.
3. `CurrencyRateID` NULL cukup tinggi; belum ada bukti cukup untuk menyimpulkan mata uang setiap pesanan tersebut.
4. Keputusan teknis: sumber `adventureworks` tetap read-only; data warehouse dan ETL menggunakan target database terpisah.

## 11. Rencana Pekan Berikutnya

- Lengkapi bukti screenshot undangan dosen di `bukti/github/`.
- Review Star Schema v1 dan definisi tujuh dimensi bersama tim lintas proses bisnis.
- Pastikan aturan `dim_currency`, konversi, dan metrik nilai penjualan disepakati.
- Desain aliran ETL dari header/detail ke dimensi dan fakta dalam database Data Warehouse terpisah.
- Definisikan pemeriksaan rekonsiliasi (`COUNT` fakta, pesanan unik, unit, subtotal) dan sketsa OLAP/dashboard.

## 12. Indeks Bukti Repositori

```text
README.md
.gitignore
docs/
  risiko-awal.md
  star-schema-v1.png
sql/profiling/
  07-penjualan-online-per-bulan.sql
  08-profiling-null-online-sales.sql
  09-profiling-currency-online.sql
  10-profiling-rentang-tanggal.sql
hasil-profiling/
  07-penjualan-online-per-bulan.csv
  08-profiling-null-online-sales.csv
  09-profiling-currency-online.csv
  10-profiling-rentang-tanggal.csv
bukti/
  github/
    .gitkeep
  database/
    01-verifikasi-database.png
    02-profiling-transaksi-online.png
    03-profiling-produk.png
    04-validasi-grain.png
    05-profiling-orderqty.png
    06-validasi-tujuh-dimensi.png
    07-penjualan-online-per-bulan.png
    08-profiling-null-online-sales.png
    09-profiling-currency-online.png
    10-profiling-rentang-tanggal.png
laporan/
  pekan-10.md
etl/
  .gitkeep
olap/
  .gitkeep
dashboard/
  .gitkeep
```

---

**Disusun oleh:** Kelompok 2 — Tim Data Warehouse Penjualan Online  
**Tanggal:** 1 November 2026  
**Pemeriksaan sponsor:** Menunggu Steering Review.
