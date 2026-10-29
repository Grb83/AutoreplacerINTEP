--------------------------------------------------------------------------------
-- Скрипт створення процедури імпорту EIC-кодів за номером лічильника
-- Файл: 05_P_IMPORT_EIC_BY_METER.sql
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE ryda.p_import_eic_by_meter (
    p_mtrsn       IN VARCHAR2,
    p_site_eic    IN VARCHAR2,
    p_point_eic   IN VARCHAR2,
    p_overwrite   IN NUMBER,
    p_out_msg     OUT VARCHAR2
) AS
    v_mid       NUMBER;
    v_cnt       NUMBER;
    v_cur_site  VARCHAR2(256);
    v_cur_point VARCHAR2(256);
    v_upd_site  VARCHAR2(256);
    v_upd_point VARCHAR2(256);
    v_skipped   NUMBER := 0;
BEGIN
    IF TRIM(p_mtrsn) IS NULL THEN
        p_out_msg := 'Помилка: Порожній номер лічильника.';
        RETURN;
    END IF;

    SELECT COUNT(DISTINCT mid) INTO v_cnt FROM ryda.meters WHERE UPPER(TRIM(mtrsn)) = UPPER(TRIM(p_mtrsn));

    IF v_cnt = 0 THEN
        p_out_msg := 'Помилка: Лічильник № ' || p_mtrsn || ' не знайдено.';
        RETURN;
    ELSIF v_cnt > 1 THEN
        p_out_msg := 'Помилка: Знайдено декілька точок з лічильником № ' || p_mtrsn || '.';
        RETURN;
    END IF;

    SELECT MAX(mid) INTO v_mid FROM ryda.meters WHERE UPPER(TRIM(mtrsn)) = UPPER(TRIM(p_mtrsn));

    SELECT site_eic, point_eic INTO v_cur_site, v_cur_point FROM ryda.points WHERE mid = v_mid;

    v_upd_site := v_cur_site;
    v_upd_point := v_cur_point;

    IF TRIM(p_site_eic) IS NOT NULL THEN
        IF v_cur_site IS NULL OR p_overwrite = 1 THEN
            v_upd_site := TRIM(p_site_eic);
        ELSE
            v_skipped := 1;
        END IF;
    END IF;

    IF TRIM(p_point_eic) IS NOT NULL THEN
        IF v_cur_point IS NULL OR p_overwrite = 1 THEN
            v_upd_point := TRIM(p_point_eic);
        ELSE
            v_skipped := 1;
        END IF;
    END IF;

    -- Якщо дані реально змінилися (відрізняються від БД)
    IF NVL(v_upd_site, ' ') != NVL(v_cur_site, ' ') OR NVL(v_upd_point, ' ') != NVL(v_cur_point, ' ') THEN
        UPDATE ryda.points 
        SET site_eic = v_upd_site, point_eic = v_upd_point 
        WHERE mid = v_mid;

        IF v_skipped = 1 THEN
            p_out_msg := 'Успіх: Оновлено частково (існуючі збережено) (mid=' || v_mid || ').';
        ELSE
            p_out_msg := 'Успіх: EIC-коди оновлено (mid=' || v_mid || ').';
        END IF;
    ELSE
        -- Дані НЕ змінилися (в базі вже лежать точно такі ж коди)
        IF p_overwrite = 1 THEN
            -- Якщо стоїть галка перезапису, але коди ідентичні, пишемо "Успіх", щоб не лякати оператора
            p_out_msg := 'Успіх: Коди ідентичні, перезаписано (mid=' || v_mid || ').';
        ELSIF v_skipped = 1 THEN
            p_out_msg := 'Пропущено: EIC-коди вже існують (mid=' || v_mid || ').';
        ELSE
            p_out_msg := 'Пропущено: Немає нових даних (mid=' || v_mid || ').';
        END IF;
    END IF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        p_out_msg := 'Критична помилка БД: ' || SQLERRM;
END;
/

GRANT EXECUTE ON ryda.p_import_eic_by_meter TO PUBLIC;