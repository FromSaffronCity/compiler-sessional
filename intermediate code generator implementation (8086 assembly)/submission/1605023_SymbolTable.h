#include<iostream>
#include<string>
#include<vector>

using namespace std;


class SymbolInfo {
    string name;  
    string type;

    SymbolInfo* next;

    /* additional info (variable, array, function) */
    string _type;  // for variable and array and function(return type)
    int _size;  // array size for array; (-1=variable, -2=function_declaration, -3=function_definition)

    struct param {
        string param_type;
        string param_name;
    } temp_param;
    
    vector<param> param_list;  // parameter list for function declaration, definition

    string symbol; // NOTICE: for assembly code symbol
    string code;  // NOTICE: for assembly code propagation

public:
    SymbolInfo() {
        /* nothing here */
    }

    SymbolInfo(string name, string type) {
        this->name = name;
        this->type = type;

        next = NULL;
        symbol = code = "";  // NOTICE
    }

    void setName(string name) {
        this->name = name;
        return ;
    }

    string getName() const {
        return name;
    }

    string getType() const {
        return type;
    }

    void setNext(SymbolInfo* next) {
        this->next = next;
        return ;
    }

    SymbolInfo* getNext() const {
        return next;
    }

   ~SymbolInfo() {
        /* nothing here */
        param_list.clear();
    }

    /* additional functionalities */
    void set_Type(string _type) {
        this->_type = _type;
        return ;
    }

    string get_Type() const {
        return _type;
    }

    void set_arrSize(int _size) {
        /* basically for array */
        this->_size = _size;
        return ;
    }

    int get_arrSize() const {
        /* basically for array */
        return _size;
    }

    int get_paramSize() const {
        /* basically for function */
        return param_list.size();
    }

    void addParam(string param_type, string param_name) {
        temp_param.param_type = param_type;
        temp_param.param_name = param_name;

        param_list.push_back(temp_param);
        return ;
    }

    param getParam(int index) const {
        return param_list[index];
    }

    void setSymbol(string symbol) {
        this->symbol = symbol;
        return ;
    }

    string getSymbol() const {
        return symbol;
    }

    void setCode(string code) {
        this->code = code;
        return ;
    }

    string getCode() const {
        return code;
    }
};


class ScopeTable {
    int id;
    int length;

    SymbolInfo** bucketList;
    ScopeTable* parentScope;

   int hashFunction(string key) {
        int hashedValue = 0;

        for(int i=0; i<key.length(); i++) {
            hashedValue += ((int)key[i] + i*(int)key[i]);  // NOTICE
        }

        return (hashedValue%length);
    } 

public:
    ScopeTable() {
        /* nothing here */
    }

    ScopeTable(int id, int length, ScopeTable* parentScope) {
        this->id = id;
        this->length = length;

        bucketList = new SymbolInfo*[length];

        for(int i=0; i<length; i++) {
            bucketList[i] = NULL;
        }

        this->parentScope = parentScope;
    }

    int getID() const {
        return id;
    }

    int getlength() const {
        return length;
    }

    ScopeTable* getParentScope() const {
        return parentScope;
    }

    ~ScopeTable() {
        delete[] bucketList;
    }

    /* main functionalities */
    SymbolInfo* lookUp(string key) {
        int index = hashFunction(key);
        int position = 0;

        SymbolInfo* temp = bucketList[index];

        while(temp != NULL) {
            if(key == temp->getName()) {
                return temp;
            }

            position++;
            temp = temp->getNext();
        }

        return NULL;  // NOTICE
    }

    bool insertSymbol(SymbolInfo& symbol) {
        if(lookUp(symbol.getName()) != NULL) {
            return false;
        }

        int index = hashFunction(symbol.getName());
        SymbolInfo* temp = bucketList[index];

        if(temp == NULL) {
            bucketList[index] = &symbol;
            symbol.setNext(NULL);
            return true;
        }

        while(temp->getNext() != NULL) {
            temp = temp->getNext();
        }

        temp->setNext(&symbol);
        symbol.setNext(NULL);

        return true;
    }

    bool deleteSymbol(string key) {
        if(lookUp(key) == NULL) {
            return false;
        }

        int index = hashFunction(key);
        SymbolInfo* temp = bucketList[index];
        SymbolInfo* previous = NULL;

        while(temp != NULL) {
            if(key == temp->getName()) {
                break;
            }

            previous = temp;
            temp = temp->getNext();
        }

        if(previous == NULL) {
            bucketList[index] = temp->getNext();
        } else {
            previous->setNext(temp->getNext());
        }

        delete temp;  // NOTICE - IMPORTANT AF
        return true;
    }

    void print() const {
        for(int i=0; i<length; i++) {
            if(bucketList[i] == NULL) {
                continue;
            }

            SymbolInfo* temp = bucketList[i];

            while(temp != NULL) {
                temp = temp->getNext();
            }
        }

        return ;
    }
};


class SymbolTable {
    ScopeTable* current;

public:
    SymbolTable() {
        current = NULL;
    }

    ~SymbolTable() {
        /* nothing here */
    }

    /* main functionalities */
    void enterScope(int id, int length) {
        ScopeTable* temp = new ScopeTable(id, length, current);
        current = temp;

        return ;
    }

    void exitScope() {
        if(current == NULL) {
            return ;
        }

        current = current->getParentScope();
        return ;
    }

    bool insertSymbol(SymbolInfo& symbol) {
        if(current == NULL) {
            return false;
        }

        return current->insertSymbol(symbol);
    }

    bool deleteSymbol(string key) {
        if(current == NULL) {
            return false;
        }

        return current->deleteSymbol(key);
    }

    SymbolInfo* lookUp(string key) {
        if(current == NULL) {
            return NULL;
        }

        return current->lookUp(key);
    }

    SymbolInfo* lookUpAll(string key) {
        if(current == NULL) {
            return NULL;
        }

        ScopeTable* temp = current;
        SymbolInfo* result = NULL;

        while(temp != NULL) {
            result = temp->lookUp(key);

            if(result != NULL) {
                break;
            }

            temp = temp->getParentScope();
        }

        return result;
    }

    void printCurrent() const {
        if(current == NULL) {
            return ;
        }

        current->print();
        return ;
    }

    void printAll() const {
        if(current == NULL) {
            return ;
        }

        /* NOTICE - const */
        ScopeTable* temp = current;

        while(temp != NULL) {
            temp->print();
            temp = temp->getParentScope();
        }

        return ;
    }
};
