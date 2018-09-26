# 電子商務網站搶購模擬 - 使用預存程序

這是一個模擬電子商務網站遇到在大量商品訂購需求中是否會有商品超賣的情況

本專案使用資料庫與程式語言如下

- [Microsoft SQL Server in Docker](https://hub.docker.com/r/microsoft/mssql-server-linux/)
- [.NET Core 2.1 ConsoleApplication](https://docs.microsoft.com/zh-tw/dotnet/core/)

> 本範例程式碼有一個對應的 Entity Framework Core 版本，並使用 Code First 建立資料庫
> [txstudio/eShopPanicBuyingSimulatorUseEFCore](https://github.com/txstudio/eShopPanicBuyingSimulatorUseEFCore)

## 資料庫

範例資料庫使用 Microsoft SQL Server in Docker 的 Image 建立，可以使用下列指令碼啟用 Container

```
docker run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=Pa$$w0rd' -p 1433:1433 -d
```

## .NET Core 應用程式

使用 ADO.NET 呼叫資料庫物件模擬大量使用者訂購行為

## 目錄說明

資料庫與應用程式更詳細說明請參考對應資料夾內的說明 (readme.md) 檔案

|資料夾|對應內容|
|--|--|
|db|Transact-SQL 指令檔|
|netcoreapp/eShop.Loader|.NET Core 主控台應用程式|

## 後紀

原本設計為 procedure-default.sql ，但進行負載測試後會出現有商品超賣的情況

感謝[楊志強老師](https://mvp.microsoft.com/zh-tw/PublicProfile/10723)給予指點將重點物件設定修改為 procedure-correct.sql 的方式在相同測試條件下商品沒有出現超賣的情形



