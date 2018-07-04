using eShop.Data;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Text;

namespace eShop.Loader
{
    public sealed class eShopRepository
    {
        private readonly string _connectionString;

        public eShopRepository(string connectionString)
        {
            this._connectionString = connectionString;
        }


        /// <summary>取得所有商品清單</summary>
        public IEnumerable<ProductMains> GetProducts()
        {
            List<ProductMains> _products;
            ProductMains _product;

            _products = new List<ProductMains>();

            using (SqlConnection _conn = new SqlConnection(this._connectionString))
            {
                SqlCommand _cmd = new SqlCommand();
                _cmd.Connection = _conn;
                _cmd.CommandText = "SELECT * FROM [Products].[ProductMains]";

                _conn.Open();

                var _reader = _cmd.ExecuteReader();

                while(_reader.Read())
                {
                    _product = new ProductMains();
                    _product.No = _reader.GetInt32(0);
                    _product.Schema = _reader.GetString(1);
                    _product.Name = _reader.GetString(2);
                    _product.SellPrice = _reader.GetDecimal(3);
                    _products.Add(_product);
                }
                _conn.Close();
            }

            if (_products.Count == 0)
                return null;

            return _products.ToArray();
        }

        /// <summary>取得指定商品型號的現有庫存</summary>
        public int GetStorage(string schema)
        {
            var _storage = 0;

            using (SqlConnection _conn = new SqlConnection(this._connectionString))
            {
                SqlCommand _cmd = new SqlCommand();
                _cmd.Connection = _conn;
                _cmd.CommandText = "SELECT [Products].[GetProductValidStorage](@Schema)";

                _cmd.Parameters.Add("@Schema", SqlDbType.VarChar, 15);
                _cmd.Parameters["@Schema"].Value = schema;

                _conn.Open();
                var _value = _cmd.ExecuteScalar();
                _conn.Close();

                _storage = Convert.ToInt32(_value);
            }

            return _storage;
        }

        /// <summary>新增訂單</summary>
        public bool AddOrder(Guid memberGuid, IEnumerable<OrderItem> items)
        {
            var _executeResult = false;

            using (SqlConnection _conn
                = new SqlConnection(this._connectionString))
            {
                SqlCommand _cmd;

                _cmd = new SqlCommand();
                _cmd.Connection = _conn;

                _cmd.CommandText = @"[Orders].[AddOrder]";
                _cmd.CommandType = CommandType.StoredProcedure;

                _cmd.Parameters.Add("@MemberGUID", SqlDbType.UniqueIdentifier);
                _cmd.Parameters.Add("@Items", SqlDbType.Structured);
                _cmd.Parameters.Add("@IsSuccess", SqlDbType.Bit);

                _cmd.Parameters["@Items"].TypeName = "[Orders].[OrderDetails]";
                _cmd.Parameters["@IsSuccess"].Direction = ParameterDirection.Output;

                _cmd.Parameters["@MemberGUID"].Value = memberGuid;
                _cmd.Parameters["@Items"].Value = this.MapToOrderItem(items);
                _cmd.Parameters["@IsSuccess"].Value = _executeResult;

                _conn.Open();
                var _result = _cmd.ExecuteNonQuery();
                _conn.Close();

                _executeResult = Convert.ToBoolean(_cmd.Parameters["@IsSuccess"].Value);

            }

            return _executeResult;
        }

        /// <summary>新增指定使用者的購買資訊</summary>
        public void AddEventBuying(Guid memberGuid, string content, bool isSuccess)
        {
            using (SqlConnection _conn
                   = new SqlConnection(this._connectionString))
            {
                SqlCommand _cmd;

                _cmd = new SqlCommand();
                _cmd.Connection = _conn;

                _cmd.CommandText = @"[Events].[AddEventBuying]";
                _cmd.CommandType = CommandType.StoredProcedure;

                _cmd.Parameters.Add("@MemberGUID", SqlDbType.UniqueIdentifier);
                _cmd.Parameters.Add("@Content", SqlDbType.NVarChar, 500);
                _cmd.Parameters.Add("@IsSuccess", SqlDbType.Bit);

                _cmd.Parameters["@MemberGUID"].Value = memberGuid;
                _cmd.Parameters["@Content"].Value = content;
                _cmd.Parameters["@IsSuccess"].Value = isSuccess;

                _conn.Open();
                var _result = _cmd.ExecuteNonQuery();
                _conn.Close();
            }
        }


        private DataTable MapToOrderItem(IEnumerable<OrderItem> items)
        {
            DataTable _table;
            DataRow _row;

            _table = new DataTable();
            _table.Columns.Add("ProductNo", typeof(int));
            _table.Columns.Add("SellPrice", typeof(decimal));
            _table.Columns.Add("Quantity", typeof(int));

            foreach (var item in items)
            {
                _row = _table.NewRow();
                _row["ProductNo"] = item.ProductNo;
                _row["SellPrice"] = item.SellPrice;
                _row["Quantity"] = item.Quantity;
                _table.Rows.Add(_row);
            }

            return _table;
        }
    }
}
