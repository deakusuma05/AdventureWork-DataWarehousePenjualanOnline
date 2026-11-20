-- ============================================================================
-- PENGUJIAN REKONSILIASI DATA (ETL RECONCILIATION & DATA QUALITY AUDIT)
-- Proyek: Data Warehouse Penjualan Online AdventureWorks (OnlineOrderFlag = 1)
-- Database Target: adventureworks_dw
-- Tujuan: Membuktikan keselarasan 100% antara data sumber staging dan tabel fakta
-- ============================================================================

USE adventureworks_dw;

-- ----------------------------------------------------------------------------
-- UJI 1: REKONSILIASI KELENGKAPAN BARIS (ROW COUNT RECONCILIATION)
-- Memastikan tidak ada data transaksi yang tertinggal atau hilang saat ETL.
-- Target: Jumlah baris Staging Detail = Jumlah baris Tabel Fakta (60.398 baris).
-- ----------------------------------------------------------------------------
SELECT 
    '1. Uji Kelengkapan Baris Detail' AS deskripsi_uji,
    (SELECT COUNT(*) FROM stg_salesorderdetail) AS baris_staging,
    (SELECT COUNT(*) FROM fact_online_sales) AS baris_fakta,
    ((SELECT COUNT(*) FROM stg_salesorderdetail) - (SELECT COUNT(*) FROM fact_online_sales)) AS selisih_baris,
    CASE 
        WHEN (SELECT COUNT(*) FROM stg_salesorderdetail) = (SELECT COUNT(*) FROM fact_online_sales) 
        THEN 'LULUS (100% Selaras)'
        ELSE 'GAGAL (Ada Data Hilang/Ganda)'
    END AS status_rekonsiliasi;


-- ----------------------------------------------------------------------------
-- UJI 2: REKONSILIASI INTEGRITAS NILAI FINANSIAL & KUANTITAS
-- Memastikan total nilai omset (LineTotal) dan kuantitas unit (OrderQty) akurat.
-- Target: Selisih nominal = Rp 0,00 (100.00% persis).
-- ----------------------------------------------------------------------------
SELECT 
    '2. Uji Integritas Finansial & Unit' AS deskripsi_uji,
    ROUND(stg.total_omset_staging, 2) AS omset_staging,
    ROUND(dw.total_omset_fakta, 2) AS omset_fakta,
    ROUND(stg.total_omset_staging - dw.total_omset_fakta, 2) AS selisih_omset,
    stg.total_qty_staging AS qty_staging,
    dw.total_qty_fakta AS qty_fakta,
    (stg.total_qty_staging - dw.total_qty_fakta) AS selisih_qty,
    CASE 
        WHEN ROUND(stg.total_omset_staging, 2) = ROUND(dw.total_omset_fakta, 2) 
         AND stg.total_qty_staging = dw.total_qty_fakta
        THEN 'LULUS (Akurat 100%)'
        ELSE 'GAGAL (Terdapat Selisih Angka)'
    END AS status_rekonsiliasi
FROM 
    (SELECT SUM(LineTotal) AS total_omset_staging, SUM(OrderQty) AS total_qty_staging FROM stg_salesorderdetail) stg,
    (SELECT SUM(line_total) AS total_omset_fakta, SUM(order_qty) AS total_qty_fakta FROM fact_online_sales) dw;


-- ----------------------------------------------------------------------------
-- UJI 3: REKONSILIASI LEVEL HEADER (SALES ORDER ID)
-- Memastikan seluruh 27.659 pesanan header online terwakili di fakta.
-- ----------------------------------------------------------------------------
SELECT 
    '3. Uji Kelengkapan Pesanan (Header)' AS deskripsi_uji,
    (SELECT COUNT(DISTINCT SalesOrderID) FROM stg_salesorderheader) AS header_order_staging,
    (SELECT COUNT(DISTINCT sales_order_id) FROM fact_online_sales) AS header_order_fakta,
    ((SELECT COUNT(DISTINCT SalesOrderID) FROM stg_salesorderheader) - (SELECT COUNT(DISTINCT sales_order_id) FROM fact_online_sales)) AS selisih_order,
    CASE 
        WHEN (SELECT COUNT(DISTINCT SalesOrderID) FROM stg_salesorderheader) = (SELECT COUNT(DISTINCT sales_order_id) FROM fact_online_sales)
        THEN 'LULUS (27.659 Order Lengkap)'
        ELSE 'GAGAL'
    END AS status_rekonsiliasi;


-- ----------------------------------------------------------------------------
-- UJI 4: AUDIT ANGGOTA DEFAULT / UNKNOWN MEMBER (-1) DI TABEL FAKTA
-- Mengidentifikasi transaksi yang dialokasikan ke surrogate key -1.
-- Catatan: currency_key = -1 wajar berjumlah 14.860 baris karena transaksi
-- domestik AS (CurrencyRateID = NULL) tidak memerlukan kurs valas.
-- ----------------------------------------------------------------------------
SELECT 
    '4. Audit Missing Key (-1) di Fakta' AS deskripsi_uji,
    SUM(CASE WHEN tanggal_key = -1 THEN 1 ELSE 0 END) AS unknown_tanggal,
    SUM(CASE WHEN product_key = -1 THEN 1 ELSE 0 END) AS unknown_product,
    SUM(CASE WHEN customer_key = -1 THEN 1 ELSE 0 END) AS unknown_customer,
    SUM(CASE WHEN territory_key = -1 THEN 1 ELSE 0 END) AS unknown_territory,
    SUM(CASE WHEN promotion_key = -1 THEN 1 ELSE 0 END) AS unknown_promotion,
    SUM(CASE WHEN currency_key = -1 THEN 1 ELSE 0 END) AS domestik_tanpa_valas_currency,
    SUM(CASE WHEN ship_method_key = -1 THEN 1 ELSE 0 END) AS unknown_ship_method,
    COUNT(*) AS total_baris_fakta
FROM fact_online_sales;


-- ----------------------------------------------------------------------------
-- UJI 5: PEMBUKTIAN SCD TIPE 2 DIM_PRODUCT (RIWAYAT BIAYA PRODUK)
-- Membuktikan produk yang mengalami perubahan harga pokok memiliki beberapa versi.
-- ----------------------------------------------------------------------------
SELECT 
    '5. Bukti SCD Tipe 2 (Product ID 707, 708, 749)' AS deskripsi_uji,
    p.product_key,
    p.product_id,
    p.product_name,
    p.standard_cost,
    p.berlaku_mulai,
    p.berlaku_sampai,
    CASE 
        WHEN p.berlaku_sampai = '9999-12-31' THEN 'Versi Aktif Saat Ini'
        ELSE 'Versi Riwayat Historis'
    END AS status_versi
FROM dim_product p
WHERE p.product_id IN (707, 708, 749)
ORDER BY p.product_id, p.berlaku_mulai;


-- ----------------------------------------------------------------------------
-- UJI 6: UJI IDEMPOTENSI & KEUNIKAN PRIMARY KEY DI TABEL FAKTA
-- Memastikan tidak ada duplikasi data akibat proses ETL yang di-run berulang kali.
-- ----------------------------------------------------------------------------
SELECT 
    '6. Uji Duplikasi Baris Fakta' AS deskripsi_uji,
    sales_detail_key,
    COUNT(*) AS jumlah_duplikat
FROM fact_online_sales
GROUP BY sales_detail_key
HAVING COUNT(*) > 1;
-- Ekspektasi: 0 baris / Empty Set (Tidak ada satupun baris duplikat).
