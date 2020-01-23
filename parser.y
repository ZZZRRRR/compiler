%{
#define YYSTYPE char*
#include <stdio.h>
#include <stdlib.h>
void yyerror(const char*);
int ii = 0,itop = -1,istack[100];
int ww = 0,wtop = -1,wstack[100];
#define _BEG_IF            {istack[++itop] = ++ii;}
#define _END_IF            {itop--;}
#define _i                 (istack[itop])

#define _BEG_WHILE         {wstack[++wtop] = ++ww;}
#define _END_WHILE         {wtop--;}
#define _w                 (wstack[wtop])

%}

%token T_IF T_ELSE T_BREAK T_LE T_GE T_EG T_NE
%token T_INTCONSTANT T_IDENTIFIER T_STRINGCONSTANT
%token T_VOID T_RETURN T_INT T_PRINT T_INPUT T_WHILE

%left '='
%left T_OR T_AND
%left T_EQ T_NE
%left '<' '>' T_LE T_GE
%left '+' '-'
%left '*' '/' '%'
%left '!'

%%

PROGRAM:                         {}
       | PROGRAM FUNCDECL        {}
       ;

FUNCDECL: RETTYPE FUNCNAME '(' ARGS ')' '{' VARDECLS STMTS '}' {printf("ENDFUNC\n\n");}
        ;

RETTYPE: T_INT                   {}
       | T_VOID                  {}
       ;

FUNCNAME:T_IDENTIFIER            {printf("FUNC @%s:\n",$1);}
        ;

ARGS:                             {}
    |_ARGS                        {printf("\n\n");}
    ;

_ARGS:T_INT T_IDENTIFIER           {printf("\targ %s",$2);}
     |_ARGS ',' T_INT T_IDENTIFIER {printf(",%s",$4);}
     ;

VARDECLS:                       {}
        | VARDECLS VARDECL ';'  {printf("\n\n");}
        ;

VARDECL: T_INT T_IDENTIFIER       {printf("\tvar %s",$2);}
       | VARDECL ',' T_IDENTIFIER {printf(", %s",$3);}
       ;

STMTS:                                {}
     | STMTS STMT                     {}
    ;

STMT: CALL                       {}
    | ASSIGN                     {}
    | PRINT                      {}
    | RETURN                     {}
    | IF                         {}
    | WHILE                      {}
    | BREAK                      {}
    ;

ASSIGN: T_IDENTIFIER '=' E ';'   {printf("\tpop %s\n\n",$1);}
      ;

PRINT: T_PRINT '(' T_STRINGCONSTANT ACTUALS ')' ';' {printf("\tprint %s\n\n",$3);}
     ;

ACTUALS:                        {}
       | ACTUALS ',' E          {}
       ;

CALL: _CALL ';'                 {printf("\tpop\n\n");}
    ;

_CALL: T_IDENTIFIER '(' _ACTUALS')' {printf("\t$%s\n",$1);}
    ;

_ACTUALS:                        {}
        | E ACTUALS              {}
        ;

RETURN: T_RETURN E ';'           {printf("\tret ~\n\n");}
      | T_RETURN ';'             {printf("\tret\n\n");}
      ;

IF: _IF TESTE THEN STMTSBLOCK ENDTHEN ENDIF   {}
  | _IF TESTE THEN STMTSBLOCK ENDTHEN ELSE STMTSBLOCK ENDIF {}
  ;

TESTE: '(' E ')'                 {}
     ;

STMTSBLOCK: '{'STMTS'}'          {}
          ;

_IF: T_IF                        {_BEG_IF;printf("_begif_%d:\n",_i);}
    ;

THEN:                            {printf("\tjz _elif_%d\n",_i);}
    ;

ENDTHEN:                         {printf("\tjmp _endif_%d\n_elif_%d:\n",_i,_i);}
       ;

ELSE: T_ELSE                     {}
    ;

ENDIF:                           {printf("_endif_%d:\n\n",_i);_END_IF;}
     ;

WHILE: _WHILE TESTE DO STMTSBLOCK ENDWHILE       {}
     ;

_WHILE: T_WHILE                                  {_BEG_WHILE;printf("_BEGWHILE_%d:\n",_w);}
      ;

DO:                               {printf("\tjz _ENDWHILE_%d\n",_w);}
  ;

ENDWHILE:                         {printf("\tjmp _BEGWHILE_%d\n_ENDWHILE_%d:\n\n",_w,_w);_END_WHILE;}
        ;

BREAK: T_BREAK ';'                   {printf("\tjmp _ENDWHILE_%d\n",_w);}
     ;

E   : E '+' E                    {printf("\tadd\n");}
    | E '-' E                    {printf("\tsub\n");}
    | E '*' E                    {printf("\tmul\n");}
    | E '/' E                    {printf("\tdiv\n");}
    | E '%' E                    {printf("\tmod\n");}
    | E '>' E                    {printf("\tcmpgt\n");}
    | E '<' E                    {printf("\tcmplt\n");}
    | E T_GE E                   {printf("\tcmpge\n");}
    | E T_LE E                   {printf("\tcmple\n");}
    | E T_EQ E                   {printf("\tcmpeq\n");}
    | E T_OR E                   {printf("\tor\n");}
    | E T_AND E                  {printf("\tand\n");}
    | '-' E %prec '!'            {printf("\tneg\n");}
    | '!' E                      {printf("\tnot\n");}
    | T_INTCONSTANT              {printf("\tpush %s\n",$1);}
    | T_IDENTIFIER               {printf("\tpush %s\n",$1);}
    | INPUT                      {}
    | _CALL                      {}
    | '(' E ')'                  {}

INPUT: T_INPUT '(' T_STRINGCONSTANT ')'       {printf("\tinput %s\n",$3);}
     ;

%%

int main(){
    return yyparse();
}