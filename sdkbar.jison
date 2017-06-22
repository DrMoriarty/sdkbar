/* Sdkbar/Sdkbox config file parser */

%start prog

%ebnf

/* operator associations and precedence */
%left 'AND' 'OR'
%left 'EQ' 'NE'
%left '+' '-'
%left '*' '/'

%% /* language grammar */

eol
    : EOL
    ;

variable
    : TOKEN
    ;

array_element
    : TOKEN '[' NUMBER ']'
    { $$ = ['INDEX', $1, $3]; }
    | long_token '[' NUMBER ']'
    { $$ = ['INDEX', $1, $3]; }
    ;

array
    : '[' arg_list ']'
      { $$ = $2; }
    ;

string
    : STRING
    | MULTILINE_STRING
    ;

rvalue
    : variable
    | string
    | object
    ;

object_start
    : '{'
    { this.object_stack = this.object_stack || [];  this.object_stack.push({}); $$ = $1; }
    ;

object_end
    : '}'
    { var ob = this.object_stack.pop(); }
    ;

object_declaration
    : string ':' rvalue
    { var key = $1.substring(1, $1.length-1); var obj = this.object_stack[this.object_stack.length-1]; obj[key] = $3; $$ = obj; }
    | string ':' rvalue COMMA object_declaration
    { var key = $1.substring(1, $1.length-1); var obj = this.object_stack[this.object_stack.length-1]; obj[key] = $3; $$ = obj; }
    ;

object
    : object_start object_declaration object_end
    { $$ = $2; }
    ;

operand
    : string
    | NUMBER
    | TRUE
    | FALSE
    | variable
    | function_call
    | array_element
    | array
    | long_token
    ;

expression
    : operand
    | object
    | expression AND expression
    { $$ = ['AND', $1, $3]; }
    | expression OR expression
    { $$ = ['OR', $1, $3]; }
    | expression EQ expression
    { $$ = ['EQ', $1, $3]; }
    | expression NE expression
    { $$ = ['NE', $1, $3]; }
    | expression '+' expression
    { $$ = ['ADD', $1, $3]; }
    | expression '-' expression
    { $$ = ['SUB', $1, $3]; }
    | expression '*' expression
    { $$ = ['MUL', $1, $3]; }
    | expression '/' expression
    { $$ = ['DIV', $1, $3]; }
    | '(' expression ')'
    { $$ = $2; }
    ;

arg_list
    : expression
      { $$ = [$1]; }
    | arg_list COMMA expression
      { $1.push($3); $$ = $1; }
    | arg_list COMMA assignment
      { $1.push($3); $$ = $1; }
    ;

long_token
    : TOKEN DOT TOKEN
      { $$ = $1+$2+$3; }
    | TOKEN DOT long_token
      { $$ = $1+$2+$3; }
    ;

function_call
    : TOKEN '(' arg_list ')'
    { $3.unshift($1); $$ = $3; }
    | long_token '(' arg_list ')'
    { $3.unshift($1); $$ = $3; }
    ;

if_statement
    : IF expression ':' block
    { $$ = ['IF', $expression, $block]; }
    | IF expression ':' block ELSE block
    { $$ = ['IF', $expression, $4, $6]; }
    ;

assignment
    : TOKEN '=' expression
    { $$ = ['ASSIGN', $1, $3]; }
    ;

line
    : if_statement
    | assignment
    | function_call
    ;

blockcontent
    : line
    { $$ = [$1]; }
    | line blockcontent
    { $2.unshift($1); $$ = $2; }
    ;

block
    : INDENT blockcontent DEDENT
    { $$ = $2; }
    ;

prog
    : blockcontent EOF EOF
    { yy.ast($1); $$ = $1; }
    ;
