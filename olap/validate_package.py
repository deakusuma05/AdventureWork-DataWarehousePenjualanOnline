from pathlib import Path
import xml.etree.ElementTree as ET
import re, sqlite3, math
p=Path(__file__).resolve().parent
cube=ET.parse(p/'adventureworks_online_sales.xml').getroot().find('Cube')
assert cube.get('name')=='OnlineSalesCube'
assert len(cube.findall('Dimension'))==7
measures={e.get('name') for tag in ['Measure','CalculatedMember'] for e in cube.findall(tag)}
assert len(measures)==11
for f in (p/'mdx').rglob('*.mdx'):
 text='\n'.join(l for l in f.read_text().splitlines() if not l.strip().startswith('--'))
 assert set(re.findall(r'\[Measures\]\.\[([^]]+)\]',text)) <= measures, f
 assert '[OnlineSalesCube]' in text
 for d in cube.findall('Dimension'):
  h=d.find('Hierarchy');prefix=(f"[{d.get('name')}].[{h.get('name')}]" if f.parent.name=='ssas' else f"[{d.get('name')}.{h.get('name')}]")
  for level in re.findall(re.escape(prefix)+r'\.\[([^]]+)\]\.Members',text):
   assert level in {l.get('name') for l in h.findall('Level')}, (f,level)
# Exercise the delivered view SELECT logic with a small synthetic fixture.
# SQLite replaces only the CREATE syntax; no claim about MySQL parser/runtime.
db=sqlite3.connect(':memory:');db.execute("ATTACH DATABASE ':memory:' AS adventureworks_dw")
db.executescript('''
CREATE TABLE adventureworks_dw.fact_online_sales(sales_detail_key INTEGER,sales_order_id INTEGER,tanggal_key INTEGER,product_key INTEGER,customer_key INTEGER,territory_key INTEGER,promotion_key INTEGER,currency_key INTEGER,ship_method_key INTEGER,order_qty INTEGER,unit_price NUMERIC,unit_price_discount NUMERIC,line_total NUMERIC);
CREATE TABLE adventureworks_dw.dim_customer(customer_key INTEGER PRIMARY KEY,customer_id INTEGER);
CREATE TABLE adventureworks_dw.dim_promotion(promotion_key INTEGER PRIMARY KEY,discount_pct NUMERIC);
CREATE TABLE adventureworks_dw.dim_currency(currency_key INTEGER PRIMARY KEY,currency_rate_id INTEGER,from_currency_code TEXT,to_currency_code TEXT,average_rate NUMERIC,end_of_day_rate NUMERIC);
INSERT INTO adventureworks_dw.dim_customer VALUES(1,42),(2,42),(3,-1);
INSERT INTO adventureworks_dw.dim_promotion VALUES(1,0),(2,0.1);
INSERT INTO adventureworks_dw.dim_currency VALUES(1,-1,'USD','USD',1,1),(2,10,'USD','EUR',0.9,0.9);
INSERT INTO adventureworks_dw.fact_online_sales VALUES(1,100,1,1,1,1,2,1,1,1,100,0,100),(2,100,1,1,2,1,1,1,1,1,50,0,50),(3,101,1,1,2,1,2,2,1,1,80,0,80),(4,102,1,1,3,1,1,2,1,1,20,0,20);
''')
sql=(p/'sql/01_create_olap_view.sql').read_text()
for stmt in sql.split(';'):
 if 'CREATE OR REPLACE SQL SECURITY INVOKER VIEW' in stmt:
  stmt=stmt[stmt.index('CREATE OR REPLACE SQL SECURITY INVOKER VIEW'):]
  db.execute(stmt.replace('CREATE OR REPLACE SQL SECURITY INVOKER VIEW','CREATE VIEW'))
row=db.execute('SELECT COUNT(*),COUNT(DISTINCT sales_order_id),COUNT(DISTINCT customer_business_id),SUM(line_total),SUM(estimated_promo_discount_value),COUNT(DISTINCT orders_without_currencyrate_key) FROM adventureworks_dw.v_online_sales_cube').fetchone()
assert row[:3]==(4,3,1),row
assert math.isclose(row[3],250) and math.isclose(row[4],18) and row[5]==1,row
assert db.execute("SELECT rate_status FROM adventureworks_dw.v_dim_currency_cube WHERE currency_key=1").fetchone()[0]=='Tanpa referensi kurs'
print('PASS: XML well-formed; 7 dimensions, 7 base measures, 4 calculated members.')
print('PASS: referenced MDX measures/levels checked against XML in both naming sets.')
print('PASS: synthetic view fixture preserves 4 details, deduplicates customer versions, excludes unknown customer, computes discount and distinct unknown orders.')
print('NOT RUN: MySQL/Mondrian/JDBC/MDX engine, actual dump data, or ETL. Static reference checks are not an MDX syntax parser.')
