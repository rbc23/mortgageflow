-------------------------------------------------------------------------------------------------
-- 1. Loan Products
-------------------------------------------------------------------------------------------------

BEGIN
    INSERT INTO loan_products
                (product_name,
                 description,
                 term_years,
                 min_interest_rate,
                 max_interest_rate,
                 active_yn)
    VALUES      ( '15-Year Fixed',
    'Shorter mortgage term with faster equity growth and lower total interest.',
    15,
    4.0000,
    8.0000,
    'Y' );

    INSERT INTO loan_products
                (product_name,
                 description,
                 term_years,
                 min_interest_rate,
                 max_interest_rate,
                 active_yn)
    VALUES      ( '20-Year Fixed',
				'Balanced mortgage product combining moderate monthly payments and interest savings.'
							  ,
				20,
				4.2500,
				8.5000,
				'Y' );

    INSERT INTO loan_products
                (product_name,
                 description,
                 term_years,
                 min_interest_rate,
                 max_interest_rate,
                 active_yn)
    VALUES      ( '30-Year Fixed',
	'Long-term fixed mortgage designed for lower monthly payments and payment stability.'
				  ,
	30,
	4.5000,
	9.0000,
	'Y' );
END; 

-------------------------------------------------------------------------------------------------
-- 2. Interest Rate History
-------------------------------------------------------------------------------------------------
BEGIN
	INSERT INTO interest_rates
				(loan_product_id,
				 interest_rate,
				 effective_from,
				 effective_to,
				 active_yn)
	SELECT loan_product_id,
		   5.5000,
		   date '2026-07-01',
		   date '2026-07-31',
		   'N'
	FROM   loan_products
	WHERE  product_name = '15-Year Fixed';

	INSERT INTO interest_rates
				(loan_product_id,
				 interest_rate,
				 effective_from,
				 effective_to,
				 active_yn)
	SELECT loan_product_id,
		   5.7000,
		   date '2026-08-01',
		   date '2026-09-30',
		   'N'
	FROM   loan_products
	WHERE  product_name = '15-Year Fixed';

	INSERT INTO interest_rates
				(loan_product_id,
				 interest_rate,
				 effective_from,
				 effective_to,
				 active_yn)
	SELECT loan_product_id,
		   5.8750,
		   date '2026-10-01',
		   NULL,
		   'Y'
	FROM   loan_products
	WHERE  product_name = '15-Year Fixed';

	INSERT INTO interest_rates
				(loan_product_id,
				 interest_rate,
				 effective_from,
				 effective_to,
				 active_yn)
	SELECT loan_product_id,
		   5.8750,
		   date '2026-07-01',
		   date '2026-07-31',
		   'N'
	FROM   loan_products
	WHERE  product_name = '20-Year Fixed';

	INSERT INTO interest_rates
				(loan_product_id,
				 interest_rate,
				 effective_from,
				 effective_to,
				 active_yn)
	SELECT loan_product_id,
		   6.0000,
		   date '2026-08-01',
		   date '2026-09-30',
		   'N'
	FROM   loan_products
	WHERE  product_name = '20-Year Fixed';

	INSERT INTO interest_rates
				(loan_product_id,
				 interest_rate,
				 effective_from,
				 effective_to,
				 active_yn)
	SELECT loan_product_id,
		   6.1250,
		   date '2026-10-01',
		   NULL,
		   'Y'
	FROM   loan_products
	WHERE  product_name = '20-Year Fixed';

	INSERT INTO interest_rates
				(loan_product_id,
				 interest_rate,
				 effective_from,
				 effective_to,
				 active_yn)
	SELECT loan_product_id,
		   6.1250,
		   date '2026-07-01',
		   date '2026-07-31',
		   'N'
	FROM   loan_products
	WHERE  product_name = '30-Year Fixed';

	INSERT INTO interest_rates
				(loan_product_id,
				 interest_rate,
				 effective_from,
				 effective_to,
				 active_yn)
	SELECT loan_product_id,
		   6.3750,
		   date '2026-08-01',
		   date '2026-09-30',
		   'N'
	FROM   loan_products
	WHERE  product_name = '30-Year Fixed';

	INSERT INTO interest_rates
				(loan_product_id,
				 interest_rate,
				 effective_from,
				 effective_to,
				 active_yn)
	SELECT loan_product_id,
		   6.5000,
		   date '2026-10-01',
		   NULL,
		   'Y'
	FROM   loan_products
	WHERE  product_name = '30-Year Fixed';

END;


-------------------------------------------------------------------------------------------------
-- 3. Generate 284 Users
-------------------------------------------------------------------------------------------------


DECLARE
    l_hash VARCHAR2(255);
BEGIN
    --------------------------------------------------------
    -- GENERATE DEMO PASSWORD HASH
    --------------------------------------------------------
    SELECT Rawtohex(Standard_hash('DemoPass123!', 'SHA256'))
    INTO   l_hash
    FROM   dual;

    --------------------------------------------------------
    -- MAIN DEMO APPLICANT
    --------------------------------------------------------
    INSERT INTO app_users
                (username,
                 email,
                 full_name,
                 password_hash,
                 ROLE,
                 active_yn)
    VALUES      ( 'john.doe',
                 'john.doe@example.com',
                 'John Doe',
                 l_hash,
                 'APPLICANT',
                 'Y' );

    --------------------------------------------------------
    -- OTHER APPLICANTS
    --------------------------------------------------------
    FOR i IN 1 .. 268 LOOP
        INSERT INTO app_users
                    (username,
                     email,
                     full_name,
                     password_hash,
                     ROLE,
                     active_yn)
        VALUES      ( 'applicant'
                     || Lpad(i, 3, '0'),
                     'applicant'
                     || Lpad(i, 3, '0')
                     || '@example.com',
                     'Applicant '
                     || Lpad(i, 3, '0'),
                     l_hash,
                     'APPLICANT',
                     CASE
                       WHEN i > 250 THEN 'N'
                       ELSE 'Y'
                     END );
    END LOOP;

    --------------------------------------------------------
    -- MAIN LOAN OFFICER
    --------------------------------------------------------
    INSERT INTO app_users
                (username,
                 email,
                 full_name,
                 password_hash,
                 ROLE,
                 active_yn)
    VALUES      ( 'sarah.lopez',
                 'sarah.lopez@mortgageflow.com',
                 'Sarah Lopez',
                 l_hash,
                 'LOAN_OFFICER',
                 'Y' );

    --------------------------------------------------------
    -- OTHER LOAN OFFICERS
    --------------------------------------------------------
    FOR i IN 1 .. 11 LOOP
        INSERT INTO app_users
                    (username,
                     email,
                     full_name,
                     password_hash,
                     ROLE,
                     active_yn)
        VALUES      ( 'officer'
                     || Lpad(i, 2, '0'),
                     'officer'
                     || Lpad(i, 2, '0')
                     || '@mortgageflow.com',
                     'Loan Officer '
                     || Lpad(i, 2, '0'),
                     l_hash,
                     'LOAN_OFFICER',
                     'Y' );
    END LOOP;

    --------------------------------------------------------
    -- MAIN ADMIN
    --------------------------------------------------------
    INSERT INTO app_users
                (username,
                 email,
                 full_name,
                 password_hash,
                 ROLE,
                 active_yn)
    VALUES      ( 'maria.admin',
                 'maria.admin@mortgageflow.com',
                 'Maria Admin',
                 l_hash,
                 'ADMIN',
                 'Y' );

    --------------------------------------------------------
    -- OTHER ADMINS
    --------------------------------------------------------
    FOR i IN 1 .. 2 LOOP
        INSERT INTO app_users
                    (username,
                     email,
                     full_name,
                     password_hash,
                     ROLE,
                     active_yn)
        VALUES      ( 'admin'
                     || Lpad(i, 2, '0'),
                     'admin'
                     || Lpad(i, 2, '0')
                     || '@mortgageflow.com',
                     'Administrator '
                     || Lpad(i, 2, '0'),
                     l_hash,
                     'ADMIN',
                     'Y' );
    END LOOP;

    COMMIT;
END;

/ 



-------------------------------------------------------------------------------------------------
-- 4. Generate 428 Mortgage Applications
-------------------------------------------------------------------------------------------------

DECLARE
    TYPE t_number_array
      IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    l_applicants      T_NUMBER_ARRAY;
    l_officers        T_NUMBER_ARRAY;
    l_applicant_count NUMBER := 0;
    l_officer_count   NUMBER := 0;
    l_product_id      NUMBER;
    l_term            NUMBER;
    l_rate            NUMBER;
    l_property_value  NUMBER;
    l_down_payment    NUMBER;
    l_loan_amount     NUMBER;
    l_annual_income   NUMBER;
    l_monthly_debt    NUMBER;
    l_monthly_rate    NUMBER;
    l_months          NUMBER;
    l_payment         NUMBER;
    l_ltv             NUMBER;
    l_dti             NUMBER;
    l_risk            VARCHAR2(20);
    l_status          VARCHAR2(20);
    l_created_at      TIMESTAMP;
    l_submitted_at    TIMESTAMP;
    l_decided_at      TIMESTAMP;
    l_decided_by      NUMBER;
BEGIN
    --------------------------------------------------------
    -- LOAD APPLICANTS
    --------------------------------------------------------
    FOR r IN (SELECT user_id
              FROM   app_users
              WHERE  ROLE = 'APPLICANT'
                     AND active_yn = 'Y'
              ORDER  BY user_id) LOOP
        l_applicant_count := l_applicant_count + 1;

        L_applicants(l_applicant_count) := r.user_id;
    END LOOP;

    --------------------------------------------------------
    -- LOAD LOAN OFFICERS
    --------------------------------------------------------
    FOR r IN (SELECT user_id
              FROM   app_users
              WHERE  ROLE = 'LOAN_OFFICER'
                     AND active_yn = 'Y'
              ORDER  BY user_id) LOOP
        l_officer_count := l_officer_count + 1;

        L_officers(l_officer_count) := r.user_id;
    END LOOP;

    --------------------------------------------------------
    -- GENERATE 428 APPLICATIONS
    --------------------------------------------------------
    FOR i IN 1 .. 428 LOOP
        ----------------------------------------------------
        -- STATUS DISTRIBUTION
        ----------------------------------------------------
        IF i <= 46 THEN
          l_status := 'DRAFT';
        ELSIF i <= 135 THEN
          l_status := 'SUBMITTED';
        ELSIF i <= 258 THEN
          l_status := 'UNDER_REVIEW';
        ELSIF i <= 350 THEN
          l_status := 'APPROVED';
        ELSE
          l_status := 'REJECTED';
        END IF;

        ----------------------------------------------------
        -- PRODUCT
        ----------------------------------------------------
        IF MOD(i, 3) = 1 THEN
          SELECT loan_product_id
          INTO   l_product_id
          FROM   loan_products
          WHERE  product_name = '15-Year Fixed';

          l_term := 15;

          l_rate := 5.875;
        ELSIF MOD(i, 3) = 2 THEN
          SELECT loan_product_id
          INTO   l_product_id
          FROM   loan_products
          WHERE  product_name = '20-Year Fixed';

          l_term := 20;

          l_rate := 6.125;
        ELSE
          SELECT loan_product_id
          INTO   l_product_id
          FROM   loan_products
          WHERE  product_name = '30-Year Fixed';

          l_term := 30;

          l_rate := 6.500;
        END IF;

        ----------------------------------------------------
        -- PROPERTY / FINANCIAL DATA
        ----------------------------------------------------
        l_property_value := 220000 + ( MOD(i * 13750, 480000) );

        l_down_payment := Round(l_property_value * ( 0.10 + ( MOD(i, 4) * 0.05 )
                                                   ),
                          2);

        l_loan_amount := l_property_value - l_down_payment;

        l_annual_income := 65000 + MOD(i * 7250, 155000);

        l_monthly_debt := 300 + MOD(i * 175, 2200);

        ----------------------------------------------------
        -- PAYMENT
        ----------------------------------------------------
        l_monthly_rate := ( l_rate / 100 ) / 12;

        l_months := l_term * 12;

        l_payment := Round(l_loan_amount * ( l_monthly_rate *
                                             Power(1 + l_monthly_rate,
                                             l_months) ) /
                                        (
                                        Power(1 + l_monthly_rate, l_months) - 1
                                        ), 2
                     );

        ----------------------------------------------------
        -- LTV
        ----------------------------------------------------
        l_ltv := Round(( l_loan_amount / l_property_value ) * 100, 2);

        ----------------------------------------------------
        -- DTI
        ----------------------------------------------------
        l_dti := Round(( l_monthly_debt + l_payment ) / ( l_annual_income / 12 )
                       *
                       100,
                 2);

        ----------------------------------------------------
        -- RISK
        ----------------------------------------------------
        IF l_ltv > 90
            OR l_dti > 45 THEN
          l_risk := 'HIGH';
        ELSIF l_ltv > 80
               OR l_dti > 35 THEN
          l_risk := 'MEDIUM';
        ELSE
          l_risk := 'LOW';
        END IF;

        ----------------------------------------------------
        -- DATES
        ----------------------------------------------------
        l_created_at := systimestamp - Numtodsinterval(MOD(i * 3, 240), 'DAY') -
                        Numtodsinterval(MOD(i * 7, 20), 'HOUR');

        IF l_status = 'DRAFT' THEN
          l_submitted_at := NULL;
        ELSE
          l_submitted_at := l_created_at
                            + Numtodsinterval( 2 + MOD(i, 12), 'HOUR' );
        END IF;

        IF l_status IN ( 'APPROVED', 'REJECTED' ) THEN
          l_decided_at := l_submitted_at
                          + Numtodsinterval( 1 + MOD(i, 5), 'DAY' );

          l_decided_by := L_officers(MOD(i - 1, l_officer_count) + 1);
        ELSE
          l_decided_at := NULL;

          l_decided_by := NULL;
        END IF;

        ----------------------------------------------------
        -- INSERT
        ----------------------------------------------------
        INSERT INTO mortgage_applications
                    (application_number,
                     applicant_user_id,
                     loan_product_id,
                     annual_income,
                     monthly_debt,
                     property_value,
                     down_payment,
                     loan_amount,
                     interest_rate,
                     loan_term_years,
                     monthly_payment,
                     ltv,
                     dti,
                     risk_level,
                     status,
                     submitted_at,
                     decided_at,
                     decided_by,
                     created_at,
                     updated_at)
        VALUES      ( 'MF-'
                     || To_char(Extract(year FROM SYSDATE))
                     || '-'
                     || Lpad(i, 4, '0'),
                     L_applicants(MOD( i - 1, l_applicant_count ) + 1),
                     l_product_id,
                     l_annual_income,
                     l_monthly_debt,
                     l_property_value,
                     l_down_payment,
                     l_loan_amount,
                     l_rate,
                     l_term,
                     l_payment,
                     l_ltv,
                     l_dti,
                     l_risk,
                     l_status,
                     l_submitted_at,
                     l_decided_at,
                     l_decided_by,
                     l_created_at,
                     Coalesce(l_decided_at, l_submitted_at, l_created_at) );
    END LOOP;

    COMMIT;
END;

/ 


-------------------------------------------------------------------------------------------------
-- 5. Generate Status History
-------------------------------------------------------------------------------------------------

DECLARE
    l_officer_id NUMBER;
BEGIN
    SELECT user_id
    INTO   l_officer_id
    FROM   app_users
    WHERE  username = 'sarah.lopez';

    FOR r IN (SELECT application_id,
                     applicant_user_id,
                     status,
                     created_at,
                     submitted_at,
                     decided_at,
                     decided_by
              FROM   mortgage_applications) LOOP
        ----------------------------------------------------
        -- APPLICATION CREATED
        ----------------------------------------------------
        INSERT INTO application_status_history
                    (application_id,
                     old_status,
                     new_status,
                     changed_by,
                     changed_at,
                     comments)
        VALUES      ( r.application_id,
                     NULL,
                     'DRAFT',
                     r.applicant_user_id,
                     r.created_at,
                     'Mortgage application created.' );

        ----------------------------------------------------
        -- SUBMITTED
        ----------------------------------------------------
        IF r.status IN ( 'SUBMITTED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED' )
        THEN
          INSERT INTO application_status_history
                      (application_id,
                       old_status,
                       new_status,
                       changed_by,
                       changed_at,
                       comments)
          VALUES      ( r.application_id,
                       'DRAFT',
                       'SUBMITTED',
                       r.applicant_user_id,
                       r.submitted_at,
                       'Application submitted by applicant.' );
        END IF;

        ----------------------------------------------------
        -- UNDER REVIEW
        ----------------------------------------------------
        IF r.status IN ( 'UNDER_REVIEW', 'APPROVED', 'REJECTED' ) THEN
          INSERT INTO application_status_history
                      (application_id,
                       old_status,
                       new_status,
                       changed_by,
                       changed_at,
                       comments)
          VALUES      ( r.application_id,
                       'SUBMITTED',
                       'UNDER_REVIEW',
                       Coalesce(r.decided_by, l_officer_id),
                       r.submitted_at + Numtodsinterval( 4, 'HOUR' ),
                       'Loan officer started application review.' );
        END IF;

        ----------------------------------------------------
        -- APPROVED
        ----------------------------------------------------
        IF r.status = 'APPROVED' THEN
          INSERT INTO application_status_history
                      (application_id,
                       old_status,
                       new_status,
                       changed_by,
                       changed_at,
                       comments)
          VALUES      ( r.application_id,
                       'UNDER_REVIEW',
                       'APPROVED',
                       r.decided_by,
                       r.decided_at,
                       'Application approved after financial review.' );
        END IF;

        ----------------------------------------------------
        -- REJECTED
        ----------------------------------------------------
        IF r.status = 'REJECTED' THEN
          INSERT INTO application_status_history
                      (application_id,
                       old_status,
                       new_status,
                       changed_by,
                       changed_at,
                       comments)
          VALUES      ( r.application_id,
                       'UNDER_REVIEW',
                       'REJECTED',
                       r.decided_by,
                       r.decided_at,
                       'Application declined after financial review.' );
        END IF;
    END LOOP;

    COMMIT;
END;

/ 

-------------------------------------------------------------------------------------------------
-- 6. Generate Audit Log
-------------------------------------------------------------------------------------------------

DECLARE
    l_officer_id NUMBER;
BEGIN
    SELECT user_id
    INTO   l_officer_id
    FROM   app_users
    WHERE  username = 'sarah.lopez';

    FOR r IN (SELECT application_id,
                     applicant_user_id,
                     status,
                     created_at,
                     submitted_at,
                     decided_at,
                     decided_by,
                     risk_level
              FROM   mortgage_applications) LOOP
        ----------------------------------------------------
        -- CREATED
        ----------------------------------------------------
        INSERT INTO audit_log
                    (application_id,
                     user_id,
                     action_type,
                     description,
                     created_at)
        VALUES      ( r.application_id,
                     r.applicant_user_id,
                     'APPLICATION_CREATED',
                     'Mortgage application created.',
                     r.created_at );

        ----------------------------------------------------
        -- SUBMITTED
        ----------------------------------------------------
        IF r.submitted_at IS NOT NULL THEN
          INSERT INTO audit_log
                      (application_id,
                       user_id,
                       action_type,
                       description,
                       created_at)
          VALUES      ( r.application_id,
                       r.applicant_user_id,
                       'APPLICATION_SUBMITTED',
                       'Applicant submitted the mortgage application.',
                       r.submitted_at );
        END IF;

        ----------------------------------------------------
        -- REVIEW
        ----------------------------------------------------
        IF r.status IN ( 'UNDER_REVIEW', 'APPROVED', 'REJECTED' ) THEN
          INSERT INTO audit_log
                      (application_id,
                       user_id,
                       action_type,
                       description,
                       created_at)
          VALUES      ( r.application_id,
                       Coalesce(r.decided_by, l_officer_id),
                       'REVIEW_STARTED',
                       'Loan officer started reviewing the application.',
                       r.submitted_at + Numtodsinterval( 4, 'HOUR' ) );

          INSERT INTO audit_log
                      (application_id,
                       user_id,
                       action_type,
                       description,
                       created_at)
          VALUES      ( r.application_id,
                       NULL,
                       'RISK_CALCULATED',
                       'Automated risk assessment calculated. Risk level: '
                       || r.risk_level,
                       r.submitted_at + Numtodsinterval( 5, 'HOUR' ) );
        END IF;

        ----------------------------------------------------
        -- APPROVAL
        ----------------------------------------------------
        IF r.status = 'APPROVED' THEN
          INSERT INTO audit_log
                      (application_id,
                       user_id,
                       action_type,
                       description,
                       created_at)
          VALUES      ( r.application_id,
                       r.decided_by,
                       'APPLICATION_APPROVED',
                       'Loan officer approved the mortgage application.',
                       r.decided_at );
        END IF;

        ----------------------------------------------------
        -- REJECTION
        ----------------------------------------------------
        IF r.status = 'REJECTED' THEN
          INSERT INTO audit_log
                      (application_id,
                       user_id,
                       action_type,
                       description,
                       created_at)
          VALUES      ( r.application_id,
                       r.decided_by,
                       'APPLICATION_REJECTED',
                       'Loan officer rejected the mortgage application.',
                       r.decided_at );
        END IF;
    END LOOP;

    COMMIT;
END;

/ 


-------------------------------------------------------------------------------------------------
-- 7. Add Administrative Audit Events
-------------------------------------------------------------------------------------------------
BEGIN
	INSERT INTO audit_log
				(user_id,
				 action_type,
				 description)
	SELECT user_id,
		   'RATE_UPDATED',
		   'Updated current 30-Year Fixed mortgage rate to 6.500%.'
	FROM   app_users
	WHERE  username = 'maria.admin';

	INSERT INTO audit_log
				(user_id,
				 action_type,
				 description)
	SELECT user_id,
		   'PRODUCT_UPDATED',
		   'Updated 20-Year Fixed mortgage product configuration.'
	FROM   app_users
	WHERE  username = 'maria.admin';

	INSERT INTO audit_log
				(user_id,
				 action_type,
				 description)
	SELECT user_id,
		   'USER_CREATED',
		   'Created a new Loan Officer account.'
	FROM   app_users
	WHERE  username = 'maria.admin';

	INSERT INTO audit_log
				(user_id,
				 action_type,
				 description)
	SELECT user_id,
		   'USER_ROLE_UPDATED',
		   'Updated user role and authorization privileges.'
	FROM   app_users
	WHERE  username = 'maria.admin';
END;


-------------------------------------------------------------------------------------------------
-- 8. Generate Error Log
-------------------------------------------------------------------------------------------------

DECLARE
    l_admin_id   NUMBER;
    l_officer_id NUMBER;
    l_app_id     NUMBER;
BEGIN
    SELECT user_id
    INTO   l_admin_id
    FROM   app_users
    WHERE  username = 'maria.admin';

    SELECT user_id
    INTO   l_officer_id
    FROM   app_users
    WHERE  username = 'sarah.lopez';

    FOR i IN 1 .. 15 LOOP
        SELECT application_id
        INTO   l_app_id
        FROM   (SELECT application_id
                FROM   mortgage_applications
                ORDER  BY application_id)
        WHERE  ROWNUM = 1;

        INSERT INTO app_error_log
                    (application_id,
                     user_id,
                     page_id,
                     error_code,
                     error_message,
                     error_stack,
                     error_backtrace,
                     created_at)
        VALUES      ( CASE
                       WHEN MOD(i, 3) = 0 THEN NULL
                       ELSE l_app_id + i - 1
                     END,
                     CASE
                       WHEN MOD(i, 2) = 0 THEN l_admin_id
                       ELSE l_officer_id
                     END,
                     CASE MOD(i, 4)
                       WHEN 0 THEN 3
                       WHEN 1 THEN 22
                       WHEN 2 THEN 51
                       ELSE 52
                     END,
                     CASE MOD(i, 4)
                       WHEN 0 THEN 'ORA-20001'
                       WHEN 1 THEN 'ORA-06502'
                       WHEN 2 THEN 'REST-001'
                       ELSE 'AUTH-001'
                     END,
                     CASE MOD(i, 4)
        WHEN 0 THEN 'Application cannot transition from the current status.'
        WHEN 1 THEN 'Numeric or value conversion error.'
        WHEN 2 THEN 'External REST service returned an unexpected response.'
        ELSE 'Authorization validation failed.'
                     END,
                     'MortgageFlow simulated application error stack.',
        'MortgageFlow simulated PL/SQL backtrace for portfolio demonstration.',
        systimestamp - Numtodsinterval(i * 8, 'HOUR') );
    END LOOP;

    COMMIT;
END;

/ 