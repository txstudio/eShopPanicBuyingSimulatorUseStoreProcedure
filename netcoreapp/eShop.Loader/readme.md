# eShop.Loader 說明

本應用程式為使用 .NET Core 2.1 進行開發的主控台應用程式

模擬大量使用者進行商品搶購行為，確認資料庫設計是否能正確避免超賣情況

程式碼使用 ADO.NET 撰寫並呼叫 StoreProcedure 與 Scalar-Valued Functions，並沒有使用 Entity Framework Core

## 操作說明

依資料庫連線字串與密碼不同修改 Program.cs 的 ConnectionString 連線字串

### 參數說明

|名稱|說明|
|--|--|
|-t|要建立的執行緒數量|

### 呼叫範例

```
dotnet eShop.Loader.dll -t 20
```

上述指令碼執行後應用程式會建立 20 個執行緒數量，並等待系統時間到執行時間 70 秒後執行

### 模擬購買行為

每一個執行緒會建立一個使用者編號並隨機購買商品或數量，重複到沒有商品可以購買就停止

## 附件

應用程式執行截圖

![等待系統時間開始執行模擬](https://raw.githubusercontent.com/txstudio/eShopPanicBuyingSimulatorUseStoreProcedure/master/screenshot/default-case-loading-test-2500-tasks.gif)

![執行中](https://raw.githubusercontent.com/txstudio/eShopPanicBuyingSimulatorUseStoreProcedure/master/screenshot/default-case-loading-test-operating.gif)

![應用程式執行完成](https://raw.githubusercontent.com/txstudio/eShopPanicBuyingSimulatorUseStoreProcedure/master/screenshot/default-case-loading-test-finish.gif)
