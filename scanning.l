%option yylineno
%{
#include "syntaxTree.h"
#include "parsing.tab.h"
int hasSyntaxError = 0;
int yycolumn = 1;
#define YY_USER_ACTION \ 
	yylloc.first_line = yylloc.last_line = yylineno; \ 
	yylloc.first_column = yycolumn; \ 
	yylloc.last_column = yycolumn + yyleng - 1; \ 
	yycolumn += yyleng;
%}


%%

0[0-9]+ {yylval.i = checkOctal(yytext); return INT;}
0|([1-9][0-9]*)  {yylval.i = checkDecimal(yytext); return INT;}
0(x|X)([0-9A-Z]+|[0-9a-z]+) {yylval.i = checkHexadecimal(yytext); return INT;}
[0-9]+"."[0-9]+ {yylval.f = checkFloat(yytext); return FLOAT;}
[0-9]+"."[0-9]*[eE]?[+-]?[0-9]+ {yylval.f = checkExpFloat(yytext); return FLOAT;}
"."[0-9]+[eE]?[+-]?[0-9]+   {yylval.f = checkExpFloat(yytext); return FLOAT;}

"," {return COMMA;}
";" {return SEMI;}
"=" {return ASSIGNOP;}
">" {yylval.type = 1; return RELOP;}
"<" {yylval.type = 2; return RELOP;}
"=="    {yylval.type = 4; return RELOP;}
">="    {yylval.type = 5; return RELOP;}
"<="    {yylval.type = 6; return RELOP;}
"!="    {yylval.type = 3; return RELOP;}
"+" {return PLUS;}
"-" {return MINUS;}
"*" {return STAR;}
"/" {return DIV;}
"&&"    {return AND;}
"||"    {return OR;}
"." {return DOT;}
"!" {return NOT;}
"int"|"float"   {yylval.s = yytext; return TYPE;}
"(" {return LP;}
")" {return RP;}
"[" {return LB;}
"]" {return RB;}
"{" {return LC;}
"}" {return RC;}
"struct"    {return STRUCT;}
"return"    {return RETURN;}
"if"    {return IF;}
"else"  {return ELSE;}
"while" {return WHILE;}
[_a-zA-Z]+[_0-9a-zA-Z]* {yylval.s = strdup(yytext); return ID;}
"//"    {
        char c = input();
        while(c != '\n') c = input();
        }
"/*"	{
		char c;
		while(1){
			c = input();
			if(c == '/'){
				c = input();
				if(c == '*'){
					fprintf(stderr, "Error type B at Line %d: Embedded annotation.\n", yylineno);
					hasSyntaxError = 1;
				}
			}
			else if(c == '*'){
				c = input();
				if(c == '/') break;
			}
		}
		}
[ \t\r\f]    /*ignore whitespace*/
\n
.   {errorA("Mysterious character or word"); hasSyntaxError = 1;} //undefined   

%%

