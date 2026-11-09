# Source-to-Target Mapping — Data Warehouse Penjualan Online AdventureWorks

**Kelompok 2 · Data Warehouse & OLAP · Sistem Informasi UPN “Veteran” Jawa Timur**  
**Versi: 2.0** — Pemetaan ETL & Validasi Target, 3 November 2026  
**Status:** Terimplementasi dan terverifikasi penuh pada pipeline Pentaho PDI (`adventureworks_dw`).  

**Penanggung jawab:** Siti Anisa Safitri (dimensional modeling), Fivediniar Edra Primaulidina (ETL), Alifa Zuriyatul Haq (kualitas data), Haura Taqiya Azza Nabila (OLAP/dashboard), dan Dea Kusuma Ningrum (koordinasi/keputusan bisnis).

---

### Ringkasan Teknis Pemetaan
* **Database Sumber:** `adventureworks` (OLTP)
* **Database Target:** `adventureworks_dw` (Data Warehouse)
* **Filter Ekstraksi:** `OnlineOrderFlag = 1`
* **Granularitas (Grain):** Satu baris detail produk per pesanan penjualan online (`SalesOrderDetailID`)
---

## Target: dim_date (SCD: tipe 0)
Sumber utama: sales_salesorderheader

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL |
| :--- | :--- | :--- | :--- | :--- |
| date_key | INT | sales_salesorderheader.OrderDate | Konversi format tanggal ke integer YYYYMMDD | NOT NULL |
| full_date | DATE | sales_salesorderheader.OrderDate | DATE(OrderDate) | NOT NULL |
| day_number | INT | sales_salesorderheader.OrderDate | DAY(OrderDate) | - |
| day_name | VARCHAR(20) | sales_salesorderheader.OrderDate | CASE DAYOFWEEK(OrderDate) ke Bahasa Indonesia ('Senin' s.d. 'Minggu') | - |
| month_number | INT | sales_salesorderheader.OrderDate | MONTH(OrderDate) | - |
| month_name | VARCHAR(20) | sales_salesorderheader.OrderDate | CASE MONTH(OrderDate) ke Bahasa Indonesia ('Januari' s.d. 'Desember') | - |
| quarter | INT | sales_salesorderheader.OrderDate | QUARTER(OrderDate) | - |
| year | INT | sales_salesorderheader.OrderDate | YEAR(OrderDate) | - |

---

## Target: dim_product (SCD: tipe 1)
Sumber utama: production_product

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL |
| :--- | :--- | :--- | :--- | :--- |
| product_key | INT | - | Surrogate key dari DW (Auto Increment) | NOT NULL |
| product_id | INT | production_product.ProductID | Langsung | NOT NULL |
| product_name | VARCHAR(100) | production_product.Name | Langsung | - |
| product_number | VARCHAR(50) | production_product.ProductNumber | Langsung | - |
| subcategory_name | VARCHAR(100) | production_productsubcategory.Name | LEFT JOIN via ProductSubcategoryID | Default 'Tanpa Subkategori' |
| category_name | VARCHAR(100) | production_productcategory.Name | LEFT JOIN via ProductCategoryID | Default 'Tanpa Kategori' |

---

## Target: dim_customer (SCD: tipe 1)
Sumber utama: sales_customer

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL |
| :--- | :--- | :--- | :--- | :--- |
| customer_key | INT | - | Surrogate key dari DW (Auto Increment) | NOT NULL |
| customer_id | INT | sales_customer.CustomerID | Langsung | NOT NULL |
| account_number | VARCHAR(30) | sales_customer.AccountNumber | Langsung | - |
| customer_type | VARCHAR(20) | - | Ditentukan tetap 'Individual' (OnlineOrderFlag = 1) | NOT NULL |
| customer_name | VARCHAR(150) | person_person.(FirstName, MiddleName, LastName) | LEFT JOIN via PersonID = BusinessEntityID, TRIM(CONCAT) | Default 'Pelanggan Tidak Diketahui' |
| territory_id | INT | sales_customer.TerritoryID | Langsung | - |

---

## Target: dim_territory (SCD: tipe 1)
Sumber utama: sales_salesterritory

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL |
| :--- | :--- | :--- | :--- | :--- |
| territory_key | INT | - | Surrogate key dari DW (Auto Increment) | NOT NULL |
| territory_id | INT | sales_salesterritory.TerritoryID | Langsung | NOT NULL |
| territory_name | VARCHAR(50) | sales_salesterritory.Name | Langsung | - |
| country_code | VARCHAR(3) | sales_salesterritory.CountryRegionCode | Langsung | - |
| territory_group | VARCHAR(50) | sales_salesterritory.Group | Langsung | - |

---

## Target: dim_promotion (SCD: tipe 1)
Sumber utama: sales_specialoffer

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL |
| :--- | :--- | :--- | :--- | :--- |
| promotion_key | INT | - | Surrogate key dari DW (Auto Increment) | NOT NULL |
| special_offer_id | INT | sales_specialoffer.SpecialOfferID | Langsung | NOT NULL |
| description | VARCHAR(255) | sales_specialoffer.Description | Langsung | - |
| discount_pct | DECIMAL(10,4) | sales_specialoffer.DiscountPct | Langsung | Default 0.0000 |
| type | VARCHAR(50) | sales_specialoffer.Type | Langsung | - |
| category | VARCHAR(50) | sales_specialoffer.Category | Langsung | - |

---

## Target: dim_currency (SCD: tipe 1)
Sumber utama: sales_currencyrate

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL |
| :--- | :--- | :--- | :--- | :--- |
| currency_key | INT | - | Surrogate key dari DW (Auto Increment) | NOT NULL |
| currency_rate_id | INT | sales_currencyrate.CurrencyRateID | Langsung | Default -1 (Injeksi baris default) |
| from_currency_code | VARCHAR(3) | sales_currencyrate.FromCurrencyCode | Langsung | Default 'USD' |
| to_currency_code | VARCHAR(3) | sales_currencyrate.ToCurrencyCode | Langsung | Default 'USD' |
| average_rate | DECIMAL(19,4) | sales_currencyrate.AverageRate | Langsung | Default 1.0000 |
| end_of_day_rate | DECIMAL(19,4) | sales_currencyrate.EndOfDayRate | Langsung | Default 1.0000 |

---

## Target: dim_ship_method (SCD: tipe 1)
Sumber utama: purchasing_shipmethod

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL |
| :--- | :--- | :--- | :--- | :--- |
| ship_method_key | INT | - | Surrogate key dari DW (Auto Increment) | NOT NULL |
| ship_method_id | INT | purchasing_shipmethod.ShipMethodID | Langsung | NOT NULL |
| ship_method_name | VARCHAR(50) | purchasing_shipmethod.Name | Langsung | - |
| ship_base | DECIMAL(19,4) | purchasing_shipmethod.ShipBase | Langsung | Default 0.0000 |
| ship_rate | DECIMAL(19,4) | purchasing_shipmethod.ShipRate | Langsung | Default 0.0000 |

---

## Target: fact_online_sales (grain: satu baris detail produk per pesanan online)
Sumber utama: sales_salesorderdetail JOIN sales_salesorderheader (Filter: `OnlineOrderFlag = 1`)

| Kolom target | Tipe | Tabel.kolom sumber | Transformasi | Aturan NULL |
| :--- | :--- | :--- | :--- | :--- |
| sales_detail_key | INT | sales_salesorderdetail.SalesOrderDetailID | Langsung (Natural Primary Key) | NOT NULL |
| sales_order_id | INT | sales_salesorderheader.SalesOrderID | Degenerate Dimension | NOT NULL |
| date_key | INT | sales_salesorderheader.OrderDate | Format YYYYMMDD | NOT NULL |
| product_key | INT | sales_salesorderdetail.ProductID | Lookup ke `dim_product` berdasarkan ProductID | Wajib match |
| customer_key | INT | sales_salesorderheader.CustomerID | Lookup ke `dim_customer` berdasarkan CustomerID | Wajib match |
| territory_key | INT | sales_salesorderheader.TerritoryID | Lookup ke `dim_territory` berdasarkan TerritoryID | Wajib match |
| promotion_key | INT | sales_salesorderdetail.SpecialOfferID | Lookup ke `dim_promotion` berdasarkan SpecialOfferID | Wajib match |
| currency_key | INT | sales_salesorderheader.CurrencyRateID | COALESCE(CurrencyRateID, -1), lookup ke `dim_currency` | Default `currency_key = 1` |
| ship_method_key | INT | sales_salesorderheader.ShipMethodID | Lookup ke `dim_ship_method` berdasarkan ShipMethodID | Wajib match |
| order_qty | INT | sales_salesorderdetail.OrderQty | Langsung | NOT NULL |
| unit_price | DECIMAL(19,4) | sales_salesorderdetail.UnitPrice | Langsung | NOT NULL |
| unit_price_discount | DECIMAL(19,4) | sales_salesorderdetail.UnitPriceDiscount | Langsung | Default 0.0000 |
| line_total | DECIMAL(19,4) | sales_salesorderdetail.LineTotal | Langsung dari sumber | NOT NULL |

---

## Urutan load
1. `dim_date`
2. `dim_product`
3. `dim_customer`
4. `dim_territory`
5. `dim_promotion`
6. `dim_currency`
7. `dim_ship_method`
8. `fact_online_sales`