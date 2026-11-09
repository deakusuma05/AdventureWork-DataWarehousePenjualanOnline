# Strategi Slowly Changing Dimension (SCD)
**Proyek:** AdventureWorks Online Sales Data Warehouse  
**Versi:** Star Schema V2 — rancangan Pekan 10

## 1. Tujuan
Strategi SCD mengatur bagaimana perubahan atribut pada tabel dimensi ditangani agar konsistensi data dan kebutuhan analisis historis tetap terjaga.

## 2. Keputusan strategi SCD

| Dimensi | SCD | Atribut/kebijakan | Alasan |
|---|---|---|---|
| `dim_date` | Type 0 | Seluruh atribut kalender | Atribut kalender bersifat tetap |
| `dim_product` | **Type 2** | `product_name`, `product_number`, `subcategory_name`, `category_name` | Menyimpan versi atribut produk dari waktu ke waktu |
| `dim_customer` | Type 1 | `account_number`, `customer_type`, `customer_name`, `territory_id` | Koreksi/perubahan informasi pelanggan menimpa nilai lama |
| `dim_territory` | Type 1 | `territory_name`, `country_code`, `territory_group` | Perubahan deskriptif wilayah diperbarui |
| `dim_promotion` | Type 0 | `description`, `discount_pct`, `type`, `category` | Definisi promosi historis dipertahankan |
| `dim_currency` | Type 0 | `from_currency_code`, `to_currency_code`, `average_rate`, `end_of_day_rate` | Nilai kurs historis dipertahankan |
| `dim_ship_method` | Type 1 | `ship_method_name`, `ship_base`, `ship_rate` | Koreksi nama/tarif menimpa nilai lama |

## 3. Rincian implementasi

### 3.1 SCD Type 0
Diterapkan pada `dim_date`, `dim_promotion`, dan `dim_currency`. Pada proses load rutin, atribut yang sudah dimuat tidak ditimpa. Perubahan atau koreksi sumber harus melalui prosedur koreksi yang disetujui dan dicatat.

### 3.2 SCD Type 1
Diterapkan pada `dim_customer`, `dim_territory`, dan `dim_ship_method`. Jika atribut yang dipantau berubah, nilai pada baris dimensi yang sama diperbarui (overwrite). Tidak dibuat versi historis baru.

### 3.3 SCD Type 2 — `dim_product`
Diterapkan pada `dim_product`. `product_id` berperan sebagai natural/business key, sedangkan `product_key` adalah surrogate key yang berbeda untuk setiap versi produk. Perubahan pada salah satu atribut yang dipantau menyebabkan versi baru dibuat. Baris fakta harus menggunakan `product_key` dari versi produk yang berlaku pada tanggal transaksi.

Atribut yang dipantau:
- `product_name`
- `product_number`
- `subcategory_name`
- `category_name`

## 4. Batasan struktur standar dan keputusan yang diperlukan

Struktur `dim_product` pada Star Schema V2 saat ini hanya memperlihatkan:
- `product_key`
- `product_id`
- `product_name`
- `product_number`
- `subcategory_name`
- `category_name`

Struktur tersebut belum menyediakan metadata masa berlaku versi. Implementasi Type 2 membutuhkan cara untuk mengetahui kapan suatu versi mulai/berakhir dan versi mana yang berlaku saat ini.

**Karena tim memilih mempertahankan struktur standar dosen, jangan menambahkan kolom metadata ke `dim_product` sebelum memperoleh persetujuan.** Sebelum implementasi ETL, Data Modeler dan sponsor/dosen perlu menyetujui salah satu pilihan:

1. Menambahkan `effective_start_date`, `effective_end_date`, dan `is_current` ke `dim_product`; atau
2. Menggunakan tabel pendamping untuk metadata versi yang terhubung melalui `product_key`, disertai aturan lookup versi berdasarkan tanggal transaksi.

Jika kedua mekanisme tersebut belum diputuskan, Type 2 baru merupakan keputusan desain dan belum siap dieksekusi. Jangan mengklaim riwayat perubahan sebelum ETL pertama tersedia apabila snapshot historis sumber tidak ada.

## 5. Dampak pada pemuatan fakta

Saat memuat `fact_online_sales`, proses ETL mengambil `product_id` dari `Sales.SalesOrderDetail`, kemudian mencari versi `dim_product` yang berlaku pada `Sales.SalesOrderHeader.OrderDate`. `product_key` versi tersebut dimasukkan ke fakta. Lookup hanya berdasarkan `product_id` tanpa tanggal berlaku tidak cukup untuk SCD Type 2.

## 6. Kesimpulan

Kombinasi SCD Type 0, Type 1, dan Type 2 digunakan pada tujuh dimensi. `dim_product` menjadi dimensi Type 2 sesuai keputusan tim. Struktur standar Star Schema V2 tetap dipertahankan pada tahap dokumentasi; mekanisme metadata versi harus disetujui sebelum implementasi fisik ETL.
