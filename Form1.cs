using ExcelDataReader;
using Oracle.ManagedDataAccess.Client;
using System;
using System.Collections.Generic;
using System.Data;
using System.Diagnostics;
using System.IO;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace AutoReplaceApp
{
    public partial class Form1 : Form
    {
        private string _dbConnectionString;
        private DataTable _excelData;
        private DateTimePicker dtp = new DateTimePicker();
        private ComboBox cmbDefaultAction; // <-- ДОДАНО
        private DateTimePicker dtpSearchStart;
        private DateTimePicker dtpSearchEnd;

        public Form1(string connectionString)
        {
            InitializeComponent();
            _dbConnectionString = connectionString;
            this.Load += Form1_Load;
            Logger.Info("Form1 ініціалізовано.");
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            this.Text = "АСКОЕ - Модуль автозаміщення та інтеграції";
            // --- НОВЕ: Розгортаємо на весь екран ---
            this.WindowState = FormWindowState.Maximized;
            this.MinimumSize = new System.Drawing.Size(1024, 768);

            // --- НОВЕ: Збільшуємо шрифт у таблиці ---
            dgvData.DefaultCellStyle.Font = new System.Drawing.Font("Segoe UI", 10F, System.Drawing.FontStyle.Regular);
            dgvData.ColumnHeadersDefaultCellStyle.Font = new System.Drawing.Font("Segoe UI", 10F, System.Drawing.FontStyle.Bold);
            dgvData.AllowUserToAddRows = false;
            dgvData.ReadOnly = false;

            // --- СТВОРЕННЯ ЕЛЕМЕНТІВ ДЛЯ НОВОГО НАЛАШТУВАННЯ ---
            Label lblDefAction = new Label() { Text = "Дія за замовчуванням (при генерації):", Location = new System.Drawing.Point(20, 145), Width = 250 };
            cmbDefaultAction = new ComboBox() { Location = new System.Drawing.Point(360, 143), Width = 60, DropDownStyle = ComboBoxStyle.DropDownList };
            cmbDefaultAction.Items.AddRange(new string[] { "", "А", "Р" });
            tabPage3.Controls.Add(lblDefAction);
            tabPage3.Controls.Add(cmbDefaultAction);

            // 1. Встановлюємо правильні стартові значення (перебиваємо дизайнер)
            nudMinHoles.Value = 1;
            nudMaxHoles.Value = 48;

            // 2. Завантаження збережених налаштувань
            try
            {
                if (Properties.Settings.Default.MinHoles > 0) nudMinHoles.Value = Properties.Settings.Default.MinHoles;
                if (Properties.Settings.Default.MaxHoles > 0) nudMaxHoles.Value = Properties.Settings.Default.MaxHoles;
                if (Properties.Settings.Default.DepthWeeks > 0) nudDepthWeeks.Value = Properties.Settings.Default.DepthWeeks;

                string defAction = Properties.Settings.Default.DefaultAction ?? "";
                if (cmbDefaultAction.Items.Contains(defAction)) cmbDefaultAction.SelectedItem = defAction;
                else cmbDefaultAction.SelectedIndex = 0;
            }
            catch { cmbDefaultAction.SelectedIndex = 0; }

            // 3. Збереження налаштувань при закритті форми
            this.FormClosing += (s, ev) =>
            {
                try
                {
                    Properties.Settings.Default.MinHoles = (int)nudMinHoles.Value;
                    Properties.Settings.Default.MaxHoles = (int)nudMaxHoles.Value;
                    Properties.Settings.Default.DepthWeeks = (int)nudDepthWeeks.Value;
                    Properties.Settings.Default.DefaultAction = cmbDefaultAction.SelectedItem.ToString();
                    Properties.Settings.Default.Save();
                }
                catch { }
            };

            // 4. ДИНАМІЧНА КНОПКА для групової зміни дат
            Button btnApplyDates = new Button();
            btnApplyDates.Text = "Скопіювати дати на всі точки";
            btnApplyDates.Size = new System.Drawing.Size(180, 25);
            btnApplyDates.Location = new System.Drawing.Point(352, 45); // Повернули на старе місце
            btnApplyDates.Click += (s, ev) =>
            {
                if (dgvData.Rows.Count > 0)
                {
                    string d1 = dgvData.Rows[0].Cells["Початкова дата заміщення"].Value?.ToString();
                    string d2 = dgvData.Rows[0].Cells["Кінцева дата заміщення"].Value?.ToString();
                    for (int i = 1; i < dgvData.Rows.Count; i++)
                    {
                        dgvData.Rows[i].Cells["Початкова дата заміщення"].Value = d1;
                        dgvData.Rows[i].Cells["Кінцева дата заміщення"].Value = d2;
                    }
                    dgvData.Refresh();
                    MessageBox.Show("Дати з першого рядка скопійовані для всіх точок!", "Готово", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
            };
            panel1.Controls.Add(btnApplyDates);
            // 5. Підключаємо події гріда (КЛІК МИШКИ ПРИБРАНО)
            dgvData.CellClick += dgvData_CellClick;           // Для календарика
            dgvData.CellFormatting += dgvData_CellFormatting; // Для кольорів
            dgvData.EditingControlShowing += dgvData_EditingControlShowing; // Ввід з клавіатури
            dgvData.CellEndEdit += dgvData_CellEndEdit;       // Завершення вводу
            dgvData.CellValidating += dgvData_CellValidating; // Порожній обробник

            // Налаштування календарика
            dtp.Visible = false;
            dtp.Format = DateTimePickerFormat.Custom;
            dtp.CustomFormat = "dd.MM.yyyy";

            // --- ЗБІЛЬШУЄМО ШРИФТ КАЛЕНДАРИКА ---
            dtp.Font = new System.Drawing.Font("Segoe UI", 11F, System.Drawing.FontStyle.Regular);

            dtp.CloseUp += (s, ev) => dtp.Visible = false;

            // --- ПРИМУСОВО ФОРМАТУЄМО ВИВІД З НУЛЯМИ ---
            dtp.ValueChanged += (s, ev) =>
            {
                if (dgvData.CurrentCell != null)
                    dgvData.CurrentCell.Value = dtp.Value.ToString("dd.MM.yyyy 00:00");
            };

            dgvData.Controls.Add(dtp);

            // --- Закладка "Білінг"
            // --- НАЛАШТУВАННЯ ВКЛАДКИ БІЛЛІНГ ТА EIC ---
            if (cmbJurType.Items.Count > 0)
            {
                cmbJurType.SelectedIndex = 0; // Встановлюємо "1 — Юридичні особи" за замовчуванням
            }

            // За замовчуванням вибираємо попередній календарний місяць
            DateTime lastMonth = DateTime.Now.AddMonths(-1);
            dtpBillingPeriod.Value = new DateTime(lastMonth.Year, lastMonth.Month, 1);

            // Налаштування гріда білінгу
            dgvBilling.DefaultCellStyle.Font = new System.Drawing.Font("Segoe UI", 10F, System.Drawing.FontStyle.Regular);
            dgvBilling.ColumnHeadersDefaultCellStyle.Font = new System.Drawing.Font("Segoe UI", 10F, System.Drawing.FontStyle.Bold);
            dgvBilling.AllowUserToAddRows = false;

            // Підписка на події кнопкок білінгу
            btnFetchBilling.Click += btnFetchBilling_Click;
            btnSaveEic.Click += btnSaveEic_Click;
            btnExportBilling.Click += btnExportBilling_Click;
            btnTestConnection.Click += btnTestConnection_Click;

            // Підписка на події гріда для динамічного підсвічування
            dgvBilling.CellFormatting += dgvBilling_CellFormatting;
            chkOnlyDiff.CheckedChanged += (s, ev) => FilterBillingGrid();
            // Створюємо вкладку (вона стане першою, індекс 0)
            InitializeEicImportTab();

            // Робимо активною вкладку "Автозаміщення", щоб вона відкривалася за замовчуванням
            // (tabPage1 тепер знаходиться на індексі 1)
            tabControl1.SelectedTab = tabPage1;
            // Ініціалізація тексту довідки
            txtHelp.Text = @"ІНСТРУКЦІЯ КОРИСТУВАЧА

1. ЯК ЗРОБИТИ АВТОЗАМІЩЕННЯ (Генерація з БД):
   • Перейдіть на вкладку 'Автозаміщення' та вкажіть 'Період пошуку' (дати поруч із кнопками).
   • Натисніть '1. Згенерувати з БД'. Програма вивантажить усі активні точки з EIC-кодами.
   • У колонці 'Зробити заміщення' переконайтеся, що стоїть 'А' (Авто) або 'Р' (Ручне).
   • Натисніть '2. Перевірити дані'. ПРОГРАМА АВТОМАТИЧНО ВИДАЛИТЬ ЗІ СПИСКУ всі точки, де дані вже повні (немає дірок), або кількість пропусків не підпадає під ваші ліміти!
   • У вас залишиться чистий список лише тих точок, які дійсно потребують заміщення.
   • Натисніть '3. Виконати заміщення'.

2. РОБОТА ЧЕРЕЗ EXCEL:
   • Ви можете натиснути 'Експорт шаблону (CSV)', заповнити дати та дії в Excel, зберегти файл як '.xlsx' і завантажити його кнопкою 'Завантажити Excel'.
   • Після завантаження обов'язково натисніть '2. Перевірити дані', щоб програма відкинула точки, де заміщення не потрібне.

3. ІМПОРТ EIC-КОДІВ З EXCEL:
   • Перейдіть на вкладку 'Імпорт EIC (Excel)'.
   • Натисніть '1. Вибрати Excel'. Файл обов'язково повинен містити колонки зі словами 'номер' (або 'лічильник'), 'площ' та 'точк' у заголовках.
   • Якщо потрібно оновити існуючі коди — поставте галочку 'Перезаписувати існуючі EIC-коди'.
   • Натисніть '2. Завантажити в БД'. Зелені рядки — успіх, жовті — пропущено, червоні — помилка.

4. ЗВІРКА З БІЛІНГОМ:
   • Перейдіть на вкладку 'Біллінг та EIC', оберіть місяць та тип споживача.
   • Натисніть '1. Звірити з Білінгом'. Програма підсвітить розбіжності.
   • Ви можете редагувати EIC-коди прямо в таблиці (жовті клітинки) і зберігати їх кнопкою '2. Зберегти EIC в БД'.

5. НАЛАШТУВАННЯ:
   • Мінімальна/Максимальна кількість пропусків: ліміт відсутніх записів. Якщо кількість дірок у цільовому дні виходить за ці межі — програма ігнорує точку.
   • Глибина пошуку: скільки тижнів углиб програма шукатиме день-аналог.
   • Дія за замовчуванням: дозволяє відразу проставляти 'А' або 'Р' при генерації списку.";
        }

        // =========================================================================
        // ВАЛІДАЦІЯ ВВЕДЕННЯ НА ЛЬОТУ
        // =========================================================================
        // Перехоплюємо момент, коли користувач починає вводити текст
        private void dgvData_EditingControlShowing(object sender, DataGridViewEditingControlShowingEventArgs e)
        {
            TextBox tb = e.Control as TextBox;
            if (tb != null)
            {
                tb.KeyPress -= ActionColumn_KeyPress; // Відписуємося, щоб не дублювати
                if (dgvData.CurrentCell.OwningColumn.Name == "Зробити заміщення")
                {
                    tb.KeyPress += ActionColumn_KeyPress; // Підписуємося на натискання клавіш
                }
            }
        }

        // Фільтруємо натискання: дозволяємо тільки А/Р (кирилиця і латиниця) і відразу робимо їх великими
        private void ActionColumn_KeyPress(object sender, KeyPressEventArgs e)
        {
            if (e.KeyChar == (char)Keys.Back) return; // Дозволяємо стирати (Backspace)

            char c = char.ToUpper(e.KeyChar); // Переводимо введену літеру у верхній регістр

            // 'A' (латиниця) або 'А' (кирилиця) -> завжди зберігаємо як кириличну 'А'
            if (c == 'A' || c == 'А')
                e.KeyChar = 'А';
            // 'P' (латиниця) або 'Р' (кирилиця) -> завжди зберігаємо як кириличну 'Р'
            else if (c == 'P' || c == 'Р')
                e.KeyChar = 'Р';
            else
                e.Handled = true; // Блокуємо всі інші символи
        }

        // Застосовуємо форматування після завершення вводу (якщо юзер вставив текст з буфера)
        private void dgvData_CellEndEdit(object sender, DataGridViewCellEventArgs e)
        {
            string colName = dgvData.Columns[e.ColumnIndex].Name;
            if (colName == "Зробити заміщення")
            {
                var cell = dgvData.Rows[e.RowIndex].Cells[e.ColumnIndex];
                if (cell.Value != null)
                {
                    string val = cell.Value.ToString().Trim().ToUpper();
                    if (val == "A" || val == "А") cell.Value = "А";
                    else if (val == "P" || val == "Р") cell.Value = "Р";
                    else cell.Value = "";
                }
            }
        }
        private void dgvData_CellValidating(object sender, DataGridViewCellValidatingEventArgs e)
        {
            // Метод намеренно оставлен пустым.
            // Мы убрали блокировку фокуса (e.Cancel = true), чтобы не мешать оператору вводить данные.
            // Вся проверка корректности дат перенесена на кнопку "2. Перевірити дані".
        }

        private void dgvData_CellClick(object sender, DataGridViewCellEventArgs e)
        {
            if (e.RowIndex >= 0 && e.ColumnIndex >= 0)
            {
                string colName = dgvData.Columns[e.ColumnIndex].Name;

                if (colName == "Початкова дата заміщення" || colName == "Кінцева дата заміщення")
                {
                    System.Drawing.Rectangle displayRect = dgvData.GetCellDisplayRectangle(e.ColumnIndex, e.RowIndex, true);
                    dtp.Size = new System.Drawing.Size(displayRect.Width, displayRect.Height);
                    dtp.Location = new System.Drawing.Point(displayRect.X, displayRect.Y);

                    if (DateTime.TryParse(dgvData.Rows[e.RowIndex].Cells[e.ColumnIndex].Value?.ToString(), out DateTime dt))
                        dtp.Value = dt;
                    else
                        dtp.Value = DateTime.Today;

                    dtp.Visible = true;
                    dtp.Focus();
                }
                else
                {
                    dtp.Visible = false;
                }
            }
        }

        // =========================================================================
        // ГЕНЕРАЦІЯ, ЕКСПОРТ ТА ЗАВАНТАЖЕННЯ
        // =========================================================================
        private void btnGenerateTemplate_Click(object sender, EventArgs e)
        {
            Logger.Info("Генерація шаблону з бази даних...");
            try
            {
                _excelData = new DataTable();
                _excelData.Columns.Add("Назва споживача", typeof(string));
                _excelData.Columns.Add("EIC Код площадки", typeof(string));
                _excelData.Columns.Add("EIC Код точки", typeof(string));
                _excelData.Columns.Add("Назва Точки", typeof(string));
                _excelData.Columns.Add("Зав.номер", typeof(string));
                _excelData.Columns.Add("Початкова дата заміщення", typeof(string));
                _excelData.Columns.Add("Кінцева дата заміщення", typeof(string));
                _excelData.Columns.Add("Зробити заміщення", typeof(string));
                _excelData.Columns.Add("Статус виконання", typeof(string));

                using (OracleConnection conn = new OracleConnection(_dbConnectionString))
                {
                    conn.Open();
                    string sql = @"
                SELECT 
                    (SELECT name FROM ryda.points parent WHERE parent.mid = p.parent) AS consumer_name,
                    p.site_eic,
                    p.point_eic,
                    p.name AS point_name,
                    (SELECT MAX(mtrsn) FROM ryda.meters m WHERE m.mid = p.mid AND m.entype = 7) AS meter_sn
                FROM ryda.points p
                WHERE NVL(p.status, 1) = 1 
                  AND TRIM(p.point_eic) IS NOT NULL 
                  AND p.point_eic <> '*'
                ORDER BY consumer_name, point_name";

                    using (OracleCommand cmd = new OracleCommand(sql, conn))
                    {
                        using (OracleDataReader reader = cmd.ExecuteReader())
                        {
                            string defaultDate = DateTime.Now.AddDays(-1).ToString("dd.MM.yyyy 00:00");
                            string defaultActionVal = cmbDefaultAction.SelectedItem?.ToString() ?? "";

                            while (reader.Read())
                            {
                                DataRow row = _excelData.NewRow();
                                row["Назва споживача"] = reader["consumer_name"]?.ToString();
                                row["EIC Код площадки"] = reader["site_eic"]?.ToString();
                                row["EIC Код точки"] = reader["point_eic"]?.ToString();
                                row["Назва Точки"] = reader["point_name"]?.ToString();
                                row["Зав.номер"] = reader["meter_sn"]?.ToString();
                                row["Початкова дата заміщення"] = defaultDate;
                                row["Кінцева дата заміщення"] = defaultDate;
                                row["Зробити заміщення"] = defaultActionVal;
                                row["Статус виконання"] = "Згенеровано";
                                _excelData.Rows.Add(row);
                            }
                        }
                    }
                }

                BindGrid();
                MessageBox.Show($"Згенеровано точок: {_excelData.Rows.Count}. \n\nВи можете проставити 'А' або 'Р', налаштувати дати, після чого натиснути 'Перевірити дані'.",
                                "Шаблон створено", MessageBoxButtons.OK, MessageBoxIcon.Information);
                btnRunReplace.Enabled = false;
            }
            catch (Exception ex)
            {
                Logger.Error("Помилка генерації шаблону", ex);
                MessageBox.Show($"Помилка генерації: {ex.Message}", "Помилка", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void btnExportTemplate_Click(object sender, EventArgs e)
        {
            dgvData.EndEdit();
            if (_excelData == null || _excelData.Rows.Count == 0) return;

            using (SaveFileDialog sfd = new SaveFileDialog() { Filter = "CSV файл (*.csv)|*.csv", FileName = "Form_AutoReplace.csv" })
            {
                if (sfd.ShowDialog() == DialogResult.OK)
                {
                    try
                    {
                        using (StreamWriter sw = new StreamWriter(sfd.FileName, false, System.Text.Encoding.GetEncoding("windows-1251")))
                        {
                            string[] colNames = new string[_excelData.Columns.Count];
                            for (int i = 0; i < _excelData.Columns.Count; i++) colNames[i] = _excelData.Columns[i].ColumnName;
                            sw.WriteLine(string.Join(";", colNames));

                            foreach (DataRow row in _excelData.Rows)
                            {
                                string[] fields = new string[_excelData.Columns.Count];
                                for (int i = 0; i < _excelData.Columns.Count; i++) fields[i] = row[i]?.ToString().Replace(";", ",");
                                sw.WriteLine(string.Join(";", fields));
                            }
                        }
                        MessageBox.Show("Файл успішно збережено!\nВідкрийте його в Excel, відредагуйте та збережіть як '.xlsx' для подальшого завантаження.", "Успіх", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show("Помилка збереження: " + ex.Message, "Помилка", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
            }
        }

        private void BindGrid()
        {
            dgvData.DataSource = null;
            dgvData.Columns.Clear();
            dgvData.AutoGenerateColumns = false;

            foreach (DataColumn dtCol in _excelData.Columns)
            {
                DataGridViewTextBoxColumn col = new DataGridViewTextBoxColumn
                {
                    Name = dtCol.ColumnName,
                    HeaderText = dtCol.ColumnName,
                    DataPropertyName = dtCol.ColumnName
                };

                if (dtCol.ColumnName == "Початкова дата заміщення" || dtCol.ColumnName == "Кінцева дата заміщення" || dtCol.ColumnName == "Зробити заміщення")
                {
                    col.ReadOnly = false; // Дозволяємо редагування
                }
                else
                {
                    col.ReadOnly = true;
                    // Робимо фон ледь сірим, щоб відрізнявся, але текст — ЧОРНИМ!
                    col.DefaultCellStyle.BackColor = System.Drawing.Color.WhiteSmoke;
                    col.DefaultCellStyle.ForeColor = System.Drawing.Color.Black;
                }
                dgvData.Columns.Add(col);
            }
            dgvData.DataSource = _excelData;
            dgvData.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.AllCells;
        }

        private void btnLoadExcel_Click(object sender, EventArgs e)
        {
            using (OpenFileDialog ofd = new OpenFileDialog() { Filter = "Excel Workbook|*.xlsx|Excel 97-2003|*.xls" })
            {
                if (ofd.ShowDialog() == DialogResult.OK)
                {
                    Logger.Info($"Завантаження Excel: {ofd.FileName}");
                    try
                    {
                        using (var stream = File.Open(ofd.FileName, FileMode.Open, FileAccess.Read))
                        {
                            using (var reader = ExcelReaderFactory.CreateReader(stream))
                            {
                                var dataSet = reader.AsDataSet();
                                DataTable rawData = dataSet.Tables[0];
                                if (rawData.Rows.Count == 0) return;

                                _excelData = new DataTable();
                                DataRow headerRow = rawData.Rows[0];
                                for (int i = 0; i < rawData.Columns.Count; i++)
                                {
                                    string colName = headerRow[i]?.ToString().Trim();
                                    if (string.IsNullOrEmpty(colName)) colName = $"Колонка {i + 1}";
                                    if (_excelData.Columns.Contains(colName)) colName = colName + "_" + i;
                                    _excelData.Columns.Add(colName, typeof(string));
                                }

                                for (int r = 1; r < rawData.Rows.Count; r++)
                                {
                                    DataRow newRow = _excelData.NewRow();
                                    for (int c = 0; c < rawData.Columns.Count; c++) newRow[c] = rawData.Rows[r][c]?.ToString().Trim();
                                    _excelData.Rows.Add(newRow);
                                }
                                BindGrid();
                                btnRunReplace.Enabled = false;
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        Logger.Error("Помилка читання Excel", ex);
                        MessageBox.Show(ex.Message, "Помилка", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
            }
        }

        // =========================================================================
        // ПЕРЕВІРКА І ЗАМІЩЕННЯ
        // =========================================================================
        private void btnValidate_Click(object sender, EventArgs e)
        {
            dgvData.EndEdit();
            if (_excelData == null || _excelData.Rows.Count == 0) return;

            if (!_excelData.Columns.Contains("Статус виконання"))
            {
                _excelData.Columns.Add("Статус виконання", typeof(string));
                BindGrid();
            }

            string colAction = FindColumnName("Зробити заміщення");
            string colEic = FindColumnName("EIC Код точки");
            string colStart = FindColumnName("Початкова дата заміщення");
            string colEnd = FindColumnName("Кінцева дата заміщення");

            if (colAction == null || colEic == null || colStart == null || colEnd == null)
            {
                MessageBox.Show("Не знайдено обов'язкові колонки (EIC Код точки, Початкова дата заміщення, Кінцева дата заміщення, Зробити заміщення).", "Помилка", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            // --- ЗЧИТУЄМО ЛІМІТИ З НАЛАШТУВАНЬ ---
            int minHoles = (int)nudMinHoles.Value;
            int maxHoles = (int)nudMaxHoles.Value;

            int validCount = 0;
            List<DataRow> rowsToRemove = new List<DataRow>();

            using (OracleConnection conn = new OracleConnection(_dbConnectionString))
            {
                try
                {
                    conn.Open();

                    OracleCommand checkCmd = conn.CreateCommand();
                    checkCmd.CommandText = @"
                SELECT COUNT(*) 
                FROM ryda.halfhourold 
                WHERE mid = :p_mid 
                  AND date_time > TRUNC(:p_start) 
                  AND date_time <= (TRUNC(:p_end) + 1)";
                    checkCmd.Parameters.Add(new OracleParameter("p_mid", OracleDbType.Int32));
                    checkCmd.Parameters.Add(new OracleParameter("p_start", OracleDbType.Date));
                    checkCmd.Parameters.Add(new OracleParameter("p_end", OracleDbType.Date));

                    for (int i = 0; i < dgvData.Rows.Count; i++)
                    {
                        DataGridViewRow gridRow = dgvData.Rows[i];
                        if (gridRow.DataBoundItem == null) continue;

                        DataRow dataRow = ((DataRowView)gridRow.DataBoundItem).Row;
                        string type = dataRow[colAction]?.ToString().Trim().ToUpper();

                        if (type == "А" || type == "A" || type == "Р" || type == "P")
                        {
                            string eicCode = dataRow[colEic]?.ToString().Trim();
                            string startStr = dataRow[colStart]?.ToString();
                            string endStr = dataRow[colEnd]?.ToString();

                            if (!DateTime.TryParse(startStr, out DateTime startDate) || !DateTime.TryParse(endStr, out DateTime endDate))
                            {
                                dataRow["Статус виконання"] = "Помилка: Невірний формат дати";
                                gridRow.DefaultCellStyle.BackColor = System.Drawing.Color.LightPink;
                                continue;
                            }
                            if (startDate > endDate)
                            {
                                dataRow["Статус виконання"] = "Помилка: Початкова дата > кінцевої";
                                gridRow.DefaultCellStyle.BackColor = System.Drawing.Color.LightPink;
                                continue;
                            }

                            int status;
                            int mid = GetMidByEic(conn, eicCode, out status);
                            if (mid <= 0)
                            {
                                dataRow["Статус виконання"] = "Помилка: EIC не знайдено в БД";
                                gridRow.DefaultCellStyle.BackColor = System.Drawing.Color.LightPink;
                                continue;
                            }
                            if (status == 0)
                            {
                                dataRow["Статус виконання"] = "Помилка: Точка відключена (Status = 0)";
                                gridRow.DefaultCellStyle.BackColor = System.Drawing.Color.LightPink;
                                continue;
                            }

                            // --- ПЕРЕВІРКА ПРОПУСКІВ ---
                            int expectedCount = (int)(endDate.Date - startDate.Date).TotalDays + 1;
                            expectedCount *= 48; // 48 півгодин у добі

                            checkCmd.Parameters["p_mid"].Value = mid;
                            checkCmd.Parameters["p_start"].Value = startDate.Date;
                            checkCmd.Parameters["p_end"].Value = endDate.Date;

                            int actualCount = Convert.ToInt32(checkCmd.ExecuteScalar());
                            int holesCount = expectedCount - actualCount;

                            // ЯКЩО ДІРОК НЕМАЄ АБО ЇХ КІЛЬКІСТЬ НЕ ПРОЛАЗИТЬ У ТВОЇ ЛІМІТИ — ВИДАЛЯЄМО З ТАБЛИЦІ
                            if (holesCount < minHoles || holesCount > maxHoles)
                            {
                                rowsToRemove.Add(dataRow);
                                continue;
                            }

                            // Якщо все в межах лімітів - підсвічуємо
                            if (type == "А" || type == "A")
                            {
                                dataRow["Статус виконання"] = $"Готово (бракує {holesCount} півгод.)";
                                gridRow.DefaultCellStyle.BackColor = System.Drawing.Color.LightGreen;
                                validCount++;
                            }
                            else
                            {
                                dataRow["Статус виконання"] = $"Відкладено (бракує {holesCount} півгод.)";
                                gridRow.DefaultCellStyle.BackColor = System.Drawing.Color.LightYellow;
                            }
                        }
                        else
                        {
                            dataRow["Статус виконання"] = "Пропущено";
                            gridRow.DefaultCellStyle.BackColor = System.Drawing.Color.White;
                        }
                    }

                    // --- ВИДАЛЯЄМО З ТАБЛИЦІ ВУЗЛИ, ЩО НЕ ПРОЙШЛИ ФІЛЬТР ЛІМІТІВ ---
                    foreach (DataRow r in rowsToRemove)
                    {
                        _excelData.Rows.Remove(r);
                    }

                    btnRunReplace.Enabled = (validCount > 0);
                }
                catch (Exception ex)
                {
                    Logger.Error("Помилка валідації", ex);
                    MessageBox.Show($"Помилка БД: {ex.Message}");
                }
            }
            dgvData.Refresh();
        }

        private void btnRunReplace_Click(object sender, EventArgs e)
        {
            dgvData.EndEdit();

            string colAction = FindColumnName("Зробити заміщення");
            string colEic = FindColumnName("EIC Код точки");
            string colStart = FindColumnName("Початкова дата заміщення");
            string colEnd = FindColumnName("Кінцева дата заміщення");

            int successCount = 0;
            int errorCount = 0;

            // Зчитуємо параметри з нової вкладки налаштувань
            int minHoles = (int)nudMinHoles.Value;
            int maxHoles = (int)nudMaxHoles.Value;
            int maxDepthWeeks = (int)nudDepthWeeks.Value;

            using (OracleConnection conn = new OracleConnection(_dbConnectionString))
            {
                try
                {
                    conn.Open();
                    using (OracleCommand cmd = conn.CreateCommand())
                    {
                        cmd.CommandText = "ryda.p_auto_replace_holes";
                        cmd.CommandType = CommandType.StoredProcedure;

                        OracleParameter pMid = new OracleParameter("p_mid", OracleDbType.Decimal);
                        OracleParameter pTargetDate = new OracleParameter("p_target_date", OracleDbType.Date);
                        OracleParameter pAnalogDate = new OracleParameter("p_analog_date", OracleDbType.Date);
                        OracleParameter pMinHoles = new OracleParameter("p_min_holes", OracleDbType.Decimal);
                        OracleParameter pMaxHoles = new OracleParameter("p_max_holes", OracleDbType.Decimal);
                        OracleParameter pOutMsg = new OracleParameter("p_out_msg", OracleDbType.Varchar2, 2000);
                        pOutMsg.Direction = ParameterDirection.Output;
                        OracleParameter pInsertedCnt = new OracleParameter("p_inserted_cnt", OracleDbType.Decimal);
                        pInsertedCnt.Direction = ParameterDirection.Output;

                        cmd.Parameters.Add(pMid);
                        cmd.Parameters.Add(pTargetDate);
                        cmd.Parameters.Add(pAnalogDate);
                        cmd.Parameters.Add(pMinHoles);
                        cmd.Parameters.Add(pMaxHoles);
                        cmd.Parameters.Add(pOutMsg);
                        cmd.Parameters.Add(pInsertedCnt);

                        for (int i = 0; i < dgvData.Rows.Count; i++)
                        {
                            DataGridViewRow gridRow = dgvData.Rows[i];
                            if (gridRow.DataBoundItem == null) continue;

                            DataRow row = ((DataRowView)gridRow.DataBoundItem).Row;
                            string type = row[colAction]?.ToString().Trim().ToUpper();

                            if (type == "А" || type == "A")
                            {
                                try
                                {
                                    string eicCode = row[colEic]?.ToString().Trim();
                                    DateTime startDate = Convert.ToDateTime(row[colStart]);
                                    DateTime endDate = Convert.ToDateTime(row[colEnd]);

                                    int status;
                                    int mid = GetMidByEic(conn, eicCode, out status);
                                    if (mid <= 0 || status == 0) continue;

                                    string resultLog = "";
                                    bool hasSuccess = false;
                                    bool hasNoDataError = false;

                                    for (DateTime dt = startDate.Date; dt <= endDate.Date; dt = dt.AddDays(1))
                                    {
                                        int dailyInserted = 0;
                                        string dailyMsg = "";

                                        // ЦИКЛ ПО ГЛИБИНІ В ТИЖНЯХ (Шукаємо аналог)
                                        for (int w = 1; w <= maxDepthWeeks; w++)
                                        {
                                            pMid.Value = mid;
                                            pTargetDate.Value = dt;
                                            pAnalogDate.Value = dt.AddDays(-7 * w); // Зсув на W тижнів
                                            pMinHoles.Value = minHoles;
                                            pMaxHoles.Value = maxHoles;

                                            cmd.ExecuteNonQuery();

                                            if (pInsertedCnt.Value != null && pInsertedCnt.Value.ToString() != "null")
                                                dailyInserted = Convert.ToInt32(pInsertedCnt.Value.ToString());

                                            dailyMsg = pOutMsg.Value?.ToString();

                                            // Якщо успішно заміщено АБО взагалі не треба заміщувати (пропущено через ліміти)
                                            if (dailyInserted > 0 || (dailyMsg != null && dailyMsg.StartsWith("Пропущено")))
                                            {
                                                break; // Знайшли що треба, виходимо з циклу тижнів
                                            }
                                        }

                                        if (dailyInserted > 0) hasSuccess = true;
                                        else if (dailyMsg != null && dailyMsg.StartsWith("Немає")) hasNoDataError = true;

                                        // Якщо за всі тижні так і не знайшли аналогів
                                        if (dailyInserted == 0 && dailyMsg != null && dailyMsg.StartsWith("Немає"))
                                            dailyMsg = $"Немає даних (перевірено {maxDepthWeeks} тиж.)";

                                        resultLog += $"[{dt:dd.MM}] {dailyMsg}; ";
                                    }

                                    row["Статус виконання"] = resultLog;

                                    // ФАРБУВАННЯ ЗА РЕЗУЛЬТАТОМ
                                    if (hasSuccess)
                                    {
                                        successCount++;
                                        gridRow.DefaultCellStyle.BackColor = System.Drawing.Color.LightGreen;
                                    }
                                    else if (hasNoDataError)
                                    {
                                        errorCount++;
                                        gridRow.DefaultCellStyle.BackColor = System.Drawing.Color.Orange; // Помаранчевий для відсутності аналогів
                                    }
                                    else
                                    {
                                        gridRow.DefaultCellStyle.BackColor = System.Drawing.Color.LightGray; // Всі дати були "Пропущені" (не було дірок)
                                    }
                                }
                                catch (Exception ex)
                                {
                                    row["Статус виконання"] = "Помилка: " + ex.Message;
                                    gridRow.DefaultCellStyle.BackColor = System.Drawing.Color.LightPink;
                                    errorCount++;
                                }
                            }
                            else if (type == "Р" || type == "P")
                            {
                                row["Статус виконання"] = "Потребує ручного втручання";
                            }
                        }
                    }
                    dgvData.Refresh();
                    MessageBox.Show($"Обробку завершено!\nУспішно заміщено точок: {successCount}\nНемає даних (помаранчеві) або помилок: {errorCount}", "Звіт", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
                catch (Exception ex)
                {
                    MessageBox.Show($"Глобальна помилка БД: {ex.Message}", "Помилка", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }

        private int GetMidByEic(OracleConnection conn, string eic, out int status)
        {
            status = 0;
            if (string.IsNullOrEmpty(eic)) return 0;

            using (OracleCommand cmd = conn.CreateCommand())
            {
                cmd.CommandText = "SELECT mid, NVL(status, 1) as status FROM ryda.points WHERE point_eic = :eic";
                cmd.Parameters.Add(new OracleParameter("eic", OracleDbType.Varchar2)).Value = eic;

                using (OracleDataReader reader = cmd.ExecuteReader())
                {
                    if (reader.Read())
                    {
                        status = Convert.ToInt32(reader["status"]);
                        return Convert.ToInt32(reader["mid"]);
                    }
                }
            }
            return 0;
        }

        private string FindColumnName(string keyword)
        {
            foreach (DataColumn col in _excelData.Columns)
                if (col.ColumnName.IndexOf(keyword, StringComparison.OrdinalIgnoreCase) >= 0)
                    return col.ColumnName;
            return null;
        }

        // Перемикання статусу (Порожньо -> А -> Р -> Порожньо) по кліку мишкою
        private void dgvData_CellMouseClick(object sender, DataGridViewCellMouseEventArgs e)
        {
            if (e.RowIndex >= 0 && e.ColumnIndex >= 0)
            {
                if (dgvData.Columns[e.ColumnIndex].Name == "Зробити заміщення")
                {
                    var cell = dgvData.Rows[e.RowIndex].Cells[e.ColumnIndex];
                    string current = cell.Value?.ToString().Trim().ToUpper() ?? "";

                    if (current == "") cell.Value = "А";
                    else if (current == "А" || current == "A") cell.Value = "Р";
                    else cell.Value = "";

                    dgvData.EndEdit(); // Одразу застосовуємо зміни
                }
            }
        }

        // Миттєве фарбування клітинок "Зробити заміщення"
        private void dgvData_CellFormatting(object sender, DataGridViewCellFormattingEventArgs e)
        {
            if (e.RowIndex >= 0 && e.ColumnIndex >= 0 && dgvData.Columns[e.ColumnIndex].Name == "Зробити заміщення")
            {
                string val = e.Value?.ToString().Trim().ToUpper() ?? "";
                if (val == "А" || val == "A")
                {
                    e.CellStyle.BackColor = System.Drawing.Color.LightGreen;
                    e.CellStyle.ForeColor = System.Drawing.Color.Black;
                }
                else if (val == "Р" || val == "P")
                {
                    e.CellStyle.BackColor = System.Drawing.Color.LightCoral;
                    e.CellStyle.ForeColor = System.Drawing.Color.Black;
                }
                else
                {
                    e.CellStyle.BackColor = System.Drawing.Color.White;
                }
            }
        }

        // =========================================================================
        // Табка Білінга тут  
        // =========================================================================
        private DataTable _billingSourceTable;

        private async void btnFetchBilling_Click(object sender, EventArgs e)
        {
            btnFetchBilling.Enabled = false;
            this.Cursor = Cursors.WaitCursor;

            try
            {
                DateTime selectedDate = dtpBillingPeriod.Value;
                string yearMonth = selectedDate.ToString("yyyyMM"); // Формат для API: YYYYMM
                DateTime startDate = new DateTime(selectedDate.Year, selectedDate.Month, 1);
                DateTime endDate = startDate.AddMonths(1);

                // Зчитуємо тип споживача з ComboBox (1 - Юр.особи, 0 - Побутові)
                int isJur = 1;
                if (cmbJurType.SelectedItem != null && cmbJurType.SelectedItem.ToString().StartsWith("0"))
                {
                    isJur = 0;
                }

                Logger.Info($"==========================================================================");
                Logger.Info($"[Billing Workflow] РОЗПОЧАТО ЗВІРКУ З БІЛІНГОМ");
                Logger.Info($"[Billing Workflow] Період: {yearMonth} ({startDate:dd.MM.yyyy} - {endDate:dd.MM.yyyy}), isJur: {isJur}");

                var billingApiClient = new BillingApiClient();

                // КРОК 0. Попередня діагностика з'єднання з сервером 10.67.1.188 (Ping -> TCP 443 -> HTTP)
                Logger.Info("[Billing Workflow] Крок 0: Запуск діагностики мережевого з'єднання з 10.67.1.188...");
                string testReport = await billingApiClient.TestConnectionAsync();
                Logger.Info(testReport);

                // КРОК 1. Зчитування даних АСКОЕ з Oracle (у фоновому потоці Task.Run)
                Logger.Info("[Billing Workflow] Крок 1: Запуск SQL-запиту до Oracle (агрегація ER z halfhourold)...");
                Stopwatch swSql = Stopwatch.StartNew();

                DataTable dtAskoe = await Task.Run(() => GetAskoeConsumptionData(startDate, endDate));

                swSql.Stop();
                Logger.Info($"[Billing Workflow] Крок 1 ЗАВЕРШЕНО: Отримано {dtAskoe.Rows.Count} точок з Oracle за {swSql.ElapsedMilliseconds} ms.");

                if (dtAskoe.Rows.Count == 0)
                {
                    Logger.Warn("[Billing Workflow] У базі даних АСКОЕ не знайдено активних точок з EIC-кодами.");
                    MessageBox.Show("У базі даних АСКОЕ не знайдено активних точок з EIC-кодами.", "Інформація", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return;
                }

                // КРОК 2. Збір списку унікальних EIC-кодів для виклику API
                List<string> eicList = new List<string>();
                foreach (DataRow row in dtAskoe.Rows)
                {
                    string eic = row["POINT_EIC"]?.ToString()?.Trim();
                    if (!string.IsNullOrEmpty(eic) && eic != "*")
                    {
                        eicList.Add(eic);
                    }
                }
                Logger.Info($"[Billing Workflow] Зібрано {eicList.Count} EIC-кодів для відправки у REST API");

                // КРОК 3. Виклик REST API Білінгу
                Logger.Info("[Billing Workflow] Крок 2: Надсилання пакетних запитів до API білінгу...");
                Dictionary<string, decimal> billingData = await billingApiClient.GetConsumptionAsync(yearMonth, isJur, eicList);
                Logger.Info($"[Billing Workflow] Крок 2 ЗАВЕРШЕНО: Отримано відповіді від API для {billingData.Count} EIC-кодів");

                // КРОК 4. Формування підсумкової таблиці для відображення (у фоновому потоці)
                Logger.Info("[Billing Workflow] Крок 3: Формування порівняльної таблиці...");
                _billingSourceTable = await Task.Run(() => BuildBillingCompareTable(dtAskoe, billingData));

                // КРОК 5. Відображення даних у DataGridView з урахуванням фільтра розбіжностей
                Logger.Info("[Billing Workflow] Крок 4: Прив'язка даних до DataGridView...");
                BindBillingGrid();

                Logger.Info($"[Billing Workflow] УСПІШНО ЗАВЕРШЕНО! Відображено {_billingSourceTable.Rows.Count} рядків.");
                Logger.Info($"==========================================================================");

                MessageBox.Show($"Звірку завершено успішно!\nОброблено точок: {_billingSourceTable.Rows.Count}",
                                "Звірка з Білінгом", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                Logger.Error("[Billing Workflow] КРИТИЧНА ПОМИЛКА під час звірки з Білінгом", ex);
                MessageBox.Show($"Помилка під час звірки:\n{ex.Message}", "Помилка", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                btnFetchBilling.Enabled = true;
                this.Cursor = Cursors.Default;
            }
        }
        /// <summary>
        /// Зчитує агреговані обсяги споживання (ER) з Oracle АСКОЕ за місяць
        /// </summary>
        private DataTable GetAskoeConsumptionData(DateTime startDate, DateTime endDate)
        {
            DataTable dt = new DataTable();

            using (OracleConnection conn = new OracleConnection(_dbConnectionString))
            {
                conn.Open();

                // Оптимізований запит із JOIN замість підзапиту
                string sql = @"
            SELECT 
                p.mid AS POINT_ID,
                parent.name AS CONSUMER_NAME,
                p.site_eic AS SITE_EIC,
                p.point_eic AS POINT_EIC,
                p.name AS POINT_NAME,
                NVL(SUM(h.er), 0) AS ASKOE_VAL
            FROM ryda.points p
            LEFT JOIN ryda.points parent ON parent.mid = p.parent
            LEFT JOIN ryda.halfhourold h 
                   ON h.mid = p.mid 
                  AND h.date_time >= :p_start_date 
                  AND h.date_time < :p_end_date
            WHERE NVL(p.status, 1) = 1
              AND TRIM(p.point_eic) IS NOT NULL
              AND p.point_eic <> '*'
            GROUP BY p.mid, parent.name, p.site_eic, p.point_eic, p.name
            ORDER BY CONSUMER_NAME, POINT_NAME";

                using (OracleCommand cmd = new OracleCommand(sql, conn))
                {
                    cmd.Parameters.Add(new OracleParameter("p_start_date", OracleDbType.Date)).Value = startDate;
                    cmd.Parameters.Add(new OracleParameter("p_end_date", OracleDbType.Date)).Value = endDate;

                    using (OracleDataAdapter adapter = new OracleDataAdapter(cmd))
                    {
                        adapter.Fill(dt);
                    }
                }
            }

            return dt;
        }

        /// <summary>
        /// Зводить дані АСКОЕ та Білінгу у єдину DataTable для гріда
        /// </summary>
        private DataTable BuildBillingCompareTable(DataTable dtAskoe, Dictionary<string, decimal> billingData)
        {
            DataTable dtResult = new DataTable();
            dtResult.Columns.Add("POINT_ID", typeof(int));
            dtResult.Columns.Add("Назва споживача", typeof(string));
            dtResult.Columns.Add("EIC площадки", typeof(string));
            dtResult.Columns.Add("EIC точки", typeof(string));
            dtResult.Columns.Add("Назва точки", typeof(string));
            dtResult.Columns.Add("Білінг (кВт·год)", typeof(decimal));
            dtResult.Columns.Add("АСКОЕ (кВт·год)", typeof(decimal));
            dtResult.Columns.Add("Різниця", typeof(decimal));
            dtResult.Columns.Add("Статус", typeof(string));

            foreach (DataRow row in dtAskoe.Rows)
            {
                int pointId = Convert.ToInt32(row["POINT_ID"]);
                string consumerName = row["CONSUMER_NAME"]?.ToString();
                string siteEic = row["SITE_EIC"]?.ToString();
                string pointEic = row["POINT_EIC"]?.ToString()?.Trim();
                string pointName = row["POINT_NAME"]?.ToString();
                decimal askoeVal = Convert.ToDecimal(row["ASKOE_VAL"]);

                decimal billingVal = 0;
                bool foundInBilling = false;

                if (!string.IsNullOrEmpty(pointEic) && billingData.TryGetValue(pointEic, out decimal bVal))
                {
                    billingVal = bVal;
                    foundInBilling = true;
                }

                decimal diffVal = billingVal - askoeVal;

                string status = "ОК";
                if (!foundInBilling)
                {
                    status = "Відсутній у Білінгу";
                }
                else if (diffVal != 0)
                {
                    status = "Розбіжність";
                }

                DataRow newRow = dtResult.NewRow();
                newRow["POINT_ID"] = pointId;
                newRow["Назва споживача"] = consumerName;
                newRow["EIC площадки"] = siteEic;
                newRow["EIC точки"] = pointEic;
                newRow["Назва точки"] = pointName;
                newRow["Білінг (кВт·год)"] = billingVal;
                newRow["АСКОЕ (кВт·год)"] = askoeVal;
                newRow["Різниця"] = diffVal;
                newRow["Статус"] = status;

                dtResult.Rows.Add(newRow);
            }

            return dtResult;
        }

        private void BindBillingGrid()
        {
            if (_billingSourceTable == null) return;

            DataView dv = new DataView(_billingSourceTable);
            if (chkOnlyDiff.Checked)
            {
                // Фільтруємо лише рядки, де є різниця або відсутні дані
                dv.RowFilter = "[Різниця] <> 0 OR [Статус] = 'Відсутній у Білінгу'";
            }

            dgvBilling.DataSource = dv;

            // Приховуємо системний ID точки
            if (dgvBilling.Columns.Contains("POINT_ID"))
                dgvBilling.Columns["POINT_ID"].Visible = false;

            // Дозволяємо редагувати лише колонки EIC
            foreach (DataGridViewColumn col in dgvBilling.Columns)
            {
                if (col.Name == "EIC площадки" || col.Name == "EIC точки")
                {
                    col.ReadOnly = false;
                    col.DefaultCellStyle.BackColor = System.Drawing.Color.LightYellow;
                }
                else
                {
                    col.ReadOnly = true;
                }
            }

            dgvBilling.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.AllCells;
        }

        private void FilterBillingGrid()
        {
            if (dgvBilling.DataSource is DataView dv)
            {
                if (chkOnlyDiff.Checked)
                    dv.RowFilter = "[Різниця] <> 0 OR [Статус] = 'Відсутній у Білінгу'";
                else
                    dv.RowFilter = "";
            }
        }

        // 1. Збереження EIC у базі даних Oracle
        private void btnSaveEic_Click(object sender, EventArgs e)
        {
            dgvBilling.EndEdit();
            if (_billingSourceTable == null || _billingSourceTable.Rows.Count == 0) return;

            int updatedCount = 0;

            using (OracleConnection conn = new OracleConnection(_dbConnectionString))
            {
                try
                {
                    conn.Open();
                    using (OracleCommand cmd = conn.CreateCommand())
                    {
                        cmd.CommandText = @"
                    UPDATE ryda.points 
                       SET site_eic = TRIM(:p_site_eic), 
                           point_eic = TRIM(:p_point_eic) 
                     WHERE mid = :p_mid";

                        cmd.Parameters.Add(new OracleParameter("p_site_eic", OracleDbType.Varchar2));
                        cmd.Parameters.Add(new OracleParameter("p_point_eic", OracleDbType.Varchar2));
                        cmd.Parameters.Add(new OracleParameter("p_mid", OracleDbType.Int32));

                        foreach (DataRow row in _billingSourceTable.Rows)
                        {
                            if (row.RowState == DataRowState.Modified)
                            {
                                cmd.Parameters["p_site_eic"].Value = row["EIC площадки"]?.ToString();
                                cmd.Parameters["p_point_eic"].Value = row["EIC точки"]?.ToString();
                                cmd.Parameters["p_mid"].Value = Convert.ToInt32(row["POINT_ID"]);

                                cmd.ExecuteNonQuery();
                                updatedCount++;
                            }
                        }
                    }

                    _billingSourceTable.AcceptChanges();
                    MessageBox.Show($"Успішно оновлено EIC-кодів для {updatedCount} точок!", "Збереження БД", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
                catch (Exception ex)
                {
                    Logger.Error("Помилка збереження EIC в БД", ex);
                    MessageBox.Show($"Помилка збереження в БД: {ex.Message}", "Помилка", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }

        // 2. Колірне підсвічування рядків з розбіжностями
        private void dgvBilling_CellFormatting(object sender, DataGridViewCellFormattingEventArgs e)
        {
            if (e.RowIndex >= 0 && dgvBilling.Rows[e.RowIndex].DataBoundItem is DataRowView drv)
            {
                string status = drv["Статус"]?.ToString();
                decimal diff = Convert.ToDecimal(drv["Різниця"]);

                if (status == "Розбіжність" || diff != 0)
                {
                    dgvBilling.Rows[e.RowIndex].DefaultCellStyle.BackColor = System.Drawing.Color.LightPink;
                }
                else if (status == "Відсутній у Білінгу")
                {
                    dgvBilling.Rows[e.RowIndex].DefaultCellStyle.BackColor = System.Drawing.Color.PeachPuff;
                }
                else
                {
                    dgvBilling.Rows[e.RowIndex].DefaultCellStyle.BackColor = System.Drawing.Color.White;
                }
            }
        }

        // 3. Експорт звіту про розбіжності у CSV
        private void btnExportBilling_Click(object sender, EventArgs e)
        {
            dgvBilling.EndEdit();
            if (dgvBilling.Rows.Count == 0) return;

            using (SaveFileDialog sfd = new SaveFileDialog() { Filter = "CSV файл (*.csv)|*.csv", FileName = $"Billing_Compare_{dtpBillingPeriod.Value:yyyy_MM}.csv" })
            {
                if (sfd.ShowDialog() == DialogResult.OK)
                {
                    try
                    {
                        using (StreamWriter sw = new StreamWriter(sfd.FileName, false, System.Text.Encoding.GetEncoding("windows-1251")))
                        {
                            List<string> headers = new List<string>();
                            foreach (DataGridViewColumn col in dgvBilling.Columns)
                            {
                                if (col.Visible) headers.Add(col.HeaderText);
                            }
                            sw.WriteLine(string.Join(";", headers));

                            foreach (DataGridViewRow row in dgvBilling.Rows)
                            {
                                if (row.IsNewRow) continue;
                                List<string> cells = new List<string>();
                                foreach (DataGridViewColumn col in dgvBilling.Columns)
                                {
                                    if (col.Visible)
                                    {
                                        string val = row.Cells[col.Index].Value?.ToString() ?? "";
                                        // Очищаємо текст від розривів рядка та заменяємо крапку з комою
                                        val = val.Replace("\r", "").Replace("\n", " ").Replace(";", ",");
                                        cells.Add(val);
                                    }
                                }
                                sw.WriteLine(string.Join(";", cells));
                            }
                        }
                        MessageBox.Show("Звіт успішно збережено!", "Успіх", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show($"Помилка збереження: {ex.Message}", "Помилка", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
            }
        }
        // =========================================================================
        // МАСОВЕ ЗАВАНТАЖЕННЯ EIC-КОДІВ З EXCEL
        // =========================================================================
        private DataGridView dgvEicImport;
        private DataTable _dtEicImport;
        private CheckBox chkOverwriteEic;
        private void InitializeEicImportTab()
        {
            TabPage tabEic = new TabPage("Імпорт EIC (Excel)");

            Panel pnlTop = new Panel { Height = 50, Dock = DockStyle.Top };
            Button btnLoad = new Button { Text = "1. Вибрати Excel", Left = 10, Top = 10, Width = 150 };
            Button btnRun = new Button { Text = "2. Завантажити в БД", Left = 170, Top = 10, Width = 150 };
            // СТВОРЮЄМО ЧЕКБОКС
            chkOverwriteEic = new CheckBox
            {
                Text = "Перезаписувати існуючі EIC-коди",
                Left = 330,
                Top = 13,
                Width = 250,
                Checked = false // За замовчуванням вимкнений
            };

            btnLoad.Click += BtnLoadEic_Click;
            btnRun.Click += BtnRunEicImport_Click;

            pnlTop.Controls.Add(btnLoad);
            pnlTop.Controls.Add(btnRun);
            pnlTop.Controls.Add(chkOverwriteEic); // ДОДАЄМО НА ПАНЕЛЬ

            dgvEicImport = new DataGridView
            {
                Dock = DockStyle.Fill,
                AllowUserToAddRows = false,
                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.AllCells,
                ReadOnly = true
            };

            // Підписка на фарбування результатів
            // Оновлюємо фарбування: тепер є ЖОВТИЙ колір для пропущених
            dgvEicImport.CellFormatting += (s, e) =>
            {
                if (e.RowIndex >= 0 && dgvEicImport.Columns[e.ColumnIndex].Name == "Результат завантаження")
                {
                    string val = e.Value?.ToString() ?? "";
                    if (val.StartsWith("Успіх"))
                        dgvEicImport.Rows[e.RowIndex].DefaultCellStyle.BackColor = System.Drawing.Color.LightGreen;
                    else if (val.StartsWith("Пропущено"))
                        dgvEicImport.Rows[e.RowIndex].DefaultCellStyle.BackColor = System.Drawing.Color.LightYellow;
                    else if (val.StartsWith("Помилка"))
                        dgvEicImport.Rows[e.RowIndex].DefaultCellStyle.BackColor = System.Drawing.Color.LightPink;
                }
            };

            tabEic.Controls.Add(dgvEicImport);
            tabEic.Controls.Add(pnlTop);

            // Вставляємо нову вкладку на ПЕРШЕ місце (індекс 0)
            tabControl1.TabPages.Insert(0, tabEic);
        }

        private void BtnLoadEic_Click(object sender, EventArgs e)
        {
            using (OpenFileDialog ofd = new OpenFileDialog() { Filter = "Excel Files|*.xlsx;*.xls" })
            {
                if (ofd.ShowDialog() == DialogResult.OK)
                {
                    try
                    {
                        using (var stream = File.Open(ofd.FileName, FileMode.Open, FileAccess.Read))
                        {
                            using (var reader = ExcelReaderFactory.CreateReader(stream))
                            {
                                var dataSet = reader.AsDataSet(new ExcelDataSetConfiguration()
                                {
                                    ConfigureDataTable = (_) => new ExcelDataTableConfiguration() { UseHeaderRow = true }
                                });

                                _dtEicImport = dataSet.Tables[0];

                                // Додаємо колонку для результату, якщо її немає
                                if (!_dtEicImport.Columns.Contains("Результат завантаження"))
                                {
                                    _dtEicImport.Columns.Add("Результат завантаження", typeof(string));
                                }

                                dgvEicImport.DataSource = _dtEicImport;
                                MessageBox.Show($"Завантажено {_dtEicImport.Rows.Count} рядків.\n\nПрограма шукатиме колонки, назви яких містять слова:\n'лічильн', 'площад' та 'точк'.", "Успіх", MessageBoxButtons.OK, MessageBoxIcon.Information);
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        MessageBox.Show("Помилка читання Excel. Переконайтеся, що файл не відкритий в іншій програмі.\n" + ex.Message, "Помилка", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    }
                }
            }
        }

        private void BtnRunEicImport_Click(object sender, EventArgs e)
        {
            if (_dtEicImport == null || _dtEicImport.Rows.Count == 0) return;

            // РОЗУМНИЙ ПОШУК КОЛОНОК (ігноруємо зайве, розрізняємо "Назву" та "Код")
            string colMeter = null, colSite = null, colPoint = null;
            foreach (DataColumn col in _dtEicImport.Columns)
            {
                string name = col.ColumnName.ToLower();

                // Шукаємо лічильник
                if (name.Contains("номер") && name.Contains("лічильник"))
                    colMeter = col.ColumnName;
                // Шукаємо EIC площадки (має бути 'площ' + 'код' або 'еіс')
                else if (name.Contains("площ") && (name.Contains("код") || name.Contains("еіс") || name.Contains("eic")))
                    colSite = col.ColumnName;
                // Шукаємо EIC точки (має бути 'точк' + 'код' або 'еіс' - щоб відсіяти просто "Назву точки обліку")
                else if (name.Contains("точк") && (name.Contains("код") || name.Contains("еіс") || name.Contains("eic")))
                    colPoint = col.ColumnName;
            }

            if (colMeter == null)
            {
                MessageBox.Show("Не знайдено колонку з номером лічильника! Переконайтеся, що заголовок містить слова 'Номер лічильника'.", "Помилка", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            int success = 0, errors = 0;
            using (OracleConnection conn = new OracleConnection(_dbConnectionString))
            {
                try
                {
                    conn.Open();
                    using (OracleCommand cmd = conn.CreateCommand())
                    {
                        // Викликаємо нашу нову процедуру з БД
                        cmd.CommandText = "ryda.p_import_eic_by_meter";
                        cmd.CommandType = CommandType.StoredProcedure;

                        cmd.Parameters.Add(new OracleParameter("p_mtrsn", OracleDbType.Varchar2));
                        cmd.Parameters.Add(new OracleParameter("p_site_eic", OracleDbType.Varchar2));
                        cmd.Parameters.Add(new OracleParameter("p_point_eic", OracleDbType.Varchar2));
                        cmd.Parameters.Add(new OracleParameter("p_overwrite", OracleDbType.Int32));

                        OracleParameter pOutMsg = new OracleParameter("p_out_msg", OracleDbType.Varchar2, 2000);
                        pOutMsg.Direction = ParameterDirection.Output;
                        cmd.Parameters.Add(pOutMsg);

                        foreach (DataRow row in _dtEicImport.Rows)
                        {
                            string mtrsn = row[colMeter]?.ToString().Trim();

                            // Якщо номеру лічильника немає (наприклад, порожні рядки в кінці Excel) - пропускаємо
                            if (string.IsNullOrEmpty(mtrsn))
                            {
                                row["Результат завантаження"] = "Пропущено (порожній лічильник)";
                                continue;
                            }

                            string siteEic = colSite != null ? row[colSite]?.ToString().Trim() : null;
                            string pointEic = colPoint != null ? row[colPoint]?.ToString().Trim() : null;

                            cmd.Parameters["p_mtrsn"].Value = mtrsn;
                            cmd.Parameters["p_site_eic"].Value = string.IsNullOrEmpty(siteEic) ? null : siteEic;
                            cmd.Parameters["p_point_eic"].Value = string.IsNullOrEmpty(pointEic) ? null : pointEic;
                            // ПЕРЕДАЄМО СТАН ЧЕКБОКСА (1 або 0)
                            cmd.Parameters["p_overwrite"].Value = chkOverwriteEic.Checked ? 1 : 0;

                            cmd.ExecuteNonQuery();

                            string result = pOutMsg.Value?.ToString();
                            row["Результат завантаження"] = result;

                            if (result != null && result.StartsWith("Успіх")) success++;
                            else errors++;
                        }
                    }
                    dgvEicImport.Refresh();
                    MessageBox.Show($"Імпорт завершено!\n\nУспішно оновлено: {success}\nПомилок/не знайдено: {errors}", "Звіт", MessageBoxButtons.OK, MessageBoxIcon.Information);
                }
                catch (Exception ex)
                {
                    Logger.Error("Глобальна помилка імпорту EIC", ex);
                    MessageBox.Show("Помилка БД: " + ex.Message, "Помилка", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }
        private async void btnTestConnection_Click(object sender, EventArgs e)
        {
            btnTestConnection.Enabled = false;
            this.Cursor = Cursors.WaitCursor;

            try
            {
                Logger.Info("[Test Connection] Запуск ручної перевірки з'єднання з сервером Білінгу...");

                var billingApiClient = new BillingApiClient();

                // Виклики виконання Ping + TCP 443 + HTTP API у фоновому потоці
                string report = await Task.Run(() => billingApiClient.TestConnectionAsync());

                Logger.Info(report);

                // Формуємо статус за результатами тесту
                bool isOk = report.Contains("[3/3 HTTP API OK]");
                MessageBoxIcon icon = isOk ? MessageBoxIcon.Information : MessageBoxIcon.Warning;
                string caption = isOk ? "Зв'язок успішний" : "Увага: Є проблеми зі зв'язком";

                MessageBox.Show(report, caption, MessageBoxButtons.OK, icon);
            }
            catch (Exception ex)
            {
                Logger.Error("[Test Connection] Помилка виконання тесту", ex);
                MessageBox.Show($"Помилка під час перевірки з'єднання:\n{ex.Message}", "Помилка", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                btnTestConnection.Enabled = true;
                this.Cursor = Cursors.Default;
            }
        }


    }
}