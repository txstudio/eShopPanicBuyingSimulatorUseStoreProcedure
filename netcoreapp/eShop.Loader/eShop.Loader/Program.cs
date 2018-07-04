using eShop.Data;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace eShop.Loader
{
    class Program
    {
        const string ConnectionString = "Server=192.168.0.80;Database=eShop;User Id=sa;Password=Pa$$w0rd;";

        static LoaderOptions _option = new LoaderOptions();
        static Random _random = new Random();
        static bool _exit = false;

        static void Main(string[] args)
        {
            //args = new string[] { "-t", "2500", "-e", "11:37" };

            SetArgs(_option, args);

            List<Task> _tasks;

            _tasks = new List<Task>();

            for (int i = 0; i < _option.Task; i++)
                _tasks.Add(new Task(eShopBuyer));

            for (int i = 0; i < _option.Task; i++)
                _tasks[i].Start();

            Stopwatch _stopwatch = new Stopwatch();

            while(_exit == false)
            {
                for (int i = 0; i < _option.Task; i++)
                {
                    if (_tasks[i].Status == TaskStatus.Running)
                        _stopwatch.Start();

                    if (_tasks[i].Status != TaskStatus.RanToCompletion)
                    {
                        Thread.Sleep(100);
                        continue;
                    }
                }  

                _exit = true;
                _stopwatch.Stop();

                Thread.Sleep(1000);
            }

            Console.WriteLine();
            Console.WriteLine("測試結束，共花費 {0} ms", _stopwatch.ElapsedMilliseconds);
            Console.WriteLine();
            Console.WriteLine("press any key to exit");
            Console.ReadKey();
        }

        static void eShopBuyer()
        {
            var _memberGUID = Guid.NewGuid();
            var _eShopDb = new eShopRepository(ConnectionString);
            var _products = _eShopDb.GetProducts().ToList();

            bool _orderResult;
            int _quantity;
            int _maxValue;
            int _productIndex;
            int _validStorage;
            ProductMains _product;
            List<OrderItem> _items;
            StringBuilder _builder;

            _builder = new StringBuilder();

            while (true)
            {
                if (_option.Start == false)
                {
                    Thread.Sleep(50);

                    continue;
                }

                _quantity = _random.Next(1, 3);
                _maxValue = _products.Count();
                _productIndex = _random.Next(0, _maxValue);

                _product = _products[_productIndex];

                _validStorage = _eShopDb.GetStorage(_products[0].Schema);

                //如果所有商品都沒有庫存的話取消訂購
                if (_validStorage <= 0)
                {
                    _validStorage = _eShopDb.GetStorage(_products[1].Schema);

                    if(_validStorage <= 0)
                    {
                        _validStorage = _eShopDb.GetStorage(_products[2].Schema);

                        if (_validStorage <= 0)
                        {
                            _builder.Clear();
                            _builder.AppendFormat("會員 {0} 完成作業", _memberGUID);

                            _eShopDb.AddEventBuying(_memberGUID, _builder.ToString(), true);

                            Console.WriteLine(_builder.ToString());
                            break;
                        }
                    }
                }

                _items = new List<OrderItem>();
                _items.Add(new OrderItem() {
                                ProductNo = _product.No,
                                Quantity = _quantity,
                                SellPrice = _product.SellPrice
                            });

                _orderResult = _eShopDb.AddOrder(_memberGUID, _items);

                //訂購商品
                _builder.Clear();
                _builder.AppendFormat("會員 {0} 訂購商品 {1} {2} 個，訂購 "
                                        , _memberGUID
                                        , _product.Name
                                        , _quantity);

                if (_orderResult == true)
                    _builder.Append("成功 ...");
                else
                    _builder.Append("失敗 ...");

                _eShopDb.AddEventBuying(_memberGUID, _builder.ToString(), _orderResult);

                Console.WriteLine(_builder.ToString());
            }
        }



        static void SetArgs(LoaderOptions option, string[] args)
        {
            var _arg = string.Empty;
            var _index = 0;

            for (int i = 0; i < args.Length; i++)
            {
                _arg = args[i];
                _index = i + 1;

                if(_index <= args.Length)
                {
                    switch (_arg)
                    {
                        case "-t":
                            option.TaskNumber = args[_index];
                            break;
                        case "-e":
                            option.StartTime = args[_index];
                            break;
                        default:
                            break;
                    }
                }
            }

            Console.WriteLine("-------------------------");
            Console.WriteLine("Task 資訊");
            Console.WriteLine("-------------------------");
            Console.WriteLine("起始時間:{0}\t總數:{1}"
                            , option.StartTime
                            , option.Task);

        }
    }

}
