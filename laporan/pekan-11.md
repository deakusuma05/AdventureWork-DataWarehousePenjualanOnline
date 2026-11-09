# Laporan Progres Pekan 11 — Penyempurnaan Star Schema V2, Spesifikasi ETL, Desain Cube OLAP, dan Wireframe Dashboard

## Proyek Data Warehouse AdventureWorks — Penjualan Online

**Mata kuliah:** Data Warehouse  
**Program studi:** Sistem Informasi, Fakultas Ilmu Komputer, UPN "Veteran" Jawa Timur  
**Periode:** Semester Ganjil 2026/2027  
**Proses bisnis:** Penjualan Online (*Online Sales* — `OnlineOrderFlag = 1`)  
**Database sumber:** `adventureworks` (MySQL/MariaDB melalui XAMPP, *read-only*)  
**Database target DW:** `adventureworks_dw` (MySQL/MariaDB)  
**Project sponsor:** Dosen pengampu mata kuliah  
**Status dokumen:** Final — Seluruh deliverable Pekan 10–11 telah diselesaikan dan terverifikasi.

---

## 1. Tim dan Pembagian Peran

| No. | Nama | NPM | Peran Utama | Fokus Kontribusi Pekan 10–11 |
|---:|---|---|---|---|
| 1 | Dea Kusuma Ningrum | 23082010048 | Project Manager & Business Analyst | Koordinasi revisi sponsor, penyelarasan 7 pertanyaan bisnis, dan review laporan |
| 2 | Fivediniar Edra Primaulidina | 23082010046 | Data Engineer & ETL Developer | Koneksi Pentaho Data Integration (PDI), transformasi `.ktr`, job `.kjb`, dan urutan load |
| 3 | Siti Anisa Safitri | 23082010045 | Data Warehouse & Dimensional Modeler | Star Schema V2 (`dim_date` & `dim_product` standar), dokumen `mapping.md`, dan `scd-strategy.md` |
| 4 | Haura Taqiya Azza Nabila | 23082010165 | OLAP & Dashboard Developer | Tabel desain Cube OLAP (beserta *calculated members*) dan prototipe `wireframe-dashboard.html` |
| 5 | Alifa Zuriyatul Haq | 23082010050 | Data Quality, Testing & Documentation | Validasi rekonsiliasi `fact_online_sales` (60.398 baris), audit kualitas kurs, dan dokumentasi bukti |

---

## 2. Ringkasan Eksekutif Pekan 11

Menindaklanjuti evaluasi *Steering Review* Pekan 10 bersama sponsor proyek, tim telah menyelesaikan revisi pemodelan dimensional menjadi **Star Schema Versi 2**, menyusun spesifikasi **Source-to-Target Mapping** serta **Strategi Slowly Changing Dimension (SCD)** secara menyeluruh, merancang **Desain Cube OLAP** beserta *calculated members*, membuat **Wireframe Dashboard** interaktif yang mencakup seluruh 7 pertanyaan bisnis (P1–P7), dan mengimplementasikan **aliran ETL Pentaho Data Integration (PDI / Spoon)** yang terhubung langsung dari database sumber `adventureworks` menuju database target `adventureworks_dw`.

Hasil eksekusi dan rekonsiliasi fisik pada `adventureworks_dw.fact_online_sales` menunjukkan kecocokan 100% terhadap baseline profiling sumber: **60.398 baris detail transaksi**, **27.659 pesanan unik**, **18.484 pelanggan aktif**, **60.398 unit produk terjual**, dan total nilai penjualan **`$29.358.677,22`**.

---

## 3. Star Schema Versi 2 Sesuai Catatan Sponsor

Berdasarkan arahan sponsor proyek pada review sebelumnya, desain dimensional diperbarui dari versi 1 menjadi **Star Schema Versi 2** ([`docs/Star-Schema-V2.png`](../docs/Star-Schema-V2.png)) dengan ketentuan utama:

1. **Menggunakan Struktur Standar `dim_date` (`dim_tanggal`):**
   - Kunci utama `tanggal_key : int(11)` dengan format `YYYYMMDD` (serta anggota khusus `-1` bila tanggal tidak diketahui).
   - Dilengkapi 11 atribut kalender standar: `tanggal` (`date`), `tahun` (`int`), `semester` (`int`), `kuartal` (`int`), `bulan` (`int`), `nama_bulan` (`varchar(20)`), `minggu_dalam_tahun` (`int`), `tanggal_dalam_bulan` (`int`), `hari_dalam_minggu` (`int`), `nama_hari` (`varchar(20)`), dan `is_akhir_pekan` (`tinyint(1)`).
2. **Menggunakan Struktur Standar `dim_product` (`dim_produk`):**
   - Menggabungkan hierarki produk, subkategori, dan kategori ke dalam struktur denormalisasi standar (`snowflake` pada OLTP disederhanakan menjadi satu tabel dimensi bintang):
     - `product_key : int(11)` (Surrogate Key PK)
     - `product_id : int(11)` (Natural/Business Key dari `Production.Product.ProductID`)
     - `product_name : varchar(100)`
     - `product_number : varchar(50)`
     - `subcategory_name : varchar(100)`
     - `category_name : varchar(100)`
3. **Tabel Fakta `fact_online_sales` pada Grain Detail Pesanan:**
   - Mempertahankan grain satu baris per item detail pesanan online (`sales_detail_key`), menyimpan `sales_order_id` sebagai *degenerate dimension* untuk perhitungan `COUNT(DISTINCT sales_order_id)`, ketujuh *foreign key* dimensi (`tanggal_key`, `product_key`, `customer_key`, `territory_key`, `promotion_key`, `currency_key`, `ship_method_key`), serta empat *measures* numerik (`order_qty`, `unit_price`, `unit_price_discount`, `line_total`).

### Ringkasan Tabel pada Star Schema V2 (`adventureworks_dw`)

| No. | Nama Tabel | Peran Tabel | Primary Key (PK) | Business / Natural Key | Jumlah Kolom | Jumlah Baris Aktual di DW |
|---:|---|---|---|---|---:|---:|
| 1 | `dim_date` | Dimensi Tanggal (Standar) | `tanggal_key` | `tanggal` (`OrderDate`) | 12 | 1.127 |
| 2 | `dim_product` | Dimensi Produk (Standar) | `product_key` | `product_id` | 6 | 1.008 |
| 3 | `dim_customer` | Dimensi Pelanggan | `customer_key` | `customer_id` | 6 | 73.936 |
| 4 | `dim_territory` | Dimensi Wilayah | `territory_key` | `territory_id` | 5 | 20 |
| 5 | `dim_promotion` | Dimensi Promosi | `promotion_key` | `special_offer_id` | 6 | 32 |
| 6 | `dim_currency` | Dimensi Mata Uang & Kurs | `currency_key` | `currency_rate_id` | 6 | 9.865 |
| 7 | `dim_ship_method` | Dimensi Metode Kirim | `ship_method_key` | `ship_method_id` | 5 | 10 |
| 8 | `fact_online_sales` | Tabel Fakta Utama | `sales_detail_key` | `SalesOrderDetailID` | 13 | **60.398** |

**Bukti visual:** [`docs/Star-Schema-V2.png`](../docs/Star-Schema-V2.png) dan DDL/data fisik pada [`sql/dump_adventureworks_dw.sql`](../sql/dump_adventureworks_dw.sql).

---

## 4. Source-to-Target Mapping Lengkap

Spesifikasi pemetaan lengkap untuk seluruh kolom pada 7 tabel dimensi dan 1 tabel fakta telah didokumentasikan dalam [`docs/mapping.md`](../docs/mapping.md). Berikut adalah ringkasan sumber dan aturan transformasi utamanya:

| Tabel Target | Tabel Sumber Utama (OLTP `adventureworks`) | Transformasi Inti & Penanganan NULL |
|---|---|---|
| `dim_date` | Derivasi kalender dari rentang `sales_salesorderheader.OrderDate` | Ekstraksi atribut `YYYYMMDD`, tahun, semester (`<=6` &rarr; 1, `>6` &rarr; 2), kuartal, bulan, nama bulan/hari, dan flag akhir pekan (`Sabtu/Minggu = 1`). |
| `dim_product` | `production_product` LEFT JOIN `production_productsubcategory` LEFT JOIN `production_productcategory` | Denormalisasi subkategori dan kategori ke satu tabel; jika produk katalog tidak memiliki subkategori/kategori, dipetakan ke `'Unknown'` / `'Not Applicable'`. |
| `dim_customer` | `sales_customer` LEFT JOIN `person_person` / `sales_store` | Penggabungan nama pelanggan (`FirstName`, `MiddleName`, `LastName` untuk individu atau `Store.Name` untuk toko) serta klasifikasi `customer_type` (`Individual` / `Store`). |
| `dim_territory` | `sales_salesterritory` | Penyalinan `TerritoryID`, `Name`, `CountryRegionCode`, dan `Group` (`North America`, `Pacific`, `Europe`). |
| `dim_promotion` | `sales_specialoffer` | Penyalinan `SpecialOfferID`, `Description`, `DiscountPct`, `Type`, dan `Category`. |
| `dim_currency` | `sales_currencyrate` + baris khusus *Unknown/Default* | Menyimpan kurs historis (`FromCurrencyCode`, `ToCurrencyCode`, `AverageRate`, `EndOfDayRate`). Transaksi dengan `CurrencyRateID IS NULL` dipetakan ke baris khusus `currency_rate_id = -1` (`currency_key = 1`). |
| `dim_ship_method` | `purchasing_shipmethod` | Penyalinan `ShipMethodID`, `Name`, `ShipBase`, dan `ShipRate`. |
| `fact_online_sales` | `sales_salesorderdetail` INNER JOIN `sales_salesorderheader` (`OnlineOrderFlag = 1`) | Lookup ketujuh surrogate key dimensi berdasarkan business key transaksi; menyalin `OrderQty`, `UnitPrice`, `UnitPriceDiscount`, dan `LineTotal` tanpa mengubah presisi sumber. |

Detail kolom demi kolom beserta tipe data dan aturan validasi NULL dapat dilihat langsung pada [`docs/mapping.md`](../docs/mapping.md).

---

## 5. Strategi Slowly Changing Dimension (SCD)

Strategi penanganan perubahan atribut dimensi telah ditetapkan secara tertulis pada [`docs/scd-strategy.md`](../docs/scd-strategy.md) dan [`docs/mapping.md`](../docs/mapping.md):

| Tabel Dimensi | Tipe SCD | Atribut yang Dipantau | Rasional Bisnis & Mekanisme |
|---|:---:|---|---|
| `dim_date` | **Type 0** | Seluruh atribut kalender | Kalender bersifat tetap (*fixed/immutable*); tidak ada pembaruan setelah dimuat. |
| `dim_product` | **Type 2** | `product_name`, `product_number`, `subcategory_name`, `category_name` | Menyimpan riwayat perubahan atribut atau reklasifikasi produk dengan membuat baris versi baru (`product_key` baru) untuk `product_id` yang sama agar histori penjualan masa lalu tetap akurat. |
| `dim_customer` | **Type 1** | `account_number`, `customer_type`, `customer_name`, `territory_id` | Pembaruan data profil/nama pelanggan menimpa (*overwrite*) nilai lama tanpa membuat baris baru. |
| `dim_territory` | **Type 1** | `territory_name`, `country_code`, `territory_group` | Koreksi penamaan wilayah atau grup menimpa nilai lama. |
| `dim_promotion` | **Type 0** | `description`, `discount_pct`, `type`, `category` | Ketentuan promosi historis pada saat transaksi berlangsung dipertahankan (*retain original*). |
| `dim_currency` | **Type 0** | `from_currency_code`, `to_currency_code`, `average_rate`, `end_of_day_rate` | Nilai tukar harian pada `CurrencyRateID` tertentu merupakan rekaman historis tetap. |
| `dim_ship_method` | **Type 1** | `ship_method_name`, `ship_base`, `ship_rate` | Pembaruan nama ekspedisi atau tarif dasar menimpa nilai lama. |

> **Catatan Kepatuhan Struktur Standar pada `dim_product` (SCD Type 2):**  
> Demi menjaga kepatuhan terhadap skema standar kelas pada Star Schema V2 (`product_key`, `product_id`, `product_name`, `product_number`, `subcategory_name`, `category_name`), tabel fisik `dim_product` mempertahankan keenam kolom standar tersebut, sementara aturan penambahan kolom masa berlaku versi (`effective_start_date`, `effective_end_date`, `is_current`) atau penggunaan tabel pendamping telah didokumentasikan pada [`docs/scd-strategy.md`](../docs/scd-strategy.md) Bagian 4.

---

## 6. Urutan Load ETL (*Load Sequence*) dan Orkestrasi Pentaho

Urutan pemuatan data (*load order*) telah didokumentasikan pada [`docs/mapping.md`](../docs/mapping.md) Bagian 3 dan diimplementasikan ke dalam Job Pentaho [`etl/online-sales-etl.kjb`](../etl/online-sales-etl.kjb) (serta [`etl/jobs/online-sales-etl.kjb`](../etl/jobs/online-sales-etl.kjb)). Seluruh tabel dimensi wajib selesai dimuat terlebih dahulu sebelum tabel fakta dijalankan agar proses *surrogate key lookup* tidak menghasilkan referensi yatim (*orphan foreign keys*):

1. **`01-dim-date.ktr`** — Membangun dan memuat dimensi kalender `dim_date` dari rentang tanggal transaksi.
2. **`02-dim-product.ktr`** — Mengekstrak katalog produk beserta subkategori dan kategori ke `dim_product`.
3. **`03-dim-customer.ktr`** — Mengekstrak master pelanggan dan profil nama ke `dim_customer`.
4. **`04-dim-territory.ktr`** — Memuat referensi wilayah pemasaran ke `dim_territory`.
5. **`05-dim-promotion.ktr`** — Memuat daftar penawaran/promosi ke `dim_promotion`.
6. **`06-dim-currency.ktr`** — Memuat referensi kurs valuta asing beserta baris khusus *Unknown/Default* (`currency_rate_id = -1`) ke `dim_currency`.
7. **`07-dim-ship-method.ktr`** — Memuat daftar metode pengiriman ke `dim_ship_method`.
8. **`08-fact-online-sales.ktr`** — Mengekstrak transaksi `OnlineOrderFlag = 1`, melakukan *lookup* ketujuh *surrogate key* dimensi, dan memuat 60.398 baris detail ke `fact_online_sales`.
9. **Verifikasi & Rekonsiliasi Pasca-Load** — Memastikan `COUNT(*) = 60.398`, `COUNT(DISTINCT sales_order_id) = 27.659`, `SUM(order_qty) = 60.398`, dan `ROUND(SUM(line_total), 2) = 29358677.22`.

**Bukti Tangkapan Layar Pentaho & Rekonsiliasi Database:**
- Orkestrasi Job Pentaho Spoon terhubung ke database: [`etl/documentation/00-job-orchestration-success.png`](../etl/documentation/00-job-orchestration-success.png) dan [`etl/documentation/00-job-orchestration-success-new.png`](../etl/documentation/00-job-orchestration-success-new.png).
- Hasil rekonsiliasi tabel fakta di phpMyAdmin: [`bukti/database/validation-fact-online-sales.png`](../bukti/database/validation-fact-online-sales.png).

---

## 7. Desain Cube OLAP dan *Calculated Members*

Spesifikasi lengkap desain Cube OLAP telah disusun dalam workbook [`docs/desain-cube-online-sales-bus-matrix-v1.1.xlsx`](../docs/desain-cube-online-sales-bus-matrix-v1.1.xlsx) yang mencakup 7 lembar kerja (*Ringkasan*, *Pertanyaan & Visual*, *Dimensi & Hierarki*, *Measures & Kalkulasi*, *Implementasi Mondrian*, *Validasi & Keputusan*, dan *Bus Matrix*).

### 7.1 Spesifikasi Hierarki Dimensi Cube (`OnlineSalesCube`)

| Dimensi Cube | Tabel DW | Foreign Key di Fakta | Hierarki Drill-Down | Level Atribut |
|---|---|---|---|---|
| **Time / Tanggal** | `dim_date` | `tanggal_key` | `Tahun` &rarr; `Semester` &rarr; `Kuartal` &rarr; `Bulan` &rarr; `Tanggal` | `tahun`, `semester`, `kuartal`, `nama_bulan`, `tanggal` |
| **Product / Produk** | `dim_product` | `product_key` | `Kategori` &rarr; `Subkategori` &rarr; `Produk` | `category_name`, `subcategory_name`, `product_name` |
| **Territory / Wilayah** | `dim_territory` | `territory_key` | `Grup Wilayah` &rarr; `Negara` &rarr; `Wilayah` | `territory_group`, `country_code`, `territory_name` |
| **Customer / Pelanggan** | `dim_customer` | `customer_key` | `Tipe Pelanggan` &rarr; `Pelanggan` | `customer_type`, `customer_name` (`customer_id`) |
| **Promotion / Promosi** | `dim_promotion` | `promotion_key` | `Kategori Promo` &rarr; `Tipe Promo` &rarr; `Penawaran` | `category`, `type`, `description` |
| **Currency / Kurs** | `dim_currency` | `currency_key` | `Status Kurs` &rarr; `Kode Mata Uang Tujuan` | `currency_rate_id` (Known vs Unknown), `to_currency_code` |
| **Ship Method / Metode Kirim** | `dim_ship_method` | `ship_method_key` | `Metode Pengiriman` | `ship_method_name` |

### 7.2 Tabel Measures Dasar dan *Calculated Members*

| Nama Measure / Member | Jenis | Kolom / Formula MDX Konseptual | Sifat Agregasi | Nilai Baseline DW | Pertanyaan Terkait |
|---|---|---|---|---:|---|
| **Nilai Penjualan (`Sales Amount`)** | Base Measure | `SUM(fact_online_sales.line_total)` | Aditif | `$29.358.677,22` | P1, P2, P3, P4, P5, P6, P7 |
| **Total Unit (`Order Quantity`)** | Base Measure | `SUM(fact_online_sales.order_qty)` | Aditif | `60.398 unit` | P1, P2 |
| **Jumlah Baris Detail (`Detail Count`)** | Base Measure | `COUNT(fact_online_sales.sales_detail_key)` | Aditif | `60.398 baris` | P5, P6, P7 |
| **Jumlah Pesanan Unik (`Distinct Orders`)** | Base Measure | `COUNT(DISTINCT fact_online_sales.sales_order_id)` | Non-aditif lintas dimensi item | `27.659 pesanan` | P1, P3, P4, P6, P7 |
| **Pelanggan Aktif (`Active Customers`)** | Base Measure | `COUNT(DISTINCT fact_online_sales.customer_key)` | Non-aditif | `18.484 pelanggan` | P3 |
| **Rata-Rata Nilai Pesanan (`Average Order Value / AOV`)** | **Calculated Member (Wajib)** | `IIF([Measures].[Distinct Orders] = 0, NULL, [Measures].[Sales Amount] / [Measures].[Distinct Orders])` | Turunan (Rasio) | **`$1.061,45`** | P1, P3, P4 |
| **Estimasi Diskon Promosi (`Estimated Promo Discount`)** | **Calculated Member** | `SUM(fact_online_sales.line_total * dim_promotion.discount_pct)` | Turunan | **`$48.530,24`** | P5 |
| **Persentase Pesanan Tanpa Kurs (`Unknown Currency Order %`)** | **Calculated Member** | `IIF([Measures].[Distinct Orders] = 0, NULL, [Measures].[Orders Without CurrencyRate] / [Measures].[Distinct Orders])` | Turunan (Proporsi) | **`53,73%`** (14.860 / 27.659) | P6 |

---

## 8. Wireframe Dashboard dan Pemetaan 7 Pertanyaan Bisnis

Tim telah membangun prototipe wireframe interaktif pada [`dashboard/wireframe-dashboard.html`](../dashboard/wireframe-dashboard.html) beserta dokumentasi perancangannya pada [`docs/wireframe-dashboard.md`](../docs/wireframe-dashboard.md) dan laporan audit teknis [`docs/dashboard-improvement-report.md`](../docs/dashboard-improvement-report.md).

Dashboard dirancang menggunakan bahasa visual **Soft Geometric Blue Analytics** (*Tonal Blue Bento Cards, Capsule Bar Charts, Dark Ink Accents, Spacious White Canvas*) dan dibagi menjadi **2 halaman analitik utama** (maksimal 5 visual pada Halaman 1) ditambah **1 halaman spesifikasi kueri SQL/JSON**:

| Kode | Pertanyaan Bisnis | Visual pada Wireframe Dashboard |Lokasi Halaman | Hasil Aktual dari `adventureworks_dw` |
|---|---|---|---|---|
| **P1** | Bagaimana tren nilai penjualan online setiap bulan? | Kartu KPI *Nilai Penjualan Online* & *Jumlah Pesanan Unik* + *Dual-Axis Line Chart* Tren Bulanan (38 bulan) | Halaman 1 (Atas & Tengah) | Total **`$29.358.677,22`** dari **`27.659`** pesanan; puncak pada **Mei 2014** (`$1.951.195,90` • `5.624 unit`). |
| **P2** | Produk, subkategori, dan kategori apa yang berkontribusi terbesar? | *Horizontal Capsule Bar Chart* Proporsi Kategori + Daftar Top 3 Produk Terlaris | Halaman 1 (Bawah — Kolom Kiri) | **Bikes** mendominasi **`$28,32M` (96,46%)**, diikuti **Accessories** (`$700,8K`) dan **Clothing** (`$339,8K`). Produk #1: *Mountain-200 Black, 46* (`$1,37M`). |
| **P3** | Pelanggan mana yang memberikan kontribusi terbesar pada penjualan online? | Kartu KPI *Pelanggan Aktif* + Frekuensi Pesanan per Pelanggan & Indikator Pelanggan VIP | Halaman 1 (Kartu KPI ke-3) | **`18.484`** pelanggan aktif online (rata-rata **`1,50 pesanan/pelanggan`**; 29 pelanggan VIP dengan transaksi `>$10.000`). |
| **P4** | Wilayah mana yang mencatat transaksi dan nilai penjualan online terbesar? | *Ranking Capsule Bar Chart* Penjualan per Grup Wilayah & Highlight Negara Teratas | Halaman 1 (Bawah — Kolom Tengah) | **North America** **`$11,37M` (38,72%)**, **Pacific/Australia** **`$9,06M` (30,86%)**, dan **Europe** **`$8,93M` (30,42%)**. |
| **P5** | Bagaimana distribusi nilai penjualan online menurut penawaran/promosi? | Kartu KPI *Estimasi Diskon Promosi* + Tabel *Promotion & Discount* | Halaman 1 (KPI ke-4 & Bawah — Kolom Kanan) | **58.247 baris** *No Discount* (`$27,31M`) dan **2.151 baris berpromosi** (`$2,05M`) dengan estimasi potongan **`$48.530,24`**. |
| **P6** | Bagaimana kelengkapan informasi mata uang dan distribusi menurut kode valuta? | *Split Bar* Kelengkapan Kurs (`currency_rate_id = -1` vs `> 0`) + Tabel Distribusi Kode Valuta (`to_currency_code`) | Halaman 2 (Panel Kanan) | **14.860 pesanan (53,73%)** tanpa referensi kurs (`-1` / default USD `$14,69M`) dan **12.799 pesanan (46,27%)** memiliki kurs (`AUD` 6.550, `CAD` 3.147, `GBP` 2.967, `DEM` 76, `FRF` 59). |
| **P7** | Metode kirim apa yang paling sering dipakai oleh pesanan online? | *Capsule Bar Chart* Distribusi Metode Pengiriman (`COUNT(DISTINCT sales_order_id)`) | Halaman 2 (Panel Kiri) | **100% pesanan online (27.659 pesanan)** dikirim menggunakan **`XRQ - TRUCK GROUND`** (`ship_method_id = 1`). |

**Bukti Wireframe Dashboard:**
- Prototipe interaktif: [`dashboard/wireframe-dashboard.html`](../dashboard/wireframe-dashboard.html)
- Dokumentasi wireframe: [`docs/wireframe-dashboard.md`](../docs/wireframe-dashboard.md)
- Tangkapan layar: [`dashboard/wireframe dashboard.png`](../dashboard/wireframe%20dashboard.png) dan [`dashboard/wireframe dashboard 2.png`](../dashboard/wireframe%20dashboard%202.png)

---

## 9. Checklist Deliverable Pekan 11

| No. | Kriteria Deliverable Pekan 11 | Status | Berkas Bukti di Repositori |
|---:|---|---|---|
| 1 | Star schema versi 2 sesuai catatan sponsor | **Selesai** | [`docs/Star-Schema-V2.png`](../docs/Star-Schema-V2.png) |
| 2 | Star schema memakai `dim_tanggal` (`dim_date`) standar & `dim_produk` (`dim_product`) mengikuti struktur standar | **Selesai** | [`docs/Star-Schema-V2.png`](../docs/Star-Schema-V2.png), [`docs/mapping.md`](../docs/mapping.md), [`sql/dump_adventureworks_dw.sql`](../sql/dump_adventureworks_dw.sql) |
| 3 | Mapping lengkap untuk semua kolom dimensi dan fakta | **Selesai** | [`docs/mapping.md`](../docs/mapping.md) |
| 4 | Strategi SCD tertulis, minimal satu dimensi tipe 2 (`dim_product`) | **Selesai** | [`docs/scd-strategy.md`](../docs/scd-strategy.md), [`docs/mapping.md`](../docs/mapping.md) |
| 5 | Urutan load tertulis | **Selesai** | [`docs/mapping.md`](../docs/mapping.md) (Bagian 3), [`etl/online-sales-etl.kjb`](../etl/online-sales-etl.kjb) |
| 6 | Tabel desain cube dengan minimal satu *calculated member* | **Selesai** | [`docs/desain-cube-online-sales-bus-matrix-v1.1.xlsx`](../docs/desain-cube-online-sales-bus-matrix-v1.1.xlsx) & Bagian 7 laporan ini |
| 7 | Wireframe dashboard, semua pertanyaan bisnis (P1–P7) terwakili | **Selesai** | [`dashboard/wireframe-dashboard.html`](../dashboard/wireframe-dashboard.html), [`docs/wireframe-dashboard.md`](../docs/wireframe-dashboard.md), [`dashboard/wireframe dashboard.png`](../dashboard/wireframe%20dashboard.png) |
| 8 | Tangkapan layar Pentaho terhubung ke database sumber & validasi fakta | **Selesai** | [`etl/documentation/00-job-orchestration-success.png`](../etl/documentation/00-job-orchestration-success.png), [`etl/documentation/00-job-orchestration-success-new.png`](../etl/documentation/00-job-orchestration-success-new.png), [`bukti/database/validation-fact-online-sales.png`](../bukti/database/validation-fact-online-sales.png) |
| 9 | Laporan `laporan/pekan-11.md` siap | **Selesai** | [`laporan/pekan-11.md`](pekan-11.md) |

---

## 10. Rencana Tindak Lanjut Pekan 12–13

1. **Finalisasi Validasi Inkremental & Penanganan Exception ETL (Pekan 12):** Memastikan seluruh transformasi `.ktr` pada folder [`etl/`](../etl/) memiliki *error handling* dan pengujian idempotensi apabila job dijalankan ulang.
2. **Implementasi Skema XML Mondrian (`olap/` — Pekan 13):** Menerjemahkan spesifikasi pada [`docs/desain-cube-online-sales-bus-matrix-v1.1.xlsx`](../docs/desain-cube-online-sales-bus-matrix-v1.1.xlsx) ke dalam berkas XML Pentaho Schema Workbench (`olap/adventureworks_online_sales.xml`) dan menguji kueri MDX terhadap angka rekonsiliasi SQL.
3. **Integrasi Backend API ke Dashboard (Pekan 14):** Menghubungkan endpoint kueri SQL/OLAP ke [`dashboard/wireframe-dashboard.html`](../dashboard/wireframe-dashboard.html) sesuai spesifikasi pada [`docs/dashboard-improvement-report.md`](../docs/dashboard-improvement-report.md).

---

**Disusun oleh:** Kelompok 2 — Tim Data Warehouse Penjualan Online  
**Tanggal:** 10 November 2026  
**Status:** Siap untuk Review Pekan 11.

