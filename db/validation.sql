/*
    驗證商品目前庫存量與訂單總計每筆商品庫存量的查詢
        若商品庫存量 < 訂單總計每筆商品庫存量 = 有超賣的情勢
*/
;WITH [OrderTable] AS (
	SELECT b.[No]
		,b.[Schema]
		,b.[Name]
		,SUM(a.[Quantity]) [TotalOrderQuantity]
	FROM [Orders].[OrderDetails] a
		INNER JOIN [Products].[ProductMains] b ON a.[ProductNo] = b.[No]
	GROUP BY b.[No]
		,b.[Schema]
		,b.[Name]
)
SELECT a.[No]
	,a.[Schema]
	,a.[Name]
	,b.[Storage]
	,a.[TotalOrderQuantity]
FROM [OrderTable] a
	INNER JOIN [Products].[ProductStorages] b 
		ON a.[No] = b.[ProductNo]
ORDER BY a.[No] ASC