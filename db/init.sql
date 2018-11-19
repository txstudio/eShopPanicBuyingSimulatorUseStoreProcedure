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
ALTER DATABASE [eShop]
	SET ALLOW_SNAPSHOT_ISOLATION ON
GO

--啟用 READ_COMMITTED_SNAPSHOT
ALTER DATABASE [eShop]
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
	VALUES (1,75),(2,150),(3,125)
GO

--訂單資料表主索引鍵使用序列
CREATE SEQUENCE [Orders].[OrderMainSeq]
	START WITH 1
	INCREMENT BY 1
GO

--訂單代碼流水序號使用的序列
CREATE SEQUENCE [Orders].[OrderSchemaSeq]
    START WITH 1
    INCREMENT BY 1
GO

--取得新一筆訂單要儲存的訂單編號 (yyyyMMdd9999999)
CREATE PROCEDURE [Orders].[GetOrderSchema]
    @Schema     CHAR(15) OUT
AS
    DECLARE @NewCode CHAR(8)
	DECLARE @Identity INT

	SET @NewCode = CONVERT(VARCHAR,GETDATE(),112)
    SET @Identity = NEXT VALUE FOR [Orders].[OrderSchemaSeq]

	SET @Schema = (@NewCode + RIGHT('000000'+CONVERT(VARCHAR(7),@Identity),7))
GO

--訂單主資料表
CREATE TABLE [Orders].[OrderMains]
(
	[No]			INT,
	[Schema]		CHAR(15),
    [OrderDate]     DATETIMEOFFSET DEFAULT (SYSDATETIMEOFFSET()),
	
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
    [EventTime]     DATETIMEOFFSET DEFAULT (SYSDATETIMEOFFSET()),

    [MemberGUID]    UNIQUEIDENTIFIER,
    [Content]       NVARCHAR(500),
	[Elapsed]		INT,
    [IsSuccess]     BIT,

    CONSTRAINT [pk_EventBuying] PRIMARY KEY ([No])
)
GO

--儲存預存程序錯誤的事件紀錄資料表
CREATE TABLE [Events].[EventDatabaseErrorLog] (
	[No]                INT IDENTITY(1, 1),
	[ErrorTime]         DATETIME DEFAULT (SYSDATETIMEOFFSET()),
	[ErrorDatabase]     NVARCHAR(100),
	[LoginName]         NVARCHAR(100),
	[UserName]          NVARCHAR(128),
	[ErrorNumber]       INT,
	[ErrorSeverity]     INT,
	[ErrorState]        INT,
	[ErrorProcedure]    NVARCHAR(130),
	[ErrorLine]         INT,
	[ErrorMessage]      NVARCHAR(MAX),
	
    CONSTRAINT [pk_EventDatabaseErrorLog] PRIMARY KEY ([No] ASC)
)
GO



/* 新增一筆購買紀錄的 StoredProcedure */
CREATE PROCEDURE [Events].[AddEventBuying]
    @MemberGUID     UNIQUEIDENTIFIER,
    @Content        NVARCHAR(500),
	@Elapsed		INT,
    @IsSuccess      BIT
AS

    INSERT INTO [Events].[EventBuying] (
        [MemberGUID]
        ,[Content]
		,[Elapsed]
        ,[IsSuccess]
    ) VALUES (
        @MemberGUID
        ,@Content
		,@Elapsed
        ,@IsSuccess
    )
GO

CREATE PROCEDURE [Events].[AddEventDatabaseError] 
    @No INT = 0 OUTPUT
AS
    DECLARE @seed INT

    SET NOCOUNT ON

    BEGIN TRY
        IF ERROR_NUMBER() IS NULL
        BEGIN
            RETURN
        END

        --
        --如果有進行中的交易正在使用時不進行記錄
        -- (尚未 rollback 或 commit)
        --
        IF XACT_STATE() = (- 1)
        BEGIN
            RETURN
        END

        INSERT INTO [Events].[EventDatabaseErrorLog] (
            [ErrorDatabase]
            ,[LoginName]
            ,[UserName]
            ,[ErrorNumber]
            ,[ErrorSeverity]
            ,[ErrorState]
            ,[ErrorProcedure]
            ,[ErrorLine]
            ,[ErrorMessage]
            )
        VALUES (
            CONVERT(NVARCHAR(100), DB_NAME())
            ,CONVERT(NVARCHAR(100), SYSTEM_USER)
            ,CONVERT(NVARCHAR(128), CURRENT_USER)
            ,ERROR_NUMBER()
            ,ERROR_SEVERITY()
            ,ERROR_STATE()
            ,ERROR_PROCEDURE()
            ,ERROR_LINE()
            ,ERROR_MESSAGE()
            )
    END TRY

    BEGIN CATCH
        RETURN (- 1)
    END CATCH
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

--重設訂單流水號序列 ex: 每天重設
CREATE PROCEDURE [Orders].[ResetOrderSchemaSeq]
AS
    ALTER SEQUENCE [Orders].[OrderSchemaSeq]
    RESTART WITH 1
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
