using System;
using System.IO;
using System.Windows.Forms;
using System.Text.RegularExpressions;
using Oracle.ManagedDataAccess.Client; // Обов'язково для білдера підключень

namespace AutoReplaceApp
{
    static class Program
    {
        [STAThread]
        static void Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            Logger.Info("=== Запуск програми AutoReplaceApp ===");

            // 1. АВТОМАТИЧНИЙ ПОШУК TNSNAMES.ORA (Рішення для будь-якого ПК)
            ConfigureTnsAdmin();

            string connString = "";

            if (args.Length > 0)
            {
                Logger.Info($"Отримано аргументи командного рядка: {args.Length} шт.");
                string inputArgs = string.Join(" ", args);
                Logger.Info($"Оригінальний рядок аргументів: '{inputArgs}'");

                connString = ParseConnectionString(inputArgs);
                Logger.Info($"Рядок підключення ПІСЛЯ парсингу: '{connString}'");
            }
            else
            {
                Logger.Warn("Аргументи не передані! Використовується резервне підключення.");
                // Для тестів без C++ клієнта: беремо аліас "askue" з tnsnames.ora
                OracleConnectionStringBuilder b = new OracleConnectionStringBuilder();
                b.UserID = "RYDA";
                b.Password = "oracle81634";
                b.DataSource = "askue";
                connString = b.ConnectionString;
            }

            Logger.Info("Передача управління головній формі...");
            try
            {
                Application.Run(new Form1(connString));
            }
            catch (Exception ex)
            {
                Logger.Error("Критична помилка в роботі форми", ex);
            }

            Logger.Info("=== Завершення роботи програми ===\n");
        }

        // МЕТОД-РЯТІВНИК: Автоматично знаходить папку з tnsnames.ora
        private static void ConfigureTnsAdmin()
        {
            try
            {
                // 1. Перевіряємо поточну папку (Срібна куля: якщо файл tnsnames.ora лежить поруч з exe)
                string localTns = AppDomain.CurrentDomain.BaseDirectory;
                if (File.Exists(Path.Combine(localTns, "tnsnames.ora")))
                {
                    Environment.SetEnvironmentVariable("TNS_ADMIN", localTns);
                    Logger.Info($"TNS_ADMIN знайдено локально: {localTns}");
                    return;
                }

                // 2. Перевіряємо системну змінну TNS_ADMIN
                string envTns = Environment.GetEnvironmentVariable("TNS_ADMIN");
                if (!string.IsNullOrEmpty(envTns) && File.Exists(Path.Combine(envTns, "tnsnames.ora")))
                {
                    Logger.Info($"TNS_ADMIN вже задано в системі: {envTns}");
                    return;
                }

                // 3. Шукаємо в змінній PATH (там завжди є шлях до bin старого Oracle клієнта)
                string pathVar = Environment.GetEnvironmentVariable("PATH");
                if (!string.IsNullOrEmpty(pathVar))
                {
                    foreach (string p in pathVar.Split(';'))
                    {
                        string path = p.Trim(' ', '"');
                        if (path.IndexOf("oracle", StringComparison.OrdinalIgnoreCase) >= 0 ||
                            path.IndexOf("app", StringComparison.OrdinalIgnoreCase) >= 0)
                        {
                            string baseDir = path;
                            if (path.EndsWith("\\bin", StringComparison.OrdinalIgnoreCase))
                            {
                                baseDir = Directory.GetParent(path).FullName;
                            }
                            string adminDir = Path.Combine(baseDir, "network", "admin");
                            if (File.Exists(Path.Combine(adminDir, "tnsnames.ora")))
                            {
                                Environment.SetEnvironmentVariable("TNS_ADMIN", adminDir);
                                Logger.Info($"TNS_ADMIN автоматично знайдено через PATH: {adminDir}");
                                return;
                            }
                        }
                    }
                }
                Logger.Warn("Файл tnsnames.ora не знайдено автоматично в системі!");
            }
            catch (Exception ex)
            {
                Logger.Error("Помилка під час автоматичного пошуку TNS_ADMIN", ex);
            }
        }
        private static string ParseConnectionString(string input)
        {
            string uid = "";
            string pwd = "";
            string tns = "";

            if (input.IndexOf("User", StringComparison.OrdinalIgnoreCase) >= 0 &&
                input.IndexOf("tns", StringComparison.OrdinalIgnoreCase) >= 0)
            {
                uid = MatchArg(input, "User");
                pwd = MatchArg(input, "password");
                tns = MatchArg(input, "tns");
            }
            else
            {
                var classicMatch = Regex.Match(input.Trim(), @"^([^/]+)/([^@]+)@(.+)$");
                if (classicMatch.Success)
                {
                    uid = classicMatch.Groups[1].Value.Trim();
                    pwd = classicMatch.Groups[2].Value.Trim();
                    tns = classicMatch.Groups[3].Value.Trim(' ', ';', '"', '\'');
                }
            }

            if (string.IsNullOrEmpty(uid) || string.IsNullOrEmpty(tns))
                return input;

            // ВИПРАВЛЕННЯ: Замість проблемного OracleConnectionStringBuilder 
            // використовуємо просте форматування рядка:
            return $"User Id={uid};Password={pwd};Data Source={tns}";
        }

        private static string MatchArg(string input, string paramName)
        {
            var match = Regex.Match(input, $@"{paramName}\s*=\s*([^ ]+)", RegexOptions.IgnoreCase);
            if (match.Success)
            {
                return match.Groups[1].Value.Trim('"', '\'');
            }
            return string.Empty;
        }
    }
}