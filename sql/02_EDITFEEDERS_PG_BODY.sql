--------------------------------------------------------------------------------
-- 2. НАКАТ ТІЛА ПАКЕТА (PACKAGE BODY)
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY ryda.editfeeders_pg IS
------------------------------------------------------------------------------------------------------------------------
 -- пакет работы с точками
 -- дата создания 19/10/2001 (Сечин А.А.)
------------------------------------------------------------------------------------------------------------------------
 gn_task_code        NUMBER DEFAULT 46;
 gn_task_command_off NUMBER DEFAULT 665;
 lc_namelength CONSTANT NUMBER := 140;
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
                                                                                                                                       an_norder NUMBER,
 --порядок в дереве по умолчанию 0
 an_nintegr NUMBER,                                                                                                                         --период интеграции
                   an_lockswitch NUMBER, an_nwithswitch NUMBER, an_nrescanal NUMBER, av_vnote VARCHAR2, av_account VARCHAR2, an_mid OUT NUMBER       --Ид точки
 ) IS                                                                                                                                           -- 46 параметра
  ln_mid              NUMBER;
 BEGIN
  SAVEPOINT editfeeders_ins;
  adminadd_pg.check_right(ln_mid, an_parent, 1, 2);

  SELECT points_seq.NEXTVAL
  INTO   ln_mid
  FROM   DUAL;

  an_mid := ln_mid;

  INSERT INTO points
              (mid, PARENT, cod, ind, NAME, short_name, implement_date, tag, npoint, norder)
  VALUES      (ln_mid, an_parent, 0, an_type, av_name, av_short_name, SYSDATE, an_tag, NULL, an_norder);

  INSERT INTO feeders
              (mid, er_position, q1_position, ed_position, q3_position, smart, q1234, canal, cellnum, POWER, current1, current2, kc, line_loss, act_loss,
               react_loss, vinfo, power2, metkc, nabc, ncalcbill, ncalcmonths, ninverted, nswitch, nusd, nblock, ndataabsence, ncommcontrol, ntechcontrol,
               nmainpoint, verifyparam, vaddparams, vimportcode, nlockcorrecttime, vcode, verifyday, nclasstn, nclasstt, ntimezonew, ntimezones, nopposite,
               nintegralperiod, nlockswitch, nwithswitch, rescanal, vnote, vaccount)
  VALUES      (ln_mid, an_er_position, an_q1_position, an_ed_position, an_q3_position, DECODE(an_smart, 1, '*', ''), DECODE(an_q1234, 1, '*', ''), an_canal,
               av_cellnum, an_power, an_current1, an_current2, an_kc, 0, 0, 0, av_info, an_power2, NVL(an_metkc, 1), NVL(an_abc, 0), NVL(an_calcbill, 0),
               NVL(an_calcmonths, 0), NVL(an_inverted, 0), NVL(an_switch, 0), an_usd, an_nblock, an_dataabsence, an_commctrl, an_techctrl, an_main,
               av_verifyparam, av_addparams, av_importcode, an_lockcorrecttime, av_code, av_verifyday, an_classtn, an_classtt, an_timezonew, an_timezones,
               an_opposite, an_nintegr, an_lockswitch, an_nwithswitch, an_nrescanal, av_vnote, av_account);

  INSERT INTO curr_power
              (mid, date_time, obsolete)
  VALUES      (ln_mid, SYSDATE, 1);

  --meters
  IF an_smart = 1 THEN
   INSERT INTO meters
               (ID, mid, NAME, POSITION, entype, smart, kc)
   VALUES      (points_seq.NEXTVAL, ln_mid, SUBSTR(av_name, 1, lc_namelength) || ' Инт.', an_er_position, 7, '*', an_kc);
  ELSE
   IF an_er_position != 0 THEN
    INSERT INTO meters
                (ID, mid, NAME, POSITION, entype, smart, kc)
    VALUES      (points_seq.NEXTVAL, ln_mid, SUBSTR(av_name, 1, lc_namelength) || ' А птр.', an_er_position, 1, '', an_kc);
   END IF;

   IF an_ed_position != 0 THEN
    INSERT INTO meters
                (ID, mid, NAME, POSITION, entype, smart, kc)
    VALUES      (points_seq.NEXTVAL, ln_mid, SUBSTR(av_name, 1, lc_namelength) || ' А выд.', an_ed_position, 2, '', an_kc);
   END IF;

   IF an_q1_position != 0 THEN
    INSERT INTO meters
                (ID, mid, NAME, POSITION, entype, smart, kc)
    VALUES      (points_seq.NEXTVAL, ln_mid, SUBSTR(av_name, 1, lc_namelength) || ' Р птр.', an_q1_position, 3, '', an_kc);
   END IF;

   IF an_q3_position != 0 THEN
    INSERT INTO meters
                (ID, mid, NAME, POSITION, entype, smart, kc)
    VALUES      (points_seq.NEXTVAL, ln_mid, SUBSTR(av_name, 1, lc_namelength) || ' Р выд.', an_q3_position, 5, '', an_kc);
   END IF;
  END IF;

  IF util_pg.get_customer_id = 1 THEN
   ln_mid := editfeeders_pg.insgroup(ln_mid);
  END IF;

  admin_pg.fiscal_p(gn_task_code, 1, 'Добавлена точка учета ' || util_pg.node_path_f(an_mid, 'points', 'mid', 'parent'));
 EXCEPTION
  WHEN OTHERS THEN
   ROLLBACK TO SAVEPOINT editfeeders_ins;
   raise_application_error(-20001, 'editfeeders_pg.ins_p: Ошибка вставки присоединения. ' || CHR(10) || SQLERRM(SQLCODE));
 END;

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
    -- Процедура вставки данных (с полным набором параметров + параметры MMS)
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
 an_status NUMBER, av_eic_point VARCHAR2, av_eic_site VARCHAR2
  ) IS
  ln_mid              NUMBER;
 BEGIN
  SAVEPOINT editfeeders_ins;
  adminadd_pg.check_right(ln_mid, an_parent, 1, 2);

  SELECT points_seq.NEXTVAL INTO ln_mid FROM DUAL;
  an_mid := ln_mid;

  INSERT INTO points
              (mid, PARENT, cod, ind, NAME, short_name, implement_date, tag, npoint, norder, mms, eic, ctype, status, point_eic, site_eic)
  VALUES      (ln_mid, an_parent, 0, an_type, av_name, av_short_name, SYSDATE, an_tag, NULL, an_norder, av_mms, av_eic, an_ctype, NVL(an_status, 1), av_eic_point, av_eic_site);

  INSERT INTO feeders
              (mid, er_position, q1_position, ed_position, q3_position, smart, q1234, canal, cellnum, POWER, current1, current2, kc, line_loss, act_loss,
               react_loss, vinfo, power2, metkc, nabc, ncalcbill, ncalcmonths, ninverted, nswitch, nusd, nblock, ndataabsence, ncommcontrol, ntechcontrol,
               nmainpoint, verifyparam, vaddparams, vimportcode, nlockcorrecttime, vcode, verifyday, nclasstn, nclasstt, ntimezonew, ntimezones, nopposite,
               nintegralperiod, nlockswitch, nwithswitch, rescanal, vnote, vaccount)
  VALUES      (ln_mid, an_er_position, an_q1_position, an_ed_position, an_q3_position, DECODE(an_smart, 1, '*', ''), DECODE(an_q1234, 1, '*', ''), an_canal,
               av_cellnum, an_power, an_current1, an_current2, an_kc, 0, 0, 0, av_info, an_power2, NVL(an_metkc, 1), NVL(an_abc, 0), NVL(an_calcbill, 0),
               NVL(an_calcmonths, 0), NVL(an_inverted, 0), NVL(an_switch, 0), an_usd, an_nblock, an_dataabsence, an_commctrl, an_techctrl, an_main,
               av_verifyparam, av_addparams, av_importcode, an_lockcorrecttime, av_code, av_verifyday, an_classtn, an_classtt, an_timezonew, an_timezones,
               an_opposite, an_nintegr, an_lockswitch, an_nwithswitch, an_nrescanal, av_vnote, av_account);
  INSERT INTO curr_power (mid, date_time, obsolete) VALUES (ln_mid, SYSDATE, 1);

  --meters
  IF an_smart = 1 THEN
   INSERT INTO meters (ID, mid, NAME, POSITION, entype, smart, kc)
   VALUES (points_seq.NEXTVAL, ln_mid, SUBSTR(av_name, 1, lc_namelength) || ' Инт.', an_er_position, 7, '*', an_kc);
  ELSE
   IF an_er_position != 0 THEN
    INSERT INTO meters (ID, mid, NAME, POSITION, entype, smart, kc)
    VALUES (points_seq.NEXTVAL, ln_mid, SUBSTR(av_name, 1, lc_namelength) || ' А птр.', an_er_position, 1, '', an_kc);
   END IF;
   IF an_ed_position != 0 THEN
    INSERT INTO meters (ID, mid, NAME, POSITION, entype, smart, kc)
    VALUES (points_seq.NEXTVAL, ln_mid, SUBSTR(av_name, 1, lc_namelength) || ' А выд.', an_ed_position, 2, '', an_kc);
   END IF;
   IF an_q1_position != 0 THEN
    INSERT INTO meters (ID, mid, NAME, POSITION, entype, smart, kc)
    VALUES (points_seq.NEXTVAL, ln_mid, SUBSTR(av_name, 1, lc_namelength) || ' Р птр.', an_q1_position, 3, '', an_kc);
   END IF;
   IF an_q3_position != 0 THEN
    INSERT INTO meters (ID, mid, NAME, POSITION, entype, smart, kc)
    VALUES (points_seq.NEXTVAL, ln_mid, SUBSTR(av_name, 1, lc_namelength) || ' Р выд.', an_q3_position, 5, '', an_kc);
   END IF;
  END IF;

  IF util_pg.get_customer_id = 1 THEN
   ln_mid := editfeeders_pg.insgroup(ln_mid);
  END IF;

  admin_pg.fiscal_p(gn_task_code, 1, 'Добавлена точка учета ' || util_pg.node_path_f(an_mid, 'points', 'mid', 'parent'));
 EXCEPTION
  WHEN OTHERS THEN
   ROLLBACK TO SAVEPOINT editfeeders_ins;
   raise_application_error(-20001, 'editfeeders_pg.ins_p: Ошибка вставки присоединения. ' || CHR(10) || SQLERRM(SQLCODE));
 END;
------------------------------------------------------------------------------------------------------------------------
 FUNCTION insgroup(an_mid NUMBER)
  RETURN NUMBER IS
  ln_gid              NUMBER;
  ln_parent           NUMBER;
  lv_name             VARCHAR2(256);
  ln_mid              NUMBER;
  ln_testmid          NUMBER;
 BEGIN
  IF NVL(util_pg.get_customer_id, 0) <> 1 THEN
   RETURN NULL;
  END IF;

  ln_testmid := 0;

  SELECT MAX(gid)
  INTO   ln_gid
  FROM   GROUPS
  WHERE  nroot1 = 1 AND nroot2 = an_mid;

  IF ln_gid > 0 THEN
   RETURN ln_gid;
  END IF;

  SELECT PARENT, NAME, DECODE(ind, 3, mid, 4, mid, NULL)
  INTO   ln_parent, lv_name, ln_mid
  FROM   points p
  WHERE  mid = an_mid;

  IF ln_parent IS NOT NULL THEN
   SELECT MAX(gid)
   INTO   ln_gid
   FROM   GROUPS
   WHERE  nroot1 = 1 AND nroot2 = ln_parent;

   IF ln_gid IS NULL THEN
    ln_gid := insgroup(ln_parent);
   END IF;
  END IF;

  IF ln_parent IS NULL THEN
   SELECT MAX(gid)
   INTO   ln_gid
   FROM   GROUPS
   WHERE  PARENT IS NULL AND NAME = 'Точки АСРПП';

   IF ln_gid IS NULL THEN
    RETURN -1;
   END IF;
  ELSE
   SELECT MAX(gid), MAX(mid)
   INTO   ln_gid, ln_testmid
   FROM   GROUPS
   WHERE  nroot1 = 1 AND nroot2 = ln_parent;
  END IF;

  IF ln_testmid > 0 THEN
   RETURN -1;
  ELSE
   editgroups_pg.ins_p_a(ln_gid, lv_name, NULL, ln_mid, 0, 1, an_mid, NULL, NULL, NULL, NULL, NULL, ln_gid);
  END IF;

  RETURN ln_gid;
 END;

-----------------------------------------------------------------------------------------------------------------------------
   -- Процедура вставки АСКУЭ
 PROCEDURE ins_p_a(
 an_parent NUMBER,                                                                                                                                    --Родитель
                  an_type NUMBER,                                                                                                                    --Тип точки
                                 av_name VARCHAR2,                                                                                                    --Название
                                                  av_short_name VARCHAR2,                                                                     --Краткое название
                                                                         an_er_position NUMBER, an_q1_position NUMBER, an_ed_position NUMBER,
 an_q3_position NUMBER, an_smart NUMBER,                                                                                                          --Интеллектуал
                                        an_q1234 NUMBER,                                                                                             --Квадранты
                                                        av_cellnum VARCHAR2,                                                                      --Номер ячейки
                                                                            an_power NUMBER,                                                          --Мощность
                                                                                            an_current1 NUMBER,                                --Напряжение перв
                                                                                                               an_current2 NUMBER,           --Напряжение вторич
 an_kc NUMBER,                                                                                                                                           --Коэфф
              an_point NUMBER,                                                                                                                  --Ид точки АСРПП
                              an_power2 NUMBER,                                                                                            --Мощность вторич кВ,
                                               an_ptype NUMBER, an_order NUMBER, an_mid OUT NUMBER                                                    --Ид точки
 ) IS
  ln_mid              NUMBER;
  ln_ind              NUMBER;
 BEGIN
  adminadd_pg.check_right(ln_mid, an_parent, 1, 2);

  SELECT points_seq.NEXTVAL
  INTO   ln_mid
  FROM   DUAL;

  an_mid := ln_mid;

  INSERT INTO points
              (mid, PARENT, cod, ind, NAME, short_name, implement_date, tag, npoint, ptype, norder)
  VALUES      (ln_mid, an_parent, 0, an_type, av_name, av_short_name, SYSDATE, NULL, an_point, an_ptype, an_order);

  INSERT INTO feeders
              (mid, er_position, q1_position, ed_position, q3_position, smart, q1234, canal, cellnum, POWER, current1, current2, kc, line_loss, act_loss,
               react_loss, vinfo, power2, metkc, nabc, ncalcbill, ncalcmonths, nlockcorrecttime, rescanal)
  VALUES      (ln_mid, an_er_position, an_q1_position, an_ed_position, an_q3_position, DECODE(an_smart, 1, '*', ''), DECODE(an_q1234, 1, '*', ''), NULL,
               av_cellnum, an_power, an_current1, an_current2, an_kc, 0, 0, 0, NULL, an_power2, 1, 0, 0, 0, 0, 0);

  INSERT INTO curr_power
              (mid, obsolete)
  VALUES      (ln_mid, 1);

  --meters
  IF an_smart = 1 THEN
   INSERT INTO meters
               (ID, mid, NAME, POSITION, entype, smart, kc)
   VALUES      (points_seq.NEXTVAL, ln_mid, SUBSTR(av_name, 1, lc_namelength) || ' Инт.', an_er_position, 7, '*', an_kc);
  ELSE
   IF an_er_position != 0 THEN
    INSERT INTO meters
                (ID, mid, NAME, POSITION, entype, smart, kc)
    VALUES      (points_seq.NEXTVAL, ln_mid, SUBSTR(av_name, 1, lc_namelength) || ' А птр.', an_er_position, 1, '', an_kc);
   END IF;

   IF an_ed_position != 0 THEN
    INSERT INTO meters
                (ID, mid, NAME, POSITION, entype, smart, kc)
    VALUES      (points_seq.NEXTVAL, ln_mid, SUBSTR(av_name, 1, lc_namelength) || ' А выд.', an_ed_position, 2, '', an_kc);
   END IF;

   IF an_q1_position != 0 THEN
    INSERT INTO meters
                (ID, mid, NAME, POSITION, entype, smart, kc)
    VALUES      (points_seq.NEXTVAL, ln_mid, SUBSTR(av_name, 1, lc_namelength) || ' Р птр.', an_q1_position, 3, '', an_kc);
   END IF;

   IF an_q3_position != 0 THEN
    INSERT INTO meters
                (ID, mid, NAME, POSITION, entype, smart, kc)
    VALUES      (points_seq.NEXTVAL, ln_mid, SUBSTR(av_name, 1, lc_namelength) || ' Р выд.', an_q3_position, 5, '', an_kc);
   END IF;
  END IF;

  IF util_pg.get_customer_id = 1 THEN
   /* SELECT p1.ind
    INTO ln_ind
    FROM points p,points p1
    WHERE p.mid=ln_mid
    AND p1.mid=p.parent;

   IF ln_ind<>4 OR ln_ind<>3 THEN*/
   ln_mid := insgroup(ln_mid);
--  END IF;
  END IF;
 EXCEPTION
  WHEN OTHERS THEN
   raise_application_error(-20001, 'editfeeders_pg.ins_p: Ошибка вставки присоединения. ' || CHR(10) || SQLERRM(SQLCODE));
 END;

------------------------------------------------------------------------------------------------------------------------
   -- Процедура вставки АСКУЭ
 PROCEDURE ins_p_synchro(
 an_parent NUMBER,                                                                                                                                    --Родитель
                  an_type NUMBER,                                                                                                                    --Тип точки
                                 av_name VARCHAR2,                                                                                                    --Название
                                                  av_short_name VARCHAR2,                                                                     --Краткое название
                                                                         an_smart NUMBER,                                                         --Интеллектуал
                                                                                         an_q1234 NUMBER,                                            --Квадранты
                                                                                                         av_cellnum VARCHAR2,                     --Номер ячейки
                                                                                                                             an_power NUMBER,         --Мощность
 an_current1 NUMBER,                                                                                                                           --Напряжение перв
                    an_current2 NUMBER,                                                                                                      --Напряжение вторич
                                       an_kc NUMBER,                                                                                                     --Коэфф
                                                    an_root NUMBER,                                                                 --Ид точки в родительской БД
                                                                   an_power2 NUMBER,                                                        --Мощность вторич кВ
                                                                                    an_mid OUT NUMBER                                                 --Ид точки
 ) IS
  ln_mid              NUMBER;
 BEGIN
  adminadd_pg.check_right(ln_mid, an_parent, 1, 2);

  SELECT points_seq.NEXTVAL
  INTO   ln_mid
  FROM   DUAL;

  an_mid := ln_mid;

  INSERT INTO points
              (mid, PARENT, cod, ind, NAME, short_name, implement_date, tag, nroot)
  VALUES      (ln_mid, an_parent, 0, an_type, av_name, av_short_name, SYSDATE, NULL, an_root);

  INSERT INTO feeders
              (mid, er_position, q1_position, ed_position, q3_position, smart, q1234, canal, cellnum, POWER, current1, current2, kc, line_loss, act_loss,
               react_loss, vinfo, power2, metkc, nabc, ncalcbill, ncalcmonths, nlockcorrecttime, rescanal)
  VALUES      (ln_mid, 0, 0, 0, 0, DECODE(an_smart, 1, '*', ''), DECODE(an_q1234, 1, '*', ''), NULL, av_cellnum, an_power, an_current1, an_current2, an_kc, 0,
               0, 0, NULL, an_power2, 1, 0, 0, 0, 0, 0);

  INSERT INTO curr_power
              (mid, obsolete)
  VALUES      (ln_mid, 1);

  INSERT INTO meters
              (ID, mid, NAME, POSITION, entype, smart, kc)
  VALUES      (points_seq.NEXTVAL, ln_mid, SUBSTR(av_name, 1, lc_namelength) || ' Инт.', 0, 7, '*', an_kc);
 EXCEPTION
  WHEN OTHERS THEN
   raise_application_error(-20001, 'editfeeders_pg.ins_p_synchro: Ошибка вставки присоединения. ' || CHR(10) || SQLERRM(SQLCODE));
 END;

------------------------------------------------------------------------------------------------------------------------
  -- Процедура обновления данных АСКУЭ
 PROCEDURE upd_p_a(
 an_mid NUMBER,                                                                                                                                       --Ид точки
               an_parent NUMBER,                                                                                                                      --Родитель
                                an_type NUMBER,                                                                                                      --Тип точки
                                               av_name VARCHAR2,                                                                                      --Название
                                                                av_short_name VARCHAR2,                                                       --Краткое название
                                                                                       an_er_position NUMBER, an_q1_position NUMBER, an_ed_position NUMBER,
 an_q3_position NUMBER, an_smart NUMBER,                                                                                                          --Интеллектуал
                                        an_q1234 NUMBER,                                                                                             --Квадранты
                                                        av_cellnum VARCHAR2,                                                                      --Номер ячейки
                                                                            an_power NUMBER,                                                          --Мощность
                                                                                            an_current1 NUMBER,                                --Напряжение перв
                                                                                                               an_current2 NUMBER,           --Напряжение вторич
 an_kc NUMBER,                                                                                                                                           --Коэфф
              an_power2 NUMBER                                                                                                              --Мощность вторич кВ
 --  an_metkc       NUMBER --Коэф прошитый в счетчике
 ) IS
  ln_gid              NUMBER;
  ln_gid1             NUMBER;
 BEGIN
  adminadd_pg.check_right(an_mid, an_parent, 1, 2);

  UPDATE points
  SET PARENT = an_parent,
      NAME = av_name,
      short_name = av_short_name,
      ind = an_type
  WHERE  mid = an_mid;

  UPDATE GROUPS
  SET NAME = av_name,
      short_name = av_short_name
  WHERE  mid = an_mid;

  UPDATE feeders
  SET smart = DECODE(an_smart, 1, '*', ''),
      q1234 = DECODE(an_q1234, 1, '*', ''),
      cellnum = av_cellnum,
      POWER = an_power,
      current1 = an_current1,
      current2 = an_current2,
      kc = an_kc,
      power2 = an_power2
  WHERE  mid = an_mid;

  --meters
  IF an_smart = 1 THEN
   DELETE FROM meters
   WHERE       mid = an_mid AND entype BETWEEN 1 AND 6;

   UPDATE meters
   SET NAME = SUBSTR(av_name, 1, lc_namelength) || ' Инт.',
       POSITION = an_er_position,
       kc = an_kc
   WHERE  mid = an_mid AND entype = 7;

   IF SQL%ROWCOUNT <= 0 THEN
    INSERT INTO meters
                (ID, mid, NAME, POSITION, entype, smart, kc)
    VALUES      (points_seq.NEXTVAL, an_mid, SUBSTR(av_name, 1, lc_namelength) || ' Инт.', an_er_position, 7, '*', an_kc);
   END IF;
  ELSE
   DELETE FROM meters
   WHERE       mid = an_mid AND entype = 7;

   IF an_er_position != 0 THEN
    UPDATE meters
    SET NAME = SUBSTR(av_name, 1, lc_namelength) || ' А птр.',
        POSITION = an_er_position,
        kc = an_kc
    WHERE  mid = an_mid AND entype = 1;

    IF SQL%ROWCOUNT <= 0 THEN
     INSERT INTO meters
                 (ID, mid, NAME, POSITION, entype, smart, kc)
     VALUES      (points_seq.NEXTVAL, an_mid, SUBSTR(av_name, 1, lc_namelength) || ' А птр.', an_er_position, 1, '', an_kc);
    END IF;
   ELSE
    DELETE FROM meters
    WHERE       mid = an_mid AND entype = 1;
   END IF;

   IF an_ed_position != 0 THEN
    UPDATE meters
    SET NAME = SUBSTR(av_name, 1, lc_namelength) || ' А выд.',
        POSITION = an_ed_position,
        kc = an_kc
    WHERE  mid = an_mid AND entype = 2;

    IF SQL%ROWCOUNT <= 0 THEN
     INSERT INTO meters
                 (ID, mid, NAME, POSITION, entype, smart, kc)
     VALUES      (points_seq.NEXTVAL, an_mid, SUBSTR(av_name, 1, lc_namelength) || ' А выд.', an_ed_position, 2, '', an_kc);
    END IF;
   ELSE
    DELETE FROM meters
    WHERE       mid = an_mid AND entype = 2;
   END IF;

   IF an_q1_position != 0 THEN
    UPDATE meters
    SET NAME = SUBSTR(av_name, 1, lc_namelength) || ' Р птр.',
        POSITION = an_q1_position,
        kc = an_kc
    WHERE  mid = an_mid AND entype = 3;

    IF SQL%ROWCOUNT <= 0 THEN
     INSERT INTO meters
                 (ID, mid, NAME, POSITION, entype, smart, kc)
     VALUES      (points_seq.NEXTVAL, an_mid, SUBSTR(av_name, 1, lc_namelength) || ' Р птр.', an_q1_position, 3, '', an_kc);
    END IF;
   ELSE
    DELETE FROM meters
    WHERE       mid = an_mid AND entype = 3;
   END IF;

   IF an_q3_position != 0 THEN
    UPDATE meters
    SET NAME = SUBSTR(av_name, 1, lc_namelength) || ' Р выд.',
        POSITION = an_q3_position,
        kc = an_kc
    WHERE  mid = an_mid AND entype = 5;

    IF SQL%ROWCOUNT <= 0 THEN
     INSERT INTO meters
                 (ID, mid, NAME, POSITION, entype, smart, kc)
     VALUES      (points_seq.NEXTVAL, an_mid, SUBSTR(av_name, 1, lc_namelength) || ' Р выд.', an_q3_position, 5, '', an_kc);
    END IF;
   ELSE
    DELETE FROM meters
    WHERE       mid = an_mid AND entype = 5;
   END IF;
  END IF;

  IF util_pg.get_customer_id = 1 THEN
   ln_gid := insgroup(an_parent);
   ln_gid1 := insgroup(an_mid);

   UPDATE GROUPS
   SET NAME = av_name,
       PARENT = ln_gid
   WHERE  nroot1 = 1 AND nroot2 = an_mid;
  END IF;
 EXCEPTION
  WHEN OTHERS THEN
   raise_application_error(-20001, 'editfeeders_pg.upd_p: Ошибка обновления присоединения. ' || CHR(10) || SQLERRM(SQLCODE));
 END;

------------------------------------------------------------------------------------------------------------------------
 PROCEDURE upd_p_b(an_mid NUMBER,                                                                                                             --Ид зеленой точки
                                 an_test NUMBER                                                                                                 --Ид синей точки
                                               ) IS
 BEGIN
  UPDATE feeders f
  SET (f.er_position, f.q1_position, f.ed_position, f.q3_position, f.canal, f.line_loss, f.act_loss, f.react_loss, f.ov_mid, f.vinfo, f.metkc, f.nabc,
       f.ncalcbill, f.ncalcmonths, f.ninverted, f.nswitch, f.nworkinghours, f.nfullhours, f.nwastepercentcalc, f.nrecompens, f.nusd, f.nblock, f.ncalcpointtype,
       f.ntechcontrol, f.ncommcontrol, f.ndataabsence, f.ndataabsencec, f.ndataabsencect, f.ddataabsencec, f.nmainpoint, f.verifyparam, f.ntcurrent, f.ntpower,
       f.vaddparams, f.vimportcode, f.nlockcorrecttime, f.vcode, f.verifyday, f.nclasstn, f.nclasstt, f.ntimezonew, f.ntimezones, f.nopposite,
       f.nintegralperiod, f.nlockswitch, f.nwithswitch, f.rescanal) =
       (SELECT a.er_position, a.q1_position, a.ed_position, a.q3_position, a.canal, a.line_loss, a.act_loss, a.react_loss, a.ov_mid, a.vinfo, a.metkc, a.nabc,
               a.ncalcbill, a.ncalcmonths, a.ninverted, 0 nswitch, a.nworkinghours, a.nfullhours, a.nwastepercentcalc, a.nrecompens, a.nusd, a.nblock,
               a.ncalcpointtype, a.ntechcontrol, a.ncommcontrol, a.ndataabsence, a.ndataabsencec, a.ndataabsencect, a.ddataabsencec, a.nmainpoint,
               a.verifyparam, a.ntcurrent, a.ntpower, a.vaddparams, a.vimportcode, a.nlockcorrecttime, NULL vcode, a.verifyday, a.nclasstn, a.nclasstt,
               a.ntimezonew, a.ntimezones, a.nopposite, a.nintegralperiod, a.nlockswitch, a.nwithswitch, a.rescanal
        FROM   feeders a
        WHERE  a.mid = an_mid)
  WHERE  mid = an_test;

  UPDATE points p
  SET (p.tag) = (SELECT a.tag
                 FROM   points a
                 WHERE  a.mid = an_mid)
  WHERE  mid = an_test;

  INSERT INTO last_save
              (mid, PROFILE, halfhour, bill, rate, clock, state_date, state_cod, state_descr, luck, rates, months, trial, fail, journal, halfhourchange,
               dparametrization, dmetercorrect)
   SELECT an_mid, a.PROFILE, a.halfhour, a.bill, a.rate, a.clock, a.state_date, a.state_cod, a.state_descr, a.luck, a.rates, a.months, a.trial, a.fail,
          a.journal, a.halfhourchange, a.dparametrization, a.dmetercorrect
   FROM   last_save a
   WHERE  mid = an_test;
 END;

---------------------------------------------------------------------------------------------------------------
 -- Процедура удаления данных
 PROCEDURE del_p(an_mid NUMBER                                                                                                                        --Ид точки
                              ) IS
 BEGIN
  IF an_mid <= util_pg.cn_pntmid THEN
   raise_application_error(-20001, 'Удаление служебных точек учета запрещено.');
  END IF;

  adminadd_pg.check_right(an_mid, NULL, 1, 2);
  admin_pg.fiscal_p(gn_task_code, 3, 'Удалена точка учета ' || util_pg.node_path_f(an_mid, 'points', 'mid', 'parent'));

  UPDATE feeders
  SET nusd = NULL
  WHERE  nusd = an_mid;

  UPDATE feeders
  SET nmainpoint = NULL
  WHERE  nmainpoint = an_mid;

  UPDATE feeders
  SET nopposite = NULL
  WHERE  nopposite = an_mid;

  UPDATE forms f
  SET f.mid = NULL
  WHERE  f.mid IN(SELECT     mid
                  FROM       points
                  CONNECT BY PRIOR mid = PARENT
                  START WITH mid = an_mid);

  DELETE FROM points
  WHERE       mid = an_mid;

  DELETE FROM GROUPS
  WHERE       nroot1 = 1 AND nroot2 = an_mid;
 EXCEPTION
  WHEN OTHERS THEN
   raise_application_error(-20001, 'editfeeders_pg.del_p: Ошибка удаления присоединения. ' || CHR(10) || SQLERRM(SQLCODE));
 END;

------------------------------------------------------------------------------------------------------------------------
--Процедура обновления счетчика АСКУЭ
 PROCEDURE upd_meters_a(
 an_mid NUMBER,                                                                                                                                       --Ид точки
               an_entype NUMBER,                                                                                                                        --ENTYPE
                                av_smart VARCHAR2,                                                                                                       --SMART
                                                  av_mtrsn VARCHAR2,                                                                                     --MTRSN
                                                                    ad_date_time DATE,                                                               --DATE_TIME
                                                                                      an_digits NUMBER,                                                 --DIGITS
                                                                                                       av_mtype VARCHAR2,                                --MTYPE
                                                                                                                         an_mcurrent NUMBER,          --MCURRENT
 an_mpower NUMBER,                                                                                                                                      --MPOWER
                  an_mconst NUMBER,                                                                                                                     --MCONST
                                   an_mclass NUMBER,                                                                                                    --MCLASS
                                                    an_myear NUMBER,                                                                                     --MYEAR
                                                                    an_mquarter NUMBER                                                                --MQUARTER
 ) IS
 BEGIN
  UPDATE meters
  SET date_time = ad_date_time,
      mtrsn = av_mtrsn,
      digits = an_digits,
      mtype = av_mtype,
      mcurrent = an_mcurrent,
      mpower = an_mpower,
      myear = an_myear,
      mquarter = an_mquarter,
      mconst = an_mconst,
      mclass = an_mclass
  WHERE  mid = an_mid AND entype = an_entype;

  admin_pg.fiscal_p(gn_task_code, 2, 'Изменены атрибуты счетчика №' || av_mtrsn || ' для точки ' || util_pg.node_path_f(an_mid, 'points', 'mid', 'parent'));
 EXCEPTION
  WHEN OTHERS THEN
   raise_application_error(-20001, 'editfeeders_pg.upd_meters: Ошибка обновления счетчика. ' || CHR(10) || SQLERRM(SQLCODE));
 END;

------------------------------------------------------------------------------------------------------------------------
--Устанавливает параметры простых потерь
 PROCEDURE setaddparam(
 an_mid NUMBER,                                                                                                                                       --Ид точки
               an_wastepercentcalc NUMBER,                                                                                                          --Тип потерь
                                          an_workinghours NUMBER,                                                                                  --Часы работы
                                                                 an_fullhours NUMBER,                                                       --Полные часы работы
                                                                                     an_line_loss NUMBER,                                      --Портери в линии
                                                                                                         an_act_loss NUMBER,                  --Потери акт транс
 an_react_loss NUMBER,                                                                                                                      --Потери реакт транс
                      an_recompens NUMBER,                                                                                                --Тип расчета реактива
                                          an_calcpointtype NUMBER,                                                                         --Тип расчетной точки
                                                                  an_gid NUMBER                                                               --ид расчет группы
 ) IS
 BEGIN
  --  raise_application_error(-20001, 'В доступе отказано');
  UPDATE feeders
  SET nwastepercentcalc = an_wastepercentcalc,
      nworkinghours = an_workinghours,
      nfullhours = an_fullhours,
      line_loss = an_line_loss,
      act_loss = an_act_loss,
      react_loss = an_react_loss,
      nrecompens = DECODE(an_recompens, 1, 1, 0, NULL, an_recompens),
      ncalcpointtype = DECODE(an_calcpointtype, 1, 1, 0, NULL, an_calcpointtype)
  WHERE  mid = an_mid;

  IF an_gid <> 0 THEN
   UPDATE calcpointbygroup
   SET gid = an_gid
   WHERE  mid = an_mid;

   IF SQL%ROWCOUNT = 0 THEN
    INSERT INTO calcpointbygroup
                (mid, gid)
    VALUES      (an_mid, an_gid);
   END IF;
  ELSE
   DELETE FROM calcpointbygroup
   WHERE       mid = an_mid;
  END IF;
 EXCEPTION
  WHEN OTHERS THEN
   raise_application_error(-20001, 'editfeeders_pg.setaddparam: Ошибка дополнительных параметров точки. ' || CHR(10) || SQLERRM(SQLCODE));
 END;

------------------------------------------------------------------------------------------------------------------------
     -- Нормативные параметры точки
 PROCEDURE setcalcparam_p(
 an_mid NUMBER,                                                                                                                                       --Ид точки
               at_date common_pg.tt_number,                                                                                              --Дата ввода в действие
                                           at_currpower common_pg.tt_number,                                                                          --Мощность
                                                                            at_monthconsumpt common_pg.tt_number,                                 --Месяч расход
 at_kc common_pg.tt_number                                                                                                                      --Коэф пересчета
 ) IS
 BEGIN
  SAVEPOINT setcalcparam_sp;

  DELETE FROM pointsparam
  WHERE       mid = an_mid;

  IF at_date.COUNT > 0 AND at_date(1) <> 0 THEN
   FOR i IN 1 .. at_date.COUNT LOOP
    INSERT INTO pointsparam
                (mid, ddate, ncurrpower, nmonthconsumpt, nkc)
    VALUES      (an_mid, TO_DATE(at_date(i), 'yyyymmdd'), at_currpower(i), at_monthconsumpt(i), NVL(at_kc(i), 1));
   END LOOP;
  END IF;

  admin_pg.fiscal_p(gn_task_code, 2, 'Изменены нормативные параметры точки учета ' || util_pg.node_path_f(an_mid, 'points', 'mid', 'parent'));
 EXCEPTION
  WHEN OTHERS THEN
   ROLLBACK TO SAVEPOINT setcalcparam_sp;
   raise_application_error(-20001, 'editfeeders_pg.setcalcparam_p: Задания нормативных параметров точки учета. ' || CHR(10) || SQLERRM(SQLCODE));
 END;

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
 ) IS
  ln_gid              NUMBER;
  ln_gid1             NUMBER;
  ln_old_kc           NUMBER;
 BEGIN
  SAVEPOINT editfeeders_upd;
  adminadd_pg.check_right(an_mid, an_parent, 1, 2);

  SELECT MAX(kc)
  INTO   ln_old_kc
  FROM   feeders
  WHERE  mid = an_mid;

  IF util_pg.get_customer_id = 1 THEN                                                                                                                     --ХЭС
   UPDATE points
   SET tag = an_tag,
       norder = an_norder
   WHERE  mid = an_mid;

   UPDATE feeders
   SET er_position = an_er_position,
       q1_position = an_q1_position,
       ed_position = an_ed_position,
       q3_position = an_q3_position,
       canal = an_canal,
       vinfo = av_info,
       metkc = NVL(an_metkc, 1),
       nabc = NVL(an_abc, 0),
       ncalcbill = NVL(an_calcbill, 0),
       ncalcmonths = NVL(an_calcmonths, 0),
       ninverted = NVL(an_inverted, 0),
       nswitch = NVL(an_switch, 0),
       nusd = an_usd,
       nblock = an_nblock,
       ndataabsence = an_dataabsence,
       ncommcontrol = an_commctrl,
       ntechcontrol = an_techctrl,
       nmainpoint = an_main,
       verifyparam = av_verifyparam,
       vaddparams = av_addparams,
       vimportcode = av_importcode,
       nlockcorrecttime = an_lockcorrecttime,
       vcode = av_code,
       verifyday = av_verifyday,
       nclasstn = an_classtn,
       nclasstt = an_classtt,
       ntimezonew = an_timezonew,
       ntimezones = an_timezones,
       nopposite = an_opposite,
       nintegralperiod = an_nintegr,
       nlockswitch = an_lockswitch,
       nwithswitch = an_nwithswitch,
       rescanal = an_nrescanal,
       vnote = av_vnote,
       vaccount = av_account
   WHERE  mid = an_mid;
  ELSE
   UPDATE points
   SET PARENT = an_parent,
       NAME = av_name,
       short_name = av_short_name,
       tag = an_tag,
       norder = an_norder
   WHERE  mid = an_mid;

   UPDATE GROUPS
   SET NAME = av_name,
       short_name = av_short_name
   WHERE  mid = an_mid;

   UPDATE feeders
   SET er_position = an_er_position,
       q1_position = an_q1_position,
       ed_position = an_ed_position,
       q3_position = an_q3_position,
       smart = DECODE(an_smart, 1, '*', ''),
       q1234 = DECODE(an_q1234, 1, '*', ''),
       canal = an_canal,
       cellnum = av_cellnum,
       POWER = an_power,
       current1 = an_current1,
       current2 = an_current2,
       kc = an_kc,
       vinfo = av_info,
       power2 = an_power2,
       metkc = NVL(an_metkc, 1),
       nabc = NVL(an_abc, 0),
       ncalcbill = NVL(an_calcbill, 0),
       ncalcmonths = NVL(an_calcmonths, 0),
       ninverted = NVL(an_inverted, 0),
       nswitch = NVL(an_switch, 0),
       nusd = an_usd,
       nblock = an_nblock,
       ndataabsence = an_dataabsence,
       ncommcontrol = an_commctrl,
       ntechcontrol = an_techctrl,
       nmainpoint = an_main,
       verifyparam = av_verifyparam,
       vaddparams = av_addparams,
       vimportcode = av_importcode,
       nlockcorrecttime = an_lockcorrecttime,
       vcode = av_code,
       verifyday = av_verifyday,
       nclasstn = an_classtn,
       nclasstt = an_classtt,
       ntimezonew = an_timezonew,
       ntimezones = an_timezones,
       nopposite = an_opposite,
       nintegralperiod = an_nintegr,
       nlockswitch = an_lockswitch,
       nwithswitch = an_nwithswitch,
       rescanal = an_nrescanal,
       vnote = av_vnote,
       vaccount = av_account
   WHERE  mid = an_mid;

   --meters
   IF an_smart = 1 THEN
    DELETE FROM meters
    WHERE       mid = an_mid AND entype BETWEEN 1 AND 6;

    UPDATE meters
    SET NAME = SUBSTR(av_name, 1, lc_namelength) || ' Инт.',
        POSITION = an_er_position,
        kc = an_kc
    WHERE  mid = an_mid AND entype = 7;

    IF SQL%ROWCOUNT <= 0 THEN
     INSERT INTO meters
                 (ID, mid, NAME, POSITION, entype, smart, kc)
     VALUES      (points_seq.NEXTVAL, an_mid, SUBSTR(av_name, 1, lc_namelength) || ' Инт.', an_er_position, 7, '*', an_kc);
    END IF;
   ELSE
    DELETE FROM meters
    WHERE       mid = an_mid AND entype = 7;

    IF an_er_position != 0 THEN
     UPDATE meters
     SET NAME = SUBSTR(av_name, 1, lc_namelength) || ' А птр.',
         POSITION = an_er_position,
         kc = an_kc
     WHERE  mid = an_mid AND entype = 1;

     IF SQL%ROWCOUNT <= 0 THEN
      INSERT INTO meters
                  (ID, mid, NAME, POSITION, entype, smart, kc)
      VALUES      (points_seq.NEXTVAL, an_mid, SUBSTR(av_name, 1, lc_namelength) || ' А птр.', an_er_position, 1, '', an_kc);
     END IF;
    ELSE
     DELETE FROM meters
     WHERE       mid = an_mid AND entype = 1;
    END IF;

    IF an_ed_position != 0 THEN
     UPDATE meters
     SET NAME = SUBSTR(av_name, 1, lc_namelength) || ' А выд.',
         POSITION = an_ed_position,
         kc = an_kc
     WHERE  mid = an_mid AND entype = 2;

     IF SQL%ROWCOUNT <= 0 THEN
      INSERT INTO meters
                  (ID, mid, NAME, POSITION, entype, smart, kc)
      VALUES      (points_seq.NEXTVAL, an_mid, SUBSTR(av_name, 1, lc_namelength) || ' А выд.', an_ed_position, 2, '', an_kc);
     END IF;
    ELSE
     DELETE FROM meters
     WHERE       mid = an_mid AND entype = 2;
    END IF;

    IF an_q1_position != 0 THEN
     UPDATE meters
     SET NAME = SUBSTR(av_name, 1, lc_namelength) || ' Р птр.',
         POSITION = an_q1_position,
         kc = an_kc
     WHERE  mid = an_mid AND entype = 3;

     IF SQL%ROWCOUNT <= 0 THEN
      INSERT INTO meters
                  (ID, mid, NAME, POSITION, entype, smart, kc)
      VALUES      (points_seq.NEXTVAL, an_mid, SUBSTR(av_name, 1, lc_namelength) || ' Р птр.', an_q1_position, 3, '', an_kc);
     END IF;
    ELSE
     DELETE FROM meters
     WHERE       mid = an_mid AND entype = 3;
    END IF;

    IF an_q3_position != 0 THEN
     UPDATE meters
     SET NAME = SUBSTR(av_name, 1, lc_namelength) || ' Р выд.',
         POSITION = an_q3_position,
         kc = an_kc
     WHERE  mid = an_mid AND entype = 5;

     IF SQL%ROWCOUNT <= 0 THEN
      INSERT INTO meters
                  (ID, mid, NAME, POSITION, entype, smart, kc)
      VALUES      (points_seq.NEXTVAL, an_mid, SUBSTR(av_name, 1, lc_namelength) || ' Р выд.', an_q3_position, 5, '', an_kc);
     END IF;
    ELSE
     DELETE FROM meters
     WHERE       mid = an_mid AND entype = 5;
    END IF;
   END IF;
  END IF;

  IF util_pg.get_customer_id = 1 THEN
   ln_gid := editfeeders_pg.insgroup(an_parent);
   ln_gid1 := editfeeders_pg.insgroup(an_mid);

   UPDATE GROUPS
   SET NAME = av_name,
       PARENT = ln_gid
   WHERE  nroot1 = 1 AND nroot2 = an_mid;
  END IF;

  admin_pg.fiscal_p(gn_task_code, 2, 'Изменены атрибуты точки ' || util_pg.node_path_f(an_mid, 'points', 'mid', 'parent'));

  IF ln_old_kc <> an_kc THEN
   file_pg.startbyevents_p(46, an_mid, SYSDATE);
  END IF;
 EXCEPTION
  WHEN OTHERS THEN
   ROLLBACK TO SAVEPOINT editfeeders_upd;
   raise_application_error(-20001, 'editfeeders_pg.upd_p: Ошибка обновления присоединения. ' || CHR(10) || SQLERRM(SQLCODE));
 END;

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
 an_status NUMBER, av_eic_point VARCHAR2, av_eic_site VARCHAR2
 ) IS
  ln_gid              NUMBER;
  ln_gid1             NUMBER;
  ln_old_kc           NUMBER;
 BEGIN
  SAVEPOINT editfeeders_upd;
  adminadd_pg.check_right(an_mid, an_parent, 1, 2);

  SELECT MAX(kc) INTO ln_old_kc FROM feeders WHERE mid = an_mid;

  IF util_pg.get_customer_id = 1 THEN
   UPDATE points
        SET tag = an_tag, norder = an_norder, mms = av_mms, eic = av_eic, ctype = an_ctype,
            status = DECODE(an_status, -1, status, an_status),
            point_eic = DECODE(av_eic_point, CHR(0), point_eic, av_eic_point),
            site_eic = DECODE(av_eic_site, CHR(0), site_eic, av_eic_site)
      WHERE mid = an_mid;
  ELSE
   UPDATE points
       SET PARENT = an_parent, NAME = av_name, short_name = av_short_name, tag = an_tag, norder = an_norder,
           mms = av_mms, eic = av_eic, ctype = an_ctype,
           status = DECODE(an_status, -1, status, an_status),
           point_eic = DECODE(av_eic_point, CHR(0), point_eic, av_eic_point),
           site_eic = DECODE(av_eic_site, CHR(0), site_eic, av_eic_site)
   WHERE  mid = an_mid;

   UPDATE GROUPS SET NAME = av_name, short_name = av_short_name WHERE mid = an_mid;
  END IF;

  UPDATE feeders
  SET er_position = an_er_position, q1_position = an_q1_position, ed_position = an_ed_position, q3_position = an_q3_position,
      smart = DECODE(an_smart, 1, '*', ''), q1234 = DECODE(an_q1234, 1, '*', ''), canal = an_canal, cellnum = av_cellnum,
      POWER = an_power, current1 = an_current1, current2 = an_current2, kc = an_kc, vinfo = av_info, power2 = an_power2,
      metkc = NVL(an_metkc, 1), nabc = NVL(an_abc, 0), ncalcbill = NVL(an_calcbill, 0), ncalcmonths = NVL(an_calcmonths, 0),
      ninverted = NVL(an_inverted, 0), nswitch = NVL(an_switch, 0), nusd = an_usd, nblock = an_nblock, ndataabsence = an_dataabsence,
      ncommcontrol = an_commctrl, ntechcontrol = an_techctrl, nmainpoint = an_main, verifyparam = av_verifyparam, vaddparams = av_addparams,
      vimportcode = av_importcode, nlockcorrecttime = an_lockcorrecttime, vcode = av_code, verifyday = av_verifyday, nclasstn = an_classtn,
      nclasstt = an_classtt, ntimezonew = an_timezonew, ntimezones = an_timezones, nopposite = an_opposite, nintegralperiod = an_nintegr,
      nlockswitch = an_lockswitch, nwithswitch = an_nwithswitch, rescanal = an_nrescanal, vnote = av_vnote, vaccount = av_account
  WHERE mid = an_mid;

  --meters
  IF util_pg.get_customer_id <> 1 THEN
      IF an_smart = 1 THEN
       DELETE FROM meters WHERE mid = an_mid AND entype BETWEEN 1 AND 6;
       UPDATE meters SET NAME = SUBSTR(av_name, 1, lc_namelength) || ' Инт.', POSITION = an_er_position, kc = an_kc WHERE mid = an_mid AND entype = 7;
       IF SQL%ROWCOUNT <= 0 THEN
        INSERT INTO meters (ID, mid, NAME, POSITION, entype, smart, kc) VALUES (points_seq.NEXTVAL, an_mid, SUBSTR(av_name, 1, lc_namelength) || ' Инт.', an_er_position, 7, '*', an_kc);
       END IF;
      ELSE
       DELETE FROM meters WHERE mid = an_mid AND entype = 7;
       IF an_er_position != 0 THEN
        UPDATE meters SET NAME = SUBSTR(av_name, 1, lc_namelength) || ' А птр.', POSITION = an_er_position, kc = an_kc WHERE mid = an_mid AND entype = 1;
        IF SQL%ROWCOUNT <= 0 THEN
         INSERT INTO meters (ID, mid, NAME, POSITION, entype, smart, kc) VALUES (points_seq.NEXTVAL, an_mid, SUBSTR(av_name, 1, lc_namelength) || ' А птр.', an_er_position, 1, '', an_kc);
        END IF;
       ELSE
        DELETE FROM meters WHERE mid = an_mid AND entype = 1;
       END IF;
       IF an_ed_position != 0 THEN
        UPDATE meters SET NAME = SUBSTR(av_name, 1, lc_namelength) || ' А выд.', POSITION = an_ed_position, kc = an_kc WHERE mid = an_mid AND entype = 2;
        IF SQL%ROWCOUNT <= 0 THEN
         INSERT INTO meters (ID, mid, NAME, POSITION, entype, smart, kc) VALUES (points_seq.NEXTVAL, an_mid, SUBSTR(av_name, 1, lc_namelength) || ' А выд.', an_ed_position, 2, '', an_kc);
        END IF;
       ELSE
        DELETE FROM meters WHERE mid = an_mid AND entype = 2;
       END IF;
       IF an_q1_position != 0 THEN
        UPDATE meters SET NAME = SUBSTR(av_name, 1, lc_namelength) || ' Р птр.', POSITION = an_q1_position, kc = an_kc WHERE mid = an_mid AND entype = 3;
        IF SQL%ROWCOUNT <= 0 THEN
         INSERT INTO meters (ID, mid, NAME, POSITION, entype, smart, kc) VALUES (points_seq.NEXTVAL, an_mid, SUBSTR(av_name, 1, lc_namelength) || ' Р птр.', an_q1_position, 3, '', an_kc);
        END IF;
       ELSE
        DELETE FROM meters WHERE mid = an_mid AND entype = 3;
       END IF;
       IF an_q3_position != 0 THEN
        UPDATE meters SET NAME = SUBSTR(av_name, 1, lc_namelength) || ' Р выд.', POSITION = an_q3_position, kc = an_kc WHERE mid = an_mid AND entype = 5;
        IF SQL%ROWCOUNT <= 0 THEN
         INSERT INTO meters (ID, mid, NAME, POSITION, entype, smart, kc) VALUES (points_seq.NEXTVAL, an_mid, SUBSTR(av_name, 1, lc_namelength) || ' Р выд.', an_q3_position, 5, '', an_kc);
        END IF;
       ELSE
        DELETE FROM meters WHERE mid = an_mid AND entype = 5;
       END IF;
      END IF;
  END IF;

  IF util_pg.get_customer_id = 1 THEN
   ln_gid := editfeeders_pg.insgroup(an_parent);
   ln_gid1 := editfeeders_pg.insgroup(an_mid);

   UPDATE GROUPS SET NAME = av_name, PARENT = ln_gid WHERE nroot1 = 1 AND nroot2 = an_mid;
  END IF;

  admin_pg.fiscal_p(gn_task_code, 2, 'Изменены атрибуты точки ' || util_pg.node_path_f(an_mid, 'points', 'mid', 'parent'));

  IF ln_old_kc <> an_kc THEN file_pg.startbyevents_p(46, an_mid, SYSDATE); END IF;
 EXCEPTION
  WHEN OTHERS THEN
   ROLLBACK TO SAVEPOINT editfeeders_upd;
   raise_application_error(-20001, 'editfeeders_pg.upd_p: Ошибка обновления присоединения. ' || CHR(10) || SQLERRM(SQLCODE));
 END;
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
 -- Процедура обновления данных (с неполным набором параметров)
 PROCEDURE upd_p(
 an_mid NUMBER, av_importcode VARCHAR2, an_canal NUMBER, an_tag NUMBER,
 an_er_position NUMBER, an_q1_position NUMBER, an_ed_position NUMBER, an_q3_position NUMBER,
 av_info VARCHAR2, an_nblock NUMBER, an_dataabsence NUMBER, an_commctrl NUMBER, an_techctrl NUMBER, an_lockcorrecttime NUMBER,
 an_timezonew NUMBER, an_timezones NUMBER, an_rescanal NUMBER
 ) IS
  CURSOR lcur_f(cn_mid NUMBER) IS
   SELECT p.mid, p.PARENT, 0 ntype, p.NAME, p.short_name, DECODE(f.smart, '*', 1, 0) smart, DECODE(f.q1234, '*', 1, 0) q1234, f.cellnum, f.POWER, f.current1,
          f.current2, f.kc, f.power2, f.metkc, f.nabc, f.ncalcbill, f.ncalcmonths, f.ninverted, f.nswitch, f.nlockswitch, f.nwithswitch, f.nusd, f.vcode,
          f.nmainpoint, f.verifyparam, f.vaddparams, f.verifyday, f.nclasstn, f.nclasstt, f.nopposite, p.norder, f.nintegralperiod, f.rescanal, f.vnote,
          f.vaccount, p.mms, p.eic, p.ctype, p.status, p.point_eic, p.site_eic
   FROM   points p, feeders f
   WHERE  p.mid = f.mid(+) AND p.mid = cn_mid;
 BEGIN
  FOR cr IN lcur_f(an_mid) LOOP
   upd_p(an_mid, cr.PARENT, cr.ntype, cr.NAME, cr.short_name, an_er_position, an_q1_position, an_ed_position, an_q3_position, cr.smart, cr.q1234, an_canal,
    cr.cellnum, cr.POWER, cr.current1, cr.current2, cr.kc, an_tag, av_info, cr.power2, cr.metkc, cr.nabc, cr.ncalcbill, cr.ncalcmonths, cr.ninverted,
    cr.nswitch, cr.nusd, an_nblock, an_dataabsence, an_commctrl, an_techctrl, cr.nmainpoint, cr.verifyparam, cr.vaddparams, av_importcode, an_lockcorrecttime,
    cr.vcode, cr.verifyday, cr.nclasstn, cr.nclasstt, an_timezonew, an_timezones, cr.nopposite, cr.norder, cr.nintegralperiod, cr.nlockswitch, cr.nwithswitch,
    an_rescanal, cr.vnote, cr.vaccount, cr.mms, cr.eic, cr.ctype, cr.status, cr.point_eic, cr.site_eic);
  END LOOP;
 END;

--------------------------------------------------------------------------------------------
--Процедура обновления параметров
 PROCEDURE upd_last_save(
 an_mid NUMBER,                                                                                                                                       --Ид точки
               ad_profile DATE,                                                                                             -- Дата постедней считанного профиля
                               ad_halfhour DATE,                                                                        -- Дата постедней считанного получасовки
                                                ad_bill DATE,                                                   -- Дата постедней считанного суточного показания
 ad_month DATE                                                                                                  -- Дата постедней считанного месячного показания
 ) IS
  ld_sys              DATE DEFAULT TRUNC(SYSDATE);
 BEGIN
  ins_last_save(an_mid);

  UPDATE last_save
  SET PROFILE = ad_profile,
      halfhour = ad_halfhour,
      bill = ad_bill,
      months = ad_month
  WHERE  mid = an_mid;

  admin_pg.fiscal_p(gn_task_code, 2, 'Изменены параметры дат считанных данных (LAST_SAVE) для точки ' || util_pg.node_path_f(an_mid, 'points', 'mid', 'parent'));
  COMMIT;
 EXCEPTION
  WHEN OTHERS THEN
   ROLLBACK;
   raise_application_error(-20001, 'editfeeders_pg.upd_last_save: Ошибка обновления параметров сохраненных данных. ' || CHR(10) || SQLERRM(SQLCODE));
 END;

------------------------------------------------------------------------------------------------------------------------
  --Процедура добавления пустой строки в last_save
 PROCEDURE ins_last_save(an_mid NUMBER,                                                                                                               --Ид точки
                                       av_state VARCHAR2 DEFAULT NULL, an_state_cod NUMBER DEFAULT 0, an_clock NUMBER DEFAULT 0) IS
  ld_sys              DATE DEFAULT TRUNC(SYSDATE);
 BEGIN
  INSERT INTO last_save
              (mid, PROFILE, halfhour, bill, state_date, state_cod, state_descr, clock, luck, rates, months, journal)
   SELECT an_mid, ld_sys - 10, ld_sys - 370, ld_sys - 370, ld_sys, NVL(an_state_cod, 0), NVL(av_state, 'Опрос не производился '), NVL(an_clock, 0),
          ld_sys - 100, ld_sys - 100, ld_sys - 370, ld_sys - 370
   FROM   DUAL
   WHERE  NOT EXISTS(SELECT *
                     FROM   last_save
                     WHERE  mid = an_mid);
 END;

------------------------------------------------------------------------------------------------------------------------
   -- Пересчитывает расход по показаниям счетчика и ГН
 PROCEDURE recalcdiff(an_mid NUMBER, ad_from DATE, an_onyformula NUMBER DEFAULT NULL) IS                                                                             --расход
  ld_calcperiod       DATE DEFAULT admin_pg.get_calcperiod;
  ln_rn               NUMBER DEFAULT 10;
  lv_name             VARCHAR2(4000);
  ln_const            NUMBER;
  ln_shift_erm        NUMBER;
  ln_ind              NUMBER;
  ln_calc             NUMBER;
 BEGIN
  SELECT MAX(p.ind), MAX(f.ncalcpointtype)
  INTO   ln_ind, ln_calc
  FROM   points p, feeders f
  WHERE  p.mid = an_mid AND p.mid = f.mid(+);

  IF ln_ind < 3 THEN
   lv_name := util_pg.node_path_f(an_mid, 'points', 'mid', 'parent');
   admin_pg.fiscal_p(gn_task_code, 2, 'Инициирован перерасчет расхода начиная с ' || TO_CHAR(ad_from, 'DD.MM.YYYY HH24:MI:SS') || ' по группе' || lv_name);
   COMMIT;
  ELSE
   IF ln_calc = calcformula_pg.cn_cpt_cons OR ln_calc = calcformula_pg.cn_cpt_amm OR ln_calc = calcformula_pg.cn_cpt_sum
      OR ln_calc = calcformula_pg.cn_cpt_formula THEN
    lv_name := util_pg.node_path_f(an_mid, 'points', 'mid', 'parent');
    admin_pg.fiscal_p(gn_task_code, 2, 'Инициирован перерасчет расхода начиная с ' || TO_CHAR(ad_from, 'DD.MM.YYYY HH24:MI:SS') || ' по точке' || lv_name);
    COMMIT;
   END IF;
  END IF;

  IF NVL(an_onyformula, 0) <> 1 THEN
   FOR lc IN (SELECT p.mid, NVL(f.kc, 0) kc, comsrvmtx_pg.is_mtx_child(f.mid, f.nusd) is_mtxchild
              FROM   (SELECT     mid, ind
                      FROM       points
                      CONNECT BY PRIOR mid = PARENT
                      START WITH mid = an_mid) p,
                     feeders f
              WHERE  p.mid = f.mid AND p.ind = 3 AND NVL(f.kc, 0) > 0
                     AND NVL(f.ncalcpointtype, 0) NOT IN
                                               (calcformula_pg.cn_cpt_cons, calcformula_pg.cn_cpt_amm, calcformula_pg.cn_cpt_sum, calcformula_pg.cn_cpt_formula)) LOOP
    lv_name := util_pg.node_path_f(lc.mid, 'points', 'mid', 'parent');

    IF lc.is_mtxchild = 1 THEN
     ln_const := get_mconst(lc.mid);
     ln_shift_erm := comsrvmtx_pg.get_shift_erm(an_mid);
    END IF;

    --Обновляем точку
    UPDATE halfhourold h
    SET er = ROUND(lc.kc * er / NVL(nkc, 1), ln_rn),
        ed = ROUND(lc.kc * ed / NVL(nkc, 1), ln_rn),
        q1 = ROUND(lc.kc * q1 / NVL(nkc, 1), ln_rn),
        q3 = ROUND(lc.kc * q3 / NVL(nkc, 1), ln_rn),
        q2 = ROUND(lc.kc * q2 / NVL(nkc, 1), ln_rn),
        q4 = ROUND(lc.kc * q4 / NVL(nkc, 1), ln_rn),
        nkc = lc.kc,
        drecalcdiff = SYSDATE,
        erm = DECODE(lc.is_mtxchild, 1, ROUND(q1m / ln_const, comsrvmtx_pg.cn_rnd) + ln_shift_erm, erm)
    WHERE  mid = lc.mid AND date_time > ad_from;

    DELETE FROM halfhourold
    WHERE       mid = lc.mid AND date_time > TRUNC(ad_from) AND NOT(nsource BETWEEN 1 AND util_pg.cn_manualinputw);

    UPDATE billorg
    SET er = ROUND(lc.kc * er / NVL(er_kc, 1), ln_rn),
        aer = ROUND(lc.kc * aer / NVL(er_kc, 1), ln_rn),
        ber = ROUND(lc.kc * ber / NVL(er_kc, 1), ln_rn),
        cer = ROUND(lc.kc * cer / NVL(er_kc, 1), ln_rn),
        ed = ROUND(lc.kc * ed / NVL(ed_kc, 1), ln_rn),
        aed = ROUND(lc.kc * aed / NVL(ed_kc, 1), ln_rn),
        bed = ROUND(lc.kc * bed / NVL(ed_kc, 1), ln_rn),
        ced = ROUND(lc.kc * ced / NVL(ed_kc, 1), ln_rn),
        q1 = ROUND(lc.kc * q1 / NVL(q1_kc, 1), ln_rn),
        aq1 = ROUND(lc.kc * aq1 / NVL(q1_kc, 1), ln_rn),
        bq1 = ROUND(lc.kc * bq1 / NVL(q1_kc, 1), ln_rn),
        cq1 = ROUND(lc.kc * cq1 / NVL(q1_kc, 1), ln_rn),
        q3 = ROUND(lc.kc * q3 / NVL(q3_kc, 1), ln_rn),
        aq3 = ROUND(lc.kc * aq3 / NVL(q3_kc, 1), ln_rn),
        bq3 = ROUND(lc.kc * bq3 / NVL(q3_kc, 1), ln_rn),
        cq3 = ROUND(lc.kc * cq3 / NVL(q3_kc, 1), ln_rn),
        q2 = ROUND(lc.kc * q2 / NVL(q2_kc, 1), ln_rn),
        aq2 = ROUND(lc.kc * aq2 / NVL(q2_kc, 1), ln_rn),
        bq2 = ROUND(lc.kc * bq2 / NVL(q2_kc, 1), ln_rn),
        cq2 = ROUND(lc.kc * cq2 / NVL(q2_kc, 1), ln_rn),
        q4 = ROUND(lc.kc * q4 / NVL(q4_kc, 1), ln_rn),
        aq4 = ROUND(lc.kc * aq4 / NVL(q4_kc, 1), ln_rn),
        bq4 = ROUND(lc.kc * bq4 / NVL(q4_kc, 1), ln_rn),
        cq4 = ROUND(lc.kc * cq4 / NVL(q4_kc, 1), ln_rn),
        er_kc = lc.kc,
        ed_kc = lc.kc,
        q1_kc = lc.kc,
        q2_kc = lc.kc,
        q3_kc = lc.kc,
        q4_kc = lc.kc,
		drecalcdiff = SYSDATE,
        erm = DECODE(lc.is_mtxchild, 1, ROUND(q1m / ln_const, comsrvmtx_pg.cn_rnd) + ln_shift_erm, erm)
    WHERE  mid = lc.mid AND date_time > ad_from;

    UPDATE monthsorg
    SET er = ROUND(lc.kc * er / NVL(er_kc, 1), ln_rn),
        aer = ROUND(lc.kc * aer / NVL(er_kc, 1), ln_rn),
        ber = ROUND(lc.kc * ber / NVL(er_kc, 1), ln_rn),
        cer = ROUND(lc.kc * cer / NVL(er_kc, 1), ln_rn),
        ed = ROUND(lc.kc * ed / NVL(ed_kc, 1), ln_rn),
        aed = ROUND(lc.kc * aed / NVL(ed_kc, 1), ln_rn),
        bed = ROUND(lc.kc * bed / NVL(ed_kc, 1), ln_rn),
        ced = ROUND(lc.kc * ced / NVL(ed_kc, 1), ln_rn),
        q1 = ROUND(lc.kc * q1 / NVL(q1_kc, 1), ln_rn),
        aq1 = ROUND(lc.kc * aq1 / NVL(q1_kc, 1), ln_rn),
        bq1 = ROUND(lc.kc * bq1 / NVL(q1_kc, 1), ln_rn),
        cq1 = ROUND(lc.kc * cq1 / NVL(q1_kc, 1), ln_rn),
        q3 = ROUND(lc.kc * q3 / NVL(q3_kc, 1), ln_rn),
        aq3 = ROUND(lc.kc * aq3 / NVL(q3_kc, 1), ln_rn),
        bq3 = ROUND(lc.kc * bq3 / NVL(q3_kc, 1), ln_rn),
        cq3 = ROUND(lc.kc * cq3 / NVL(q3_kc, 1), ln_rn),
        q2 = ROUND(lc.kc * q2 / NVL(q2_kc, 1), ln_rn),
        aq2 = ROUND(lc.kc * aq2 / NVL(q2_kc, 1), ln_rn),
        bq2 = ROUND(lc.kc * bq2 / NVL(q2_kc, 1), ln_rn),
        cq2 = ROUND(lc.kc * cq2 / NVL(q2_kc, 1), ln_rn),
        q4 = ROUND(lc.kc * q4 / NVL(q4_kc, 1), ln_rn),
        aq4 = ROUND(lc.kc * aq4 / NVL(q4_kc, 1), ln_rn),
        bq4 = ROUND(lc.kc * bq4 / NVL(q4_kc, 1), ln_rn),
        cq4 = ROUND(lc.kc * cq4 / NVL(q4_kc, 1), ln_rn),
        er_kc = lc.kc,
        ed_kc = lc.kc,
        q1_kc = lc.kc,
        q2_kc = lc.kc,
        q3_kc = lc.kc,
        q4_kc = lc.kc,
		drecalcdiff = SYSDATE,
        erm = DECODE(lc.is_mtxchild, 1, ROUND(q1m / ln_const, comsrvmtx_pg.cn_rnd) + ln_shift_erm, erm)
    WHERE  mid = lc.mid AND date_time > ad_from;

    --Обновляем ОВ
    UPDATE halfhourold
    SET er = ROUND(lc.kc * er / NVL(nkc, 1), ln_rn),
        ed = ROUND(lc.kc * ed / NVL(nkc, 1), ln_rn),
        q1 = ROUND(lc.kc * q1 / NVL(nkc, 1), ln_rn),
        q3 = ROUND(lc.kc * q3 / NVL(nkc, 1), ln_rn),
        q2 = ROUND(lc.kc * q2 / NVL(nkc, 1), ln_rn),
        q4 = ROUND(lc.kc * q4 / NVL(nkc, 1), ln_rn),
        nkc = lc.kc,
        denter = SYSDATE,
        erm = DECODE(lc.is_mtxchild, 1, ROUND(q1m / ln_const, comsrvmtx_pg.cn_rnd) + ln_shift_erm, erm)
    WHERE  nswitch = lc.mid AND date_time > ad_from;

    DELETE FROM halfhourold
    WHERE       nswitch = lc.mid AND date_time > TRUNC(ad_from) AND NOT(nsource BETWEEN 1 AND util_pg.cn_manualinputw);

    -- Чистим bill
    DELETE FROM billold
    WHERE       mid = lc.mid AND date_time > ad_from;

    calcformula_pg.calcpoint4bill(lc.mid, TRUNC(ad_from), ld_calcperiod + 1);
    admin_pg.fiscal_p(gn_task_code, 2, 'Выполнен перерасчет расхода начиная с ' || TO_CHAR(ad_from, 'DD.MM.YYYY HH24:MI:SS') || ' по точке учета ' || lv_name);
    COMMIT;
   END LOOP;
  END IF;

  FOR i IN 0 .. TRUNC(SYSDATE - TRUNC(ad_from)) - 1 LOOP
   calcformula_pg.calc(TRUNC(ad_from) + i, an_mid);
   COMMIT;
  END LOOP;

  COMMIT;
  calcformula_pg.calc_lagging_job;
  COMMIT;
 EXCEPTION
  WHEN OTHERS THEN
   ROLLBACK;
   raise_application_error(-20001, 'edtfeeders_pg.recalcdiff: Ошибка перерасчета расходапо точке: ''' || lv_name || '''. ' || CHR(10) || SQLERRM(SQLCODE));
 END;

------------------------------------------------------------------------------------------------------------------------
 --Процедура удаления данных из БД
 PROCEDURE delete_data(
 an_mid NUMBER,                                                                                                                                       --Ид точки
               ad_profile DATE,                                                                                       -- Дата > которой удаляются данные профиля
                               ad_halfhour DATE,                                                                           -- Дата > которой удаляются данные ГН
                                                ad_bill DATE,                                                        -- Дата > которой удаляются данные Суточных
                                                             ad_month DATE,                                       --  Дата > которой удаляются месячные Суточных
                                                                           ad_profile_e DATE DEFAULT NULL,          -- Дата <= которой удаляются данные профиля
 ad_halfhour_e DATE DEFAULT NULL,                                                                                        -- Дата <= которой удаляются данные ГН
                                 ad_bill_e DATE DEFAULT NULL,                                                      -- Дата <= которой удаляются данные Суточных
                                                             ad_month_e DATE DEFAULT NULL,                      --  Дата <= которой удаляются месячные Суточных
 ad_journal DATE DEFAULT NULL,                                                                                       -- Дата > которой удаляются данные Журнала
                              ad_journal_e DATE DEFAULT NULL,                                                       -- Дата <= которой удаляются данные Журнала
                                                             ad_currpower DATE DEFAULT NULL,                     --  Дата > которой удаляются мгновенные данные
 ad_currpower_e DATE DEFAULT NULL,                                                                              --  Дата <= которой удаляются мгновенные данные
                                  an_withreload NUMBER DEFAULT 1                                                                     --Признак сдвига LAST_SAVE
 ) IS
  lv_name             VARCHAR2(4000);
  ld_end              DATE DEFAULT TO_DATE(300001, 'YYYYMM');
  ln_ind              NUMBER;
 BEGIN
  SELECT MAX(ind)
  INTO   ln_ind
  FROM   points
  WHERE  mid = an_mid;

  IF ln_ind < 3 THEN
   lv_name := util_pg.node_path_f(an_mid, 'points', 'mid', 'parent');
   admin_pg.fiscal_p(gn_task_code, 3,
       'Инициировано удаление данных профиля за период с '
    || TO_CHAR(ad_profile, 'DD.MM.YYYY HH24:MI:SS')
    || ' по '
    || TO_CHAR(NVL(ad_profile_e, ld_end), 'DD.MM.YYYY HH24:MI:SS')
    || ' по группе '
    || lv_name);
   COMMIT;
  END IF;

  -- FOR lc IN (SELECT p.mid, DECODE(util_pg.taketimezone, 1, 0, NVL(util_pg.cn_tzw - f.ntimezonew, 0)) tz
  FOR lc IN (SELECT p.mid, DECODE(util_pg.taketimezone, 1, NVL(util_pg.cn_tzw - f.ntimezonew, 0), 0) tz
             FROM   (SELECT     mid
                     FROM       points
                     CONNECT BY PRIOR mid = PARENT
                     START WITH mid = an_mid) p,
                    feeders f
             WHERE  f.mid = p.mid) LOOP
   lv_name := util_pg.node_path_f(lc.mid, 'points', 'mid', 'parent');

   IF ad_profile IS NOT NULL THEN
    DELETE FROM PROFILE
    WHERE       mid = lc.mid AND date_time > ad_profile AND date_time <= NVL(ad_profile_e, ld_end);

    admin_pg.fiscal_p(gn_task_code, 3,
        'Выполнено удаление данных профиля за период с '
     || TO_CHAR(ad_profile, 'DD.MM.YYYY HH24:MI:SS')
     || ' по '
     || TO_CHAR(NVL(ad_profile_e, ld_end), 'DD.MM.YYYY HH24:MI:SS')
     || ' по точке учета '
     || lv_name);
   END IF;

   IF ad_halfhour IS NOT NULL THEN
    DELETE FROM halfhourold
    WHERE       mid = lc.mid AND date_time > ad_halfhour AND date_time <= NVL(ad_halfhour_e, ld_end);

    DELETE FROM billold
    WHERE       mid = lc.mid AND date_time > ad_halfhour AND date_time <= NVL(ad_halfhour_e, ld_end);

    --ОВ
    DELETE FROM billold
    WHERE       mid IN(SELECT mid
                       FROM   halfhourold
                       WHERE  nswitch = lc.mid AND date_time > ad_halfhour AND date_time <= NVL(ad_halfhour_e, ld_end)) AND date_time > ad_halfhour
                AND date_time <= NVL(ad_halfhour_e, ld_end);

    DELETE FROM halfhourold
    WHERE       nswitch = lc.mid AND date_time > ad_halfhour AND date_time <= NVL(ad_halfhour_e, ld_end);

    admin_pg.fiscal_p(gn_task_code, 3,
        'Выполнено удаление данных ГН начиная с '
     || TO_CHAR(ad_halfhour, 'DD.MM.YYYY HH24:MI:SS')
     || ' по '
     || TO_CHAR(NVL(ad_halfhour_e, ld_end), 'DD.MM.YYYY HH24:MI:SS')
     || ' по точке учета '
     || lv_name);
   END IF;

   IF ad_bill IS NOT NULL THEN
    DELETE FROM billorg
    WHERE       mid = lc.mid AND date_time >= TRUNC(ad_bill) + 1 AND date_time <= NVL(ad_bill_e, ld_end);

    admin_pg.fiscal_p(gn_task_code, 3,
        'Выполнено удаление суточных данных начиная с '
     || TO_CHAR(ad_bill, 'DD.MM.YYYY HH24:MI:SS')
     || ' по '
     || TO_CHAR(NVL(ad_bill_e, ld_end), 'DD.MM.YYYY HH24:MI:SS')
     || ' по точке учета '
     || lv_name);
   END IF;

   IF ad_month IS NOT NULL THEN
    DELETE FROM monthsorg
    WHERE       mid = lc.mid AND date_time >= ADD_MONTHS(TRUNC(ad_month, 'MONTH'), 1) AND date_time <= NVL(ad_month_e, ld_end);

    admin_pg.fiscal_p(gn_task_code, 3,
        'Выполнено удаление месячных данных начиная с '
     || TO_CHAR(ad_month, 'DD.MM.YYYY HH24:MI:SS')
     || ' по '
     || TO_CHAR(NVL(ad_month_e, ld_end), 'DD.MM.YYYY HH24:MI:SS')
     || ' по точке учета '
     || lv_name);
   END IF;

   IF ad_journal IS NOT NULL THEN
    DELETE FROM journal
    WHERE       mid = lc.mid AND date_time > ad_journal AND date_time <= NVL(ad_journal_e, ld_end);

    DELETE FROM ea_events
    WHERE       mid = lc.mid AND evdate > ad_journal AND evdate <= NVL(ad_journal_e, ld_end);

    admin_pg.fiscal_p(gn_task_code, 3,
        'Выполнено удаление данных журнала начиная с '
     || TO_CHAR(ad_journal, 'DD.MM.YYYY HH24:MI:SS')
     || ' по '
     || TO_CHAR(NVL(ad_journal_e, ld_end), 'DD.MM.YYYY HH24:MI:SS')
     || ' по точке учета '
     || lv_name);
   END IF;

   IF ad_currpower IS NOT NULL THEN
    DELETE FROM curr_power_arch
    WHERE       mid = lc.mid AND date_time > ad_currpower AND date_time <= NVL(ad_currpower_e, ld_end);

    admin_pg.fiscal_p(gn_task_code, 3,
        'Выполнено удаление мгновенных данных начиная с '
     || TO_CHAR(ad_currpower, 'DD.MM.YYYY HH24:MI:SS')
     || ' по '
     || TO_CHAR(NVL(ad_currpower_e, ld_end), 'DD.MM.YYYY HH24:MI:SS')
     || ' по точке учета '
     || lv_name);
   END IF;

   IF an_withreload = 1 THEN
    UPDATE last_save
    SET PROFILE = NVL(ad_profile, PROFILE),
        halfhour = NVL(util_pg.to_unlocaltime(ad_halfhour) - lc.tz / 24, halfhour),
        bill = NVL(ad_bill, bill),
        months = NVL(ad_month, months),
        journal = NVL(ad_journal, journal)
    WHERE  mid = lc.mid;
   END IF;

   COMMIT;
  END LOOP;

  COMMIT;
 EXCEPTION
  WHEN OTHERS THEN
   ROLLBACK;
   raise_application_error(-20001, 'indic_pg.delete_data: Ошибка удаления данных по точке: ''' || lv_name || '''. ' || CHR(10) || SQLERRM(SQLCODE));
 END;

------------------------------------------------------------------------------------------------------------------------

 --ищем точку, группу или канал (an_mid - точка старта)
 FUNCTION findpoint(
 an_mid NUMBER, av_name VARCHAR2, av_code VARCHAR2, av_mtrsn VARCHAR2, av_pmid VARCHAR2 DEFAULT NULL, an_pointtype NUMBER DEFAULT NULL,
 av_canal VARCHAR2 DEFAULT NULL, av_account VARCHAR2 DEFAULT NULL
 )
  RETURN NUMBER
 IS
  lv_sql              VARCHAR2(2000);
  lv_name             VARCHAR2(2000) DEFAULT REPLACE(UPPER(TRIM(av_name)),    '*', '%');
  lv_code             VARCHAR2(2000) DEFAULT REPLACE(UPPER(TRIM(av_code)),    '*', '%');
  lv_mtrsn            VARCHAR2(2000) DEFAULT REPLACE(UPPER(TRIM(av_mtrsn)),   '*', '%');
  lv_pmid             VARCHAR2(2000) DEFAULT REPLACE(UPPER(TRIM(av_pmid)),    '*', '%');
  lv_canal            VARCHAR2(2000) DEFAULT REPLACE(UPPER(TRIM(av_canal)),   '*', '%');
  lv_account          VARCHAR2(2000) DEFAULT REPLACE(UPPER(TRIM(av_account)), '*', '%');
  ln_ret              NUMBER;
 BEGIN
--  IF an_pointtype IS NOT NULL THEN
  IF an_pointtype = 1 THEN                                                                                                                            -- группы
   lv_sql := 'select nvl(min(p.gid),0) from groups p,feeders f,meters m where p.gid> NVL (:an_mid, 0) and f.mid=p.mid and f.mid=m.mid(+) ';
  ELSIF an_pointtype = 2 THEN                                                                                                  -- каналы added by KAG 10.03.2010
   lv_sql :=
       'select nvl(min(cp.cid),0) from chanpoint cp, feeders f, meters m, points p 
               WHERE cp.cid> NVL (:an_mid, 0) AND f.mid=cp.mid AND f.mid=m.mid(+) AND p.mid=cp.mid 
                     AND EXISTS (SELECT * FROM  schemchannels
                                  WHERE noperscanschemas IN (SELECT noperscanschemas FROM ROLES
                                                              WHERE role_id IN (SELECT role_id FROM users WHERE usr = '''
    || USER
    || '''))
                                        AND cid = cp.cid) ';
  ELSE                                                                                                                                                  -- точки
   -- lv_sql := 'select nvl(min(f.mid),0) from points p,feeders f,meters m where f.mid>' || NVL (an_mid, 0) || ' and f.mid=p.mid and f.mid=m.mid(+) ';
   lv_sql := 'select nvl(min(p.mid),0) from points p, feeders f, meters m where p.mid > NVL(:an_mid, 0) and p.mid = f.mid(+) and f.mid = m.mid(+) ';
  END IF;

  IF lv_name IS NOT NULL THEN
   IF INSTR(lv_name, '%') > 0 THEN
    lv_sql := lv_sql || ' and upper(p.NAME) like ''' || lv_name || '''';
   ELSE
    lv_sql := lv_sql || ' and upper(p.NAME)=''' || lv_name || '''';
   END IF;
  END IF;

  IF lv_account IS NOT NULL THEN
   IF INSTR(lv_account, '%') > 0 THEN
    lv_sql := lv_sql || ' and upper(f.vaccount) like ''' || lv_account || '''';
   ELSE
    lv_sql := lv_sql || ' and upper(f.vaccount)=''' || lv_account || '''';
   END IF;
  END IF;

  IF lv_code IS NOT NULL THEN
   IF INSTR(lv_code, '%') > 0 THEN
    lv_sql := lv_sql || ' and upper(f.VCODE) like ''' || lv_code || '''';
   ELSE
    lv_sql := lv_sql || ' and upper(f.VCODE)=''' || lv_code || '''';
   END IF;
  END IF;

  IF lv_mtrsn IS NOT NULL THEN
   IF INSTR(lv_mtrsn, '%') > 0 THEN
    lv_sql := lv_sql || ' and upper(m.MTRSN) like ''' || lv_mtrsn || '''';
   ELSE
    lv_sql := lv_sql || ' and upper(m.MTRSN)=''' || lv_mtrsn || '''';
   END IF;
  END IF;            
                     
  IF lv_pmid IS NOT NULL THEN
   IF INSTR(lv_pmid, '%') > 0 THEN
    IF an_pointtype = 1 THEN
     lv_sql := lv_sql || ' and upper(p.GID) like ''' || lv_pmid || '''';
    ELSE
     lv_sql := lv_sql || ' and upper(p.MID) like ''' || lv_pmid || '''';
    END IF;
   ELSE
    IF an_pointtype = 1 THEN
     lv_sql := lv_sql || ' and upper(p.GID)=''' || lv_pmid || '''';
    ELSE
     lv_sql := lv_sql || ' and upper(p.MID)=''' || lv_pmid || '''';
    END IF;
   END IF;
  END IF;

  IF lv_canal IS NOT NULL THEN
   IF INSTR(lv_canal, '%') > 0 THEN
    lv_sql := lv_sql || ' and ( upper(f.CANAL) like ''' || lv_canal || ''' OR upper(f.RESCANAL) like ''' || lv_canal || ''')';
   ELSE
    lv_sql := lv_sql || ' and ( upper(f.CANAL)=''' || lv_canal || ''' OR upper(f.RESCANAL)=''' || lv_canal || ''')';
   END IF;
  END IF;

  EXECUTE IMMEDIATE lv_sql
  INTO              ln_ret
  USING             an_mid;

  RETURN ln_ret;
 END;




--------========================================================================================================================================================================================

 --ищем точку, группу, канал опроса счетчиков, канал рассылки макетов                                                                                added KVV 25.02.2021 

 PROCEDURE findpoint(
                       an_pointtype NUMBER, av_pmid VARCHAR2 DEFAULT NULL, av_name VARCHAR2 DEFAULT NULL, av_shortname VARCHAR2 DEFAULT NULL, 
                         av_code VARCHAR2 DEFAULT NULL, av_mtrsn VARCHAR2 DEFAULT NULL, av_canal VARCHAR2 DEFAULT NULL, av_account VARCHAR2 DEFAULT NULL, 
                           av_note VARCHAR2 DEFAULT NULL,  av_vcode VARCHAR2 DEFAULT NULL, av_vimportcode VARCHAR2 DEFAULT NULL, acur_t OUT common_pg.tcur
                      )
 IS
  ln_pointtype        NUMBER DEFAULT an_pointtype;
  lv_sql              VARCHAR2(4000);
  lv_pmid             VARCHAR2(2000) DEFAULT REPLACE(UPPER(TRIM(av_pmid)),     '*', '%');
  lv_name             VARCHAR2(2000) DEFAULT REPLACE(UPPER(TRIM(av_name)),     '*', '%');
  lv_shortname        VARCHAR2(2000) DEFAULT REPLACE(UPPER(TRIM(av_shortname)),'*', '%');
  lv_code             VARCHAR2(2000) DEFAULT REPLACE(UPPER(TRIM(av_code)),     '*', '%');
  lv_mtrsn            VARCHAR2(2000) DEFAULT REPLACE(UPPER(TRIM(av_mtrsn)),    '*', '%');
  lv_canal            VARCHAR2(2000) DEFAULT REPLACE(UPPER(TRIM(av_canal)),    '*', '%');
  lv_account          VARCHAR2(2000) DEFAULT REPLACE(UPPER(TRIM(av_account)),  '*', '%');
  lv_note	          VARCHAR2(2000) DEFAULT REPLACE(UPPER(TRIM(av_note)),     '*', '%');
  lv_vimportcode      VARCHAR2(2000) DEFAULT REPLACE(UPPER(TRIM(av_vimportcode)),'*','%');
  lv_vcode            VARCHAR2(2000) DEFAULT REPLACE(UPPER(TRIM(av_vcode)),    '*', '%');


 BEGIN
  IF an_pointtype IS NULL THEN  ln_pointtype := 0; END IF;

  IF an_pointtype = 1 OR an_pointtype = 11 THEN                                                                                                     -- группы учета
              
              lv_sql := 'SELECT nvl(g.gid,0) mid FROM groups g, groups gg  WHERE g.gid = gg.gid ';
 
  ELSIF an_pointtype = 2 OR an_pointtype = 22 THEN                                                                                                  -- каналы опроса счетчиков

              lv_sql := 'SELECT NVL(p.mid,0) mid FROM (SELECT *  FROM points WHERE mid > 1 CONNECT BY PRIOR mid = parent START WITH mid = 1) p,  channels c
                                WHERE p.mid = c.cid(+) AND NVL(c.nkind, 0) <> 1 ';
/*'                     AND EXISTS (SELECT * FROM  schemchannels
                                  WHERE noperscanschemas IN (SELECT noperscanschemas FROM ROLES
                                                   WHERE role_id IN (SELECT role_id FROM users WHERE usr = '''|| USER|| '''))
                                        AND cid = cp.cid) ';  */
   ELSIF an_pointtype = 3 OR an_pointtype = 33 THEN                                                                                                 -- каналы рассылки макетов                   
              lv_sql := 'SELECT nvl(p.mid,0) mid FROM (SELECT *  FROM points WHERE mid > 3 CONNECT BY PRIOR mid = parent START WITH mid = 3) p, points pp  
                              WHERE p.mid = pp.mid ';                                                                  
 
   ELSE                                                                                                                                             -- точки учета
              lv_sql := 'SELECT nvl(p.mid,0) mid FROM( SELECT * FROM points CONNECT BY PRIOR mid = parent START WITH mid = 1000) p, points pp 
                              WHERE p.mid = pp.mid ';

 END IF;
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 IF lv_pmid IS NOT NULL THEN
   IF INSTR(lv_pmid, '%') > 0 THEN
    IF an_pointtype IN (11, 22, 33) THEN lv_sql := lv_sql;
    ELSIF an_pointtype = 1 THEN
                             lv_sql := lv_sql || ' AND UPPER(g.gid) LIKE ''' || lv_pmid || '''';
    ELSE
                             lv_sql := lv_sql || ' AND UPPER(p.mid) LIKE ''' || lv_pmid || '''';
    END IF;
   ELSE
    CASE an_pointtype WHEN  1 THEN lv_sql := lv_sql || ' AND UPPER(g.gid)=''' || lv_pmid || '''';
                      WHEN 11 THEN lv_sql := lv_sql || ' AND UPPER(g.mid)=''' || lv_pmid || '''';
                      WHEN 22 THEN lv_sql := lv_sql || ' AND UPPER(p.mid) IN (SELECT cid FROM chanpoint WHERE UPPER(mid)=''' || lv_pmid || ''')';
                      WHEN 33 THEN lv_sql := lv_sql || ' AND UPPER(p.mid) IN (SELECT ndeportation FROM deportation WHERE nmaket  = ''' || lv_pmid || ''')';
                      ELSE         lv_sql := lv_sql || ' AND UPPER(p.mid)=''' || lv_pmid || '''';
    END CASE;
   END IF;
 END IF;
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 IF lv_name IS NOT NULL THEN
   IF INSTR(lv_name, '%') > 0 THEN
     IF an_pointtype IN (11, 22, 33) THEN  lv_sql := lv_sql;
     ELSIF an_pointtype = 1 THEN
                             lv_sql := lv_sql || ' AND UPPER(g.name) LIKE ''' || lv_name || '''';
       ELSE
                             lv_sql := lv_sql || ' AND UPPER(p.name) LIKE ''' || lv_name || '''';
     END IF;
   ELSE
     CASE WHEN  an_pointtype IN (11, 22) THEN  lv_sql := lv_sql;
          WHEN  an_pointtype =  1        THEN  lv_sql := lv_sql || ' AND UPPER(g.name)=''' || lv_name || '''';
          WHEN  an_pointtype = 33        THEN  lv_sql := lv_sql || ' AND UPPER(p.mid) IN (SELECT ndeportation 
                                                                          FROM deportation 
                                                                              WHERE nmaket  IN (SELECT nmaket FROM makets WHERE UPPER(vname) = ''' || lv_name || '''))';
          ELSE  lv_sql := lv_sql || ' AND UPPER(p.name)=''' || lv_name || '''';
     END CASE;
   END IF;
 END IF;
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 IF lv_shortname IS NOT NULL THEN
   IF INSTR(lv_shortname, '%') > 0 THEN
     IF an_pointtype IN (11, 2, 22, 3, 33) THEN  lv_sql := lv_sql;
     ELSIF an_pointtype = 1 THEN
                             lv_sql := lv_sql || ' AND UPPER(g.short_name) LIKE ''' || lv_shortname || '''';
       ELSE
                             lv_sql := lv_sql || ' AND UPPER(p.short_name) LIKE ''' || lv_shortname || '''';
     END IF;
   ELSE
     IF an_pointtype IN (11, 2, 22, 3, 33) THEN  lv_sql := lv_sql;
     ELSIF an_pointtype = 1 THEN
                             lv_sql := lv_sql || ' AND UPPER(g.short_name)=''' || lv_shortname || '''';
       ELSE
                             lv_sql := lv_sql || ' AND UPPER(p.short_name)=''' || lv_shortname || '''';
     END IF;
   END IF;
 END IF; 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 IF lv_code IS NOT NULL THEN
   IF INSTR(lv_code, '%') > 0 THEN
     IF an_pointtype IN (1, 11, 2, 22, 3, 33) THEN  
          lv_sql := lv_sql;
      ELSE
          lv_sql := lv_sql || ' AND p.mid IN (SELECT mid FROM feeders WHERE UPPER(vcode) LIKE ''' || lv_code || ''')';
      END IF;    
    ELSE
        CASE WHEN an_pointtype IN (1, 2, 3, 33) THEN  lv_sql := lv_sql;
             WHEN an_pointtype = 11 THEN lv_sql := lv_sql || ' AND g.mid IN (SELECT mid FROM feeders WHERE UPPER(vcode) = ''' || lv_code || ''')';
             WHEN an_pointtype = 22 THEN lv_sql := lv_sql || ' AND p.mid IN (SELECT cid FROM chanpoint 
                                                                               WHERE mid IN (SELECT mid FROM feeders WHERE UPPER(vcode) = ''' || lv_code || '''))';
             ELSE  
           lv_sql := lv_sql || ' AND p.mid IN (SELECT mid FROM feeders WHERE UPPER(vcode) = ''' || lv_code || ''')';
        END CASE;  
   END IF;
 END IF;
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF lv_mtrsn IS NOT NULL THEN
   CASE WHEN  INSTR(lv_mtrsn, '%') > 0 AND an_pointtype IS NULL 
           THEN lv_sql := lv_sql || ' AND p.mid IN (SELECT DISTINCT mid FROM meters WHERE UPPER(mtrsn) LIKE ''' || lv_mtrsn || ''')';
        WHEN  an_pointtype IS NULL 
           THEN  lv_sql := lv_sql || ' AND p.mid IN (SELECT DISTINCT mid FROM meters WHERE UPPER(mtrsn) = ''' || lv_mtrsn || ''')';
        ELSE  lv_sql := lv_sql;
   END CASE;
END IF; 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF lv_canal IS NOT NULL THEN
   CASE WHEN  INSTR(lv_canal, '%') > 0 AND an_pointtype IS NULL 
           THEN lv_sql := lv_sql || ' AND p.mid IN (SELECT mid FROM feeders WHERE (UPPER(canal) LIKE ''' || lv_canal || ''' OR UPPER(rescanal) LIKE ''' || lv_canal || '''))';
        WHEN  an_pointtype IS NULL 
           THEN  lv_sql := lv_sql || ' AND p.mid IN (SELECT mid FROM feeders WHERE (UPPER(canal) = ''' || lv_canal || ''' OR UPPER(rescanal) = ''' || lv_canal || '''))';
        ELSE  lv_sql := lv_sql;
   END CASE;
END IF; 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
IF lv_account IS NOT NULL THEN
   CASE WHEN  INSTR(lv_account, '%') > 0 AND an_pointtype IS NULL 
           THEN lv_sql := lv_sql || ' AND p.mid IN (SELECT mid FROM feeders WHERE UPPER(vaccount) LIKE ''' || lv_account || ''')';
        WHEN  an_pointtype IS NULL
           THEN  lv_sql := lv_sql || ' AND p.mid IN (SELECT mid FROM feeders WHERE UPPER(vaccount) = ''' || lv_account || ''')';
        ELSE  lv_sql := lv_sql;
   END CASE;
END IF; 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
 IF lv_note IS NOT NULL THEN
   IF INSTR(lv_note, '%') > 0  THEN
      CASE  ln_pointtype WHEN 0  THEN  lv_sql := lv_sql || ' AND p.mid IN (SELECT mid FROM feeders WHERE UPPER(vnote) LIKE ''' || lv_note || ''')';
                         WHEN 2  THEN  lv_sql := lv_sql || ' AND p.mid IN (SELECT cid FROM channels WHERE UPPER(vnote) LIKE ''' || lv_note || ''')';
                         WHEN 3  THEN  lv_sql := lv_sql || ' AND p.mid IN (SELECT ndeportation FROM deportation WHERE UPPER(vnote) LIKE ''' || lv_note || ''')';
         ELSE   lv_sql := lv_sql;
       END CASE; 
  ELSE   
      CASE  ln_pointtype WHEN  0  THEN  lv_sql := lv_sql || ' AND p.mid IN (SELECT mid FROM feeders WHERE UPPER(vnote) = ''' || lv_note || ''')';
                         WHEN  2  THEN  lv_sql := lv_sql || ' AND p.mid IN (SELECT cid FROM channels WHERE UPPER(vnote) = ''' || lv_note || ''')';
                         WHEN  3  THEN  lv_sql := lv_sql || ' AND p.mid IN (SELECT ndeportation FROM deportation WHERE UPPER(vnote) = ''' || lv_note || ''')';
                         WHEN 33  THEN  lv_sql := lv_sql || ' AND p.mid IN (SELECT ndeportation 
                                                                               FROM deportation 
                                                                                  WHERE nmaket IN (SELECT nmaket FROM makets WHERE UPPER(vnote) = ''' || lv_note || '''))';
         ELSE   lv_sql := lv_sql;
       END CASE; 
   END IF; 
 END IF; 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF lv_vimportcode IS NOT NULL THEN
   CASE WHEN  INSTR(lv_vimportcode, '%') > 0 AND an_pointtype IS NULL 
           THEN lv_sql := lv_sql || ' AND p.mid IN (SELECT mid FROM feeders WHERE UPPER(vimportcode) LIKE ''' || lv_vimportcode || ''')';
        WHEN  an_pointtype IS NULL
           THEN  lv_sql := lv_sql || ' AND p.mid IN (SELECT mid FROM feeders WHERE UPPER(vimportcode) = ''' || lv_vimportcode || ''')';
        ELSE  lv_sql := lv_sql;
   END CASE;
END IF; 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF lv_vcode IS NOT NULL THEN
   CASE WHEN  INSTR(lv_vcode, '%') > 0 AND an_pointtype IS NULL 
           THEN lv_sql := lv_sql || ' AND p.mid IN (SELECT DISTINCT mid  FROM maketpoints a WHERE a.ngroup IN 
                                                     (SELECT a.ngroup FROM maketgroups a  WHERE a.vcode LIKE ''' || lv_vcode || '''))';
        WHEN  an_pointtype IS NULL
           THEN lv_sql := lv_sql || ' AND p.mid IN (SELECT DISTINCT mid  FROM maketpoints a WHERE a.ngroup IN 
                                                     (SELECT a.ngroup FROM maketgroups a  WHERE a.vcode = ''' || lv_vcode || '''))';
        ELSE  lv_sql := lv_sql;
   END CASE;
END IF; 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

  OPEN acur_t FOR lv_sql;
 END;
----======================================================================================================================================================================-----
--------------------------------------------------------------------------------------------------------------
 PROCEDURE recompens_p(acur_t OUT common_pg.tcur) IS
 BEGIN
  OPEN acur_t FOR
   SELECT   nrecompens, LTRIM(TO_CHAR(nratio, '0.99')) || ' ' || vname vname, 1 nsort, nratio
   FROM     recompens
   UNION ALL
   SELECT   0 nrecompens, 'По счетчику на реактивную', 0 nsort, 0 nratio
   FROM     DUAL
   ORDER BY 3, 4 DESC;
 END;

-----------------------------------------------------------------------------------------------------------------
 PROCEDURE calcpointtype_p(acur_t OUT common_pg.tcur) IS
 BEGIN
  OPEN acur_t FOR
   SELECT   ncalcpointtype, vname, 1 nsort
   FROM     calcpointtype
   UNION ALL
   SELECT   0, 'Не производить', 0 nsort
   FROM     DUAL
   ORDER BY 3, 2;
 END;

-------------------------------------------------------------------------------------------------------------------
 PROCEDURE naccperiod_p(an_mid NUMBER, acur_t OUT common_pg.tcur) IS
 BEGIN
  OPEN acur_t FOR
   SELECT   naccperiod, nworkinghours, nfullhours
   FROM     pointfullhours
   WHERE    mid = an_mid
   ORDER BY 1 DESC;
 END;

-----------------------------------------------------------------------------------------------------------------
 PROCEDURE connectaccperiod_p(an_mid NUMBER, acur_t OUT common_pg.tcur) IS
 BEGIN
  OPEN acur_t FOR
   SELECT   naccperiod, nworkinghours, nfullhours
   FROM     connectionparamfullhours
   WHERE    nconnectionparam = an_mid
   ORDER BY 1 DESC;
 END;

-----------------------------------------------------------------------------------------------------------------
 PROCEDURE nperiod_p(an_mid NUMBER, acur_t OUT common_pg.tcur) IS
 BEGIN
  OPEN acur_t FOR
   SELECT   TO_CHAR(ddate, 'yyyymmdd') nperiod, ncurrpower, nmonthconsumpt, nkc
   FROM     pointsparam
   WHERE    mid = an_mid
   ORDER BY ddate DESC;
 END;

---------------------------------------------------------------------------------------------------------------------
 PROCEDURE readnode_p(an_mid NUMBER, an_parent NUMBER, acur_t OUT common_pg.tcur) IS
 BEGIN
  IF an_parent IS NULL THEN
   OPEN acur_t FOR
    SELECT   1 havechild, p.mid, 1 TYPE, p.NAME, p.short_name, DECODE(p.ind, 1, 1, 2, 1, 3), 0 er_position, 0 q1_position, 0 ed_position, 0 q3_position,
             0 smart, 0 q, 0 canal, 0 cellnum, 0 POWER, 0 power2, 0 current1, 0 current2, 0 kc, 0 metkc, p.tag, '' vinfo, 0 nabc, 0 ncalcbill, 0 ncalcmonths,
             0 ninverted, 0 nswitch, 0 nlockswitch, 0 nwithswitch, 0 nwastepercentcalc, 0 nworkinghours, 0 nfullhours, 0 line_loss, 0 act_loss, 0 react_loss,
             0 nrecompens, DECODE(1, 2, 0) usdmid, '' usdtext, DECODE(1, 2, 0) nblock, 0 ncalcpointtype, 0 ncurrpower, 0 nmonthconsumpt, 0 dataabs,
             0 commcontr, 0 techcontr, DECODE(1, 2, 0) mainmid, '' maintext, 0 gid, '' groupname, '' verifyparam, '' vaddparams, '' vimportcode,
             0 nlockcorrecttime, '' vcode, '' verifyday, 1 / 2 nclasstn, 1 / 2 nclasstt, 2 ntimezonew, 3 ntimezones, DECODE(1, 2, 0) oppositemid, ' ' opposite,
             p.norder, ' ' formula, '' vsource, 0 nintegralperiod, 0 rescanal, '' vnote, 0 vaccount,-1 noff,DECODE(1, 2, sysdate) doff,
             p.mms, p.eic, p.ctype, p.status, p.point_eic, p.site_eic
    FROM     points p
    WHERE    p.mid IN(SELECT * FROM TABLE(adminadd_pg.getfirst_accmid(util_pg.cn_pntmid)))
             AND EXISTS(SELECT * FROM points WHERE PARENT = p.mid AND cod = 0 AND(ind < 3 OR mid IN(SELECT mid FROM feeders)))
    UNION ALL
    SELECT   0 havechild, p.mid, 1, p.NAME, p.short_name, DECODE(p.ind, 1, 1, 2, 1, 3), 0 er_position, 0 q1_position, 0 ed_position, 0 q3_position, 0, 0,
             0 canal, 0 cellnum, 0 POWER, 0 power2, 0 current1, 0 current2, 0 kc, 0 kc, p.tag, '' vinfo, 0 nabc, 0 ncalcbill, 0 ncalcmonths, 0 ninverted,
             0 nswitch, 0 nlockswitch, 0 nwithswitch, 0 nwastepercentcalc, 0 nworkinghours, 0 nfullhours, 0 line_loss, 0 act_loss, 0 react_loss, 0 nrecompens,
             DECODE(1, 2, 0) usdmid, '' usdtext, DECODE(1, 2, 0) nblock, 0 ncalcpointtype, 0 ncurrpower, 0 nmonthconsumpt, 0 dataabs, 0 commcontr, 0 techcontr,
             DECODE(1, 2, 0) mainmid, '' maintext, 0 gid, '' groupname, '' verifyparam, '' vaddparams, '' vimportcode, 0 nlockcorrecttime, '' vcode,
             '' verifyday, 1 / 2 nclasstn, 1 / 2 nclasstt, 2 ntimezonew, 3 ntimezones, DECODE(1, 2, 0) oppositemid, ' ' opposite, p.norder, ' ' formula,
             '' vsource, 0 nintegralperiod, 0 rescanal, '' vnote, 0 vaccount,-1 noff,DECODE(1, 2, sysdate) doff,
             p.mms, p.eic, p.ctype, p.status, p.point_eic, p.site_eic
    FROM     points p
    WHERE    p.mid IN(SELECT * FROM TABLE(adminadd_pg.getfirst_accmid(util_pg.cn_pntmid)))
             AND NOT EXISTS(SELECT * FROM points WHERE PARENT = p.mid AND cod = 0 AND(ind < 3 OR mid IN(SELECT mid FROM feeders)))
    ORDER BY norder, 6, 4;
  ELSE
   IF adminadd_pg.check_accread(an_mid) = 0 THEN raise_application_error(-20002, 'В доступе отказано. an_id=' || an_mid); END IF;

   OPEN acur_t FOR
    SELECT   1 havechild, p.mid, DECODE(p.ind, 1, 1, 2, 2, 3, 3, 4) TYPE, p.NAME, p.short_name, DECODE(p.ind, 1, 1, 2, 1, 3), NVL(f.er_position, 0) er_position,
             NVL(f.q1_position, 0) q1_position, NVL(f.ed_position, 0) ed_position, NVL(f.q3_position, 0) q3_position, DECODE(f.smart, '*', 1, 0) smart,
             DECODE(f.q1234, '*', 1, 0) q, NVL(f.canal, 0) canal, f.cellnum, NVL(f.POWER, 0) POWER, NVL(f.power2, 0) power2, NVL(f.current1, 1) current1,
             NVL(f.current2, 1) current2, NVL(f.kc, 1) kc, NVL(f.metkc, 1) metkc, p.tag, vinfo, NVL(f.nabc, 0) nabc, NVL(f.ncalcbill, 0) ncalcbill,
             NVL(f.ncalcmonths, 0) ncalcmonths, NVL(f.ninverted, 0) ninverted, NVL(f.nswitch, 0) nswitch, NVL(f.nlockswitch, 0) nlockswitch,
             NVL(f.nwithswitch, 0) nwithswitch, NVL(f.nwastepercentcalc, 0) nwastepercentcalc, f.nworkinghours, f.nfullhours, f.line_loss, f.act_loss,
             f.react_loss, NVL(nrecompens, 0) nrecompens, f.nusd usdmid, util_pg.get_pointname(f.nusd, 2) usdtext, f.nblock,
             NVL(f.ncalcpointtype, 0) ncalcpointtype, util_pg.get_curr_power(p.mid) ncurrpower, util_pg.get_months_consumpt(p.mid) nmonthconsumpt,
             f.ndataabsence dataabs, f.ncommcontrol commcontr, f.ntechcontrol techcontr, f.nmainpoint mainmid, util_pg.get_pointname(f.nmainpoint, 2) maintext,
             f.verifyparam, f.vaddparams, f.vimportcode, NVL(f.nlockcorrecttime, 0) nlockcorrecttime, f.vcode, f.verifyday, NVL(f.nclasstn, 1 / 2) nclasstn,
             NVL(f.nclasstt, 1 / 2) nclasstt, NVL(f.ntimezonew, 2) ntimezonew, NVL(f.ntimezones, 3) ntimezones, f.nopposite oppositemid,
             util_pg.get_pointname(f.nopposite, 2) opposite, p.norder, NVL(editfeeders_pg.formulameas_p(p.mid), ' ') formula, t.vname vsource,
             f.nintegralperiod, f.rescanal, f.vnote, f.vaccount,nvl(cp.noff,-1) noff, cp.doff,
             p.mms, p.eic, p.ctype, p.status, p.point_eic, p.site_eic
    FROM     points p, feeders f, sourcetypes t,curr_power cp
    WHERE    p.PARENT = an_mid AND p.cod = 0 AND(p.ind < 3 OR p.mid IN(SELECT mid FROM feeders)) AND p.mid = f.mid(+) and p.mid = cp.mid(+) 
             AND EXISTS(SELECT * FROM points WHERE PARENT = p.mid AND cod = 0 AND(ind < 3 OR mid IN(SELECT mid FROM feeders))) AND p.ptype = t.ptype(+)
    UNION ALL
    SELECT   0 havechild, p.mid, DECODE(p.ind, 1, 1, 2, 2, 3, 3, 4), p.NAME, p.short_name, DECODE(p.ind, 1, 1, 2, 1, 3), NVL(f.er_position, 0),
             NVL(f.q1_position, 0), NVL(f.ed_position, 0), NVL(f.q3_position, 0), DECODE(f.smart, '*', 1, 0), DECODE(f.q1234, '*', 1, 0), NVL(f.canal, 0),
             f.cellnum, NVL(f.POWER, 0), NVL(f.power2, 0), NVL(f.current1, 1), NVL(f.current2, 1), NVL(f.kc, 1), NVL(f.metkc, 1), p.tag, vinfo, NVL(f.nabc, 0),
             NVL(f.ncalcbill, 0), NVL(f.ncalcmonths, 0), NVL(f.ninverted, 0), NVL(f.nswitch, 0), NVL(f.nlockswitch, 0) nlockswitch,
             NVL(f.nwithswitch, 0) nwithswitch, NVL(f.nwastepercentcalc, 0), f.nworkinghours, f.nfullhours, f.line_loss, f.act_loss, f.react_loss,
             NVL(nrecompens, 0) nrecompens, f.nusd, util_pg.get_pointname(f.nusd, 2), f.nblock, NVL(f.ncalcpointtype, 0) ncalcpointtype,
             util_pg.get_curr_power(p.mid) ncurrpower, util_pg.get_months_consumpt(p.mid) nmonthconsumpt, f.ndataabsence dataabs, f.ncommcontrol commcontr,
             f.ntechcontrol techcontr, f.nmainpoint mainmid, util_pg.get_pointname(f.nmainpoint, 2), f.verifyparam, f.vaddparams, f.vimportcode,
             NVL(f.nlockcorrecttime, 0), f.vcode, f.verifyday, NVL(f.nclasstn, 1 / 2) nclasstn, NVL(f.nclasstt, 1 / 2) nclasstt, NVL(f.ntimezonew, 2) ntimezonew,
             NVL(f.ntimezones, 3) ntimezones, f.nopposite oppositemid, util_pg.get_pointname(f.nopposite, 2) opposite, p.norder,
             NVL(editfeeders_pg.formulameas_p(p.mid), ' ') formula, t.vname vsource, f.nintegralperiod, f.rescanal, f.vnote, f.vaccount,nvl(cp.noff,-1) noff, cp.doff,
             p.mms, p.eic, p.ctype, p.status, p.point_eic, p.site_eic
    FROM     points p, feeders f, sourcetypes t,curr_power cp
    WHERE    p.PARENT = an_mid AND p.cod = 0 AND(p.ind < 3 OR p.mid IN(SELECT mid FROM feeders)) AND p.mid = f.mid(+) and p.mid = cp.mid(+) 
             AND NOT EXISTS(SELECT * FROM points WHERE PARENT = p.mid AND cod = 0 AND(ind < 3 OR mid IN(SELECT mid FROM feeders))) AND p.ptype = t.ptype(+) 
    ORDER BY norder, 6, 4;
  END IF;
 END;
-----------------------------------------------------------------------------------------------------------------------
 PROCEDURE readcounter_p(an_mid NUMBER, acur_t OUT common_pg.tcur) IS
 BEGIN
  OPEN acur_t FOR
   SELECT   p.mid, m.ID, m.NAME, m.mtrsn, m.entype, TO_CHAR(NVL(m.date_time, SYSDATE), 'dd.mm.yyyy') date_count, m.digits, m.mtype, m.mcurrent, m.mpower,
            m.mconst, m.mclass, m.myear, m.mquarter, m.POSITION, p.norder
   FROM     meters m, points p
   WHERE    m.mid = p.mid AND p.PARENT = an_mid
   ORDER BY norder, DECODE(p.ind, 1, 1, 2, 1, 3), p.NAME, m.NAME, m.entype;
 END;

---------------------------------------------------------------------------------------------------------------
 PROCEDURE readlossts_p(an_mid NUMBER, acur_t OUT common_pg.tcur) IS
 BEGIN
  OPEN acur_t FOR
   SELECT   1 nsobst, c.nconnectionparam, c.mid, c.vname, c.nsn, c.nsh, c.ndeltapidling, c.ndeltapsc, c.niidling, c.nusc, c.nro, c.nxo, c.nl, c.nun,
            c.nenergypercent, c.nworkinghours, c.nfullhours, c.nnotincludeconsump, c.nparallelconnection, c.nrenergypercent, c.nprocent,
            util_pg.get_loss_info(c.nconnectionparam, c.mid) linf, p.mid, p.NAME
   FROM     connectionparam c, points p
   WHERE    p.mid = c.mid AND p.PARENT = an_mid
   UNION ALL
   SELECT   0 nsobst, c.nconnectionparam, s.mid, c.vname, c.nsn, c.nsh, c.ndeltapidling, c.ndeltapsc, c.niidling, c.nusc, c.nro, c.nxo, c.nl, c.nun,
            c.nenergypercent, c.nworkinghours, c.nfullhours, s.nnotincludeconsump, c.nparallelconnection, c.nrenergypercent, c.nprocent,
            util_pg.get_loss_info(s.nconnectionparam, s.mid) linf, p.mid, p.NAME
   FROM     connectionparam c, sharedconnectionparam s, points p
   WHERE    s.mid = p.mid AND s.nconnectionparam = c.nconnectionparam(+) AND p.PARENT = an_mid
   ORDER BY 24, 1 DESC, 4, 2;
 END;

---------------------------------------------------------------------------------------------------------------
 PROCEDURE readgroup_p(an_mid NUMBER, acur_t OUT common_pg.tcur) IS
 BEGIN
  OPEN acur_t FOR
   SELECT   c.gid, g.NAME, p.mid
   FROM     calcpointbygroup c, GROUPS g, points p
   WHERE    g.gid = c.gid AND p.mid = c.mid(+) AND p.PARENT = an_mid
   ORDER BY 3;
 END;

---------------------------------------------------------------------------------------------------------------------
 PROCEDURE smart_p(an_mid NUMBER, av_sm OUT VARCHAR2) IS
 BEGIN
  SELECT MAX(smart) sm
  INTO   av_sm
  FROM   meters
  WHERE  mid = an_mid AND ROWNUM = 1;
 END;

---------------------------------------------------------------------------------------
 PROCEDURE get_submenu_p(an_fid NUMBER, an_monitor NUMBER, an_gid NUMBER, acur_t OUT common_pg.tcur) IS
  lv_sub              VARCHAR2(100);
  lv_sql              VARCHAR2(1000);
 BEGIN
  IF an_fid <> 0 THEN
   lv_sub := ' PARENT = :par1 ';
  ELSE
   lv_sub := ' PARENT IS NULL ';
  END IF;

  lv_sql :=
      ' SELECT DISTINCT DECODE (f.codetemplate, NULL, 1, 0) CHILD, f.fid,
                f.codetemplate, f.nameform, f.commentform, f.enablecontrols,
                f.stepprofile, f.namealert, f.vprocname,:par3,f.mid
           FROM forms f
          WHERE '
   || lv_sub
   || ' AND monitor = :par2
     CONNECT BY PRIOR PARENT = fid
     START WITH SUBSTR (enablecontrols, 7, 1) = ''1'' AND
((f.CODETEMPLATE NOT IN (1200,1201,1202,1203,1206)) OR (f.CODETEMPLATE IN (1200,1201,1202,1203,1206)
 AND (f.mid IS NULL OR f.mid IN (SELECT mid FROM points CONNECT BY PRIOR parent=mid START WITH mid=:par3)) ))
 ORDER BY 1, nameform DESC ';

  IF an_fid <> 0 THEN
   OPEN acur_t FOR lv_sql USING an_gid, an_fid, an_monitor, an_gid;
  ELSE
   OPEN acur_t FOR lv_sql USING an_gid, an_monitor, an_gid;
  END IF;
 END;

-------------------------------------------------------------------------------------------------------
 PROCEDURE get_acc(an_role_id NUMBER, acur_t OUT common_pg.tcur) IS
 BEGIN
  OPEN acur_t FOR    'SELECT r.task_id, r.nacc,t.task_cod
                FROM role_task r,tasks t
               WHERE r.role_id = '
                  || an_role_id
                  || '
               and r.task_id=t.task_id
               and t.task_cod in (608,603)';
 END;

--------------------------------------------------------------------------------------------------------
 PROCEDURE nmainpoint_p(an_mid NUMBER, acur_t OUT common_pg.tcur) IS
 BEGIN
  OPEN acur_t FOR
   SELECT mid, util_pg.get_pointname(mid, 1) NAME
   FROM   feeders
   WHERE  nmainpoint = an_mid;
 END;

-------------------------------------------------------------------------------------------------------------
 PROCEDURE nopposite_p(an_mid NUMBER, acur_t OUT common_pg.tcur) IS
 BEGIN
  OPEN acur_t FOR
   SELECT mid, util_pg.get_pointname(mid, 1) NAME
   FROM   feeders
   WHERE  nopposite = an_mid;
 END;

--------------------------------------------------------------------------------------------------------------
--возвращает измерения и их глобальные индексы для конкретной точки
--Виленская Н.Б. 14.11.2008
 PROCEDURE get_measure(an_mid NUMBER, an_objtype NUMBER, acur_t OUT common_pg.tcur) IS
 BEGIN
  OPEN acur_t FOR
   SELECT   s.vname, m.mrid, s.nmeasure, an_mid mid
   FROM     mrids m, measures s
   WHERE    s.nmeasure = m.nmeasure(+) AND an_mid = m.mid(+) AND s.nmrid = 1
   ORDER BY 3;
 END;

-----------------------------------------------------------------------------------------------------------------------
--Сохранение глобальных индексов
 PROCEDURE ins_guid(an_mid NUMBER, an_nmeasure common_pg.tt_number, an_mrid common_pg.tt_varchar2) IS
 BEGIN
  DELETE FROM mrids
  WHERE       mid = an_mid;

  IF an_nmeasure.COUNT > 0 THEN
   FOR i IN 1 .. an_nmeasure.COUNT - 1 LOOP
    IF (an_mrid IS NOT NULL) THEN
     INSERT INTO mrids
                 (mid, nmeasure, mrid)
     VALUES      (an_mid, an_nmeasure(i), an_mrid(i));
    END IF;
   END LOOP;
  END IF;
 END;

-----------------------------------------------------------------------------------------------------------------
 FUNCTION formulameas_p(an_mid NUMBER)
  RETURN VARCHAR2 IS
  lc_meas             common_pg.tcur;
  lv_nmeas            VARCHAR2(100) DEFAULT ' ';
  lv_row              VARCHAR2(100) DEFAULT ' ';
 BEGIN
  OPEN lc_meas FOR
   SELECT DECODE(a.nmeas, 0, 'Общая', 1, 'A+', 2, 'A-', 3, 'R+', 5, 'R-', ' ')
   INTO   lv_nmeas
   FROM   pointformula a
   WHERE  a.mid = an_mid;

  LOOP
   FETCH lc_meas
   INTO  lv_row;

   EXIT WHEN lc_meas%NOTFOUND;

   IF lc_meas%ROWCOUNT = 1 THEN
    lv_nmeas := lv_row;
   ELSE
    lv_nmeas := lv_nmeas || '; ' || lv_row;
   END IF;
  END LOOP;

  CLOSE lc_meas;

  RETURN lv_nmeas;
 END;

-------------------------------------------------------------------------------------------------
 -- added by KAG 27.01.2010
 -- список базовых периодов интеграции
 PROCEDURE integratortimes_p(acur_t OUT common_pg.tcur) IS
 BEGIN
  OPEN acur_t FOR
   SELECT 1 nintegralperiod
   FROM   DUAL
   UNION ALL
   SELECT 2 nintegralperiod
   FROM   DUAL
   UNION ALL
   SELECT 3 nintegralperiod
   FROM   DUAL
   UNION ALL
   SELECT 5 nintegralperiod
   FROM   DUAL
   UNION ALL
   SELECT 10 nintegralperiod
   FROM   DUAL
   UNION ALL
   SELECT 15 nintegralperiod
   FROM   DUAL
   UNION ALL
   SELECT 30 nintegralperiod
   FROM   DUAL
   UNION ALL
   SELECT 60 nintegralperiod
   FROM   DUAL;
 END;

-------------------------------------------------------------------------------------------------
 PROCEDURE get_metertypedict(acur_t OUT common_pg.tcur) IS
 BEGIN
  OPEN acur_t FOR
   SELECT   *
   FROM     metertypedict
   ORDER BY vname;
 END;

-------------------------------------------------------------------------------------------------
 PROCEDURE upd_metertypedict(an_mtype NUMBER, av_vname VARCHAR2, an_digits NUMBER, an_mcurrent NUMBER, an_mpower NUMBER, an_mconst NUMBER, an_mclass NUMBER) IS
 BEGIN
  UPDATE metertypedict
  SET vname = av_vname,
      digits = an_digits,
      mcurrent = an_mcurrent,
      mpower = an_mpower,
      mconst = an_mconst,
      mclass = an_mclass
  WHERE  nmetertype = an_mtype;
 END;

-------------------------------------------------------------------------------------------------
 PROCEDURE ins_metertypedict(an_mtype OUT NUMBER, av_vname VARCHAR2, an_digits NUMBER, an_mcurrent NUMBER, an_mpower NUMBER, an_mconst NUMBER, an_mclass NUMBER) IS
  t_mtype             NUMBER;
 BEGIN
  SELECT dict_seq.NEXTVAL
  INTO   t_mtype
  FROM   DUAL;

  an_mtype := t_mtype;

  INSERT INTO metertypedict
              (nmetertype, vname, digits, mcurrent, mpower, mconst, mclass)
  VALUES      (t_mtype, av_vname, an_digits, an_mcurrent, an_mpower, an_mconst, an_mclass);
 EXCEPTION
  WHEN OTHERS THEN
   ROLLBACK;
   raise_application_error(-20000, 'EDITFEEDERS_PG.ins_metertypedict: Ошибка сохранения.' || CHR(10) || SQLERRM(SQLCODE));
 END;

-------------------------------------------------------------------------------------------------
 PROCEDURE del_metertypedict(an_mtype NUMBER) IS
 BEGIN
  DELETE FROM metertypedict
  WHERE       nmetertype = an_mtype;
 END;

---------------------------------------------------------------------------------------------------
 PROCEDURE upd_green IS
  i                   NUMBER := 0;
 BEGIN
  FOR lc1 IN (SELECT p.mid
              FROM   points p, feeders f
              WHERE  p.mid = f.mid AND NVL(p.ind, 0) = 4 AND NVL(f.ncalcpointtype, 0) <> 6 AND NVL(f.ncalcpointtype, 0) <> 4
              MINUS
              SELECT mid
              FROM   greenpoint
              WHERE  ntype = 1) LOOP
   i := i + 1;

   INSERT INTO greenpoint
               (mid, norder, ntype)
   VALUES      (lc1.mid, 1, 1);
  END LOOP;

  FOR lc IN (SELECT mid
             FROM   greenpoint
             WHERE  ntype = 1
             INTERSECT
             SELECT mid
             FROM   feeders f
             WHERE  f.ncalcpointtype = 6) LOOP
   i := i + 1;

   DELETE FROM greenpoint
   WHERE       mid = lc.mid AND ntype = 1;
  END LOOP;

  FOR lc2 IN (SELECT f.mid
              FROM   feeders f
              WHERE  NVL(f.ncalcpointtype, 0) = 4
              MINUS
              SELECT mid
              FROM   greenpoint
              WHERE  ntype = 2) LOOP
   i := i + 1;

   INSERT INTO greenpoint
               (mid, norder, ntype)
   VALUES      (lc2.mid, 1, 2);
  END LOOP;

  FOR lc3 IN (SELECT mid
              FROM   greenpoint
              WHERE  ntype = 2
              MINUS
              SELECT f.mid
              FROM   feeders f
              WHERE  NVL(f.ncalcpointtype, 0) = 4) LOOP
   i := i + 1;

   DELETE FROM greenpoint
   WHERE       mid = lc3.mid AND ntype = 2;
  END LOOP;

  COMMIT;

  IF i <> 0 THEN
   orderformula_pg.order_formula;
  END IF;
 END;

----------------------------------------------------------------------------------------------------
--возвращает кол импульсов на квт-ч
 FUNCTION get_mconst(an_mid NUMBER, an_entype NUMBER DEFAULT 7)
  RETURN NUMBER IS
  ln_ret              NUMBER;
 BEGIN
  FOR lc IN (SELECT   NVL(DECODE(mconst, 0, 1, mconst), 1) mconst
             FROM     meters
             WHERE    mid = an_mid AND entype(+) = an_entype
             ORDER BY entype) LOOP
   RETURN lc.mconst;
  END LOOP;

  RETURN 1;
 END;

---------------------------------------------------------------------------------------------------------------------
 PROCEDURE clon_formulas(an_smid NUMBER, an_fmid NUMBER) IS
--an_smid с чего копируем an_fmid на что копируем верхние папки
  ln_cnt              NUMBER;
  ex_notclon          EXCEPTION;
  ln_id               NUMBER;
 BEGIN
  SELECT COUNT(*)
  INTO   ln_cnt
  FROM   ((SELECT     LEVEL, NAME
           FROM       points
           WHERE      cod = 0 AND(ind < 3 OR mid IN(SELECT mid
                                                    FROM   feeders))
           CONNECT BY PRIOR mid = PARENT
           START WITH PARENT = an_fmid
           MINUS
           SELECT     LEVEL, NAME
           FROM       points
           WHERE      cod = 0 AND(ind < 3 OR mid IN(SELECT mid
                                                    FROM   feeders))
           CONNECT BY PRIOR mid = PARENT
           START WITH PARENT = an_smid)
          UNION ALL
          (SELECT     LEVEL, NAME
           FROM       points
           WHERE      cod = 0 AND(ind < 3 OR mid IN(SELECT mid
                                                    FROM   feeders))
           CONNECT BY PRIOR mid = PARENT
           START WITH PARENT = an_smid
           MINUS
           SELECT     LEVEL, NAME
           FROM       points
           WHERE      cod = 0 AND(ind < 3 OR mid IN(SELECT mid
                                                    FROM   feeders))
           CONNECT BY PRIOR mid = PARENT
           START WITH PARENT = an_fmid));

  IF ln_cnt > 0 THEN
   RAISE ex_notclon;
  END IF;

  FOR lc IN (SELECT p1.mid smid, p2.mid fmid, pf.nid
             FROM   (SELECT     pn2.mid, LEVEL lv, pn2.NAME, (SELECT NAME
                                                              FROM   points
                                                              WHERE  mid = pn2.PARENT) pn2name, PARENT
                     FROM       points pn2
                     WHERE      pn2.cod = 0 AND(pn2.ind < 3 OR pn2.mid IN(SELECT mid
                                                                          FROM   feeders))
                     CONNECT BY PRIOR pn2.mid = pn2.PARENT
                     START WITH pn2.PARENT = an_smid) p1,
                    (SELECT     pn1.mid, LEVEL lv, pn1.NAME, (SELECT NAME
                                                              FROM   points
                                                              WHERE  mid = pn1.PARENT) pn1name, PARENT
                     FROM       points pn1
                     WHERE      pn1.cod = 0 AND(pn1.ind < 3 OR pn1.mid IN(SELECT mid
                                                                          FROM   feeders))
                     CONNECT BY PRIOR pn1.mid = pn1.PARENT
                     START WITH pn1.PARENT = an_fmid) p2,
                    pointformula pf
             WHERE  p1.lv = p2.lv AND p1.NAME = p2.NAME AND p1.mid = pf.mid AND(p2.pn1name = p1.pn2name OR(p1.PARENT = an_smid AND p2.PARENT = an_fmid))) LOOP
   SELECT points_seq.NEXTVAL
   INTO   ln_id
   FROM   DUAL;

   INSERT INTO pointformula
               (nid, mid, nmeas, vformula, vmemo, nopttype, nhoureriod, ndivtype)
    SELECT ln_id, lc.fmid, a.nmeas, a.vformula, a.vmemo, a.nopttype, a.nhoureriod, a.ndivtype
    FROM   pointformula a
    WHERE  nid = lc.nid;

   FOR lc1 IN (SELECT norder, vname,
                      SUBSTR(vparam, 1, INSTR(vparam, '.')) || p2.mid || SUBSTR(vparam, INSTR(vparam, '.', INSTR(vparam, '.') + 1), LENGTH(vparam)) vparam,
                      vmemo, nsign, nshift, p2.mid
               FROM   formulparams fp,
                      (SELECT     pn2.mid, LEVEL lv, pn2.NAME, (SELECT NAME
                                                                FROM   points
                                                                WHERE  mid = pn2.PARENT) pn2name, PARENT
                       FROM       points pn2
                       WHERE      pn2.cod = 0 AND(pn2.ind < 3 OR pn2.mid IN(SELECT mid
                                                                            FROM   feeders))
                       CONNECT BY PRIOR pn2.mid = pn2.PARENT
                       START WITH pn2.PARENT = an_smid) p1,
                      (SELECT     pn1.mid, LEVEL lv, pn1.NAME, (SELECT NAME
                                                                FROM   points
                                                                WHERE  mid = pn1.PARENT) pn1name, PARENT
                       FROM       points pn1
                       WHERE      pn1.cod = 0 AND(pn1.ind < 3 OR pn1.mid IN(SELECT mid
                                                                            FROM   feeders))
                       CONNECT BY PRIOR pn1.mid = pn1.PARENT
                       START WITH pn1.PARENT = an_fmid) p2
               WHERE  fp.nid = lc.nid AND fp.mid IN(SELECT     p3.mid
                                                    FROM       points p3
                                                    WHERE      cod = 0 AND(ind < 3 OR mid IN(SELECT mid
                                                                                             FROM   feeders))
                                                    CONNECT BY PRIOR p3.mid = p3.PARENT
                                                    START WITH p3.PARENT = an_smid) AND p1.lv = p2.lv AND p1.NAME = p2.NAME
                      AND(p2.pn1name = p1.pn2name OR(p1.PARENT = an_smid AND p2.PARENT = an_fmid)) AND p1.mid = fp.mid
               UNION ALL
               SELECT norder, vname, vparam, vmemo, nsign, nshift, mid
               FROM   formulparams fp1
               WHERE  fp1.nid = lc.nid AND fp1.mid NOT IN(SELECT     p4.mid
                                                          FROM       points p4
                                                          WHERE      cod = 0 AND(ind < 3 OR mid IN(SELECT mid
                                                                                                   FROM   feeders))
                                                          CONNECT BY PRIOR p4.mid = p4.PARENT
                                                          START WITH p4.PARENT = an_smid)) LOOP
    INSERT INTO formulparams
                (nid, norder, vname, vparam, vmemo, nshift, mid)
    VALUES      (ln_id, lc1.norder, lc1.vname, lc1.vparam, lc1.vmemo, lc1.nshift, lc1.mid);
   END LOOP;
  END LOOP;

  editformula_pg.order_formula;
  COMMIT;
 EXCEPTION
  WHEN ex_notclon THEN
   raise_application_error(-20000, 'EDITFEEDERS_PG.clone_formulas: Несоответствие клонируемых папок.' || CHR(10) || SQLERRM(SQLCODE));
  WHEN OTHERS THEN
   ROLLBACK;
   raise_application_error(-20000, 'EDITFEEDERS_PG.clone_formulas: Ошибка сохранения.' || CHR(10) || SQLERRM(SQLCODE));
 END;

------------------------------------------------------------------------------------------------------------------
--Посылка команды на отключение включение питания
 PROCEDURE set_command_off(an_mid NUMBER, an_cmd NUMBER) IS
  lv_cmd              VARCHAR2(256) := 'Выдана команда ';
 BEGIN
  adminadd_pg.check_right(an_mid, NULL, 1, 1);
  ins_last_save(an_mid);

  UPDATE last_save
  SET dcmdoff = SYSDATE,
      ncmdoff = decode(an_cmd,1,1,2,2,0),
      dexecmdoff = NULL
  WHERE  mid = an_mid;

  IF an_cmd = 1 THEN
   lv_cmd := lv_cmd || 'Отключить нагрузку';
  ELSIF an_cmd = 2 THEN
   lv_cmd := lv_cmd || 'Включить нагрузку';
  ELSE
   lv_cmd := lv_cmd || 'Отмена';
  END IF;

  admin_pg.fiscal_p(gn_task_command_off, 1, lv_cmd || ' для точки ' || util_pg.node_path_f(an_mid, 'points', 'mid', 'parent'));
  COMMIT;
 EXCEPTION
  WHEN OTHERS THEN
   ROLLBACK;
   raise_application_error(-20001, 'editfeeders_pg.set_command_off: Ошибка выдачи команды счетчику. ' || CHR(10) || SQLERRM(SQLCODE));
 END;
------------------------------------------------------------------------------------------------------------------
END editfeeders_pg;
/