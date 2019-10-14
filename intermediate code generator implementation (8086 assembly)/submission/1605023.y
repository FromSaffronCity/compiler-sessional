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
int scope_count = 0;  // NOTICE

SymbolTable symbolTable;

FILE* input;
ofstream log;
ofstream code;  // contains unoptimized assembly code
ofstream optimized_code;  // contains optimized assembly code

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

int label_count = 0;  // NOTICE, they are for newly introduced functions
int temp_count = 0;

vector<string> data_list;  // for all variables to be declared in data segment
bool can_be_defined = false;  // for function definition (writing assembly codes)
vector<string> local_list;  // for receiving arguments of a function
vector<string> temp_list;  // for sending arguments to a function

/* auxiliary functions */
string insertVar(string _type, var var_in) {
    /* symbolTable insertion for variable and array */
    SymbolInfo* symbolInfo = new SymbolInfo(var_in.var_name, "ID");
    symbolInfo->set_Type(_type);  // setting variable type
    symbolInfo->set_arrSize(var_in.var_size);

    /* additional for setting symbol */
    string str = var_in.var_name, temp;
    stringstream ss;
    ss << scope_count;
    ss >> temp;
    str += temp;
    symbolInfo->setSymbol(str);

    if(var_in.var_size == -1) {
        data_list.push_back(str+(string)" dw ?");  // variable

    } else {
        str += " dw ";
        ss.str("");
        ss.clear();
        ss << var_in.var_size;
        ss >> temp;
        str += temp;
        str += " dup (?)";
        data_list.push_back(str);  // array
    }

    symbolTable.insertSymbol(*symbolInfo);
    return str;
}

void insertFunc(string _type, string name, int _size) {
    /* symbolTable insertion for function(declaration and definition) */
    SymbolInfo* symbolInfo = new SymbolInfo(name, "ID");
    symbolInfo->set_Type(_type);  // setting return type
    symbolInfo->set_arrSize(_size);  // NOTICE: for distinguishing between declaration and definition
    symbolInfo->setSymbol(name);  // NOTICE: setting symbol which will be used to call procedure in assembly code
    
    for(int i=0; i<param_list.size(); i++) {
        symbolInfo->addParam(param_list[i].param_type, param_list[i].param_name);
    }

    symbolTable.insertSymbol(*symbolInfo);
    return ;
}

string newLabel() {
    string str = "L", temp;
    stringstream ss;
    ss << label_count;
    ss >> temp;
    str += temp;
    label_count++;
    return str;
}

string newTemp() {
    string str = "t", temp;
    stringstream ss;
    ss << temp_count;
    ss >> temp;
    str += temp;
    temp_count++;
    return str;
}

void optimizeCode(string code) {
    string temp;
    stringstream ss(code);
    vector<string> tokens, tokens_1, tokens_2;

    while(getline(ss, temp, '\n')) {
        tokens.push_back(temp);
    }

    int line_count = tokens.size();

    for(int i=0; i<line_count; i++) {
        if(i == line_count-1) {
            optimized_code << tokens[i] << endl;
            continue;
        }

        // NOTICE
        if((tokens[i].length() < 4) || (tokens[i+1].length() < 4)) {
            optimized_code << tokens[i] << endl;
            continue;
        }

        if((tokens[i].substr(1,3) == "mov") && (tokens[i+1].substr(1,3) == "mov")) {
            stringstream ss_1(tokens[i]), ss_2(tokens[i+1]);

            while(getline(ss_1, temp, ' ')) {
                tokens_1.push_back(temp);
            }

            while(getline(ss_2, temp, ' ')) {
                tokens_2.push_back(temp);
            }

            /* NOTICE: in this case, tokens_1 and tokens_2 have same size that is same number of strings(3) */
            if((tokens_1[1].substr(0, tokens_1[1].length()-1) == tokens_2[2]) && (tokens_2[1].substr(0, tokens_2[1].length()-1) == tokens_1[2])) {
                optimized_code << tokens[i] << endl;
                i++;  // NOTICE: skipping next line as a part of optimization
            } else {
                optimized_code << tokens[i] << endl;
            }

            tokens_1.clear();
            tokens_2.clear();
        } else {
            optimized_code << tokens[i] << endl;
        }
    }

    tokens.clear();
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
            $$ = new SymbolInfo("", "NON_TERMINAL");

            if(error_count == 0) {
                /* assembly code generation */
                string assembly_code = "";
                assembly_code += (string)".model small\n.stack 100h\n.data\n\n";

                for(int i=0; i<data_list.size(); i++) {
                    assembly_code += (string)"\t"+(string)data_list[i]+(string)"\n";
                }

                data_list.clear();

                /* adding some extra variables */
                assembly_code += (string)"\n\taddress dw 0\n\tdigit_num dw ?\n\tdivisor dw 10000\n\tis_zero_end db 0\n";

                assembly_code += (string)"\n.code\n\n";
                assembly_code += $1->getCode();  // NOTICE

                /* println function */
                assembly_code += (string)"println proc\n\tpop address\n\tpop bx\n";
                assembly_code += (string)"\tcmp bx, 0\n\tjge continue_prog\n\tneg bx\n\tmov ah, 2\n\tmov dl, '-'\n\tint 21h\n\tcontinue_prog"+(string)":\n";
                assembly_code += (string)"\tmov ax, bx\n\txor dx, dx\n";
                assembly_code += (string)"\tfor_out"+(string)":\n\tdiv divisor\n\tmov digit_num, ax\n\tmov bx, dx\n";
                assembly_code += (string)"\tcmp digit_num, 0\n\tjne display\n\tcmp is_zero_end, 0\n\tjne display\n\tcmp divisor, 1\n\tjne continue\n";
                assembly_code += (string)"\tmov ah, 2\n\tmov dx, bx\n\tor dx, 30h\n\tint 21h\n\tjmp end_for_out\n";
                assembly_code += (string)"\tdisplay"+(string)":\n\tmov is_zero_end, 1\n\tmov ah, 2\n\tmov dx, digit_num\n\tor dx, 30h\n\tint 21h\n";        
                assembly_code += (string)"\tcontinue"+(string)":\n\tmov digit_num, bx\n\tcmp divisor, 1\n\tje end_for_out\n";
                assembly_code += (string)"\tmov ax, divisor\n\txor dx, dx\n\tmov bx, 10\n\tdiv bx\n\tmov divisor, ax\n";
                assembly_code += (string)"\tmov ax, digit_num\n\txor dx, dx\n\tjmp for_out\n\tend_for_out"+(string)":\n";
                assembly_code += (string)"\tmov ah, 2\n\tmov dl, 0ah\n\tint 21h\n\tmov dl, 0dh\n\tint 21h\n\tmov divisor, 10000\n\tmov is_zero_end, 0\n";
                assembly_code += (string)"\tpush address\n\tret\nprintln endp\n\n";

                assembly_code += (string)"end main";

                $$->setCode(assembly_code);
                code << $$->getCode() << endl;
                optimizeCode($$->getCode());

            } else {
                /* do nothing */
            }

            /* deletion */
            delete $1;
	}
	    ;

program: program unit {   
            $$ = new SymbolInfo("", "NON_TERMINAL");
            $$->setCode($1->getCode()+$2->getCode());  

            /* deletion */
            delete $1;
            delete $2;
    }
	    | unit {
            $$ = new SymbolInfo("", "NON_TERMINAL");
            $$->setCode($1->getCode());

            /* deletion */
            delete $1;
    }
	    ;
	
unit: var_declaration {
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* deletion */
            delete $1;
    }
        | func_declaration {
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* deletion */
            delete $1;
    }
        | func_definition {
            $$ = new SymbolInfo("", "NON_TERMINAL");
            $$->setCode($1->getCode());

            /* deletion */
            delete $1;
    }
        ;
     
func_declaration: type_specifier id embedded LPAREN parameter_list RPAREN embedded_out_dec SEMICOLON {
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* clearing param_list */
            param_list.clear();

            /* deletion */
            delete $1;
            delete $2;
            delete $5;
    }
        | type_specifier id embedded LPAREN RPAREN embedded_out_dec SEMICOLON {
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* clearing param_list */
            param_list.clear();

            /* deletion */
            delete $1;
            delete $2;
    }
        ;
		 
func_definition: type_specifier id embedded LPAREN parameter_list RPAREN embedded_out_def compound_statement {
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* code setting */
            string temp = "";
            
            if(($2->getName() == "main") && (can_be_defined == true)) {
                temp += (string)"main proc\n\tmov ax, @data\n\tmov ds ,ax\n\n";
                temp += $8->getCode();
                temp += (string)"\n\n\tmov ah, 4ch\n\tint 21h\nmain endp\n\n";

                can_be_defined = false;  // NOTICE

            } else {
                if(can_be_defined == true) {
                    temp += $2->getName()+(string)" proc\n\tpop address\n";

                    for(int i=(local_list.size()-1); i>=0; i--) {
                        temp += (string)"\tpop "+local_list[i]+(string)"\n";
                    }

                    temp += $8->getCode();

                    temp += (string)"\tpush address\n\tret\n";
                    temp += $2->getName()+(string)" endp\n\n";
                }

                can_be_defined = false; // NOTICE
            }

            $$->setCode(temp);
            local_list.clear();  // NOTICE

            /* deletion */
            delete $1;
            delete $2;
            delete $5;
            delete $8;
    }
        | type_specifier id embedded LPAREN RPAREN embedded_out_def compound_statement {
            $$ = new SymbolInfo("", "NON_TERMINAL");
            
            /* code setting */
            string temp = "";
            
            if(($2->getName() == "main") && (can_be_defined == true)) {
                temp += (string)"main proc\n\tmov ax, @data\n\tmov ds ,ax\n\n";
                temp += $7->getCode();
                temp += (string)"\n\n\tmov ah, 4ch\n\tint 21h\nmain endp\n\n";

                can_be_defined = false;  // NOTICE

            } else {
                if(can_be_defined == true) {
                    temp += $2->getName()+(string)" proc\n\tpop address\n";

                    for(int i=(local_list.size()-1); i>=0; i--) {
                        temp += (string)"\tpop "+local_list[i]+(string)"\n";
                    }

                    temp += $7->getCode();

                    temp += (string)"\tpush address\n\tret\n";
                    temp += $2->getName()+(string)" endp\n\n";
                }

                can_be_defined = false; // NOTICE
            }

            $$->setCode(temp);
            local_list.clear();  // NOTICE

            /* deletion */
            delete $1;
            delete $2;
            delete $7;
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
                log << "Error at line no: " << line_count << " multiple declaration of " << name_final << "\n" << endl;
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
                can_be_defined = true;

            } else if(temp->get_arrSize() != -2) {
                /* function declaration not found */
                log << "Error at line no: " << line_count << " multiple declaration of " << name_final << "\n" << endl;
                error_count++;

            } else {
                /* function declaration with similar name found */

                /* further checking */
                if(temp->get_Type() != type_final) {
                    /* return type not matching */
                    log << "Error at line no: " << line_count << " inconsistent function definition with its declaration for " << name_final << "\n" << endl;
                    error_count++;

                } else if(temp->get_paramSize()==1 && param_list.size()==0 && temp->getParam(0).param_type=="void") {
                    /* parameter list matched */
                    temp->set_arrSize(-3);  // NOTICE: given function declaration has a matching definition, so it can be called
                    can_be_defined = true;

                } else if(temp->get_paramSize()==0 && param_list.size()==1 && param_list[0].param_type=="void") {
                    /* parameter list matched */
                    temp->set_arrSize(-3);  // NOTICE: given function declaration has a matching definition, so it can be called
                    can_be_defined = true;

                } else if(temp->get_paramSize() != param_list.size()) {
                    /* parameter list size not matching */
                    log << "Error at line no: " << line_count << " inconsistent function definition with its declaration for " << name_final << "\n" << endl;
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
                        can_be_defined = true;
                        
                    } else {
                        /* parameter list not matched */
                        log << "Error at line no: " << line_count << " inconsistent function definition with its declaration for " << name_final << "\n" << endl;
                        error_count++;
                    }
                }
            }
    }
        ;	

parameter_list: parameter_list COMMA type_specifier id {
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* adding parameter to parameter list */
            temp_parameter.param_type = (string)$3->getName();
            temp_parameter.param_name = (string)$4->getName();

            param_list.push_back(temp_parameter);

            /* deletion */
            delete $1;
            delete $3;
            delete $4;
    }
        | parameter_list COMMA type_specifier {
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* adding parameter to parameter list */
            temp_parameter.param_type = (string)$3->getName();
            temp_parameter.param_name = "";

            param_list.push_back(temp_parameter);

            /* deletion */
            delete $1;
            delete $3;
    }
        | type_specifier id {
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* adding parameter to parameter list */
            temp_parameter.param_type = (string)$1->getName();
            temp_parameter.param_name = (string)$2->getName();

            param_list.push_back(temp_parameter);

            /* deletion */
            delete $1;
            delete $2;
    }
        | type_specifier {
            $$ = new SymbolInfo("", "NON_TERMINAL");  // NOTICE

            /* adding parameter to parameter list */
            temp_parameter.param_type = (string)$1->getName();
            temp_parameter.param_name = "";

            param_list.push_back(temp_parameter);

            /* deletion */
            delete $1;
    }
        ;

compound_statement: LCURL embedded_in statements RCURL {
            $$ = new SymbolInfo("", "NON_TERMINAL");  // NOTICE
            $$->setCode($3->getCode());

            /* additional action */
            symbolTable.exitScope();

            /* deletion */
            delete $3;
    }
        | LCURL embedded_in RCURL {
            $$ = new SymbolInfo("", "NON_TERMINAL");  // NOTICE

            /* additional action */
            symbolTable.exitScope();
    }
        ;

embedded_in: {
            /* NOTICE: embedded action */
            symbolTable.enterScope(++scope_count, 7);   // #bucket_in_each_scopeTable = 7

            /* add parameters (if exists) to symbolTable */
            if(param_list.size()==1 && param_list[0].param_type=="void") {
                /* only parameter is void */
            } else {
                for(int i=0; i<param_list.size(); i++) {
                    temp_var.var_name = param_list[i].param_name;
                    temp_var.var_size = -1;

                    local_list.push_back(insertVar(param_list[i].param_type, temp_var));  // NOTICE
                }
            }

            param_list.clear();  // NOTICE
    }
        ;
 		    
var_declaration: type_specifier declaration_list SEMICOLON {
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* NOTICE: symbolTable insertion*/
            string garbage;

            if($1->getName() == "void") {
                log << "Error at line no: " << line_count << " variable type can not be void " << "\n" << endl;
                error_count++;

                for(int i=0; i<var_list.size(); i++) {
                    insertVar("float", var_list[i]);  // NOTICE: by default, void type variables are float type
                }
            } else {
                for(int i=0; i<var_list.size(); i++) {
                    garbage = insertVar((string)$1->getName(), var_list[i]);  // NOTICE
                }
            }

            var_list.clear();

            /* deletion */
            delete $1;
            delete $2;
    }
 		;
 		 
type_specifier: INT {
            $$ = new SymbolInfo("int", "NON_TERMINAL");
            type = "int";
    }
 		| FLOAT {
            $$ = new SymbolInfo("float", "NON_TERMINAL");
            type = "float";
    }
 		| VOID {
            $$ = new SymbolInfo("void", "NON_TERMINAL");
            type = "void";
    }
 		;

id: ID {
            /* NOTICE */
            $$ = new SymbolInfo((string)$1->getName(), "NON_TERMINAL");
            name = $1->getName();

            /* deletion section */
            delete $1;
    }
        ;
 		
declaration_list: declaration_list COMMA id {
            $$ = new SymbolInfo("", "NON_TERMINAL");  // NOTICE

            /* keeping track of identifier(variable) */
            temp_var.var_name = (string)$3->getName();
            temp_var.var_size = -1;

            var_list.push_back(temp_var);

            /* checking whether already declared or not */
            SymbolInfo* temp = symbolTable.lookUp($3->getName());

            if(temp != NULL) {
                log << "Error at line no: " << line_count << " multiple declaration of " << $3->getName() << "\n" << endl;
                error_count++;
            }

            /* deletion section */
            delete $1;
            delete $3;
    }
 		| declaration_list COMMA id LTHIRD CONST_INT RTHIRD {
             /* array */
            $$ = new SymbolInfo("", "NON_TERMINAL");  // NOTICE

            /* keeping track of identifier(array) */
            temp_var.var_name = (string)$3->getName();

            stringstream temp_str((string) $5->getName());
            temp_str >> temp_var.var_size;

            var_list.push_back(temp_var);

            /* checking whether already declared or not */
            SymbolInfo* temp = symbolTable.lookUp($3->getName());

            if(temp != NULL) {
                log << "Error at line no: " << line_count << " multiple declaration of " << $3->getName() << "\n" << endl;
                error_count++;
            }

            /* deletion section */
            delete $1;
            delete $3;
            delete $5;
    }
 		| id {
            $$ = new SymbolInfo((string)$1->getName(), "NON_TERMINAL");

            /* keeping track of identifier(variable) */
            temp_var.var_name = (string)$1->getName();
            temp_var.var_size = -1;

            var_list.push_back(temp_var);

            /* checking whether already declared or not */
            SymbolInfo* temp = symbolTable.lookUp($1->getName());

            if(temp != NULL) {
                log << "Error at line no: " << line_count << " multiple declaration of " << $1->getName() << "\n" << endl;
                error_count++;
            }

            /* deletion section */
            delete $1;
    }
 		| id LTHIRD CONST_INT RTHIRD {
             /* array */
            $$ = new SymbolInfo((string)$1->getName(), "NON_TERMINAL");  // NOTICE

            /* keeping track of identifier(array) */
            temp_var.var_name = (string)$1->getName();

            stringstream temp_str((string) $3->getName());
            temp_str >> temp_var.var_size;

            var_list.push_back(temp_var);

            /* checking whether already declared or not */
            SymbolInfo* temp = symbolTable.lookUp($1->getName());

            if(temp != NULL) {
                log << "Error at line no: " << line_count << " multiple declaration of " << $1->getName() << "\n" << endl;
                error_count++;
            }

            /* deletion section */
            delete $1;
            delete $3;
    }
 		;
 		  
statements: statement {
            $$ = new SymbolInfo("", "NON_TERMINAL");
            $$->setCode($1->getCode());

            /* deletion section */
            delete $1;
    }
	    | statements statement {
            $$ = new SymbolInfo("", "NON_TERMINAL");
            $$->setCode($1->getCode()+$2->getCode());

            /* deletion section */
            delete $1;
            delete $2;
    }
	    ;
	   
statement: var_declaration {
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* deletion section */
            delete $1;
    }
        | expression_statement {
            $$ = new SymbolInfo("", "NON_TERMINAL");
            $$->setCode($1->getCode());

            /* deletion section */
            delete $1;
    }
        | compound_statement {
            $$ = new SymbolInfo("", "NON_TERMINAL");
            $$->setCode($1->getCode());

            /* deletion section */
            delete $1;
    }
        | FOR LPAREN expression_statement embedded_exp embedded_void expression_statement embedded_exp embedded_void expression embedded_exp embedded_void RPAREN statement {
            /* NOTICE: for loop */
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* code setting */
            if(($3->getSymbol() != ";") && ($6->getSymbol() != ";")) {
                string label1 = newLabel();
                string label2 = newLabel();

                $$->setCode($3->getCode());
                $$->setCode($$->getCode()+(string)"\t"+label1+(string)":\n"+$6->getCode()+(string)"\tmov ax, "+$6->getSymbol()+(string)"\n\tcmp ax, 0\n\tje "+label2+(string)"\n");
                $$->setCode($$->getCode()+$13->getCode()+$9->getCode()+(string)"\tjmp "+label1+(string)"\n\t"+label2+(string)":\n");
            }

            /* deletion */
            delete $3;
            delete $6;
            delete $9;
            delete $13;
    }
        | IF LPAREN expression embedded_exp RPAREN embedded_void statement %prec LOWER_THAN_ELSE {
            /* NOTICE: conflict */
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* code setting */
            string label = newLabel();

            $$->setCode($3->getCode()+(string)"\tmov ax, "+$3->getSymbol()+(string)"\n\tcmp ax, 0\n\tje "+label+(string)"\n"+$7->getCode()+(string)"\t"+label+(string)":\n");

            /* deletion */
            delete $3;
            delete $7;
    }
        | IF LPAREN expression embedded_exp RPAREN embedded_void statement ELSE statement {
            /* NOTICE: conflict */
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* code setting */
            string label1 = newLabel();
            string label2 = newLabel();

            $$->setCode($3->getCode()+(string)"\tmov ax, "+$3->getSymbol()+(string)"\n\tcmp ax, 0\n\tje "+label1+(string)"\n"+$7->getCode()+(string)"\tjmp "+label2+(string)"\n");
            $$->setCode($$->getCode()+(string)"\t"+label1+(string)":\n"+$9->getCode()+(string)"\t"+label2+(string)":\n");

            /* deletion */
            delete $3;
            delete $7;
            delete $9;
    }
        | WHILE LPAREN expression embedded_exp RPAREN embedded_void statement {
            /* NOTICE: while loop */
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* code setting */
            string label1 = newLabel();
            string label2 = newLabel();

            $$->setCode((string)"\t"+label1+(string)":\n"+$3->getCode()+(string)"\tmov ax, "+$3->getSymbol()+(string)"\n\tcmp ax, 0\n\tje "+label2+(string)"\n");
            $$->setCode($$->getCode()+$7->getCode()+(string)"\tjmp "+label1+(string)"\n\t"+label2+(string)":\n");

            /* deletion */
            delete $3;
            delete $7;
    }
        | PRINTLN LPAREN id RPAREN SEMICOLON {
            /* NOTICE: println function */
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* code setting */
            SymbolInfo* temp = symbolTable.lookUpAll($3->getName());
            string input_var;  // symbol/variable in assembly code

            /* id(variable) setting */
            if(temp == NULL) {
                log << "Error at line no : " << line_count << " undeclared variable " << $3->getName() << "\n" << endl;
                error_count++;

                input_var = "";  // no id available

            } else {
                if(temp->get_Type() != "void") {
                    input_var = temp->getSymbol();
                } else {
                    input_var = "";  // no id available
                }
            }

            /* checking whether it is actually variable or not */
            if((temp!=NULL) && (temp->get_arrSize()!=-1)) {
                log << "Error at line no : " << line_count << " type mismatch(not variable)" << "\n" << endl;
                error_count++;

                input_var = "";  // no id available
            }

            /* building code part */
            $$->setCode((string)"\tpush ax\n\tpush bx\n\tpush address\n\tpush "+input_var+(string)"\n\tcall println\n\tpop address\n\tpop bx\n\tpop ax\n");

            /* deletion */
            delete $3;
    }
        | RETURN expression SEMICOLON {
            /* NOTICE: return statement */
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* void checking -> can not return void expression here */
            if($2->get_Type() == "void") {
                /* void function call within expression */
                log << "Error at line no : " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;
            } 

            /* code setting */
            $$->setCode($2->getCode()+(string)"\tpush "+$2->getSymbol()+(string)"\n");  // ret instruction will be written in func_def

            /* deletion */
            delete $2;
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
                log << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
            } 
    }
        ;	
	  
expression_statement: SEMICOLON {
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* type setting -> NOTICE */
            $$->set_Type("int");
            type = "int";

            /* symbol setting */
            $$->setSymbol(";");  // NOTICE -> will be used in for loop
    }		
        | expression SEMICOLON {
            $$ = new SymbolInfo("", "NON_TERMINAL");

           /* type setting */ 
           $$->set_Type($1->get_Type());
           type = $1->get_Type();

           /* symbol and code setting */
           $$->setSymbol($1->getSymbol());
           $$->setCode($1->getCode());

            /* deletion section */
            delete $1;
    }
        ;
	  
variable: id {           
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* declaration checking & type setting */
            SymbolInfo* temp = symbolTable.lookUpAll($1->getName());

            if(temp == NULL) {
                log << "Error at line no: " << line_count << " undeclared variable " << $1->getName() << "\n" << endl;
                error_count++;

                $$->set_arrSize(-1);
                $$->set_Type("float");  // NOTICE: by default, undeclared variables are of float type
            } else {
                $$->set_arrSize(-1);

                if(temp->get_Type() != "void") {
                    $$->set_Type(temp->get_Type());
                    $$->setSymbol(temp->getSymbol());
                } else {
                    $$->set_Type("float");  //matching function found with return type void
                }
            }

            /* checking whether it is id or not */
            if((temp!=NULL) && (temp->get_arrSize()!=-1)) {
                log << "Error at line no: " << line_count << " type mismatch(not variable)" << "\n" << endl;
                error_count++;
            }

            /* deletion section */
            delete $1;
    }
        | id LTHIRD expression RTHIRD {
            /* array */
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* declaration checking & type setting */
            SymbolInfo* temp = symbolTable.lookUpAll($1->getName());

            if(temp == NULL) {
                log << "Error at line no : " << line_count << " undeclared variable " << $1->getName() << "\n" << endl;
                error_count++;

                $$->set_arrSize(0); // NOTICE: undeclared variable size is set to zero
                $$->set_Type("float");  // NOTICE: by default, undeclared variables are of float type
            } else {
                if(temp->get_Type() != "void") {
                    $$->set_arrSize(temp->get_arrSize());
                    $$->set_Type(temp->get_Type());
                    $$->setSymbol(temp->getSymbol());
                } else {
                    $$->set_arrSize(0); // NOTICE: undeclared variable size is set to zero
                    $$->set_Type("float");  //matching function found with return type void
                }
            }

            /* checking whether it is array or not */
            if((temp!=NULL) && (temp->get_arrSize()<=-1)) {
                log << "Error at line no: " << line_count << " type mismatch(not array)" << "\n" << endl;
                error_count++;

                $$->set_arrSize(0); // NOTICE: undeclared variable size is set to zero
                $$->setSymbol("");
            }

            /* semantic analysis (array index checking)  */
            if($3->get_Type() != "int") {
                /* non-integer (floating point) index for array */
                log << "Error at line no: " << line_count << " non-integer array index" << "\n" << endl;
                error_count++;
            }            

            /* void checking  */
            if($3->get_Type() == "void") {
                /* void function call within expression */
                log << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
            } 

            /* symbol and code setting -> might change later */
            $$->setCode($3->getCode()+(string)"\tmov bx, "+$3->getSymbol()+(string)"\n\t"+(string)"add bx, bx"+(string)"\n");

            /* deletion section */
            delete $1;
            delete $3;
    }
        ;
	 
expression: logic_expression {
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* type setting -> NOTICE: semantic analysis might be required -> NOTICE: think about void function */
            $$->set_Type($1->get_Type());
            type = $1->get_Type();

            /* symbol and code setting */
            $$->setSymbol($1->getSymbol());
            $$->setCode($1->getCode());

            /* deletion */
            delete $1;
    }
        | variable ASSIGNOP logic_expression { 
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* void checking  */
            if($3->get_Type() == "void") {
                /* void function call within expression */
                log << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
                $3->set_Type("float");  // by default, float type
            } 

            /* checking type consistency */
            if($1->get_Type() != $3->get_Type()) {
                log << "Error at line no: " << line_count << " type mismatch(" << $1->get_Type() << "=" << $3->get_Type() << ")" << "\n" << endl;
                error_count++;
            }

            /* type setting */
            $$->set_Type($1->get_Type());
            type = $1->get_Type();

            /* symbol and code setting */
            if($1->get_arrSize() > -1) {
                /* array */
                string temp = newTemp();
                data_list.push_back(temp+(string)" dw ?");

                $$->setCode($3->getCode()+$1->getCode()+(string)"\tmov ax, "+$3->getSymbol()+(string)"\n");
                $$->setCode($$->getCode()+(string)"\tmov "+$1->getSymbol()+(string)"[bx], ax\n\tmov "+temp+(string)", ax\n");  // NOTICE -> IMPORTANT
                $$->setSymbol(temp);
            } else {
                /* variable */
                $$->setCode($1->getCode()+$3->getCode()+(string)"\tmov ax, "+$3->getSymbol()+(string)"\n\tmov "+$1->getSymbol()+(string)", ax\n");
                $$->setSymbol($1->getSymbol());
            }

            /* deletion */
            delete $1;
            delete $3;
    }
        ;
			
logic_expression: rel_expression {
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* type setting -> NOTICE: semantic analysis might be required */
            $$->set_Type($1->get_Type());

            /* symbol and code setting */
            $$->setSymbol($1->getSymbol());
            $$->setCode($1->getCode());

            /* deletion */
            delete $1;
    }
        | rel_expression LOGICOP rel_expression {
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* type setting -> NOTICE: semantic analysis (type-casting) might be required */

            /* void checking  */
            if($1->get_Type() == "void") {
                /* void function call within expression */
                log << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
            } 

            if($3->get_Type() == "void") {
                /* void function call within expression */
                log << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
            }

            /* type casting */
            $$->set_Type("int");

            /* symbol and code setting */
            string label1 = newLabel();
            string label2 = newLabel();
            string temp = newTemp();
            data_list.push_back(temp+(string)" dw ?");

            $$->setCode($1->getCode()+$3->getCode());
            
            if($2->getName() == "&&") {
                $$->setCode($$->getCode()+(string)"\tmov ax, "+$1->getSymbol()+(string)"\n\tcmp ax, 0\n\tje "+label1+(string)"\n");
                $$->setCode($$->getCode()+(string)"\tmov ax, "+$3->getSymbol()+(string)"\n\tcmp ax, 0\n\tje "+label1+(string)"\n");
                $$->setCode($$->getCode()+(string)"\tmov ax, 1\n\tmov "+temp+(string)", ax\n\tjmp "+label2+(string)"\n\t");
                $$->setCode($$->getCode()+label1+(string)":\n\tmov ax, 0\n\tmov "+temp+(string)", ax\n\t");
                $$->setCode($$->getCode()+label2+(string)":\n");
            } else {
                /* logicop is "||" */
                $$->setCode($$->getCode()+(string)"\tmov ax, "+$1->getSymbol()+(string)"\n\tcmp ax, 0\n\tjne "+label1+(string)"\n");
                $$->setCode($$->getCode()+(string)"\tmov ax, "+$3->getSymbol()+(string)"\n\tcmp ax, 0\n\tjne "+label1+(string)"\n");
                $$->setCode($$->getCode()+(string)"\tmov ax, 0\n\tmov "+temp+(string)", ax\n\tjmp "+label2+(string)"\n\t");
                $$->setCode($$->getCode()+label1+(string)":\n\tmov ax, 1\n\tmov "+temp+(string)", ax\n\t");
                $$->setCode($$->getCode()+label2+(string)":\n");
            }
            
            $$->setSymbol(temp);

            /* deletion */
            delete $1;
            delete $2;
            delete $3;
    }
        ;
			
rel_expression: simple_expression {
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* type setting -> NOTICE: semantic analysis might be required */
            $$->set_Type($1->get_Type());

            /* symbol and code setting */
            $$->setSymbol($1->getSymbol());
            $$->setCode($1->getCode());

            /* deletion */
            delete $1;
    }
		| simple_expression RELOP simple_expression	{
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* type setting -> NOTICE: semantic analysis (type-casting) might be required */

            /* void checking  */
            if($1->get_Type() == "void") {
                /* void function call within expression */
                log << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
            } 

            if($3->get_Type() == "void") {
                /* void function call within expression */
                log << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
            }

            /* type casting */
            $$->set_Type("int");

            /* symbol and code setting */
            string label1 = newLabel();
            string label2 = newLabel();
            string temp = newTemp();
            data_list.push_back(temp+(string)" dw ?");

            $$->setCode($1->getCode()+$3->getCode()+(string)"\tmov ax, "+$1->getSymbol()+(string)"\n\tcmp ax, "+$3->getSymbol()+(string)"\n");

            if($2->getName() == "<") {
                $$->setCode($$->getCode()+(string)"\tjl "+label1+(string)"\n\tmov ax, 0\n\tmov "+temp+(string)", ax\n\tjmp "+label2+(string)"\n");
                $$->setCode($$->getCode()+(string)"\t"+label1+(string)":\n\tmov ax, 1\n\tmov "+temp+(string)", ax\n\t"+label2+(string)":\n");
            } else if($2->getName() == "<=") {
                $$->setCode($$->getCode()+(string)"\tjle "+label1+(string)"\n\tmov ax, 0\n\tmov "+temp+(string)", ax\n\tjmp "+label2+(string)"\n");
                $$->setCode($$->getCode()+(string)"\t"+label1+(string)":\n\tmov ax, 1\n\tmov "+temp+(string)", ax\n\t"+label2+(string)":\n");
            } else if($2->getName() == ">") {
                $$->setCode($$->getCode()+(string)"\tjg "+label1+(string)"\n\tmov ax, 0\n\tmov "+temp+(string)", ax\n\tjmp "+label2+(string)"\n");
                $$->setCode($$->getCode()+(string)"\t"+label1+(string)":\n\tmov ax, 1\n\tmov "+temp+(string)", ax\n\t"+label2+(string)":\n");
            } else if($2->getName() == ">=") {
                $$->setCode($$->getCode()+(string)"\tjge "+label1+(string)"\n\tmov ax, 0\n\tmov "+temp+(string)", ax\n\tjmp "+label2+(string)"\n");
                $$->setCode($$->getCode()+(string)"\t"+label1+(string)":\n\tmov ax, 1\n\tmov "+temp+(string)", ax\n\t"+label2+(string)":\n");
            } else if($2->getName() == "==") {
                $$->setCode($$->getCode()+(string)"\tje "+label1+(string)"\n\tmov ax, 0\n\tmov "+temp+(string)", ax\n\tjmp "+label2+(string)"\n");
                $$->setCode($$->getCode()+(string)"\t"+label1+(string)":\n\tmov ax, 1\n\tmov "+temp+(string)", ax\n\t"+label2+(string)":\n");
            } else {
                /* relop is "!=" */
                $$->setCode($$->getCode()+(string)"\tjne "+label1+(string)"\n\tmov ax, 0\n\tmov "+temp+(string)", ax\n\tjmp "+label2+(string)"\n");
                $$->setCode($$->getCode()+(string)"\t"+label1+(string)":\n\tmov ax, 1\n\tmov "+temp+(string)", ax\n\t"+label2+(string)":\n");
            }

            $$->setSymbol(temp);

            /* deletion */
            delete $1;
            delete $2;
            delete $3;
    }
		;
				
simple_expression: term {
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* type setting  */
            $$->set_Type($1->get_Type());

            /* symbol and code setting */
            $$->setSymbol($1->getSymbol());
            $$->setCode($1->getCode());

            /* deletion */
            delete $1;
    }
        | simple_expression ADDOP term {
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* type setting -> NOTICE: semantic analysis (type-casting) required  */

            /* void checking  */
            if($1->get_Type() == "void") {
                /* void function call within expression */
                log << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
                $1->set_Type("float");  // by default, float type
            } 

            if($3->get_Type() == "void") {
                /* void function call within expression */
                log << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
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

            /* symbol and code setting */
            string temp = newTemp();
            data_list.push_back(temp+(string)" dw ?");

            if($2->getName() == "+") {
                /* NOTICE : addition */
                $$->setCode($1->getCode()+$3->getCode()+(string)"\tmov ax, "+$1->getSymbol()+(string)"\n\tadd ax, "+$3->getSymbol()+(string)"\n\tmov "+temp+(string)", ax\n");
                $$->setSymbol(temp);

            } else {
                /* NOTICE : subtraction */
                $$->setCode($1->getCode()+$3->getCode()+(string)"\tmov ax, "+$1->getSymbol()+(string)"\n\tsub ax, "+$3->getSymbol()+(string)"\n\tmov "+temp+(string)", ax\n");
                $$->setSymbol(temp);
            }

            /* deletion */
            delete $1;
            delete $2;
            delete $3;
    }
        ;
					
term: unary_expression {
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* type setting  */
            $$->set_Type($1->get_Type());

            /* symbol and code setting */
            $$->setSymbol($1->getSymbol());
            $$->setCode($1->getCode());

            /* deletion */
            delete $1;
    }
        |  term MULOP unary_expression {
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* type setting -> NOTICE: semantic analysis (type-casting, mod-operands checking) required */

            /* void checking  */
            if($1->get_Type() == "void") {
                /* void function call within expression */
                log << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
                $1->set_Type("float");  // by default, float type
            } 

            if($3->get_Type() == "void") {
                /* void function call within expression */
                log << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
                $3->set_Type("float");  // by default, float type
            } 

            /* type setting (with semantic analysis) */
            if(($2->getName() == "%") && ($1->get_Type() != "int" || $3->get_Type() != "int")) {
                /* type-checking for mod operator */
                log << "Error at line no: " << line_count << " operand type mismatch for modulus operator" << "\n" << endl;
                error_count++;

                $$->set_Type("int");  // type-conversion
            } else if(($2->getName() != "%") && ($1->get_Type() == "float" || $3->get_Type() == "float")) {
                $$->set_Type("float");  // type-conversion
            } else {
                $$->set_Type($1->get_Type());
            }

            /* symbol and code setting */
            string temp = newTemp();
            data_list.push_back(temp+(string)" dw ?");

            if($2->getName() == "*") {
                /* NOTICE : multiplication */
                $$->setCode($1->getCode()+$3->getCode()+(string)"\tmov ax, "+$1->getSymbol()+(string)"\n\tmov bx, "+$3->getSymbol()+(string)"\n\timul bx\n\tmov "+temp+(string)", ax\n");
                $$->setSymbol(temp);

            } else {
                /* NOTICE : division or mod */
                $$->setCode($1->getCode()+$3->getCode()+(string)"\tmov ax, "+$1->getSymbol()+(string)"\n\tcwd\n");
                $$->setCode($$->getCode()+(string)"\tmov bx, "+$3->getSymbol()+(string)"\n\tidiv bx\n");
                
                if($2->getName() == "/") {
                    $$->setCode($$->getCode()+(string)"\tmov "+temp+(string)", ax\n");  // division
                } else {
                    $$->setCode($$->getCode()+(string)"\tmov "+temp+(string)", dx\n");  // mod
                }
                
                $$->setSymbol(temp);
            }

            /* deletion */
            delete $1;
            delete $2;
            delete $3;
    }
        ;

unary_expression: ADDOP unary_expression {
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* void checking  */
            if($2->get_Type() == "void") {
                /* void function call within expression */
                log << "Error at line no: " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
                $$->set_Type("float");  // by default, float type
            } else {
                /* type setting */
                $$->set_Type($2->get_Type());
            }

            /* symbol and code setting */
            if($1->getName() == "-") {
                /* negative number */
                string temp = newTemp();
                data_list.push_back(temp+(string)" dw ?");

                $$->setCode($2->getCode()+(string)"\tmov ax, "+$2->getSymbol()+(string)"\n\tmov "+temp+(string)", ax\n\tneg "+temp+(string)"\n");
                $$->setSymbol(temp);
            } else {
                /* positive number */
                $$->setSymbol($2->getSymbol());
                $$->setCode($2->getCode());
            }

            /* deletion */
            delete $1;
            delete $2;
    }  
        | NOT unary_expression {
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* void checking */
            if($2->get_Type() == "void") {
                /* void function call within expression */
                log << "Error at line no : " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
            }

            /* type casting */
            $$->set_Type("int");

            /* symbol and code setting */
            string label1 = newLabel();
            string label2 = newLabel();
            string temp = newTemp();
            data_list.push_back(temp+(string)" dw ?");

            $$->setCode($2->getCode()+(string)"\tmov ax, "+$2->getSymbol()+(string)"\n\tcmp ax, 0\n\tje "+label1+(string)"\n\tmov ax, 0\n\tmov "+temp+(string)", ax\n\tjmp "+label2+(string)"\n");
            $$->setCode($$->getCode()+(string)"\t"+label1+(string)": \n\tmov ax, 1\n\tmov "+temp+(string)", ax\n\t"+label2+(string)":\n");

            $$->setSymbol(temp);

            /* deletion */
            delete $2;
    }
        | factor {
            $$ = new SymbolInfo("", "NON_TERMINAL");

            /* type setting */
            $$->set_Type($1->get_Type());

            /* symbol and code setting */
            $$->setSymbol($1->getSymbol());
            $$->setCode($1->getCode());

            /* deletion */
            delete $1;
    }
        ;
	
factor: variable {
            $$ = new SymbolInfo("", "NON_TERMINAL");  

            /* variable or array */
            $$->set_arrSize($1->get_arrSize());

            /* type setting */
            $$->set_Type($1->get_Type());

            /* symbol and code setting */
            $$->setSymbol($1->getSymbol());
            $$->setCode($1->getCode());

            /* NOTICE */
            if($$->get_arrSize() > -1) {
                /* array */
                string temp = newTemp();
                data_list.push_back(temp+(string)" dw ?");

                $$->setCode($$->getCode()+(string)"\tmov ax, "+$1->getSymbol()+(string)"[bx]\n\tmov "+temp+(string)", ax\n");
                $$->setSymbol(temp);
            }

            /* deletion section */
            delete $1;
    }
        | id LPAREN argument_list RPAREN {
            /* NOTICE: function call */
            $$ = new SymbolInfo("", "NON_TERMINAL");  
            bool is_valid = false;

            /* type setting -> NOTICE: semantic analysis (matching argument_list with parameter_list) required */
            SymbolInfo* temp = symbolTable.lookUpAll($1->getName());

            if(temp == NULL) {
                /* no such id found */
                log << "Error at line no : " << line_count << " no such identifier found" << "\n" << endl;
                error_count++;

                $$->set_Type("float");  // NOTICE: by default, float type

            } else if(temp->get_arrSize() != -3) {
                /* no such function definition found */
                log << "Error at line no: " << line_count << " no such function definition found" << "\n" << endl;
                error_count++;

                $$->set_Type("float");  // NOTICE: by default, float type

            } else {
                /* matching argument with parameter list */
                if(temp->get_paramSize()==1 && arg_list.size()==0 && temp->getParam(0).param_type=="void") {
                    /* consistent function call & type setting */
                    $$->set_Type(temp->get_Type());
                    is_valid = true;

                } else if(temp->get_paramSize() != arg_list.size()) {
                    /* inconsistent function call */
                    log << "Error at line no: " << line_count << " inconsistent function call" << "\n" << endl;
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
                        log << "Error at line no: " << line_count << " inconsistent function call" << "\n" << endl;
                        error_count++;

                        $$->set_Type("float");  // NOTICE: by default, float type

                    } else {
                        /* consistent function call & type setting */
                        $$->set_Type(temp->get_Type());
                        is_valid = true;
                    }
                }
            }

            if(is_valid == true) {
                string _temp = newTemp();
                data_list.push_back(_temp+(string)" dw ?");

                $$->setCode($3->getCode());
                $$->setCode($$->getCode()+(string)"\tpush ax\n\tpush bx\n\tpush address\n");

                for(int i=0; i<temp_list.size(); i++) {
                    $$->setCode($$->getCode()+(string)"\tpush "+temp_list[i]+(string)"\n");
                }

                $$->setCode($$->getCode()+(string)"\tcall "+temp->getSymbol()+(string)"\n");

                if(temp->get_Type() != "void") {
                    $$->setCode($$->getCode()+(string)"\tpop "+_temp+(string)"\n");
                }

                $$->setCode($$->getCode()+(string)"\tpop address\n\tpop bx\n\tpop ax\n");
                $$->setSymbol(_temp);
            }

            arg_list.clear();  // NOTICE
            temp_list.clear();  // NOTICE

            /* deletion */
            delete $1;
            delete $3;
    }
        | LPAREN expression RPAREN {
            $$ = new SymbolInfo("", "NON_TERMINAL");  
            $$->setSymbol($2->getSymbol());
            $$->setCode($2->getCode());

            /* void checking  */
            if($2->get_Type() == "void") {
                /* void function call within expression */
                log << "Error at line no : " << line_count << " void function called within expression" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
                $2->set_Type("float");  // by default, float type
            } 

            /* type setting */
            $$->set_Type($2->get_Type());

            /* deletion section */
            delete $2;
    }
        | CONST_INT { 
            $$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
            $$->setSymbol($1->getName());  // NOTICE

            /* type setting */
            $$->set_Type("int");

            /* deletion section */
            delete $1;
    }
        | CONST_FLOAT {
            $$ = new SymbolInfo($1->getName(), "NON_TERMINAL");
            $$->setSymbol($1->getName());  // NOTICE

            /* type setting */
            $$->set_Type("float");

            /* deletion section */
            delete $1;
    }
        | variable INCOP {
            $$ = new SymbolInfo("", "NON_TERMINAL");  

            /* type setting */
            $$->set_Type($1->get_Type());

            /* symbol and code setting */
            string temp1;

            if($1->get_arrSize() > -1) {
                /* array */
                temp1 = newTemp();
                data_list.push_back(temp1+(string)" dw ?");
                $$->setCode($1->getCode()+(string)"\tmov ax, "+$1->getSymbol()+(string)"[bx]\n\tmov "+temp1+(string)", ax\n");
                $$->setCode($$->getCode()+(string)"\tinc "+$1->getSymbol()+(string)"[bx]\n");

                $$->setSymbol(temp1);

            } else {
                /* variable */
                temp1 = newTemp();
                data_list.push_back(temp1+(string)" dw ?");
                $$->setCode($1->getCode()+(string)"\tmov ax, "+$1->getSymbol()+(string)"\n\tmov "+temp1+(string)", ax\n\tinc "+$1->getSymbol()+(string)"\n");

                $$->setSymbol(temp1);
            }

            /* deletion section */
            delete $1;
    }
        | variable DECOP {
            $$ = new SymbolInfo("", "NON_TERMINAL");  

            /* type setting */
            $$->set_Type($1->get_Type());

            /* symbol and code setting */
            string temp1;

            if($1->get_arrSize() > -1) {
                /* array */
                temp1 = newTemp();
                data_list.push_back(temp1+(string)" dw ?");
                $$->setCode($1->getCode()+(string)"\tmov ax, "+$1->getSymbol()+(string)"[bx]\n\tmov "+temp1+(string)", ax\n");
                $$->setCode($$->getCode()+(string)"\tdec "+$1->getSymbol()+(string)"[bx]\n");

                $$->setSymbol(temp1);

            } else {
                /* variable */
                temp1 = newTemp();
                data_list.push_back(temp1+(string)" dw ?");
                $$->setCode($1->getCode()+(string)"\tmov ax, "+$1->getSymbol()+(string)"\n\tmov "+temp1+(string)", ax\n\tdec "+$1->getSymbol()+(string)"\n");

                $$->setSymbol(temp1);
            }

            /* deletion section */
            delete $1;
    }
        ;
	
argument_list: arguments {
            $$ = new SymbolInfo("", "NON_TERMINAL");  

            /* code setting */
            $$->setCode($1->getCode());

            /* deletion */
            delete $1;
    }
        | {
            /* NOTICE: epsilon-production */
            $$ = new SymbolInfo("", "NON_TERMINAL");  
    }
        ;
	
arguments: arguments COMMA logic_expression {
            $$ = new SymbolInfo("", "NON_TERMINAL"); 

            /* code setting */
            $$->setCode($1->getCode()+$3->getCode()); 

            /* void checking  */
            if($3->get_Type() == "void") {
                /* void function call within argument of function */
                log << "Error at line no : " << line_count << " void function called within argument of function" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
                $3->set_Type("float");  // by default, float type
            } 

            /* keeping track of encountered argument */
            arg_list.push_back($3->get_Type());

            /* keeping track of arguments sent */
            temp_list.push_back($3->getSymbol());

            /* deletion */
            delete $1;
            delete $3;
    }
        | logic_expression {  
            $$ = new SymbolInfo("", "NON_TERMINAL"); 

            /* code setting */
            $$->setCode($1->getCode()); 

            /* void checking  */
            if($1->get_Type() == "void") {
                /* void function call within argument of function */
                log << "Error at line no : " << line_count << " void function called within argument of function" << "\n" << endl;
                error_count++;

                /* type setting (if necessary) */
                $1->set_Type("float");  // by default, float type
            } 

            /* keeping track of encountered argument */
            arg_list.push_back($1->get_Type());

            /* keeping track of arguments sent */
            temp_list.push_back($1->getSymbol());

            /* deletion */
            delete $1;
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
	
	if(log.is_open() != true) {
		cout << "log file not opened properly, terminating program..." << endl;
		fclose(input);
		
		exit(EXIT_FAILURE);
	}

    code.open("1605023_code.asm", ios::out);
	
	if(code.is_open() != true) {
		cout << "code file not opened properly, terminating program..." << endl;
		fclose(input);
		log.close();
		
		exit(EXIT_FAILURE);
	}

    optimized_code.open("1605023_optimized_code.asm", ios::out);
	
	if(optimized_code.is_open() != true) {
		cout << "optimized code file not opened properly, terminating program..." << endl;
		fclose(input);
		log.close();
        code.close();
		
		exit(EXIT_FAILURE);
	}
	
	symbolTable.enterScope(++scope_count, 7);   // #bucket_in_each_scopeTable = 7
	
	yyin = input;
    yyparse();  // processing starts

    log << endl;

	log << "Total Lines: " << (--line_count) << endl;  // NOTICE here: line_count changed (July 19) -> works for sample
	log << "\n" << "Total Errors: " << error_count << endl;

    if(error_count > 0) {
        code << "error found in input code" << endl;
        optimized_code << "error found in input code" << endl;
    }
	
	fclose(yyin);
	log.close();
	code.close();
    optimized_code.close();
	
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