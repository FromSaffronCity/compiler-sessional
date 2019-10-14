%{
#include<iostream>
#include<string>
#include<sstream>
#include<fstream>
#include<cstdlib>
#include<vector>
#include "1605023_SymbolTable.h"

using namespace std;

int yyparse(void);
int yylex(void);

extern FILE* yyin;

int line_count = 1;  // NOTICE
int error_count = 0;
int scope_count = 1;

SymbolTable symbolTable;

FILE* input;
ofstream log;
ofstream error;

/* auxiliary variables and structures and containers */
string type, type_final;  // basially for function declaration-definition
string name, name_final;  // basically for function declaration-definition

struct var{
    string var_name;
    int var_size;  // it is set to -1 for variables
} temp_var;

vector<var> var_list;  // for identifier(variable, array) insertion into symbolTable

struct parameter {
    string param_type;
    string param_name;  // it is set to empty string "" for function declaration
} temp_parameter;

vector<parameter> param_list;  // parameter list for function declaration, definition

vector<string> arg_list;  // argument list for function call

/* auxiliary functions */
void insertVar(string _type, var var_in) {
    /* symbolTable insertion for variable and array */
    SymbolInfo* symbolInfo = new SymbolInfo(var_in.var_name, "ID");
    symbolInfo->set_Type(_type);  // setting variable type
    symbolInfo->set_arrSize(var_in.var_size);

    symbolTable.insertSymbol(*symbolInfo);
    return ;
}

void insertFunc(string _type, string name, int _size) {
    /* symbolTable insertion for function(declaration and definition) */
    SymbolInfo* symbolInfo = new SymbolInfo(name, "ID");
    symbolInfo->set_Type(_type);  // setting return type
    symbolInfo->set_arrSize(_size);  // NOTICE: for distinguishing between declaration and definition
    
    for(int i=0; i<param_list.size(); i++) {
        symbolInfo->addParam(param_list[i].param_type, param_list[i].param_name);
    }

    symbolTable.insertSymbol(*symbolInfo);
    return ;
}

/* yyerror function for reporting syntax error */
void yyerror(char*); 
%}

%define api.value.type {SymbolInfo*}

%token CONST_INT CONST_FLOAT ID
%token INT FLOAT VOID IF ELSE FOR WHILE PRINTLN RETURN
%token ASSIGNOP NOT INCOP DECOP LOGICOP RELOP ADDOP MULOP
%token LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON 

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE


%%


start: program {
            $$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
            log << "At line no: " << (line_count-1) << " start: program" << "\n"  << endl;  // NOTICE here: line_count changed (July 19) -> works for sample
            log << $1->getName() << "\n"  << endl;
	}
	    ;

program: program unit {   
            $$ = new SymbolInfo((string)$1->getName()+(string)$2->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " program: program unit" << "\n"  << endl;
            log << (string)$1->getName()+(string)$2->getName() << "\n"  << endl;
    }
	    | unit {
            $$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " program: unit" << "\n"  << endl;
            log << $1->getName() << "\n"  << endl;
    }
	    ;
	
unit: var_declaration {
            $$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " unit: var_declaration" << "\n"  << endl;
            log << $1->getName() << "\n"  << endl;
    }
        | func_declaration {
            $$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " unit: func_declaration" << "\n"  << endl;
            log << $1->getName() << "\n"  << endl;
    }
        | func_definition {
            $$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " unit: func_definition" << "\n"  << endl;
            log << $1->getName() << "\n"  << endl;
    }
        ;
     
func_declaration: type_specifier id embedded LPAREN parameter_list RPAREN embedded_out_dec SEMICOLON {
            $$ = new SymbolInfo((string)$1->getName()+(string)" "+(string)$2->getName()+(string)"("+(string)$5->getName()+(string)")"+(string)";"+(string)"\n"+(string)"\n", "NON_TERMINAL");
            log << "At line no: " << line_count << " func_declaration: type_specifier ID LPAREN parameter_list RPAREN SEMICOLON" << "\n"  << endl;
            log << (string)$1->getName()+(string)" "+(string)$2->getName()+(string)"("+(string)$5->getName()+(string)")"+(string)";" << "\n"  << endl;

            /* clearing param_list */
            param_list.clear();
    }
        | type_specifier id embedded LPAREN RPAREN embedded_out_dec SEMICOLON {
            $$ = new SymbolInfo((string)$1->getName()+(string)" "+(string)$2->getName()+(string)"("+(string)")"+(string)";"+(string)"\n"+(string)"\n", "NON_TERMINAL");
            log << "At line no: " << line_count << " func_declaration: type_specifier ID LPAREN RPAREN SEMICOLON" << "\n"  << endl;
            log << (string)$1->getName()+(string)" "+(string)$2->getName()+(string)"("+(string)")"+(string)";" << "\n"  << endl;

            /* clearing param_list */
            param_list.clear();
    }
        ;
		 
func_definition: type_specifier id embedded LPAREN parameter_list RPAREN embedded_out_def compound_statement {
            $$ = new SymbolInfo((string)$1->getName()+(string)" "+(string)$2->getName()+(string)"("+(string)$5->getName()+(string)")"+(string)$8->getName()+(string)"\n"+(string)"\n", "NON_TERMINAL");
            log << "At line no: " << line_count << " func_definition: type_specifier ID LPAREN parameter_list RPAREN compound_statement" << "\n"  << endl;
            log << (string)$1->getName()+(string)" "+(string)$2->getName()+(string)"("+(string)$5->getName()+(string)")"+(string)$8->getName() << "\n"  << endl;
    }
        | type_specifier id embedded LPAREN RPAREN embedded_out_def compound_statement {
            $$ = new SymbolInfo((string)$1->getName()+(string)" "+(string)$2->getName()+(string)"("+(string)")"+(string)$7->getName()+(string)"\n"+(string)"\n", "NON_TERMINAL");
            log << "At line no: " << line_count << " func_definition: type_specifier ID LPAREN RPAREN compound_statement" << "\n"  << endl;
            log << (string)$1->getName()+(string)" "+(string)$2->getName()+(string)"("+(string)")"+(string)$7->getName() << "\n"  << endl;
    }
        ;		

embedded: {
            /* NOTICE: embedded action */
            type_final = type;
            name_final = name;
    }
        ;	

embedded_out_dec: {
            /* NOTICE: embedded action */
            SymbolInfo* temp = symbolTable.lookUpAll(name_final);

            if(temp != NULL) {
                error << "Error at line no: " << line_count << " multiple declaration of " << name_final << "\n" << endl;
                error_count++;
            } else {
                /* inserting function declaration in symbolTable */
                insertFunc(type_final, name_final, -2);
            }
    }
        ;		

embedded_out_def: {
            /* NOTICE: embedded action */
            SymbolInfo* temp = symbolTable.lookUpAll(name_final);

            if(temp == NULL) {
                /* inserting function definition in symbolTable */
                insertFunc(type_final, name_final, -3);

            } else if(temp->get_arrSize() != -2) {
                /* function declaration not found */
                error << "Error at line no: " << line_count << " multiple declaration of " << name_final << "\n" << endl;
                error_count++;

            } else {
                /* function declaration with similar name found */

                /* further checking */
                if(temp->get_Type() != type_final) {
                    /* return type not matching */
                    error << "Error at line no: " << line_count << " inconsistent function definition with its declaration for " << name_final << "\n" << endl;
                    error_count++;

                } else if(temp->get_paramSize()==1 && param_list.size()==0 && temp->getParam(0).param_type=="void") {
                    /* parameter list matched */
                    temp->set_arrSize(-3);  // NOTICE: given function declaration has a matching definition, so it can be called

                } else if(temp->get_paramSize()==0 && param_list.size()==1 && param_list[0].param_type=="void") {
                    /* parameter list matched */
                    temp->set_arrSize(-3);  // NOTICE: given function declaration has a matching definition, so it can be called

                } else if(temp->get_paramSize() != param_list.size()) {
                    /* parameter list size not matching */
                    error << "Error at line no: " << line_count << " inconsistent function definition with its declaration for " << name_final << "\n" << endl;
                    error_count++;

                } else {
                    /* checking parameter type */
                    int i;

                    for(i=0; i<param_list.size(); i++) {
                        if(temp->getParam(i).param_type != param_list[i].param_type) {
                            break;
                        }
                    }

                    if(i == param_list.size()) {
                        /* parameter list matched */
                        temp->set_arrSize(-3);  // NOTICE: given function declaration has a matching definition, so it can be called
                    } else {
                        /* parameter list not matched */
                        error << "Error at line no: " << line_count << " inconsistent function definition with its declaration for " << name_final << "\n" << endl;
                        error_count++;
                    }
                }
            }
    }
        ;	

parameter_list: parameter_list COMMA type_specifier id {
            $$ = new SymbolInfo((string)$1->getName()+(string)","+(string)$3->getName()+(string)" "+(string)$4->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " parameter_list: parameter_list COMMA type_specifier ID" << "\n"  << endl;
            log << (string)$1->getName()+(string)", "+(string)$3->getName()+(string)$4->getName() << "\n"  << endl;

            /* adding parameter to parameter list */
            temp_parameter.param_type = (string)$3->getName();
            temp_parameter.param_name = (string)$4->getName();

            param_list.push_back(temp_parameter);
    }
        | parameter_list COMMA type_specifier {
            $$ = new SymbolInfo((string)$1->getName()+(string)","+(string)$3->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " parameter_list: parameter_list COMMA type_specifier" << "\n"  << endl;
            log << (string)$1->getName()+(string)", "+(string)$3->getName() << "\n"  << endl;

            /* adding parameter to parameter list */
            temp_parameter.param_type = (string)$3->getName();
            temp_parameter.param_name = "";

            param_list.push_back(temp_parameter);
    }
        | type_specifier id {
            $$ = new SymbolInfo((string)$1->getName()+(string)" "+(string)$2->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " parameter_list: type_specifier ID" << "\n"  << endl;
            log << (string)$1->getName()+(string)$2->getName() << "\n"  << endl;

            /* adding parameter to parameter list */
            temp_parameter.param_type = (string)$1->getName();
            temp_parameter.param_name = (string)$2->getName();

            param_list.push_back(temp_parameter);
    }
        | type_specifier {
            $$ = new SymbolInfo((string)$1->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " parameter_list: type_specifier" << "\n"  << endl;
            log << (string)$1->getName() << "\n"  << endl;

            /* adding parameter to parameter list */
            temp_parameter.param_type = (string)$1->getName();
            temp_parameter.param_name = "";

            param_list.push_back(temp_parameter);
    }
        ;

compound_statement: LCURL embedded_in statements RCURL {
            $$ = new SymbolInfo((string)"{ "+(string)"\n"+(string)$3->getName()+(string)"}"+(string)"\n", "NON_TERMINAL");  // NOTICE
            log << "At line no: " << line_count << " compound_statement: LCURL statements RCURL" << "\n"  << endl;
            log << (string)"{ \n"+(string)$3->getName()+(string)"\n}" << "\n"  << endl;

            /* additional action */
            symbolTable.printAll(log);
            symbolTable.exitScope(log);
    }
        | LCURL embedded_in RCURL {
            $$ = new SymbolInfo((string)"{ "+(string)"\n"+(string)"\n"+(string)"}"+(string)"\n", "NON_TERMINAL");  // NOTICE
            log << "At line no: " << line_count << " compound_statement: LCURL RCURL" << "\n"  << endl;
            log << (string)"{ "+(string)"}" << "\n"  << endl;

            /* additional action */
            symbolTable.printAll(log);
            symbolTable.exitScope(log);
    }
        ;

embedded_in: {
            /* NOTICE: embedded action */
            symbolTable.enterScope(scope_count++, 7, log);   // #bucket_in_each_scopeTable = 7

            /* add parameters (if exists) to symbolTable */
            if(param_list.size()==1 && param_list[0].param_type=="void") {
                /* only parameter is void */
            } else {
                for(int i=0; i<param_list.size(); i++) {
                    temp_var.var_name = param_list[i].param_name;
                    temp_var.var_size = -1;

                    insertVar(param_list[i].param_type, temp_var);
                }
            }

            param_list.clear();  // NOTICE
    }
        ;
 		    
var_declaration: type_specifier declaration_list SEMICOLON {
            $$ = new SymbolInfo((string)$1->getName()+(string)" "+(string)$2->getName()+(string)";"+(string)"\n"+(string)"\n", "NON_TERMINAL");
            log << "At line no: " << line_count << " var_declaration: type_specifier declaration_list SEMICOLON" << "\n"  << endl;
            log << (string)$1->getName()+(string)" "+(string)$2->getName()+(string)";" << "\n"  << endl;

            /* NOTICE: symbolTable insertion*/
            if($1->getName() == "void") {
                error << "Error at line no: " << line_count << " variable type can not be void " << "\n" << endl;
                error_count++;

                for(int i=0; i<var_list.size(); i++) {
                    insertVar("float", var_list[i]);  // NOTICE: by default, void type variables are float type
                }
            } else {
                for(int i=0; i<var_list.size(); i++) {
                    insertVar((string)$1->getName(), var_list[i]);
                }
            }

            var_list.clear();
    }
 		;
 		 
type_specifier: INT {
            $$ = new SymbolInfo("int", "NON_TERMINAL");
            log << "At line no: " << line_count << " type_specifier: INT" << "\n"  << endl;
            log << "int" << "\n"  << endl;

            type = "int";
    }
 		| FLOAT {
            $$ = new SymbolInfo("float", "NON_TERMINAL");
            log << "At line no: " << line_count << " type_specifier: FLOAT" << "\n"  << endl;
            log << "float" << "\n"  << endl;

            type = "float";
    }
 		| VOID {
            $$ = new SymbolInfo("void", "NON_TERMINAL");
            log << "At line no: " << line_count << " type_specifier: VOID" << "\n"  << endl;
            log << "void" << "\n"  << endl;

            type = "void";
    }
 		;

id: ID {
            $$ = new SymbolInfo((string)$1->getName(), "NON_TERMINAL");
            name = $1->getName();
    }
        ;
 		
declaration_list: declaration_list COMMA id {
            $$ = new SymbolInfo((string)$1->getName()+(string)","+(string)$3->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " declaration_list: declaration_list COMMA ID" << "\n"  << endl;
            log << (string)$1->getName()+(string)" , "+(string)$3->getName() << "\n"  << endl;

            /* keeping track of identifier(variable) */
            temp_var.var_name = (string)$3->getName();
            temp_var.var_size = -1;

            var_list.push_back(temp_var);

            /* checking whether already declared or not */
            SymbolInfo* temp = symbolTable.lookUp($3->getName());

            if(temp != NULL) {
                error << "Error at line no: " << line_count << " multiple declaration of " << $3->getName() << "\n" << endl;
                error_count++;
            }
    }
 		| declaration_list COMMA id LTHIRD CONST_INT RTHIRD {
             /* array */
            $$ = new SymbolInfo((string)$1->getName()+(string)","+(string)$3->getName()+(string)"["+(string)$5->getName()+(string)"]", "NON_TERMINAL");
            log << "At line no: " << line_count << " declaration_list: declaration_list COMMA ID LTHIRD CONST_INT RTHIRD" << "\n"  << endl;
            log << (string)$1->getName()+(string)" , "+(string)$3->getName()+(string)"["+(string)$5->getName()+(string)"]" << "\n"  << endl;

            /* keeping track of identifier(array) */
            temp_var.var_name = (string)$3->getName();

            stringstream temp_str((string) $5->getName());
            temp_str >> temp_var.var_size;

            var_list.push_back(temp_var);

            /* checking whether already declared or not */
            SymbolInfo* temp = symbolTable.lookUp($3->getName());

            if(temp != NULL) {
                error << "Error at line no: " << line_count << " multiple declaration of " << $3->getName() << "\n" << endl;
                error_count++;
            }
    }
 		| id {
            $$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " declaration_list: ID" << "\n"  << endl;
            log << $1->getName() << "\n"  << endl;

            /* keeping track of identifier(variable) */
            temp_var.var_name = (string)$1->getName();
            temp_var.var_size = -1;

            var_list.push_back(temp_var);

            /* checking whether already declared or not */
            SymbolInfo* temp = symbolTable.lookUp($1->getName());

            if(temp != NULL) {
                error << "Error at line no: " << line_count << " multiple declaration of " << $1->getName() << "\n" << endl;
                error_count++;
            }
    }
 		| id LTHIRD CONST_INT RTHIRD {
             /* array */
            $$ = new SymbolInfo((string)$1->getName()+(string)"["+(string)$3->getName()+(string)"]", "NON_TERMINAL");
            log << "At line no: " << line_count << " declaration_list: ID LTHIRD CONST_INT RTHIRD" << "\n"  << endl;
            log << (string)$1->getName()+(string)"["+(string)$3->getName()+(string)"]" << "\n"  << endl;

            /* keeping track of identifier(array) */
            temp_var.var_name = (string)$1->getName();

            stringstream temp_str((string) $3->getName());
            temp_str >> temp_var.var_size;

            var_list.push_back(temp_var);

            /* checking whether already declared or not */
            SymbolInfo* temp = symbolTable.lookUp($1->getName());

            if(temp != NULL) {
                error << "Error at line no: " << line_count << " multiple declaration of " << $1->getName() << "\n" << endl;
                error_count++;
            }
    }
 		;
 		  
statements: statement {
            $$ = new SymbolInfo((string)$1->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " statements: statement" << "\n"  << endl;
            log << (string)$1->getName() << "\n"  << endl;
    }
	    | statements statement {
            $$ = new SymbolInfo((string)$1->getName()+(string)$2->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " statements: statements statement" << "\n"  << endl;
            log << (string)$1->getName()+(string)$2->getName() << "\n"  << endl;
    }
	    ;
	   
statement: var_declaration {
            $$ = new SymbolInfo((string)"\t"+(string)$1->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " statement: var_declaration" << "\n"  << endl;
            log << $1->getName() << "\n"  << endl;
    }
        | expression_statement {
            $$ = new SymbolInfo((string)$1->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " statement: expression_statement" << "\n"  << endl;
            log << (string)$1->getName() << "\n"  << endl;
    }
        | compound_statement {
            $$ = new SymbolInfo((string)"\t"+(string)$1->getName()+(string)"\n", "NON_TERMINAL");
            log << "At line no: " << line_count << " statement: compound_statement" << "\n"  << endl;
            log << (string)$1->getName() << "\n"  << endl;
    }
        | FOR LPAREN expression_statement embedded_exp embedded_void expression_statement embedded_exp embedded_void expression embedded_exp embedded_void RPAREN statement {
            /* for this loop, the output in log will be a bit distorted for adding +(string)"\n" in expression_statement */
            $$ = new SymbolInfo((string)"\t"+(string)"for"+(string)"("+(string)$3->getName()+(string)$6->getName()+(string)$9->getName()+(string)")"+(string)$13->getName()+(string)"\n", "NON_TERMINAL");
            log << "At line no: " << line_count << " statement: FOR LPAREN expression_statement expression_statement expression RPAREN statement" << "\n"  << endl;
            log << (string)"for"+(string)"("+(string)$3->getName()+(string)$6->getName()+(string)$9->getName()+(string)")"+(string)$13->getName() << "\n"  << endl;
    }
        | IF LPAREN expression embedded_exp RPAREN embedded_void statement %prec LOWER_THAN_ELSE {
            /* NOTICE: conflict */
            $$ = new SymbolInfo((string)"\t"+(string)"if"+(string)"("+(string)$3->getName()+(string)")"+(string)$7->getName()+(string)"\n", "NON_TERMINAL");
            log << "At line no: " << line_count << " statement: IF LPAREN expression RPAREN statement" << "\n"  << endl;
            log << (string)"if"+(string)"("+(string)$3->getName()+(string)")"+(string)$7->getName() << "\n"  << endl;
    }
        | IF LPAREN expression embedded_exp RPAREN embedded_void statement ELSE statement {
            /* NOTICE: conflict */
            $$ = new SymbolInfo((string)"\t"+(string)"if"+(string)"("+(string)$3->getName()+(string)")"+(string)$7->getName()+(string)" else"+(string)$9->getName()+(string)"\n", "NON_TERMINAL");
            log << "At line no: " << line_count << " statement: IF LPAREN expression RPAREN statement ELSE statement" << "\n"  << endl;
            log << (string)"if"+(string)"("+(string)$3->getName()+(string)")"+(string)$7->getName()+(string)" else"+(string)$9->getName() << "\n"  << endl;
    }
        | WHILE LPAREN expression embedded_exp RPAREN embedded_void statement {
            $$ = new SymbolInfo((string)"\t"+(string)"while"+(string)"("+(string)$3->getName()+(string)")"+(string)$7->getName()+(string)"\n", "NON_TERMINAL");
            log << "At line no: " << line_count << " statement: WHILE LPAREN expression RPAREN statement" << "\n"  << endl;
            log << (string)"while"+(string)"("+(string)$3->getName()+(string)")"+(string)$7->getName() << "\n"  << endl;
    }
        | PRINTLN LPAREN id RPAREN SEMICOLON {
            $$ = new SymbolInfo((string)"\t"+(string)"println"+(string)"("+(string)$3->getName()+(string)")"+(string)";"+(string)"\n", "NON_TERMINAL");
            log << "At line no: " << line_count << " statement: PRINTLN LPAREN ID RPAREN SEMICOLON" << "\n"  << endl;
            log << (string)"println"+(string)"("+(string)$3->getName()+(string)")"+(string)";" << "\n"  << endl;
    }
        | RETURN expression SEMICOLON {
            $$ = new SymbolInfo((string)"\t"+(string)"return "+(string)$2->getName()+(string)";"+(string)"\n", "NON_TERMINAL");
            log << "At line no: " << line_count << " statement: RETURN expression SEMICOLON" << "\n"  << endl;
            log << (string)"return "+(string)$2->getName()+(string)";" << "\n"  << endl;

            /* void checking -> can not return void expression here */
            if($2->get_Type() == "void") {
                /* void function call within expression */
                error << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
            } 
    }
        ;

embedded_exp: {
            /* NOTICE: embedded action */
            type_final = type;
    }
        ;	

embedded_void: {
            /* NOTICE: embedded action */
            
            /* void checking  */
            if(type_final == "void") {
                /* void function call within expression */
                error << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
            } 
    }
        ;	
	  
expression_statement: SEMICOLON {
            $$ = new SymbolInfo((string)"\t"+(string)";"+(string)"\n", "NON_TERMINAL");
            log << "At line no: " << line_count << " expression_statement: SEMICOLON" << "\n"  << endl;
            log << ";" << "\n"  << endl;

            /* type setting -> NOTICE */
            $$->set_Type("int");
            type = "int";
    }		
        | expression SEMICOLON {
            $$ = new SymbolInfo((string)"\t"+(string)$1->getName()+(string)";"+(string)"\n", "NON_TERMINAL");
            log << "At line no: " << line_count << " expression_statement: expression SEMICOLON" << "\n"  << endl;
            log << (string)$1->getName()+(string)";" << "\n"  << endl;

           /* type setting */ 
           $$->set_Type($1->get_Type());
           type = $1->get_Type();
    }
        ;
	  
variable: id {
            $$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " variable: ID" << "\n"  << endl;
            log << $1->getName() << "\n"  << endl;           

            /* declaration checking & type setting */
            SymbolInfo* temp = symbolTable.lookUpAll($1->getName());

            if(temp == NULL) {
                error << "Error at line no: " << line_count << " undeclared variable " << $1->getName() << "\n" << endl;
                error_count++;

                $$->set_Type("float");  // NOTICE: by default, undeclared variables are of float type
            } else {
                if(temp->get_Type() != "void") {
                    $$->set_Type(temp->get_Type());
                } else {
                    $$->set_Type("float");  //matching function found with return type void
                }
            }

            /* checking whether it is id or not */
            if((temp!=NULL) && (temp->get_arrSize()!=-1)) {
                error << "Error at line no: " << line_count << " type mismatch(not variable)" << "\n" << endl;
                error_count++;
            }
    }
        | id LTHIRD expression RTHIRD {
            /* array */
            $$ = new SymbolInfo((string)$1->getName()+(string)"["+(string)$3->getName()+(string)"]", "NON_TERMINAL");
            log << "At line no: " << line_count << " variable: ID LTHIRD expression RTHIRD" << "\n"  << endl;
            log << (string)$1->getName()+(string)"["+(string)$3->getName()+(string)"]" << "\n"  << endl;

            /* declaration checking & type setting */
            SymbolInfo* temp = symbolTable.lookUpAll($1->getName());

            if(temp == NULL) {
                error << "Error at line no: " << line_count << " undeclared variable " << $1->getName() << "\n" << endl;
                error_count++;

                $$->set_Type("float");  // NOTICE: by default, undeclared variables are of float type
            } else {
                if(temp->get_Type() != "void") {
                    $$->set_Type(temp->get_Type());
                } else {
                    $$->set_Type("float");  //matching function found with return type void
                }
            }

            /* checking whether it is array or not */
            if((temp!=NULL) && (temp->get_arrSize()<=-1)) {
                error << "Error at line no: " << line_count << " type mismatch(not array)" << "\n" << endl;
                error_count++;
            }

            /* semantic analysis (array index checking)  */
            if($3->get_Type() != "int") {
                /* non-integer (floating point) index for array */
                error << "Error at line no: " << line_count << " non-integer array index" << "\n" << endl;
                error_count++;
            }            

            /* void checking  */
            if($3->get_Type() == "void") {
                /* void function call within expression */
                error << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
            } 
    }
        ;
	 
expression: logic_expression {
            $$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " expression: logic_expression" << "\n"  << endl;
            log << $1->getName() << "\n"  << endl;  

            /* type setting -> NOTICE: semantic analysis might be required -> NOTICE: think about void function */
            $$->set_Type($1->get_Type());
            type = $1->get_Type();
    }
        | variable ASSIGNOP logic_expression {
            $$ = new SymbolInfo((string)$1->getName()+(string)" = "+(string)$3->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " expression: variable ASSIGNOP logic_expression" << "\n"  << endl;
            log << (string)$1->getName()+(string)" = "+(string)$3->getName() << "\n"  << endl;  

            /* void checking  */
            if($3->get_Type() == "void") {
                /* void function call within expression */
                error << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
                $3->set_Type("float");  // by default, float type
            } 

            /* checking type consistency */
            if($1->get_Type() != $3->get_Type()) {
                error << "Error at line no: " << line_count << " type mismatch(" << $1->get_Type() << "=" << $3->get_Type() << ")" << "\n" << endl;
                error_count++;
            }

            /* type setting */
            $$->set_Type($1->get_Type());
            type = $1->get_Type();
    }
        ;
			
logic_expression: rel_expression {
            $$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " logic_expression: rel_expression" << "\n"  << endl;
            log << $1->getName() << "\n"  << endl;  

            /* type setting -> NOTICE: semantic analysis might be required */
            $$->set_Type($1->get_Type());
    }
        | rel_expression LOGICOP rel_expression {
            $$ = new SymbolInfo((string)$1->getName()+(string)$2->getName()+(string)$3->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " logic_expression: rel_expression LOGICOP rel_expression" << "\n"  << endl;
            log << (string)$1->getName()+(string)$2->getName()+(string)$3->getName() << "\n"  << endl; 

            /* type setting -> NOTICE: semantic analysis (type-casting) might be required */

            /* void checking  */
            if($1->get_Type() == "void") {
                /* void function call within expression */
                error << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
            } 

            if($3->get_Type() == "void") {
                /* void function call within expression */
                error << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
            }

            /* type casting */
            $$->set_Type("int");
    }
        ;
			
rel_expression: simple_expression {
            $$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " rel_expression: simple_expression" << "\n"  << endl;
            log << $1->getName() << "\n"  << endl;  

            /* type setting -> NOTICE: semantic analysis might be required */
            $$->set_Type($1->get_Type());
    }
		| simple_expression RELOP simple_expression	{
            $$ = new SymbolInfo((string)$1->getName()+(string)$2->getName()+(string)$3->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " rel_expression: simple_expression RELOP simple_expression" << "\n"  << endl;
            log << (string)$1->getName()+(string)$2->getName()+(string)$3->getName() << "\n"  << endl; 

            /* type setting -> NOTICE: semantic analysis (type-casting) might be required */

            /* void checking  */
            if($1->get_Type() == "void") {
                /* void function call within expression */
                error << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
            } 

            if($3->get_Type() == "void") {
                /* void function call within expression */
                error << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
            }

            /* type csting */
            $$->set_Type("int");
    }
		;
				
simple_expression: term {
            $$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " simple_expression: term" << "\n"  << endl;
            log << $1->getName() << "\n"  << endl;  

            /* type setting  */
            $$->set_Type($1->get_Type());
    }
        | simple_expression ADDOP term {
            $$ = new SymbolInfo((string)$1->getName()+(string)$2->getName()+(string)$3->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " simple_expression: simple_expression ADDOP term" << "\n"  << endl;
            log << (string)$1->getName()+(string)$2->getName()+(string)$3->getName() << "\n"  << endl; 

            /* type setting -> NOTICE: semantic analysis (type-casting) required  */

            /* void checking  */
            if($1->get_Type() == "void") {
                /* void function call within expression */
                error << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
                $1->set_Type("float");  // by default, float type
            } 

            if($3->get_Type() == "void") {
                /* void function call within expression */
                error << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
                $3->set_Type("float");  // by default, float type
            }

            /* type setting (with type casting if required) */
            if($1->get_Type()=="float" || $3->get_Type()=="float") {
                $$->set_Type("float");
            } else {
                $$->set_Type($1->get_Type());  // basically, int
            }
    }
        ;
					
term: unary_expression {
            $$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " term: unary_expression" << "\n"  << endl;
            log << $1->getName() << "\n"  << endl;  

            /* type setting  */
            $$->set_Type($1->get_Type());
    }
        |  term MULOP unary_expression {
            $$ = new SymbolInfo((string)$1->getName()+(string)$2->getName()+(string)$3->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " term: term MULOP unary_expression" << "\n"  << endl;
            log << (string)$1->getName()+(string)$2->getName()+(string)$3->getName() << "\n"  << endl; 

            /* type setting -> NOTICE: semantic analysis (type-casting, mod-operands checking) required */

            /* void checking  */
            if($1->get_Type() == "void") {
                /* void function call within expression */
                error << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
                $1->set_Type("float");  // by default, float type
            } 

            if($3->get_Type() == "void") {
                /* void function call within expression */
                error << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
                $3->set_Type("float");  // by default, float type
            } 

            /* type setting (with semantic analysis) */
            if(($2->getName() == "%") && ($1->get_Type() != "int" || $3->get_Type() != "int")) {
                /* type-checking for mod operator */
                error << "Error at line no: " << line_count << " operand type mismatch for modulus operator" << "\n" << endl;
                error_count++;

                $$->set_Type("int");  // type-conversion
            } else if(($2->getName() != "%") && ($1->get_Type() == "float" || $3->get_Type() == "float")) {
                $$->set_Type("float");  // type-conversion
            } else {
                $$->set_Type($1->get_Type());
            }
    }
        ;

unary_expression: ADDOP unary_expression {
            $$ = new SymbolInfo((string)$1->getName()+(string)$2->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " unary_expression: ADDOP unary_expression" << "\n"  << endl;
            log << (string)$1->getName()+(string)$2->getName() << "\n"  << endl; 

            /* void checking  */
            if($2->get_Type() == "void") {
                /* void function call within expression */
                error << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
                $$->set_Type("float");  // by default, float type
            } else {
                /* type setting */
                $$->set_Type($2->get_Type());
            }
    }  
        | NOT unary_expression {
            $$ = new SymbolInfo((string)"!"+(string)$2->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " unary_expression: NOT unary_expression" << "\n"  << endl;
            log << (string)"!"+(string)$2->getName() << "\n"  << endl;  

            /* void checking */
            if($2->get_Type() == "void") {
                /* void function call within expression */
                error << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
            }

            /* type casting */
            $$->set_Type("int");
    }
        | factor {
            $$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " unary_expression: factor" << "\n"  << endl;
            log << $1->getName() << "\n"  << endl;  

            /* type setting */
            $$->set_Type($1->get_Type());
    }
        ;
	
factor: variable {
            $$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " factor: variable" << "\n"  << endl;
            log << $1->getName() << "\n"  << endl;  

            /* type setting */
            $$->set_Type($1->get_Type());
    }
        | id LPAREN argument_list RPAREN {
            $$ = new SymbolInfo((string)$1->getName()+(string)"("+(string)$3->getName()+(string)")", "NON_TERMINAL");
            log << "At line no: " << line_count << " factor: ID LPAREN argument_list RPAREN" << "\n"  << endl;
            log << (string)$1->getName()+(string)"("+(string)$3->getName()+(string)")" << "\n"  << endl;

            /* type setting -> NOTICE: semantic analysis (matching argument_list with parameter_list) required */
            SymbolInfo* temp = symbolTable.lookUpAll($1->getName());

            if(temp == NULL) {
                /* no such id found */
                error << "Error at line no: " << line_count << " no such identifier found" << "\n" << endl;
                error_count++;

                $$->set_Type("float");  // NOTICE: by default, float type

            } else if(temp->get_arrSize() != -3) {
                /* no such function definition found */
                error << "Error at line no: " << line_count << " no such function definition found" << "\n" << endl;
                error_count++;

                $$->set_Type("float");  // NOTICE: by default, float type

            } else {
                /* matching argument with parameter list */
                if(temp->get_paramSize()==1 && arg_list.size()==0 && temp->getParam(0).param_type=="void") {
                    /* consistent function call & type setting */
                    $$->set_Type(temp->get_Type());

                } else if(temp->get_paramSize() != arg_list.size()) {
                    /* inconsistent function call */
                    error << "Error at line no: " << line_count << " inconsistent function call" << "\n" << endl;
                    error_count++;

                    $$->set_Type("float");  // NOTICE: by default, float type

                } else {
                    int i;

                    for(i=0; i<arg_list.size(); i++) {
                        if(temp->getParam(i).param_type != arg_list[i]) {
                            break;
                        }
                    }

                    if(i != arg_list.size()) {
                        /* inconsistent function call */
                        error << "Error at line no: " << line_count << " inconsistent function call" << "\n" << endl;
                        error_count++;

                        $$->set_Type("float");  // NOTICE: by default, float type

                    } else {
                        /* consistent function call & type setting */
                        $$->set_Type(temp->get_Type());
                    }
                }
            }

            arg_list.clear();  // NOTICE
    }
        | LPAREN expression RPAREN {
            $$ = new SymbolInfo((string)"("+(string)$2->getName()+(string)")", "NON_TERMINAL");
            log << "At line no: " << line_count << " factor: LPAREN expression RPAREN" << "\n"  << endl;
            log << (string)"("+(string)$2->getName()+(string)")" << "\n"  << endl;

            /* void checking  */
            if($2->get_Type() == "void") {
                /* void function call within expression */
                error << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
                $2->set_Type("float");  // by default, float type
            } 

            /* type setting */
            $$->set_Type($2->get_Type());
    }
        | CONST_INT {
            $$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " factor: CONST_INT" << "\n"  << endl;
            log << $1->getName() << "\n"  << endl;  

            /* type setting */
            $$->set_Type("int");
    }
        | CONST_FLOAT {
            $$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " factor: CONST_FLOAT" << "\n"  << endl;
            log << $1->getName() << "\n"  << endl;  

            /* type setting */
            $$->set_Type("float");
    }
        | variable INCOP {
            $$ = new SymbolInfo((string)$1->getName()+(string)"++", "NON_TERMINAL");
            log << "At line no: " << line_count << " factor: variable INCOP" << "\n"  << endl;
            log << (string)$1->getName()+(string)"++" << "\n"  << endl; 

            /* type setting */
            $$->set_Type($1->get_Type());
    }
        | variable DECOP {
            $$ = new SymbolInfo((string)$1->getName()+(string)"--", "NON_TERMINAL");
            log << "At line no: " << line_count << " factor: variable DECOP" << "\n"  << endl;
            log << (string)$1->getName()+(string)"--" << "\n"  << endl; 

            /* type setting */
            $$->set_Type($1->get_Type());
    }
        ;
	
argument_list: arguments {
            $$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " argument_list: arguments" << "\n"  << endl;
            log << $1->getName() << "\n"  << endl;  
    }
        | {
            /* NOTICE: epsilon-production */
            $$ = new SymbolInfo("", "NON_TERMINAL");
            log << "At line no: " << line_count << " argument_list: <epsilon-production>" << "\n"  << endl;
            log << "" << "\n"  << endl;  
    }
        ;
	
arguments: arguments COMMA logic_expression {
            $$ = new SymbolInfo((string)$1->getName()+(string)", "+(string)$3->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " arguments: arguments COMMA logic_expression" << "\n"  << endl;
            log << (string)$1->getName()+(string)", "+(string)$3->getName() << "\n"  << endl;  

            /* void checking  */
            if($3->get_Type() == "void") {
                /* void function call within argument of function */
                error << "Error at line no: " << line_count << " void function called within argument of function" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
                $3->set_Type("float");  // by default, float type
            } 

            /* keeping track of encountered argument */
            arg_list.push_back($3->get_Type());
    }
        | logic_expression {
            $$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
            log << "At line no: " << line_count << " arguments: logic_expression" << "\n"  << endl;
            log << $1->getName() << "\n"  << endl;  

            /* void checking  */
            if($1->get_Type() == "void") {
                /* void function call within argument of function */
                error << "Error at line no: " << line_count << " void function called within argument of function" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
                $1->set_Type("float");  // by default, float type
            } 

            /* keeping track of encountered argument */
            arg_list.push_back($1->get_Type());
    }
        ;
 

%%


int main(int argc, char* argv[]) {
	if(argc != 2) {
		cout << "input file name not provided, terminating program..." << endl;
		return 0;
	}

    input = fopen(argv[1], "r");

    if(input == NULL) {
		cout << "input file not opened properly, terminating program..." << endl;
		exit(EXIT_FAILURE);
	}

	log.open("1605023_log.txt", ios::out);
	error.open("1605023_error.txt", ios::out);
	
	if(log.is_open() != true) {
		cout << "log file not opened properly, terminating program..." << endl;
		fclose(input);
		
		exit(EXIT_FAILURE);
	}
	
	if(error.is_open() != true) {
		cout << "error file not opened properly, terminating program..." << endl;
		fclose(input);
		log.close();
		
		exit(EXIT_FAILURE);
	}
	
	symbolTable.enterScope(scope_count++, 7, log);   // #bucket_in_each_scopeTable = 7
	
	yyin = input;
    yyparse();  // processing starts

    log << endl;
	symbolTable.printAll(log);
	symbolTable.exitScope(log);

	log << "Total Lines: " << (--line_count) << endl;  // NOTICE here: line_count changed (July 19) -> works for sample
	log << "\n" << "Total Errors: " << error_count << endl;
    error << "\n" << "Total Errors: " << error_count << endl;
	
	fclose(yyin);
	log.close();
	error.close();
	
	return 0;
} 

void yyerror(char* s) {
    /* it may be modified later */
    log << "At line no: " << line_count << " " << s << endl;

    line_count++;
    error_count++;
    
    return ;
}

/*
    yaccFile=1605023.y
    lexFile=1605023.l
    inputFile=input.txt
    ####################################################################
    #Created by Mir Mahathir Mohammad 1605011
    ####################################################################
    DIR="$(cd "$(dirname "$0")" && pwd)"
    cd $DIR
    bison -d -y -v ./$yaccFile
    g++ -w -c -o ./y.o ./y.tab.c
    flex -o ./lex.yy.c ./$lexFile
    g++ -fpermissive -w -c -o ./l.o ./lex.yy.c
    g++ -o ./a.out ./y.o ./l.o -lfl -ly	
    ./a.out ./input.txt
*/