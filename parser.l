%{
#define YYSTYPE char *
#include"y.tab.h"
int cur_line = 1;
void yyerror(const char* msg);
void unrecognized_char(char c);
%}

/* \042 is '"'*/

OPERATOR       ([-/+*()=,;!<>{}])
INTEGER        ([0-9]+)
STRING         (\042[^042\n]*\042)
IDENTIFIER     ([_a-zA-Z][_a-zA-Z0-9]*)
WHITESPACE     ([ \t]*)

%%
\n             {cur_line++;}
{OPERATOR}     {return yytext[0];}
"int"          {return T_INT;}
"print"        {return T_PRINT;}
"void"         {return T_VOID;}
"return"       {return T_RETURN;}
"input"        {return T_INPUT;}
"while"        {return T_WHILE;}
"if"           {return T_IF;}
"else"         {return T_ELSE;}
"break"        {return T_BREAK;}
"<="           {return T_LE;}
">="           {return T_GE;}
"=="           {return T_EQ;}
"!="           {return T_NE;}
"&&"           {return T_AND;}
"||"           {return T_OR;}

{INTEGER}      {yylval = strdup(yytext);return T_INTCONSTANT;}
{STRING}       {yylval = strdup(yytext);return T_STRINGCONSTANT;}
{IDENTIFIER}   {yylval = strdup(yytext);return T_IDENTIFIER;}

{WHITESPACE}   {}
\n             {cur_line++;}
.              {unrecognized_char(yytext[0]);}
%%

int yywrap(){
    return 1;
}

void unrecognized_char(char c)
{
    char buf[32] = " unrecognized character:?";
    buf[24] = c;
    yyerror(buf);
}

void yyerror(const char* msg)
{
    printf("error at line%d:\n\t%s\n",cur_line, msg);
    exit(-1);
}