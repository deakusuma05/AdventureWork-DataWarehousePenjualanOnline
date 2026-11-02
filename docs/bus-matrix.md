
# Bus Matrix — Data Warehouse Penjualan Online AdventureWorks

**Kelompok:** 2  
**Mata Kuliah:** Data Warehouse & OLAP  
**Program Studi:** Sistem Informasi, UPN “Veteran” Jawa Timur  
**Dokumen:** `docs/bus-matrix.md`  
---

## 1. Identitas dan Tanggung Jawab Tim

| Nama | Peran |
|---|---|
| Dea Kusuma Ningrum | Project Manager & Business Analyst |
| Fivediniar Edra Primaulidina | Data Engineer & ETL Developer |
| Siti Anisa Safitri | Data Warehouse & Dimensional Modeler |
| Haura Taqiya Azza Nabila | OLAP & Dashboard Developer |
| Alifa Zuriyatul Haq | Data Quality, Testing & Documentation |

Kelompok mengembangkan Data Warehouse berdasarkan database
AdventureWorks dengan fokus pada proses bisnis Penjualan Online.

Bus Matrix digunakan untuk menentukan hubungan antara proses bisnis
dan dimensi analisis yang diperlukan dalam perancangan star schema.

## 2. Proses Bisnis yang Dipilih

Proses bisnis yang dipilih adalah **Penjualan Online (Online Sales Order)**.

Analisis dibatasi pada transaksi dengan:

`OnlineOrderFlag = TRUE`

### 2.1 Identifikasi Sumber Data

| Komponen | Tabel Sumber | Keterangan |
|---|---|---|
| Header transaksi | `sales_salesorderheader` | Informasi pesanan |
| Detail transaksi | `sales_salesorderdetail` | Detail produk yang dipesan |
| Produk | `production_product` | Informasi produk |
| Pelanggan | `sales_customer` | Identitas pelanggan |
| Wilayah | `sales_salesterritory` | Wilayah penjualan |
| Promosi | `sales_specialoffer` | Informasi penawaran khusus |
| Metode pengiriman | `purchasing_shipmethod` | Informasi pengiriman |

### 2.2 Informasi Database

| Komponen | Nilai |
|---|---|
| DBMS | PostgreSQL |
| Database | `adventureworks` |
| Schema | `adventureworks2` |
| Jumlah tabel | 71 |
| Sifat sumber | Read-only |

Database sumber digunakan untuk membaca transaksi operasional.
Tabel Data Warehouse direncanakan disimpan secara terpisah.

## 3. Penentuan Grain

**Grain: Setiap baris pada tabel fakta merepresentasikan satu detail
item produk dalam satu pesanan penjualan online.**

Tabel fakta yang direncanakan adalah:

`fact_online_sales`

Identitas transaksi:

| Kolom | Fungsi |
|---|---|
| `SalesOrderID` | Identitas pesanan |
| `SalesOrderDetailID` | Identitas detail item |

Satu pesanan dapat mempunyai beberapa baris detail.

Konsekuensi pemilihan grain:

1. Jumlah detail dihitung dengan `COUNT(*)`.
2. Jumlah pesanan dihitung dengan `COUNT(DISTINCT SalesOrderID)`.
3. Kuantitas menggunakan `OrderQty`.
4. Nilai detail menggunakan `LineTotal`.
5. Nilai header tidak dijumlahkan berulang pada setiap detail.

Kolom `SubTotal`, `TaxAmt`, `Freight`, dan `TotalDue` berada
pada tingkat header pesanan.

Nilai tersebut tidak boleh langsung disalin ke semua baris detail
kemudian dijumlahkan karena dapat menyebabkan double counting.

## 4. Bus Matrix Versi 1

| Proses Bisnis | Tanggal | Produk | Pelanggan | Wilayah | Promosi | Mata Uang | Metode Kirim |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Penjualan Online | X | X | X | X | X | ? | X |

**Keterangan:**

- `X` = Dimensi digunakan dalam rancangan awal.
- `?` = Dimensi masih memerlukan pemeriksaan dan keputusan.
- Sel kosong = Dimensi tidak digunakan.

Enam dimensi menjadi rancangan utama:

1. Dimensi Tanggal
2. Dimensi Produk
3. Dimensi Pelanggan
4. Dimensi Wilayah
5. Dimensi Promosi
6. Dimensi Metode Pengiriman

Dimensi Mata Uang masih menjadi kandidat karena referensi kurs
dan kebutuhan analisis mata uang belum dipastikan.

## 5. Pemetaan Dimensi ke Sumber Data

| Dimensi DW | Business Key | Tabel Sumber | Kegunaan |
|---|---|---|---|
| `dim_date` | `OrderDate` | `sales_salesorderheader` | Analisis berdasarkan waktu |
| `dim_product` | `ProductID` | `sales_salesorderdetail`, `production_product` | Analisis produk |
| `dim_customer` | `CustomerID` | `sales_salesorderheader`, `sales_customer` | Analisis pelanggan |
| `dim_territory` | `TerritoryID` | `sales_salesorderheader`, `sales_salesterritory` | Analisis wilayah penjualan |
| `dim_promotion` | `SpecialOfferID` | `sales_salesorderdetail`, `sales_specialoffer` | Analisis penawaran khusus |
| `dim_ship_method` | `ShipMethodID` | `sales_salesorderheader`, `purchasing_shipmethod` | Analisis metode pengiriman |
| `dim_currency` | Belum ditetapkan | `sales_currencyrate`, `sales_currency` | Kandidat analisis mata uang |

### 5.1 Dimensi Tanggal

Dimensi Tanggal menggunakan `OrderDate` sebagai tanggal utama.

Atribut yang direncanakan:

- Tanggal
- Hari
- Bulan
- Kuartal
- Tahun

Hierarki OLAP:

**Tahun → Kuartal → Bulan → Tanggal**

Zona waktu pelaporan perlu ditetapkan sebelum membentuk
kunci tanggal agar pengelompokan transaksi per bulan konsisten.

### 5.2 Dimensi Produk

Dimensi Produk menggunakan `ProductID`.

Sumber informasi produk:

- `production_product`
- `production_productsubcategory`
- `production_productcategory`

Hierarki OLAP:

**Kategori → Subkategori → Produk**

Berdasarkan profiling sebelumnya, terdapat 130 produk unik
yang terjual melalui kanal online.

Produk tanpa kategori harus ditangani secara eksplisit
agar tidak hilang selama proses transformasi.

### 5.3 Dimensi Pelanggan

Dimensi Pelanggan menggunakan `CustomerID` dari header pesanan.

Dimensi ini digunakan untuk menganalisis:

- Jumlah pesanan setiap pelanggan.
- Nilai pesanan setiap pelanggan.
- Kontribusi pelanggan terhadap transaksi online.

### 5.4 Dimensi Wilayah

Dimensi Wilayah menggunakan `TerritoryID`.

Wilayah yang dianalisis merupakan wilayah penjualan,
bukan otomatis alamat tujuan pengiriman.

Atribut yang direncanakan:

- Nama wilayah
- Kelompok wilayah
- Kode negara atau region

### 5.5 Dimensi Promosi

Dimensi Promosi menggunakan `SpecialOfferID`.

Keberadaan ID penawaran tidak selalu berarti transaksi
memperoleh diskon positif.

Analisis diskon juga perlu menggunakan informasi
`UnitPriceDiscount`, `UnitPrice`, dan `LineTotal`.

### 5.6 Dimensi Metode Pengiriman

Dimensi Metode Pengiriman menggunakan `ShipMethodID`.

Dimensi ini digunakan untuk mengetahui jumlah pesanan
dan nilai transaksi menurut metode pengiriman.

Biaya `Freight` berasal dari tingkat header,
sehingga memerlukan perlakuan khusus jika akan
dianalisis pada tingkat detail.

## 6. Evaluasi Dimensi Mata Uang

Rancangan awal kelompok memasukkan `dim_currency`.

Namun, `CurrencyRateID` merupakan referensi data kurs,
bukan identitas mata uang secara langsung.

Hasil profiling sebelumnya menunjukkan:

- 33.400 baris detail online terkait dengan header
  yang memiliki `CurrencyRateID` NULL.

Angka tersebut dihitung pada tingkat detail,
bukan jumlah pesanan.

Sebelum memasukkan Dimensi Mata Uang, perlu diperiksa:

1. Hubungan `CurrencyRateID` dengan tabel kurs.
2. Makna nilai NULL pada `CurrencyRateID`.
3. Mata uang yang digunakan pada `LineTotal`.
4. Kebutuhan analisis berdasarkan mata uang.
5. Aturan konversi nilai transaksi.

**Keputusan sementara:**

`dim_currency` berstatus perlu validasi dan belum menjadi
dimensi wajib pada star schema versi 1.

Keputusan ini perlu diselaraskan dengan rancangan star schema
yang telah disusun kelompok.

## 7. Rancangan Tabel Fakta

Nama tabel fakta:

`fact_online_sales`

### 7.1 Identitas dan Foreign Key

| Kolom | Sumber | Fungsi |
|---|---|---|
| `sales_order_id` | `SalesOrderID` | Identitas pesanan |
| `sales_order_detail_id` | `SalesOrderDetailID` | Identitas detail |
| `order_date_key` | `OrderDate` | FK ke `dim_date` |
| `product_key` | `ProductID` | FK ke `dim_product` |
| `customer_key` | `CustomerID` | FK ke `dim_customer` |
| `territory_key` | `TerritoryID` | FK ke `dim_territory` |
| `promotion_key` | `SpecialOfferID` | FK ke `dim_promotion` |
| `ship_method_key` | `ShipMethodID` | FK ke `dim_ship_method` |

### 7.2 Measures

| Measure | Sumber | Agregasi |
|---|---|---|
| `order_quantity` | `OrderQty` | SUM |
| `line_sales_amount` | `LineTotal` | SUM |
| Jumlah detail | Baris tabel fakta | COUNT |
| Jumlah pesanan | `SalesOrderID` | COUNT DISTINCT |
| Harga satuan | `UnitPrice` | Tidak dijumlahkan |

Measure tambahan yang perlu diuji:

- `gross_amount`: nilai sebelum diskon.
- `discount_amount`: nominal diskon detail transaksi.

Rumus diskon perlu dibandingkan dengan nilai sumber
sebelum digunakan dalam laporan.

## 8. Pertanyaan Bisnis

| No. | Pertanyaan Bisnis | Dimensi | Measure |
|---|---|---|---|
| 1 | Bagaimana perkembangan nilai pesanan online setiap bulan? | Tanggal | SUM nilai detail |
| 2 | Produk dan kategori mana yang memberikan kontribusi terbesar? | Produk, Tanggal | SUM nilai detail |
| 3 | Pelanggan mana yang paling sering melakukan pesanan? | Pelanggan | COUNT DISTINCT pesanan |
| 4 | Wilayah penjualan mana yang memiliki nilai transaksi terbesar? | Wilayah | SUM nilai detail |
| 5 | Bagaimana nilai transaksi berdasarkan penawaran khusus? | Promosi | SUM nilai detail |
| 6 | Metode pengiriman mana yang paling banyak digunakan? | Metode Pengiriman | COUNT DISTINCT pesanan |

Setiap pertanyaan memiliki ukuran yang dapat dihitung
dan dimensi yang digunakan untuk mengelompokkan hasil.

## 9. Hasil Profiling Data Sumber

| Indikator | Hasil |
|---|---:|
| Jumlah tabel | 71 |
| Pesanan seluruh kanal | 31.465 |
| Detail seluruh kanal | 121.317 |
| Pesanan online | 27.659 |
| Detail online | 60.398 |
| Produk unik terjual online | 130 |
| Total unit online | 60.398 |
| Total `LineTotal` online | 29.358.677,22 |

Rentang `OrderDate` online:

- Tanggal awal: 31 Mei 2011.
- Tanggal akhir: 30 Juni 2014.

### 9.1 Profiling NULL

| Kolom | Jumlah NULL |
|---|---:|
| `CustomerID` | 0 |
| `TerritoryID` | 0 |
| `ShipMethodID` | 0 |
| `ProductID` | 0 |
| `SpecialOfferID` | 0 |
| `LineTotal` | 0 |
| `SalesPersonID` pada header terkait | 60.398 |
| `CurrencyRateID` pada header terkait | 33.400 |

Seluruh pesanan online tidak memiliki `SalesPersonID`.

Oleh karena itu, Dimensi Salesperson tidak dimasukkan
ke rancangan awal.

Angka profiling merupakan baseline sumber dan akan
digunakan untuk rekonsiliasi setelah ETL dijalankan.

## 10. Query Verifikasi PostgreSQL

Seluruh query menggunakan operasi baca-saja.

### 10.1 Verifikasi Jumlah Pesanan dan Detail

```sql
SELECT
    COUNT(*) AS jumlah_detail,
    COUNT(DISTINCT h.salesorderid) AS jumlah_pesanan,
    COUNT(DISTINCT d.productid) AS produk_unik,
    SUM(d.orderqty) AS total_unit,
    ROUND(SUM(d.linetotal)::numeric, 2) AS total_nilai
FROM adventureworks2.sales_salesorderheader h
JOIN adventureworks2.sales_salesorderdetail d
    ON d.salesorderid = h.salesorderid
WHERE h.onlineorderflag = TRUE;
```

### 10.2 Verifikasi NULL CurrencyRateID

```sql
SELECT
    COUNT(*) AS jumlah_pesanan_online,
    COUNT(*) FILTER (
        WHERE currencyrateid IS NULL
    ) AS tanpa_referensi_kurs,
    COUNT(*) FILTER (
        WHERE currencyrateid IS NOT NULL
    ) AS dengan_referensi_kurs
FROM adventureworks2.sales_salesorderheader
WHERE onlineorderflag = TRUE;
```

### 10.3 Pemeriksaan Duplikasi Detail

```sql
SELECT
    d.salesorderid,
    d.salesorderdetailid,
    COUNT(*) AS jumlah
FROM adventureworks2.sales_salesorderdetail d
JOIN adventureworks2.sales_salesorderheader h
    ON h.salesorderid = d.salesorderid
WHERE h.onlineorderflag = TRUE
GROUP BY
    d.salesorderid,
    d.salesorderdetailid
HAVING COUNT(*) > 1;
```

Hasil yang diharapkan adalah 0 baris.

### 10.4 Pemeriksaan Status Pesanan

```sql
SELECT
    status,
    COUNT(*) AS jumlah_pesanan
FROM adventureworks2.sales_salesorderheader
WHERE onlineorderflag = TRUE
GROUP BY status
ORDER BY status;
```

Hasil query digunakan untuk memahami status pesanan
sebelum menetapkan definisi KPI penjualan.

## 11. Conformed Dimension

Conformed dimension adalah dimensi yang memiliki definisi
konsisten dan dapat digunakan oleh beberapa proses bisnis.

| Dimensi | Status | Kebutuhan Kesepakatan |
|---|---|---|
| `dim_date` | Kandidat conformed | Kalender dan zona waktu |
| `dim_product` | Kandidat conformed | Identitas produk dan kategori |
| `dim_customer` | Belum ditetapkan | Definisi pelanggan |
| `dim_territory` | Belum ditetapkan | Definisi wilayah |
| `dim_promotion` | Belum ditetapkan | Definisi penawaran khusus |
| `dim_ship_method` | Belum ditetapkan | Klasifikasi metode pengiriman |
| `dim_currency` | Ditunda | Identitas mata uang dan penggunaan kurs |

Dimensi Tanggal dan Produk menjadi kandidat utama karena
berpotensi digunakan pada proses pembelian dan produksi.

Status akhir memerlukan kesepakatan dengan kelompok lain
serta Project Sponsor.

## 12. Risiko Awal

| Risiko | Dampak | Penanganan |
|---|---|---|
| Nilai header dihitung berulang pada detail | Nilai agregasi terlalu besar | Gunakan measure sesuai grain |
| Referensi mata uang belum jelas | Interpretasi nilai transaksi salah | Validasi kurs dan satuan pelaporan |
| Zona waktu berbeda | Transaksi berpindah bulan | Tetapkan zona waktu pelaporan |
| Relasi sumber tidak sesuai asumsi | Jumlah fakta tidak cocok | Periksa join dan duplikasi |
| Definisi dimensi berbeda antarkelompok | Analisis tidak konsisten | Sepakati conformed dimension |

## 13. Keputusan yang Masih Diperlukan

| No. | Keputusan | Status |
|---|---|---|
| 1 | Persetujuan grain detail pesanan | Menunggu review |
| 2 | Persetujuan enam dimensi utama | Menunggu review |
| 3 | Penggunaan Dimensi Mata Uang | Perlu pemeriksaan |
| 4 | Penetapan zona waktu | Belum diputuskan |
| 5 | Penentuan status pesanan untuk KPI | Perlu profiling |
| 6 | Persetujuan conformed dimension | Menunggu kesepakatan |
| 7 | Konsistensi Bus Matrix dan star schema | Perlu pemeriksaan |

## 14. Keterkaitan dengan Dokumen Proyek

Dokumen ini digunakan bersama:

- `docs/piagam-proyek.md`
- `docs/pertanyaan-bisnis.md`
- `docs/grain.md`
- `docs/star-schema-v1.md`
- `docs/star-schema-v1.drawio`
- `docs/star-schema-v1.png`
- `docs/risiko-awal.md`
- `sql/profiling/`
- `hasil-profiling/`
- `laporan/pekan-10.md`

## 15. Status Pengerjaan

| Komponen | Status |
|---|---|
| Pemilihan proses bisnis | Sudah dipilih |
| Pernyataan grain | Sudah dirancang |
| Bus Matrix versi 1 | Sudah dirancang |
| Pemetaan dimensi ke sumber | Perlu validasi relasi |
| Pertanyaan bisnis | Sudah disusun |
| Profiling awal | Sebagian hasil tersedia |
| Kesesuaian dengan star schema | Perlu diperiksa |
| Persetujuan conformed dimension | Menunggu kesepakatan |
| Persetujuan Project Sponsor | Belum dikonfirmasi |

## 16. Kesimpulan

Bus Matrix Penjualan Online dirancang berdasarkan grain
satu detail item dalam satu pesanan online.

Enam dimensi utama digunakan untuk mendukung analisis
waktu, produk, pelanggan, wilayah, promosi, dan pengiriman.

Dimensi Mata Uang masih memerlukan pemeriksaan karena
`CurrencyRateID` adalah referensi kurs dan sebagian
pesanan tidak memiliki nilai pada kolom tersebut.

Rancangan ini menjadi dasar pengembangan star schema
versi 1 dan akan disesuaikan berdasarkan hasil
validasi data serta keputusan Steering Review.
