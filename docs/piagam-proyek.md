# Piagam Proyek
# Data Warehouse Penjualan Online AdventureWorks

**Kelompok 2 · Data Warehouse & OLAP**  
**Program Studi Sistem Informasi · UPN “Veteran” Jawa Timur**  
**Versi:** 1.1 · 2 November 2026  
**Status:** Rancangan kerja untuk review tim

## 1. Identitas proyek

| Unsur | Ketetapan rancangan |
|---|---|
| Nama proyek | Data Warehouse Penjualan Online AdventureWorks |
| Proses bisnis | **Analisis Kinerja Penjualan Online Berdasarkan Detail Transaksi** |
| Nama proses dalam bahasa Inggris | Online Sales Transaction Performance Analysis |
| Label ringkas pada Bus Matrix | Penjualan Online |
| Sumber data | Database transaksi `adventureworks` |
| Target Data Warehouse | Database terpisah `adventureworks_dw` |
| Perangkat ETL | Pentaho Data Integration |
| Lingkungan basis data acuan | MySQL/MariaDB sesuai acuan proyek; koneksi dan nama tabel aktual diverifikasi sebelum implementasi |
| Tabel fakta | `fact_online_sales` |
| Model dimensional | Star schema: satu tabel fakta dan tujuh tabel dimensi |
| Dokumen terkait | [Grain](grain.md), [Bus Matrix](bus-matrix.md), dan rancangan `star-schema-v1.md`/`star-schema-v1.png` |

## 2. Latar belakang

Data penjualan AdventureWorks tersebar pada tabel pesanan, detail produk, pelanggan, wilayah, promosi, mata uang/kurs, dan metode pengiriman. Struktur transaksi tersebut perlu diintegrasikan agar analisis tidak harus membangun ulang hubungan tabel dan aturan perhitungan setiap kali laporan dibuat.

Proyek ini membangun Data Warehouse untuk transaksi yang dipesan secara online. Data dipertahankan pada tingkat detail produk dalam pesanan agar dapat diringkas menurut waktu dan dimensi bisnis tanpa kehilangan referensi transaksi asal. Pemisahan database sumber dan target menjaga proses analitik serta pemuatan ulang tetap terpisah dari database transaksi.

## 3. Tujuan dan manfaat

1. Mengintegrasikan detail pesanan online ke `fact_online_sales` melalui ETL yang terdokumentasi.
2. Menyediakan tujuh dimensi analisis yang konsisten dengan Bus Matrix dan star schema.
3. Menyediakan analisis tren bulanan, kontribusi produk, pelanggan, wilayah, dan promosi, serta distribusi metode kirim dan kelengkapan informasi mata uang.
4. Membuktikan kesesuaian jumlah detail, pesanan, unit, dan nominal antara sumber dan DW dengan filter yang sama.
5. Menyediakan dasar OLAP dan dashboard yang dapat ditelusuri kembali ke definisi KPI dan data sumber.

Manfaat utama proyek adalah tersedianya data analisis yang terintegrasi, definisi pengukuran yang konsisten, dan bukti kualitas data yang dapat diperiksa saat review.

## 4. Pertanyaan bisnis

| ID | Pertanyaan | Ukuran utama | Dimensi |
|---|---|---|---|
| PB-01 | Bagaimana perkembangan nilai transaksi online setiap bulan? | `SUM(line_total)`, jumlah pesanan distinct | Date |
| PB-02 | Produk dan kategori mana yang memberikan kontribusi nilai terbesar? | Nilai detail dan unit terjual | Product, Date |
| PB-03 | Pelanggan mana yang memiliki nilai transaksi terbesar? | Nilai detail dan jumlah pesanan distinct | Customer, Date |
| PB-04 | Wilayah penjualan mana yang memberikan kontribusi tertinggi? | Nilai detail dan jumlah pesanan distinct | Territory, Date |
| PB-05 | Bagaimana kontribusi transaksi berdasarkan jenis promosi? | Nilai detail, jumlah detail, diskon setelah validasi rumus | Promotion, Date |
| PB-06 | Bagaimana distribusi transaksi menurut mata uang dan kelengkapan referensi kurs? | Pesanan distinct, proporsi referensi kurs NULL | Currency, Date; referensi kurs sumber untuk audit |
| PB-07 | Metode pengiriman apa yang paling banyak digunakan? | Jumlah pesanan distinct | Ship Method, Date |

Nilai transaksi diartikan sebagai nilai detail pesanan pada sumber. Penyebutan pendapatan terealisasi memerlukan kebijakan status pesanan yang tervalidasi. Perbandingan nominal mengikuti satuan mata uang yang telah dibuktikan konsisten.

## 5. Ruang lingkup dan batasan

| Aspek | Cakupan proyek |
|---|---|
| Transaksi | Pesanan dengan `sales_salesorderheader.OnlineOrderFlag = 1` |
| Sumber utama | `sales_salesorderheader` dan `sales_salesorderdetail`, dihubungkan melalui `SalesOrderID` |
| Grain fakta | Satu baris detail produk dalam satu pesanan online, diidentifikasi oleh `SalesOrderDetailID` |
| Periode | Mengikuti rentang `OrderDate` aktual; baseline sebelumnya mencatat Mei 2011–Juni 2014 |
| Dimensi | Date, Product, Customer, Territory, Promotion, Currency, Ship Method |
| Measure inti | `order_qty`, `unit_price`, `unit_price_discount`, `line_total` |
| Measure turunan | `gross_amount` dan `discount_amount`, digunakan setelah formula dan presisi tervalidasi |
| Operasi analisis | Slice, dice, roll-up, drill-down, serta peringkat kontribusi |
| Penanganan data tidak lengkap | Anggota dimensi khusus dan catatan kualitas; transaksi tidak dihapus hanya karena referensi kurs NULL |

Penjualan offline, pembelian, produksi, persediaan, serta perhitungan keuntungan bersih berada di luar cakupan. Pajak dan ongkir tingkat pesanan tidak menjadi measure aditif pada fakta detail tanpa rancangan alokasi tersendiri. `Territory` merepresentasikan wilayah penjualan, bukan otomatis alamat pengiriman.

## 6. Kesepakatan model dimensional

| Label Bus Matrix | Tabel dimensi | FK pada fakta | Sumber konteks transaksi |
|---|---|---|---|
| Date | `dim_date` | `date_key` | Header.`OrderDate` |
| Product | `dim_product` | `product_key` | Detail.`ProductID` |
| Customer | `dim_customer` | `customer_key` | Header.`CustomerID` |
| Territory | `dim_territory` | `territory_key` | Header.`TerritoryID` |
| Promotion | `dim_promotion` | `promotion_key` | Detail.`SpecialOfferID` |
| Currency | `dim_currency` | `currency_key` | Header.`CurrencyRateID` → referensi kurs → kode mata uang; pemetaan final perlu validasi |
| Ship Method | `dim_ship_method` | `ship_method_key` | Header.`ShipMethodID` |

Setiap dimensi memiliki primary key pengganti dan setiap FK fakta menunjuk anggota dimensi yang valid. `SalesOrderID` dan `SalesOrderDetailID` tetap disimpan sebagai referensi sumber. Kunci teknis fakta, bila digunakan, tidak mengubah grain.

Hierarki analisis yang disiapkan adalah Tahun → Kuartal → Bulan → Tanggal, Kategori → Subkategori → Produk, serta Kelompok Wilayah → Negara/Region → Wilayah. Ketujuh dimensi masih kandidat conformed dimension karena pemakaian konsisten lintas proses belum dibuktikan.

## 7. Tim dan tanggung jawab

Pembagian berikut mengikuti dokumen Bus Matrix dan menjadi acuan koordinasi pekerjaan.

| Anggota | Peran | Tanggung jawab utama |
|---|---|---|
| Dea Kusuma Ningrum | Analisis bisnis dan integrasi rancangan | Merumuskan kebutuhan dan pertanyaan bisnis; ikut menganalisis pilihan desain serta aturan KPI; membantu pemecahan masalah lintas bagian; menyelaraskan hasil pemodelan, ETL, kualitas data, dan dashboard dengan tujuan proyek |
| Siti Anisa Safitri | Dimensional modeling | Menjaga grain, Bus Matrix, star schema, PK/FK, dan definisi dimensi |
| Fivediniar Edra Primaulidina | ETL | Menyiapkan koneksi, staging, transformasi, job Pentaho, dan dokumentasi pemuatan |
| Alifa Zuriyatul Haq | Kualitas data | Profiling, rekonsiliasi, pemeriksaan duplikasi/NULL/FK, dan bukti validasi |
| Haura Taqiya Azza Nabila | OLAP dan dashboard | Menyusun hierarki, KPI, analisis visual, serta pengujian agregasi |

Dea terlibat langsung dalam penyusunan pertanyaan bisnis dan definisi KPI, penelaahan alternatif solusi, serta penyelarasan dokumen dan hasil pekerjaan lintas bagian. Luaran kontribusinya berupa rumusan kebutuhan, catatan pertimbangan keputusan, dan revisi hasil integrasi rancangan. Pelaksanaannya dikerjakan bersama anggota yang menangani bagian terkait.

Perubahan lintas bagian ditinjau bersama pemilik pekerjaan yang terdampak. Persetujuan dosen atau pihak lain dicatat setelah benar-benar diberikan.

## 8. Luaran dan tahapan pekerjaan

| Tahap | Kegiatan | Luaran | Syarat melanjutkan |
|---|---|---|---|
| 1. Penyelarasan desain | Menyamakan proses, filter, grain, fakta, dan tujuh dimensi | Piagam, grain, Bus Matrix, star schema | Tidak ada perbedaan definisi antar dokumen |
| 2. Profiling dan mapping | Memeriksa sumber, status, tanggal, kurs, dan formula | Query SELECT, hasil profiling, source-to-target mapping | Sumber dan aturan transformasi dapat dijelaskan |
| 3. ETL | Menyiapkan staging, memuat dimensi, lookup key, memuat fakta | Transformasi `.ktr`, job `.kjb`, dokumentasi workflow | Pemuatan berhasil dan kegagalan tercatat |
| 4. Validasi | Membandingkan sumber–target dan menguji re-run | Dokumen validasi serta bukti query | Kriteria penerimaan terpenuhi |
| 5. Analisis | Menyusun OLAP dan dashboard | Hierarki/cube sesuai perangkat yang dipakai, dashboard, uji KPI | Agregasi konsisten dan satuan nilai jelas |
| 6. Pelaporan | Merangkum hasil, batasan, dan tindak lanjut | Laporan serta bahan review | Luaran dan bukti dapat ditelusuri |

Tanggal mulai dan tenggat tiap tahap mengikuti jadwal perkuliahan serta kesepakatan tim. Dokumen ini tidak menetapkan tanggal pelaksanaan yang belum tersedia. Dependensi tetap desain → mapping → ETL → validasi → analisis, meskipun dokumentasi desain diselaraskan setelah Bus Matrix dibuat.

## 9. Kriteria penerimaan

| ID | Kriteria | Bukti yang disiapkan |
|---|---|---|
| KP-01 | Fakta hanya memuat detail pesanan online sesuai filter resmi | Query cakupan sumber dan target |
| KP-02 | Identitas detail unik dan tidak NULL | Pemeriksaan `sales_order_detail_id` |
| KP-03 | Jumlah detail, pesanan distinct, dan unit sesuai sumber | Rekonsiliasi jumlah dengan snapshot/filter sama |
| KP-04 | Total nilai detail sesuai sumber dengan presisi terdokumentasi | Perbandingan `SUM(LineTotal)` dan `SUM(line_total)` |
| KP-05 | Seluruh FK valid, termasuk anggota khusus | Pemeriksaan orphan dan log lookup |
| KP-06 | Penanganan kurs NULL dapat ditelusuri tanpa menghapus detail | Jumlah referensi kurs NULL serta mapping Unknown |
| KP-07 | Pemuatan ulang tidak menggandakan data | Hasil re-run dan pemeriksaan keunikan |
| KP-08 | Nilai tren tidak bergeser bulan tanpa penjelasan | Rekonsiliasi bulanan dan aturan tanggal |
| KP-09 | KPI dashboard sesuai grain dan aturan mata uang | Uji agregasi, distinct count, dan definisi KPI |
| KP-10 | Database sumber tidak dimodifikasi oleh ETL | Konfigurasi koneksi dan dokumentasi job |

Baseline yang tercatat pada Bus Matrix adalah 60.398 detail, 27.659 pesanan, 130 produk unik, 60.398 unit, dan nilai detail 29.358.677,22 dalam satuan sumber. Angka ini merupakan pembanding dari profiling sebelumnya, bukan hasil ETL terbaru. Perubahan snapshot/filter mewajibkan penghitungan ulang baseline.

## 10. Risiko, asumsi, dan keputusan terbuka

| Risiko/keputusan | Dampak | Penanganan | Penanggung jawab terkait |
|---|---|---|---|
| Identitas mata uang dan arti kurs NULL belum final | Salah pelabelan atau penjumlahan nominal | Telusuri kode mata uang, satuan `LineTotal`, dan aturan konversi; jangan otomatis mengisi USD | Siti, Fivediniar, Alifa |
| Distribusi bulan pada hasil sebelumnya berbeda | Tren dashboard tidak konsisten | Jalankan ulang query pada sumber/sesi yang sama dan tetapkan satu hasil acuan | Alifa, Fivediniar, Haura |
| Status pesanan belum menjadi kebijakan KPI | Nilai pesanan dapat disalahartikan sebagai pendapatan terealisasi | Profilkan `Status`; dokumentasikan filter dan hitung ulang baseline bila berubah | Dea, Siti, Alifa |
| Join dimensi menghasilkan banyak pasangan | Jumlah dan nilai fakta berlipat | Pastikan lookup menghasilkan tepat satu anggota per detail dan tanggal efektif bila SCD Type 2 | Siti, Fivediniar |
| Formula diskon atau presisi belum tervalidasi | KPI promosi keliru | Rekonsiliasi terhadap `LineTotal` dan hindari penerapan diskon dua kali | Siti, Alifa |
| Historisasi dan kalender belum final | Konteks historis atau tanggal berubah | Tetapkan aturan SCD dan interpretasi waktu sebelum finalisasi ETL | Siti, Fivediniar, Haura |

Asumsi kerja adalah data sumber dapat diakses untuk ekstraksi dan target tersedia untuk pengembangan. Keberadaan database, koneksi, dan transformasi belum dibuktikan oleh dokumen ini.

## 11. Pengendalian perubahan dan persetujuan

Perubahan proses, grain, filter, dimensi, atau definisi KPI dicatat bersama alasan dan dampaknya. Perubahan grain memerlukan peninjauan ulang star schema, mapping, ETL, baseline, serta dashboard. Riwayat persetujuan memuat tanggal, pihak yang meninjau, dan keputusan setelah review berlangsung.

Versi 1.1 memperjelas kontribusi Dea pada analisis bisnis dan integrasi rancangan. Dokumen disusun dari `bus-matrix.md` versi 2.0 dan acuan rancangan star schema pada materi proyek yang diberikan. Statusnya adalah rancangan untuk review tim; tidak menyatakan implementasi ataupun persetujuan telah selesai.
