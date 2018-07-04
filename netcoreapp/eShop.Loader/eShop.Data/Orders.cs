using System;

namespace eShop.Data
{
    public sealed class OrderItem
    {
        public int ProductNo { get; set; }
        public decimal SellPrice { get; set; }
        public int Quantity { get; set; }
    }
}
