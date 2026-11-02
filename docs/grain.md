# GRAIN FACT ONLINE SALES
## AdventureWorks Online Sales Data Warehouse

### 1. Pengertian Grain

Grain merupakan tingkat detail data yang menentukan arti satu baris pada tabel fakta (Fact Table). Penetapan grain dilakukan sebelum menentukan dimensi dan measures agar tidak terjadi duplikasi atau kesalahan perhitungan dalam analisis penjualan.

Pada proyek Data Warehouse AdventureWorks ini, grain ditetapkan berdasarkan proses bisnis Penjualan Online (*Online Sales*).

### 2. Pernyataan Grain

**Satu baris pada tabel `fact_online_sales` merepresentasikan satu detail produk dalam satu pesanan penjualan online (SalesOrderDetailID), yang berasal dari transaksi dengan `OnlineOrderFlag = 1` pada database AdventureWorks.**

Dengan demikian, setiap baris fakta merepresentasikan satu item detail pesanan, bukan satu keseluruhan pesanan.

### 3. Dasar Penetapan Grain

Penetapan grain didasarkan pada tabel sumber berikut:

| Tabel Sumber | Fungsi |
|---|---|
| `sales_salesorderheader` | Menyimpan informasi utama pesanan penjualan. |
| `sales_salesorderdetail` | Menyimpan rincian produk dalam setiap pesanan. |

Hubungan kedua tabel menggunakan atribut `SalesOrderID`.

Filter transaksi yang digunakan:

```sql
WHERE OnlineOrderFlag = 1
```

Tabel `sales_salesorderdetail` dipilih sebagai dasar grain karena setiap barisnya merepresentasikan satu detail produk dalam pesanan.

### 4. Hasil Validasi Grain

Berdasarkan hasil profiling database AdventureWorks menggunakan MySQL XAMPP, diperoleh hasil berikut:

| Indikator | Hasil |
|---|---:|
| Total detail penjualan online | 60.398 |
| Detail ID unik | 60.398 |
| Jumlah pesanan online | 27.659 |
| Produk unik terjual | 130 |
| Total unit terjual | 60.398 |
| Total nilai penjualan | 29.358.677,22 |

Hasil validasi menunjukkan bahwa jumlah keseluruhan baris detail sama dengan jumlah `SalesOrderDetailID` unik.

Artinya, setiap detail transaksi memiliki identitas yang unik dan dapat digunakan sebagai identitas sumber pada tabel fakta.

### 5. Validasi Distribusi OrderQty

Hasil profiling terhadap kolom `OrderQty` menunjukkan:

| OrderQty | Jumlah Baris |
|---:|---:|
| 1 | 60.398 |
| **Total** | **60.398** |

Seluruh detail transaksi online memiliki kuantitas pembelian sebesar satu unit.

Kondisi tersebut merupakan karakteristik data yang ditemukan pada hasil profiling, bukan ketentuan grain. Oleh karena itu, kolom `OrderQty` tetap dipertahankan sebagai measure agar analisis kuantitas tetap dapat dilakukan.

### 6. Penentuan Fact Table dan Measures

Nama tabel fakta yang digunakan adalah `fact_online_sales`.

Measures yang direncanakan:

| Measure | Kolom Sumber | Fungsi |
|---|---|---|
| Quantity Sold | `OrderQty` | Menghitung total unit produk terjual. |
| Unit Price | `UnitPrice` | Menyimpan harga satuan produk. |
| Unit Price Discount | `UnitPriceDiscount` | Menyimpan nilai atau proporsi diskon harga satuan. |
| Sales Amount | `LineTotal` | Menghitung total nilai penjualan detail setelah diskon. |

Catatan: `UnitPrice` dan `UnitPriceDiscount` merupakan nilai pada tingkat detail, sehingga tidak boleh langsung dijumlahkan sebagai total penjualan. `LineTotal` digunakan sebagai measure utama nilai penjualan.

### 7. Hubungan Grain dengan Tujuh Dimensi

Berdasarkan bus matrix resmi tim, tabel fakta menggunakan tujuh dimensi berikut:

| No. | Dimensi | Foreign Key yang Direncanakan | Sumber Atribut |
|---|---|---|---|
| 1 | `dim_date` | `date_key` | `OrderDate` |
| 2 | `dim_product` | `product_key` | `ProductID` |
| 3 | `dim_customer` | `customer_key` | `CustomerID` |
| 4 | `dim_territory` | `territory_key` | `TerritoryID` |
| 5 | `dim_promotion` | `promotion_key` | `SpecialOfferID` |
| 6 | `dim_currency` | `currency_key` | `CurrencyRateID` |
| 7 | `dim_ship_method` | `ship_method_key` | `ShipMethodID` |

Setiap baris fakta akan memiliki hubungan dengan tujuh dimensi tersebut.

Khusus `CurrencyRateID`, terdapat 14.860 pesanan online tanpa nilai kurs dari total 27.659 pesanan. Kondisi ini harus ditangani menggunakan anggota dimensi khusus untuk nilai tidak tersedia (*Unknown/Not Applicable*), bukan dengan menghapus transaksi.

### 8. Identitas Baris Fakta

Kolom `SalesOrderDetailID` dipertahankan sebagai identitas transaksi dari database sumber untuk keperluan pelacakan dan validasi.

Rancangan identitas tabel fakta:

| Kolom | Keterangan |
|---|---|
| `fact_online_sales_key` | Primary Key tabel fakta (surrogate key). |
| `SalesOrderDetailID` | Identitas detail transaksi dari sumber. |
| `SalesOrderID` | Identitas pesanan sumber untuk pelacakan. |
| Foreign keys tujuh dimensi | Penghubung tabel fakta dengan tabel dimensi. |
| Measures | Nilai kuantitas, harga, diskon, dan penjualan. |

`SalesOrderDetailID` harus tetap unik dalam hasil pemuatan data.

### 9. Kesimpulan

Berdasarkan hasil profiling dan validasi, grain tabel `fact_online_sales` ditetapkan pada tingkat satu baris detail produk dalam satu pesanan penjualan online.

Hasil validasi menunjukkan 60.398 baris detail dengan 60.398 ID detail unik, sehingga grain yang ditetapkan sesuai dengan struktur data sumber.

Penetapan grain ini menjadi dasar dalam perancangan Star Schema versi 1 dan pengembangan proses ETL menggunakan Pentaho Data Integration.
