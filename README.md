# AdventureWorks Data Warehouse — Online Sales Analytics

**Kelompok 2 | Proyek Data Warehouse | Sistem Informasi — UPN “Veteran” Jawa Timur**

## 1. Deskripsi Proyek

Proyek ini bertujuan merancang dan mengembangkan Data Warehouse berbasis database AdventureWorks untuk mendukung analisis proses bisnis **Penjualan Online (Online Sales)**.

AdventureWorks merupakan database operasional (OLTP) yang menyediakan informasi transaksi penjualan, produk, pelanggan, wilayah pemasaran, promosi, mata uang, dan metode pengiriman.

Melalui proyek ini, data transaksi operasional akan diintegrasikan ke dalam struktur dimensional berbentuk *Star Schema*, diproses menggunakan Extract, Transform, Load (ETL), dianalisis melalui Online Analytical Processing (OLAP), dan disajikan dalam dashboard interaktif.

Pengembangan dilaksanakan secara bertahap mulai dari perencanaan hingga presentasi akhir proyek.

## 2. Identitas Proyek

| Komponen | Keterangan |
|---|---|
| Nama Proyek | AdventureWorks Online Sales Data Warehouse |
| Mata Kuliah | Data Warehouse |
| Program Studi | Sistem Informasi |
| Fakultas | Fakultas Ilmu Komputer |
| Universitas | UPN “Veteran” Jawa Timur |
| Proses Bisnis | Penjualan Online |
| Database Sumber | AdventureWorks |
| DBMS | MySQL/MariaDB |
| Database Management | phpMyAdmin |
| Lingkungan Pengembangan | XAMPP |
| Model Data Warehouse | Star Schema |
| Project Sponsor | Dosen Pengampu Mata Kuliah |
| Periode | Semester Ganjil 2026/2027 |

## 3. Tujuan Proyek

Tujuan utama proyek ini adalah membangun sistem analisis penjualan online yang mampu mengubah data transaksi operasional menjadi informasi terstruktur untuk mendukung pengambilan keputusan bisnis.

Tujuan khusus:

1. Mengidentifikasi kebutuhan informasi pada proses bisnis penjualan online.
2. Melakukan profiling dan analisis kualitas data sumber.
3. Merancang model dimensional menggunakan pendekatan Star Schema.
4. Mengembangkan proses ETL untuk mengintegrasikan data ke Data Warehouse.
5. Membangun OLAP cube untuk analisis multidimensional.
6. Mengembangkan dashboard interaktif untuk menyajikan indikator kinerja penjualan online.
7. Memvalidasi hasil analisis terhadap data sumber.

## 4. Ruang Lingkup

Proyek berfokus pada transaksi penjualan online yang tercatat dalam database AdventureWorks.

Identifikasi transaksi online dilakukan menggunakan atribut:

`OnlineOrderFlag = 1`

Ruang lingkup analisis mencakup:

- Tren penjualan online berdasarkan waktu.
- Performa penjualan berdasarkan produk.
- Kontribusi pelanggan terhadap penjualan.
- Distribusi penjualan berdasarkan wilayah.
- Analisis efektivitas promosi.
- Analisis transaksi berdasarkan mata uang.
- Analisis penjualan berdasarkan metode pengiriman.

**Batasan:** Database AdventureWorks digunakan sebagai sumber data yang bersifat read-only. Seluruh transformasi dan penyimpanan hasil ETL dilakukan pada database Data Warehouse terpisah.

## 5. Sumber Data

Database sumber: `adventureworks`

Dataset menggunakan port AdventureWorks untuk MySQL/MariaDB.

Tabel utama yang digunakan:

| Tabel | Deskripsi |
|---|---|
| `sales_salesorderheader` | Informasi utama pesanan penjualan |
| `sales_salesorderdetail` | Detail produk dalam pesanan |
| `sales_customer` | Data pelanggan |
| `production_product` | Informasi produk |
| `sales_salesterritory` | Informasi wilayah pemasaran |
| `sales_specialoffer` | Informasi promosi |
| `sales_currency` | Informasi mata uang |
| `purchasing_shipmethod` | Informasi metode pengiriman |

Tabel pendukung dan hubungan antarentitas akan divalidasi pada tahap profiling dan desain dimensional.

## 6. Pertanyaan Bisnis

Data Warehouse dirancang untuk menjawab pertanyaan bisnis berikut:

| No. | Pertanyaan Bisnis | Indikator |
|---|---|---|
| 1 | Bagaimana perkembangan nilai penjualan online setiap bulan? | Total nilai penjualan |
| 2 | Produk apa yang memberikan kontribusi penjualan terbesar? | Nilai penjualan dan unit terjual |
| 3 | Bagaimana kontribusi pelanggan terhadap penjualan online? | Nilai transaksi per pelanggan |
| 4 | Wilayah mana yang menghasilkan penjualan online tertinggi? | Total nilai penjualan per wilayah |
| 5 | Bagaimana distribusi penjualan berdasarkan promosi? | Nilai penjualan per promosi |
| 6 | Bagaimana distribusi transaksi berdasarkan mata uang? | Jumlah pesanan dan nilai transaksi menurut mata uang |
| 7 | Bagaimana distribusi penjualan berdasarkan metode pengiriman? | Jumlah pesanan per metode pengiriman |

Definisi metrik, termasuk perlakuan terhadap diskon, pajak, ongkos kirim, dan mata uang, akan ditetapkan dalam dokumen perencanaan dimensional.

## 7. Desain Dimensional

### 7.1 Business Process

Proses bisnis yang dipilih adalah **Penjualan Online**.

### 7.2 Grain

Satu baris pada tabel fakta merepresentasikan satu item produk dalam satu detail pesanan penjualan online.

### 7.3 Dimensi

Berdasarkan bus matrix perkuliahan, dimensi yang digunakan adalah:

1. Dimensi Tanggal
2. Dimensi Produk
3. Dimensi Pelanggan
4. Dimensi Wilayah
5. Dimensi Promosi
6. Dimensi Mata Uang
7. Dimensi Metode Kirim

Dimensi yang digunakan bersama proses bisnis lain merupakan kandidat *conformed dimension* dan membutuhkan kesepakatan definisi lintas tim.

### 7.4 Fakta dan Measures

Calon measures meliputi:

- Kuantitas produk terjual.
- Nilai penjualan per item.
- Harga satuan.
- Nilai diskon.

Definisi akhir measures dan aturan agregasinya ditetapkan melalui desain dimensional dan validasi data.

## 8. Arsitektur Sistem

Alur pengembangan Data Warehouse:

**AdventureWorks (OLTP) → Data Profiling → ETL → Data Warehouse (Star Schema) → OLAP Cube → Dashboard**

Komponen utama:

- **OLTP Source:** Database AdventureWorks pada MySQL/MariaDB.
- **Data Profiling:** Pemeriksaan struktur, kelengkapan, dan kualitas data.
- **ETL:** Ekstraksi, transformasi, dan pemuatan data menggunakan Pentaho Data Integration.
- **Data Warehouse:** Penyimpanan data analitis berbasis Star Schema.
- **OLAP:** Analisis multidimensional menggunakan Mondrian.
- **Dashboard:** Visualisasi indikator kinerja penjualan online berbasis web.

## 9. Teknologi

| Teknologi | Fungsi |
|---|---|
| MySQL/MariaDB | Database sumber dan penyimpanan Data Warehouse |
| XAMPP | Lingkungan database lokal |
| phpMyAdmin | Administrasi dan eksekusi query SQL |
| Pentaho Data Integration | ETL |
| Mondrian | OLAP Cube |
| draw.io | Pemodelan Star Schema |
| GitHub | Version control dan dokumentasi |
| Markdown | Dokumentasi proyek |
| Teknologi Web | Pengembangan dashboard |

## 10. Tahapan Pengembangan

| Pekan | Tahapan | Deliverables |
|---|---|---|
| 9 | Perencanaan dan desain awal | Piagam proyek, profiling, pertanyaan bisnis, Star Schema v1, bus matrix |
| 10 | Desain ETL, cube, dan dashboard | Rancangan ETL, OLAP, dan dashboard |
| 11 | Implementasi Data Warehouse | Database dimensional |
| 12 | Implementasi ETL | Proses ETL menggunakan Pentaho |
| 13 | Implementasi OLAP | OLAP Cube Mondrian |
| 14 | Implementasi dashboard | Dashboard web |
| 15 | Presentasi akhir | Demonstrasi dan laporan proyek |
| 16 | Evaluasi akhir semester | Evaluasi sesuai ketentuan perkuliahan |

## 11. Struktur Repositori

```text
adventureworks-online-sales-dw/
│
├── README.md
├── .gitignore
│
├── docs/
│   ├── piagam-proyek.md
│   ├── pertanyaan-bisnis.md
│   ├── grain.md
│   ├── star-schema-v1.drawio
│   ├── star-schema-v1.png
│   ├── star-schema-v1.md
│   ├── bus-matrix.md
│   └── risiko-awal.md
│
├── sql/
│   └── profiling/
│       ├── 08-profiling-null-online-sales.sql
│       └── 09-profiling-currency-online.sql
│
├── hasil-profiling/
│   ├── 07-penjualan-online-per-bulan.csv
│   ├── 08-profiling-null-online-sales.csv
│   ├── 09-profiling-currency-online.csv
│   └── 10-profiling-rentang-tanggal.csv
│
├── bukti/
│   ├── github/
│   │   ├── repositori-tim.png
│   │   └── undangan-dosen.png
│   │
│   └── database/
│       ├── 01-verifikasi-database.png
│       ├── 02-profiling-transaksi-online.png
│       ├── 03-profiling-produk.png
│       ├── 04-validasi-grain.png
│       ├── 05-profiling-orderqty.png
│       ├── 06-validasi-tujuh-dimensi.png
│       ├── 07-penjualan-online-per-bulan.png
│       ├── 08-profiling-null-online-sales.png
│       ├── 09-profiling-currency-online.png
│       └── 10-profiling-rentang-tanggal.png
│
├── laporan/
│   └── pekan-10.md
│
├── etl/
│   └── .gitkeep
│
├── olap/
│   └── .gitkeep
│
└── dashboard/
    └── .gitkeep
```
Struktur dapat disesuaikan dengan ketentuan resmi proyek.

## 12. Tim Proyek

Proyek AdventureWorks Online Sales Data Warehouse dikerjakan oleh lima mahasiswa Program Studi Sistem Informasi, Fakultas Ilmu Komputer, UPN “Veteran” Jawa Timur.

### 12.1 Anggota dan Pembagian Peran

| No. | Nama Anggota | NPM | Peran |
|---|---|---|---|
| 1 | Dea Kusuma Ningrum | 23082010048 | Project Manager & Business Analyst |
| 2 | Fivediniar Edra Primaulidina | 23082010046 | Data Engineer & ETL Developer |
| 3 | Siti Anisa Safitri | 23082010045 | Data Warehouse & Dimensional Modeler |
| 4 | Haura Taqiya Azza Nabila  | 23082010165 | OLAP & Dashboard Developer |
| 5 | Alifa Zuriyatul Haq | 23082010050 | Data Quality, Testing & Documentation |

### 12.2 Tanggung Jawab Tim

**1. Project Manager & Business Analyst — Dea Kusuma Ningrum**

- Mengelola perencanaan, koordinasi, dan pembagian tugas.
- Merumuskan kebutuhan serta pertanyaan bisnis penjualan online.
- Memastikan kesesuaian proyek dengan ketentuan perkuliahan.
- Mengkoordinasikan komunikasi dengan Project Sponsor.
- Memantau progres dan kesiapan Steering Review.

**2. Data Engineer & ETL Developer — Fivediniar Edra Primaulidina**

- Mengidentifikasi tabel dan relasi database sumber.
- Merancang alur ekstraksi, transformasi, dan pemuatan data.
- Mengembangkan ETL menggunakan Pentaho Data Integration.
- Menangani integrasi data sumber ke Data Warehouse.
- Mendokumentasikan proses ETL.

**3. Data Warehouse & Dimensional Modeler — Siti Anisa Safitri**

- Menentukan grain tabel fakta.
- Mengidentifikasi fakta, measures, dan dimensi.
- Merancang Star Schema.
- Menyusun bus matrix dan mengidentifikasi conformed dimension.
- Mengimplementasikan rancangan dimensional di DBMS.

**4. OLAP & Dashboard Developer — Haura Taqiya Azza Nabila**

- Merancang struktur OLAP cube.
- Mengimplementasikan analisis multidimensional dengan Mondrian.
- Menentukan hierarki dan measures untuk kebutuhan analisis.
- Mengembangkan dashboard penjualan online.
- Memastikan dashboard dapat menampilkan indikator bisnis.

**5. Data Quality, Testing & Documentation — Alifa Zuriyatul Haq**

- Melakukan profiling data sumber.
- Memeriksa NULL, duplikasi, dan konsistensi relasi data.
- Memvalidasi hasil ETL dan agregasi Data Warehouse.
- Mengelola dokumentasi teknis serta bukti pengujian.
- Membantu penyusunan laporan progres dan dokumentasi GitHub.

### 12.3 Mekanisme Kolaborasi

Seluruh anggota bertanggung jawab terhadap kualitas akhir proyek, meskipun memiliki pembagian peran utama yang berbeda.

Kolaborasi dilaksanakan melalui:

1. **GitHub:** Penyimpanan kode, SQL, dokumentasi, dan version control.
2. **Review Tim:** Pemeriksaan hasil pekerjaan sebelum digabungkan ke branch utama.
3. **Steering Review:** Pelaporan kemajuan kepada Project Sponsor.
4. **Validasi Bersama:** Pemeriksaan kesesuaian hasil terhadap kebutuhan bisnis dan database sumber.

Setiap anggota wajib mendokumentasikan hasil pekerjaannya dan berkoordinasi apabila ditemukan kendala yang dapat memengaruhi jadwal atau kualitas proyek.

## 13. Risiko Awal

| Risiko | Mitigasi |
|---|---|
| Ketidaksesuaian data sumber dengan kebutuhan analisis | Melakukan profiling dan pemeriksaan relasi tabel |
| Duplikasi data akibat join atau ETL | Mendefinisikan grain dan memvalidasi keunikan data |
| Ketidakkonsistenan dimensi lintas proses bisnis | Menyepakati conformed dimension bersama tim terkait |
| Keterlambatan implementasi ETL dan OLAP | Menetapkan pembagian tugas dan target mingguan |
| Perbedaan hasil agregasi antara OLTP dan Data Warehouse | Melakukan rekonsiliasi jumlah transaksi dan nilai penjualan |

## 14. Status Proyek

**Tahap saat ini: Pekan 9 — Perencanaan dan Desain Awal**

- [x] Menentukan proses bisnis Penjualan Online
- [x] Menyiapkan database AdventureWorks pada MySQL
- [x] Melakukan impor database sumber
- [x] Memverifikasi 71 tabel dan tabel sumber utama
- [x] Mengidentifikasi dimensi berdasarkan bus matrix
- [ ] Melengkapi piagam dan peran anggota tim
- [ ] Memastikan undangan dosen diterima
- [ ] Memfinalisasi pertanyaan bisnis
- [ ] Menyimpan hasil profiling lengkap
- [ ] Memfinalisasi Star Schema versi 1
- [ ] Memfinalisasi bus matrix dan conformed dimension
- [ ] Melengkapi daftar risiko
- [ ] Menyusun laporan Steering Review pekan 10

Checklist ini diperbarui berdasarkan bukti yang tersedia dalam repositori.

## 15. Ketentuan Pengelolaan Data

1. Database sumber AdventureWorks tidak boleh dimodifikasi setelah proses impor dan verifikasi.
2. Analisis sumber menggunakan query read-only.
3. Implementasi tabel fakta dan dimensi dilakukan pada database Data Warehouse terpisah.
4. Setiap proses ETL harus dapat diuji dan direproduksi.
5. Seluruh hasil profiling, desain, dan laporan disimpan dalam repositori.
6. Perubahan rancangan didokumentasikan melalui Git.

---

**AdventureWorks Online Sales Data Warehouse**

Program Studi Sistem Informasi  
Fakultas Ilmu Komputer  
Universitas Pembangunan Nasional “Veteran” Jawa Timur  
2026
