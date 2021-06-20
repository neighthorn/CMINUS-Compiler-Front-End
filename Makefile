all: clean compiler

compiler: scanning.l parsing.y syntaxTree.h
	bison -d -v parsing.y
	flex scanning.l
	cc -g -o $@ syntaxTree.h main.c parsing.tab.c lex.yy.c -lfl

clean:
	rm -f compiler lex.yy.c parsing.tab.c parsing.tab.h
