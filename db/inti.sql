/*
--將既有 eShop 資料庫移除的指令碼
EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'eShop'
GO

USE [master]
GO

ALTER DATABASE [eShop]
	SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO

USE [master]
GO

DROP DATABASE [eShop]
GO
*/

/*
    建立 eShop 範例資料庫需要的資料表與預設資料內容
*/
CREATE DATABASE [eShop]
GO

/*
	此設定與 Azure SQL Database 相同
	https://blogs.msdn.microsoft.com/sqlcat/2013/12/26/be-aware-of-the-difference-in-isolation-levels-if-porting-an-application-from-windows-azure-sql-db-to-sql-server-in-windows-azure-virtual-machine/
*/

--啟用 SNAPSHOT_ISOLATION
ALTER DATABASE eShop  
	SET ALLOW_SNAPSHOT_ISOLATION ON
GO

--啟用 READ_COMMITTED_SNAPSHOT
ALTER DATABASE eShop  
	SET READ_COMMITTED_SNAPSHOT ON
	WITH ROLLBACK IMMEDIATE
GO

USE [eShop]
GO

CREATE SCHEMA [Products]
GO

CREATE SCHEMA [Orders]
GO

CREATE SCHEMA [Events]
GO

--商品資料表
CREATE TABLE [Products].[ProductMains]
(
	[No]			INT,
	[Schema]		VARCHAR(15),
	[Name]			NVARCHAR(50),
	[SellPrice]		SMALLMONEY,
	
	CONSTRAINT [pk_Products_ProductMains] PRIMARY KEY ([No]),
	
	CONSTRAINT [un_Products_ProductMains_Schema] UNIQUE ([Schema])
)
GO

INSERT INTO [Products].[ProductMains] ([No],[Schema],[Name],[SellPrice])
VALUES 
	(1,'DYAJ93A900930IK',N'Microsoft Surface Pro (Core i7/16G/256G/W10P)',70888)
	,(2,'DYAJ93A900929IK',N'Microsoft Surface Pro (Core i5/8G/128G/W10P)',51888)
	,(3,'DYAJ93A900928IK',N'Microsoft Surface Pro (Core i3/4G/128G/W10P)',41888)
GO

--商品庫存資料表
CREATE TABLE [Products].[ProductStorages]
(
	[ProductNo]		INT,
	[Storage]		SMALLINT,
	
	CONSTRAINT [pk_ProductStorages] PRIMARY KEY ([ProductNo]),
	
	CONSTRAINT [fk_ProductStorages_ProductNo] FOREIGN KEY ([ProductNo])
		REFERENCES [Products].[ProductMains]([No]) 
			ON DELETE NO ACTION 
			ON UPDATE NO ACTION
)
GO

INSERT INTO [Products].[ProductStorages] ([ProductNo],[Storage])
	VALUES (1,15),(2,30),(3,25)
GO

--訂單資料表主索引鍵使用序列
CREATE SEQUENCE [Orders].[OrderMainSeq]
	START WITH 1
	INCREMENT BY 1
GO

--訂單主資料表
CREATE TABLE [Orders].[OrderMains]
(
	[No]			INT,
	[Schema]		CHAR(15),
	
	[MemberGUID]	UNIQUEIDENTIFIER,
	[IsDeleted]		BIT,
	
	CONSTRAINT [pk_OrderMains] PRIMARY KEY ([No]),
	
	CONSTRAINT [un_OrderMains_Schema] UNIQUE ([Schema])
)

--詳細訂單資料：訂購數量與單價
CREATE TABLE [Orders].[OrderDetails]
(
	[OrderNo]		INT,
	[ProductNo]		INT,
	
	[SellPrice]		SMALLMONEY,
	[Quantity]		SMALLINT,
	
	CONSTRAINT [pk_OrderDetails] PRIMARY KEY ([OrderNo],[ProductNo]),
	
	CONSTRAINT [fk_OrderDetails_OrderNo] FOREIGN KEY ([OrderNo])
		REFERENCES [Orders].[OrderMains] ([No]) 
			ON DELETE NO ACTION 
			ON UPDATE NO ACTION,
			
	CONSTRAINT [fk_OrderDetails_ProductNo] FOREIGN KEY ([ProductNo])
		REFERENCES [Products].[ProductMains] ([No]) 
			ON DELETE NO ACTION 
			ON UPDATE NO ACTION
)
GO

--事件紀錄資料表
CREATE TABLE [Events].[EventBuying]
(
    [No]            INT IDENTITY(1,1),

    [MemberGUID]    UNIQUEIDENTIFIER,
    [Content]       NVARCHAR(500),
    [IsSuccess]     BIT,

    CONSTRAINT [pk_EventBuying] PRIMARY KEY ([No])
)
GO

--取得新一筆訂單要儲存的訂單編號 (yyyyMMdd9999999)
CREATE FUNCTION [Orders].[GetOrderSchema]()
	RETURNS CHAR(15)
AS
BEGIN
	DECLARE @Schema CHAR(15)
	DECLARE @LastCode CHAR(8)
	DECLARE @LastIdentity CHAR(7)
	DECLARE @NewCode CHAR(8)
	DECLARE @Identity INT

	-- SET @Schema = (
		-- SELECT TOP(1) [Schema] FROM [Orders].[OrderMains]
		-- ORDER BY [No] DESC
	-- )
	SET @Schema = (
		SELECT TOP(1) [Schema] 
		FROM [Orders].[OrderMains]
		ORDER BY [Schema] DESC
	)

	SET @NewCode = CONVERT(VARCHAR,GETDATE(),112)
	SET @LastCode = LEFT(@Schema,8)
	SET @LastIdentity = RIGHT(@Schema,7)

	SET @Identity = 0

	If @NewCode = @LastCode 
		SET @Identity = CONVERT(INT,@LastIdentity)

	SET @Identity = @Identity + 1

	RETURN (@NewCode + RIGHT('000000'+CONVERT(VARCHAR(7),@Identity),7))
END
GO

/* 新增一筆購買紀錄的 StoredProcedure */
CREATE PROCEDURE [Events].[AddEventBuying]
    @MemberGUID     UNIQUEIDENTIFIER,
    @Content        NVARCHAR(500),
    @IsSuccess      BIT
AS

    INSERT INTO [Events].[EventBuying] (
        [MemberGUID]
        ,[Content]
        ,[IsSuccess]
    ) VALUES (
        @MemberGUID
        ,@Content
        ,@IsSuccess
    )
GO


/* 預存程序使用自訂資料表型態 */
CREATE TYPE [Orders].[OrderDetails]
	AS TABLE
	(
		[ProductNo]		INT,
		[SellPrice]		SMALLMONEY,
		[Quantity]		SMALLINT
	)
GO

--取得指定商品型號的有效庫存
CREATE FUNCTION [Products].[GetProductValidStorage]
(
	@Schema			VARCHAR(15)
)
RETURNS SMALLINT
AS
BEGIN
	RETURN 0
END
GO

--建立訂單的 StoredProcedure
CREATE PROCEDURE [Orders].[AddOrder]
	@MemberGUID		UNIQUEIDENTIFIER,
	@Items 			[Orders].[OrderDetails] READONLY,
    @OrderSchema    CHAR(15) OUT,
	@IsSuccess		BIT OUT
AS
    SET @IsSuccess = 0

    RETURN
GO