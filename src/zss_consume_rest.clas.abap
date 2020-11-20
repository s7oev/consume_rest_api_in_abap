CLASS zss_consume_rest DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES:
      if_oo_adt_classrun.

    TYPES:
      BEGIN OF post_s,
        user_id TYPE i,
        id      TYPE i,
        title   TYPE string,
        body    TYPE string,
      END OF post_s,

      post_tt TYPE TABLE OF post_s WITH EMPTY KEY,

      BEGIN OF post_without_id_s,
        user_id TYPE i,
        title   TYPE string,
        body    TYPE string,
      END OF post_without_id_s.

    METHODS:
      create_client
        IMPORTING url           TYPE string
        RETURNING VALUE(result) TYPE REF TO if_web_http_client
        RAISING   cx_static_check,

      read_posts
        RETURNING VALUE(result) TYPE post_tt
        RAISING   cx_static_check,

      read_single_post
        IMPORTING id            TYPE i
        RETURNING VALUE(result) TYPE post_s
        RAISING   cx_static_check,

      create_post
        IMPORTING post_without_id TYPE post_without_id_s
        RETURNING VALUE(result)   TYPE string
        RAISING   cx_static_check,

      update_post
        IMPORTING post          TYPE post_s
        RETURNING VALUE(result) TYPE string
        RAISING   cx_static_check,

      delete_post
        IMPORTING id TYPE i
        RAISING   cx_static_check.

  PRIVATE SECTION.
    CONSTANTS:
      base_url     TYPE string VALUE 'https://jsonplaceholder.typicode.com/posts',
      content_type TYPE string VALUE 'Content-type',
      json_content TYPE string VALUE 'application/json; charset=UTF-8'.
ENDCLASS.



CLASS zss_consume_rest IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    TRY.
        " Read
        DATA(all_posts) = read_posts(  ).
        DATA(first_post) = read_single_post( 1 ).

        " Create
        DATA(create_response) = create_post( VALUE #( user_id = 7
          title = 'Hello, World!' body = ':)' ) ).

        " Update
        first_post-user_id = 777.
        DATA(update_response) = update_post( first_post ).

        " Delete
        delete_post( 9 ).

        " Print results
        out->write( all_posts ).
        out->write( first_post ).
        out->write( create_response ).
        out->write( update_response ).

      CATCH cx_root INTO DATA(exc).
        out->write( exc->get_text(  ) ).
    ENDTRY.
  ENDMETHOD.


  METHOD create_client.
    DATA(dest) = cl_http_destination_provider=>create_by_url( url ).
    result = cl_web_http_client_manager=>create_by_http_destination( dest ).
  ENDMETHOD.


  METHOD read_posts.
    " Get JSON of all posts
    DATA(url) = |{ base_url }|.
    DATA(client) = create_client( url ).
    DATA(response) = client->execute( if_web_http_client=>get )->get_text(  ).
    client->close(  ).

    " Convert JSON to post table
    xco_cp_json=>data->from_string( response )->apply(
      VALUE #( ( xco_cp_json=>transformation->camel_case_to_underscore ) )
      )->write_to( REF #( result ) ).
  ENDMETHOD.


  METHOD read_single_post.
    " Get JSON for input post ID
    DATA(url) = |{ base_url }/{ id }|.
    DATA(client) = create_client( url ).
    DATA(response) = client->execute( if_web_http_client=>get )->get_text(  ).
    client->close(  ).

    " Convert JSON to post structure
    xco_cp_json=>data->from_string( response )->apply(
      VALUE #( ( xco_cp_json=>transformation->camel_case_to_underscore ) )
      )->write_to( REF #( result ) ).
  ENDMETHOD.


  METHOD create_post.
    " Convert input post to JSON
    DATA(json_post) = xco_cp_json=>data->from_abap( post_without_id )->apply(
      VALUE #( ( xco_cp_json=>transformation->underscore_to_camel_case ) ) )->to_string(  ).

    " Send JSON of post to server and return the response
    DATA(url) = |{ base_url }|.
    DATA(client) = create_client( url ).
    DATA(req) = client->get_http_request(  ).
    req->set_text( json_post ).
    req->set_header_field( i_name = content_type i_value = json_content ).

    result = client->execute( if_web_http_client=>post )->get_text(  ).
    client->close(  ).
  ENDMETHOD.


  METHOD update_post.
    " Convert input post to JSON
    DATA(json_post) = xco_cp_json=>data->from_abap( post )->apply(
      VALUE #( ( xco_cp_json=>transformation->underscore_to_camel_case ) ) )->to_string(  ).

    " Send JSON of post to server and return the response
    DATA(url) = |{ base_url }/{ post-id }|.
    DATA(client) = create_client( url ).
    DATA(req) = client->get_http_request(  ).
    req->set_text( json_post ).
    req->set_header_field( i_name = content_type i_value = json_content ).

    result = client->execute( if_web_http_client=>put )->get_text(  ).
    client->close(  ).
  ENDMETHOD.


  METHOD delete_post.
    DATA(url) = |{ base_url }/{ id }|.
    DATA(client) = create_client( url ).
    DATA(response) = client->execute( if_web_http_client=>delete ).

    IF response->get_status(  )-code NE 200.
      RAISE EXCEPTION TYPE cx_web_http_client_error.
    ENDIF.
  ENDMETHOD.
ENDCLASS.