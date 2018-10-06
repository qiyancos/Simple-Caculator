%{
#include <map>
#include <string>
#include <iostream>
#include <stdio.h>
#include <stdlib.h>

using namespace std;
struct UNIT{
	union{
		char* name;
		float value;
	}val;
	bool intFlag;
};

#define YYSTYPE UNIT
//#define DEBUG_ON 1
// Decide if the debug infomation should be showed
std::map<string, UNIT> varList;
typedef std::map<string, UNIT>::value_type varListValue;
typedef std::map<string, UNIT>::iterator varListIt;

#define OP_MINUS 0
#define OP_BNEG 1
#define OP_BAND 2
#define OP_BXOR 3
#define OP_BOR 4
#define OP_ADD 5
#define OP_SUB 6
#define OP_DIV 7
#define OP_TIMES 8
#define OP_ASSIGN 9
#define OP_MOD 10

int yyerror(const char * msg);
extern int yylex(void);

void writeVar(char* name, UNIT value){
	string varName = name;
	varListIt target = varList.find(varName);
	if(target == varList.end())
		varList.insert(varListValue(varName, value));
	else
		varList[varName] = value;
}

UNIT readVar(char* name){
	string varName = name;
	varListIt target = varList.find(varName);
	if(target != varList.end())
		return target->second;
	else {
		UNIT temp;
		temp.val.value = 0;
		temp.intFlag = true;
		return temp;
	}
}

void typeCheck(UNIT a, UNIT b, char op){
	if(!(a.intFlag && b.intFlag)){
		string type1 = a.intFlag ? "int" : "float";
		string type2 = b.intFlag ? "int" : "float";
		printf("Error: invalid operand of types '%s' and '%s' to binary 'operator%c'!\n", type1.c_str(), type2.c_str(), op);
		exit(1);
	}
}

UNIT assign(int op_type, UNIT src1, UNIT src2) {
	switch(op_type){
	case OP_BNEG:
		if (src1.intFlag) src1.val.value = ~(int)src1.val.value;
		else {
			printf("Error: invalid operand of types 'float' to binary 'operator~'!\n");
			exit(1);
		}
		break;
	case OP_MINUS: 
		src1.val.value = -src1.val.value;
		break;
	case OP_MOD: 
		typeCheck(src1, src2, '%');
		src1.val.value = (int)src1.val.value % (int)src2.val.value;
		break;
	case OP_BAND:
		typeCheck(src1, src2, '&');
		src1.val.value = (int)src1.val.value & (int)src2.val.value;
		break;
	case OP_BXOR:
		typeCheck(src1, src2, '^');
		src1.val.value = (int)src1.val.value ^ (int)src2.val.value;
		break;
	case OP_BOR:
		typeCheck(src1, src2, '|');
		src1.val.value = (int)src1.val.value | (int)src2.val.value;
		break;
	case OP_ADD:
		src1.intFlag &= src2.intFlag;
		src1.val.value += (int)src2.val.value;
		break;
	case OP_SUB:
		src1.intFlag &= src2.intFlag;
		src1.val.value -= (int)src2.val.value;
		break;
	case OP_TIMES:
		src1.intFlag &= src2.intFlag;
		src1.val.value *= (int)src2.val.value;
		break;
	case OP_DIV:
		src1.intFlag &= src2.intFlag;
		src1.val.value /= (int)src2.val.value;
		break;
	case OP_ASSIGN:
		writeVar(src1.val.name, src2);
		src1.val.value = src2.val.value;
		break;
	default: 
		printf("Unkown operator type!\n");
		exit(1);
	}
	return src1;
}

void debugCheck(int flag, UNIT a, string b){
#ifdef DEBUG_ON
	if(flag == 1) printf("Value: %f; IntFlag: %d; Level: ", a.val.value, a.intFlag);
	else if(flag == 0) printf("Name: %s; IntFlag: %d; Level: ", a.val.name, a.intFlag);
	printf("%s", b.c_str());
#endif
}

void dump(UNIT a){
	if(a.intFlag) printf("%d", (int)a.val.value);
	else printf("%f", a.val.value);
}

%}

%token FLOAT VAR INT
%token LB RB BNEG MINUS PLUS
%token DIV MOD TIMES
%token BAND BXOR BOR
%token EQ DELIM CR

%%
text   : text input CR {printf("\n"); debugCheck(-1, $$, "Finish!\n");}
	| input CR {printf("\n"); debugCheck(-1, $$, "Finish!\n");};

input : input DELIM expr {printf("; "); dump($3);
		debugCheck(1, $3, "DELIM_input DELIM\n");}
	| input DELIM {debugCheck(1, $1, "DELIM_input DELIM\n");}
	| expr {dump($1); debugCheck(1, $1, "DELIM_expr\n");}; 

expr: varFactor EQ expr {$$ = assign(OP_ASSIGN, $1, $3);
		debugCheck(1, $$, "Expr_Assign\n");}
	| basicExpr51 {$$ = $1; debugCheck(1, $$, "Expr_51\n");}
	| basicExpr41 {$$ = $1; debugCheck(1, $$, "Expr_41\n");}
	| basicExpr31 {$$ = $1; debugCheck(1, $$, "Expr_31\n");}
	| basicExpr21 {$$ = $1; debugCheck(1, $$, "Expr_21\n");}
	| basicExpr20 {$$ = $1; debugCheck(1, $$, "Expr_20\n");}
	| basicExpr10 {$$ = $1; debugCheck(1, $$, "Expr_10\n");}
	| basicExpr01 {$$ = $1; debugCheck(1, $$, "Expr_01\n");}
	| basicExpr00 {$$ = $1; debugCheck(1, $$, "Expr_00\n");};

basicExpr51: basicExpr41 BOR basicExpr41 {$$ = assign(OP_BOR, $1, $3);
	debugCheck(1, $$, "Bexpr51_BOR 41\n");}

basicExpr41: basicExpr31 BXOR basicExpr31 {$$ = assign(OP_BXOR, $1, $3);
	debugCheck(1, $$, "Bexpr41_BXOR 31\n");}

basicExpr31: basicExpr21 BAND basicExpr21 {$$ = assign(OP_BAND, $1, $3);
	debugCheck(1, $$, "Bexpr31_BAND 21\n");};

basicExpr21: MINUS basicExpr20 {$$ = assign(OP_MINUS, $2, $$);
		debugCheck(1, $$, "Bexpr21_MINUS 20\n");}
	| PLUS basicExpr20 {$$ = $2; debugCheck(1, $$, "Bexpr21_PLUS 20\n");}
	| basicExpr20 {$$ = $1; debugCheck(1, $$, "Bexpr21_20\n");};

basicExpr20: basicExpr10 PLUS MINUS basicExpr10 {$$ = assign(OP_SUB, $1, $3);
		debugCheck(1, $$, "Bexpr20_ADD MINUS 10\n");}
	| basicExpr10 PLUS basicExpr10 {$$ = assign(OP_ADD, $1, $3);
		debugCheck(1, $$, "Bexpr20_ADD 10\n");}
	| basicExpr10 MINUS PLUS basicExpr10 {$$ = assign(OP_SUB, $1, $3);
		debugCheck(1, $$, "Bexpr20_SUB PLUS 10\n");}
	| basicExpr10 MINUS basicExpr10 {$$ = assign(OP_SUB, $1, $3);
		debugCheck(1, $$, "Bexpr20_SUB 10\n");}
	| basicExpr10 {$$ = $1; debugCheck(1, $$, "Bexpr20_10\n");};

basicExpr10: basicExpr00 DIV basicExpr01 {$$ = assign(OP_DIV, $1, $3);
		debugCheck(1, $$, "Bexpr10_DIV\n");}
	| basicExpr00 TIMES basicExpr01 {$$ = assign(OP_TIMES, $1, $3); 
		debugCheck(1, $$, "Bexpr10_TIMES\n");}
	| basicExpr00 MOD basicExpr01 {$$ = assign(OP_MOD, $1, $3); 
		debugCheck(1, $$, "Bexpr10_MOD\n");}
	| basicExpr00 {$$ = $1; debugCheck(1, $$, "Bexpr10_00\n");};

basicExpr01: MINUS basicExpr00 
		{$$ = assign(OP_MINUS, $2, $$); 
		debugCheck(1, $$, "Bexpr01_MINUS 00\n");}
	| PLUS basicExpr00 {$$ = $2; debugCheck(1, $$, "Bexpr01_PLUS 00\n");}
	| basicExpr00 {$$ = $1; debugCheck(1, $$, "Bexpr01_00\n");};

basicExpr00: BNEG factor {$$ = assign(OP_BNEG, $2, $$); 
		debugCheck(1, $$, "Bexpr00_BNEG Factor\n");}
	| normalFactor {$$ = $1; debugCheck(1, $$, "Bexpr00_nF\n");};

factor: MINUS normalFactor {$$ = assign(OP_MINUS, $2, $$); 
		debugCheck(1, $$, "Factor_MINUS nF\n");}
	| PLUS normalFactor {$$ = $2; debugCheck(1, $$, "Factor_PLUS nF\n");}
	| normalFactor {$$ = $1; debugCheck(1, $$, "Factor_nF\n");};

normalFactor: FLOAT {$$ = $1; debugCheck(1, $$, "NormalFactor_Float\n");}
	| INT {$$ = $1; debugCheck(1, $$, "NormalFactor_INT\n");}
	| varFactor {$$ = readVar($1.val.name); 
		debugCheck(1, $$, "NormalFactor_vF\n");}
	| bracketFactor {$$ = $1; debugCheck(1, $$, "NormalFactor_bF\n");};

bracketFactor: LB expr RB {$$ = $2; debugCheck(1, $$, "Bracket\n");};

varFactor: VAR {$$ = $1; debugCheck(0, $$, "Var\n");};

%%
int main()
{
  //printf("Variable's name must be within 20 chars!\n");
  yyparse();
  return 0;
}

int yyerror(const char *msg)
{
  printf("Error encountered: %s \n", msg);
}

