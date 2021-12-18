PROGRAM hello;

CONST 
  a = 2;

VAR
	cn : integer;

BEGIN

  cn := a + 3 * 2;
  IF(cn > 1) THEN
    BEGIN
    cn := cn + a;
    END
  ELSE
    BEGIN
      cn := 0;
    END
  ;

END.

