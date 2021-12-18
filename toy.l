%option noyywrap yylineno
%{
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>

#include "ast.h"
#include "utils.h"
#include "parser.hpp"
#include "ccalc.h"

#define YY_INPUT(buf,result,max_size)  {\
    result = GetNextChar(buf, max_size); \
    if (  result <= 0  ) \
      result = YY_NULL; \
    }
#define YYLVAL_DEBUG yylval.debug = strdup(yytext); 
extern YYLTYPE yylloc;
int yycolumn = 1;
int line_number;
#define YY_USER_ACTION yylloc.first_line = yylloc.last_line = yylineno;\
	yylloc.first_column = yycolumn; yylloc.last_column = yycolumn + yyleng - 1; \
    yycolumn += yyleng; 
%}

DIGIT             [0-9]+ 
DECIMAL           [0-9]+\.[0-9]+
ALPHA             [_A-Za-z]
ALPHA_NUM         ({ALPHA}|{DIGIT})
HEX_DIGIT         [0-9A-F]
IDENTIFIER        {ALPHA}{ALPHA_NUM}*
UNSIGNED_INTEGER  {DIGIT}+
HEX_INTEGER       ${HEX_DIGIT}{HEX_DIGIT}*
EXPONENT          e[+-]?{DIGIT}+
I                 {UNSIGNED_INTEGER}
RIIL              ({I}\.{I}?|{I}?\.{I}){EXPONENT}?
STRING            \'([^'\n]|\'\')+\'
BAD_STRING        \'([^'\n]|\'\')+

%x COMMENT1 COMMENT2


%%

(?# comment)
"{"                  BEGIN(COMMENT1);
<COMMENT1>[^}\n]+
<COMMENT1>\n            ++line_number;
<COMMENT1><<EOF>>    yyerror("EOF in comment");
<COMMENT1>"}"        BEGIN(INITIAL);
"(*"                 BEGIN(COMMENT2);
<COMMENT2>[^)*\n]+
<COMMENT2>\n            ++line_number;
<COMMENT2><<EOF>>    yyerror("EOF in comment");
<COMMENT2>"*)"       BEGIN(INITIAL);
<COMMENT2>[*)]

(?# symbols)
\'.\'	 	 { BeginToken(yytext); yylval.debug = strdup(yytext + 1); return CHAR;}
"="       { BeginToken(yytext);YYLVAL_DEBUG return EQUAL; }
"<"       { BeginToken(yytext);YYLVAL_DEBUG return LTHAN; }
"<="      { BeginToken(yytext);YYLVAL_DEBUG return LEQU; }
">"       { BeginToken(yytext);YYLVAL_DEBUG return GT; }
">="      { BeginToken(yytext);YYLVAL_DEBUG return GE; }
"<>"      { BeginToken(yytext);YYLVAL_DEBUG return UNEQUAL; }
"+"       { BeginToken(yytext);YYLVAL_DEBUG return PLUS; }
"-"       { BeginToken(yytext);YYLVAL_DEBUG return MINUS; }
"*"       { BeginToken(yytext);YYLVAL_DEBUG return MUL; }
"/"|"DIV" { BeginToken(yytext);YYLVAL_DEBUG return DIV; }		
")"       { BeginToken(yytext);YYLVAL_DEBUG return RIGHTP; }
"("       { BeginToken(yytext);YYLVAL_DEBUG return LEFTP; }
"["	  { BeginToken(yytext);YYLVAL_DEBUG return LB; }
"]"       { BeginToken(yytext);YYLVAL_DEBUG return RB; }
":="      { BeginToken(yytext);YYLVAL_DEBUG return ASSIGN; }
";"       { BeginToken(yytext);YYLVAL_DEBUG return SEMI; }
","	  { BeginToken(yytext);YYLVAL_DEBUG return COMMA; }
":"	  { BeginToken(yytext);YYLVAL_DEBUG return COLON; }

(?# Dont't forget to compile with -i, to enable case insensitivity)
"READ"|"READLN"   { BeginToken(yytext);YYLVAL_DEBUG return READ; }
"WRITE"|"WRITELN" {BeginToken(yytext);YYLVAL_DEBUG return WRITE; }
"BEGIN"     { BeginToken(yytext);YYLVAL_DEBUG return BEGINN; }
"END"	    { BeginToken(yytext);YYLVAL_DEBUG return END; }
"CASE"      { BeginToken(yytext);YYLVAL_DEBUG return CASE; }
"FOR"       { BeginToken(yytext);YYLVAL_DEBUG return FOR; }
"GOTO"      { BeginToken(yytext);YYLVAL_DEBUG return GOTO; }
"MOD"       { BeginToken(yytext);YYLVAL_DEBUG return MOD; }
"AND"       { BeginToken(yytext);YYLVAL_DEBUG return AND; }
"OR"        { BeginToken(yytext);YYLVAL_DEBUG return OR; }
"NOT"	    { BeginToken(yytext);YYLVAL_DEBUG return NOT; }
"REPEAT"    { BeginToken(yytext);YYLVAL_DEBUG return REPEAT; }
"UNTIL"     { BeginToken(yytext);YYLVAL_DEBUG return UNTIL; }
"IF"        { BeginToken(yytext);YYLVAL_DEBUG return IF; }
"THEN"      { BeginToken(yytext);YYLVAL_DEBUG return THEN; }
"ELSE"      { BeginToken(yytext);YYLVAL_DEBUG return ELSE; }
"WHILE"     { BeginToken(yytext);YYLVAL_DEBUG return WHILE; }
"DO"        { BeginToken(yytext);YYLVAL_DEBUG return DO; }
"DOWNTO"    { BeginToken(yytext);YYLVAL_DEBUG return DOWNTO; } 
"TO"        { BeginToken(yytext);YYLVAL_DEBUG return TO; }
"OF"        { BeginToken(yytext);YYLVAL_DEBUG return OF; }
"CONST"     { BeginToken(yytext);YYLVAL_DEBUG return CONST;}
"PROGRAM"   { BeginToken(yytext);YYLVAL_DEBUG return PROGRAM; }
"FUNCTION"  { BeginToken(yytext);YYLVAL_DEBUG return FUNCTION; }
"ARRAY"     { BeginToken(yytext);YYLVAL_DEBUG return ARRAY; }
"PROCEDURE" { BeginToken(yytext);YYLVAL_DEBUG return PROCEDURE; }
"TYPE"      { BeginToken(yytext);YYLVAL_DEBUG return TYPE; }
"RECORD"    { BeginToken(yytext);YYLVAL_DEBUG return RECORD; }
"VAR"       { BeginToken(yytext);YYLVAL_DEBUG return VAR; }

{RIIL} { BeginToken(yytext); YYLVAL_DEBUG return REAL; }
{UNSIGNED_INTEGER}  { BeginToken(yytext);YYLVAL_DEBUG  return UINTEGER; }
{STRING}            { BeginToken(yytext); YYLVAL_DEBUG return STRING; } 

"."      { BeginToken(yytext);YYLVAL_DEBUG return DOT; }
"FALSE"|"TRUE" { BeginToken(yytext);YYLVAL_DEBUG return SYS_BOOL; }

(?# system function)
"ABSOLUTE" { BeginToken(yytext);YYLVAL_DEBUG return SF_ABSOLUTE; }
(?# system type)
"boolean"|"char"|"integer"|"real"|"longint"    {BeginToken(yytext);YYLVAL_DEBUG return SYS_TYPE;}
([_a-zA-Z])([_a-zA-Z0-9])* { BeginToken(yytext);yylval.debug = strdup(yytext);return IDD; }

[ \t]+ {BeginToken(yytext);}
\n      ++line_number;
.		{ yyerror("Invalid character\n");} 

%%


void yyerror(const char* message)
{
   fprintf(stderr,"Error: \"%s\" in line %d. Token = %s\n",
           message,line_number,yytext);
   exit(1);
}


