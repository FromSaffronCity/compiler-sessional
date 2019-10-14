%option noyywrap

%x INSIDE_COMMENT
%x NEXT_OF_STAR

%{
#include<iostream>
#include<string>
#include<fstream>
#include<cstring>
#include<cstdlib>

using namespace std;

#include "1605023_SymbolTable.h"  // NOTICE: this declaration must be here

SymbolTable symbolTable;

FILE* input;
ofstream log;
ofstream token;

int line_count = 1;
int error_count = 0;

string comment = "";

void insertPrint(string symbol, string type) {
	SymbolInfo* symbolInfo = new SymbolInfo(symbol, type);
	
	log << endl;  // NOTICE
	
	if(symbolTable.insertSymbol(*symbolInfo, log) == true) {
			symbolTable.printAll(log);
	}
	
	return ;
}

char lexemeToChar(const char* ptr) {
	if(ptr[1] != '\\') {
		return ptr[1];
	}
	
	if(ptr[1] == '\\') {
		if(ptr[2] == 'n') {
			return (char) 10;
		} else if(ptr[2] == 't') {
			return (char) 9;
		} else if(ptr[2] == 'v') {
			return (char) 11;
		} else if(ptr[2] == 'f') {
			return (char) 12;
		} else if(ptr[2] == 'r') {
			return (char) 13;
		} else if(ptr[2] == 'a') {
			return (char) 7;
		} else if(ptr[2] == 'b') {
			return (char) 8;
		} else if(ptr[2] == '0') {
			return (char) 0;
		} else if(ptr[2] == '\\') {
			return (char) 92;
		} else if(ptr[2] == '\"') {
			return (char) 34;
		} else if(ptr[2] == '\'') {
			return (char) 39;
		} else if(ptr[2] == '?') {
			return (char) 63;
		} else if(ptr[2] == 'e') {
			return (char) 27;
		} else {
			/* most unlikely case */
		}
	}
}

string generateString(const char* ptr) {
	int length = strlen(ptr);
	string str = "";
	
	for(int i=0; i<length; i++) {
		if(ptr[i] != '\\') {
			str.append(1u, ptr[i]); 
		} else {
			if(ptr[i+1] == 'n') {
				str.append(1u, '\n');
			} else if(ptr[i+1] == 't') {
				str.append(1u, '\t');
			} else if(ptr[i+1] == 'v') {
				str.append(1u, '\v');
			} else if(ptr[i+1] == 'f') {
				str.append(1u, '\f');
			} else if(ptr[i+1] == 'r') {
				str.append(1u, '\r');
			} else if(ptr[i+1] == 'a') {
				str.append(1u, '\a');
			} else if(ptr[i+1] == 'b') {
				str.append(1u, '\b');
			} else if(ptr[i+1] == '0') {
				str.append(1u, '\0');
			} else if(ptr[i+1] == '\'') {
				str.append(1u, '\'');
			} else if(ptr[i+1] == '\\') {
				if(ptr[i+2] == '\n') {
					if(ptr[i+3] == 'n') {
						str.append(1u, '\n');
					} else if(ptr[i+3] == 't') {
						str.append(1u, '\t');
					} else if(ptr[i+3] == 'v') {
						str.append(1u, '\v');
					} else if(ptr[i+3] == 'f') {
						str.append(1u, '\f');
					} else if(ptr[i+3] == 'r') {
						str.append(1u, '\r');
					} else if(ptr[i+3] == 'a') {
						str.append(1u, '\a');
					} else if(ptr[i+3] == 'b') {
						str.append(1u, '\b');
					} else if(ptr[i+3] == '0') {
						str.append(1u, '\0');
					} else if(ptr[i+3] == '\\') {
						str.append(1u, '\\');
					} else if(ptr[i+3] == '\"') {
						str.append(1u, '\"');
					} else if(ptr[i+3] == '\'') {
						str.append(1u, '\'');
					} else if(ptr[i+3] == '?') {
						str.append(1u, '\?');
					} else if(ptr[i+3] == 'e') {
						str.append(1u, '\e');
					} else {
						str.append(1u, ptr[i+3]);
					}
					
					i+=3;
					line_count++;
					continue;
				} else {
					str.append(1u, '\\');
				}
			} else if(ptr[i+1] == '\"') {
				str.append(1u, '\"');
			}  else if(ptr[i+1] == '?') {
				str.append(1u, '\?');
			} else if(ptr[i+1] == 'e') {
				str.append(1u, '\e');
			} else if(ptr[i+1] == '\n') {
				line_count++;
			} else {
				str.append(1u, ptr[i+1]);  // NOTICE: warning issue
			}
			
			i++;
		}
	}
	
	return str;
}

void saveComment(const char* ptr) {
	int length = strlen(ptr);
	
	for(int i=0; i<length; i++) {
		comment.append(1u, ptr[i]);
	}
	
	return ;
}

void countLine(const char* ptr) {
	int length = strlen(ptr);
	
	for(int i=0; i<length; i++) {
		if(ptr[i] == '\n') {
			line_count++;
		}
	}
	
	return ;
}

void countLine(string str) {
	for(int i=0; i<str.length(); i++) {
		if(str[i] == '\n') {
			line_count++;
		}
	}
	
	return ;
}

void finishingDimu() {
	log << endl;
	symbolTable.printAll(log);
	symbolTable.exitScope();

	log << "Total Lines: " << --line_count << endl;  // NOTICE: for ubuntu
	log << "Total Errors: " << error_count << endl;
	return ;
}
%}

WHITESPACE [ \t\v\f\r]+
LETTER [A-Za-z]
DIGIT [0-9]
NEWLINE \n


%%


"if"	{
			token << "<IF> ";
			log << "Line no " << line_count << ": Token <IF> Lexeme " << yytext << " found" << endl;
		}
"else"	{
			token << "<ELSE> ";
			log << "Line no " << line_count << ": Token <ELSE> Lexeme " << yytext << " found" << endl;
		}
"for"	{
			token << "<FOR> ";
			log << "Line no " << line_count << ": Token <FOR> Lexeme " << yytext << " found" << endl;
		}
"while"	{
			token << "<WHILE> ";
			log << "Line no " << line_count << ": Token <WHILE> Lexeme " << yytext << " found" << endl;
		}
"do"	{
			token << "<DO> ";
			log << "Line no " << line_count << ": Token <DO> Lexeme " << yytext << " found" << endl;
		}
"break"	{
			token << "<BREAK> ";
			log << "Line no " << line_count << ": Token <BREAK> Lexeme " << yytext << " found" << endl;
		}
"continue"	{
			token << "<CONTINUE> ";
			log << "Line no " << line_count << ": Token <CONTINUE> Lexeme " << yytext << " found" << endl;
		}
"switch"	{
			token << "<SWITCH> ";
			log << "Line no " << line_count << ": Token <SWITCH> Lexeme " << yytext << " found" << endl;
		}
"case"	{
			token << "<CASE> ";
			log << "Line no " << line_count << ": Token <CASE> Lexeme " << yytext << " found" << endl;
		}
"default"	{
			token << "<DEFAULT> ";
			log << "Line no " << line_count << ": Token <DEFAULT> Lexeme " << yytext << " found" << endl;
		}
"int"	{
			token << "<INT> ";
			log << "Line no " << line_count << ": Token <INT> Lexeme " << yytext << " found" << endl;
		}
"char"	{
			token << "<CHAR> ";
			log << "Line no " << line_count << ": Token <CHAR> Lexeme " << yytext << " found" << endl;
		}
"float"	{
			token << "<FLOAT> ";
			log << "Line no " << line_count << ": Token <FLOAT> Lexeme " << yytext << " found" << endl;
		}
"double"	{
			token << "<DOUBLE> ";
			log << "Line no " << line_count << ": Token <DOUBLE> Lexeme " << yytext << " found" << endl;
		}
"void"	{
			token << "<VOID> ";
			log << "Line no " << line_count << ": Token <VOID> Lexeme " << yytext << " found" << endl;
		}
"return"	{
				token << "<RETURN> ";
				log << "Line no " << line_count << ": Token <RETURN> Lexeme " << yytext << " found" << endl;
			}
			
{DIGIT}+	{
			token << "<CONST_INT, " << yytext << "> ";
			log << "Line no " << line_count << ": Token <CONST_INT> Lexeme " << yytext << " found" << endl;
			insertPrint(yytext, "CONST_INT");
		}
({DIGIT}+\.?{DIGIT}*|\.{DIGIT}+)([Ee][+-]?{DIGIT}+)?	{
			token << "<CONST_FLOAT, " << yytext << "> ";
			log << "Line no " << line_count << ": Token <CONST_FLOAT> Lexeme " << yytext << " found" << endl;
			insertPrint(yytext, "CONST_FLOAT");
		}
'([ !-~]{-}['\\])'|'\\[ntvfrab0\\"'?e]'	{
			token << "<CONST_CHAR, " << lexemeToChar(yytext) << "> ";
			log << "Line no " << line_count << ": Token <CONST_CHAR> Lexeme " << yytext << " found" << endl;
			insertPrint(yytext, "CONST_CHAR");
		}
			
"+"|"-"	{
			token << "<ADDOP, " << yytext << "> ";
			log << "Line no " << line_count << ": Token <ADDOP> Lexeme " << yytext << " found" << endl;
			// insertPrint(yytext, "ADDOP");
		}
"*"|"/"|"%"	{
			token << "<MULOP, " << yytext << "> ";
			log << "Line no " << line_count << ": Token <MULOP> Lexeme " << yytext << " found" << endl;
			// insertPrint(yytext, "MULOP");
		}
"++"|"--"	{
			token << "<INCOP, " << yytext << "> ";
			log << "Line no " << line_count << ": Token <INCOP> Lexeme " << yytext << " found" << endl;
			// insertPrint(yytext, "INCOP");
		}
"<"|"<="|">"|">="|"=="|"!="	{
			token << "<RELOP, " << yytext << "> ";
			log << "Line no " << line_count << ": Token <RELOP> Lexeme " << yytext << " found" << endl;
			// insertPrint(yytext, "RELOP");
		}
"="	{
			token << "<ASSIGNOP, " << yytext << "> ";
			log << "Line no " << line_count << ": Token <ASSIGNOP> Lexeme " << yytext << " found" << endl;
			// insertPrint(yytext, "ASSIGNOP");
		}
"&&"|"||"	{
			token << "<LOGICOP, " << yytext << "> ";
			log << "Line no " << line_count << ": Token <LOGICOP> Lexeme " << yytext << " found" << endl;
			// insertPrint(yytext, "LOGICOP");
		}
"&"|"|"|"^"|"<<"|">>"	{
			token << "<BITOP, " << yytext << "> ";
			log << "Line no " << line_count << ": Token <BITOP> Lexeme " << yytext << " found" << endl;
			// insertPrint(yytext, "BITOP");
		}
"!"	{
		token << "<NOT, " << yytext << "> ";
		log << "Line no " << line_count << ": Token <NOT> Lexeme " << yytext << " found" << endl;
		// insertPrint(yytext, "NOT");
	}
"("	{
		token << "<LPAREN, " << yytext << "> ";
		log << "Line no " << line_count << ": Token <LPAREN> Lexeme " << yytext << " found" << endl;
		// insertPrint(yytext, "LPAREN");
	}
")"	{
		token << "<RPAREN, " << yytext << "> ";
		log << "Line no " << line_count << ": Token <RPAREN> Lexeme " << yytext << " found" << endl;
		// insertPrint(yytext, "RPAREN");
	}
"{"	{
		token << "<LCURL, " << yytext << "> ";
		log << "Line no " << line_count << ": Token <LCURL> Lexeme " << yytext << " found" << endl;
		// insertPrint(yytext, "LCURL");
	}
"}"	{
		token << "<RCURL, " << yytext << "> ";
		log << "Line no " << line_count << ": Token <RCURL> Lexeme " << yytext << " found" << endl;
		// insertPrint(yytext, "RCURL");
	}
"["	{
		token << "<LTHIRD, " << yytext << "> ";
		log << "Line no " << line_count << ": Token <LTHIRD> Lexeme " << yytext << " found" << endl;
		// insertPrint(yytext, "LTHIRD");
	}
"]"	{
		token << "<RTHIRD, " << yytext << "> ";
		log << "Line no " << line_count << ": Token <RTHIRD> Lexeme " << yytext << " found" << endl;
		// insertPrint(yytext, "RTHIRD");
	}
","	{
		token << "<COMMA, " << yytext << "> ";
		log << "Line no " << line_count << ": Token <COMMA> Lexeme " << yytext << " found" << endl;
		// insertPrint(yytext, "COMMA");
	}
";"	{
	   	token << "<SEMICOLON, " << yytext << "> ";
		log << "Line no " << line_count << ": Token <SEMICOLON> Lexeme " << yytext << " found" << endl;
		// insertPrint(yytext, "SEMICOLON");
	}
	
[A-Z_a-z][0-9A-Z_a-z]* {
					       token << "<ID, " << yytext << "> ";
						   log << "Line no " << line_count << ": Token <ID> Lexeme " << yytext << " found" << endl;
						   insertPrint(yytext, "ID");	
					   }
					   
\"((([\t !-~]{-}[\\"])*(\\[ntvfrab0\\"'?e])*)*((\\)*(\\\n)))*(([\t !-~]{-}[\\"])*(\\[ntvfrab0\\"'?e])*)*\" {
																log << "Line no " << line_count << ": Token <STRING> Lexeme " << yytext << " found" << endl;
																token << "<STRING, " << generateString(yytext) << "> ";
															}
															
\/\*	{
			BEGIN INSIDE_COMMENT;  // another state starts 
		}
<INSIDE_COMMENT>([\t\n !-~]{-}[\*])* {
					saveComment(yytext);
				}
<INSIDE_COMMENT>\* {
			saveComment(yytext);
			BEGIN NEXT_OF_STAR;
		}
<NEXT_OF_STAR>\/ {
			/* comment finished */
			log << "Line no " << line_count << ": Token <COMMENT> Lexeme " << "/*" << comment << "/" << " found" << endl;
			countLine(comment);
			comment = "";
			BEGIN INITIAL; // another state ends
		}
<NEXT_OF_STAR>\* {
			saveComment(yytext);	
		}
<NEXT_OF_STAR>([\t\n !-~]{-}[\/\*]) {
			saveComment(yytext);
			BEGIN INSIDE_COMMENT;
		}
\/\/([\t !-~]*(\\\n))*([\t !-~]*([\t !-~]{-}[\\]))*	{
				   log << "Line no " << line_count << ": Token <COMMENT> Lexeme " << yytext << " found" << endl;
				   countLine(yytext);
				}

{WHITESPACE}	{/* ignore them */}

{NEWLINE}	{line_count++;}

({DIGIT}+\.?{DIGIT}*|\.{DIGIT}+)(\.+{DIGIT}*)* {
					log << "Error at line " << line_count << ": Too many decimal point " << yytext << endl;
					error_count++;
				}
({DIGIT}+\.?{DIGIT}*|\.{DIGIT}+)(\.+{DIGIT}*)*([Ee][+-]?({DIGIT}+\.?{DIGIT}*|\.{DIGIT}+)(\.+{DIGIT}*)*)* {
					log << "Error at line " << line_count << ": Ill formed number " << yytext << endl;
					error_count++;
				}
[0-9]+[A-Z_a-z][0-9A-Z_a-z]* {
					log << "Error at line " << line_count << ": Invalid prefix on ID or invalid suffix on Number " << yytext << endl;
					error_count++;
				}
''   {
		log << "Error at line " << line_count << ": Empty character constant error " << yytext << endl;
		error_count++;
	}
'\\([\t !-~]{-}[ntvfrab0\\"'e?])'   {
		log << "Error at line " << line_count << ": Unknown escape sequence " << yytext << endl;
		error_count++;
	}
'\t'|'(([\t !-~]{-}['])|(\\'))(([\t !-~]{-}['])|(\\'))+' {
		/* not all cases handled (no single quote is allowed inside) */
		/* tab is considered as multiple space character */
		log << "Error at line " << line_count << ": Multi character constant error " << yytext << endl;
		error_count++;
	}
'((\\')|([\t !-~]{-}[']))*({NEWLINE}) {
		/* not all cases handled (no single quote is allowed inside) */
		/* <<EOF>> is omitted at the end, but works fine */
		log << "Error at line " << line_count << ": Unterminated character " << yytext << endl;
		countLine(yytext);
		error_count++;
	}
\"((([\t !-~]{-}[\\"])*(\\[ntvfrab0\\"'?e])*)*((\\)*(\\\n)))*(([\t !-~]{-}[\\"])*(\\[ntvfrab0\\"'?e])*)*({NEWLINE}) {
		/* <<EOF>> is omitted at the end, but works fine */
		log << "Error at line " << line_count << ": Unterminated String " << yytext << endl;
		countLine(yytext);
		error_count++;
	}
.   {
		log << "Error at line " << line_count << ": Unrecognized character " << yytext << endl;
		error_count++;
	}

<NEXT_OF_STAR><<EOF>> {
			/* unfinished comment lexical error */
			log << "Error at line " << line_count << ": Unterminated comment " << "/*" << comment << endl;
			countLine(comment);
			comment = "";
			error_count++;		
					
			finishingDimu();
			return 0;
		}

<INSIDE_COMMENT><<EOF>> {
			/* unfinished comment lexical error */
			log << "Error at line " << line_count << ": Unterminated comment " << "/*" << comment << endl;
			countLine(comment);
			comment = "";
			error_count++;		
					
			finishingDimu();
			return 0;
		}
	
<INITIAL><<EOF>> {
			finishingDimu();
			return 0;
		}


%%


int main(int argc, char* argv[]) {
	if(argc != 2) {
		cout << "input file name not provided, terminating program..." << endl;
		return 0;
	}
	
	input = fopen(argv[1], "r");
	log.open("1605023_log.txt", ios::out);
	token.open("1605023_token.txt", ios::out);
	
	if(log.is_open() != true) {
		cout << "log file not opened properly, terminating program..." << endl;
		fclose(input);
		
		exit(EXIT_FAILURE);
	}
	
	if(token.is_open() != true) {
		cout << "token file not opened properly, terminating program..." << endl;
		fclose(input);
		log.close();
		
		exit(EXIT_FAILURE);
	}
	
	symbolTable.enterScope(1, 5);  // scopeTable_serial = 1, #bucket_in_scopeTable = 5
	
	yyin = input;
	yylex();  // scanning input
	
	fclose(yyin);
	log.close();
	token.close();
	
	return 0;
} 
