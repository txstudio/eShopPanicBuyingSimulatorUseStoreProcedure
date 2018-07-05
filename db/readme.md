# 資料庫指令碼描述

本範例資料庫建置於 Microsoft SQL Server 2017，使用 Transact-SQL 撰寫

此資料夾包含建立範例資料庫物件、驗證與重設資料所需要的指令碼

|檔名|描述|
|--|--|
|init.sql|初始化資料庫物件|
|procedure-default.sql|建立取得商品庫存量與建立訂單預存程序|
|procedure-correct.sql|建立取得商品庫存量與建立訂單預存程序使用正確的方法|
|reset.sql|重設資料表資料與物件|
|validation.sql|驗證查詢結果是否有商品超賣的查詢|

建立結果圖片請參考

[附件>資料庫物件截圖](#%E9%99%84%E4%BB%B6)

## 建置資料庫環境流程
執行 init.sql 指令碼後依情境執行 procedure-default.sql 或 procedure-correct.sql，在執行完成負載模擬後執行 validation.sql 驗證是否有商品發生超賣情形。

可透過 reset.sql 將商品庫存與訂單狀態重設到初始狀態。


## 重點資料庫物件說明

### 資料表
#### Events.EventBuying
儲存負載模擬後紀錄使用者購買紀錄：是否成功與購買時間

#### Events.EventDatebaseErrorLog
紀錄在預存程序執行錯誤資料表

### 預存程序
#### Orders.AddOrder
建立訂單使用的預存程序，依情境會有不同的執行邏輯

#### Orders.GetOrderSchema
呼叫 Orders.OrderSchemaSeq 序列建立訂單編號的預存程序：格式 yyyyMMdd#######

#### Orders.ResetOrderSchemaSeq
重設訂單序號的預存程序，依情境可於每日進行重設序號種子作業
> 此為愈先撰寫項目並沒有任何程式碼或資料庫物件有進行呼叫

### 使用者自訂方法
#### Products.GetProductValidStorage
取得指定商品代碼可購買的商品庫存量，依情境會有不同的計算方式

## 附件

#### 資料庫物件截圖

![Database object](https://raw.githubusercontent.com/txstudio/eShopPanicBuyingSimulatorUseStoreProcedure/master/screenshot/db-objects.gif)

#### 預存程序執行錯誤的事件紀錄方法從 AdvantureWork 範例程式碼取得，請參考下列連結

[AdvantureWorks in Github](https://github.com/Microsoft/sql-server-samples/blob/master/samples/databases/adventure-works/oltp-install-script/instawdb.sql#L203)

#### 為何使用 StoreProcedure 提供訂單編號

原本使用 Scalar-Valued Functions 提供訂單的訂單編號，在大量呼叫的時候會出現訂單代碼重複的問題造成錯誤讓 Transaction Rollback ，改使用 Sequence 賦予訂單序號，避免出現唯一條件限制的資料庫 Exception，不過儲存順序跟主索引可能會有所差異。
