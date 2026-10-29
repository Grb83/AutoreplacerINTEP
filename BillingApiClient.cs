using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Text;
using System.Threading.Tasks;
using Newtonsoft.Json;

namespace AutoReplaceApp
{
    public class EicConsumpResponse
    {
        [JsonProperty("eicCode")]
        public string EicCode { get; set; }

        [JsonProperty("value")]
        public decimal Value { get; set; }
    }

    internal class EicConsumpRequest
    {
        [JsonProperty("eiccodes")]
        public List<string> EicCodes { get; set; }
    }

    public class BillingApiClient
    {
        private static readonly HttpClient _httpClient;
        private const string ApiKey = "PromObl2026";
        private const string TargetIp = "10.67.1.188";
        private const string BaseUrl = "https://10.67.1.188/";

        static BillingApiClient()
        {
            try
            {
                // 1. TLS 1.2 для .NET 4.5.1
                ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12 | SecurityProtocolType.Tls11 | SecurityProtocolType.Tls;

                // 2. Ігнорування SSL-сертифікатів
                ServicePointManager.ServerCertificateValidationCallback = (sender, certificate, chain, sslPolicyErrors) => true;

                ServicePointManager.DefaultConnectionLimit = 50;

                _httpClient = new HttpClient()
                {
                    BaseAddress = new Uri(BaseUrl),
                    Timeout = TimeSpan.FromSeconds(30)
                };

                _httpClient.DefaultRequestHeaders.Clear();
                _httpClient.DefaultRequestHeaders.Add("Coe-Api-Key", ApiKey);

                // Вказуємо Host header для IIS віртуальних хостів
                _httpClient.DefaultRequestHeaders.Host = "Gies5";

                Logger.Info($"[BillingApiClient] Ініціалізовано. IP: {TargetIp}, Host Header: Gies5");
            }
            catch (Exception ex)
            {
                Logger.Error("[BillingApiClient] Помилка ініціалізації HttpClient", ex);
            }
        }

        public async Task<string> TestConnectionAsync()
        {
            StringBuilder report = new StringBuilder();
            report.AppendLine("=== ДІАГНОСТИКА З'ЄДНАННЯ З СЕРВЕРОМ БІЛІНГУ ===");

            // 1. Ping
            try
            {
                using (Ping ping = new Ping())
                {
                    PingReply reply = ping.Send(TargetIp, 2000);
                    if (reply.Status == IPStatus.Success)
                    {
                        report.AppendLine($"[1/3 Ping OK] IP {TargetIp} відповідає ({reply.RoundtripTime} ms).");
                    }
                    else
                    {
                        report.AppendLine($"[1/3 Ping FAIL] Статус: {reply.Status}");
                    }
                }
            }
            catch (Exception ex)
            {
                report.AppendLine($"[1/3 Ping ERROR] {ex.Message}");
            }

            // 2. TCP Port 443
            try
            {
                using (TcpClient tcp = new TcpClient())
                {
                    var connectTask = tcp.ConnectAsync(TargetIp, 443);
                    if (await Task.WhenAny(connectTask, Task.Delay(3000)) == connectTask)
                    {
                        report.AppendLine($"[2/3 TCP Port 443 OK] Порт HTTPS відкритий.");
                    }
                    else
                    {
                        report.AppendLine($"[2/3 TCP Port 443 FAIL] Порт 443 заблоковано.");
                        return report.ToString();
                    }
                }
            }
            catch (Exception ex)
            {
                report.AppendLine($"[2/3 TCP Port 443 ERROR] {ex.Message}");
                return report.ToString();
            }

            // 3. HTTP API POST Запит з реальним тестовим EIC
            try
            {
                Stopwatch sw = Stopwatch.StartNew();
                string testUrl = "PromObl/api2/EicsConsump?yearMonth=202605&isJur=1";

                // Тестовий EIC зі специфікації
                var testPayload = new EicConsumpRequest { EicCodes = new List<string> { "62Z4053761015554" } };
                string json = JsonConvert.SerializeObject(testPayload);
                var content = new StringContent(json, Encoding.UTF8, "application/json");

                HttpResponseMessage response = await _httpClient.PostAsync(testUrl, content);
                sw.Stop();

                string body = await response.Content.ReadAsStringAsync();

                if (response.IsSuccessStatusCode)
                {
                    report.AppendLine($"[3/3 HTTP API OK] Сервер успішно відповів за {sw.ElapsedMilliseconds} ms! Status: 200 OK");
                    report.AppendLine($"Відповідь: {body}");
                }
                else
                {
                    report.AppendLine($"[3/3 HTTP API WARNING] Status: {response.StatusCode} ({sw.ElapsedMilliseconds} ms)");
                    report.AppendLine($"Деталі: {body}");
                }
            }
            catch (Exception ex)
            {
                string details = ex.InnerException != null ? $"{ex.Message} -> Inner: {ex.InnerException.Message}" : ex.Message;
                report.AppendLine($"[3/3 HTTP API ERROR] {details}");
            }

            return report.ToString();
        }

        public async Task<Dictionary<string, decimal>> GetConsumptionAsync(string yearMonth, int isJur, List<string> eicCodes)
        {
            var resultDict = new Dictionary<string, decimal>(StringComparer.OrdinalIgnoreCase);

            if (eicCodes == null || eicCodes.Count == 0)
                return resultDict;

            var cleanEics = eicCodes
                .Where(e => !string.IsNullOrWhiteSpace(e) && e.Trim() != "*")
                .Select(e => e.Trim())
                .Distinct()
                .ToList();

            if (cleanEics.Count == 0)
                return resultDict;

            int batchSize = 500;
            int totalBatches = (int)Math.Ceiling((double)cleanEics.Count / batchSize);

            for (int i = 0; i < cleanEics.Count; i += batchSize)
            {
                int currentBatchNum = (i / batchSize) + 1;
                var batch = cleanEics.Skip(i).Take(batchSize).ToList();

                Logger.Info($"[BillingApiClient] === Пакет {currentBatchNum}/{totalBatches}: Відправка {batch.Count} EIC ===");

                var batchResult = await SendBatchRequestAsync(yearMonth, isJur, batch, currentBatchNum, totalBatches);

                foreach (var item in batchResult)
                {
                    if (!string.IsNullOrEmpty(item.EicCode))
                    {
                        resultDict[item.EicCode.Trim()] = item.Value;
                    }
                }
            }

            return resultDict;
        }

        private async Task<List<EicConsumpResponse>> SendBatchRequestAsync(string yearMonth, int isJur, List<string> batchEics, int batchNum, int totalBatches)
        {
            string url = $"PromObl/api2/EicsConsump?yearMonth={yearMonth}&isJur={isJur}";

            var requestPayload = new EicConsumpRequest { EicCodes = batchEics };
            string jsonBody = JsonConvert.SerializeObject(requestPayload);
            var content = new StringContent(jsonBody, Encoding.UTF8, "application/json");

            Stopwatch sw = Stopwatch.StartNew();

            try
            {
                HttpResponseMessage response = await _httpClient.PostAsync(url, content);
                sw.Stop();

                string jsonResponse = await response.Content.ReadAsStringAsync();
                Logger.Info($"[API POST Recv] Pkg {batchNum}/{totalBatches} <- Status: {response.StatusCode} ({sw.ElapsedMilliseconds} ms)");

                if (!response.IsSuccessStatusCode)
                {
                    Logger.Error($"[API Error] Status: {response.StatusCode} | Details: {jsonResponse}");
                    throw new Exception($"API Білінгу повернуло статус {response.StatusCode}: {jsonResponse}");
                }

                var items = JsonConvert.DeserializeObject<List<EicConsumpResponse>>(jsonResponse);
                return items ?? new List<EicConsumpResponse>();
            }
            catch (Exception ex)
            {
                sw.Stop();
                string details = ex.InnerException != null ? $"{ex.Message} -> Inner: {ex.InnerException.Message}" : ex.Message;
                Logger.Error($"[API Fail] Pkg {batchNum}/{totalBatches}: {details}", ex);
                throw new Exception($"Не вдалося з'єднатися з сервером Білінгу: {details}");
            }
        }
    }
}