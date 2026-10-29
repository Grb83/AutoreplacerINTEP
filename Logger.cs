using System;
using System.IO;

namespace AutoReplaceApp
{
    public static class Logger
    {
        private static readonly string LogDirectory = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Logs");

        static Logger()
        {
            // Створюємо папку Logs при першому зверненні, якщо її немає
            if (!Directory.Exists(LogDirectory))
            {
                Directory.CreateDirectory(LogDirectory);
            }
        }

        private static void WriteLog(string level, string message)
        {
            try
            {
                string fileName = $"AppLog_{DateTime.Now:yyyy-MM-dd}.txt";
                string filePath = Path.Combine(LogDirectory, fileName);
                string logLine = $"[{DateTime.Now:HH:mm:ss}] [{level}] {message}{Environment.NewLine}";

                // Дописуємо в кінець файлу
                File.AppendAllText(filePath, logLine);
            }
            catch
            {
                // Логер не повинен "валити" програму, якщо файл раптом заблокований
            }
        }

        public static void Info(string message)
        {
            WriteLog("INFO", message);
        }

        public static void Warn(string message)
        {
            WriteLog("WARN", message);
        }

        public static void Error(string message, Exception ex = null)
        {
            string logMessage = ex == null ? message : $"{message} | Виключення: {ex.Message}";
            WriteLog("ERROR", logMessage);
        }
    }
}