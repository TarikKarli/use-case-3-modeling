from pathlib import Path

import duckdb


SCRIPT_PATH = Path(__file__).resolve()
PROJECT_DIR = SCRIPT_PATH.parent.parent
CSV_PATH = PROJECT_DIR / "data" / "raw" / "online_retail.csv"


def print_section(title: str) -> None:
    """Terminal çıktısında okunabilir bölüm başlığı oluşturur."""

    print("\n" + "=" * 80)
    print(title)
    print("=" * 80)


def main() -> None:
    """Ham verideki temel iş kurallarını ve anormallikleri inceler."""

    if not CSV_PATH.exists():
        raise FileNotFoundError(f"CSV dosyası bulunamadı: {CSV_PATH}")

    connection = duckdb.connect(database=":memory:")
    csv_path_sql = CSV_PATH.as_posix()

    raw_data = f"""
        read_csv_auto(
            '{csv_path_sql}',
            header = true,
            sample_size = 100000
        )
    """

    print_section("İŞ VARLIĞI SAYILARI")

    entity_counts = connection.execute(
        f"""
        SELECT
            COUNT(*) AS total_row_count,
            COUNT(DISTINCT Invoice) AS distinct_invoice_count,
            COUNT(DISTINCT StockCode) AS distinct_product_count,
            COUNT(DISTINCT "Customer ID") AS distinct_customer_count
        FROM {raw_data}
        """
    ).fetchdf()

    print(entity_counts.to_string(index=False))

    print_section("TEMEL NULL KONTROLÜ")

    null_counts = connection.execute(
        f"""
        SELECT
            COUNT(*) FILTER (
                WHERE Invoice IS NULL
            ) AS null_invoice_count,

            COUNT(*) FILTER (
                WHERE StockCode IS NULL
            ) AS null_stock_code_count,

            COUNT(*) FILTER (
                WHERE InvoiceDate IS NULL
            ) AS null_invoice_date_count,

            COUNT(*) FILTER (
                WHERE Country IS NULL
            ) AS null_country_count
        FROM {raw_data}
        """
    ).fetchdf()

    print(null_counts.to_string(index=False))

    print_section("İPTAL FATURASI ANALİZİ")

    cancellation_analysis = connection.execute(
        f"""
        SELECT
            COUNT(*) FILTER (
                WHERE UPPER(CAST(Invoice AS VARCHAR)) LIKE 'C%'
            ) AS cancellation_row_count,

            COUNT(DISTINCT Invoice) FILTER (
                WHERE UPPER(CAST(Invoice AS VARCHAR)) LIKE 'C%'
            ) AS cancellation_invoice_count,

            COUNT(*) FILTER (
                WHERE Quantity < 0
            ) AS negative_quantity_count,

            COUNT(*) FILTER (
                WHERE Quantity < 0
                  AND UPPER(CAST(Invoice AS VARCHAR)) LIKE 'C%'
            ) AS negative_quantity_with_c_invoice_count,

            COUNT(*) FILTER (
                WHERE Quantity < 0
                  AND UPPER(CAST(Invoice AS VARCHAR)) NOT LIKE 'C%'
            ) AS negative_quantity_without_c_invoice_count
        FROM {raw_data}
        """
    ).fetchdf()

    print(cancellation_analysis.to_string(index=False))

    print_section("DUPLICATE SATIR ANALİZİ")

    duplicate_analysis = connection.execute(
        f"""
        WITH grouped_rows AS (
            SELECT
                Invoice,
                StockCode,
                Description,
                Quantity,
                InvoiceDate,
                Price,
                "Customer ID",
                Country,
                COUNT(*) AS occurrence_count
            FROM {raw_data}
            GROUP BY
                Invoice,
                StockCode,
                Description,
                Quantity,
                InvoiceDate,
                Price,
                "Customer ID",
                Country
            HAVING COUNT(*) > 1
        )

        SELECT
            COUNT(*) AS duplicate_group_count,
            COALESCE(
                SUM(occurrence_count - 1),
                0
            ) AS extra_duplicate_row_count
        FROM grouped_rows
        """
    ).fetchdf()

    print(duplicate_analysis.to_string(index=False))

    print_section("SIFIR VE NEGATİF FİYAT ÖRNEKLERİ")

    price_examples = connection.execute(
        f"""
        SELECT
            Invoice,
            StockCode,
            Description,
            Quantity,
            Price,
            "Customer ID",
            Country
        FROM {raw_data}
        WHERE Price <= 0
        LIMIT 20
        """
    ).fetchdf()

    print(price_examples.to_string(index=False))

    print_section("NEGATİF QUANTITY ÖRNEKLERİ")

    quantity_examples = connection.execute(
        f"""
        SELECT
            Invoice,
            StockCode,
            Description,
            Quantity,
            Price,
            "Customer ID",
            Country
        FROM {raw_data}
        WHERE Quantity < 0
        LIMIT 20
        """
    ).fetchdf()

    print(quantity_examples.to_string(index=False))

    connection.close()


if __name__ == "__main__":
    main()