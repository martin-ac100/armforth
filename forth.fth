: IF LIT BZ , HERE @ DUP , ; IMMEDIATE
: THEN HERE @ SWAP ! ; IMMEDIATE
: TIMES [ HERE @ ] DUP IF 1- OVER EXE BRANCH [ SWAP , ] THEN DROP DROP ;
: HELLO 77 . ;
: t IF 1 . THEN 0 . ;
1 t 0 t
' HELLO 5 TIMES 

