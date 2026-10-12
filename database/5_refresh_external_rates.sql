CREATE OR REPLACE PROCEDURE refresh_external_rates
IS
    l_response         CLOB;
    l_rate             NUMBER;
    l_rate_date        DATE;
    l_product_id       NUMBER;
    l_current_rate     NUMBER;

BEGIN

    --------------------------------------------------
    -- Get 15-year and 30-year FRED mortgage rates
    --------------------------------------------------

    FOR r IN (
        SELECT
            'MORTGAGE15US' AS series_id,
            15             AS term_years
        FROM dual

        UNION ALL

        SELECT
            'MORTGAGE30US',
            30
        FROM dual
    )
    LOOP

        --------------------------------------------------
        -- Call FRED
        --------------------------------------------------

        l_response :=
            apex_web_service.make_rest_request(
                p_url =>
                    'https://api.stlouisfed.org/fred/series/observations'
                    || '?series_id=' || r.series_id
                    || '&file_type=json'
                    || '&sort_order=desc'
                    || '&limit=1',

                p_http_method         => 'GET',
                p_credential_static_id => 'FRED_API_KEY'
            );


        --------------------------------------------------
        -- Check response
        --------------------------------------------------

        IF apex_web_service.g_status_code NOT BETWEEN 200 AND 299 THEN
            raise_application_error(
                -20001,
                'FRED API error: HTTP '
                || apex_web_service.g_status_code
            );
        END IF;


        --------------------------------------------------
        -- Read rate
        --------------------------------------------------

        l_rate :=
            TO_NUMBER(
                JSON_VALUE(
                    l_response,
                    '$.observations[0].value'
                ),
                '999999D9999',
                'NLS_NUMERIC_CHARACTERS=''.,'''
            );


        --------------------------------------------------
        -- Read date supplied by FRED
        --------------------------------------------------

        l_rate_date :=
            TO_DATE(
                JSON_VALUE(
                    l_response,
                    '$.observations[0].date'
                ),
                'YYYY-MM-DD'
            );


        --------------------------------------------------
        -- Find MortgageFlow product
        --------------------------------------------------

        SELECT loan_product_id
        INTO l_product_id
        FROM loan_products
        WHERE term_years = r.term_years
          AND active_yn = 'Y'
        FETCH FIRST 1 ROW ONLY;


        --------------------------------------------------
        -- Find current rate
        --------------------------------------------------

        BEGIN

            SELECT interest_rate
            INTO l_current_rate
            FROM interest_rates
            WHERE loan_product_id = l_product_id
              AND active_yn = 'Y'
            ORDER BY effective_from DESC
            FETCH FIRST 1 ROW ONLY;

        EXCEPTION

            WHEN NO_DATA_FOUND THEN
                l_current_rate := NULL;

        END;


        --------------------------------------------------
        -- Insert only when rate changed
        --------------------------------------------------

        IF l_current_rate IS NULL
           OR l_current_rate <> l_rate
        THEN

            UPDATE interest_rates
            SET
                active_yn = 'N',
                effective_to = SYSDATE
            WHERE loan_product_id = l_product_id
              AND active_yn = 'Y';


            INSERT INTO interest_rates (
                loan_product_id,
                interest_rate,
                effective_from,
                effective_to,
                active_yn
            )
            VALUES (
                l_product_id,
                l_rate,
                l_rate_date,
                NULL,
                'Y'
            );

        END IF;

    END LOOP;


    COMMIT;

END refresh_external_rates;
/