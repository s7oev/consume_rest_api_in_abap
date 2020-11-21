CLASS zss_tester DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES:
      BEGIN OF user_s,
        id         TYPE i,
        email      TYPE string,
        first_name TYPE string,
        last_name  TYPE string,
        avatar     TYPE string,
      END OF user_s,
      user_tt TYPE TABLE OF user_s WITH EMPTY KEY,

      BEGIN OF json_s,
        data TYPE user_tt,
      END OF json_s.

    INTERFACES:
      if_oo_adt_classrun.

    METHODS:
      create_client
        RETURNING VALUE(r_client) TYPE REF TO if_web_http_client,

      get_users_json
        IMPORTING i_client      TYPE REF TO if_web_http_client
        RETURNING VALUE(r_json) TYPE string,

      post_user
        IMPORTING i_client               TYPE REF TO if_web_http_client
        RETURNING VALUE(r_json_response) TYPE string,

      users_json_to_tab
        IMPORTING i_json       TYPE string
        RETURNING VALUE(r_tab) TYPE user_tt,

      post_test_2
        RETURNING VALUE(result) TYPE string
        RAISING cx_root.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZSS_TESTER IMPLEMENTATION.


  METHOD get_users_json.
    TRY.
        DATA(response) = i_client->execute( if_web_http_client=>get ).
        r_json = response->get_text(  ).
      CATCH cx_web_http_client_error.
    ENDTRY.
  ENDMETHOD.


  METHOD post_user.
    TRY.
        TYPES:
          BEGIN OF users_post_s,
            name TYPE string,
            job  TYPE string,
          END OF users_post_s.

        DATA(user) = VALUE users_post_s( name = 's7oev' job = 'abap' ).
        DATA(json_string) = xco_cp_json=>data->from_abap( user )->to_string(  ).


        DATA(req) = i_client->get_http_request(  ).
        json_string = '{"name":"s7oev","job":"abap"}'.

        req->append_text( json_string ).
*        req->set_text( '{"name":"s7oev","job":"abap"}' ).
*        req->set_form_field( i_name = 'name' i_value = 's7oev' ).
*        req->set_form_field( i_name = 'job' i_value = 'abap' ).

        DATA(req_txt) = req->get_text(  ).


        DATA(response) = i_client->execute( if_web_http_client=>post ).
        r_json_response = response->get_text(  ).
      CATCH cx_web_http_client_error.
    ENDTRY.
  ENDMETHOD.


  METHOD post_test_2.
    DATA url TYPE string.
    url = 'https://jsonplaceholder.typicode.com/posts'.

    DATA(dest) = cl_http_destination_provider=>create_by_url( url ).
    DATA(client) = cl_web_http_client_manager=>create_by_http_destination( dest ).

    DATA(req) = client->get_http_request(  ).

    req->set_text( '{ "title":"s7oev", "body":"sss", "userId":7 }' ).
    req->set_header_field( i_name = 'Content-type' i_value = 'application/json; charset=UTF-8' ).

    result = client->execute( if_web_http_client=>post )->get_text(  ).
  ENDMETHOD.


  METHOD if_oo_adt_classrun~main.
    TRY.
        DATA(client) = create_client(  ).
        DATA(users_json) = get_users_json( i_client = client ).
        DATA(users_tab) = users_json_to_tab( users_json ).
        out->write( users_tab ).

        DATA(post_response) = post_user( i_client = client ).
        out->write( post_response ).

        out->write( post_test_2(  ) ).

      CATCH cx_root INTO DATA(exc).
        out->write( exc->get_text(  ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD create_client.
    TRY.
        DATA url TYPE string.
        url = 'https://reqres.in/api/users'.

        DATA(dest) = cl_http_destination_provider=>create_by_url( url ).
        r_client = cl_web_http_client_manager=>create_by_http_destination( dest ).
      CATCH cx_root.
    ENDTRY.
  ENDMETHOD.


  METHOD users_json_to_tab.
    DATA tab TYPE json_s.
    "/ui2/cl_json=>deserialize( EXPORTING json = i_json CHANGING data = tab ).

    xco_cp_json=>data->from_string( i_json )->write_to( REF #( tab ) ).

    r_tab = tab-data.
  ENDMETHOD.
ENDCLASS.
