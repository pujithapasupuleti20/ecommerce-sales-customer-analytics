# E-Commerce Sales & Customer Analytics

An end-to-end portfolio project using **MySQL** and **Power BI** to analyze e-commerce sales, orders, customers, products, payments, deliveries, and returns.

## Project objectives
- Analyze total revenue, order volume, and average order value (AOV).
- Understand delivered, cancelled, and returned order patterns.
- Compare revenue by state, city, product category, customer gender, sales channel, and payment method.
- Explore discount-level sales/AOV, product performance, stock risk, delivery duration, and return reasons.
- Analyze payment status and customer repeat purchasing.

## Tools
- MySQL / MySQL Workbench
- Power BI Desktop
- GitHub

## Data model
The SQL script creates six tables: `customers`, `products`, `orders`, `payments`, `order_items`, and `returns`.

**Grain matters:** `orders` is one row per order, while `order_items` may contain multiple rows per order. Use `orders.total_payable` for order-level revenue and `order_items.line_total` for product/category revenue. Avoid summing order-level revenue after joining to multiple order-item rows.

## Regional finding
**Reported project finding:** Andhra Pradesh was identified during the project analysis as the highest-performing state for orders and revenue. The SQL script includes state-level revenue/order queries and category analyses for Andhra Pradesh and Telangana. The SQL file contains the queries but not the result grids, so insert the exact AP order and revenue figures from the final query outputs before publishing.

For the AP/Telangana category query, use `COUNT(DISTINCT o.order_id)` if the metric is unique orders; a direct `COUNT(o.order_id)` after joining `order_items` can count an order multiple times.

## SQL analysis included
- Total and monthly sales; growth calculations
- Delivered, cancelled, and returned rates
- Revenue by category, city, state, sales channel, and gender
- Customer segments, repeat purchasing, and customers who never ordered
- Delivery time and monthly deliveries
- Top products and low-stock products
- Payment status/success and payment method analysis
- Return reasons and discount-level sales/AOV

## Power BI dashboard
The report includes KPI cards for Total Revenue, Total Orders, AOV, Delivered Rate, Cancellation Rate, and Return Rate; Year, Category, and State slicers; yearly revenue trend; order-status distribution; revenue by category, gender, state, payment status, and payment method; and a Top 10 Products table.

Add a clean exported dashboard image named `dashboard_preview.png`, then uncomment:
<!-- ![Power BI dashboard](dashboard_preview.png) -->

## Previously reported metrics — validate before publication
| Metric | Reported value |
|---|---:|
| Total orders | 60,000 |
| Total order revenue | Approximately 24.09M |
| AOV | Approximately 401.45 |
| Delivered orders | 41,960 (approximately 69.93%) |
| Cancelled orders | 3,689 (approximately 6.15%) |
| Returned orders | 2,374 (approximately 3.96%) |
| Delivered revenue | Approximately 16.86M (about 70.01% of reported order revenue) |
| Payment success rate | 82.48%; validate denominator |
| Hyderabad Electronics revenue | 618,000 reported; verify query grain/definition |

Discount AOV values previously reported were 443.12 at 0%, 426.85 at 5%, 405.09 at 10%, 385.31 at 15%, and 365.43 at 20%. This is an association, not proof of causation.

The inventory analysis previously flagged Yoga Mat Classic (stock 0; 76 historical delivered units sold) and Headphones Pro (stock 5; 81 historical delivered units sold). Treat these as possible replenishment signals, not demand forecasts.

## SQL validation notes
Before publishing, check:
1. Do not sum `orders.total_payable` after a one-to-many join to `order_items`.
2. Use `COUNT(DISTINCT order_id)` for unique order counts after joining order items.
3. Avoid reporting growth from a zero previous-month value as a meaningful percentage.
4. Remove ungrouped `order_status` from the Top 10 product query, and sort by revenue if the visual is titled Top 10 by Revenue.
5. Prevent duplicated order revenue when joining to multiple payment records.
6. Define whether delivery time is item-level or order-level.
7. Define repeat purchase rate denominator clearly.

## Recommendations
- Investigate cancellations and returns by channel, payment method, and shipping type.
- Compare category mix across Andhra Pradesh, Telangana, and other states using final outputs.
- Review low-stock items alongside recent sales and supplier lead time.
- Evaluate discount effectiveness using margin and conversion as well as AOV.
- Monitor payment failures and repeat purchasing with clear metric definitions.

## Repository structure
```text
ecommerce-sales-customer-analytics/
├── README.md
├── ecommerce_analysis.sql
├── Ecommerce_Sales_Customer_Analytics_Corrected_Insights.pdf
├── ecommerce_dashboard.pbix
└── dashboard_preview.png
```

## Data privacy
Do not commit passwords, credentials, or private customer information. Only publish data you are authorized to share. Check the PBIX file for embedded sensitive data before making the repository public.
