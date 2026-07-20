# SCD Araştırma Notu

## 1. SCD Nedir?

SCD, Slowly Changing Dimension ifadesinin kısaltmasıdır.

Türkçede "Yavaş Değişen Boyut" olarak ifade edilir.

Dimension tablolarındaki müşteri adresi, müşteri segmenti, ürün
kategorisi veya çalışan departmanı gibi bilgilerin zaman içinde
değişmesini yönetmek için kullanılan yöntemlerdir.

Örneğin bir müşteri başlangıçta Standard segmentinde olabilir:

- Customer ID: 13085
- Segment: Standard

Müşteri daha sonra Premium segmentine geçebilir:

- Customer ID: 13085
- Segment: Premium

Bu değişiklik karşısında eski değerin silinip silinmeyeceği veya
tarihsel olarak korunup korunmayacağı kullanılan SCD tipine bağlıdır.

---

## 2. SCD Type 0

SCD Type 0 yönteminde bir dimension alanı ilk kez kaydedildikten sonra
değiştirilmez.

İlk değer kalıcı olarak korunur.

### Örnek

İlk kayıt:

| customer_id | registration_country |
|---|---|
| 13085 | United Kingdom |

Kaynak sistemde daha sonra ülke bilgisi değişse bile dimension
tablosundaki ilk değer korunur.

### Ne Zaman Kullanılır?

- Doğum tarihi
- İlk kayıt tarihi
- İlk müşteri kazanım kanalı
- Değişmemesi gereken tarihsel bilgiler

### Avantajı

İlk kayıt hiçbir zaman kaybolmaz.

### Dezavantajı

Kaynak sistemde yapılan düzeltmeler dimension tablosuna yansımaz.

---

## 3. SCD Type 1

SCD Type 1 yönteminde eski değer yeni değerle değiştirilir.

Eski bilgi saklanmaz ve tarihsel geçmiş kaybolur.

### Değişiklikten Önce

| customer_sk | customer_id | country |
|---:|---:|---|
| 1 | 13085 | United Kingdom |

### Değişiklikten Sonra

| customer_sk | customer_id | country |
|---:|---:|---|
| 1 | 13085 | France |

Eski `United Kingdom` değeri silinmiş olur.

### Ne Zaman Kullanılır?

- Yazım hatalarının düzeltilmesi
- Yanlış girilmiş e-posta adresinin düzeltilmesi
- Tarihsel olarak takip edilmesi gerekmeyen alanlar
- Her zaman yalnızca güncel değerin önemli olduğu durumlar

### Avantajı

Uygulanması kolaydır ve tabloda ek satır oluşturmaz.

### Dezavantajı

Eski değer saklanmadığı için geçmişe dönük analiz yapılamaz.

---

## 4. SCD Type 2

SCD Type 2 yönteminde değişiklik olduğunda mevcut satırın üzerine
yazılmaz. Bunun yerine aynı business key için yeni bir dimension
satırı oluşturulur.

Her tarihsel versiyon farklı bir surrogate key alır.

### Değişiklikten Önce

| customer_sk | customer_id | segment | valid_from | valid_to | is_current |
|---:|---:|---|---|---|---|
| 1 | 13085 | Standard | 2026-01-01 | NULL | true |

### Değişiklikten Sonra

| customer_sk | customer_id | segment | valid_from | valid_to | is_current |
|---:|---:|---|---|---|---|
| 1 | 13085 | Standard | 2026-01-01 | 2026-07-20 | false |
| 2 | 13085 | Premium | 2026-07-20 | NULL | true |

`customer_id` aynı kalmıştır fakat müşterinin iki farklı tarihsel
versiyonu farklı `customer_sk` değerleriyle saklanmıştır.

### Ne Zaman Kullanılır?

- Müşteri segmenti değişiklikleri
- Müşteri adresi değişiklikleri
- Çalışanın departman değişiklikleri
- Ürün kategorisi değişiklikleri
- Geçmiş raporların dönemindeki gerçek bilgiyle üretilmesi gereken
  durumlar

### Avantajı

Bütün tarihsel değişiklikler korunur.

Örneğin geçmişte verilen bir sipariş, müşterinin o tarihte bulunduğu
segmente bağlanabilir.

### Dezavantajı

Aynı müşteri için birden fazla satır oluşur. Sorgular ve model yapısı
Type 1'e göre daha karmaşıktır.

### Bu Projede Kullanımı

Bu projede `dim_customer` için SCD Type 2 kullanılacaktır.

Kaynak veri setinde müşteri segmenti bulunmadığı için kontrollü olarak
bir `customer_segment` alanı oluşturulacaktır.

Bir müşterinin segmenti önce `Standard`, daha sonra `Premium` olarak
değiştirilecektir.

dbt snapshot iki farklı versiyonu tarihsel olarak saklayacaktır.

Takip edilecek temel alanlar:

- valid_from
- valid_to
- is_current

---

## 5. SCD Type 3

SCD Type 3 yönteminde mevcut değerle birlikte sınırlı sayıda eski
değer aynı satırda tutulur.

Yeni bir satır oluşturmak yerine yeni kolonlar kullanılır.

### Değişiklikten Önce

| customer_id | current_segment | previous_segment |
|---:|---|---|
| 13085 | Standard | NULL |

### Değişiklikten Sonra

| customer_id | current_segment | previous_segment |
|---:|---|---|
| 13085 | Premium | Standard |

### Ne Zaman Kullanılır?

- Yalnızca bir önceki değerin önemli olduğu durumlar
- Mevcut ve önceki organizasyon yapısının karşılaştırılması
- Sınırlı tarihsel karşılaştırma gereken raporlar

### Avantajı

Type 2 gibi çok sayıda satır oluşturmaz.

Mevcut ve önceki değer kolayca karşılaştırılabilir.

### Dezavantajı

Sadece sınırlı geçmiş saklanır.

Bir müşteri üç veya daha fazla kez segment değiştirdiyse bütün geçmiş
korunamaz.

---

## 6. SCD Tiplerinin Karşılaştırılması

| SCD Tipi | Eski Değer Korunur mu? | Yeni Satır Oluşur mu? | Temel Kullanım |
|---|---|---|---|
| Type 0 | İlk değer korunur | Hayır | Hiç değişmemesi gereken alanlar |
| Type 1 | Hayır | Hayır | Düzeltme ve yalnızca güncel değer |
| Type 2 | Evet, tüm geçmiş | Evet | Tam tarihsel değişiklik takibi |
| Type 3 | Evet, sınırlı geçmiş | Hayır | Mevcut ve önceki değeri karşılaştırma |

---

## 7. Proje İçin Seçilen Yöntem

Bu projede müşteri değişiklikleri için SCD Type 2 seçilmiştir.

Bunun nedenleri:

1. Müşterinin geçmiş segmentlerinin kaybolmaması gerekir.
2. Eski siparişlerin müşterinin o tarihteki segmentiyle
   ilişkilendirilebilmesi gerekir.
3. Aynı customer_id için birden fazla tarihsel versiyon saklanmalıdır.
4. Her tarihsel versiyona farklı bir customer_sk verilmelidir.
5. dbt snapshot, Type 2 yapısını uygulamak için uygundur.