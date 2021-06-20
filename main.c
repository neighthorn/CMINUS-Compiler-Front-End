#include "syntaxTree.h"
#include<stdio.h>
#include<stdlib.h>
#include<string.h>

extern int yyparse(void);
extern int yylex(void);
extern char * yytext;
extern void yyrestart(FILE * file);
extern int hasSyntaxError;

void errorA(char * s){
	hasSyntaxError = 1;
	fprintf(stderr, "Error type A at Line %d: %s: %s.\n", yylineno, s, yytext);
}

void errorB(char * s){
	hasSyntaxError = 1;
	fprintf(stderr, "Error type B at Line %d: %s: %s.\n", yylineno, s, yytext);
}

int hexMap(char c){
	if(c >= '0' && c <= '9') return c-'0';

	switch(c){
		case 'a':
		case 'A': return 10;
		case 'b':
		case 'B': return 11;
		case 'c':
		case 'C': return 12;
		case 'd':
		case 'D': return 13;
		case 'e':
		case 'E': return 14;
		case 'f':
		case 'F': return 15;
		default: errorA("Illegal hexadecimal number.");
	}

	return 0;
}

int checkDecimal(char * s){
    long num = atoi(s);
	int len = strlen(s);

	if(len > 10) errorA("The number is out of range.");
    if(num >= (long)1<<32){
		errorA("The number is out of range.");
		num = -1;
	}
    return (int)num;
}

int checkOctal(char * s){
	long num = 0;
	int i = 1;
	for(; s[i] != '\0'; ++i){
		if(i > 11){
			errorA("Number out of range.");
			break;
		}
		if(s[i] > '7'){
			errorA("Illegal octal number.");
		}
		num = num * 8 + s[i] - '0';
	}
	if(num >= (long)1<<32){
		errorA("Number out of range.");
		num = -1;
	}
	return (int)num;
}

int checkHexadecimal(char * s){
	long num = 0;
	int i = 2;
	for(; s[i] != '\0'; ++i){
		if(i > 8){
			errorA("hexadecimal number out of range.");
			break;
		}
		num = num * 16 + hexMap(s[i]);
	}
	if(num >= (long)1<<32){ 
		errorA("Number out of range.");
		num = -1;
	}
	return (int)num;
}

float checkFloat(char * s){
	double num = atof(s);
	return num;
}

float checkExpFloat(char * s){
	double num = atof(s);
	return num;
}

struct AST * newAstNode(char * _nodetype, int _lineNumber, struct AST * _firstChild){
	struct AST * node = (struct AST *)malloc(sizeof(struct AST));
	node->nodetype = _nodetype;
	node->lineNumber = _lineNumber;
	node->firstChild = _firstChild;
	node->sibling = NULL;
	node->isSyntaxUnit = 1;
	node->isLeafNode = 0;
	node->integer = 0;
	node->floatNumber = 0.0;
	node->str = "";
	return node;
}

struct AST * newRelopNode(int type, int _lineNumber){
	struct AST * node = (struct AST *)malloc(sizeof(struct AST));
	node->nodetype = "TYPE";
	node->lineNumber = _lineNumber;
	node->firstChild = NULL;
	node->sibling = NULL;
	node->isSyntaxUnit = 0;
	node->isLeafNode = 0;
	node->integer = 0;
	node->floatNumber = 0.0;
	switch(type){
		case 1: node->str = ">"; break;
		case 2: node->str = "<"; break;
		case 4: node->str = "=="; break;
		case 5: node->str = ">="; break;
		case 6: node->str = "<="; break;
		case 3: node->str = "!="; break;
		default: node->str = "";
	}
	return node;
}

void setSibling(struct AST * node, struct AST * _sibling){
	if(node == NULL) return;
	node->sibling = _sibling;
}

void setInteger(struct AST * node, int _integer){
	if(node == NULL) return;
	node->integer = _integer;
}

void setFloatNumber(struct AST * node, float _floatNumber){
	if(node == NULL) return;
	node->floatNumber = _floatNumber;
}

void setString(struct AST * node, char * _str){
	if(node == NULL) return;
	char * tmp = (char *)malloc(sizeof(char *)*20);
	strcpy(tmp, _str);
	node->str = tmp;
}

void setLeafNode(struct AST * node, int _isLeafNode){
	if(node == NULL) return;
	node->isLeafNode = _isLeafNode;
}

void setSyntaxUnit(struct AST * node, int _isSyntaxUnit){
	if(node == NULL) return;
	node->isSyntaxUnit = _isSyntaxUnit;
}

void printValue(struct AST * node){
	printf(": ");
	if(node->isLeafNode == 1) printf("%d\n", node->integer);
	else if(node->isLeafNode == 2) printf("%g\n", node->floatNumber);
	else if(node->isLeafNode == 3) printf("%s\n", node->str);
	return;
}

void printSyntaxTree(struct AST * node, int depth){
	if(node == NULL) return;
	struct AST * tr = node;
	int i;
	struct AST * sib;
	if(strcmp(tr->nodetype, "NULL")==0){
		printSyntaxTree(tr->firstChild, depth+1);
		printSyntaxTree(tr->sibling, depth);
		return;
	}
	for(i = 0; i < depth; ++i) printf("  ");
	printf("%s", tr->nodetype);
	if(tr->isSyntaxUnit) printf(" (%d)\n", tr->lineNumber);
	else if(tr->isLeafNode) printValue(tr);
	else printf("\n");
	printSyntaxTree(tr->firstChild, depth+1);
	printSyntaxTree(tr->sibling, depth);
	return;
}

int main(int argc, char ** argv){
    int i;

    //stdin
    if(argc <= 1){
        yyparse();
        return 0;
    }

    //file
    for(i = 1; i < argc; ++i){
        FILE * f = fopen(argv[i], "r");
        if(!f){
            perror(argv[i]);
            return 1;
        }
        yyrestart(f);
        yylineno = 1;
        yyparse();
        fclose(f);
    }

    return 0;
}
