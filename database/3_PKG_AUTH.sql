CREATE OR replace PACKAGE pkg_auth
AS
  ---------------------------------------------------------
  -- AUTHENTICATE USER
  ---------------------------------------------------------
  FUNCTION Authenticate_user (
    p_username IN VARCHAR2,
    p_password IN VARCHAR2 )
  RETURN BOOLEAN;
  ---------------------------------------------------------
  -- LOAD USER INFORMATION INTO APEX SESSION
  ---------------------------------------------------------
  PROCEDURE load_user_context;
END pkg_auth;

/
CREATE OR replace PACKAGE BODY pkg_auth
AS
  ---------------------------------------------------------
  -- AUTHENTICATE USER
  ---------------------------------------------------------
  FUNCTION Authenticate_user (p_username IN VARCHAR2,
                              p_password IN VARCHAR2)
  RETURN BOOLEAN
  IS
    l_hash  VARCHAR2(255);
    l_count NUMBER;
  BEGIN
      -----------------------------------------------------
      -- Generate SHA256 hash from entered password
      -----------------------------------------------------
      SELECT Rawtohex(Standard_hash(p_password, 'SHA256'))
      INTO   l_hash
      FROM   dual;

      -----------------------------------------------------
      -- Validate username, password and active status
      -----------------------------------------------------
      SELECT Count(*)
      INTO   l_count
      FROM   app_users
      WHERE  Upper(Trim(username)) = Upper(Trim(p_username))
             AND password_hash = l_hash
             AND active_yn = 'Y';

      -----------------------------------------------------
      -- Authentication succeeds only for exactly one user
      -----------------------------------------------------
      RETURN l_count = 1;
  EXCEPTION
    WHEN OTHERS THEN
               RETURN FALSE;
  END authenticate_user;
  ---------------------------------------------------------
  -- LOAD USER INFORMATION INTO APEX SESSION
  ---------------------------------------------------------
  PROCEDURE Load_user_context
  IS
    l_user_id   app_users.user_id%TYPE;
    l_role      app_users.ROLE%TYPE;
    l_full_name app_users.full_name%TYPE;
    l_username  app_users.username%TYPE;
  BEGIN
      -----------------------------------------------------
      -- Get authenticated APEX username
      -----------------------------------------------------
      l_username := V('APP_USER');

      -----------------------------------------------------
      -- Find user information
      -----------------------------------------------------
      SELECT user_id,
             Upper(Trim(ROLE)),
             full_name
      INTO   l_user_id, l_role, l_full_name
      FROM   app_users
      WHERE  Upper(Trim(username)) = Upper(Trim(l_username))
             AND active_yn = 'Y';

      -----------------------------------------------------
      -- Store user ID in APEX session
      -----------------------------------------------------
      apex_util.Set_session_state(p_name => 'G_USER_ID', p_value => l_user_id);

      -----------------------------------------------------
      -- Store user role in APEX session
      -----------------------------------------------------
      apex_util.Set_session_state(p_name => 'G_USER_ROLE', p_value => l_role);

      -----------------------------------------------------
      -- Store user's full name in APEX session
      -----------------------------------------------------
      apex_util.Set_session_state(p_name => 'G_FULL_NAME',
      p_value => l_full_name)
      ;
  EXCEPTION
    WHEN no_data_found THEN
               Raise_application_error(-20001,
               'Authenticated user was not found.'); WHEN too_many_rows THEN
               Raise_application_error(-20002,
               'Multiple active users were found with the same username.');
  END load_user_context;
END pkg_auth;

/ 