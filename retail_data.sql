
-- query the SKU/product_id ,customer of retail files for the same product_id

select  sku,customer from PortofolioProject.dbo.Retail_file1 q
join PortofolioProject.dbo.Retail_file2 w
on q.SKU = w.ProductID



--What is the optimum price for each item?
-- price per product

select  (totalsales/quantity) as product_price
From PortofolioProject.dbo.Retail_file2
where Quantity	is not NULL




--query customer_id, total sales per customer
select CustomerID, sum(totalsales) as sales_percustomer From PortofolioProject.dbo.Retail_file2
group by CustomerID;



----Demand prediction for each item on next months.

WITH MonthlySales AS (
	SELECT
        PRODUCTID,
		MONTH(Date) AS sale_month,
        --DATE_TRUNC('month', date) AS sale_month,
        sum(TOTALSALES) as tot
    From PortofolioProject.dbo.Retail_file2
    GROUP BY PRODUCTID, MONTH(Date)
),
ItemAvgDemand AS (
    SELECT
         PRODUCTID,
		 sale_month,
        AVG(tot) OVER (PARTITION BY PRODUCTID ORDER BY sale_month ROWS BETWEEN 2 PRECEDING AND 1 PRECEDING) AS moving_avg_demand
    FROM MonthlySales
)
SELECT
    PRODUCTID,
    DATEADD(month, 1, MAX(sale_month)) AS next_month,
    COALESCE(moving_avg_demand, 0) AS predicted_demand
FROM ItemAvgDemand
WHERE sale_month = (SELECT MAX(sale_month) FROM MonthlySales)
GROUP BY PRODUCTID, moving_avg_demand;




--Customer Lifetime Value for each Customer.

SELECT
    customerid,
    round(SUM(totalsales),2) AS total_purchase_amount,
    COUNT(DISTINCT date) AS total_transactions,
    round(AVG(totalsales),2) AS avg_transaction_amount,
    abs(DATEDIFF(DAY,MAX(date),MIN(date))) AS customer_lifetime_days,
    round(SUM(totalsales) / abs(DATEDIFF(day,MAX(date),MIN(date))),2 )AS historic_clv  --higher historic clv = higher purchases
FROM
    PortofolioProject.dbo.Retail_file2
GROUP BY
    customerid
having abs(DATEDIFF(month,MIN(date),MAX(date))) <> 0
order by historic_clv desc  



-----Customer Segmentation (an easy approach of RFM or more complex segmentations)

SELECT
    customerid,
    DATEDIFF(day,MAX(date), CAST(GETDATE() AS DATE)) AS recency,
    COUNT(DISTINCT date) AS frequency,
    round(SUM(totalsales),2) AS monetary
FROM
	PortofolioProject.dbo.Retail_file2
GROUP BY
    customerid;

--Customer <> Product Recommendation (what are the best products for the customers).

SELECT
    customerid,
    productid,
    COUNT(*) AS purchase_count
FROM
    PortofolioProject.dbo.Retail_file2
WHERE
    customerid = '456' -- Replace with the customer ID for whom recommendations are needed
GROUP BY
    customerid,
    productid
ORDER BY
    purchase_count DESC
