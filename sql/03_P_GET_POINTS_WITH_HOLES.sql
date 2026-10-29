CREATE OR REPLACE PROCEDURE ryda.p_get_points_with_holes (
    p_start_date IN DATE,
    p_end_date   IN DATE,
    p_cursor     OUT SYS_REFCURSOR
) AS
    v_expected_cnt NUMBER;
BEGIN
    -- Рахуємо, скільки півгодин має бути за цей період
    v_expected_cnt := (TRUNC(p_end_date) - TRUNC(p_start_date) + 1) * 48;

    OPEN p_cursor FOR
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
          -- ФІЛЬТР: шукаємо точки, у яких бракує записів у halfhourold
          AND (
              SELECT COUNT(*) 
              FROM ryda.halfhourold h 
              WHERE h.mid = p.mid 
                AND h.date_time > TRUNC(p_start_date) 
                AND h.date_time <= (TRUNC(p_end_date) + 1)
          ) < v_expected_cnt
        ORDER BY consumer_name, point_name;
END;
/

-- Не забуваємо дати права
GRANT EXECUTE ON ryda.p_get_points_with_holes TO PUBLIC;