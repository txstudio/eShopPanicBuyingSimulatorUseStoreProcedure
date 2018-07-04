using eShop.Data;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Text;

namespace eShop.Loader
{
    public sealed class eShopContext
    {
        private readonly ProductRepository _product;
        private readonly OrderRepository _order;

        public eShopContext(string connectionString)
        {
            this._product = new ProductRepository(connectionString);
            this._order = new OrderRepository(connectionString);
        }

        public ProductRepository Product
        {
            get
            {
                return this._product;
            }
        }

        public OrderRepository Order
        {
            get
            {
                return this._order;
            }
        }
    }

    public abstract class DbRepository
    {
        private readonly string _connectionString;

        protected DbRepository(string connectionString)
        {
            this._connectionString = connectionString;
        }

        protected string ConnectionString
        {
            get
            {
                return this._connectionString;
            }
        }
    }


    public sealed class ProductRepository : DbRepository
    {
        public ProductRepository(string connectionString)
            : base(connectionString) { }

        public IEnumerable<ProductMains> GetProducts()
        {
            throw new NotImplementedException();
        }
    }

    public sealed class OrderRepository : DbRepository
    {
        public OrderRepository(string connectionString)
            : base(connectionString) { }

        public bool AddOrder(Guid memberGUID, IEnumerable<OrderItem> items)
        {
            throw new NotImplementedException();
        }
    }
}
