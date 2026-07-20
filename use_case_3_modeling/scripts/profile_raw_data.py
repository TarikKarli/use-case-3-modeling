from pathlib import Path

import duckdb


# Bu Python dosyasının bulunduğu konumu alır.
SCRIPT_PATH = Path(__file__).resolve()

# scripts klasörünün bir üstü dbt proje klasörümüzdür.
PROJECT_DIR = SCRIPT_PATH.parent.parent

# Ham CSV dosyasının tam yolunu oluşturur.
CSV_PATH = PROJECT_DIR / "data" / "raw" / "online_retail.csv"


def main() -> None:
    """Ham Online Retail CSV dosyasının temel veri profilini çıkarır."""

    if not CSV_PATH.exists():
        raise FileNotFoundError(
            f"CSV dosyası bulunamadı: {CSV_PATH}"
        )

    file_size_mb = CSV_PATH.stat().st_size / (1024 * 1024)

    print("=" * 60)
    print("DOSYA BİLGİSİ")
    print("=" * 60)
    print(f"Dosya yolu : {CSV_PATH}")
    print(f"Dosya boyutu: {file_size_mb:.2f} MB")

    # :memory: geçici DuckDB veritabanı oluşturur.
    # Script kapanınca bu bağlantı da kapanır.
    connection = duckdb.connect(database=":memory:")

    # Windows yolundaki ters slash sorunlarını önlemek için
    # yolu standart slash biçimine çeviriyoruz.
    csv_path_sql = CSV_PATH.as_posix()

    raw_data = f"""
        read_csv_auto(
            '{csv_path_sql}',
            header = true,
            sample_size = 100000
        )
    """

    print("\n" + "=" * 60)
    print("KOLONLAR VE VERİ TİPLERİ")
    print("=" * 60)

    schema = connection.execute(
        f"DESCRIBE SELECT * FROM {raw_data}"
    ).fetchdf()

    print(schema.to_string(index=False))

    print("\n" + "=" * 60)
    print("İLK 5 SATIR")
    print("=" * 60)

    preview = connection.execute(
        f"SELECT * FROM {raw_data} LIMIT 5"
    ).fetchdf()

    print(preview.to_string(index=False))

    print("\n" + "=" * 60)
    print("GENEL İSTATİSTİKLER")
    print("=" * 60)

    statistics = connection.execute(
        f"""
        SELECT
            COUNT(*) AS total_row_count,

            COUNT(*) FILTER (
                WHERE "Customer ID" IS NULL
            ) AS null_customer_count,

            COUNT(*) FILTER (
                WHERE Description IS NULL
            ) AS null_description_count,

            COUNT(*) FILTER (
                WHERE Quantity <= 0
            ) AS non_positive_quantity_count,

            COUNT(*) FILTER (
                WHERE Price <= 0
            ) AS non_positive_price_count,

            COUNT(DISTINCT Country)
                AS distinct_country_count,

            MIN(InvoiceDate)
                AS minimum_invoice_date,

            MAX(InvoiceDate)
                AS maximum_invoice_date

        FROM {raw_data}
        """
    ).fetchdf()

    print(statistics.to_string(index=False))

    connection.close()


if __name__ == "__main__":
    main()