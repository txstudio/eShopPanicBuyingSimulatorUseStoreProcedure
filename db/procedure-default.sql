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
	取得商品目前庫存	
	取得訂單的庫存	
	
	目前庫存減訂單庫存 = 可銷售數量
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
	
	SET @OrderStorage = (
		SELECT SUM([Quantity]) FROM [Orders].[OrderDetails]
		WHERE [ProductNo] = @ProductNo
	)
	
	SET @Storage = ISNULL(@ProductStorage,0) - ISNULL(@OrderStorage,0)
	
	IF @Storage > 0
	BEGIN
		RETURN @Storage
	END
	
	RETURN 0
END
GO

ALTER PROCEDURE [Orders].[AddOrder]
	@MemberGUID		UNIQUEIDENTIFIER,
	@Items 			[Orders].[OrderDetails] READONLY,
	@IsSuccess		BIT OUT
AS

	--超賣
	--不指定 ISOLATION LEVEL
	--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    --SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    --SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	--SET TRANSACTION ISOLATION LEVEL SNAPSHOT
    
	--不會超賣 - 速度超慢
	--SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
	
	BEGIN TRY
		BEGIN TRANSACTION
		
		DECLARE @OrderNo INT
		DECLARE @Schame CHAR(15)
		
		SET @IsSuccess = 0
		
		--只要有一筆商品庫存量小於購買數量
		--	取消此筆交易
		IF EXISTS( 
			SELECT a.[ProductNo]
			FROM @Items a
				INNER JOIN [Products].[ProductMains] b ON a.[ProductNo] = b.[No]
			WHERE (
				(SELECT [Products].[GetProductValidStorage](b.[Schema])) - a.[Quantity]
			) < 0
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
			,@Schame
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