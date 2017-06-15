/* Sdkbar/Sdkbox config file parser */

/* lexical grammar */

%lex

%s expect_indent
%s expect_object

%%

\#[^\n]*                return 'COMMENT';
"{"                     { this.begin('expect_object'); return '{'; }
<expect_object>"}"      { this.popState(); return '}'; }
<expect_object>[\s\n]+  /* skip space in object declaration */
\n                      { this.begin('expect_indent'); return 'EOL'; }
<expect_indent>[ ]+     { this.begin('INITIAL'); return 'INDENT'; }
[ ]+                    /*  skip space */
[0-9]+("."[0-9]+)?\b    return 'NUMBER';
\'\'\'[^\']+\'\'\'      return 'MULTILINE_STRING'
\"[^\"]*\"              return 'STRING';
\'[^\']*\'              return 'STRING';
"*"                     return '*'
"/"                     return '/'
"-"                     return '-'
"+"                     return '+'
"=="                    return 'EQ'
"!="                    return 'NE'
"and"                   return 'AND'
"or"                    return 'OR'
"="                     return '='
"("                     return '('
")"                     return ')'
"["                     return '['
"]"                     return ']'
\.                      return '.'
","                     return ','
":"                     return ':'
"if"                    { this.begin('INITIAL'); return 'IF'; }
"else:"                 { this.begin('INITIAL'); return 'ELSE'; }
"True"                  return 'TRUE'
"False"                 return 'FALSE'
[a-zA-Z_]+[a-zA-Z_0-9]* { this.begin('INITIAL'); return 'TOKEN'; }
<<EOF>>                 return 'EOF'
.                       return 'INVALID'


/lex

/* operator associations and precedence */

%left 'AND' 'OR'
%left 'EQ' 'NE'
%left '+' '-'
%left '*' '/'

%start translation_unit

%% /* language grammar */

comment
    : COMMENT
      { yy.comment($1); $$ = $1; }
    ;

eol
    : EOL
    ;

variable
    : TOKEN
    ;

array_element
    : TOKEN '[' NUMBER ']'
    | long_token '[' NUMBER ']'
    ;

array
    : '[' arg_list ']'
      { $$ = $2; }
    ;

string
    : STRING
    | MULTILINE_STRING
    ;

object_start
    : '{'
    { this.current_object = {}; $$ = $1; }
    ;

object_end
    : '}'
    { var ob = this.current_object; this.current_object = null; $$ = ob; }
    ;

object_declaration
    : string ':' string
    { var key = $1.substring(1, $1.length-1); this.current_object[key] = $3; $$ = this.current_object; }
    | string ':' string ',' object_declaration
    { var key = $1.substring(1, $1.length-1); this.current_object[key] = $3; $$ = this.current_object; }
    ;

object
    : object_start object_declaration object_end
    { $$ = $3; }
    ;

operand
    : string
    | NUMBER
    | TRUE
    | FALSE
    | variable
    | inline_function_call
    | array_element
    | array
    | long_token
    ;

expression
    : operand
    | object
    | expression AND expression
      { $$ = yy.logic_operation($2, $1, $3); }
    | expression OR expression
      { $$ = yy.logic_operation($2, $1, $3); }
    | expression EQ expression
      { $$ = yy.logic_operation($2, $1, $3); }
    | expression NE expression
      { $$ = yy.logic_operation($2, $1, $3); }
    | expression '+' expression
      { $$ = yy.operation($2, $1, $3); }
    | expression '-' expression
      { $$ = yy.operation($2, $1, $3); }
    | expression '*' expression
      { $$ = yy.operation($2, $1, $3); }
    | expression '/' expression
      { $$ = yy.operation($2, $1, $3); }
    | '(' expression ')'
    ;

arg_list
    : expression
      { $$ = [$1]; }
    | arg_list ',' expression
      { $1.push($3); $$ = $1; }
    | arg_list ',' inline_assignment
      { $1.push($3); $$ = $1; }
    ;

long_token
    : TOKEN '.' TOKEN
      { $$ = $1+$2+$3; }
    | TOKEN '.' long_token
      { $$ = $1+$2+$3; }
    ;

function_call
    : TOKEN '(' arg_list ')'
    { $$ = yy.call_function(0, $1, $3); }
    | INDENT TOKEN '(' arg_list ')'
    { $$ = yy.call_function(@1.last_column, $2, $4); }
    | long_token '(' arg_list ')'
    { $$ = yy.call_function(0, $1, $3); }
    | INDENT long_token '(' arg_list ')'
    { $$ = yy.call_function(@1.last_column, $2, $4); }
    ;

inline_function_call
    : TOKEN '(' arg_list ')'
    { $$ = yy.inline_call_function($1, $3); }
    | long_token '(' arg_list ')'
    { $$ = yy.inline_call_function($1, $3); }
    ;

if_statement
    : IF expression ':'
    { $$ = yy.if_condition(0, $2); }
    | INDENT IF expression ':'
    { $$ = yy.if_condition(@1.last_column, $3); }
    ;

else_statement
    : ELSE
    { $$ = yy.else_condition(0); }
    | INDENT ELSE
    { $$ = yy.else_condition(@1.last_column); }
    ;

inline_assignment
    : TOKEN '=' expression
    { $$ = yy.inline_assign($1, $3); }
    ;    

assignment
    : TOKEN '=' expression
    { $$ = yy.assign(0, $1, $3); }
    | INDENT TOKEN '=' expression
    { $$ = yy.assign(@1.last_column, $2, $4); }
    ;

line
    : comment eol
    | if_statement eol
    | else_statement eol
    | assignment eol
    | function_call eol
    | eol
    ;

translation_unit
    : line translation_unit
    | EOF
    ;
