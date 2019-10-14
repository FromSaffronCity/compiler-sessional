#include<iostream>
#include<fstream>
#include<string>
#include<cstdlib>

using namespace std;


class SymbolInfo {
    string name;
    string type;

    SymbolInfo* next;

public:
    SymbolInfo();
    SymbolInfo(string, string);

    string getName() const;
    string getType() const;

    void setNext(SymbolInfo*);
    SymbolInfo* getNext() const;

    ~SymbolInfo();

    friend ostream& operator<<(ostream&, SymbolInfo&);
};

SymbolInfo::SymbolInfo() {
    /* nothing here */
}

SymbolInfo::SymbolInfo(string name, string type) {
    this->name = name;
    this->type = type;

    next = NULL;
}

string SymbolInfo::getName() const {
    return name;
}

string SymbolInfo::getType() const {
    return type;
}

void SymbolInfo::setNext(SymbolInfo* next) {
    this->next = next;
    return ;
}

SymbolInfo* SymbolInfo::getNext() const {
    return next;
}

SymbolInfo::~SymbolInfo() {
    /* nothing here */
}

ostream& operator<<(ostream& out, SymbolInfo& ref) {
    out << "< " << ref.name << ", " << ref.type << ">";
    return out;
}


class ScopeTable {
    int id;
    int length;

    SymbolInfo** bucketList;
    ScopeTable* parentScope;

    int hashFunction(string);

public:
    ScopeTable();
    ScopeTable(int, int, ScopeTable*);

    int getID() const;
    int getlength() const;
    ScopeTable* getParentScope() const;

    ~ScopeTable();

    /* main functionalities */
    SymbolInfo* lookUp(string, ofstream&);
    bool insertSymbol(SymbolInfo&, ofstream&);
    bool deleteSymbol(string, ofstream&);
    void print(ofstream&) const;
};

int ScopeTable::hashFunction(string key) {
    int hashedValue = 0;

    for(int i=0; i<key.length(); i++) {
        hashedValue += ((int)key[i] + i*(int)key[i]);  // NOTICE
    }

    return (hashedValue%length);
}

ScopeTable::ScopeTable() {
    /* nothing here */
}

ScopeTable::ScopeTable(int id, int length, ScopeTable* parentScope) {
    this->id = id;
    this->length = length;

    bucketList = new SymbolInfo*[length];

    for(int i=0; i<length; i++) {
        bucketList[i] = NULL;
    }

    this->parentScope = parentScope;
}

int ScopeTable::getID() const {
    return id;
}

int ScopeTable::getlength() const {
    return length;
}

ScopeTable* ScopeTable::getParentScope() const {
    return parentScope;
}

ScopeTable::~ScopeTable() {
    delete[] bucketList;
}

SymbolInfo* ScopeTable::lookUp(string key, ofstream& oObj) {
    int index = hashFunction(key);
    int position = 0;

    SymbolInfo* temp = bucketList[index];

    while(temp != NULL) {
        if(key == temp->getName()) {
            cout << "\t" << "Found in ScopeTable #" << id << " at position " << index << ", " << position << endl;
            oObj << "\t" << "Found in ScopeTable #" << id << " at position " << index << ", " << position << endl;
            return temp;
        }

        position++;
        temp = temp->getNext();
    }

    cout << "\t" << "Not found in ScopeTable #" << id << endl;
    oObj << "\t" << "Not found in ScopeTable #" << id << endl;

    return NULL;  // NOTICE
}

bool ScopeTable::insertSymbol(SymbolInfo& symbol, ofstream& oObj) {
    if(lookUp(symbol.getName(), oObj) != NULL) {
        cout << "\t" << symbol << " already exists in current ScopeTable" << endl;
        oObj << "\t" << symbol << " already exists in current ScopeTable" << endl;

        return false;
    }

    int index = hashFunction(symbol.getName());
    int position = 0;

    SymbolInfo* temp = bucketList[index];

    if(temp == NULL) {
        bucketList[index] = &symbol;
        symbol.setNext(NULL);

        cout << "\t" << "Inserted in ScopeTable #" << id << " at position " << index << ", " << position << endl;
        oObj << "\t" << "Inserted in ScopeTable #" << id << " at position " << index << ", " << position << endl;
        return true;
    }

    while(temp->getNext() != NULL) {
        temp = temp->getNext();
        position++;
    }

    temp->setNext(&symbol);
    symbol.setNext(NULL);

    cout << "\t" << "Inserted in ScopeTable #" << id << " at position " << index << ", " << ++position << endl;  // NOTICE
    oObj << "\t" << "Inserted in ScopeTable #" << id << " at position " << index << ", " << position << endl;
    return true;
}

bool ScopeTable::deleteSymbol(string key, ofstream& oObj) {
    if(lookUp(key, oObj) == NULL) {
        cout << "\t" << key << " not found (failed to delete)" << endl;
        oObj << "\t" << key << " not found (failed to delete)" << endl;

        return false;
    }

    int index = hashFunction(key);
    int position = 0;

    SymbolInfo* temp = bucketList[index];
    SymbolInfo* previous = NULL;

    while(temp != NULL) {
        if(key == temp->getName()) {
            break;
        }

        position++;
        previous = temp;
        temp = temp->getNext();
    }

    if(previous == NULL) {
        bucketList[index] = temp->getNext();
    } else {
        previous->setNext(temp->getNext());
    }

    delete temp;  // NOTICE - IMPORTANT AF

    cout << "\t" << "Deleted entry at " << index << ", " << position << " from current ScopeTable" << endl;
    oObj << "\t" << "Deleted entry at " << index << ", " << position << " from current ScopeTable" << endl;
    return true;
}

void ScopeTable::print(ofstream& oObj) const {
    cout << "\t" << "ScopeTable #" << id << endl;
    oObj << "\t" << "ScopeTable #" << id << endl;

    for(int i=0; i<length; i++) {
        cout << "\t" << i << " -->";
        oObj << "\t" << i << " -->";

        SymbolInfo* temp = bucketList[i];

        while(temp != NULL) {
            cout << " " << *temp;
            oObj << " " << *temp;

            temp = temp->getNext();
        }

        cout << endl;
        oObj << endl;
    }

    return ;
}


class SymbolTable {
    ScopeTable* current;

public:
    SymbolTable();
    ~SymbolTable();

    /* main functionalities */
    void enterScope(int, int, ofstream&);
    void exitScope(ofstream&);

    bool insertSymbol(SymbolInfo&, ofstream&);
    bool deleteSymbol(string, ofstream&);
    SymbolInfo* lookUp(string, ofstream&);

    void printCurrent(ofstream&) const;
    void printAll(ofstream&) const;
};

SymbolTable::SymbolTable() {
    current = NULL;
}

SymbolTable::~SymbolTable() {
    /* nothing here */
}

void SymbolTable::enterScope(int id, int length, ofstream& oObj) {
    ScopeTable* temp = new ScopeTable(id, length, current);
    current = temp;

    cout << "\t" << "New ScopeTable with id " << id << " created" << endl;
    oObj << "\t" << "New ScopeTable with id " << id << " created" << endl;

    return ;
}

void SymbolTable::exitScope(ofstream& oObj) {
    if(current == NULL) {
        cout << "\t" << "no ScopeTable in the SymbolTable" << endl;
        oObj << "\t" << "no ScopeTable in the SymbolTable" << endl;

        return ;
    }

    cout << "\t" << "ScopeTable with id " << current->getID() << " removed" << endl;
    oObj << "\t" << "ScopeTable with id " << current->getID() << " removed" << endl;

    current = current->getParentScope();
    return ;
}

bool SymbolTable::insertSymbol(SymbolInfo& symbol, ofstream& oObj) {
    if(current == NULL) {
        cout << "\t" << "no ScopeTable in the SymbolTable" << endl;
        oObj << "\t" << "no ScopeTable in the SymbolTable" << endl;

        return false;
    }

    return current->insertSymbol(symbol, oObj);
}

bool SymbolTable::deleteSymbol(string key, ofstream& oObj) {
    if(current == NULL) {
        cout << "\t" << "no ScopeTable in the SymbolTable" << endl;
        oObj << "\t" << "no ScopeTable in the SymbolTable" << endl;

        return false;
    }

    return current->deleteSymbol(key, oObj);
}

SymbolInfo* SymbolTable::lookUp(string key, ofstream& oObj) {
    if(current == NULL) {
        cout << "\t" << "no ScopeTable in the SymbolTable" << endl;
        oObj << "\t" << "no ScopeTable in the SymbolTable" << endl;

        return NULL;
    }

    ScopeTable* temp = current;
    SymbolInfo* result = NULL;

    while(temp != NULL) {
        result = temp->lookUp(key, oObj);

        if(result != NULL) {
            break;
        }

        temp = temp->getParentScope();
    }

    return result;
}

void SymbolTable::printCurrent(ofstream& oObj) const {
    if(current == NULL) {
        cout << "\t" << "no ScopeTable in the SymbolTable" << endl;
        oObj << "\t" << "no ScopeTable in the SymbolTable" << endl;

        return ;
    }

    current->print(oObj);
    return ;
}

void SymbolTable::printAll(ofstream& oObj) const {
    if(current == NULL) {
        cout << "\t" << "no ScopeTable in the SymbolTable" << endl;
        oObj << "\t" << "no ScopeTable in the SymbolTable" << endl;

        return ;
    }

    /* NOTICE - const */
    ScopeTable* temp = current;

    while(temp != NULL) {
        temp->print(oObj);

        cout << endl;
        oObj << endl;

        temp = temp->getParentScope();
    }

    return ;
}


int main() {
    ifstream iObj("1605023_my_input.txt");  // NOTICE: select input file
    ofstream oObj("1605023_my_output.txt");

    if(iObj.is_open() != true) {
        exit(EXIT_FAILURE);
    }

    if(oObj.is_open() != true) {
        exit(EXIT_FAILURE);
    }

    int length, serial, current_sct;
    string opt, name, type;

    iObj >> length;
    serial = current_sct = 0;

    SymbolTable st;
    st.enterScope(++serial, length, oObj);
    current_sct++;

    /*
        ~ IMPORTANT ~

        to terminate the while loop below
         any character except for I, L, D, P, S, E must be inputted in opt
          this will cause the loop to terminate
    */

    while(true) {
        iObj >> opt;

        if(opt == "I") {
            iObj >> name >> type;

            cout << opt << " " << name << " " << type << "\n" << endl;
            oObj << opt << " " << name << " " << type << "\n" << endl;

            SymbolInfo* symbol = new SymbolInfo(name, type);

            st.insertSymbol(*symbol, oObj);
        } else if(opt == "L") {
            iObj >> name;

            cout << opt << " " << name << "\n" << endl;
            oObj << opt << " " << name << "\n" << endl;

            st.lookUp(name, oObj);
        } else if(opt == "D") {
            iObj >> name;

            cout << opt << " " << name << "\n" << endl;
            oObj << opt << " " << name << "\n" << endl;

            st.deleteSymbol(name, oObj);
        } else if(opt == "P") {
            iObj >> type;

            cout << opt << " " << type << "\n" << endl;
            oObj << opt << " " << type << "\n" << endl;

            if(type == "A") {
                st.printAll(oObj);
            } else if(type == "C") {
                st.printCurrent(oObj);
            } else {
                cout << "\t" << "invalid operation" << "\n" << endl;
                oObj << "\t" << "invalid operation" << "\n" << endl;
            }
        } else if(opt == "S") {
            cout << opt << "\n" << endl;
            oObj << opt << "\n" << endl;

            st.enterScope(++serial, length, oObj);
            current_sct++;
        } else if(opt == "E") {
            cout << opt << "\n" << endl;
            oObj << opt << "\n" << endl;

            st.exitScope(oObj);
            current_sct--;
        } else {
            break;  // NOTICE: any opt input except for I,L,D,P,S,E means "exit"
        }
    }

    for(int i=0; i<current_sct; i++) {
        st.exitScope(oObj);
    }

    iObj.close();
    oObj.close();

    return 0;
}
