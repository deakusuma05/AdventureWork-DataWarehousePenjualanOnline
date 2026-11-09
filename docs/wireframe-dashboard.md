# Wireframe & Pemetaan Data Dashboard Penjualan Online — AdventureWorks DW

**Kelompok 2 · Data Warehouse & OLAP · Sistem Informasi UPN “Veteran” Jawa Timur**  
**Versi:** 2.1 — Penyelarasan Penuh Data Aktual `sql/adventureworks_dw.sql`, Prinsip Visualisasi Data & Piagam Proyek (10 November 2026)  
**Acuan Evaluasi:** Prinsip Desain Dosen (Visualisasi Data & Kebutuhan Pekan 14)  
**Status Implementasi Prototipe:** [`dashboard/wireframe-dashboard.html`](../dashboard/wireframe-dashboard.html) (Aktif di `http://localhost:3000/wireframe-dashboard.html`)

---

## 1. Evaluasi Kepatuhan terhadap Prinsip Desain Dosen

Berikut adalah hasil audit dan penyelarasan rancangan dashboard terhadap setiap poin prinsip yang diberikan dosen:

| Prinsip Dosen | Aturan / Standar Evaluasi | Status pada Dashboard Saat Ini | Penyesuaian & Bukti Implementasi |
|---|---|:---:|---|
| **1. Berangkat dari Pertanyaan Bisnis** | Setiap visual wajib menjawab satu pertanyaan bisnis dari piagam proyek. Jika tidak menjawab, hapus. | ✅ **Lolos Penuh** | Setiap visual menjawab 7 Pertanyaan Bisnis resmi (P1 s.d. P7) pada piagam proyek/Bus Matrix `OnlineOrderFlag = 1`. Komponen yang tidak relevan (seperti Sales Person) sengaja ditiadakan karena bernilai NULL di seluruh data online. |
| **2. Pemilihan Visual yang Tepat** | Prinsip Visdat: Satu jenis grafik terbaik untuk tiap pertanyaan bisnis. | ✅ **Lolos Penuh** | • **Tren Penjualan (P1):** **Line chart** (bukan pie/scatter/tabel).<br>• **Kategori Terbesar (P2):** **Bar chart** (bukan pie/gauge).<br>• **Wilayah Tertinggi (P4):** **Bar chart** wilayah & negara.<br>• **Promosi & Diskon (P5):** **Tabel rincian promosi & diskon** (sesuai contoh wireframe dosen).<br>• **Pengiriman (P7):** **Bar chart** sebaran metode kirim. |
| **3. Urutan Baca (Layout)** | **Atas:** Ringkasan (KPI)<br>**Tengah:** Tren (Line Chart)<br>**Bawah:** Rincian (Bar & Tabel) | ✅ **Lolos Penuh** | Mengikuti alur pandang mata (*Z-pattern / F-pattern*):<br>1. *Atas:* 4 KPI Cards (Angka + perubahan periode lalu).<br>2. *Tengah:* Line Chart tren bulanan 38 bulan.<br>3. *Bawah:* Bar horizontal produk & kategori, Bar wilayah, serta Tabel promosi & diskon. |
| **4. Jumlah Visual per Halaman** | **Maksimal 5 sampai 7 visual per halaman**. Lebih dari itu, pecah menjadi beberapa halaman. | ✅ **Lolos Penuh** | Dashboard dipecah menjadi **2 halaman tematik**:<br>• **Halaman 1 (Penjualan & Produk):** Tepat **5 visual** (1 baris KPI + 1 Line Chart + 3 Bar/Tabel Rincian).<br>• **Halaman 2 (Logistik & Kualitas Data):** Tepat **2 visual** (Metode Kirim P7 & Kualitas Kurs P6). |
| **5. Filter Global** | Filter berlaku untuk semua visual. Dituliskan filter apa saja yang tersedia. | ✅ **Lolos Penuh** | Filter global tertera di header: **Tahun** (`dim_date.tahun`: 2011–2014), **Wilayah** (`dim_territory.territory_group`), dan **Kategori Produk** (`dim_product.category_name`). |
| **6. Kesiapan Sumber Data (Pekan 14)** | Backend kecil mengembalikan JSON. Kueri SQL dicatat untuk tiap visual. | ✅ **Lolos Penuh** | Tersedia tab **Spesifikasi Kueri JSON Pekan 14** dan pop-up interaktif pada tiap visual yang merinci endpoint API dan kueri SQL `SELECT` sesuai skema aktual `sql/adventureworks_dw.sql`. |

---

## 2. Pemetaan Data Aktual Hasil Load (`sql/adventureworks_dw.sql`) ke Komponen Wireframe

Seluruh angka pada wireframe telah dipetakan langsung dari data hasil ETL di [`sql/adventureworks_dw.sql`](../sql/adventureworks_dw.sql):

### 2.1 Ringkasan Populasi Tabel Data Warehouse (`adventureworks_dw`)

| Tabel DW | Jumlah Baris Ter-load | Keterangan Pemetaan di Dashboard |
|---|---:|---|
| `fact_online_sales` | **60.398** | 27.659 pesanan unik (`sales_order_id`), 60.398 unit, total `line_total` **$29.358.677,22** |
| `dim_date` | **1.124** | Rentang kalender transaksi online Mei 2011 – Juni 2014 (38 bulan aktif), PK `tanggal_key` |
| `dim_product` | **130** | 130 produk unik terjual online (88 Bikes, 22 Accessories, 20 Clothing), PK `product_key` |
| `dim_customer` | **73.936** | 18.484 pelanggan aktif yang bertransaksi di `fact_online_sales` (29 pelanggan VIP > $10K) |
| `dim_territory` | **40** | 10 wilayah penjualan dalam 3 grup (`North America`, `Pacific`, `Europe`), PK `territory_key` |
| `dim_promotion` | **16** | 4 jenis penawaran aktif di transaksi online (`No Discount`, `Volume Discount 11 to 14`, `Touring-1000`, `Touring-3000`) |
| `dim_currency` | **9.865** | `currency_key = 1` (`currency_rate_id = -1`, Default USD) + kurs `AUD`, `CAD`, `GBP`, `DEM`, `FRF` |
| `dim_ship_method` | **4** | Seluruh pesanan online terhubung ke `XRQ - TRUCK GROUND` (`ship_method_id = 1`) |

### 2.2 Pemetaan Angka per Visual & Filter Tahun

| Tahun (`dim_date.tahun`) | Nilai Penjualan (`SUM(line_total)`) | Pesanan Unik (`COUNT(DISTINCT sales_order_id)`) | Pelanggan Aktif (`COUNT(DISTINCT customer_key)`) | Unit Terjual (`SUM(order_qty)`) | Penjualan Promo (`special_offer_id > 1`) | Estimasi Diskon Promo (`line_total * discount_pct`) |
|---|---:|---:|---:|---:|---:|---:|
| **Semua Tahun** | **$29.358.677,22** | **27.659** | **18.484** | **60.398** | **$2.051.070,14** (2.151 baris) | **$48.530,24** |
| **2011** | $3.863.120,21 | 1.201 | 1.201 | 1.201 | $0,00 (0 baris) | $0,00 |
| **2012** | $6.390.599,95 | 2.743 | 2.743 | 2.743 | $463.510,67 (206 baris) | $9.270,21 |
| **2013** | $10.732.127,33 | 12.584 | 10.541 | 28.959 | $1.016.028,10 (1.118 baris) | $27.829,40 |
| **2014** | $8.372.829,73 | 11.131 | 9.898 | 27.495 | $571.531,37 (827 baris) | $11.430,63 |

### 2.3 Pemetaan Rincian Visual Bawah & Halaman 2

1. **Visual 3 — Kategori & Top Produk (`dim_product` - P2):**
   - **Bikes:** **$28.318.144,65 (96,46%)** — 15.205 unit (88 produk)
   - **Accessories:** **$700.759,96 (2,39%)** — 36.092 unit (22 produk)
   - **Clothing:** **$339.772,61 (1,16%)** — 9.101 unit (20 produk)
   - **Top 5 Produk:** `Mountain-200 Black, 46` ($1.373.469,55 / 620 unit), `Mountain-200 Black, 42` ($1.363.142,09 / 614 unit), `Mountain-200 Silver, 38` ($1.339.462,79 / 596 unit), `Mountain-200 Silver, 46` ($1.301.100,10 / 580 unit), `Mountain-200 Black, 38` ($1.294.866,14 / 582 unit).
2. **Visual 4 — Penjualan per Wilayah (`dim_territory` - P4):**
   - **North America (US & Canada):** **$11.367.634,37 (38,72%)** — 12.942 pesanan unik (28.964 unit)
   - **Pacific (Australia):** **$9.061.000,58 (30,86%)** — 6.718 pesanan unik (13.345 unit) — *Negara tunggal dengan penjualan tertinggi*
   - **Europe (UK, Germany, France):** **$8.930.042,26 (30,42%)** — 7.999 pesanan unik (18.089 unit)
3. **Visual 5 — Rincian Promosi & Diskon (`dim_promotion` - P5):**
   - `No Discount` (`0%`): **58.247 baris** (27.119 pesanan) — **$27.307.607,08** (93,01%) — Diskon **$0,00**
   - `Volume Discount 11 to 14` (`2%`): **2.118 baris** (2.075 pesanan) — **$2.005.230,23** (6,83%) — Estimasi Diskon **$40.104,60**
   - `Touring-1000 Promotion` (`20%`): **13 baris** (13 pesanan) — **$30.992,91** (0,11%) — Estimasi Diskon **$6.198,58**
   - `Touring-3000 Promotion` (`15%`): **20 baris** (20 pesanan) — **$14.847,00** (0,05%) — Estimasi Diskon **$2.227,05**
   - *(Catatan: Di tabel sumber OLTP, kolom `UnitPriceDiscount` bernilai `0.0000` pada seluruh transaksi online karena `OrderQty = 1`, namun `SpecialOfferID` tetap merekam program promosi yang diikuti sehingga nilai estimasi diskon berdasarkan `dim_promotion.discount_pct` adalah **$48.530,24**).*
4. **Visual 6 — Sebaran Metode Pengiriman (`dim_ship_method` - P7):**
   - **`XRQ - TRUCK GROUND` (`ship_method_id = 1`):** **27.659 pesanan unik (100,0%)** / 60.398 baris detail — **$29.358.677,22**.
5. **Visual 7 — Kelengkapan Kurs & Mata Uang (`dim_currency` - P6):**
   - **Tanpa Kurs (`currency_rate_id = -1` / Default USD):** **14.860 pesanan (53,73%)** / 33.400 baris detail — **$14.693.465,32**
   - **Dengan Kurs (`currency_rate_id > 0`):** **12.799 pesanan (46,27%)** / 26.998 baris detail — **$14.665.211,90**:
     - `AUD`: **6.550 pesanan (23,68%)** — $9.051.988,08
     - `CAD`: **3.147 pesanan (11,38%)** — $1.806.517,44
     - `GBP`: **2.967 pesanan (10,73%)** — $3.388.349,69
     - `DEM`: **76 pesanan (0,27%)** — $237.784,99
     - `FRF`: **59 pesanan (0,21%)** — $180.571,69

---

## 3. Diagram Wireframe Kotak & Label (Sesuai Format Kuliah)

### HALAMAN 1: KINERJA PENJUALAN, PRODUK & WILAYAH

```
+---------------------------------------------------------------------------------------------------+
|  FILTER GLOBAL:                                                                                   |
|  [Tahun: Semua | 2011 | 2012 | 2013 | 2014]   [Wilayah: Global v]   [Kategori: Semua Kategori v]  |
+---------------------------------------------------------------------------------------------------+
|  RINGKASAN DI ATAS (KPI CARDS):                                                                   |
|  +---------------------+ +---------------------+ +---------------------+ +---------------------+ |
|  | KPI: Nilai Penjualan| | KPI: Jumlah Pesanan | | KPI: Pelanggan Aktif| | KPI: Penjualan Promo| |
|  | Angka + Delta (P1)  | | Angka + Delta (P1)  | | Angka + Delta (P3)  | | & Est. Diskon (P5)  | |
|  | $29.358.677,22      | | 27.659 Pesanan      | | 18.484 Pelanggan    | | $2,05M (Est.$48,5K) | |
|  +---------------------+ +---------------------+ +---------------------+ +---------------------+ |
+---------------------------------------------------------------------------------------------------+
|  TREN DI TENGAH:                                                                                  |
|  +----------------------------------------------------------------------------------------------+ |
|  | Line Chart (P1)                                                                              | |
|  | Tren penjualan per bulan selama 38 bulan (Mei 2011 – Juni 2014)                              | |
|  | - Sumbu X: Bulan / Tahun (dim_date: tahun, bulan, nama_bulan)                                | |
|  | - Sumbu Y: Nilai Penjualan ($ line_total) & Garis Putus-putus Unit Terjual (order_qty)       | |
|  | - Highlight Titik Puncak: Mei 2014 ($1.951.195,90 • 5.624 Unit • 2.232 Pesanan)              | |
|  +----------------------------------------------------------------------------------------------+ |
+---------------------------------------------------------------------------------------------------+
|  RINCIAN DI BAWAH:                                                                                |
|  +---------------------------+ +----------------------------+ +---------------------------------+ |
|  | Bar Chart (P2)            | | Bar Chart (P4)             | | Tabel (P5)                      | |
|  | Kategori & Produk Terlaris| | Penjualan per Wilayah      | | Rincian Promosi & Nilai Diskon  | |
|  | - Bar Kategori Produk:    | | - North America ($11,37M)  | | - No Discount: 58.247 ($27,31M) | |
|  |   1. Bikes (96,46%)       | | - Pacific ($9,06M - Aus #1)| | - Vol Disc 11-14: 2.118 ($2,01M)| |
|  |   2. Accessories (2,39%)  | | - Europe ($8,93M)          | | - Touring-1000: 13 ($30,99K)    | |
|  |   3. Clothing (1,16%)     | | Sumbu: Nilai Penjualan ($) | | - Touring-3000: 20 ($14,85K)    | |
|  | - Top Produk Mountain-200 | | per Territory Group        | | Est. Diskon Promo: $48.530,24   | |
|  +---------------------------+ +----------------------------+ +---------------------------------+ |
+---------------------------------------------------------------------------------------------------+
```

### HALAMAN 2: LOGISTIK PENGIRIMAN & KUALITAS DATA MATA UANG

```
+---------------------------------------------------------------------------------------------------+
|  FILTER GLOBAL:                                                                                   |
|  [Tahun: Semua | 2011 | 2012 | 2013 | 2014]   [Wilayah: Global v]   [Kategori: Semua Kategori v]  |
+---------------------------------------------------------------------------------------------------+
|  RINCIAN OPERASIONAL & AUDIT DATA WAREHOUSE:                                                      |
|  +---------------------------------------------------+ +----------------------------------------+ |
|  | Bar Chart (P7)                                    | | Quality Split & Tabel (P6)             | |
|  | Sebaran Metode Pengiriman                         | | Kelengkapan Kurs & Distribusi Valuta   | |
|  |                                                   | |                                        | |
|  | - 🚚 XRQ - TRUCK GROUND (ship_method_id = 1):     | | - Bar Proporsi Referensi Kurs:         | |
|  |   27.659 pesanan unik (100,0%) / 60.398 detail    | |   * Tanpa Kurs (-1): 14.860 (53,73%)   | |
|  | - Metode Lain di Katalog OLTP:                    | |   * Dengan Kurs: 12.799 (46,27%)       | |
|  |   0 pesanan online (0,0%)                         | | - Tabel Sebaran Valuta Transaksi:      | |
|  |                                                   | |   USD (14.860), AUD (6.550), CAD (3.147),| |
|  | Ukuran: COUNT(DISTINCT sales_order_id)            | |   GBP (2.967), DEM (76), FRF (59)      | |
|  +---------------------------------------------------+ +----------------------------------------+ |
+---------------------------------------------------------------------------------------------------+
```

---

## 4. Spesifikasi Kueri Backend JSON Sesuai Skema `sql/adventureworks_dw.sql` (Pekan 14)

### Visual 1 — KPI Ringkasan: `GET /api/kpi/summary`
```sql
SELECT 
    ROUND(SUM(f.line_total), 2) AS total_sales,
    COUNT(DISTINCT f.sales_order_id) AS total_orders,
    COUNT(DISTINCT f.customer_key) AS active_customers,
    SUM(f.order_qty) AS total_units,
    ROUND(SUM(f.line_total) / COUNT(DISTINCT f.sales_order_id), 2) AS aov,
    ROUND(SUM(CASE WHEN p.special_offer_id > 1 THEN f.line_total ELSE 0 END), 2) AS promo_sales,
    ROUND(SUM(f.line_total * p.discount_pct), 2) AS estimated_promo_discount
FROM fact_online_sales f
JOIN dim_promotion p ON f.promotion_key = p.promotion_key;
```

### Visual 2 — Line Chart Tren Bulanan (P1): `GET /api/trends/monthly`
```sql
SELECT 
    d.tahun,
    d.bulan,
    d.nama_bulan,
    COUNT(DISTINCT f.sales_order_id) AS monthly_orders,
    SUM(f.order_qty) AS monthly_units,
    ROUND(SUM(f.line_total), 2) AS monthly_sales
FROM fact_online_sales f
JOIN dim_date d ON f.tanggal_key = d.tanggal_key
GROUP BY d.tahun, d.bulan, d.nama_bulan
ORDER BY d.tahun, d.bulan;
```

### Visual 3 — Bar Chart Kategori & Produk (P2): `GET /api/products/ranking`
```sql
SELECT 
    p.category_name,
    p.product_name,
    SUM(f.order_qty) AS units_sold,
    ROUND(SUM(f.line_total), 2) AS sales_amount
FROM fact_online_sales f
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.product_key, p.category_name, p.product_name
ORDER BY sales_amount DESC
LIMIT 10;
```

### Visual 4 — Bar Chart Penjualan per Wilayah (P4): `GET /api/regions/sales`
```sql
SELECT 
    t.territory_group,
    t.country_code,
    t.territory_name,
    COUNT(DISTINCT f.sales_order_id) AS distinct_orders,
    ROUND(SUM(f.line_total), 2) AS sales_amount
FROM fact_online_sales f
JOIN dim_territory t ON f.territory_key = t.territory_key
GROUP BY t.territory_group, t.country_code, t.territory_name
ORDER BY sales_amount DESC;
```

### Visual 5 — Tabel Promosi & Diskon (P5): `GET /api/promotions/details`
```sql
SELECT 
    p.special_offer_id,
    p.description AS jenis_penawaran,
    p.discount_pct,
    COUNT(*) AS jumlah_baris,
    COUNT(DISTINCT f.sales_order_id) AS jumlah_pesanan,
    ROUND(SUM(f.line_total), 2) AS nilai_penjualan,
    ROUND(SUM(f.line_total * p.discount_pct), 2) AS estimasi_diskon
FROM fact_online_sales f
JOIN dim_promotion p ON f.promotion_key = p.promotion_key
GROUP BY p.promotion_key, p.special_offer_id, p.description, p.discount_pct
ORDER BY nilai_penjualan DESC;
```

### Visual 6 — Bar Chart Metode Pengiriman (P7): `GET /api/shipping/distribution`
```sql
SELECT 
    s.ship_method_id,
    s.ship_method_name,
    COUNT(DISTINCT f.sales_order_id) AS total_orders,
    COUNT(*) AS detail_rows,
    ROUND(SUM(f.line_total), 2) AS sales_amount
FROM fact_online_sales f
JOIN dim_ship_method s ON f.ship_method_key = s.ship_method_key
GROUP BY s.ship_method_id, s.ship_method_name
ORDER BY total_orders DESC;
```

### Visual 7 — Quality Split Mata Uang & Kurs (P6): `GET /api/currency/quality`
```sql
SELECT 
    CASE WHEN c.currency_rate_id = -1 THEN 'Tanpa Kurs (Default USD)' ELSE 'Dengan Kurs' END AS status_kurs,
    c.to_currency_code,
    COUNT(DISTINCT f.sales_order_id) AS distinct_orders,
    COUNT(*) AS detail_rows,
    ROUND(SUM(f.line_total), 2) AS total_sales
FROM fact_online_sales f
JOIN dim_currency c ON f.currency_key = c.currency_key
GROUP BY status_kurs, c.to_currency_code
ORDER BY distinct_orders DESC;
```
