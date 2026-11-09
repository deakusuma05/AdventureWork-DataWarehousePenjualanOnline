# Laporan Audit Teknis & Prioritas Pengembangan Dashboard (Tahap D — Improvement Report)

**Proyek:** AdventureWorks Online Sales Data Warehouse (`adventureworks_dw`)  
**Berkas yang Diaudit:** [`dashboard/wireframe-dashboard.html`](../dashboard/wireframe-dashboard.html)  
**Desain Visual:** *AdventureWorks — Sky Blue Analytics*  
**Tanggal:** 10 November 2026

---

## 1. Kekurangan Filter Lintas Visual (*Cross-Visual Global Filtering*)

- **Kondisi Saat Ini:** Perubahan pada kontrol Filter Global (`Tahun`, `Wilayah`, dan `Kategori`) baru memperbarui keempat kartu KPI utama melalui objek lookup `DW_SLICES` (`80 kombinasi = 5 Tahun × 4 Wilayah × 4 Kategori`).
- **Keterbatasan:** Visual di bawah KPI — yaitu *Monthly Sales Trend* (P1), *Product Category & Top 3 Products* (P2), *Territory Performance* (P4), *Promotion & Discount Table* (P5), *Shipping Distribution* (P7), serta *Currency Quality Split* (P6) — masih menampilkan angka snapshot keseluruhan (*All Years, Global, All Categories*).
- **Strategi Penyelesaian (Tanpa Mengubah Struktur Layout):**
  1. Memperluas struktur JSON snapshot atau respons endpoint backend agar menyertakan agregasi per dimensi (`categories`, `top_products`, `territories`, `promotions`, `currencies`, `shipping`) untuk setiap kombinasi filter.
  2. Menambahkan ID DOM terstruktur pada elemen bar dan baris tabel agar fungsi `triggerFilterChange()` dapat memperbarui lebar kapsul (`style.width`) dan teks nominal secara sinkron.

---

## 2. Keterbatasan Grafik SVG Statis (*Monthly Sales Trend — P1*)

- **Kondisi Saat Ini:** Grafik garis bulanan menggunakan elemen `<svg>` dengan atribut `<path d="...">` yang koordinatnya dituliskan secara statis untuk merangkum kurva 38 bulan (Mei 2011 – Juni 2014).
- **Perbaikan Visual yang Telah Dilakukan:** Menambahkan pemisahan eksplisit antara **Sumbu Y Kiri** (*Nilai Penjualan USD*, garis biru royal `#2379F5` dengan area gradasi `#B9D6FA`) dan **Sumbu Y Kanan** (*Unit Terjual Qty*, garis putus-putus biru azure `#639DF5`) sehingga dua metrik dengan satuan berbeda tidak lagi membingungkan pembaca.
- **Kebutuhan Pengembangan Berikutnya:**
  1. Menyimpan seluruh 38 titik deret waktu (`2011-05` s.d. `2014-06`) dari tabel `fact_online_sales JOIN dim_date` ke dalam array JavaScript atau mengambilnya dari endpoint `GET /api/trends/monthly`.
  2. Membuat fungsi generator koordinat SVG (` polyline / path generator`) di JavaScript yang otomatis menghitung skala `min/max` sumbu Y dan menggambar ulang kurva ketika pengguna memilih filter tahun tertentu (misalnya menampilkan 12 titik bulan ketika tahun `2013` dipilih).

---

## 3. Kebutuhan Backend API (Persiapan Implementasi Pekan 14)

- **Kondisi Saat Ini:** Dashboard berjalan sebagai aplikasi *client-side* mandiri dengan **DW Data Snapshot** yang diekstrak dari [`sql/adventureworks_dw.sql`](../sql/adventureworks_dw.sql). Belum ada layanan backend HTTP aktif yang terhubung langsung ke MySQL/MariaDB.
- **Arsitektur Backend yang Direkomendasikan (Pekan 14):**
  - **Layanan Ringan (Node.js/Express, PHP, atau Python FastAPI/Flask):** Menyediakan REST API *read-only* yang menerima parameter query `?year=2013&region=NA&category=Bikes`.
  - **Daftar Endpoint Inti:**
    1. `GET /api/kpi/summary` — Mengembalikan `total_sales`, `total_orders`, `active_customers`, `total_units`, `aov`, dan `est_promo_discount`.
    2. `GET /api/trends/monthly` — Deret waktu bulanan (`tahun`, `bulan`, `nama_bulan`, `monthly_sales`, `monthly_units`, `monthly_orders`).
    3. `GET /api/products/top` — Agregasi kategori dan 10 produk terlaris.
    4. `GET /api/regions/sales` — Agregasi `territory_group`, `country_code`, dan `territory_name`.
    5. `GET /api/promotions/details` — Rincian penawaran pada `dim_promotion`.
    6. `GET /api/currency/quality` & `GET /api/shipping/distribution` — Audit kurs `dim_currency` dan metode kirim `dim_ship_method`.
  - **Keamanan:** Kredensial database disimpan di `.env` sisi server; browser tidak boleh melakukan koneksi langsung ke MySQL.

---

## 4. Kebutuhan Integrasi OLAP Mondrian (Pekan 13)

- **Kondisi Saat Ini:** Skema fisik `adventureworks_dw` telah memiliki tabel fakta `fact_online_sales` dan 7 tabel dimensi (`dim_date`, `dim_product`, `dim_customer`, `dim_territory`, `dim_promotion`, `dim_currency`, `dim_ship_method`), namun skema XML Mondrian (`olap/*.xml`) belum diimplementasikan.
- **Kebutuhan Integrasi Mondrian:**
  1. Menyusun berkas skema Mondrian (`olap/adventureworks_online_sales.xml`) dengan Cube `OnlineSalesCube` pada tabel `fact_online_sales`.
  2. Mendefinisikan 3 hierarki utama untuk operasi *roll-up* dan *drill-down*:
     - **Dimensi Waktu (`dim_date`, FK `tanggal_key`):** `Tahun (tahun)` &rarr; `Semester (semester)` &rarr; `Kuartal (kuartal)` &rarr; `Bulan (bulan / nama_bulan)` &rarr; `Tanggal (tanggal)`.
     - **Dimensi Produk (`dim_product`, FK `product_key`):** `Kategori (category_name)` &rarr; `Subkategori (subcategory_name)` &rarr; `Produk (product_name)`.
     - **Dimensi Wilayah (`dim_territory`, FK `territory_key`):** `Grup Wilayah (territory_group)` &rarr; `Negara (country_code)` &rarr; `Wilayah (territory_name)`.
  3. Mendefinisikan *Measures* pada Mondrian:
     - `Sales Amount`: `SUM(line_total)`
     - `Order Quantity`: `SUM(order_qty)`
     - `Distinct Orders`: `distinct-count(sales_order_id)` (krusial agar jumlah pesanan tidak dijumlahkan secara aditif lintas produk).

---

## 5. Audit Validitas Rumus Diskon Promosi (`Estimated Discount` — P5)

- **Temuan Data Aktual pada `sql/adventureworks_dw.sql`:**
  - Kolom `unit_price_discount` pada `fact_online_sales` bernilai `0.0000` untuk seluruh 60.398 baris transaksi online, dan `line_total` sama persis dengan `order_qty × unit_price`.
  - Di sisi lain, kolom `promotion_key` menghubungkan 2.151 baris transaksi online ke 3 penawaran berpromosi di `dim_promotion`:
    1. `Volume Discount 11 to 14` (`discount_pct = 0.02` / 2%): 2.118 baris, `SUM(line_total) = $2.005.230,23` &rarr; Estimasi `$40.104,60`.
    2. `Touring-1000 Promotion` (`discount_pct = 0.20` / 20%): 13 baris, `SUM(line_total) = $30.992,91` &rarr; Estimasi `$6.198,58`.
    3. `Touring-3000 Promotion` (`discount_pct = 0.15` / 15%): 20 baris, `SUM(line_total) = $14.847,00` &rarr; Estimasi `$2.227,05`.
- **Implikasi Bisnis & Pelabelan:**
  - Karena `unit_price_discount = 0` di tabel sumber OLTP untuk pesanan online (`OrderQty = 1`), angka **$48.530,24** (`SUM(f.line_total * p.discount_pct)`) adalah **Estimasi Diskon Promosi (*Estimated Discount*)** berdasarkan tarif katalog promosi, bukan potongan faktual yang mengurangi `LineTotal`.
  - Oleh sebab itu, label pada KPI ke-4 dan Tabel P5 wajib dipertahankan sebagai **"Estimasi Diskon Promosi (*Estimated*)"** dan tidak boleh diklaim sebagai *Actual Discount* tanpa revisi aturan bisnis bersama dosen pengampu.

---

## 6. Prioritas Pengembangan OLAP & Dashboard Berikutnya

1. **Prioritas 1 (Pekan 13 — Skema OLAP Mondrian):** Menyusun `olap/adventureworks_online_sales.xml` dan memvalidasi konsistensi hasil kueri MDX terhadap angka baseline SQL (`$29.358.677,22` dan `27.659 pesanan unik`).
2. **Prioritas 2 (Pekan 14 — Backend API JSON):** Mengimplementasikan endpoint REST API ringan yang membaca `adventureworks_dw` pada MySQL dan melayani parameter filter global.
3. **Prioritas 3 (Pekan 14 — Sinkronisasi Visual Dinamis):** Menghubungkan respons JSON dari backend ke grafik tren SVG dan ketiga panel rincian bawah sehingga seluruh visual merespons filter global secara *real-time*.

