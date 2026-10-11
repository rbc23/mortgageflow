create or replace package pkg_auth as

    function authenticate_user (
        p_username in varchar2,
        p_password in varchar2
    ) return boolean;

    procedure load_user_context;

end pkg_auth;
/



create or replace package body pkg_auth as


    ---------------------------------------------------------
    -- AUTHENTICATE USER
    ---------------------------------------------------------
    function authenticate_user (
        p_username in varchar2,
        p_password in varchar2
    ) return boolean
    is

        l_hash  varchar2(255);
        l_count number;

    begin

        -----------------------------------------------------
        -- Generate SHA256 hash
        -----------------------------------------------------

        select rawtohex(
                   standard_hash(
                       p_password,
                       'SHA256'
                   )
               )
          into l_hash
          from dual;


        -----------------------------------------------------
        -- Validate credentials
        -----------------------------------------------------

        select count(*)
          into l_count
          from app_users
         where upper(username) =
               upper(trim(p_username))
           and password_hash = l_hash
           and active_yn = 'Y';


        return l_count = 1;

    exception

        when others then
            return false;

    end authenticate_user;



    ---------------------------------------------------------
    -- LOAD USER INFORMATION INTO APEX SESSION
    ---------------------------------------------------------
    procedure load_user_context
    is

        l_user_id   app_users.user_id%type;
        l_role      app_users.role%type;
        l_full_name app_users.full_name%type;

    begin

        select user_id,
               role,
               full_name
          into l_user_id,
               l_role,
               l_full_name
          from app_users
         where upper(username) =
               upper(apex_application.g_user)
           and active_yn = 'Y';


        apex_util.set_session_state(
            'G_USER_ID',
            l_user_id
        );

        apex_util.set_session_state(
            'G_USER_ROLE',
            l_role
        );

        apex_util.set_session_state(
            'G_FULL_NAME',
            l_full_name
        );

    exception

        when no_data_found then

            raise_application_error(
                -20001,
                'Authenticated user was not found.'
            );

    end load_user_context;


end pkg_auth;
/