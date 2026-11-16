# ATLAS — Paket OLAP lengkap, khusus folder olap

## Mulai di sini

1. Gunakan database arsip `adventureworks_dw` dengan tabel `fact_online_sales`. Paket ini bukan untuk skema `adventureworks_dw_praktik_haura`. Dump database tidak disertakan; sumber yang dimaksud adalah `sql/adventureworks_dw (2).sql` dari proyek asli. Jangan mengimpor dua dump yang berbeda ke skema yang sama.
2. Jalankan `sql/00_preflight.sql`. Hasil missing_column harus kosong. Setelah itu jalankan pemeriksaan key dan relasi: daftar duplikat harus kosong, jumlah missing_reference dan NULL wajib nol. Berhenti dan perbaiki sumber bila gagal; jangan mengubah fakta hanya agar sesuai angka target.
3. Jalankan `sql/01_create_olap_view.sql` menggunakan akun migrasi. Skrip mengganti dua view bernama v_dim_currency_cube dan v_online_sales_cube, tidak menghapus tabel fakta. Pastikan tidak ada definisi view lain yang perlu dipertahankan. Akun cube harus mempunyai SELECT pada view dan tabel terkait karena view memakai SQL SECURITY INVOKER.
4. Jalankan `sql/rekonsiliasi_cube.sql`. Periksa detail view sama dengan fakta dan tidak ada detail hilang/berlipat.
5. Di Schema Workbench/Mondrian yang kompatibel dengan schema legacy, pasang driver JDBC yang cocok dengan Java dan server database. Isi koneksi berdasarkan `connection.properties.example`. File contoh bukan launcher dan tidak otomatis dibaca aplikasi.
6. Buka `adventureworks_online_sales.xml`. Cube: `OnlineSalesCube`. Ada 7 dimensi, 7 base measures, dan 4 calculated members.
7. Tentukan mode penamaan pada konfigurasi runtime Mondrian yang benar-benar dimuat. `mondrian.properties.example` memberi contoh. Restart runtime setelah perubahan. Dengan `mondrian.olap.SsasCompatibleNaming=false`, gunakan file langsung dalam `mdx/`. Dengan nilai true, gunakan `mdx/ssas/`. Jangan mencampurkan keduanya. Folder contoh ini tidak otomatis mengubah konfigurasi runtime.
8. Eksekusi `00_query.mdx`, lalu `01_query.mdx` sampai `07_query.mdx`, dan `06b_destination_currency.mdx`, satu file per eksekusi. File `01-07-pertanyaan-bisnis.mdx` adalah kumpulan referensi; jangan mengirim seluruh isinya sebagai satu query.
9. Cocokkan hasil MDX dengan SQL pada database yang sama. Bandingkan nilai numerik, bukan hanya urutan baris atau teks format tampilan. Untuk Top 10 dengan nilai seri di batas peringkat, anggota yang dipilih bisa berbeda. Setelah reload ETL/view, buka ulang koneksi atau bersihkan cache Mondrian sebelum rekonsiliasi.

## Kontrak ukuran

- Sales Amount: SUM(line_total), tanpa konversi mata uang tambahan.
- Distinct Orders: COUNT(DISTINCT sales_order_id); jangan menjumlahkan nilai distinct antar kelompok.
- Active Customers: COUNT(DISTINCT customer_id) dari dim_customer melalui surrogate key; unknown -1 tidak dihitung. Ini menghitung pelanggan, bukan banyaknya versi dimensi.
- Estimated Promo Discount: SUM(line_total * discount_pct). Ini estimasi referensi promosi, bukan diskon transaksi aktual.
- Orders Without CurrencyRate: pesanan unik dengan currency_rate_id=-1. NULL atau relasi kurs hilang harus diperbaiki/dijelaskan melalui preflight, bukan diam-diam dianggap kurs tersedia.
- Unknown Currency Order %: orders without rate / distinct orders dalam konteks sel; pada baris status unknown nilainya 100%, sedangkan total cube memakai seluruh order.
- AOV dan Revenue Per Unit: rasio total; bukan rata-rata dari rasio kelompok.

Baseline historis arsip: 60.398 detail, 27.659 pesanan, 60.398 unit, penjualan 29.358.677,2207, estimasi promosi 48.530,24, dan 14.860 pesanan tanpa kurs. Angka ini berasal dari dokumentasi paket sebelumnya, bukan hasil audit ulang dump asli pada sesi ini. Bandingkan database yang sebenarnya sebelum menyatakan cocok.

Hierarchy memakai natural ID di bawah parent. Satu ID yang berpindah parent bisa muncul di lebih dari satu cabang. uniqueMembers=false tidak menghapus duplikasi source dan tidak membuktikan implementasi SCD2 benar. Key surrogate dimensi tetap wajib unik. Jika satu natural ID mempunyai beberapa caption dalam cabang yang sama, tentukan kebijakan historis/caption dahulu sebelum mempercayai label cube.

## Isi paket dan status

- XML utama lengkap; varian legacy_no_view lama dihapus agar tidak tertukar dengan cube yang kurang measures.
- MDX P0–P7 dan tambahan P6b dalam dua mode nama hierarki.
- Preflight, view, SQL rekonsiliasi, kontrak kolom, contoh konfigurasi, dan skrip validasi.
- Jalankan `python validate_package.py` untuk pemeriksaan statis dan uji logika view memakai fixture sintetis SQLite. Fixture bukan data AdventureWorks dan bukan eksekusi MySQL/Mondrian.
- Hasil pengujian tercatat pada `VALIDASI.txt`. Tidak ada bukti eksekusi JDBC, MDX, MySQL pengguna, atau ETL pada paket ini. Folder ini tidak menyertakan installer/runtime, dashboard, atau dump database.

## Referensi resmi yang diperiksa

- https://mondrian.pentaho.com/documentation/schema.html — schema, uniqueMembers dan aggregator.
- https://mondrian.pentaho.com/documentation/configuration.html — SsasCompatibleNaming.
- https://mondrian.pentaho.com/api/mondrian/olap/MondrianProperties.html — bentuk nama hierarchy pada kedua mode.
