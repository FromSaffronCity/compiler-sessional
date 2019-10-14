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
            oObj << "\t" << "Found in ScopeTable #" << id << " at position " << index << ", " << position << "\n" << endl;
            return temp;
        }

        position++;
        temp = temp->getNext();
    }

    return NULL;  // NOTICE
}

bool ScopeTable::insertSymbol(SymbolInfo& symbol, ofstream& oObj) {
    if(lookUp(symbol.getName(), oObj) != NULL) {
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

bool ScopeTable::deleteSymbol(string key, ofstream& oObj) {
    if(lookUp(key, oObj) == NULL) {
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

void ScopeTable::print(ofstream& oObj) const {
    oObj << "\t" << "ScopeTable #" << id << endl;

    for(int i=0; i<length; i++) {
        if(bucketList[i] == NULL) {
            continue;
        }

        oObj << "\t" << i << " -->";

        SymbolInfo* temp = bucketList[i];

        while(temp != NULL) {
            oObj << " " << *temp;
			temp = temp->getNext();
        }

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
    void enterScope(int, int);
    void exitScope();

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

void SymbolTable::enterScope(int id, int length) {
    ScopeTable* temp = new ScopeTable(id, length, current);
    current = temp;

    return ;
}

void SymbolTable::exitScope() {
    if(current == NULL) {
        return ;
    }

    current = current->getParentScope();
    return ;
}

bool SymbolTable::insertSymbol(SymbolInfo& symbol, ofstream& oObj) {
    if(current == NULL) {
        return false;
    }

    return current->insertSymbol(symbol, oObj);
}

bool SymbolTable::deleteSymbol(string key, ofstream& oObj) {
    if(current == NULL) {
        return false;
    }

    return current->deleteSymbol(key, oObj);
}

SymbolInfo* SymbolTable::lookUp(string key, ofstream& oObj) {
    if(current == NULL) {
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
        return ;
    }

    current->print(oObj);
    return ;
}

void SymbolTable::printAll(ofstream& oObj) const {
    if(current == NULL) {
        return ;
    }

    /* NOTICE - const */
    ScopeTable* temp = current;

    while(temp != NULL) {
        temp->print(oObj);
        oObj << endl;

        temp = temp->getParentScope();
    }

    return ;
}
