CREATE OR REPLACE PROCEDURE RYDA.P_AUTO_REPLACE_HOLES (
    p_mid IN NUMBER,
    p_target_date IN DATE,
    p_analog_date IN DATE,
    p_min_holes IN NUMBER,
    p_max_holes IN NUMBER,
    p_out_msg OUT VARCHAR2,
    p_inserted_cnt OUT NUMBER 
) AS
    v_holes RYDA.common_pg.tt_number;
    v_count NUMBER;
    v_er NUMBER; v_ed NUMBER; v_q1 NUMBER; v_q2 NUMBER; v_q3 NUMBER; v_q4 NUMBER;
    v_vqm VARCHAR2(32);
    v_target_time DATE;
    v_analog_time DATE;
    v_success_cnt NUMBER := 0;
    v_status NUMBER;
    
    -- Змінні для перевірки існуючих даних
    v_tar_nsource NUMBER;
    v_tar_exists NUMBER;
BEGIN
    p_inserted_cnt := 0; 

    BEGIN
        SELECT NVL(status, 1) INTO v_status FROM RYDA.points WHERE mid = p_mid;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_status := 0;
    END;

    IF v_status = 0 THEN
        p_out_msg := 'Пропущено. Точка відключена (Status=0).';
        RETURN;
    END IF;

    v_holes := RYDA.das_pg.getholeinhalfhour(p_target_date, p_mid, 1, NULL);
    v_count := v_holes.COUNT;

    IF v_count < p_min_holes OR v_count > p_max_holes THEN
        p_out_msg := 'Пропущено (' || v_count || ' дірок).';
        RETURN;
    END IF;

    v_vqm := RYDA.qm_pg.cv_defqm;
    v_vqm := RYDA.qm_pg.sbt(v_vqm, 1, RYDA.qm_pg.cn_ok);
    v_vqm := RYDA.qm_pg.sbt(v_vqm, 10, RYDA.qm_pg.cn_subst);
    v_vqm := RYDA.qm_pg.sbt(v_vqm, 20, RYDA.qm_pg.cn_add_ok);
    v_vqm := RYDA.qm_pg.sbt(v_vqm, 22, RYDA.qm_pg.cn_calcr);

    FOR i IN 1..v_count LOOP
        v_target_time := TRUNC(p_target_date) + v_holes(i) / 48;
        v_analog_time := TRUNC(p_analog_date) + v_holes(i) / 48;

        BEGIN
            -- Беремо для аналога лише реальні дані (nsource <= 20)
            SELECT SUM(er), SUM(ed), SUM(q1), SUM(q2), SUM(q3), SUM(q4)
            INTO v_er, v_ed, v_q1, v_q2, v_q3, v_q4
            FROM RYDA.halfhourold
            WHERE mid = p_mid 
              AND date_time > v_analog_time - (30 / 1440) 
              AND date_time <= v_analog_time 
              AND nsource <= 20 
              AND ((er IS NOT NULL AND er >= 0) OR (ed IS NOT NULL AND ed >= 0)); 

            IF v_er IS NOT NULL OR v_ed IS NOT NULL THEN
                
                -- ПЕРЕВІРЯЄМО ЦІЛЬОВУ ПІВГОДИНУ
                v_tar_exists := 0;
                BEGIN
                    SELECT NVL(nsource, 0) INTO v_tar_nsource 
                    FROM RYDA.halfhourold 
                    WHERE mid = p_mid AND date_time = v_target_time;
                    v_tar_exists := 1;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        v_tar_exists := 0;
                END;

                -- ЗАПИСУЄМО ЛИШЕ ЯКЩО ПУСТО АБО ЦЕ НАШЕ МИНУЛЕ АВТОЗАМІЩЕННЯ (23)
                IF v_tar_exists = 0 THEN
                    INSERT INTO RYDA.halfhourold (mid, date_time, er, ed, q1, q2, q3, q4, status, nsource, vqm)
                    VALUES (p_mid, v_target_time, NVL(v_er, 0), NVL(v_ed, 0), NVL(v_q1, 0), NVL(v_q2, 0), NVL(v_q3, 0), NVL(v_q4, 0), 0, 23, v_vqm);
                    v_success_cnt := v_success_cnt + 1;
                ELSIF v_tar_nsource = 23 THEN
                    UPDATE RYDA.halfhourold 
                    SET er = NVL(v_er, 0), ed = NVL(v_ed, 0), q1 = NVL(v_q1, 0), q2 = NVL(v_q2, 0), q3 = NVL(v_q3, 0), q4 = NVL(v_q4, 0), status = 0, vqm = v_vqm
                    WHERE mid = p_mid AND date_time = v_target_time;
                    v_success_cnt := v_success_cnt + 1;
                END IF;
                
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                NULL; 
        END;
    END LOOP;

    p_inserted_cnt := v_success_cnt; 

    IF v_success_cnt > 0 THEN
        RYDA.admin_pg.fiscal_p(200, 1, 'Автозаміщення (Універсальне 15/30хв). ТУ: ' || p_mid || ' (' || v_success_cnt || ' напівгод.)');
        p_out_msg := 'Заміщено ' || v_success_cnt || ' напівгодин.';
    ELSE
        p_out_msg := 'Немає валідних даних в дні-аналогу або існуючі дані захищено.';
    END IF;
END;
-- Не забуваємо дати права
GRANT EXECUTE ON RYDA.P_AUTO_REPLACE_HOLES TO PUBLIC;
/