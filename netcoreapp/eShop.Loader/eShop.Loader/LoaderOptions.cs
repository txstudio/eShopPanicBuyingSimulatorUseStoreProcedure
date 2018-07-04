using System;

namespace eShop.Loader
{
    internal class LoaderOptions
    {
        public string StartTime { get; set; }
        public string TaskNumber { get; set; }
        public int Task
        {
            get
            {
                if (string.IsNullOrWhiteSpace(this.TaskNumber) == true)
                    return 5;

                return Convert.ToInt32(this.TaskNumber);
            }
        }
        public bool Start
        {
            get
            {
                //input - TimeSpan.Compare
                //  15:00, 14:59 = 1
                //  15:00, 15:00 = 0
                //  14:59, 15:00 = (-1)

                var _sysTimeSpan = DateTime.Now.TimeOfDay;

                if (this.StartTimeSpan.HasValue == false)
                    return true;

                if (TimeSpan.Compare(_sysTimeSpan, this.StartTimeSpan.Value) == 1)
                    return true;

                return false;
            }
        }

        private TimeSpan? StartTimeSpan
        {
            get
            {
                if (string.IsNullOrWhiteSpace(this.StartTime) == true)
                    return null;

                TimeSpan _out;

                if (TimeSpan.TryParse(this.StartTime, out _out) == true)
                    return _out;

                return null;
            }
        }
    }

}
