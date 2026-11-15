-- =============================================================================
-- DDL DATA WAREHOUSE: ADVENTUREWORKS ONLINE SALES
-- Kelompok 2 · Data Warehouse & OLAP · UPN "Veteran" Jawa Timur
-- File: sql/ddl.sql
-- Standar: Star Schema Versi 2 (Idempotent: Aman dijalankan berulang kali)
-- =============================================================================

SET FOREIGN_KEY_CHECKS = 0;

-- -----------------------------------------------------------------------------
-- 1. DROP TABLES (Urutan: Tabel Fakta terlebih dahulu, baru Tabel Dimensi)
-- -----------------------------------------------------------------------------
DROP TABLE IF EXISTS `fact_online_sales`;
DROP TABLE IF EXISTS `dim_ship_method`;
DROP TABLE IF EXISTS `dim_currency`;
DROP TABLE IF EXISTS `dim_promotion`;
DROP TABLE IF EXISTS `dim_territory`;
DROP TABLE IF EXISTS `dim_customer`;
DROP TABLE IF EXISTS `dim_product`;
DROP TABLE IF EXISTS `dim_date`;

SET FOREIGN_KEY_CHECKS = 1;

-- -----------------------------------------------------------------------------
-- 2. CREATE DIMENSION TABLES
-- -----------------------------------------------------------------------------

-- 2.1 Dimensi Tanggal (dim_date / dim_tanggal Standar Versi 1.0)
CREATE TABLE `dim_date` (
  `tanggal_key` int(11) NOT NULL,
  `tanggal` date NOT NULL,
  `tahun` int(11) NOT NULL,
  `semester` int(11) NOT NULL,
  `kuartal` int(11) NOT NULL,
  `bulan` int(11) NOT NULL,
  `nama_bulan` varchar(20) NOT NULL,
  `minggu_dalam_tahun` int(11) NOT NULL,
  `tanggal_dalam_bulan` int(11) NOT NULL,
  `hari_dalam_minggu` int(11) NOT NULL,
  `nama_hari` varchar(20) NOT NULL,
  `is_akhir_pekan` tinyint(1) NOT NULL,
  PRIMARY KEY (`tanggal_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2.2 Dimensi Produk (dim_product)
CREATE TABLE `dim_product` (
  `product_key` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `product_name` varchar(100) DEFAULT NULL,
  `product_number` varchar(50) DEFAULT NULL,
  `subcategory_name` varchar(100) DEFAULT NULL,
  `category_name` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`product_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2.3 Dimensi Pelanggan (dim_customer)
CREATE TABLE `dim_customer` (
  `customer_key` int(11) NOT NULL,
  `customer_id` int(11) NOT NULL,
  `account_number` varchar(30) DEFAULT NULL,
  `customer_type` varchar(20) DEFAULT NULL,
  `customer_name` varchar(150) DEFAULT NULL,
  `territory_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`customer_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2.4 Dimensi Wilayah (dim_territory)
CREATE TABLE `dim_territory` (
  `territory_key` int(11) NOT NULL,
  `territory_id` int(11) NOT NULL,
  `territory_name` varchar(50) DEFAULT NULL,
  `country_code` varchar(3) DEFAULT NULL,
  `territory_group` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`territory_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2.5 Dimensi Promosi (dim_promotion)
CREATE TABLE `dim_promotion` (
  `promotion_key` int(11) NOT NULL,
  `special_offer_id` int(11) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `discount_pct` decimal(10,4) DEFAULT NULL,
  `type` varchar(50) DEFAULT NULL,
  `category` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`promotion_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2.6 Dimensi Mata Uang & Kurs (dim_currency)
CREATE TABLE `dim_currency` (
  `currency_key` int(11) NOT NULL,
  `currency_rate_id` int(11) NOT NULL,
  `from_currency_code` varchar(3) DEFAULT NULL,
  `to_currency_code` varchar(3) DEFAULT NULL,
  `average_rate` decimal(19,4) DEFAULT NULL,
  `end_of_day_rate` decimal(19,4) DEFAULT NULL,
  PRIMARY KEY (`currency_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2.7 Dimensi Metode Pengiriman (dim_ship_method)
CREATE TABLE `dim_ship_method` (
  `ship_method_key` int(11) NOT NULL,
  `ship_method_id` int(11) NOT NULL,
  `ship_method_name` varchar(50) DEFAULT NULL,
  `ship_base` decimal(19,4) DEFAULT NULL,
  `ship_rate` decimal(19,4) DEFAULT NULL,
  PRIMARY KEY (`ship_method_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 3. CREATE FACT TABLE
-- -----------------------------------------------------------------------------

-- 3.1 Tabel Fakta Penjualan Online (fact_online_sales)
CREATE TABLE `fact_online_sales` (
  `sales_detail_key` int(11) NOT NULL,
  `sales_order_id` int(11) NOT NULL,
  `tanggal_key` int(11) NOT NULL,
  `product_key` int(11) NOT NULL,
  `customer_key` int(11) NOT NULL,
  `territory_key` int(11) NOT NULL,
  `promotion_key` int(11) NOT NULL,
  `currency_key` int(11) NOT NULL,
  `ship_method_key` int(11) NOT NULL,
  `order_qty` int(11) NOT NULL,
  `unit_price` decimal(19,4) NOT NULL,
  `unit_price_discount` decimal(19,4) NOT NULL,
  `line_total` decimal(19,4) NOT NULL,
  PRIMARY KEY (`sales_detail_key`),
  
  -- Indeks untuk optimasi query analitik OLAP
  KEY `idx_fk_tanggal` (`tanggal_key`),
  KEY `idx_fk_product` (`product_key`),
  KEY `idx_fk_customer` (`customer_key`),
  KEY `idx_fk_territory` (`territory_key`),
  KEY `idx_fk_promotion` (`promotion_key`),
  KEY `idx_fk_currency` (`currency_key`),
  KEY `idx_fk_ship_method` (`ship_method_key`),
  
  -- Foreign Key Constraints (Integritas Referensial ke 7 Dimensi)
  CONSTRAINT `fk_fact_tanggal` FOREIGN KEY (`tanggal_key`) REFERENCES `dim_date` (`tanggal_key`) ON DELETE NO ACTION ON UPDATE CASCADE,
  CONSTRAINT `fk_fact_product` FOREIGN KEY (`product_key`) REFERENCES `dim_product` (`product_key`) ON DELETE NO ACTION ON UPDATE CASCADE,
  CONSTRAINT `fk_fact_customer` FOREIGN KEY (`customer_key`) REFERENCES `dim_customer` (`customer_key`) ON DELETE NO ACTION ON UPDATE CASCADE,
  CONSTRAINT `fk_fact_territory` FOREIGN KEY (`territory_key`) REFERENCES `dim_territory` (`territory_key`) ON DELETE NO ACTION ON UPDATE CASCADE,
  CONSTRAINT `fk_fact_promotion` FOREIGN KEY (`promotion_key`) REFERENCES `dim_promotion` (`promotion_key`) ON DELETE NO ACTION ON UPDATE CASCADE,
  CONSTRAINT `fk_fact_currency` FOREIGN KEY (`currency_key`) REFERENCES `dim_currency` (`currency_key`) ON DELETE NO ACTION ON UPDATE CASCADE,
  CONSTRAINT `fk_fact_ship_method` FOREIGN KEY (`ship_method_key`) REFERENCES `dim_ship_method` (`ship_method_key`) ON DELETE NO ACTION ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------------------------------
-- 4. INJEKSI BARIS DEFAULT / UNKNOWN (-1) PADA SELURUH DIMENSI
-- -----------------------------------------------------------------------------

-- Baris -1 untuk dim_date
INSERT INTO `dim_date` (
  `tanggal_key`, `tanggal`, `tahun`, `semester`, `kuartal`, `bulan`, 
  `nama_bulan`, `minggu_dalam_tahun`, `tanggal_dalam_bulan`, `hari_dalam_minggu`, 
  `nama_hari`, `is_akhir_pekan`
) VALUES (
  -1, '1900-01-01', 1900, 1, 1, 1, 
  'Unknown', 1, 1, 1, 
  'Unknown', 0
);

-- Baris -1 untuk dim_product
INSERT INTO `dim_product` (
  `product_key`, `product_id`, `product_name`, `product_number`, 
  `subcategory_name`, `category_name`
) VALUES (
  -1, -1, 'Unknown Product', 'UNKNOWN', 
  'Unknown Subcategory', 'Unknown Category'
);

-- Baris -1 untuk dim_customer
INSERT INTO `dim_customer` (
  `customer_key`, `customer_id`, `account_number`, `customer_type`, 
  `customer_name`, `territory_id`
) VALUES (
  -1, -1, 'UNKNOWN', 'Unknown', 
  'Unknown Customer', -1
);

-- Baris -1 untuk dim_territory
INSERT INTO `dim_territory` (
  `territory_key`, `territory_id`, `territory_name`, `country_code`, 
  `territory_group`
) VALUES (
  -1, -1, 'Unknown Territory', 'UNK', 
  'Unknown Group'
);

-- Baris -1 untuk dim_promotion
INSERT INTO `dim_promotion` (
  `promotion_key`, `special_offer_id`, `description`, `discount_pct`, 
  `type`, `category`
) VALUES (
  -1, -1, 'Unknown Promotion', 0.0000, 
  'Unknown', 'Unknown'
);

-- Baris -1 untuk dim_currency
INSERT INTO `dim_currency` (
  `currency_key`, `currency_rate_id`, `from_currency_code`, `to_currency_code`, 
  `average_rate`, `end_of_day_rate`
) VALUES (
  -1, -1, 'USD', 'USD', 
  1.0000, 1.0000
);

-- Baris -1 untuk dim_ship_method
INSERT INTO `dim_ship_method` (
  `ship_method_key`, `ship_method_id`, `ship_method_name`, `ship_base`, 
  `ship_rate`
) VALUES (
  -1, -1, 'Unknown Ship Method', 0.0000, 
  0.0000
);

-- =============================================================================
-- SELESAI. Skrip ini bersifat idempotent dan siap dijalankan berulang kali.
-- =============================================================================

