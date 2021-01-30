# compiler-sessional
offline/assignment programs coded for the course **Compilers Sessional (CSE-310)**.  
## navigation  
### offline-1
```symbol table implementation``` contains implementation of a symbol table with basic functionalities written in _C++_.  
- ```symbol table implementation/submission/1605023_main.cpp``` is the symbol table code  
### offline-2  
```scanner implementation (flex)``` contains implementation of a lexical analyzer/scanner for specified tokens written in _flex_.  
- ```scanner implementation (flex)/submission/1605023_SymbolTable.h``` is the header file for symbol table  
- ```scanner implementation (flex)/submission/1605023.l``` is the lex file for scanner  
- run ```scanner implementation (flex)/submission/script.sh``` with specified input file  
### offline-3
```parser implementation (yacc-bison)``` contains implementation of a syntactic analyzer/parser for specified grammers written in _yacc/bison_.  
- ```parser implementation (yacc-bison)/submission/1605023_SymbolTable.h``` is the header file for symbol table  
- ```parser implementation (yacc-bison)/submission/1605023.l``` is the lex file for scanner  
- ```parser implementation (yacc-bison)/submission/1605023.y``` is the yacc file for parser (also semantic analyzer)  
- run ```parser implementation (yacc-bison)/submission/run.sh``` with specified input file  
### offline-4
```intermediate code generator implementation (8086 assembly)``` contains implementation of an intermediate code generator from _C_ codes to _intel8086 assembly language_ codes for a specified sets of tokens and grammers.
- ```intermediate code generator implementation (8086 assembly)/submission/1605023_SymbolTable.h``` is the header file for symbol table  
- ```intermediate code generator implementation (8086 assembly)/submission/1605023.l``` is the lex file for scanner  
- ```intermediate code generator implementation (8086 assembly)/submission/1605023.y``` is the yacc file for parser (also semantic analyzer and converter)  
- run ```parser implementation (yacc-bison)/submission/run.sh``` with specified input file  
