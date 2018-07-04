/*
--重新設定商品庫存資訊
DELETE FROM [Products].[ProductStorages]
GO

INSERT INTO [Products].[ProductStorages] ([ProductNo],[Storage])
	VALUES (1,75),(2,150),(3,125)
GO
*/

--取得指定商品型號的有效庫存
ALTER FUNCTION [Products].[GetProductValidStorage]
(
	@Schema			VARCHAR(15)
)
RETURNS SMALLINT
AS
BEGIN
	/*
	    從商品庫存 Products.ProductStorages 資料表中取得可銷售庫存
	*/
	DECLARE @ProductNo		INT
	DECLARE @ProductStorage	SMALLINT
	DECLARE @OrderStorage	SMALLINT
	DECLARE @Storage		SMALLINT
	
	SET @ProductNo = (
		SELECT [No] FROM [Products].[ProductMains]
		WHERE [Schema] = @Schema
	)
	
	IF @ProductNo IS NULL
	BEGIN
		RETURN (0)
	END	
	
	SET @ProductStorage = (
		SELECT [Storage] FROM [Products].[ProductStorages]
		WHERE [ProductNo] = @ProductNo
	)

    RETURN @ProductStorage
END
GO

ALTER PROCEDURE [Orders].[AddOrder]
	@MemberGUID		UNIQUEIDENTIFIER,
	@Items 			[Orders].[OrderDetails] READONLY,
	@IsSuccess		BIT OUT
AS
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		DECLARE @OrderNo INT
		DECLARE @Schema CHAR(15)
		DECLARE @output TABLE (
			[ProductNo]		INT PRIMARY KEY,
			[AfterStorage]	SMALLINT
		)
		
		SET @IsSuccess = 0
		
        --直接更新指定商品庫存
		UPDATE [Products].[ProductStorages]
			SET [Storage] = ([Storage] - [Quantity])
		OUTPUT deleted.[ProductNo]
			,inserted.[Storage]
		INTO @output
			FROM [Products].[ProductStorages] a 
				INNER JOIN @Items b ON a.[ProductNo] = b.[ProductNo]
		
		--若有商品庫存量小於購買數量
		--	取消此筆交易
		IF EXISTS(
			SELECT [ProductNo] 
			FROM @output 
			WHERE [AfterStorage] < 0
		)
		BEGIN
			ROLLBACK
		
			RETURN
		END
					
        --取得訂單建立序號
		SET @OrderNo = NEXT VALUE FOR [Orders].[OrderMainSeq]
        EXEC [Orders].[GetOrderSchema] @Schema OUT
	
        --新增訂單內容
		INSERT INTO [Orders].[OrderMains] (
			[No]
            ,[Schema]
			,[MemberGUID]
			,[IsDeleted]
		) VALUES (
			@OrderNo
            ,@Schema
			,@MemberGUID
			,0
		)
		
		INSERT INTO [Orders].[OrderDetails] (
			[OrderNo]
			,[ProductNo]
			,[SellPrice]
			,[Quantity]
		) SELECT @OrderNo
			,[ProductNo]
			,[SellPrice]
			,[Quantity]
		FROM @Items	

		SET @IsSuccess = 1	
	
		COMMIT
	END TRY
	
	BEGIN CATCH	
		ROLLBACK
		
		EXEC [Events].[AddEventDatabaseError] 
		
		SET @IsSuccess = 0
	END CATCH
GO