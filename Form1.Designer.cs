namespace AutoReplaceApp
{
    partial class Form1
    {
        private System.ComponentModel.IContainer components = null;

        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Код, автоматически созданный конструктором форм Windows

        private void InitializeComponent()
        {
            this.tabControl1 = new System.Windows.Forms.TabControl();
            this.tabPage1 = new System.Windows.Forms.TabPage();
            this.dgvData = new System.Windows.Forms.DataGridView();
            this.panel1 = new System.Windows.Forms.Panel();
            this.btnGenerateTemplate = new System.Windows.Forms.Button();
            this.btnLoadExcel = new System.Windows.Forms.Button();
            this.btnExportTemplate = new System.Windows.Forms.Button();
            this.btnValidate = new System.Windows.Forms.Button();
            this.btnRunReplace = new System.Windows.Forms.Button();
            this.tabPage2 = new System.Windows.Forms.TabPage();
            this.dgvBilling = new System.Windows.Forms.DataGridView();
            this.panelBillingTop = new System.Windows.Forms.Panel();
            this.btnExportBilling = new System.Windows.Forms.Button();
            this.btnSaveEic = new System.Windows.Forms.Button();
            this.btnFetchBilling = new System.Windows.Forms.Button();
            this.chkOnlyDiff = new System.Windows.Forms.CheckBox();
            this.cmbJurType = new System.Windows.Forms.ComboBox();
            this.labelJurType = new System.Windows.Forms.Label();
            this.labelBillngPeriod = new System.Windows.Forms.Label();
            this.dtpBillingPeriod = new System.Windows.Forms.DateTimePicker();
            this.tabPage3 = new System.Windows.Forms.TabPage();
            this.label3 = new System.Windows.Forms.Label();
            this.nudDepthWeeks = new System.Windows.Forms.NumericUpDown();
            this.label2 = new System.Windows.Forms.Label();
            this.nudMaxHoles = new System.Windows.Forms.NumericUpDown();
            this.label1 = new System.Windows.Forms.Label();
            this.nudMinHoles = new System.Windows.Forms.NumericUpDown();
            this.tabPage4 = new System.Windows.Forms.TabPage();
            this.txtHelp = new System.Windows.Forms.TextBox();
            this.btnTestConnection = new System.Windows.Forms.Button();
            this.tabControl1.SuspendLayout();
            this.tabPage1.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dgvData)).BeginInit();
            this.panel1.SuspendLayout();
            this.tabPage2.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dgvBilling)).BeginInit();
            this.panelBillingTop.SuspendLayout();
            this.tabPage3.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.nudDepthWeeks)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.nudMaxHoles)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.nudMinHoles)).BeginInit();
            this.tabPage4.SuspendLayout();
            this.SuspendLayout();
            // 
            // tabControl1
            // 
            this.tabControl1.Controls.Add(this.tabPage1);
            this.tabControl1.Controls.Add(this.tabPage2);
            this.tabControl1.Controls.Add(this.tabPage3);
            this.tabControl1.Controls.Add(this.tabPage4);
            this.tabControl1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tabControl1.Location = new System.Drawing.Point(0, 0);
            this.tabControl1.Name = "tabControl1";
            this.tabControl1.SelectedIndex = 0;
            this.tabControl1.Size = new System.Drawing.Size(958, 725);
            this.tabControl1.TabIndex = 0;
            // 
            // tabPage1
            // 
            this.tabPage1.Controls.Add(this.dgvData);
            this.tabPage1.Controls.Add(this.panel1);
            this.tabPage1.Location = new System.Drawing.Point(4, 22);
            this.tabPage1.Name = "tabPage1";
            this.tabPage1.Padding = new System.Windows.Forms.Padding(3);
            this.tabPage1.Size = new System.Drawing.Size(950, 699);
            this.tabPage1.TabIndex = 0;
            this.tabPage1.Text = "Автозаміщення";
            this.tabPage1.UseVisualStyleBackColor = true;
            // 
            // dgvData
            // 
            this.dgvData.AllowUserToAddRows = false;
            this.dgvData.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.dgvData.Dock = System.Windows.Forms.DockStyle.Fill;
            this.dgvData.Location = new System.Drawing.Point(3, 85);
            this.dgvData.Name = "dgvData";
            this.dgvData.Size = new System.Drawing.Size(944, 611);
            this.dgvData.TabIndex = 4;
            // 
            // panel1
            // 
            this.panel1.Controls.Add(this.btnGenerateTemplate);
            this.panel1.Controls.Add(this.btnLoadExcel);
            this.panel1.Controls.Add(this.btnExportTemplate);
            this.panel1.Controls.Add(this.btnValidate);
            this.panel1.Controls.Add(this.btnRunReplace);
            this.panel1.Dock = System.Windows.Forms.DockStyle.Top;
            this.panel1.Location = new System.Drawing.Point(3, 3);
            this.panel1.Name = "panel1";
            this.panel1.Size = new System.Drawing.Size(944, 82);
            this.panel1.TabIndex = 3;
            // 
            // btnGenerateTemplate
            // 
            this.btnGenerateTemplate.Location = new System.Drawing.Point(18, 12);
            this.btnGenerateTemplate.Name = "btnGenerateTemplate";
            this.btnGenerateTemplate.Size = new System.Drawing.Size(150, 25);
            this.btnGenerateTemplate.TabIndex = 3;
            this.btnGenerateTemplate.Text = "1. Згенерувати з БД";
            this.btnGenerateTemplate.UseVisualStyleBackColor = true;
            this.btnGenerateTemplate.Click += new System.EventHandler(this.btnGenerateTemplate_Click);
            // 
            // btnLoadExcel
            // 
            this.btnLoadExcel.Location = new System.Drawing.Point(185, 12);
            this.btnLoadExcel.Name = "btnLoadExcel";
            this.btnLoadExcel.Size = new System.Drawing.Size(150, 25);
            this.btnLoadExcel.TabIndex = 0;
            this.btnLoadExcel.Text = "або Завантажити Excel";
            this.btnLoadExcel.UseVisualStyleBackColor = true;
            this.btnLoadExcel.Click += new System.EventHandler(this.btnLoadExcel_Click);
            // 
            // btnExportTemplate
            // 
            this.btnExportTemplate.Location = new System.Drawing.Point(352, 12);
            this.btnExportTemplate.Name = "btnExportTemplate";
            this.btnExportTemplate.Size = new System.Drawing.Size(150, 25);
            this.btnExportTemplate.TabIndex = 4;
            this.btnExportTemplate.Text = "Експорт шаблону (CSV)";
            this.btnExportTemplate.UseVisualStyleBackColor = true;
            this.btnExportTemplate.Click += new System.EventHandler(this.btnExportTemplate_Click);
            // 
            // btnValidate
            // 
            this.btnValidate.Location = new System.Drawing.Point(18, 45);
            this.btnValidate.Name = "btnValidate";
            this.btnValidate.Size = new System.Drawing.Size(150, 25);
            this.btnValidate.TabIndex = 2;
            this.btnValidate.Text = "2. Перевірити дані";
            this.btnValidate.UseVisualStyleBackColor = true;
            this.btnValidate.Click += new System.EventHandler(this.btnValidate_Click);
            // 
            // btnRunReplace
            // 
            this.btnRunReplace.Enabled = false;
            this.btnRunReplace.Location = new System.Drawing.Point(185, 45);
            this.btnRunReplace.Name = "btnRunReplace";
            this.btnRunReplace.Size = new System.Drawing.Size(150, 25);
            this.btnRunReplace.TabIndex = 1;
            this.btnRunReplace.Text = "3. Виконати заміщення";
            this.btnRunReplace.UseVisualStyleBackColor = true;
            this.btnRunReplace.Click += new System.EventHandler(this.btnRunReplace_Click);
            // 
            // tabPage2
            // 
            this.tabPage2.Controls.Add(this.dgvBilling);
            this.tabPage2.Controls.Add(this.panelBillingTop);
            this.tabPage2.Location = new System.Drawing.Point(4, 22);
            this.tabPage2.Name = "tabPage2";
            this.tabPage2.Padding = new System.Windows.Forms.Padding(3);
            this.tabPage2.Size = new System.Drawing.Size(950, 699);
            this.tabPage2.TabIndex = 1;
            this.tabPage2.Text = "Біллінг та EIC";
            this.tabPage2.UseVisualStyleBackColor = true;
            // 
            // dgvBilling
            // 
            this.dgvBilling.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.dgvBilling.Dock = System.Windows.Forms.DockStyle.Fill;
            this.dgvBilling.Location = new System.Drawing.Point(3, 73);
            this.dgvBilling.Name = "dgvBilling";
            this.dgvBilling.Size = new System.Drawing.Size(944, 623);
            this.dgvBilling.TabIndex = 1;
            // 
            // panelBillingTop
            // 
            this.panelBillingTop.Controls.Add(this.btnTestConnection);
            this.panelBillingTop.Controls.Add(this.btnExportBilling);
            this.panelBillingTop.Controls.Add(this.btnSaveEic);
            this.panelBillingTop.Controls.Add(this.btnFetchBilling);
            this.panelBillingTop.Controls.Add(this.chkOnlyDiff);
            this.panelBillingTop.Controls.Add(this.cmbJurType);
            this.panelBillingTop.Controls.Add(this.labelJurType);
            this.panelBillingTop.Controls.Add(this.labelBillngPeriod);
            this.panelBillingTop.Controls.Add(this.dtpBillingPeriod);
            this.panelBillingTop.Dock = System.Windows.Forms.DockStyle.Top;
            this.panelBillingTop.Location = new System.Drawing.Point(3, 3);
            this.panelBillingTop.Name = "panelBillingTop";
            this.panelBillingTop.Size = new System.Drawing.Size(944, 70);
            this.panelBillingTop.TabIndex = 0;
            // 
            // btnExportBilling
            // 
            this.btnExportBilling.Location = new System.Drawing.Point(319, 41);
            this.btnExportBilling.Name = "btnExportBilling";
            this.btnExportBilling.Size = new System.Drawing.Size(122, 23);
            this.btnExportBilling.TabIndex = 7;
            this.btnExportBilling.Text = "Експорт у CSV";
            this.btnExportBilling.UseVisualStyleBackColor = true;
            // 
            // btnSaveEic
            // 
            this.btnSaveEic.Location = new System.Drawing.Point(164, 41);
            this.btnSaveEic.Name = "btnSaveEic";
            this.btnSaveEic.Size = new System.Drawing.Size(134, 23);
            this.btnSaveEic.TabIndex = 6;
            this.btnSaveEic.Text = "2. Зберегти EIC в БД";
            this.btnSaveEic.UseVisualStyleBackColor = true;
            // 
            // btnFetchBilling
            // 
            this.btnFetchBilling.Location = new System.Drawing.Point(20, 41);
            this.btnFetchBilling.Name = "btnFetchBilling";
            this.btnFetchBilling.Size = new System.Drawing.Size(123, 23);
            this.btnFetchBilling.TabIndex = 5;
            this.btnFetchBilling.Text = "1. Звірити з Білінгом";
            this.btnFetchBilling.UseVisualStyleBackColor = true;
            // 
            // chkOnlyDiff
            // 
            this.chkOnlyDiff.AutoSize = true;
            this.chkOnlyDiff.Location = new System.Drawing.Point(639, 3);
            this.chkOnlyDiff.Name = "chkOnlyDiff";
            this.chkOnlyDiff.Size = new System.Drawing.Size(248, 17);
            this.chkOnlyDiff.TabIndex = 4;
            this.chkOnlyDiff.Text = "Показувати тільки розбіжності (Різниця ≠ 0)";
            this.chkOnlyDiff.UseVisualStyleBackColor = true;
            // 
            // cmbJurType
            // 
            this.cmbJurType.FormattingEnabled = true;
            this.cmbJurType.ImeMode = System.Windows.Forms.ImeMode.NoControl;
            this.cmbJurType.Items.AddRange(new object[] {
            "1 - Юридичні особи",
            "2 - Побутові"});
            this.cmbJurType.Location = new System.Drawing.Point(490, 2);
            this.cmbJurType.Name = "cmbJurType";
            this.cmbJurType.Size = new System.Drawing.Size(121, 21);
            this.cmbJurType.TabIndex = 3;
            // 
            // labelJurType
            // 
            this.labelJurType.AutoSize = true;
            this.labelJurType.Location = new System.Drawing.Point(361, 3);
            this.labelJurType.Name = "labelJurType";
            this.labelJurType.Size = new System.Drawing.Size(120, 13);
            this.labelJurType.TabIndex = 2;
            this.labelJurType.Text = "Вибір типу споживача:";
            // 
            // labelBillngPeriod
            // 
            this.labelBillngPeriod.AutoSize = true;
            this.labelBillngPeriod.Location = new System.Drawing.Point(17, 8);
            this.labelBillngPeriod.Name = "labelBillngPeriod";
            this.labelBillngPeriod.Size = new System.Drawing.Size(74, 13);
            this.labelBillngPeriod.TabIndex = 1;
            this.labelBillngPeriod.Text = "Вибір місяця:";
            // 
            // dtpBillingPeriod
            // 
            this.dtpBillingPeriod.CustomFormat = "MM.yyyy р.";
            this.dtpBillingPeriod.Format = System.Windows.Forms.DateTimePickerFormat.Custom;
            this.dtpBillingPeriod.Location = new System.Drawing.Point(146, 2);
            this.dtpBillingPeriod.Name = "dtpBillingPeriod";
            this.dtpBillingPeriod.ShowUpDown = true;
            this.dtpBillingPeriod.Size = new System.Drawing.Size(197, 20);
            this.dtpBillingPeriod.TabIndex = 0;
            // 
            // tabPage3
            // 
            this.tabPage3.Controls.Add(this.label3);
            this.tabPage3.Controls.Add(this.nudDepthWeeks);
            this.tabPage3.Controls.Add(this.label2);
            this.tabPage3.Controls.Add(this.nudMaxHoles);
            this.tabPage3.Controls.Add(this.label1);
            this.tabPage3.Controls.Add(this.nudMinHoles);
            this.tabPage3.Location = new System.Drawing.Point(4, 22);
            this.tabPage3.Name = "tabPage3";
            this.tabPage3.Padding = new System.Windows.Forms.Padding(3);
            this.tabPage3.Size = new System.Drawing.Size(950, 699);
            this.tabPage3.TabIndex = 2;
            this.tabPage3.Text = "Налаштування";
            this.tabPage3.UseVisualStyleBackColor = true;
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Location = new System.Drawing.Point(20, 105);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(266, 13);
            this.label3.TabIndex = 4;
            this.label3.Text = "Глибина пошуку аналога (максимум тижнів назад):";
            // 
            // nudDepthWeeks
            // 
            this.nudDepthWeeks.Location = new System.Drawing.Point(360, 103);
            this.nudDepthWeeks.Maximum = new decimal(new int[] {
            52,
            0,
            0,
            0});
            this.nudDepthWeeks.Minimum = new decimal(new int[] {
            1,
            0,
            0,
            0});
            this.nudDepthWeeks.Name = "nudDepthWeeks";
            this.nudDepthWeeks.Size = new System.Drawing.Size(60, 20);
            this.nudDepthWeeks.TabIndex = 5;
            this.nudDepthWeeks.Value = new decimal(new int[] {
            4,
            0,
            0,
            0});
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(20, 65);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(245, 13);
            this.label2.TabIndex = 2;
            this.label2.Text = "Максимальна кількість пропусків для запуску:";
            // 
            // nudMaxHoles
            // 
            this.nudMaxHoles.Location = new System.Drawing.Point(360, 63);
            this.nudMaxHoles.Maximum = new decimal(new int[] {
            48,
            0,
            0,
            0});
            this.nudMaxHoles.Name = "nudMaxHoles";
            this.nudMaxHoles.Size = new System.Drawing.Size(60, 20);
            this.nudMaxHoles.TabIndex = 3;
            this.nudMaxHoles.Value = new decimal(new int[] {
            40,
            0,
            0,
            0});
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(20, 25);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(324, 13);
            this.label1.TabIndex = 0;
            this.label1.Text = "Мінімальна кількість пропусків (дірок) для запуску заміщення:";
            // 
            // nudMinHoles
            // 
            this.nudMinHoles.Location = new System.Drawing.Point(360, 23);
            this.nudMinHoles.Maximum = new decimal(new int[] {
            48,
            0,
            0,
            0});
            this.nudMinHoles.Name = "nudMinHoles";
            this.nudMinHoles.Size = new System.Drawing.Size(60, 20);
            this.nudMinHoles.TabIndex = 1;
            this.nudMinHoles.Value = new decimal(new int[] {
            9,
            0,
            0,
            0});
            // 
            // tabPage4
            // 
            this.tabPage4.Controls.Add(this.txtHelp);
            this.tabPage4.Location = new System.Drawing.Point(4, 22);
            this.tabPage4.Name = "tabPage4";
            this.tabPage4.Padding = new System.Windows.Forms.Padding(3);
            this.tabPage4.Size = new System.Drawing.Size(950, 699);
            this.tabPage4.TabIndex = 3;
            this.tabPage4.Text = "Довідка";
            this.tabPage4.UseVisualStyleBackColor = true;
            // 
            // txtHelp
            // 
            this.txtHelp.BackColor = System.Drawing.SystemColors.Window;
            this.txtHelp.Dock = System.Windows.Forms.DockStyle.Fill;
            this.txtHelp.Font = new System.Drawing.Font("Segoe UI", 10F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(204)));
            this.txtHelp.Location = new System.Drawing.Point(3, 3);
            this.txtHelp.Multiline = true;
            this.txtHelp.Name = "txtHelp";
            this.txtHelp.ReadOnly = true;
            this.txtHelp.ScrollBars = System.Windows.Forms.ScrollBars.Vertical;
            this.txtHelp.Size = new System.Drawing.Size(944, 693);
            this.txtHelp.TabIndex = 0;
            // 
            // btnTestConnection
            // 
            this.btnTestConnection.Location = new System.Drawing.Point(465, 41);
            this.btnTestConnection.Name = "btnTestConnection";
            this.btnTestConnection.Size = new System.Drawing.Size(114, 23);
            this.btnTestConnection.TabIndex = 8;
            this.btnTestConnection.Text = "Перевірити зв\'язок";
            this.btnTestConnection.UseVisualStyleBackColor = true;
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(958, 725);
            this.Controls.Add(this.tabControl1);
            this.Name = "Form1";
            this.Text = "Form1";
            this.tabControl1.ResumeLayout(false);
            this.tabPage1.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.dgvData)).EndInit();
            this.panel1.ResumeLayout(false);
            this.tabPage2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.dgvBilling)).EndInit();
            this.panelBillingTop.ResumeLayout(false);
            this.panelBillingTop.PerformLayout();
            this.tabPage3.ResumeLayout(false);
            this.tabPage3.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.nudDepthWeeks)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.nudMaxHoles)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.nudMinHoles)).EndInit();
            this.tabPage4.ResumeLayout(false);
            this.tabPage4.PerformLayout();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.TabControl tabControl1;
        private System.Windows.Forms.TabPage tabPage1;
        private System.Windows.Forms.TabPage tabPage2;
        private System.Windows.Forms.TabPage tabPage3;
        private System.Windows.Forms.TabPage tabPage4;
        private System.Windows.Forms.Button btnRunReplace;
        private System.Windows.Forms.Button btnLoadExcel;
        private System.Windows.Forms.Panel panel1;
        private System.Windows.Forms.DataGridView dgvData;
        private System.Windows.Forms.Button btnValidate;
        private System.Windows.Forms.Button btnGenerateTemplate;
        private System.Windows.Forms.Button btnExportTemplate;
        private System.Windows.Forms.NumericUpDown nudMinHoles;
        private System.Windows.Forms.NumericUpDown nudMaxHoles;
        private System.Windows.Forms.NumericUpDown nudDepthWeeks;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.TextBox txtHelp;
        private System.Windows.Forms.Panel panelBillingTop;
        private System.Windows.Forms.DataGridView dgvBilling;
        private System.Windows.Forms.DateTimePicker dtpBillingPeriod;
        private System.Windows.Forms.Label labelBillngPeriod;
        private System.Windows.Forms.Label labelJurType;
        private System.Windows.Forms.ComboBox cmbJurType;
        private System.Windows.Forms.CheckBox chkOnlyDiff;
        private System.Windows.Forms.Button btnExportBilling;
        private System.Windows.Forms.Button btnSaveEic;
        private System.Windows.Forms.Button btnFetchBilling;
        private System.Windows.Forms.Button btnTestConnection;
    }
}