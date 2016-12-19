lexer grammar SystemVerilogLexer;

@lexer::header {
    package ca.martinda.veelox;
}
ID : [a-z]+ ;
WS : [ \\t\\r\\n]+ -> skip ;
