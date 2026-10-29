--------------------------------------------------------------------------------
-- 1. НАКАТ СПЕЦИФІКАЦІЇ ПАКЕТА (PACKAGE IS)
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE ryda.editfeeders_pg IS
  -- пакет работы с точками
  -- дата создания 19/10/2001 (Сечин А.А.)
------------------------------------------------------------------------------------------------------------------------
  -- Процедура вставки (полное кол-во параметров)
 PROCEDURE ins_p(
  an_parent NUMBER,                                                                                                                                   --Родитель
                  an_type NUMBER,                                                                                                                   --Тип точки
                                 av_name VARCHAR2,                                                                                                   --Название
                                                  av_short_name VARCHAR2,                                                                    --Краткое название
                                                                         an_er_position NUMBER, an_q1_position NUMBER, an_ed_position NUMBER,
 an_q3_position NUMBER, an_smart NUMBER,                                                                                                         --Интеллектуал
                                        an_q1234 NUMBER,                                                                                            --Квадранты
                                                        an_canal NUMBER,                                                                         --Номер канала
                                                                        av_cellnum VARCHAR2,                                                     --Номер ячейки
                                                                                            an_power NUMBER,                                 --Мощность перв кВ
                                                                                                            an_current1 NUMBER,               --Напряжение перв
 an_current2 NUMBER,                                                                                                                        --Напряжение вторич
                    an_kc NUMBER,                                                                                                                       --Коэфф
                                 an_tag NUMBER,                                                                                                     --Тег связи
                                               av_info VARCHAR2,                                                                               --Доп информация
                                                                an_power2 NUMBER,                                                          --Мощность вторич кВ
                                                                                 an_metkc NUMBER,                                    --Коэф прошитый в счетчике
                                                                                                 an_abc NUMBER,                          --Заземленная нейтраль
                                                                                                               an_calcbill NUMBER,    --Верифицировать суточные
 an_calcmonths NUMBER,                                                                                                                --Верифицировать месячные
                      an_inverted NUMBER,                                                                                                            --Инверсия
                                         an_switch NUMBER,                                                                                  --Признак обводника
                                                          an_usd NUMBER,                                                                                  --УСД
                                                                        an_nblock NUMBER,                                  -- блокировка автоматического опроса
                                                                                         an_dataabsence NUMBER, an_commctrl NUMBER, an_techctrl NUMBER,
 an_main NUMBER,                                                                                         --nMainPoint - основная точка учёта (для дублирования)
                av_verifyparam VARCHAR2,                                                                                               -- Параметры верификации
                                        av_addparams VARCHAR2,                                                                      -- Дополнительные параметры
                                                              av_importcode VARCHAR2,                                                    -- Связной код импорта
                                                                                     an_lockcorrecttime NUMBER,                 -- блокировка коррекции времени
 av_code VARCHAR2,                                                                                                                                 -- код точки
                  av_verifyday VARCHAR2,                                                                                      -- Параметры верификации суточных
                                        an_classtn NUMBER,                                                                                  --Класс тотности ТН
                                                          an_classtt NUMBER,                                                                --Класс тотности ТТ
                                                                            an_timezonew NUMBER,                                          --Веменная зона зимой
                                                                                                an_timezones NUMBER,                      --Веменная зона летом
                                                                                                                    an_opposite NUMBER,
                                                                                                                       --id, информация о противоположной точке
 an_norder NUMBER,                                                                                                            --порядок в дереве по умолчанию 0
                  an_nintegr NUMBER,                                                                                                        --период интеграции
                                    an_lockswitch NUMBER, an_nwithswitch NUMBER, an_nrescanal NUMBER, av_vnote VARCHAR2, av_account VARCHAR2,
 an_mid OUT NUMBER                                                                                                                                   --Ид точки
);

--------------------------------------------------------------------------------------------------------------------------------------------------------------
PROCEDURE ins_p(
 an_parent NUMBER, an_type NUMBER, av_name VARCHAR2, av_short_name VARCHAR2, an_er_position NUMBER, an_q1_position NUMBER, an_ed_position NUMBER,
 an_q3_position NUMBER, an_smart NUMBER, an_q1234 NUMBER, an_canal NUMBER, av_cellnum VARCHAR2, an_power NUMBER, an_current1 NUMBER, an_current2 NUMBER,
 an_kc NUMBER, an_tag NUMBER, av_info VARCHAR2, an_power2 NUMBER, an_metkc NUMBER, an_abc NUMBER, an_calcbill NUMBER, an_calcmonths NUMBER,
 an_inverted NUMBER, an_switch NUMBER, an_usd NUMBER, an_nblock NUMBER, an_dataabsence NUMBER, an_commctrl NUMBER, an_techctrl NUMBER,
 an_main NUMBER, av_verifyparam VARCHAR2, av_addparams VARCHAR2, av_importcode VARCHAR2, an_lockcorrecttime NUMBER, av_code VARCHAR2,
 av_verifyday VARCHAR2, an_classtn NUMBER, an_classtt NUMBER, an_timezonew NUMBER, an_timezones NUMBER, an_opposite NUMBER, an_norder NUMBER,
 an_nintegr NUMBER, an_lockswitch NUMBER, an_nwithswitch NUMBER, an_nrescanal NUMBER, av_vnote VARCHAR2, av_account VARCHAR2,
 av_mms VARCHAR2, av_eic VARCHAR2, an_ctype NUMBER,
 an_mid OUT NUMBER, 
 an_status IN NUMBER DEFAULT 1, av_eic_point IN VARCHAR2 DEFAULT NULL, av_eic_site IN VARCHAR2 DEFAULT NULL
 );

---------------------------------------------------------------------------------------------------------------------------------------------------------------
    -- Процедура вставки АСКУЭ (синхронизация с АСРПП)
 PROCEDURE ins_p_a(
 an_parent NUMBER,                                                                                                                                   --Родитель
                  an_type NUMBER,                                                                                                                   --Тип точки
                                 av_name VARCHAR2,                                                                                                   --Название
                                                  av_short_name VARCHAR2,                                                                    --Краткое название
                                                                         an_er_position NUMBER, an_q1_position NUMBER, an_ed_position NUMBER,
 an_q3_position NUMBER, an_smart NUMBER,                                                                                                         --Интеллектуал
                                        an_q1234 NUMBER,                                                                                            --Квадранты
                                                        av_cellnum VARCHAR2,                                                                     --Номер ячейки
                                                                            an_power NUMBER,                                                         --Мощность
                                                                                            an_current1 NUMBER,                               --Напряжение перв
                                                                                                               an_current2 NUMBER,          --Напряжение вторич
 an_kc NUMBER,                                                                                                                                          --Коэфф
              an_point NUMBER,                                                                                                                 --Ид точки АСРПП
                              an_power2 NUMBER,                                                                                            --Мощность вторич кВ
                                               an_ptype NUMBER, an_order NUMBER, an_mid OUT NUMBER                                                   --Ид точки
 );

------------------------------------------------------------------------------------------------------------------------
 PROCEDURE upd_p_b(an_mid NUMBER, an_test NUMBER                                                                                                     --Ид точки
                                                );

------------------------------------------------------------------------------------------------------------------------
  -- Процедура обновления данных АСКУЭ
 PROCEDURE upd_p_a(
 an_mid NUMBER,                                                                                                                                      --Ид точки
               an_parent NUMBER,                                                                                                                     --Родитель
                                an_type NUMBER,                                                                                                     --Тип точки
                                               av_name VARCHAR2,                                                                                     --Название
                                                                av_short_name VARCHAR2,                                                      --Краткое название
                                                                                       an_er_position NUMBER, an_q1_position NUMBER, an_ed_position NUMBER,
 an_q3_position NUMBER, an_smart NUMBER,                                                                                                         --Интеллектуал
                                        an_q1234 NUMBER,                                                                                            --Квадранты
                                                        av_cellnum VARCHAR2,                                                                     --Номер ячейки
                                                                            an_power NUMBER,                                                         --Мощность
                                                                                            an_current1 NUMBER,                               --Напряжение перв
                                                                                                               an_current2 NUMBER,          --Напряжение вторич
 an_kc NUMBER,                                                                                                                                          --Коэфф
              an_power2 NUMBER                                                                                                             --Мощность вторич кВ
 --  an_metkc       NUMBER --Коэф прошитый в счетчике
 );

------------------------------------------------------------------------------------------------------------------------
  -- Процедура вставки при синхронизации базы (дочерняя и родительская АСКУЭ)
 PROCEDURE ins_p_synchro(
 an_parent NUMBER,                                                                                                                                   --Родитель
                  an_type NUMBER,                                                                                                                   --Тип точки
                                 av_name VARCHAR2,                                                                                                   --Название
                                                  av_short_name VARCHAR2,                                                                    --Краткое название
                                                                         an_smart NUMBER,                                                        --Интеллектуал
                                                                                         an_q1234 NUMBER,                                           --Квадранты
                                                                                                         av_cellnum VARCHAR2,                    --Номер ячейки
                                                                                                                             an_power NUMBER,        --Мощность
 an_current1 NUMBER,                                                                                                                          --Напряжение перв
                    an_current2 NUMBER,                                                                                                     --Напряжение вторич
                                       an_kc NUMBER,                                                                                                    --Коэфф
                                                    an_root NUMBER,                                                                --Ид точки в родительской БД
                                                                   an_power2 NUMBER,                                                       --Мощность вторич кВ
                                                                                    an_mid OUT NUMBER                                                --Ид точки
 );

------------------------------------------------------------------------------------------------------------------------
  -- Процедура удаления данных
 PROCEDURE del_p(an_mid NUMBER                                                                                                                       --Ид точки
                              );

------------------------------------------------------------------------------------------------------------------------
--Процедура обновления счетчика АСКУЭ
 PROCEDURE upd_meters_a(
 an_mid NUMBER,                                                                                                                                      --Ид точки
               an_entype NUMBER,                                                                                                                       --ENTYPE
                                av_smart VARCHAR2,                                                                                                      --SMART
                                                  av_mtrsn VARCHAR2,                                                                                    --MTRSN
                                                                    ad_date_time DATE,                                                              --DATE_TIME
                                                                                      an_digits NUMBER,                                                --DIGITS
                                                                                                       av_mtype VARCHAR2,                               --MTYPE
                                                                                                                         an_mcurrent NUMBER,         --MCURRENT
 an_mpower NUMBER,                                                                                                                                     --MPOWER
                  an_mconst NUMBER,                                                                                                                    --MCONST
                                   an_mclass NUMBER,                                                                                                   --MCLASS
                                                    an_myear NUMBER,                                                                                    --MYEAR
                                                                    an_mquarter NUMBER                                                               --MQUARTER
 );

------------------------------------------------------------------------------------------------------------------------
 FUNCTION insgroup(an_mid NUMBER)
  RETURN NUMBER;

------------------------------------------------------------------------------------------------------------------------
--Устанавливает параметры простых потерь
 PROCEDURE setaddparam(
 an_mid NUMBER,                                                                                                                                      --Ид точки
               an_wastepercentcalc NUMBER,                                                                                                         --Тип потерь
                                          an_workinghours NUMBER,                                                                                 --Часы работы
                                                                 an_fullhours NUMBER,                                                      --Полные часы работы
                                                                                     an_line_loss NUMBER,                                     --Портери в линии
                                                                                                         an_act_loss NUMBER,                 --Потери акт транс
 an_react_loss NUMBER,                                                                                                                     --Потери реакт транс
                      an_recompens NUMBER,                                                                                               --Тип расчета реактива
                                          an_calcpointtype NUMBER DEFAULT NULL,                                                          -- Тип расчетной точки
                                                                               an_gid NUMBER DEFAULT NULL                                    --ид расчет группы
 );

------------------------------------------------------------------------------------------------------------------------
     -- Нормативные параметры точки
 PROCEDURE setcalcparam_p(
 an_mid NUMBER,                                                                                                                                      --Ид точки
               at_date common_pg.tt_number,                                                                                             --Дата ввода в действие
                                           at_currpower common_pg.tt_number,                                                                         --Мощность
                                                                            at_monthconsumpt common_pg.tt_number,                                --Месяч расход
 at_kc common_pg.tt_number                                                                                                                     --Коэф пересчета
 );
------------------------------------------------------------------------------------------------------------------------
   -- Процедура вставки (полное кол-во параметров)
 PROCEDURE upd_p(
 an_mid NUMBER,                                                                                                                                      --Ид точки
               an_parent NUMBER,                                                                                                                     --Родитель
                                an_type NUMBER,                                                                                                     --Тип точки
                                               av_name VARCHAR2,                                                                                     --Название
                                                                av_short_name VARCHAR2,                                                      --Краткое название
                                                                                       an_er_position NUMBER, an_q1_position NUMBER, an_ed_position NUMBER,
 an_q3_position NUMBER, an_smart NUMBER,                                                                                                         --Интеллектуал
                                        an_q1234 NUMBER,                                                                                            --Квадранты
                                                        an_canal NUMBER,                                                                         --Номер канала
                                                                        av_cellnum VARCHAR2,                                                     --Номер ячейки
                                                                                            an_power NUMBER,                                         --Мощность
                                                                                                            an_current1 NUMBER,               --Напряжение перв
 an_current2 NUMBER,                                                                                                                        --Напряжение вторич
                    an_kc NUMBER,                                                                                                                       --Коэфф
                                 an_tag NUMBER,                                                                                                     --Тег связи
                                               av_info VARCHAR2,                                                                               --Доп информация
                                                                an_power2 NUMBER,                                                          --Мощность вторич кВ
                                                                                 an_metkc NUMBER,                                    --Коэф прошитый в счетчике
                                                                                                 an_abc NUMBER,                          --Заземленная нейтраль
                                                                                                               an_calcbill NUMBER,    --Верифицировать суточные
 an_calcmonths NUMBER,                                                                                                                --Верифицировать месячные
                      an_inverted NUMBER,                                                                                                            --Инверсия
                                         an_switch NUMBER,                                                                                  --Признак обводника
                                                          an_usd NUMBER,                                                                                  --УСД
                                                                        an_nblock NUMBER,                                              --Блокировка авт. опроса
                                                                                         an_dataabsence NUMBER, an_commctrl NUMBER, an_techctrl NUMBER,
 an_main NUMBER,                                                                                         --nMainPoint - основная точка учёта (для дублирования)
                av_verifyparam VARCHAR2,                                                                                               -- Параметры верификации
                                        av_addparams VARCHAR2,                                                                      -- Дополнительные параметры
                                                              av_importcode VARCHAR2,                                                    -- Связной код импорта
                                                                                     an_lockcorrecttime NUMBER,                 -- блокировка коррекции времени
 av_code VARCHAR2,                                                                                                                                 -- код точки
                  av_verifyday VARCHAR2,                                                                                      -- Параметры верификации суточных
                                        an_classtn NUMBER,                                                                                  --Класс тотности ТН
                                                          an_classtt NUMBER,                                                                --Класс тотности ТТ
                                                                            an_timezonew NUMBER,                                          --Веменная зона зимой
                                                                                                an_timezones NUMBER,                      --Веменная зона летом
                                                                                                                    an_opposite NUMBER,
                                                                                                                       --id, информация о противоположной точке
 an_norder NUMBER,                                                                                                            --порядок в дереве по умолчанию 0
                  an_nintegr NUMBER,                                                                                                        --период интеграции
                                    an_lockswitch NUMBER,                                                                                  --не переходит на ОВ
                                                         an_nwithswitch NUMBER,                                                            --данные с учетом ОВ
                                                                               an_nrescanal NUMBER, av_vnote VARCHAR2, av_account VARCHAR2
 );

------------------------------------------------------------------------------------------------------------------------
-- Процедура обновления данных (с полным набором параметров + параметры MMS + нові поля)
 PROCEDURE upd_p(
 an_mid NUMBER, an_parent NUMBER, an_type NUMBER, av_name VARCHAR2, av_short_name VARCHAR2, an_er_position NUMBER, an_q1_position NUMBER, an_ed_position NUMBER,
 an_q3_position NUMBER, an_smart NUMBER, an_q1234 NUMBER, an_canal NUMBER, av_cellnum VARCHAR2, an_power NUMBER, an_current1 NUMBER, an_current2 NUMBER,
 an_kc NUMBER, an_tag NUMBER, av_info VARCHAR2, an_power2 NUMBER, an_metkc NUMBER, an_abc NUMBER, an_calcbill NUMBER, an_calcmonths NUMBER,
 an_inverted NUMBER, an_switch NUMBER, an_usd NUMBER, an_nblock NUMBER, an_dataabsence NUMBER, an_commctrl NUMBER, an_techctrl NUMBER,
 an_main NUMBER, av_verifyparam VARCHAR2, av_addparams VARCHAR2, av_importcode VARCHAR2, an_lockcorrecttime NUMBER, av_code VARCHAR2,
 av_verifyday VARCHAR2, an_classtn NUMBER, an_classtt NUMBER, an_timezonew NUMBER, an_timezones NUMBER, an_opposite NUMBER, an_norder NUMBER,
 an_nintegr NUMBER, an_lockswitch NUMBER, an_nwithswitch NUMBER, an_nrescanal NUMBER, av_vnote VARCHAR2, av_account VARCHAR2,
 av_mms VARCHAR2, av_eic VARCHAR2, an_ctype NUMBER,
 an_status IN NUMBER DEFAULT -1, av_eic_point IN VARCHAR2 DEFAULT CHR(0), av_eic_site IN VARCHAR2 DEFAULT CHR(0)
 );

------------------------------------------------------------------------------------------------------------------------
 -- Процедура обновления данных (с неполным набором параметров)
 PROCEDURE upd_p(
 an_mid NUMBER,                                                                                                                                      --Ид точки
               av_importcode VARCHAR2,                                                                                                   -- Связной код импорта
                                      an_canal NUMBER,                                                                                           --Номер канала
                                                      an_tag NUMBER,                                                                                --Тег связи
                                                                    an_er_position NUMBER, an_q1_position NUMBER, an_ed_position NUMBER, an_q3_position NUMBER,
 av_info VARCHAR2,                                                                                                                             --Доп информация
                  an_nblock NUMBER,                                                                                                    --Блокировка авт. опроса
                                   an_dataabsence NUMBER, an_commctrl NUMBER, an_techctrl NUMBER, an_lockcorrecttime NUMBER,    -- блокировка коррекции времени
 an_timezonew NUMBER,                                                                                                                    --Временная зона зимой
                     an_timezones NUMBER,                                                                                                --Временная зона летом
                                         an_rescanal NUMBER
 );                                                                                                                                             -- 16 параметра

---------------------------------------------------------------------------------------------------------------------
--Процедура обновления параметров
 PROCEDURE upd_last_save(
 an_mid NUMBER,                                                                                                                                      --Ид точки
               ad_profile DATE,                                                                                            -- Дата постедней считанного профиля
                               ad_halfhour DATE,                                                                       -- Дата постедней считанного получасовки
                                                ad_bill DATE,                                                  -- Дата постедней считанного суточного показания
 ad_month DATE                                                                                                 -- Дата постедней считанного месячного показания
 );

------------------------------------------------------------------------------------------------------------------------
  --Процедура добавления пустой строки в last_save
 PROCEDURE ins_last_save(an_mid NUMBER,                                                                                                              --Ид точки
                                       av_state VARCHAR2 DEFAULT NULL, an_state_cod NUMBER DEFAULT 0, an_clock NUMBER DEFAULT 0);

------------------------------------------------------------------------------------------------------------------------
   -- Пересчитывает расход по показаниям счетчика и ГН
 PROCEDURE recalcdiff(an_mid NUMBER, ad_from DATE, an_onyformula NUMBER DEFAULT NULL);                                                                       --расход

------------------------------------------------------------------------------------------------------------------------
 --Процедура удаления данных из БД
 PROCEDURE delete_data(
 an_mid NUMBER,                                                                                                                                      --Ид точки
               ad_profile DATE,                                                                                      -- Дата > которой удаляются данные профиля
                               ad_halfhour DATE,                                                                          -- Дата > которой удаляются данные ГН
                                                ad_bill DATE,                                                       -- Дата > которой удаляются данные Суточных
                                                             ad_month DATE,                                      --  Дата > которой удаляются месячные Суточных
                                                                           ad_profile_e DATE DEFAULT NULL,          -- Дата <= которой удаляются данные профиля
 ad_halfhour_e DATE DEFAULT NULL,                                                                                        -- Дата <= которой удаляются данные ГН
                                 ad_bill_e DATE DEFAULT NULL,                                                      -- Дата <= которой удаляются данные Суточных
                                                             ad_month_e DATE DEFAULT NULL,                      --  Дата <= которой удаляются месячные Суточных
 ad_journal DATE DEFAULT NULL,                                                                                       -- Дата > которой удаляются данные Журнала
                              ad_journal_e DATE DEFAULT NULL,                                                       -- Дата <= которой удаляются данные Журнала
                                                             ad_currpower DATE DEFAULT NULL,                     --  Дата > которой удаляются мгновенные данные
 ad_currpower_e DATE DEFAULT NULL,                                                                              --  Дата <= которой удаляются мгновенные данные
                                  an_withreload NUMBER DEFAULT 1                                                                     --Признак сдвига LAST_SAVE
 );

------------------------------------------------------------------------------------------------------------------------
--ищем точку (an_mid - точка старта)
 FUNCTION findpoint(
 an_mid NUMBER, av_name VARCHAR2, av_code VARCHAR2, av_mtrsn VARCHAR2, av_pmid VARCHAR2 DEFAULT NULL, an_pointtype NUMBER DEFAULT NULL,
 av_canal VARCHAR2 DEFAULT NULL, av_account VARCHAR2 DEFAULT NULL
 )
  RETURN NUMBER
;
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--ищем объект в дереве точек учета. дереве групп, каналах оапроса, каналах приема и рассылки макетов
 PROCEDURE findpoint(
                       an_pointtype NUMBER, av_pmid VARCHAR2 DEFAULT NULL, av_name VARCHAR2 DEFAULT NULL, av_shortname VARCHAR2 DEFAULT NULL, 
                         av_code VARCHAR2 DEFAULT NULL, av_mtrsn VARCHAR2 DEFAULT NULL, av_canal VARCHAR2 DEFAULT NULL, av_account VARCHAR2 DEFAULT NULL, 
                           av_note VARCHAR2 DEFAULT NULL,  av_vcode VARCHAR2 DEFAULT NULL, av_vimportcode VARCHAR2 DEFAULT NULL, acur_t OUT common_pg.tcur
                      );
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 PROCEDURE recompens_p(acur_t OUT common_pg.tcur);

------------------------------------------------------------------------------------------------------------------------
 PROCEDURE calcpointtype_p(acur_t OUT common_pg.tcur);

-----------------------------------------------------------------------------------------------------------------------
 PROCEDURE naccperiod_p(an_mid NUMBER, acur_t OUT common_pg.tcur);

-----------------------------------------------------------------------------------------------------------------------
 PROCEDURE connectaccperiod_p(an_mid NUMBER, acur_t OUT common_pg.tcur);

----------------------------------------------------------------------------------------------------------------------
 PROCEDURE nperiod_p(an_mid NUMBER, acur_t OUT common_pg.tcur);

-----------------------------------------------------------------------------------------------------------------------
--дерево точек
 PROCEDURE readnode_p(an_mid NUMBER, an_parent NUMBER, acur_t OUT common_pg.tcur);

------------------------------------------------------------------------------------------------------------------------
--счетчики для точки
 PROCEDURE readcounter_p(an_mid NUMBER, acur_t OUT common_pg.tcur);

----------------------------------------------------------------------------------------------------------------------
--потери для точки
 PROCEDURE readlossts_p(an_mid NUMBER, acur_t OUT common_pg.tcur);

----------------------------------------------------------------------------------------------------------------------
--рассчетная группа для точки
 PROCEDURE readgroup_p(an_mid NUMBER, acur_t OUT common_pg.tcur);

-----------------------------------------------------------------------------------------------------------------------
 PROCEDURE smart_p(an_mid NUMBER, av_sm OUT VARCHAR2);

-----------------------------------------------------------------------------------------------------------------------
 PROCEDURE get_submenu_p(an_fid NUMBER, an_monitor NUMBER, an_gid NUMBER, acur_t OUT common_pg.tcur);

-----------------------------------------------------------------------------------------------------------------------
 PROCEDURE get_acc(an_role_id NUMBER, acur_t OUT common_pg.tcur);

----------------------------------------------------------------------------------------------------------------------
 PROCEDURE nmainpoint_p(an_mid NUMBER, acur_t OUT common_pg.tcur);

-----------------------------------------------------------------------------------------------------------------------
 PROCEDURE nopposite_p(an_mid NUMBER, acur_t OUT common_pg.tcur);

-----------------------------------------------------------------------------------------------------------------------
--возвращает измерения и их глобальные индексы для конкретной точки
--Виленская Н.Б. 14.11.2008
 PROCEDURE get_measure(an_mid NUMBER, an_objtype NUMBER, acur_t OUT common_pg.tcur);

-----------------------------------------------------------------------------------------------------------------------
--сохраняет измерения и их глобальные индексы для конкретной точки
--Виленская Н.Б. 14.11.2008
 PROCEDURE ins_guid(an_mid NUMBER, an_nmeasure common_pg.tt_number, an_mrid common_pg.tt_varchar2);

-----------------------------------------------------------------------------------------------------------
 FUNCTION formulameas_p(an_mid NUMBER)
  RETURN VARCHAR2;

-------------------------------------------------------------------------------------------------
 -- added by KAG 27.01.2010
 -- список базовых периодов интеграции
 PROCEDURE integratortimes_p(acur_t OUT common_pg.tcur);

--------------------------------------------------------------------------------------------------------------
--выводит таблицу METERTYPEDICT
 PROCEDURE get_metertypedict(acur_t OUT common_pg.tcur);

--------------------------------------------------------------------------------------------------------------
--обновляет таблицу METERTYPEDICT
 PROCEDURE upd_metertypedict(an_mtype NUMBER, av_vname VARCHAR2, an_digits NUMBER, an_mcurrent NUMBER, an_mpower NUMBER, an_mconst NUMBER, an_mclass NUMBER);

--------------------------------------------------------------------------------------------------------------
--вставка записи
 PROCEDURE ins_metertypedict(an_mtype OUT NUMBER, av_vname VARCHAR2, an_digits NUMBER, an_mcurrent NUMBER, an_mpower NUMBER, an_mconst NUMBER,
 an_mclass NUMBER);

--------------------------------------------------------------------------------------------------------------
--удаление записи
 PROCEDURE del_metertypedict(an_mtype NUMBER);

--------------------------------------------------------------------------------------------------------------
 PROCEDURE upd_green;

--------------------------------------------------------------------------------------------------------------
--возвращает кол импульсов на квт-ч
 FUNCTION get_mconst(an_mid NUMBER, an_entype NUMBER DEFAULT 7)
  RETURN NUMBER;

 PRAGMA RESTRICT_REFERENCES(get_mconst, WNDS, WNPS);

-----------------------------------------------------------------------------------------------------------------------
--клонирует формулы
 PROCEDURE clon_formulas(an_smid NUMBER, an_fmid NUMBER);
------------------------------------------------------------------------------------------------------------------
--Посылка команды на отключение включение питания
 PROCEDURE set_command_off(an_mid NUMBER, an_cmd NUMBER);
------------------------------------------------------------------------------------------------------------------
END editfeeders_pg;
/