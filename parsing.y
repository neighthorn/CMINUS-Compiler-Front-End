%locations
%{
#include<stdio.h>
#include "syntaxTree.h"
extern char * yytext;
extern int hasSyntaxError;
#define YYERROR_VERBOSE 1
int debug = 0;
%}

%union{
    struct AST * a; //astnode
	struct symbol * sym;
	struct symlist * symArgs;
    int i; //integer
	int type; //relop
    float f; //float
    char * s; //string id
}

%token <i> INT
%token <f> FLOAT
%token <s> ID
%token <type> RELOP
%token <s> TYPE
%token <a> SEMI COMMA ASSIGNOP
%token <a> PLUS MINUS STAR DIV
%token <a> AND OR DOT NOT
%token <a> LP RP LB RB LC RC
%token <a> STRUCT RETURN IF ELSE WHILE
%type <a> Program ExtDefList ExtDef ExtDecList Specifier StructSpecifier
%type <a> OptTag Tag VarDec FunDec VarList ParamDec CompSt
%type <a> StmtList Stmt DefList Def DecList Dec Exp Args

/*priority*/
%right ASSIGNOP
%left AND OR
%left RELOP
%left PLUS MINUS
%left STAR DIV
%right NOT
%left LP RP LB RB DOT

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

/***********High-Level Definitions***********/
/*Program*/
Program: ExtDefList	{	
					if(debug) printf("This is the root.\n");
					$$ = newAstNode("Program", @$.first_line, $1);
					if(hasSyntaxError == 0) printSyntaxTree($$, 0);
					}

/*The list of ExtDef*/
ExtDefList: ExtDef ExtDefList	{
								if(debug) printf("This is ExtDef ExtDefList.\n");
								$$ = newAstNode("ExtDefList", @$.first_line, $1);
								setSibling($1, $2);
								if(debug) printf("Finish ExtDef ExtDefList.\n");
								}
    |	{$$ = newAstNode("NULL", -1, NULL);}
    ;

/*ExtDef: definition of global variable/struct/function*/
ExtDef: Specifier ExtDecList SEMI	{
									if(debug) printf("This is Specifier ExtDecList SEMI.\n");
									$$ = newAstNode("ExtDef", @$.first_line, $1);
									setSibling($1, $2);
									struct AST * semiNode = newAstNode("SEMI", @3.first_line, NULL);
									setSyntaxUnit(semiNode, 0);
									setSibling($2, semiNode);
									if(debug) printf("Finish Specifier ExtDecList SEMI.\n");
									}	/*global variable*/
    | Specifier SEMI	{
						if(debug) printf("This is Specifier SEMI.\n");
						$$ = newAstNode("ExtDef", @$.first_line, $1);
						struct AST * semiNode = newAstNode("SEMI", @2.first_line, NULL);
						setSyntaxUnit(semiNode, 0);
						setSibling($1, semiNode);
						if(debug) printf("Finish Specifier SEMI.\n");
						}	/*struct*/
    | Specifier FunDec CompSt	{
								if(debug) printf("This is Specifier FunDec CompSt.\n");
								$$ = newAstNode("ExtDef", @$.first_line, $1);
								setSibling($1, $2);
								setSibling($2, $3);
								if(debug) printf("Finish Specifier FunDec CompSt.\n");
								}	/*function*/
	
    | error SEMI	{hasSyntaxError = 1; $$ = NULL;}
	;

/*name of variables*/
ExtDecList: VarDec	{$$ = newAstNode("ExtDecList", @$.first_line, $1);}
    | VarDec COMMA ExtDecList	{
								if(debug) printf("This is VarDec COMMA ExtDecList\n");
								$$ = newAstNode("ExtDecList", @$.first_line, $1);
								struct AST * commaNode = newAstNode("COMMA", @2.first_line, NULL);
								setSyntaxUnit(commaNode, 0);
								setSibling($1, commaNode);
								setSibling(commaNode, $3);
								if(debug) printf("Finish VarDec COMMMA ExtDecList\n");
								}
    ;

/***********Specifiers***********/
/*int float struct*/
Specifier: TYPE	{
				if(debug) printf("This is Specifier TYPE.\n");
				struct AST * typeNode = newAstNode("TYPE", @1.first_line, NULL);
				setSyntaxUnit(typeNode, 0);
				setLeafNode(typeNode, 3);
				setString(typeNode, $1);
				$$ = newAstNode("Specifier", @$.first_line, typeNode);
				if(debug) printf("Finish Specifier TYPE.\n");
				}
    | StructSpecifier	{$$ = newAstNode("Specifier", @$.first_line, $1);}
    ;

/*struct definition*/
StructSpecifier: STRUCT OptTag LC DefList RC	{
												struct AST * structNode = newAstNode("STRUCT", @1.first_line, NULL);
												setSyntaxUnit(structNode, 0);
												$$ = newAstNode("StructSpecifier", @$.first_line, structNode);
												setSibling(structNode, $2);
												struct AST * lcNode = newAstNode("LC", @3.first_line, NULL);
												setSyntaxUnit(lcNode, 0);
												setSibling($2, lcNode);
												setSibling(lcNode, $4);
												struct AST * rcNode = newAstNode("RC", @5.first_line, NULL);
												setSyntaxUnit(rcNode, 0);
												setSibling($4, rcNode);
												}
    | STRUCT Tag	{
					struct AST * structNode = newAstNode("STRUCT", @1.first_line, NULL);
					setSyntaxUnit(structNode, 0);
					$$ = newAstNode("StructSpecifier", @$.first_line, structNode);
					setSibling(structNode, $2);
					}
    ;

/*the name of Struct, if there is a definition of struct, the name can be null*/
OptTag: ID	{
			struct AST * idNode = newAstNode("ID", @1.first_line, NULL);
			setSyntaxUnit(idNode, 0);
			setLeafNode(idNode, 3);
			setString(idNode, $1);
			$$ = newAstNode("OptTag", @$.first_line, idNode);}
    |	{$$ = newAstNode("NULL", -1, NULL);}
    ;

/*Struct Tag; Tag cannot be null*/
Tag: ID	{
		struct AST * idNode = newAstNode("ID", @1.first_line, NULL);
		setSyntaxUnit(idNode, 0);
		setLeafNode(idNode, 3);
		setString(idNode, $1);
		$$ = newAstNode("Tag", @$.first_line, idNode);}
    ;

/***********Declarators***********/
/*the definition of variable or array*/
VarDec: ID	{
			struct AST * idNode = newAstNode("ID", @1.first_line, NULL);
			setSyntaxUnit(idNode, 0);
			setLeafNode(idNode, 3);
			setString(idNode, $1);
			$$ = newAstNode("VarDec", @$.first_line, idNode);}
    | VarDec LB INT RB	{
						$$ = newAstNode("VarDec", @$.first_line, $1);
						struct AST * lbNode = newAstNode("LB", @2.first_line, NULL);
						setSyntaxUnit(lbNode, 0);
						setSibling($1, lbNode);
						struct AST * intNode = newAstNode("INT", @3.first_line, NULL);
						setSyntaxUnit(intNode, 0);
						setLeafNode(intNode, 1);
						setInteger(intNode, 1);
						setSibling(lbNode, intNode);
						struct AST * rbNode = newAstNode("RB", @4.first_line, NULL);
						setSyntaxUnit(rbNode, 0);
						setSibling(intNode, rbNode);
						}
	| error RB	{hasSyntaxError = 1; $$ = NULL;}
    ;

/*the definition of function; VarList is the parameters*/
FunDec: ID LP VarList RP	{
							struct AST * idNode = newAstNode("ID", @1.first_line, NULL);
							setSyntaxUnit(idNode, 0);
							setLeafNode(idNode, 3);
							setString(idNode, $1);
							if(debug) printf("FunDec IDNODE: %s %s\n", $1, idNode->str);
							$$ = newAstNode("FunDec", @$.first_line, idNode);
							struct AST * lpNode = newAstNode("LP", @2.first_line, NULL);
							setSyntaxUnit(lpNode, 0);
							setSibling(idNode, lpNode);
							setSibling(lpNode, $3);
							struct AST * rpNode = newAstNode("RP", @4.first_line, NULL);	
							setSyntaxUnit(rpNode, 0);
							setSibling($3, rpNode);
							}
    | ID LP RP	{
				struct AST * idNode = newAstNode("ID", @1.first_line, NULL);
				setSyntaxUnit(idNode, 0);
				setLeafNode(idNode, 3);
				setString(idNode, $1);
				$$ = newAstNode("FunDec", @$.first_line, idNode);
				struct AST * lpNode = newAstNode("LP", @2.first_line, NULL);
				setSyntaxUnit(lpNode, 0);
				setSibling(idNode, lpNode);
				struct AST * rpNode = newAstNode("RP", @3.first_line, NULL);
				setSyntaxUnit(rpNode, 0);
				setSibling(lpNode, rpNode);
				}
	| error RP	{hasSyntaxError = 1; $$ = NULL;}
    ;

/*the parameters*/
VarList: ParamDec COMMA VarList	{
								$$ = newAstNode("VarList", @$.first_line, $1);
								struct AST * commaNode = newAstNode("COMMA", @2.first_line, NULL);
								setSyntaxUnit(commaNode, 0);
								setSibling($1, commaNode);
								setSibling(commaNode, $3);
								}
    | ParamDec	{$$ = newAstNode("VarList", @$.first_line, $1);}
    ;

/*a single parameter*/
ParamDec: Specifier VarDec	{
							$$ = newAstNode("ParamDec", @$.first_line, $1);
							setSibling($1, $2);
							}
    ;

/***********Statements***********/
/*a block with statements and local definitions*/
CompSt: LC DefList StmtList RC	{
								struct AST * lcNode = newAstNode("LC", @1.first_line, NULL);
								setSyntaxUnit(lcNode, 0);
								$$ = newAstNode("CompSt", @$.first_line, lcNode);
								setSibling(lcNode, $2);
								setSibling($2, $3);
								struct AST * rcNode = newAstNode("RC", @4.first_line, NULL);
								setSyntaxUnit(rcNode, 0);
								setSibling($3, rcNode);
								}
		| error RC	{hasSyntaxError = 1; $$ = NULL;}
    ;

/*a block of statements*/
StmtList: Stmt StmtList	{
						$$ = newAstNode("StmtList", @$.first_line, $1);
						setSibling($1, $2);
						}
    |	{$$ = newAstNode("NULL", -1, NULL);} 
    ;

/*the correct program sentence/statement*/
Stmt: Exp SEMI	{
				if(debug) printf("Stmt: Exp SEMI\n");
				$$ = newAstNode("Stmt", @$.first_line, $1);
				struct AST * semiNode = newAstNode("SEMI", @2.first_line, NULL);
				setSyntaxUnit(semiNode, 0);
				setSibling($1, semiNode);
				if(debug) printf("Stmt: Exp SEMI\n");
				}
    | CompSt	{$$ = newAstNode("Stmt", @$.first_line, $1);}
    | RETURN Exp SEMI	{
						struct AST * returnNode = newAstNode("RETURN", @1.first_line, NULL);
						setSyntaxUnit(returnNode, 0);
						$$ = newAstNode("Stmt", @$.first_line, returnNode);
						setSibling(returnNode, $2);
						struct AST * semiNode = newAstNode("SEMI", @3.first_line, NULL);
						setSyntaxUnit(semiNode, 0);
						setSibling($2, semiNode);
						}
    | IF LP Exp RP Stmt	%prec LOWER_THAN_ELSE	{
												struct AST * ifNode = newAstNode("IF", @1.first_line, NULL);
												setSyntaxUnit(ifNode, 0);
												$$ = newAstNode("Stmt", @$.first_line, ifNode);
												struct AST * lpNode = newAstNode("LP", @2.first_line, NULL);
												setSyntaxUnit(lpNode, 0);
												setSibling(ifNode, lpNode);
												setSibling(lpNode, $3);
												struct AST * rpNode = newAstNode("RP", @4.first_line, NULL);
												setSyntaxUnit(rpNode, 0);
												setSibling($3, rpNode);
												setSibling(rpNode, $5);
												}
    | IF LP Exp RP Stmt ELSE Stmt	{
									struct AST * ifNode = newAstNode("IF", @1.first_line, NULL);
									setSyntaxUnit(ifNode, 0);
									$$ = newAstNode("Stmt", @$.first_line, ifNode);
									struct AST * lpNode = newAstNode("LP", @2.first_line, NULL);
									setSyntaxUnit(lpNode, 0);
									setSibling(ifNode, lpNode);
									setSibling(lpNode, $3);
									struct AST * rpNode = newAstNode("RP", @4.first_line, NULL);
									setSyntaxUnit(rpNode, 0);
									setSibling($3, rpNode);
									setSibling(rpNode, $5);
									struct AST * elseNode = newAstNode("ELSE", @6.first_line, NULL);
									setSyntaxUnit(elseNode, 0);
									setSibling($5, elseNode);
									setSibling(elseNode, $7);
									}
    | WHILE LP Exp RP Stmt	{
							struct AST * whileNode = newAstNode("WHILE", @1.first_line, NULL);
							setSyntaxUnit(whileNode, 0);
							$$ = newAstNode("WHILE", @$.first_line, whileNode);
							struct AST * lpNode = newAstNode("LP", @2.first_line, NULL);
							setSyntaxUnit(lpNode, 0);
							setSibling(whileNode, lpNode);
							setSibling(lpNode, $3);
							struct AST * rpNode = newAstNode("RP", @4.first_line, NULL);
							setSyntaxUnit(rpNode, 0);
							setSibling($3, rpNode);
							setSibling(rpNode, $5);
							}
	| error SEMI	{hasSyntaxError = 1; $$ = NULL;}
    ;

/************Local Definitions***********/
/*local definitions list*/
DefList: Def DefList	{
						$$ = newAstNode("DefList", @$.first_line, $1);
						setSibling($1, $2);
						}
    |	{$$ = newAstNode("NULL", -1, NULL);}
    ;

/*a complete sentence of definition*/
Def: Specifier DecList SEMI	{
							$$ = newAstNode("Def", @$.first_line, $1);
							setSibling($1, $2);
							struct AST * semiNode = newAstNode("SEMI", @3.first_line, NULL);
							setSyntaxUnit(semiNode, 0);
							setSibling($2, semiNode);
							}
    ;

/*variables list*/
DecList: Dec	{$$ = newAstNode("DecList", @$.first_line, $1);}
    | Dec COMMA DecList	{
						$$ = newAstNode("Dec", @$.first_line, $1);
						struct AST * commaNode = newAstNode("COMMA", @2.first_line, NULL);
						setSyntaxUnit(commaNode, 0);
						setSibling($1, commaNode);
						setSibling(commaNode, $3);
						}

/*a single variable with/without assignment*/
Dec: VarDec	{$$ = newAstNode("Dec", @$.first_line, $1);}
    | VarDec ASSIGNOP Exp	{
							if(debug) printf("This is VarDec ASSIGNOP Exp\n");
							$$ = newAstNode("Dec", @$.first_line, $1);
							struct AST * assignNode = newAstNode("ASSIGNOP", @2.first_line, NULL);
							setSyntaxUnit(assignNode, 0);
							setSibling($1, assignNode);
							setSibling(assignNode, $3);
							if(debug) printf("Finish VarDec ASSIGNOP Exp\n");
							}
    ;

/************Expressions************/
/*simple expressions*/
Exp: Exp ASSIGNOP Exp	{
						$$ = newAstNode("Exp", @$.first_line, $1);
						struct AST * assignNode = newAstNode("ASSIGNOP", @2.first_line, NULL);
						setSyntaxUnit(assignNode, 0);
						setSibling($1, assignNode);
						setSibling(assignNode, $3);
						}
    | Exp AND Exp	{
					$$ = newAstNode("Exp", @$.first_line, $1);
					struct AST * andNode = newAstNode("AND", @2.first_line, NULL);
					setSyntaxUnit(andNode, 0);
					setSibling($1, andNode);
					setSibling(andNode, $3);
					}
    | Exp OR Exp	{
					$$ = newAstNode("Exp", @$.first_line, $1);
					struct AST * orNode = newAstNode("OR", @2.first_line, NULL);
					setSyntaxUnit(orNode, 0);
					setSibling($1, orNode);
					setSibling(orNode, $3);
					}
    | Exp RELOP Exp	{
					$$ = newAstNode("Exp", @$.first_line, $1);
					struct AST * relNode = newRelopNode($2, @2.first_line);
					setSibling($1, relNode);
					setSibling(relNode, $3);
					}
    | Exp PLUS Exp	{
					$$ = newAstNode("Exp", @$.first_line, $1);
					struct AST * plusNode = newAstNode("PLUS", @2.first_line, NULL);
					setSyntaxUnit(plusNode, 0);
					setSibling($1, plusNode);
					setSibling(plusNode, $3);
					}
    | Exp MINUS Exp	{
					$$ = newAstNode("Exp", @$.first_line, $1);
					struct AST * minusNode = newAstNode("MINUS", @2.first_line, NULL);
					setSyntaxUnit(minusNode, 0);
					setSibling($1, minusNode);
					setSibling(minusNode, $3);
					}
    | Exp STAR Exp	{
					$$ = newAstNode("Exp", @$.first_line, $1);
					struct AST * starNode = newAstNode("STAR", @2.first_line, NULL);
					setSyntaxUnit(starNode, 0);
					setSibling($1, starNode);
					setSibling(starNode, $3);
					}
    | Exp DIV Exp	{
					$$ = newAstNode("Exp", @$.first_line, $1);
					struct AST * divNode = newAstNode("DIV", @2.first_line, NULL);
					setSyntaxUnit(divNode, 0);
					setSibling($1, divNode);
					setSibling(divNode, $3);
					}
    | LP Exp RP	{
				struct AST * lpNode = newAstNode("LP", @1.first_line, NULL);
				setSyntaxUnit(lpNode, 0);
				$$ = newAstNode("Exp", @$.first_line, lpNode);
				setSibling(lpNode, $2);
				struct AST * rpNode = newAstNode("RP", @3.first_line, NULL);
				setSyntaxUnit(rpNode, 0);
				setSibling($2, rpNode);
				}
    | MINUS Exp	{
				struct AST * minusNode = newAstNode("MINUS", @1.first_line, NULL);
				setSyntaxUnit(minusNode, 0);
				$$ = newAstNode("Exp", @$.first_line, minusNode);
				setSibling(minusNode, $2);
				}
    | NOT Exp	{
				struct AST * notNode = newAstNode("NOT", @1.first_line, NULL);
				setSyntaxUnit(notNode, 0);
				$$ = newAstNode("Exp", @$.first_line, notNode);
				setSibling(notNode, $2);
				}
    | ID LP Args RP	{
					struct AST * idNode = newAstNode("ID", @1.first_line, NULL);
					setSyntaxUnit(idNode, 0);
					setLeafNode(idNode, 3);
					setString(idNode, $1);
					$$ = newAstNode("Exp", @$.first_line, idNode);
					struct AST * lpNode = newAstNode("LP", @2.first_line, NULL);
					setSyntaxUnit(lpNode, 0);
					setSibling(idNode, lpNode);
					setSibling(lpNode, $3);
					struct AST * rpNode = newAstNode("RP", @4.first_line, NULL);
					setSyntaxUnit(rpNode, 0);
					setSibling($3, rpNode);
					}
    | ID LP RP	{
				struct AST * idNode = newAstNode("ID", @1.first_line, NULL);
				setSyntaxUnit(idNode, 0);
				setLeafNode(idNode, 3);
				setString(idNode, $1);
				$$ = newAstNode("Exp", @$.first_line, idNode);
				struct AST * lpNode = newAstNode("LP", @2.first_line, NULL);
				setSyntaxUnit(lpNode, 0);
				setSibling(idNode, lpNode);
				struct AST * rpNode = newAstNode("RP", @3.first_line, NULL);
				setSyntaxUnit(rpNode, 0);
				setSibling(lpNode, rpNode);
				}
    | Exp LB Exp RB	{
					$$ = newAstNode("Exp", @$.first_line, $1);
					struct AST * lbNode = newAstNode("LB", @2.first_line, NULL);
					setSyntaxUnit(lbNode, 0);
					setSibling($1, lbNode);
					setSibling(lbNode, $3);
					struct AST * rbNode = newAstNode("RB", @4.first_line, NULL);
					setSyntaxUnit(rbNode, 0);
					setSibling($3, rbNode);
					}
    | Exp DOT ID	{
					$$ = newAstNode("Exp", @$.first_line, $1);
					struct AST * dotNode = newAstNode("DOT", @2.first_line, NULL);
					setSyntaxUnit(dotNode, 0);
					setSibling($1, dotNode);
					struct AST * idNode = newAstNode("ID", @3.first_line, NULL);
					setSyntaxUnit(idNode, 0);
					setLeafNode(idNode, 3);
					setString(idNode, $3);
					setSibling(dotNode, idNode);
					}
    | ID	{
			struct AST * idNode = newAstNode("ID", @1.first_line, NULL); 
			setString(idNode, $1); 
			setSyntaxUnit(idNode, 0); 
			setLeafNode(idNode, 3); 
			$$ = newAstNode("Exp", @$.first_line, idNode);}
    | INT	{
			struct AST * intNode = newAstNode("INT", @1.first_line, NULL); 
			setInteger(intNode, $1); 
			setSyntaxUnit(intNode, 0); 
			setLeafNode(intNode, 1); 
			$$ = newAstNode("Exp", @$.first_line, intNode);}
    | FLOAT	{
			struct AST * floatNode = newAstNode("FLOAT", @1.first_line, NULL); 
			setFloatNumber(floatNode, $1); 
			setSyntaxUnit(floatNode, 0); 
			setLeafNode(floatNode, 2); 
			$$ = newAstNode("Exp", @$.first_line, floatNode);}
    ;

/*arguments*/
Args: Exp COMMA Args	{
						$$ = newAstNode("Args", @$.first_line, $1);
						struct AST * commaNode = newAstNode("COMMA", @$.first_line, NULL);
						setSyntaxUnit(commaNode, 0);
						setSibling($1, commaNode);
						setSibling(commaNode, $3);
						}
    | Exp	{$$ = newAstNode("Args", @$.first_line, $1);}
    ;
%%

void yyerror(const char * s){
	fprintf(stderr, "Error type B at Line %d: %s: %s\n", yylineno, s, yytext);
}
