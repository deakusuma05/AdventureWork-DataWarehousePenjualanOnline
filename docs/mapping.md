# Source-to-Target Mapping — AdventureWorks Online Sales DW

**Versi:** 1.0 (rancangan Pekan 10)  
**Database sumber:** AdventureWorks pada MySQL/XAMPP  
**Database target:** `adventureworks_dw`  
**Proses bisnis:** Penjualan Online (`OnlineOrderFlag = 1`)  
**Grain fakta:** Satu baris pada `fact_online_sales` merepresentasikan satu baris detail produk (`SalesOrderDetailID`) dalam satu pesanan penjualan online.

> **Catatan penamaan sumber:** Nama di kolom sumber menggunakan nama logis skema AdventureWorks (misalnya `Sales.SalesOrderHeader`). Pada dump MySQL, nama fisiknya dapat menjadi `sales_salesorderheader` atau bentuk lain. Cocokkan nama fisik melalui phpMyAdmin sebelum membuat transformasi Pentaho. Jangan mengubah database sumber.

## 1. Strategi SCD

| Target | SCD | Atribut yang dipantau / kebijakan |
|---|---|---|
| `dim_date` | Type 0 | Seluruh atribut kalender dipertahankan; tidak diperbarui pada load rutin. |
| `dim_product` | **Type 2** | Pantau `product_name`, `product_number`, `subcategory_name`, `category_name`. Perubahan membuat versi produk baru dengan `product_key` baru; `product_id` tetap. |
| `dim_customer` | Type 1 | `account_number`, `customer_type`, `customer_name`, `territory_id` diperbarui dengan overwrite jika berubah. |
| `dim_territory` | Type 1 | `territory_name`, `country_code`, `territory_group` diperbarui dengan overwrite. |
| `dim_promotion` | Type 0 | Deskripsi dan atribut promosi historis dipertahankan; koreksi harus melalui prosedur terkendali. |
| `dim_currency` | Type 0 | Kurs historis (`average_rate`, `end_of_day_rate`) dipertahankan sesuai `currency_rate_id`. |
| `dim_ship_method` | Type 1 | Nama metode, biaya dasar, dan tarif diperbarui dengan overwrite. |

### Catatan implementasi Type 2 pada `dim_product`

Struktur standar yang terlihat pada Star Schema V2 adalah `product_key`, `product_id`, `product_name`, `product_number`, `subcategory_name`, dan `category_name`. Struktur ini belum menampilkan kolom masa berlaku versi.

Karena keputusan tim adalah mempertahankan struktur standar, **jangan menambahkan kolom ke tabel standar tanpa persetujuan dosen/sponsor**. Sebelum implementasi Type 2, tim harus menyepakati salah satu mekanisme berikut:

1. Persetujuan untuk menambahkan metadata versi ke `dim_product` (misalnya `effective_start_date`, `effective_end_date`, `is_current`); atau
2. Persetujuan untuk menyimpan metadata versi pada tabel pendamping yang terhubung ke `product_key`, dengan aturan lookup versi yang terdokumentasi.

Tanpa metadata versi dan aturan lookup tersebut, Type 2 belum dapat diimplementasikan secara benar. `product_key` harus berbeda untuk setiap versi, sedangkan fakta harus memakai versi produk yang berlaku pada tanggal transaksi. Jika tidak ada snapshot historis sumber, perubahan sebelum ETL pertama tidak boleh diklaim sebagai riwayat yang diketahui.

## 2. Source-to-target mapping

### Target: `dim_date` (SCD Type 0)

**Sumber utama:** `Sales.SalesOrderHeader.OrderDate` (tanggal kalender dibentuk dari rentang tanggal transaksi).  
**Catatan:** tabel tanggal merupakan dimensi hasil derivasi, bukan salinan satu tabel sumber.

| Kolom target | Tipe target | Tabel.kolom sumber | Transformasi | Aturan NULL |
|---|---|---|---|---|
| `tanggal_key` | INT | `Sales.SalesOrderHeader.OrderDate` | Format tanggal menjadi `YYYYMMDD` | Tidak boleh NULL; gunakan `-1` hanya untuk tanggal tidak diketahui jika kebijakan DW mengizinkan |
| `tanggal` | DATE | `Sales.SalesOrderHeader.OrderDate` | CAST/DATE dari OrderDate | Tidak boleh NULL untuk transaksi valid |
| `tahun` | INT | `OrderDate` | YEAR(OrderDate) | Tidak boleh NULL |
| `semester` | INT | `OrderDate` | Jika bulan <= 6 maka 1, selain itu 2 | Tidak boleh NULL |
| `kuartal` | INT | `OrderDate` | QUARTER(OrderDate) | Tidak boleh NULL |
| `bulan` | INT | `OrderDate` | MONTH(OrderDate) | Tidak boleh NULL |
| `nama_bulan` | VARCHAR(20) | `OrderDate` | Nama bulan sesuai bahasa/standar tim | Tidak boleh NULL |
| `minggu_dalam_tahun` | INT | `OrderDate` | Nomor minggu sesuai konvensi kalender yang disepakati | Tidak boleh NULL |
| `tanggal_dalam_bulan` | INT | `OrderDate` | DAYOFMONTH(OrderDate) | Tidak boleh NULL |
| `hari_dalam_minggu` | INT | `OrderDate` | Nomor hari sesuai konvensi kalender yang disepakati | Tidak boleh NULL |
| `nama_hari` | VARCHAR(20) | `OrderDate` | Nama hari sesuai bahasa/standar tim | Tidak boleh NULL |
| `is_akhir_pekan` | TINYINT(1) | `OrderDate` | 1 untuk Sabtu/Minggu, selain itu 0 | Tidak boleh NULL |

### Target: `dim_product` (SCD Type 2)

**Sumber utama:** `Production.Product`; JOIN `Production.ProductSubcategory`; JOIN `Production.ProductCategory`.

| Kolom target | Tipe target | Tabel.kolom sumber | Transformasi | Aturan NULL |
|---|---|---|---|---|
| `product_key` | INT | - | Surrogate key DW; key baru untuk setiap versi produk | Tidak boleh NULL |
| `product_id` | INT | `Production.Product.ProductID` | Salin sebagai natural/business key | Tidak boleh NULL |
| `product_name` | VARCHAR(100) | `Production.Product.Name` | Salin nama produk | Ikuti aturan sumber; jika NULL, tandai dan investigasi |
| `product_number` | VARCHAR(50) | `Production.Product.ProductNumber` | Salin nomor produk | Ikuti aturan sumber; jika NULL, tandai dan investigasi |
| `subcategory_name` | VARCHAR(100) | `Production.ProductSubcategory.Name` melalui `ProductSubcategoryID` | LEFT JOIN dari Product ke ProductSubcategory | Jika tidak memiliki subkategori, gunakan nilai Unknown/Not Applicable sesuai kebijakan |
| `category_name` | VARCHAR(100) | `Production.ProductCategory.Name` melalui ProductSubcategory | LEFT JOIN Product → ProductSubcategory → ProductCategory | Jika tidak memiliki kategori, gunakan Unknown/Not Applicable sesuai kebijakan |

**Aturan Type 2:** bandingkan empat atribut deskriptif untuk `product_id` yang sama. Jika berubah, buat versi baru dengan surrogate key baru. Fakta mencari `product_key` berdasarkan `product_id` dan tanggal transaksi. Metadata versi belum masuk ke struktur standar sampai disetujui.

### Target: `dim_customer` (SCD Type 1)

**Sumber utama:** `Sales.Customer`; JOIN `Person.Person` dan/atau `Sales.Store` untuk nama pelanggan.

| Kolom target | Tipe target | Tabel.kolom sumber | Transformasi | Aturan NULL |
|---|---|---|---|---|
| `customer_key` | INT | - | Surrogate key DW | Tidak boleh NULL |
| `customer_id` | INT | `Sales.Customer.CustomerID` | Salin sebagai natural key | Tidak boleh NULL |
| `account_number` | VARCHAR(30) | `Sales.Customer.AccountNumber` | Salin | Jika NULL, gunakan kebijakan Unknown/NULL yang disepakati |
| `customer_type` | VARCHAR(20) | `Sales.Customer.PersonID`, `Sales.Customer.StoreID` | Derivasi tipe pelanggan berdasarkan sumber Person/Store; dokumentasikan aturan klasifikasi | Jika tidak dapat ditentukan, `Unknown` |
| `customer_name` | VARCHAR(150) | `Person.Person` atau `Sales.Store` | JOIN berdasarkan PersonID atau StoreID; bentuk nama sesuai aturan tim | Jika tidak tersedia, `Unknown` |
| `territory_id` | INT | `Sales.Customer.TerritoryID` | Salin business key wilayah | Jika NULL, pertahankan NULL untuk lookup Unknown di dimensi wilayah |

**Aturan Type 1:** perubahan atribut menimpa nilai lama; tidak menyimpan versi historis. Pastikan sumber nama pelanggan (Person atau Store) sesuai tipe customer.

### Target: `dim_territory` (SCD Type 1)

**Sumber utama:** `Sales.SalesTerritory`.

| Kolom target | Tipe target | Tabel.kolom sumber | Transformasi | Aturan NULL |
|---|---|---|---|---|
| `territory_key` | INT | - | Surrogate key DW | Tidak boleh NULL |
| `territory_id` | INT | `Sales.SalesTerritory.TerritoryID` | Salin sebagai natural key | Tidak boleh NULL |
| `territory_name` | VARCHAR(50) | `Sales.SalesTerritory.Name` | Salin | Jika NULL, tandai dan investigasi |
| `country_code` | VARCHAR(3) | `Sales.SalesTerritory.CountryRegionCode` | Salin; sesuaikan panjang/kode standar jika diperlukan | Jika NULL, gunakan kebijakan Unknown |
| `territory_group` | VARCHAR(50) | `Sales.SalesTerritory.[Group]` | Salin; `[Group]` mungkin perlu delimiter karena kata GROUP adalah keyword SQL | Jika NULL, gunakan kebijakan Unknown |

**Aturan Type 1:** perubahan nama, kode negara, atau grup wilayah menimpa nilai lama.

### Target: `dim_promotion` (SCD Type 0)

**Sumber utama:** `Sales.SpecialOffer`.

| Kolom target | Tipe target | Tabel.kolom sumber | Transformasi | Aturan NULL |
|---|---|---|---|---|
| `promotion_key` | INT | - | Surrogate key DW | Tidak boleh NULL |
| `special_offer_id` | INT | `Sales.SpecialOffer.SpecialOfferID` | Salin sebagai natural key | Tidak boleh NULL |
| `description` | VARCHAR(255) | `Sales.SpecialOffer.Description` | Salin | Jika NULL, gunakan kebijakan Unknown |
| `discount_pct` | DECIMAL(10,4) | `Sales.SpecialOffer.DiscountPct` | Salin; pastikan skala target cukup | Jika NULL, investigasi; jangan otomatis dianggap 0 tanpa aturan |
| `type` | VARCHAR(50) | `Sales.SpecialOffer.Type` | Salin | Jika NULL, gunakan kebijakan Unknown |
| `category` | VARCHAR(50) | `Sales.SpecialOffer.Category` | Salin | Jika NULL, gunakan kebijakan Unknown |

**Aturan Type 0:** atribut yang telah dimuat dipertahankan. Jika sumber mengoreksi definisi promosi, koreksi dilakukan dengan persetujuan dan dicatat.

### Target: `dim_currency` (SCD Type 0)

**Sumber utama:** `Sales.CurrencyRate`; referensi kode dari `Sales.Currency` bila dibutuhkan.

| Kolom target | Tipe target | Tabel.kolom sumber | Transformasi | Aturan NULL |
|---|---|---|---|---|
| `currency_key` | INT | - | Surrogate key DW | Tidak boleh NULL |
| `currency_rate_id` | INT | `Sales.CurrencyRate.CurrencyRateID` | Salin sebagai natural key kurs | Untuk baris Unknown, gunakan key khusus sesuai kebijakan DW |
| `from_currency_code` | VARCHAR(3) | `Sales.CurrencyRate.FromCurrencyCode` | Salin kode mata uang | Jika NULL, tandai dan investigasi |
| `to_currency_code` | VARCHAR(3) | `Sales.CurrencyRate.ToCurrencyCode` | Salin kode mata uang | Jika NULL, tandai dan investigasi |
| `average_rate` | DECIMAL(19,4) | `Sales.CurrencyRate.AverageRate` | Salin dengan presisi sesuai sumber | Jika NULL, pertahankan sebagai NULL/Unknown; jangan isi 0 tanpa aturan |
| `end_of_day_rate` | DECIMAL(19,4) | `Sales.CurrencyRate.EndOfDayRate` | Salin dengan presisi sesuai sumber | Jika NULL, pertahankan sebagai NULL/Unknown; jangan isi 0 tanpa aturan |

**Kebijakan fakta:** profiling menemukan 14.860 dari 27.659 pesanan online tidak memiliki `CurrencyRateID`. Baris fakta tersebut harus menunjuk ke anggota Unknown pada `dim_currency` (misalnya `currency_key = -1` jika disepakati), bukan dipasangkan dengan kurs rekaan. Pesanan yang memiliki `CurrencyRateID` menggunakan lookup ke baris kurs yang sesuai.

### Target: `dim_ship_method` (SCD Type 1)

**Sumber utama:** `Purchasing.ShipMethod`.

| Kolom target | Tipe target | Tabel.kolom sumber | Transformasi | Aturan NULL |
|---|---|---|---|---|
| `ship_method_key` | INT | - | Surrogate key DW | Tidak boleh NULL |
| `ship_method_id` | INT | `Purchasing.ShipMethod.ShipMethodID` | Salin sebagai natural key | Tidak boleh NULL |
| `ship_method_name` | VARCHAR(50) | `Purchasing.ShipMethod.Name` | Salin | Jika NULL, tandai dan investigasi |
| `ship_base` | DECIMAL(19,4) | `Purchasing.ShipMethod.ShipBase` | Salin dengan presisi sesuai sumber | Jika NULL, investigasi; jangan otomatis 0 |
| `ship_rate` | DECIMAL(19,4) | `Purchasing.ShipMethod.ShipRate` | Salin dengan presisi sesuai sumber | Jika NULL, investigasi; jangan otomatis 0 |

**Aturan Type 1:** perubahan nama atau tarif menimpa nilai sebelumnya.

### Target: `fact_online_sales` (grain: satu baris detail produk dalam satu pesanan online)

**Sumber utama:** `Sales.SalesOrderDetail`; JOIN `Sales.SalesOrderHeader` dengan `SalesOrderID`. Lookup ke seluruh dimensi berdasarkan business key dan aturan versi yang berlaku.

| Kolom target | Tipe target | Tabel.kolom sumber | Transformasi | Aturan NULL |
|---|---|---|---|---|
| `sales_detail_key` | INT | `Sales.SalesOrderDetail.SalesOrderDetailID` | Salin sebagai identitas detail sumber atau gunakan strategi key yang disetujui | Tidak boleh NULL |
| `sales_order_id` | INT | `Sales.SalesOrderDetail.SalesOrderID` | Salin ID pesanan | Tidak boleh NULL |
| `product_key` | INT | `Sales.SalesOrderDetail.ProductID` | Lookup `dim_product` berdasarkan `product_id`; untuk Type 2 pilih versi yang berlaku pada `SalesOrderHeader.OrderDate` | Jika tidak ditemukan, gunakan Unknown dan catat exception |
| `customer_key` | INT | `Sales.SalesOrderHeader.CustomerID` | Lookup `dim_customer` berdasarkan `customer_id` | Jika tidak ditemukan, gunakan Unknown dan catat exception |
| `territory_key` | INT | `Sales.SalesOrderHeader.TerritoryID` | Lookup `dim_territory` berdasarkan `territory_id` | Jika NULL/tidak ditemukan, gunakan Unknown |
| `promotion_key` | INT | `Sales.SalesOrderDetail.SpecialOfferID` | Lookup `dim_promotion` berdasarkan `special_offer_id` | Jika tidak ditemukan, gunakan Unknown |
| `currency_key` | INT | `Sales.SalesOrderHeader.CurrencyRateID` | Lookup `dim_currency` berdasarkan `currency_rate_id` | Jika NULL, gunakan anggota Unknown; profiling menunjukkan 14.860 pesanan tanpa CurrencyRateID |
| `ship_method_key` | INT | `Sales.SalesOrderHeader.ShipMethodID` | Lookup `dim_ship_method` berdasarkan `ship_method_id` | Jika tidak ditemukan, gunakan Unknown |
| `order_qty` | INT | `Sales.SalesOrderDetail.OrderQty` | Salin kuantitas | Tidak boleh NULL; validasi nilai positif |
| `unit_price` | DECIMAL(19,4) | `Sales.SalesOrderDetail.UnitPrice` | Salin harga satuan | Tidak boleh NULL; validasi |
| `unit_price_discount` | DECIMAL(19,4) | `Sales.SalesOrderDetail.UnitPriceDiscount` | Salin diskon per unit (rasio sesuai definisi sumber) | Jika NULL, investigasi; jangan otomatis 0 tanpa kebijakan |
| `line_total` | DECIMAL(19,4) | `Sales.SalesOrderDetail.LineTotal` | Salin nilai total baris dari sumber; jangan hitung ulang kecuali untuk rekonsiliasi | Tidak boleh NULL; profiling sebelumnya menunjukkan 0 NULL |

**Filter ekstraksi:** `Sales.SalesOrderHeader.OnlineOrderFlag = 1`.

**Join utama:** `Sales.SalesOrderHeader.SalesOrderID = Sales.SalesOrderDetail.SalesOrderID`.

**Validasi yang sudah dilaporkan tim:** 60.398 baris detail online; 27.659 pesanan online; 130 produk unik; `LineTotal` tidak NULL. Nilai tersebut menjadi baseline rekonsiliasi, bukan angka yang harus dipaksakan jika data sumber berubah.

## 3. Urutan load

1. **Extract** tabel sumber yang diperlukan dari AdventureWorks ke staging tanpa mengubah database sumber.
2. **Validasi staging**: tipe data, duplikasi business key, NULL, jumlah baris, dan relasi.
3. **Load `dim_date`** dari rentang `OrderDate` transaksi.
4. **Load `dim_territory`**.
5. **Load `dim_customer`** dengan SCD Type 1.
6. **Load `dim_product`** dengan mekanisme SCD Type 2 yang sudah disetujui dan metadata versi yang tersedia.
7. **Load `dim_promotion`** dengan kebijakan Type 0.
8. **Load `dim_currency`** dengan kebijakan Type 0; siapkan anggota Unknown untuk pesanan tanpa `CurrencyRateID`.
9. **Load `dim_ship_method`** dengan SCD Type 1.
10. **Load `fact_online_sales`** setelah seluruh surrogate key dimensi dapat di-lookup.
11. **Rekonsiliasi fakta**: jumlah detail, jumlah pesanan, jumlah produk, total unit, total `LineTotal`, serta jumlah FK Unknown.

> Urutan antar-dimensi dapat disesuaikan berdasarkan dependensi ETL. Semua dimensi harus selesai/siap di-lookup sebelum fakta dimuat. Jika menggunakan tabel pendamping untuk metadata Type 2, muat tabel tersebut bersama proses `dim_product`.

## 4. Catatan dan keputusan yang masih harus dikonfirmasi

- Pastikan nama fisik tabel MySQL sesuai dump yang diimpor.
- Konfirmasi apakah `dim_product` boleh ditambah metadata Type 2 atau harus memakai tabel pendamping.
- Konfirmasi nilai surrogate key Unknown (misalnya `-1`) dan pastikan tipe/constraint PK mendukungnya.
- Pastikan sumber `customer_name` untuk pelanggan individu dan toko: `Person.Person` atau `Sales.Store`.
- Pastikan definisi `customer_type` disetujui tim.
- Pastikan definisi minggu dalam `dim_date` mengikuti standar dosen.
- Pastikan presisi `DECIMAL` target tidak mengurangi presisi sumber.
- `currency_rate_id` NULL pada header tidak boleh dianggap kurs nol.
- Jangan mengubah isi database AdventureWorks sumber.

## 5. Validasi sebelum implementasi Pentaho

- [ ] Semua kolom target dimensi dan fakta sudah mempunyai sumber/aturan derivasi.
- [ ] Nama tabel/kolom fisik MySQL sudah diverifikasi di phpMyAdmin.
- [ ] Aturan JOIN dan business key sudah diuji.
- [ ] Aturan NULL/Unknown sudah disepakati.
- [ ] Mekanisme metadata SCD Type 2 produk sudah disetujui.
- [ ] Urutan load disetujui Data Modeler dan ETL Developer.
- [ ] Hasil load fakta direkonsiliasi dengan baseline profiling.
