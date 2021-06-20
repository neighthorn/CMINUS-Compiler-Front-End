#ifndef SYNTAXTREE_H_
#define SYNTAXTREE_H_

#define HASHNUM 9997

//词法分析器的接口
extern int yylineno;
void yyerror(const char * s);
void errorA(char * s);
void errorB(char * s);

//abstract syntax tree node (origin node)
// expressions
struct AST{
    char * nodetype; //节点类型 符号类型 二元运算符/一元运算符表达式
    int lineNumber; //行号
    struct AST * firstChild;
	struct AST * sibling;
	int isSyntaxUnit;
	int isLeafNode;
	int integer;
	float floatNumber;
	char * str;
};
//symlist和symbol都是为了维护哈希表，用来检验使用的变量是否被定义过
//the list of arguments
struct symlist{
    struct symbol * sym;
    struct symlist * nxt;
};

struct symbol{
    char * name;
    int i;
	double f;
    struct AST * function; //function ast node
    struct symlist * symArgs; //arguments
};

int checkDecimal(char * s);
int checkOctal(char * s);
int checkHexadecimal(char * s);
float checkFloat(char * s);
float checkExpFloat(char * s);
//void functionDefine(struct symbol * name, struct * symArgs, struct AST * stmts);
struct AST * newAstNode(char * _nodetype, int _lineNumber, struct AST * _firstChild);
struct AST * newRelopNode(int type, int _lineNumber);
void setSibling(struct AST * node, struct AST * _sibling);
void setInteger(struct AST * node, int _integer);
void setFloatNumber(struct AST * node, float _floatNumber);
void setString(struct AST * node, char * _str);
void setSyntaxUnit(struct AST * node, int _isSyntaxUnit);
void setLeafNode(struct AST * node, int _isLeafNode);
void printSyntaxTree(struct AST * node, int depth);
#endif
