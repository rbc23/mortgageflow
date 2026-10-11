CREATE OR REPLACE PACKAGE pkg_mortgage_app AS
  /* =========================================================
       PRODUCT / RATE
       ========================================================= */
  PROCEDURE get_product_terms (p_loan_product_id IN NUMBER,
                               p_interest_rate OUT  NUMBER,
                               p_term_years OUT     NUMBER
  );
  /* =========================================================
       CALCULATIONS
       ========================================================= */
  FUNCTION Calculate_monthly_payment (p_loan_amount IN   NUMBER,
                                      p_interest_rate IN NUMBER,
                                      p_term_years IN    NUMBER
  ) RETURN NUMBER;
  FUNCTION Calculate_ltv (p_loan_amount IN    NUMBER,
                          p_property_value IN NUMBER
  ) RETURN NUMBER;
  FUNCTION Calculate_dti (p_annual_income IN   NUMBER,
                          p_monthly_debt IN    NUMBER,
                          p_monthly_payment IN NUMBER
  ) RETURN NUMBER;
  FUNCTION Calculate_risk (p_ltv IN NUMBER,
                           p_dti IN NUMBER
  ) RETURN VARCHAR2;
  PROCEDURE calculate_mortgage (p_property_value IN   NUMBER,
                                p_down_payment IN     NUMBER,
                                p_annual_income IN    NUMBER,
                                p_monthly_debt IN     NUMBER,
                                p_interest_rate IN    NUMBER,
                                p_term_years IN       NUMBER,
                                p_loan_amount OUT     NUMBER,
                                p_monthly_payment OUT NUMBER,
                                p_ltv OUT             NUMBER,
                                p_dti OUT             NUMBER,
                                p_risk_level OUT      VARCHAR2
  );
  /* =========================================================
       APPLICATION CREATION / EDITING
       ========================================================= */
  PROCEDURE create_application (p_applicant_user_id IN   NUMBER,
                                p_loan_product_id IN     NUMBER,
                                p_annual_income IN       NUMBER,
                                p_monthly_debt IN        NUMBER,
                                p_property_value IN      NUMBER,
                                p_down_payment IN        NUMBER,
                                p_application_id OUT     NUMBER,
                                p_application_number OUT VARCHAR2
  );
  PROCEDURE update_draft (p_application_id IN    NUMBER,
                          p_applicant_user_id IN NUMBER,
                          p_loan_product_id IN   NUMBER,
                          p_annual_income IN     NUMBER,
                          p_monthly_debt IN      NUMBER,
                          p_property_value IN    NUMBER,
                          p_down_payment IN      NUMBER
  );
  /* =========================================================
       APPLICATION LIFECYCLE
       ========================================================= */
  PROCEDURE submit_application (p_application_id IN            NUMBER,
                                p_user_id IN                   NUMBER,
                                p_comments IN VARCHAR2 DEFAULT NULL
  );
  PROCEDURE start_review (p_application_id IN            NUMBER,
                          p_user_id IN                   NUMBER,
                          p_comments IN VARCHAR2 DEFAULT NULL
  );
  PROCEDURE approve_application (p_application_id IN            NUMBER,
                                 p_user_id IN                   NUMBER,
                                 p_comments IN VARCHAR2 DEFAULT NULL
  );
  PROCEDURE reject_application (p_application_id IN NUMBER,
                                p_user_id IN        NUMBER,
                                p_comments IN       VARCHAR2
  );
  END pkg_mortgage_app;

/

CREATE OR REPLACE PACKAGE BODY pkg_mortgage_app AS
  /* =========================================================
       PRIVATE: AUDIT
       ========================================================= */
  PROCEDURE add_audit (p_application_id IN NUMBER,
                       p_user_id IN        NUMBER,
                       p_action_type IN    VARCHAR2,
                       p_description IN    VARCHAR2
  ) IS

    BEGIN
      INSERT INTO audit_log
                  ( application_id,
                    user_id,
                    action_type,
                    description,
                    created_at )
      VALUES      ( p_application_id,
                    p_user_id,
                    p_action_type,
                    p_description,
                    Systimestamp );
    END add_audit;
  /* =========================================================
       PRIVATE: STATUS HISTORY
       ========================================================= */
  PROCEDURE add_status_history (p_application_id IN NUMBER,
                                p_old_status IN     VARCHAR2,
                                p_new_status IN     VARCHAR2,
                                p_user_id IN        NUMBER,
                                p_comments IN       VARCHAR2
  ) IS
    BEGIN
      INSERT INTO application_status_history
                  ( application_id,
                    old_status,
                    new_status,
                    changed_by,
                    changed_at,
                    comments )
      VALUES      ( p_application_id,
                    p_old_status,
                    p_new_status,
                    p_user_id,
                    Systimestamp,
                    p_comments );
    END add_status_history;
  /* =========================================================
       PRIVATE: VALIDATE USER
       ========================================================= */
  PROCEDURE assert_active_user (p_user_id IN NUMBER
  )
  IS
    l_count NUMBER;
    BEGIN
      SELECT Count(*)
      INTO   l_count
      FROM   app_users
      WHERE  user_id = p_user_id
             AND active_yn = 'Y';
      IF l_count = 0 THEN
        Raise_application_error( -20001, 'Invalid or inactive user.' );
      END IF;
    END assert_active_user;
  /* =========================================================
       PRIVATE: VALIDATE STAFF
       ========================================================= */
  PROCEDURE assert_staff_user (p_user_id IN NUMBER
  )
  IS
    l_count NUMBER;
    BEGIN
      SELECT Count(*)
      INTO   l_count
      FROM   app_users
      WHERE  user_id = p_user_id
             AND active_yn = 'Y'
             AND role IN ( 'LOAN_OFFICER', 'ADMIN' );
      IF l_count = 0 THEN
        Raise_application_error( -20001, 'Loan officer or administrator privileges are required.' );
      END IF;
    END assert_staff_user;
  /* =========================================================
       PRODUCT / CURRENT INTEREST RATE
       ========================================================= */
  PROCEDURE get_product_terms (p_loan_product_id IN NUMBER,
                               p_interest_rate OUT  NUMBER,
                               p_term_years OUT     NUMBER
  ) IS
    BEGIN
      WITH current_rates
           AS (SELECT ir.loan_product_id,
                      ir.interest_rate,
                      Row_number() OVER ( PARTITION BY ir.loan_product_id ORDER BY ir.effective_from DESC) AS rn
               FROM   interest_rates ir
               WHERE  ir.active_yn = 'Y'
                      AND ir.effective_from <= SYSDATE
                      AND ( ir.effective_to IS NULL
                            OR ir.effective_to >= SYSDATE ))
        SELECT cr.interest_rate,
               lp.term_years
        INTO   p_interest_rate, p_term_years
        FROM   loan_products lp
               JOIN current_rates cr
               ON cr.loan_product_id = lp.loan_product_id
                  AND cr.rn = 1
        WHERE  lp.loan_product_id = p_loan_product_id
               AND lp.active_yn = 'Y'; EXCEPTION WHEN no_data_found THEN Raise_application_error( -20001, 'The selected loan product has no active current interest rate.' );
    END get_product_terms;
  /* =========================================================
       MONTHLY PAYMENT
       ========================================================= */
  FUNCTION Calculate_monthly_payment (p_loan_amount IN   NUMBER,
                                      p_interest_rate IN NUMBER,
                                      p_term_years IN    NUMBER
  ) RETURN NUMBER
  IS
    l_monthly_rate NUMBER;
    l_payment_count NUMBER;
    l_payment NUMBER;
    BEGIN
      IF p_loan_amount <= 0 THEN
        Raise_application_error( -20001, 'Loan amount must be greater than zero.' );
      END IF;
      IF p_term_years <= 0 THEN
        Raise_application_error( -20001, 'Loan term must be greater than zero.' );
      END IF;
      IF p_interest_rate < 0 THEN
        Raise_application_error( -20001, 'Interest rate cannot be negative.' );
      END IF;
      l_monthly_rate := (p_interest_rate / 100) / 12;
      l_payment_count := p_term_years * 12;
      IF l_monthly_rate = 0 THEN
        l_payment := p_loan_amount / l_payment_count;
      ELSE
        l_payment := p_loan_amount * ( l_monthly_rate * Power( 1 + l_monthly_rate, l_payment_count ) ) / ( Power( 1 + l_monthly_rate, l_payment_count ) - 1 );
      END IF;
      RETURN Round( l_payment, 2 );
    END calculate_monthly_payment;
  /* =========================================================
       LTV
       ========================================================= */
  FUNCTION Calculate_ltv (p_loan_amount IN    NUMBER,
                          p_property_value IN NUMBER
  ) RETURN NUMBER IS
    BEGIN
      IF p_property_value <= 0 THEN
        Raise_application_error( -20001, 'Property value must be greater than zero.' );
      END IF;
      RETURN Round( ( p_loan_amount / p_property_value ) * 100, 2 );
    END calculate_ltv;
  /* =========================================================
       DTI
       ========================================================= */
  FUNCTION Calculate_dti (p_annual_income IN   NUMBER,
                          p_monthly_debt IN    NUMBER,
                          p_monthly_payment IN NUMBER
  ) RETURN NUMBER IS
    BEGIN
      IF p_annual_income <= 0 THEN
        Raise_application_error( -20001, 'Annual income must be greater than zero.' );
      END IF;
      RETURN Round( ( Nvl(p_monthly_debt, 0) + p_monthly_payment ) / ( p_annual_income / 12 ) * 100, 2 );
    END calculate_dti;
  /* =========================================================
       RISK
       Demo underwriting logic
       ========================================================= */
  FUNCTION Calculate_risk (p_ltv IN NUMBER,
                           p_dti IN NUMBER
  ) RETURN VARCHAR2 IS
    BEGIN
      IF p_ltv > 90
         OR p_dti > 45 THEN
        RETURN 'HIGH';
      ELSIF p_ltv > 80 OR p_dti > 35 THEN

        RETURN 'MEDIUM';
      ELSE
        RETURN 'LOW';
      END IF;
    END calculate_risk;
  /* =========================================================
       COMPLETE CALCULATION
       ========================================================= */
  PROCEDURE calculate_mortgage (p_property_value IN   NUMBER,
                                p_down_payment IN     NUMBER,
                                p_annual_income IN    NUMBER,
                                p_monthly_debt IN     NUMBER,
                                p_interest_rate IN    NUMBER,
                                p_term_years IN       NUMBER,
                                p_loan_amount OUT     NUMBER,
                                p_monthly_payment OUT NUMBER,
                                p_ltv OUT             NUMBER,
                                p_dti OUT             NUMBER,
                                p_risk_level OUT      VARCHAR2
  ) IS
    BEGIN
      IF p_property_value IS NULL
         OR p_property_value <= 0 THEN
        Raise_application_error( -20001, 'Property value must be greater than zero.' );
      END IF;
      IF Nvl(p_down_payment, 0) < 0
         OR Nvl(p_down_payment, 0) >= p_property_value THEN
        Raise_application_error( -20001, 'Down payment must be less than the property value.' );
      END IF;
      IF p_annual_income IS NULL
         OR p_annual_income <= 0 THEN
        Raise_application_error( -20001, 'Annual income must be greater than zero.' );
      END IF;
      p_loan_amount := p_property_value - Nvl(p_down_payment, 0);
      p_monthly_payment := Calculate_monthly_payment( p_loan_amount => p_loan_amount, p_interest_rate => p_interest_rate, p_term_years => p_term_years );
      p_ltv := Calculate_ltv( p_loan_amount => p_loan_amount, p_property_value => p_property_value );
      p_dti := Calculate_dti( p_annual_income => p_annual_income, p_monthly_debt => p_monthly_debt, p_monthly_payment => p_monthly_payment );
      p_risk_level := Calculate_risk( p_ltv => p_ltv, p_dti => p_dti );
    END calculate_mortgage;
  /* =========================================================
       CREATE APPLICATION
       ========================================================= */
  PROCEDURE create_application (p_applicant_user_id IN   NUMBER,
                                p_loan_product_id IN     NUMBER,
                                p_annual_income IN       NUMBER,
                                p_monthly_debt IN        NUMBER,
                                p_property_value IN      NUMBER,
                                p_down_payment IN        NUMBER,
                                p_application_id OUT     NUMBER,
                                p_application_number OUT VARCHAR2
  )
  IS
    l_interest_rate NUMBER;
    l_term_years NUMBER;
    l_loan_amount NUMBER;
    l_monthly_payment NUMBER;
    l_ltv NUMBER;
    l_dti NUMBER;
    l_risk VARCHAR2(20);
    l_temp_number VARCHAR2(30);
    BEGIN
      Assert_active_user( p_applicant_user_id );
      /* Get rate and term directly from product */
      Get_product_terms( p_loan_product_id => p_loan_product_id, p_interest_rate => l_interest_rate, p_term_years => l_term_years );
      /* Calculate everything */
      Calculate_mortgage( p_property_value => p_property_value, p_down_payment => p_down_payment, p_annual_income => p_annual_income, p_monthly_debt => p_monthly_debt, p_interest_rate => l_interest_rate, p_term_years => l_term_years, p_loan_amount => l_loan_amount, p_monthly_payment => l_monthly_payment, p_ltv => l_ltv, p_dti => l_dti, p_risk_level => l_risk );
      /* Temporary unique application number */
      l_temp_number := 'TMP-' || Substr( Rawtohex(Sys_guid()), 1, 20 );
      INSERT INTO mortgage_applications
                  ( application_number,
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
                    created_at,
                    updated_at )
      VALUES      ( l_temp_number,
                    p_applicant_user_id,
                    p_loan_product_id,
                    p_annual_income,
                    Nvl(p_monthly_debt, 0),
                    p_property_value,
                    Nvl(p_down_payment, 0),
                    l_loan_amount,
                    l_interest_rate,
                    l_term_years,
                    l_monthly_payment,
                    l_ltv,
                    l_dti,
                    l_risk,
                    'DRAFT',
                    Systimestamp,
                    Systimestamp ) RETURNING application_id INTO p_application_id;
      /* Generate final application number */
      p_application_number := 'MF-' || To_char(Sysdate, 'YYYY') || '-' || Lpad( p_application_id, 4, '0' );
      UPDATE mortgage_applications
      SET    application_number = p_application_number
      WHERE  application_id = p_application_id;
      /* Initial history */
      Add_status_history( p_application_id => p_application_id, p_old_status => NULL, p_new_status => 'DRAFT', p_user_id => p_applicant_user_id, p_comments => 'Mortgage application created.' );
      /* Audit */
      Add_audit( p_application_id => p_application_id, p_user_id => p_applicant_user_id, p_action_type => 'APPLICATION_CREATED', p_description => 'Mortgage application ' || p_application_number || ' created.' );
    END create_application;
  /* =========================================================
       UPDATE DRAFT
       ========================================================= */
  PROCEDURE update_draft (p_application_id IN    NUMBER,
                          p_applicant_user_id IN NUMBER,
                          p_loan_product_id IN   NUMBER,
                          p_annual_income IN     NUMBER,
                          p_monthly_debt IN      NUMBER,
                          p_property_value IN    NUMBER,
                          p_down_payment IN      NUMBER
  )
  IS
    l_status MORTGAGE_APPLICATIONS.STATUS%TYPE;
    l_owner_id MORTGAGE_APPLICATIONS.APPLICANT_USER_ID%TYPE;
    l_interest_rate NUMBER;
    l_term_years NUMBER;
    l_loan_amount NUMBER;
    l_monthly_payment NUMBER;
    l_ltv NUMBER;
    l_dti NUMBER;
    l_risk VARCHAR2(20);
    BEGIN
      SELECT status,
             applicant_user_id
      INTO   l_status, l_owner_id
      FROM   mortgage_applications
      WHERE  application_id = p_application_id FOR UPDATE;
      IF l_owner_id <> p_applicant_user_id THEN
        Raise_application_error( -20001, 'You cannot modify this application.' );
      END IF;
      IF l_status <> 'DRAFT' THEN
        Raise_application_error( -20001, 'Only draft applications can be edited.' );
      END IF;
      Get_product_terms( p_loan_product_id => p_loan_product_id, p_interest_rate => l_interest_rate, p_term_years => l_term_years );
      Calculate_mortgage( p_property_value => p_property_value, p_down_payment => p_down_payment, p_annual_income => p_annual_income, p_monthly_debt => p_monthly_debt, p_interest_rate => l_interest_rate, p_term_years => l_term_years, p_loan_amount => l_loan_amount, p_monthly_payment => l_monthly_payment, p_ltv => l_ltv, p_dti => l_dti, p_risk_level => l_risk );
      UPDATE mortgage_applications
      SET    loan_product_id = p_loan_product_id,
             annual_income = p_annual_income,
             monthly_debt = Nvl(p_monthly_debt, 0),
             property_value = p_property_value,
             down_payment = Nvl(p_down_payment, 0),
             loan_amount = l_loan_amount,
             interest_rate = l_interest_rate,
             loan_term_years = l_term_years,
             monthly_payment = l_monthly_payment,
             ltv = l_ltv,
             dti = l_dti,
             risk_level = l_risk,
             updated_at = Systimestamp
      WHERE  application_id = p_application_id;
      Add_audit( p_application_id => p_application_id, p_user_id => p_applicant_user_id, p_action_type => 'APPLICATION_UPDATED', p_description => 'Draft mortgage application updated.' );
    END update_draft;
  /* =========================================================
       SUBMIT APPLICATION
       ========================================================= */
  PROCEDURE submit_application (p_application_id IN            NUMBER,
                                p_user_id IN                   NUMBER,
                                p_comments IN VARCHAR2 DEFAULT NULL
  )
  IS
    l_status MORTGAGE_APPLICATIONS.STATUS%TYPE;
    l_owner_id MORTGAGE_APPLICATIONS.APPLICANT_USER_ID%TYPE;
    BEGIN
      Assert_active_user( p_user_id );
      SELECT status,
             applicant_user_id
      INTO   l_status, l_owner_id
      FROM   mortgage_applications
      WHERE  application_id = p_application_id FOR UPDATE;
      IF l_owner_id <> p_user_id THEN
        Raise_application_error( -20001, 'You cannot submit this application.' );
      END IF;
      IF l_status <> 'DRAFT' THEN
        Raise_application_error( -20001, 'Only draft applications can be submitted.' );
      END IF;
      UPDATE mortgage_applications
      SET    status = 'SUBMITTED',
             submitted_at = Systimestamp,
             updated_at = Systimestamp
      WHERE  application_id = p_application_id;
      Add_status_history( p_application_id => p_application_id, p_old_status => l_status, p_new_status => 'SUBMITTED', p_user_id => p_user_id, p_comments => Nvl( p_comments, 'Application submitted.' ) );
      Add_audit( p_application_id => p_application_id, p_user_id => p_user_id, p_action_type => 'APPLICATION_SUBMITTED', p_description => 'Mortgage application submitted.' );
    END submit_application;
  /* =========================================================
       START REVIEW
       ========================================================= */
  PROCEDURE start_review (p_application_id IN            NUMBER,
                          p_user_id IN                   NUMBER,
                          p_comments IN VARCHAR2 DEFAULT NULL
  )
  IS
    l_status MORTGAGE_APPLICATIONS.STATUS%TYPE;
    BEGIN
      Assert_staff_user( p_user_id );
      SELECT status
      INTO   l_status
      FROM   mortgage_applications
      WHERE  application_id = p_application_id FOR UPDATE;
      IF l_status <> 'SUBMITTED' THEN
        Raise_application_error( -20001, 'Only submitted applications can enter review.' );
      END IF;
      UPDATE mortgage_applications
      SET    status = 'UNDER_REVIEW',
             updated_at = Systimestamp
      WHERE  application_id = p_application_id;
      Add_status_history( p_application_id => p_application_id, p_old_status => l_status, p_new_status => 'UNDER_REVIEW', p_user_id => p_user_id, p_comments => Nvl( p_comments, 'Loan officer review started.' ) );
      Add_audit( p_application_id => p_application_id, p_user_id => p_user_id, p_action_type => 'REVIEW_STARTED', p_description => 'Mortgage application review started.' );
    END start_review;
  /* =========================================================
       APPROVE
       ========================================================= */
  PROCEDURE approve_application (p_application_id IN            NUMBER,
                                 p_user_id IN                   NUMBER,
                                 p_comments IN VARCHAR2 DEFAULT NULL
  )
  IS
    l_status MORTGAGE_APPLICATIONS.STATUS%TYPE;
    BEGIN
      Assert_staff_user( p_user_id );
      SELECT status
      INTO   l_status
      FROM   mortgage_applications
      WHERE  application_id = p_application_id FOR UPDATE;
      IF l_status <> 'UNDER_REVIEW' THEN
        Raise_application_error( -20001, 'Only applications under review can be approved.' );
      END IF;
      UPDATE mortgage_applications
      SET    status = 'APPROVED',
             decided_at = Systimestamp,
             decided_by = p_user_id,
             updated_at = Systimestamp
      WHERE  application_id = p_application_id;
      Add_status_history( p_application_id => p_application_id, p_old_status => l_status, p_new_status => 'APPROVED', p_user_id => p_user_id, p_comments => Nvl( p_comments, 'Mortgage application approved.' ) );
      Add_audit( p_application_id => p_application_id, p_user_id => p_user_id, p_action_type => 'APPLICATION_APPROVED', p_description => 'Mortgage application approved.' );
    END approve_application;
  /* =========================================================
       REJECT
       ========================================================= */
  PROCEDURE reject_application (p_application_id IN NUMBER,
                                p_user_id IN        NUMBER,
                                p_comments IN       VARCHAR2
  )
  IS
    l_status MORTGAGE_APPLICATIONS.STATUS%TYPE;
    BEGIN
      Assert_staff_user( p_user_id );
      IF Trim(p_comments) IS NULL THEN
        Raise_application_error( -20001, 'A rejection reason is required.' );
      END IF;
      SELECT status
      INTO   l_status
      FROM   mortgage_applications
      WHERE  application_id = p_application_id FOR UPDATE;
      IF l_status <> 'UNDER_REVIEW' THEN
        Raise_application_error( -20001, 'Only applications under review can be rejected.' );
      END IF;
      UPDATE mortgage_applications
      SET    status = 'REJECTED',
             decided_at = Systimestamp,
             decided_by = p_user_id,
             updated_at = Systimestamp
      WHERE  application_id = p_application_id;
      Add_status_history( p_application_id => p_application_id, p_old_status => l_status, p_new_status => 'REJECTED', p_user_id => p_user_id, p_comments => p_comments );
      Add_audit( p_application_id => p_application_id, p_user_id => p_user_id, p_action_type => 'APPLICATION_REJECTED', p_description => 'Mortgage application rejected. Reason: ' || p_comments );
    END reject_application;
  END pkg_mortgage_app;

/