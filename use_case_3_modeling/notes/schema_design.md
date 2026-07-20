# Use Case 3 — Şema Tasarım Kararları

## Projenin Amacı

Bu projede ham e-ticaret sipariş verisi, analiz ve raporlama için
uygun bir star schema yapısına dönüştürülecektir.

Merkezde `fact_orders`, çevresinde ise `dim_customer`,
`dim_product` ve `dim_date` tabloları bulunacaktır.

## Fact Tablosunun Grain'i

`fact_orders` tablosundaki her satır, bir faturadaki tek bir ürün
satırını temsil eder.

Bir faturada birden fazla ürün olabileceği için aynı fatura numarası
fact tablosunda birden fazla satırda bulunabilir.

## Fact Orders

Fact tablosunda şu ölçüler bulunacaktır:

- quantity
- unit_price
- line_amount

`line_amount` şu şekilde hesaplanacaktır:

quantity * unit_price

Fact tablosu şu dimension tablolarına bağlanacaktır:

- customer_sk
- product_sk
- date_sk

Fatura numarası ayrıca bir dimension tablosu oluşturulmadan doğrudan
fact tablosunda tutulacaktır.

## Customer Dimension

`dim_customer` müşteri bilgilerini tutacaktır.

Kaynak sistemdeki doğal anahtar `customer_id`, veri ambarında
oluşturulan yapay anahtar ise `customer_sk` olacaktır.

Customer ID değeri bulunmayan satışlar silinmeyecektir. Bu satışlar
`customer_sk = -1` olan Unknown Customer kaydına bağlanacaktır.

Müşteri değişiklikleri SCD Type 2 yöntemiyle takip edilecektir.

## Product Dimension

`dim_product` ürün bilgilerini tutacaktır.

Doğal anahtar `stock_code`, yapay anahtar ise `product_sk` olacaktır.

Ürün açıklaması `product_name` adıyla standartlaştırılacaktır.

## Date Dimension

`dim_date`, fatura tarihinden türetilen takvim bilgilerini tutacaktır.

Temel alanlar:

- date_sk
- full_date
- year
- quarter
- month_number
- month_name
- week_number
- day_name
- is_weekend

## İptal ve İade Kararı

`C` ile başlayan faturalar iptal faturası olarak işaretlenecektir.

Ancak negatif miktarlı bazı kayıtlar `C` ile başlamadığı için iki ayrı
alan kullanılacaktır:

- is_cancellation_invoice
- is_negative_quantity

Negatif miktarlı kayıtlar silinmeyecektir. Böylece satış, iade ve net
gelir ayrı ayrı hesaplanabilecektir.

## Duplicate Kararı

Kaynak veride benzersiz bir invoice line ID bulunmamaktadır.

Bütün kaynak kolonları aynı olan kayıtlar exact duplicate olarak kabul
edilecektir. Her duplicate grubunda ilk kayıt tutulacak, diğer kayıtlar
staging aşamasında kaldırılacaktır.

Bu karar üretim ortamında kaynak sistem sahibiyle doğrulanmalıdır.

## Fiyat Kararı

Sıfır veya negatif fiyatlı kayıtlar doğrudan silinmeyecektir.

Bu kayıtlar hasarlı ürün, kayıp stok veya operasyonel düzeltme olabilir.
Bu nedenle `is_non_positive_price` alanıyla işaretlenecektir.

## Profiling Sonuçları

- Toplam satır: 1.067.371
- Farklı fatura: 53.628
- Farklı ürün: 5.305
- Farklı müşteri: 5.942
- Customer ID boş satır: 243.007
- Negatif miktarlı satır: 22.950
- C ile başlayan iptal satırı: 19.494
- C ile başlamayan negatif miktarlı satır: 3.457
- Fazladan exact duplicate satır: 34.335
- Tarih aralığı: 2009-12-01 ile 2011-12-09
