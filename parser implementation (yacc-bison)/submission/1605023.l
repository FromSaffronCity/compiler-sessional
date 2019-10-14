%option noyywrap

%{
#include<iostream>
#include<string>
#include<fstream>

#include "1605023_SymbolTable.h"
#include "y.tab.h"

using namespace std;

void yyerror(char*);  // yyerror() function for generating error message

extern YYSTYPE yylval;  
extern SymbolTable symbolTable;   // NOTICE

extern int line_count;
extern int error_count;  // NOTICE
%}

WHITESPACE [ \t\v\f\r]+
LETTER [A-Za-z]
DIGIT [0-9]
NEWLINE \n


%%


"if" {
	return IF;
}
"else"	{
	return ELSE;
}
"for"	{
	return FOR;
}
"while"	{
	return WHILE;
}
"int"	{
	return INT;
}
"float"	{
	return FLOAT;
}
"void"	{
    return VOID;
}
"return"	{
	return RETURN;
}
"println" {
    return PRINTLN;
}
			
{DIGIT}+	{
    SymbolInfo* symbolInfo = new  SymbolInfo(yytext, "CONST_INT");
    yylval = (YYSTYPE) symbolInfo;
    return CONST_INT;
}
({DIGIT}+\.?{DIGIT}*|\.{DIGIT}+)([Ee][+-]?{DIGIT}+)?	{
    SymbolInfo* symbolInfo = new  SymbolInfo(yytext, "CONST_FLOAT");
    yylval = (YYSTYPE) symbolInfo;
    return CONST_FLOAT;
}
			
"+"|"-"	{
    SymbolInfo* symbolInfo = new  SymbolInfo(yytext, "ADDOP");
    yylval = (YYSTYPE) symbolInfo;
    return ADDOP;
}
"*"|"/"|"%"	{
	SymbolInfo* symbolInfo = new  SymbolInfo(yytext, "MULOP");
    yylval = (YYSTYPE) symbolInfo;
    return MULOP;
}
"++"	{
	return INCOP;
}
"--" {
	return DECOP;
}
"<"|"<="|">"|">="|"=="|"!="	{
	SymbolInfo* symbolInfo = new  SymbolInfo(yytext, "RELOP");
    yylval = (YYSTYPE) symbolInfo;
    return RELOP;
}
"="	{
	return ASSIGNOP;
}
"&&"|"||"	{
	SymbolInfo* symbolInfo = new  SymbolInfo(yytext, "LOGICOP");
    yylval = (YYSTYPE) symbolInfo;
    return LOGICOP;
}
"!"	{
    return NOT;
}
"("	{
    return LPAREN;
}
")"	{
    return RPAREN;
}
"{"	{
    return LCURL;
}
"}"	{
    return RCURL;
}
"["	{
    return LTHIRD;
}
"]"	{
    return RTHIRD;
}
","	{
    return COMMA;
}
";"	{
    return SEMICOLON;
}
	
[A-Z_a-z][0-9A-Z_a-z]* {
	SymbolInfo* symbolInfo = new  SymbolInfo(yytext, "ID");
    yylval = (YYSTYPE) symbolInfo;
    return ID;
 }

{WHITESPACE} {
    /* ignore them */
}

{NEWLINE}	{
    line_count++;
}


%%
