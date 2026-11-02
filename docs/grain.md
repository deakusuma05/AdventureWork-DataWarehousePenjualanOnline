# Grain Fact Online Sales

**Proyek:** Data Warehouse Penjualan Online AdventureWorks  
**Kelompok:** 2 · Data Warehouse & OLAP  
**Versi:** 1.0 · 2 November 2026  
**Status:** Definisi rancangan untuk review tim

## 1. Pernyataan grain

**Satu baris pada `fact_online_sales` merepresentasikan satu baris detail produk dalam satu pesanan penjualan online, yang diidentifikasi oleh `SalesOrderDetailID`, dengan filter `OnlineOrderFlag = 1`.**

Grain menggunakan baris detail transaksi, bukan produk unik per pesanan, total pesanan, atau total penjualan per bulan. Produk yang sama dapat muncul pada lebih dari satu baris detail; setiap identitas detail tetap menjadi satu baris fakta tersendiri.

Proses bisnis yang didukung adalah **Analisis Kinerja Penjualan Online Berdasarkan Detail Transaksi**. Nama ringkasnya pada visual Bus Matrix adalah **Penjualan Online**.

## 2. Sumber, cakupan, dan jenis fakta

| Unsur | Definisi |
|---|---|
| Sumber → target | `adventureworks` → `adventureworks_dw` |
| Jenis fakta | Transaction fact |
| Header | `sales_salesorderheader` |
| Detail | `sales_salesorderdetail` |
| Hubungan | `h.SalesOrderID = d.SalesOrderID` |
| Filter | `h.OnlineOrderFlag = 1` |
| Waktu analisis utama | `h.OrderDate` |
| Identitas detail sumber | `d.SalesOrderDetailID` |
| Referensi pesanan | `h.SalesOrderID` |
| Fakta target | `fact_online_sales` |
| Periode | Seluruh periode sumber sesuai snapshot ekstraksi; baseline sebelumnya Mei 2011–Juni 2014 |

Filter status tambahan belum ditetapkan. Karena itu, data mewakili detail pesanan online sesuai filter sumber; penetapan pendapatan terealisasi memerlukan kebijakan status tersendiri. Jika filter berubah, baseline dan query rekonsiliasi harus berubah bersama.

## 3. Identitas dan kunci fakta

| Kolom target | Sumber/aturan | Fungsi |
|---|---|---|
| `sales_detail_key` | Kunci teknis opsional yang dibentuk pada target | Primary key teknis bila dipakai dalam implementasi |
| `sales_order_detail_id` | Detail.`SalesOrderDetailID` | Identitas sumber, wajib tidak NULL dan unik untuk sumber proyek ini |
| `sales_order_id` | Header.`SalesOrderID` | Referensi transaksi/degenerate dimension untuk distinct count dan audit |
| Tujuh kolom FK | Lookup primary key dimensi | Menghubungkan fakta dengan konteks analisis |
| `order_status_code` | Header.`Status` | Atribut audit/filter sesuai Bus Matrix |

Kunci teknis fakta tidak menggantikan pemeriksaan keunikan `sales_order_detail_id`. ETL menggunakan identitas detail untuk mencegah duplikasi saat pemuatan ulang. Satu pesanan boleh memiliki banyak detail, sehingga `sales_order_id` tidak unik pada fakta.

Jika kelak beberapa sistem sumber digabungkan, identitas unik perlu memasukkan penanda sumber. Perubahan itu berada di luar cakupan satu sumber AdventureWorks saat ini.

## 4. Hubungan tujuh dimensi

| Dimensi | Tabel dan PK | FK fakta | Referensi sumber | Makna konteks |
|---|---|---|---|---|
| Date | `dim_date.date_key` | `date_key` | Header.`OrderDate` | Tanggal pesanan |
| Product | `dim_product.product_key` | `product_key` | Detail.`ProductID` | Produk pada baris detail |
| Customer | `dim_customer.customer_key` | `customer_key` | Header.`CustomerID` | Pelanggan pemesan |
| Territory | `dim_territory.territory_key` | `territory_key` | Header.`TerritoryID` | Wilayah penjualan |
| Promotion | `dim_promotion.promotion_key` | `promotion_key` | Detail.`SpecialOfferID` | Penawaran yang terkait dengan detail |
| Currency | `dim_currency.currency_key` | `currency_key` | Header.`CurrencyRateID` → kurs → kode mata uang | Identitas mata uang setelah pemetaan tervalidasi |
| Ship Method | `dim_ship_method.ship_method_key` | `ship_method_key` | Header.`ShipMethodID` | Metode pengiriman pesanan |

Setiap baris fakta harus menemukan tepat satu anggota pada setiap dimensi, termasuk anggota khusus bila diperlukan. Hubungan tiap dimensi ke fakta adalah satu-ke-banyak. Lookup tidak boleh menggandakan baris detail. Bila SCD Type 2 dipilih, lookup menggunakan business key dan periode efektif agar hanya satu versi dimensi yang cocok.

`CurrencyRateID` merupakan referensi catatan kurs dan tidak otomatis menjadi business key `dim_currency`. Pemilihan mata uang asal/tujuan serta satuan nominal harus dipastikan sebelum mapping final. Status ketujuh dimensi tetap kandidat conformed dimension, sesuai [Bus Matrix](bus-matrix.md).

## 5. Measure dan aturan agregasi

| Kolom fakta | Sumber/rumus | Aturan agregasi |
|---|---|---|
| `order_qty` | Detail.`OrderQty` | Dapat dijumlahkan sebagai unit |
| `unit_price` | Detail.`UnitPrice` | Harga satuan; tidak dijumlahkan sebagai nilai penjualan |
| `unit_price_discount` | Detail.`UnitPriceDiscount` | Parameter diskon sumber; tidak dijumlahkan sebagai nominal diskon |
| `line_total` | Detail.`LineTotal` | Dapat dijumlahkan dalam satuan nominal yang konsisten; pertahankan nilai sumber |
| `gross_amount` | `order_qty × unit_price` | Measure turunan setelah formula dan presisi tervalidasi; agregasi mengikuti satuan mata uang |
| `discount_amount` | `gross_amount − line_total` | Measure turunan setelah rekonsiliasi formula; agregasi mengikuti satuan mata uang |

`LineTotal` telah merepresentasikan nilai detail setelah diskon menurut definisi rancangan. Jangan mengurangi nilai tersebut dengan diskon untuk kedua kalinya. Semantik `UnitPriceDiscount` sebagai rasio atau nominal diperiksa terhadap skema dan data aktual; nilai sumber dipertahankan selama pemeriksaan.

Nilai transaksi tidak diberi label rupiah atau USD tanpa bukti. Total nominal lintas kelompok hanya menjadi KPI bisnis setelah satuan sumber terbukti sama atau konversi ke mata uang pelaporan ditetapkan. Total mentah tetap dapat digunakan sebagai kontrol teknis terhadap snapshot sumber yang sama.

### 5.1 Ukuran tingkat pesanan

`SubTotal`, `TaxAmt`, `Freight`, dan `TotalDue` berada pada header pesanan. Nilai tersebut tidak disalin sebagai measure aditif ke setiap detail karena satu pesanan dapat memiliki beberapa detail. Apabila analisis nilai header dibutuhkan, gunakan perhitungan pada grain pesanan atau rancangan alokasi/fakta terpisah yang ditinjau terlebih dahulu.

### 5.2 Rumus KPI

| KPI | Rumus | Catatan |
|---|---|---|
| Jumlah detail | `COUNT(*)` | Menghitung baris fakta |
| Jumlah pesanan | `COUNT(DISTINCT sales_order_id)` | Hitung ulang pada setiap konteks agregasi |
| Jumlah unit | `SUM(order_qty)` | Tidak diasumsikan selalu sama dengan jumlah detail |
| Nilai detail | `SUM(line_total)` | Filter status dan satuan nominal harus konsisten |
| Rata-rata nilai pesanan | `SUM(line_total) / NULLIF(COUNT(DISTINCT sales_order_id), 0)` | Rasio dihitung dari agregat, bukan menjumlah rata-rata kelompok |
| Harga rata-rata tertimbang | `SUM(gross_amount) / NULLIF(SUM(order_qty), 0)` | Digunakan setelah validasi measure turunan dan satuan |
| Pelanggan unik | `COUNT(DISTINCT dim_customer.customer_id)` setelah join | Gunakan business key agar pergantian versi SCD tidak menambah pelanggan |

Jumlah pesanan antarproduk atau antarkategori tidak boleh dijumlahkan menjadi jumlah pesanan keseluruhan karena satu pesanan dapat mencakup beberapa produk/kategori. Distribusi metode kirim juga menggunakan pesanan distinct jika pertanyaannya jumlah pesanan, bukan jumlah detail.

## 6. Contoh penerapan grain

Contoh berikut adalah ilustrasi, bukan hasil ekstraksi AdventureWorks.

| SalesOrderID | SalesOrderDetailID | ProductID | OrderQty | LineTotal |
|---|---|---|---:|---:|
| 1001 | 501 | A | 2 | 200 |
| 1001 | 502 | B | 1 | 150 |
| 1001 | 503 | A | 1 | 100 |

Pesanan 1001 menghasilkan **tiga baris fakta**, **satu pesanan**, **empat unit**, dan **nilai detail 450** dalam satuan yang sama. Produk A muncul dua kali dengan identitas detail berbeda sehingga kedua baris tetap dipertahankan. Agregasi produk A menghasilkan tiga unit dan nilai 300, tanpa mengubah grain penyimpanan.

Jika ongkir pesanan sebesar 30 disalin ke ketiga detail dan dijumlahkan, hasilnya menjadi 90. Karena itu, ongkir header tidak diperlakukan sebagai measure aditif pada fakta ini.

## 7. Aturan transformasi dan integritas

1. Ekstrak header dan detail dari snapshot yang konsisten, lalu terapkan filter online yang sama untuk pemuatan dan rekonsiliasi.
2. Pastikan join header–detail tidak menghasilkan penggandaan dan tidak menyembunyikan detail yang tidak berpasangan; catat anomali sumber.
3. Interpretasikan `OrderDate` dengan aturan waktu yang ditetapkan sebelum lookup `date_key`.
4. Muat dimensi sebelum fakta. Lookup referensi sumber ke primary key dimensi, bukan menyalin ID sumber sebagai surrogate key secara otomatis.
5. Gunakan anggota Unknown untuk referensi yang belum teridentifikasi; bedakan dari Not Applicable jika kondisi tersebut memang terbukti. Catat ID sumber dan alasan lookup gagal pada staging/log audit.
6. Jangan menetapkan mata uang default hanya dari `CurrencyRateID` NULL. Simpan referensi kurs dan kondisi NULL pada staging/log agar jumlahnya tetap dapat ditelusuri.
7. Pertahankan harga dan nilai historis dari detail transaksi; harga master produk tidak menggantikannya.
8. Gunakan presisi desimal yang mempertahankan skala sumber. Pembulatan tampilan dilakukan setelah agregasi; toleransi rekonsiliasi didokumentasikan jika konversi presisi diperlukan.
9. Cegah duplikasi berdasarkan `sales_order_detail_id`. Perubahan baris sumber ditangani dengan strategi update/upsert atau reload yang terdokumentasi.
10. Catat baris yang ditolak beserta alasannya. Baris yang tertunda belum dianggap memenuhi penerimaan penuh sampai dimuat atau penyelesaiannya disetujui dan direkonsiliasi.

## 8. Baseline dan pengujian

Baseline berikut disalin dari Bus Matrix versi 2.0. Database tidak diuji ulang saat penyusunan dokumen ini.

| Kontrol | Nilai profiling sebelumnya |
|---|---:|
| Jumlah detail online | 60.398 |
| Detail ID unik | 60.398 |
| Pesanan online distinct | 27.659 |
| Produk unik terjual online | 130 |
| Total unit | 60.398 |
| Total `LineTotal` sumber, dibulatkan dua desimal | 29.358.677,22 |
| Detail dengan referensi kurs NULL | 33.400 |
| Pesanan dengan referensi kurs NULL | 14.860 |

Kesamaan jumlah detail dan unit adalah karakteristik data profiling sebelumnya, bukan aturan grain. Rancangan tetap mendukung `OrderQty > 1`.

### 8.1 Verifikasi grain sumber

Query menggunakan nama tabel MySQL/MariaDB sesuai acuan proyek.

```sql
SELECT
    COUNT(*) AS jumlah_detail,
    COUNT(DISTINCT d.SalesOrderDetailID) AS detail_unik,
    SUM(CASE WHEN d.SalesOrderDetailID IS NULL THEN 1 ELSE 0 END) AS detail_id_null,
    COUNT(DISTINCT h.SalesOrderID) AS jumlah_pesanan,
    COUNT(DISTINCT d.ProductID) AS produk_unik,
    SUM(d.OrderQty) AS jumlah_unit,
    SUM(d.LineTotal) AS nilai_detail_presisi_sumber
FROM adventureworks.sales_salesorderheader h
JOIN adventureworks.sales_salesorderdetail d
  ON h.SalesOrderID = d.SalesOrderID
WHERE h.OnlineOrderFlag = 1;
```

Syarat grain sumber adalah `jumlah_detail = detail_unik` dan `detail_id_null = 0`. Nominal presisi sumber disimpan untuk pembandingan; format dua desimal hanya untuk penyajian.

### 8.2 Verifikasi grain target

```sql
SELECT
    COUNT(*) AS jumlah_detail,
    COUNT(DISTINCT sales_order_detail_id) AS detail_unik,
    SUM(CASE WHEN sales_order_detail_id IS NULL THEN 1 ELSE 0 END) AS detail_id_null,
    COUNT(DISTINCT sales_order_id) AS jumlah_pesanan,
    SUM(order_qty) AS jumlah_unit,
    SUM(line_total) AS nilai_detail_presisi_target
FROM adventureworks_dw.fact_online_sales;
```

Query target dijalankan setelah tabel diimplementasikan dengan penamaan ini. Bandingkan dengan sumber pada snapshot dan filter yang sama. Produk unik diverifikasi melalui business key `dim_product.product_id`, bukan jumlah surrogate key apabila dimensi dihistorisasi.

### 8.3 Pemeriksaan penerimaan

| Kontrol | Syarat lulus |
|---|---|
| Grain | Detail ID tidak NULL dan tidak berulang |
| Cakupan | Tidak ada detail dari pesanan offline |
| Rekonsiliasi | Jumlah detail, pesanan, unit, dan nilai sesuai sumber dengan aturan presisi sama |
| Relasi dimensi | Tujuh FK menunjuk anggota valid; lookup tidak memperbanyak detail |
| Kurs NULL | Jumlah NULL sumber dapat direkonsiliasi melalui staging/audit dan anggota khusus sesuai mapping |
| Kalender | Pengelompokan bulanan konsisten setelah aturan tanggal ditetapkan |
| Pemuatan ulang | Re-run snapshot yang sama tidak menambah duplikasi atau mengubah total tanpa sebab |
| Agregasi OLAP | Roll-up/drill-down menjaga total measure aditif dan menghitung ulang distinct count |

Perbedaan hasil bulanan yang dicatat dalam Bus Matrix harus diselesaikan sebelum dashboard tren dinyatakan valid. Jumlah total yang cocok belum membuktikan distribusi bulan sudah tepat.

## 9. Keselarasan dan pengendalian perubahan

Dokumen ini menggunakan satu proses, satu fakta, tujuh dimensi, dan penamaan kolom fakta yang sama dengan [Bus Matrix](bus-matrix.md) serta [Piagam Proyek](piagam-proyek.md). Rancangan star schema pada acuan proyek menggunakan struktur yang sama. Gambar/skema fisik perlu tetap diperiksa saat implementasi, terutama pemetaan Currency, kunci teknis fakta, dan aturan SCD.

Pemetaan kode mata uang, status pesanan untuk KPI, interpretasi tanggal, formula diskon, serta historisasi masih mengikuti keputusan terbuka pada Bus Matrix. Tidak ada hasil ETL atau persetujuan yang diasumsikan selesai. Perubahan grain wajib ditinjau bersama perubahan star schema, mapping, ETL, baseline, dan definisi KPI.
