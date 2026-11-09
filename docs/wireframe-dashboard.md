# Wireframe & Rancangan Dashboard Penjualan Online — AdventureWorks DW

**Kelompok 2 · Data Warehouse & OLAP · Sistem Informasi UPN “Veteran” Jawa Timur**  
**Versi:** 2.0 — Penyelarasan Penuh Prinsip Visualisasi Data & Piagam Proyek, 10 November 2026  
**Acuan Evaluasi:** Prinsip Desain Dosen (Visualisasi Data & Kebutuhan Pekan 14)  
**Status Implementasi Prototipe:** `dashboard/wireframe-dashboard.html` (Aktif di `http://localhost:3000/`)

---

## 1. Evaluasi Kepatuhan terhadap Prinsip Desain Dosen

Berikut adalah hasil audit dan penyelarasan rancangan dashboard terhadap setiap poin prinsip yang diberikan dosen:

| Prinsip Dosen | Aturan / Standar Evaluasi | Status pada Dashboard Saat Ini | Penyesuaian & Bukti Implementasi |
|---|---|:---:|---|
| **1. Berangkat dari Pertanyaan Bisnis** | Setiap visual wajib menjawab satu pertanyaan bisnis dari piagam proyek. Jika tidak menjawab, hapus. | ✅ **Lolos Penuh** | Setiap visual menjawab 7 Pertanyaan Bisnis resmi (P1 s.d. P7) pada piagam proyek/Bus Matrix `OnlineOrderFlag = 1`. Komponen yang tidak relevan (seperti Sales Person) sengaja ditiadakan karena bernilai NULL di seluruh data online. |
| **2. Pemilihan Visual yang Tepat** | Prinsip Visdat: Satu jenis grafik terbaik untuk tiap pertanyaan bisnis. | ✅ **Lolos Penuh** | • **Tren Penjualan (P1):** **Line chart** (bukan pie/scatter/tabel).<br>• **Kategori Terbesar (P2):** **Bar chart** (bukan pie/gauge).<br>• **Wilayah Tertinggi (P4):** **Bar chart** wilayah & negara.<br>• **Promosi & Diskon (P5):** **Tabel rincian promosi & diskon** (sesuai contoh wireframe dosen).<br>• **Pengiriman (P7):** **Bar chart** sebaran metode kirim. |
| **3. Urutan Baca (Layout)** | **Atas:** Ringkasan (KPI)<br>**Tengah:** Tren (Line Chart)<br>**Bawah:** Rincian (Bar & Tabel) | ✅ **Lolos Penuh** | Mengikuti alur pandang mata (*Z-pattern / F-pattern*):<br>1. *Atas:* 4 KPI Cards (Angka + perubahan periode lalu).<br>2. *Tengah:* Line Chart tren bulanan 3 tahun.<br>3. *Bawah:* Bar horizontal produk & kategori, Bar wilayah, serta Tabel promosi & diskon. |
| **4. Jumlah Visual per Halaman** | **Maksimal 5 sampai 7 visual per halaman**. Lebih dari itu, pecah menjadi beberapa halaman. | ✅ **Lolos Penuh** | Dashboard dipecah menjadi **2 halaman tematik**:<br>• **Halaman 1 (Penjualan & Produk):** Tepat **5 visual** (1 baris KPI + 1 Line Chart + 3 Bar/Tabel Rincian).<br>• **Halaman 2 (Logistik & Kualitas Data):** Tepat **2 visual** (Metode Kirim P7 & Kualitas Kurs P6). |
| **5. Filter Global** | Filter berlaku untuk semua visual. Dituliskan filter apa saja yang tersedia. | ✅ **Lolos Penuh** | Filter global tertera di header: **Tahun** (`dim_date`: 2011–2014), **Wilayah** (`dim_territory`), dan **Kategori Produk** (`dim_product`). |
| **6. Kesiapan Sumber Data (Pekan 14)** | Backend kecil mengembalikan JSON. Kueri SQL dicatat untuk tiap visual. | ✅ **Lolos Penuh** | Tersedia tab **Spesifikasi Kueri JSON Pekan 14** dan pop-up interaktif pada tiap visual yang merinci endpoint API dan kueri SQL `SELECT` dari DW target. |

---

## 2. Diagram Wireframe Kotak & Label (Sesuai Format Kuliah)

Berdasarkan format baku *"cukup berupa kotak dan label"* untuk menyepakati isi dan tata letak sebelum koding Pekan 14:

### HALAMAN 1: KINERJA PENJUALAN, PRODUK & WILAYAH

```
+---------------------------------------------------------------------------------------------------+
|  FILTER GLOBAL:                                                                                   |
|  [Tahun: Semua | 2011 | 2012 | 2013 | 2014]   [Wilayah: Global v]   [Kategori: Semua Kategori v]  |
+---------------------------------------------------------------------------------------------------+
|  RINGKASAN DI ATAS (KPI CARDS):                                                                   |
|  +---------------------+ +---------------------+ +---------------------+ +---------------------+ |
|  | KPI: Nilai Penjualan| | KPI: Jumlah Pesanan | | KPI: Pelanggan Aktif| | KPI: Total Diskon    | |
|  | Angka + Delta (P1)  | | Angka + Delta (P1)  | | Angka + Delta (P3)  | | Nilai Diskon (P5)   | |
|  | $29.358.677 (+69%)  | | 27.659 Pesanan      | | 18.484 Pelanggan    | | $84.320,12          | |
|  +---------------------+ +---------------------+ +---------------------+ +---------------------+ |
+---------------------------------------------------------------------------------------------------+
|  TREN DI TENGAH:                                                                                  |
|  +----------------------------------------------------------------------------------------------+ |
|  | Line Chart (P1)                                                                              | |
|  | Tren penjualan per bulan selama tiga tahun (Mei 2011 – Juni 2014)                            | |
|  | - Sumbu X: Bulan / Tahun (dim_date)                                                          | |
|  | - Sumbu Y: Nilai Penjualan ($ LineTotal) & Garis Putus-putus Unit Terjual                     | |
|  | - Highlight Titik Puncak: Mei 2014 ($1,95 Juta • 5.624 Unit)                                 | |
|  +----------------------------------------------------------------------------------------------+ |
+---------------------------------------------------------------------------------------------------+
|  RINCIAN DI BAWAH:                                                                                |
|  +---------------------------+ +----------------------------+ +---------------------------------+ |
|  | Bar Chart (P2)            | | Bar Chart (P4)             | | Tabel (P5)                      | |
|  | Kategori & Produk Terlaris| | Penjualan per Wilayah      | | Rincian Promosi & Nilai Diskon  | |
|  | - Bar Kategori Produk:    | | - North America ($15,2M)   | | - Kolom: Jenis Penawaran,       | |
|  |   1. Bikes (94,6%)        | | - Pacific ($9,06M - Aus #1)| |          Jumlah Baris, Nilai $, | |
|  |   2. Accessories (2,9%)   | | - Europe ($5,08M)          | |          Nilai Diskon           | |
|  |   3. Clothing (2,5%)      | | Sumbu: Nilai Penjualan ($) | | Data: No Discount vs Diskon     | |
|  | - Bar Horizontal Top 10   | | per Territory Group        | | Total Diskon: $84.320,12        | |
|  +---------------------------+ +----------------------------+ +---------------------------------+ |
+---------------------------------------------------------------------------------------------------+
```

---

### HALAMAN 2: LOGISTIK PENGIRIMAN & KUALITAS DATA MATA UANG

*(Dipisah ke halaman 2 agar memenuhi batas maksimal 5–7 visual per halaman)*

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
|  | - ✈️ XRX - AIR: 10.450 pesanan (37,8%)             | | - Bar Proporsi Referensi Kurs:         | |
|  | - 🚚 CARGO TRANSPORT 5: 7.210 pesanan (26,1%)     | |   * Tanpa Kurs (NULL): 14.860 (53,7%)  | |
|  | - ⚡ OVERNIGHT J-FAST: 5.040 pesanan (18,2%)      | |   * Dengan Kurs: 12.799 (46,3%)        | |
|  | - 📦 STANDARD GROUND: 4.959 pesanan (17,9%)       | | - Tabel Sebaran Valuta Transaksi:      | |
|  |                                                   | |   USD (Default), AUD, CAD, EUR, GBP    | |
|  | Ukuran: COUNT(DISTINCT SalesOrderID)              | | Catatan: Injeksi Default USD di DW     | |
|  +---------------------------------------------------+ +----------------------------------------+ |
+---------------------------------------------------------------------------------------------------+
```

---

## 3. Spesifikasi Kueri Backend JSON (Persiapan Pekan 14)

Pada Pekan 14, visual dashboard akan terhubung ke backend kecil (Node.js/Python API) yang mengeksekusi kueri ke database target `adventureworks_dw` dan mengembalikan JSON:

### Visual 1 — KPI Ringkasan: `GET /api/kpi/summary`
```sql
SELECT 
    ROUND(SUM(line_total), 2) AS total_sales,
    COUNT(DISTINCT sales_order_id) AS total_orders,
    SUM(order_qty) AS total_units,
    ROUND(SUM(line_total) / COUNT(DISTINCT sales_order_id), 2) AS aov,
    ROUND(SUM(unit_price_discount * order_qty * unit_price), 2) AS total_discount
FROM fact_online_sales;
```

### Visual 2 — Line Chart Tren Bulanan (P1): `GET /api/trends/monthly`
```sql
SELECT 
    d.year,
    d.month_number,
    d.month_name,
    COUNT(DISTINCT f.sales_order_id) AS monthly_orders,
    SUM(f.order_qty) AS monthly_units,
    ROUND(SUM(f.line_total), 2) AS monthly_sales
FROM fact_online_sales f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.month_number, d.month_name
ORDER BY d.year, d.month_number;
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
GROUP BY p.category_name, p.product_name
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
    p.description AS jenis_penawaran,
    COUNT(*) AS jumlah_baris,
    ROUND(SUM(f.line_total), 2) AS nilai_penjualan,
    ROUND(SUM(f.unit_price_discount * f.order_qty * f.unit_price), 2) AS nilai_diskon
FROM fact_online_sales f
JOIN dim_promotion p ON f.promotion_key = p.promotion_key
GROUP BY p.description
ORDER BY nilai_penjualan DESC;
```

### Visual 6 — Bar Chart Metode Pengiriman (P7): `GET /api/shipping/distribution`
```sql
SELECT 
    s.ship_method_name,
    COUNT(DISTINCT f.sales_order_id) AS total_orders,
    ROUND(COUNT(DISTINCT f.sales_order_id) * 100.0 / (SELECT COUNT(DISTINCT sales_order_id) FROM fact_online_sales), 2) AS percentage
FROM fact_online_sales f
JOIN dim_ship_method s ON f.ship_method_key = s.ship_method_key
GROUP BY s.ship_method_name
ORDER BY total_orders DESC;
```

### Visual 7 — Quality Split Mata Uang & Kurs (P6): `GET /api/currency/quality`
```sql
SELECT 
    c.to_currency_code,
    COUNT(DISTINCT f.sales_order_id) AS distinct_orders,
    ROUND(SUM(f.line_total), 2) AS total_sales
FROM fact_online_sales f
JOIN dim_currency c ON f.currency_key = c.currency_key
GROUP BY c.to_currency_code
ORDER BY distinct_orders DESC;
```

---

## 4. Cara Pengujian Prototipe Aktif

Prototipe wireframe interaktif yang telah diselaraskan dapat langsung dibuka di peramban:
- **URL Server Lokal:** [http://localhost:3000/](http://localhost:3000/)
- **Berkas Lokal:** [`dashboard/wireframe-dashboard.html`](file:///c:/Mata%20Kuliah/DWO/Final%20Project/AdventureWork-DataWarehousePenjualanOnline-main/dashboard/wireframe-dashboard.html)
