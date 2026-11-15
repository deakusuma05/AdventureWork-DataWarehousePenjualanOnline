# Kamus Data (Data Dictionary) — AdventureWorks Online Sales DW

**Kelompok 2 · Data Warehouse & OLAP · Sistem Informasi UPN “Veteran” Jawa Timur**  
**Versi Dokumen:** 1.0 (Pekan 11 — Pelaporan Steering Review Pekan 12)  
**Database Target:** `adventureworks_dw` (MySQL / MariaDB pada XAMPP)  
**Model Arsitektur:** Star Schema Versi 2 (1 Tabel Fakta + 7 Tabel Dimensi + Tabel Staging)  
**Grain Fakta:** Satu baris pada `fact_online_sales` merepresentasikan satu baris detail produk (`SalesOrderDetailID`) dalam satu pesanan penjualan online (`OnlineOrderFlag = 1`).

---

## 1. Penjelasan Khusus Dimensi Tanggal (`dim_date` / `dim_tanggal`)

* **Versi Skrip yang Digunakan:** `dim_tanggal` Standar Versi 1.0
* **Peran Dimensi:** SCD Tipe 0 (*Fixed Historic Calendar Dimension*)
* **Primary Key:** `tanggal_key` bertipe `INT(11)` berformat `YYYYMMDD` (contoh: `20110531`).

### Penjelasan dengan Bahasa Sendiri:
Tabel `dim_date` (atau `dim_tanggal`) adalah dimensi kalender standar yang menjadi tulang punggung analisis berbasis waktu (*time-series analysis*) di seluruh sistem Data Warehouse dan kubus OLAP kelompok kami. 

Berbeda dengan database transaksional (OLTP) yang mengandalkan fungsi kalkulasi tanggal saat query dijalankan, tabel dimensi tanggal di DW menyimpan seluruh atribut waktu yang sudah **dipra-kalkulasi (*pre-calculated*)** dan distandarkan ke dalam bahasa Indonesia.

1. **Mengapa Menggunakan Integer `YYYYMMDD` sebagai Primary Key (Bukan Tipe `DATE` Biasa)?**
   * **Efisiensi Join & Indexing:** Tipe data integer jauh lebih cepat diproses oleh mesin database saat melakukan *indexing* dan operasi *join* ke jutaan baris fakta dibandingkan tipe `DATE` atau `TIMESTAMP`.
   * **Kemudahan Partisi:** Format integer memudahkan partisi tabel fakta berdasarkan rentang tahun/bulan.
   * **Dukungan Baris Khusus (`-1`):** Kolom tanggal kalender asli tidak dapat menampung nilai `-1`. Dengan format integer, nilai `-1` dapat digunakan sebagai *surrogate key* untuk merepresentasikan transaksi dengan tanggal yang tidak valid atau tidak diketahui tanpa merusak relasi integritas referensial.
2. **Fungsi Baris Khusus `-1` (*Unknown Date Member*):**
   * Diisi nilai default: `tanggal_key = -1`, `tanggal = '1900-01-01'`, `nama_bulan = 'Unknown'`, dan `nama_hari = 'Unknown'`. Jika ada transaksi yang tanggalnya bermasalah, transaksi tersebut tetap dapat dimuat ke fakta dan tidak hilang diam-diam (*zero data loss*).
3. **Penyelarasan Hierarki OLAP:**
   * Kolom-kolom kalender disusun hierarkis: **Tahun $\rightarrow$ Semester $\rightarrow$ Kuartal $\rightarrow$ Bulan $\rightarrow$ Tanggal**, yang memungkinkan analisis *drill-down* (melihat rincian harian) dan *roll-up* (melihat ringkasan tahunan) secara instan.
4. **Analisis Hari Kerja vs Akhir Pekan:**
   * Keberadaan atribut `is_akhir_pekan` (`1` untuk Sabtu/Minggu, `0` untuk Senin–Jumat) memungkinkan tim bisnis membedakan pola perilaku belanja pelanggan online di hari kerja dibandingkan waktu libur.

---

## 2. Kamus Data Tabel Dimensi (Star Schema V2)

### 2.1. Tabel `dim_date` (Dimensi Tanggal Standar v1.0)
* **Tabel Sumber:** Derivasi kalender transaksi `sales_salesorderheader.OrderDate`
* **Tipe SCD:** SCD Tipe 0 (Permanen/Statis)

| Nama Kolom | Tipe Data | Peran | Aturan NULL | Keterangan / Definisi Bisnis |
|---|---|---|---|---|
| `tanggal_key` | `INT(11)` | **PK** | NOT NULL | Kunci pengganti format integer `YYYYMMDD` (atau `-1` untuk tidak diketahui). |
| `tanggal` | `DATE` | Natural Key | NOT NULL | Tanggal kalender lengkap format standar SQL (`YYYY-MM-DD`). |
| `tahun` | `INT(11)` | Atribut | NOT NULL | Angka tahun kalender 4 digit (contoh: 2011, 2012, 2013, 2014). |
| `semester` | `INT(11)` | Atribut | NOT NULL | Periode semester (1 untuk Jan–Jun, 2 untuk Jul–Des). |
| `kuartal` | `INT(11)` | Atribut | NOT NULL | Periode triwulan bisnis (1, 2, 3, atau 4). |
| `bulan` | `INT(11)` | Atribut | NOT NULL | Nomor urut bulan dalam tahun (1 s.d. 12). |
| `nama_bulan` | `VARCHAR(20)` | Atribut | NOT NULL | Nama bulan dalam bahasa Indonesia ('Januari' s.d. 'Desember'). |
| `minggu_dalam_tahun`| `INT(11)` | Atribut | NOT NULL | Nomor minggu dalam setahun sesuai kalender standar (1 s.d. 53). |
| `tanggal_dalam_bulan`| `INT(11)` | Atribut | NOT NULL | Tanggal / hari ke berapa dalam bulan tersebut (1 s.d. 31). |
| `hari_dalam_minggu` | `INT(11)` | Atribut | NOT NULL | Nomor urut hari (1 = Minggu, 2 = Senin, ..., 7 = Sabtu). |
| `nama_hari` | `VARCHAR(20)` | Atribut | NOT NULL | Nama hari dalam bahasa Indonesia ('Senin' s.d. 'Minggu'). |
| `is_akhir_pekan` | `TINYINT(1)` | Atribut | NOT NULL | Flag boolean status libur akhir pekan: `1` = Ya (Sabtu/Minggu), `0` = Tidak. |

---

### 2.2. Tabel `dim_product` (Dimensi Produk)
* **Tabel Sumber:** `production_product` JOIN `production_productsubcategory` JOIN `production_productcategory`
* **Tipe SCD:** SCD Tipe 1 (Overwrite) / Siap Tipe 2 jika disetujui sponsor
* **Karakteristik:** Denormalisasi kategori dan subkategori ke dalam satu tabel bintang tunggal (*star denormalization*).

| Nama Kolom | Tipe Data | Peran | Aturan NULL | Keterangan / Definisi Bisnis |
|---|---|---|---|---|
| `product_key` | `INT(11)` | **PK** | NOT NULL | Surrogate key buatan Data Warehouse (bernilai `-1` untuk produk tidak diketahui). |
| `product_id` | `INT(11)` | Natural Key | NOT NULL | ID unik produk dari sistem operasional OLTP (`ProductID`). |
| `product_name` | `VARCHAR(100)` | Atribut | Boleh NULL | Nama resmi produk katalog penjualan (contoh: *Mountain-200 Black, 38*). |
| `product_number` | `VARCHAR(50)` | Atribut | Boleh NULL | Kode SKU / nomor model pabrikan produk (contoh: *BK-M68B-38*). |
| `subcategory_name`| `VARCHAR(100)` | Atribut | Boleh NULL | Nama kelompok subkategori produk (contoh: *Mountain Bikes*, *Helmets*). |
| `category_name` | `VARCHAR(100)` | Atribut | Boleh NULL | Nama kategori produk level tertinggi (*Bikes*, *Accessories*, *Clothing*). |

---

### 2.3. Tabel `dim_customer` (Dimensi Pelanggan)
* **Tabel Sumber:** `sales_customer` JOIN `person_person`
* **Tipe SCD:** SCD Tipe 1 (Overwrite)
* **Karakteristik:** Khusus pelanggan transaksi penjualan online (`OnlineOrderFlag = 1`), seluruhnya merupakan pelanggan individu (*Individual Person*).

| Nama Kolom | Tipe Data | Peran | Aturan NULL | Keterangan / Definisi Bisnis |
|---|---|---|---|---|
| `customer_key` | `INT(11)` | **PK** | NOT NULL | Surrogate key buatan Data Warehouse (bernilai `-1` untuk pelanggan unknown). |
| `customer_id` | `INT(11)` | Natural Key | NOT NULL | ID unik pelanggan dari OLTP (`CustomerID`). |
| `account_number` | `VARCHAR(30)` | Atribut | Boleh NULL | Nomor akun unik identitas pelanggan (contoh: *AW00011000*). |
| `customer_type` | `VARCHAR(20)` | Atribut | Boleh NULL | Klasifikasi jenis pelanggan; bernilai tetap `'Individual'` untuk pesanan online. |
| `customer_name` | `VARCHAR(150)` | Atribut | Boleh NULL | Nama lengkap gabungan dari `FirstName`, `MiddleName`, dan `LastName`. |
| `territory_id` | `INT(11)` | Atribut / FK Sumber | Boleh NULL | ID wilayah tempat tinggal atau registrasi akun pelanggan. |

---

### 2.4. Tabel `dim_territory` (Dimensi Wilayah Penjualan)
* **Tabel Sumber:** `sales_salesterritory`
* **Tipe SCD:** SCD Tipe 1 (Overwrite)
* **Karakteristik:** Merepresentasikan wilayah pemasaran transaksi (*sales territory*), bukan alamat ekspedisi.

| Nama Kolom | Tipe Data | Peran | Aturan NULL | Keterangan / Definisi Bisnis |
|---|---|---|---|---|
| `territory_key` | `INT(11)` | **PK** | NOT NULL | Surrogate key buatan Data Warehouse (bernilai `-1` untuk wilayah unknown). |
| `territory_id` | `INT(11)` | Natural Key | NOT NULL | ID unik wilayah penjualan dari sistem sumber (`TerritoryID`). |
| `territory_name` | `VARCHAR(50)` | Atribut | Boleh NULL | Nama distrik/wilayah penjualan (contoh: *Southwest*, *Australia*, *Canada*). |
| `country_code` | `VARCHAR(3)` | Atribut | Boleh NULL | Kode ISO 2 karakter negara asal wilayah (*US*, *CA*, *AU*, *GB*, *FR*, *DE*). |
| `territory_group` | `VARCHAR(50)` | Atribut | Boleh NULL | Kelompok benua pasar penjualan (*North America*, *Pacific*, *Europe*). |

---

### 2.5. Tabel `dim_promotion` (Dimensi Promosi & Penawaran Khusus)
* **Tabel Sumber:** `sales_specialoffer`
* **Tipe SCD:** SCD Tipe 0 (Tetap/Historis)

| Nama Kolom | Tipe Data | Peran | Aturan NULL | Keterangan / Definisi Bisnis |
|---|---|---|---|---|
| `promotion_key` | `INT(11)` | **PK** | NOT NULL | Surrogate key buatan Data Warehouse (bernilai `-1` untuk promo unknown). |
| `special_offer_id`| `INT(11)` | Natural Key | NOT NULL | ID penawaran khusus dari sumber (`SpecialOfferID`). |
| `description` | `VARCHAR(255)` | Atribut | Boleh NULL | Deskripsi program promosi (contoh: *No Discount*, *Volume Discount 11 to 14*). |
| `discount_pct` | `DECIMAL(10,4)`| Atribut | Boleh NULL | Persentase potongan harga yang dijanjikan (contoh: `0.0200` = 2%). |
| `type` | `VARCHAR(50)` | Atribut | Boleh NULL | Jenis promosi (*No Discount*, *Volume Discount*, *Seasonal Promo*). |
| `category` | `VARCHAR(50)` | Atribut | Boleh NULL | Kategori target penawaran (*No Discount*, *Reseller*, *Customer*). |

---

### 2.6. Tabel `dim_currency` (Dimensi Mata Uang & Kurs)
* **Tabel Sumber:** `sales_currencyrate`
* **Tipe SCD:** SCD Tipe 0 (Historis)
* **Karakteristik:** Menangani catatan kurs valuta asing. Transaksi tanpa referensi kurs (53,73% dari pesanan online) dimapping ke baris `-1` (USD Base).

| Nama Kolom | Tipe Data | Peran | Aturan NULL | Keterangan / Definisi Bisnis |
|---|---|---|---|---|
| `currency_key` | `INT(11)` | **PK** | NOT NULL | Surrogate key buatan Data Warehouse (bernilai `-1` untuk default USD base). |
| `currency_rate_id`| `INT(11)` | Natural Key | NOT NULL | ID catatan konversi kurs dari OLTP (`CurrencyRateID`). |
| `from_currency_code`| `VARCHAR(3)`| Atribut | Boleh NULL | Kode mata uang asal transaksi (default: `'USD'`). |
| `to_currency_code`| `VARCHAR(3)` | Atribut | Boleh NULL | Kode mata uang target pelaporan / pembayaran (*AUD*, *CAD*, *EUR*, *GBP*). |
| `average_rate` | `DECIMAL(19,4)`| Atribut | Boleh NULL | Nilai kurs rata-rata yang berlaku saat tanggal transaksi. |
| `end_of_day_rate` | `DECIMAL(19,4)`| Atribut | Boleh NULL | Nilai kurs penutupan hari yang berlaku saat tanggal transaksi. |

---

### 2.7. Tabel `dim_ship_method` (Dimensi Metode Pengiriman)
* **Tabel Sumber:** `purchasing_shipmethod`
* **Tipe SCD:** SCD Tipe 1 (Overwrite)

| Nama Kolom | Tipe Data | Peran | Aturan NULL | Keterangan / Definisi Bisnis |
|---|---|---|---|---|
| `ship_method_key` | `INT(11)` | **PK** | NOT NULL | Surrogate key buatan Data Warehouse (bernilai `-1` untuk kurir unknown). |
| `ship_method_id` | `INT(11)` | Natural Key | NOT NULL | ID metode pengiriman dari sistem operasional (`ShipMethodID`). |
| `ship_method_name`| `VARCHAR(50)` | Atribut | Boleh NULL | Nama layanan kurir/ekspedisi (contoh: *XRX - AIR*, *CARGO TRANSPORT 5*). |
| `ship_base` | `DECIMAL(19,4)`| Atribut | Boleh NULL | Biaya dasar pengiriman pesanan (*base shipping cost*). |
| `ship_rate` | `DECIMAL(19,4)`| Atribut | Boleh NULL | Tarif biaya kirim tambahan per satuan berat pesanan. |

---

## 3. Kamus Data Tabel Fakta Utama (`fact_online_sales`)

* **Tipe Fakta:** *Transaction Fact Table*
* **Grain:** Satu baris merepresentasikan satu baris detail produk (`SalesOrderDetailID`) dalam satu pesanan penjualan online.
* **Tabel Sumber:** `sales_salesorderdetail` INNER JOIN `sales_salesorderheader` (Filter: `OnlineOrderFlag = 1`).
* **Jumlah Baris Terverifikasi:** 60.398 baris fakta (unik dan tervalidasi).

| Nama Kolom | Tipe Data | Peran | Aturan NULL | Foreign Key / Referensi Dimensi | Keterangan / Definisi Bisnis |
|---|---|---|---|---|---|
| `sales_detail_key` | `INT(11)` | **PK** | NOT NULL | - | Kunci utama unik fakta, berasal dari `SalesOrderDetailID`. |
| `sales_order_id` | `INT(11)` | Degenerate Dimension | NOT NULL | - | Nomor identitas invoice pesanan, digunakan untuk `COUNT(DISTINCT)`. |
| `tanggal_key` | `INT(11)` | **FK** | NOT NULL | `dim_date.tanggal_key` | Kunci tanggal pemesanan (`OrderDate`). |
| `product_key` | `INT(11)` | **FK** | NOT NULL | `dim_product.product_key` | Kunci produk yang dibeli. |
| `customer_key` | `INT(11)` | **FK** | NOT NULL | `dim_customer.customer_key` | Kunci pelanggan pembeli. |
| `territory_key` | `INT(11)` | **FK** | NOT NULL | `dim_territory.territory_key` | Kunci wilayah penjualan transaksi. |
| `promotion_key` | `INT(11)` | **FK** | NOT NULL | `dim_promotion.promotion_key` | Kunci program promosi/penawaran yang diterapkan. |
| `currency_key` | `INT(11)` | **FK** | NOT NULL | `dim_currency.currency_key` | Kunci mata uang dan referensi kurs yang digunakan. |
| `ship_method_key` | `INT(11)` | **FK** | NOT NULL | `dim_ship_method.ship_method_key`| Kunci metode kurir pengiriman pesanan. |
| `order_qty` | `INT(11)` | Measure (Aditif) | NOT NULL | - | Kuantitas unit produk yang dibeli (seluruh detail bernilai 1). |
| `unit_price` | `DECIMAL(19,4)` | Measure (Non-Aditif)| NOT NULL | - | Harga satuan resmi per unit produk pada saat transaksi. |
| `unit_price_discount`| `DECIMAL(19,4)`| Measure (Non-Aditif)| NOT NULL | - | Nilai/rasio diskon harga per unit produk (0.0000 s.d. 1.0000). |
| `line_total` | `DECIMAL(19,4)` | Measure (Aditif) | NOT NULL | - | Total nilai nominal transaksi baris (`OrderQty × UnitPrice × (1 - Diskon)`). Target: **$29.358.677,22**. |

---

## 4. Daftar Tabel Staging (Staging Layer)

Tabel staging adalah lapisan penampungan sementara (*landing zone*) yang digunakan dalam arsitektur integrasi data ETL (baik melalui Pentaho PDI maupun pipeline n8n) untuk mengekstraksi data mentah dari OLTP `adventureworks` sebelum dibersihkan dan dimasukkan ke tabel dimensi/fakta di `adventureworks_dw`.

### 4.1. Tabel `stg_sales_order_header`
* **Tabel Sumber:** `sales_salesorderheader`
* **Tujuan:** Data mentah header penjualan online yang lolos filter awal `OnlineOrderFlag = 1`.

| Nama Kolom | Tipe Data | Aturan NULL | Keterangan |
|---|---|---|---|
| `SalesOrderID` | `INT(11)` | NOT NULL | Primary key transaksi tingkat pesanan. |
| `OrderDate` | `DATETIME` | NOT NULL | Waktu pesanan dibuat. |
| `Status` | `TINYINT(3)` | NOT NULL | Kode status pesanan operasional (1–6). |
| `OnlineOrderFlag` | `TINYINT(1)` | NOT NULL | Filter transaksi online (`1`). |
| `CustomerID` | `INT(11)` | NOT NULL | Natural key pelanggan. |
| `TerritoryID` | `INT(11)` | Boleh NULL | Natural key wilayah penjualan. |
| `CurrencyRateID` | `INT(11)` | Boleh NULL | Referensi catatan kurs (boleh NULL jika USD). |
| `ShipMethodID` | `INT(11)` | NOT NULL | Natural key metode pengiriman. |
| `SubTotal` | `DECIMAL(19,4)` | NOT NULL | Subtotal akumulasi nilai pesanan header. |

### 4.2. Tabel `stg_sales_order_detail`
* **Tabel Sumber:** `sales_salesorderdetail`
* **Tujuan:** Data mentah detail pesanan produk per baris transaksi.

| Nama Kolom | Tipe Data | Aturan NULL | Keterangan |
|---|---|---|---|
| `SalesOrderID` | `INT(11)` | NOT NULL | ID pesanan relasi ke header. |
| `SalesOrderDetailID` | `INT(11)` | NOT NULL | Primary key detail item pesanan (grain fakta). |
| `OrderQty` | `SMALLINT(6)` | NOT NULL | Jumlah produk yang dipesan. |
| `ProductID` | `INT(11)` | NOT NULL | Natural key produk yang dibeli. |
| `SpecialOfferID` | `INT(11)` | NOT NULL | Natural key promosi/penawaran khusus. |
| `UnitPrice` | `DECIMAL(19,4)` | NOT NULL | Harga satuan barang. |
| `UnitPriceDiscount` | `DECIMAL(19,4)` | NOT NULL | Potongan harga satuan. |
| `LineTotal` | `DECIMAL(19,4)` | NOT NULL | Total nilai baris transaksi. |

### 4.3. Tabel `stg_product_catalog`
* **Tabel Sumber:** `production_product` JOIN `production_productsubcategory` JOIN `production_productcategory`
* **Tujuan:** Penampungan master katalog produk sebelum diproses ke `dim_product`.

| Nama Kolom | Tipe Data | Aturan NULL | Keterangan |
|---|---|---|---|
| `ProductID` | `INT(11)` | NOT NULL | Business key produk. |
| `ProductName` | `VARCHAR(100)` | NOT NULL | Nama produk sumber. |
| `ProductNumber` | `VARCHAR(50)` | NOT NULL | SKU produk sumber. |
| `SubcategoryName` | `VARCHAR(100)` | Boleh NULL | Nama subkategori hasil join. |
| `CategoryName` | `VARCHAR(100)` | Boleh NULL | Nama kategori hasil join. |

### 4.4. Tabel `stg_customer_person`
* **Tabel Sumber:** `sales_customer` JOIN `person_person`
* **Tujuan:** Penampungan nama dan data pelanggan sebelum diproses ke `dim_customer`.

| Nama Kolom | Tipe Data | Aturan NULL | Keterangan |
|---|---|---|---|
| `CustomerID` | `INT(11)` | NOT NULL | Business key pelanggan. |
| `AccountNumber` | `VARCHAR(30)` | Boleh NULL | Nomor rekening/akun nasabah. |
| `CustomerName` | `VARCHAR(150)` | Boleh NULL | Nama lengkap hasil penggabungan string (FirstName + MiddleName + LastName). |
| `TerritoryID` | `INT(11)` | Boleh NULL | Wilayah penjualan pelanggan. |

