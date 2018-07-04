# 電子商務網站搶購模擬 - 使用預存程序

這是一個模擬電子商務網站遇到在大量商品訂購需求中是否會有商品超賣的情況

本專案使用資料庫與程式語言如下

- [Microsoft SQL Server in Docker](https://hub.docker.com/r/microsoft/mssql-server-linux/)
- [.NET Core ConsoleApplication 2.1](https://docs.microsoft.com/zh-tw/dotnet/core/)

此範例會有建立資料庫環境使用的 T-SQL 指令碼與模擬大量使用者操作的主控台應用程式，如下圖



## 關於資料庫

範例資料庫使用 Microsoft SQL Server in Docker 的 Image 建立，可以使用下列指令碼啟用 Container

```
docker run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=Pa$$w0rd' -p 1433:1433 -d
```

## .NET Core 應用程式


