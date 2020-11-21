CLASS zcl_ss_tester_vsc DEFINITION PUBLIC CREATE PRIVATE.
  PUBLIC SECTION.
    INTERFACES:
      if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_ss_tester_vsc IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( 'Hello World!' ).
    DATA tt TYPE test_t.
    APPEND 5 TO tt.
  ENDMETHOD.
ENDCLASS.
