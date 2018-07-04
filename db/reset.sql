/* 重設相關物件與資料表內容的 T-SQL */

--重新設定商品庫存資訊
DELETE FROM [Products].[ProductStorages]
GO

INSERT INTO [Products].[ProductStorages] ([ProductNo],[Storage])
	VALUES (1,75),(2,150),(3,125)
GO

--清除已經新增的訂單資料表
DELETE FROM [Orders].[OrderDetails]
GO

DELETE FROM [Orders].[OrderMains]
GO

--清除事件紀錄資料表
TRUNCATE TABLE [Events].[EventBuying]
GO

TRUNCATE TABLE [Events].[EventDatabaseErrorLog]
GO

--重設訂單主索引鍵序列
ALTER SEQUENCE [Orders].[OrderMainSeq]
	RESTART WITH 1
GO

--重設訂單代碼流水序號使用序列
ALTER SEQUENCE [Orders].[OrderSchemaSeq]
    RESTART WITH 1
GO