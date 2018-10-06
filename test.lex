%{
struct UNIT{
	union{
		char* name;
		float value;
	}val;
	bool intFlag;
};
#define YYSTYPE UNIT
#include "y.tab.h"
#include <stdio.h>
//#include <string.h>
//extern char* yylval;
%}

char 	[a-zA-Z]
varchar [a-zA-Z0-9_]
num 	[0-9]
posnum 	[1-9]

eq		"="

minus 	"-"
plus 	"+"
div 	"/"
mod 	"%"
times	"*"

delim 	";"
cr		"\n"
lb 		"("
rb		")"

band	"&"
bor		"|"
bneg	"~"
bxor	"^"

var 	{char}+{varchar}*
int 	{posnum}{num}*|[0]
float 	{int}\.{num}+

%%

{float}	{yylval.val.value = atof(yytext); 
		yylval.intFlag = false;
		return FLOAT;}
{int}   {yylval.val.value = atof(yytext); 
		yylval.intFlag = true;
 		return INT;}
{var}	{yylval.val.name = strdup(yytext);return VAR;}
{minus}	{return MINUS;}
{eq}	{return EQ;}
{plus}	{return PLUS;}
{div}	{return DIV;}
{mod}	{return MOD;}
{times}	{return TIMES;}
{delim}	{return DELIM;}
{lb}	{return LB;}
{rb}	{return RB;}
{cr}	{return CR;}
{band}	{return BAND;}
{bor}	{return BOR;}
{bneg}	{return BNEG;}
{bxor}	{return BXOR;}
. ;

%%

int yywrap()
{
  return 1;
}
