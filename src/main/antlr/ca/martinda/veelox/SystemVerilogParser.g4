grammar SystemVerilogParser;
import SystemVerilogLexer;

@parser::header {
    package ca.martinda.veelox;
}

r  : 'hello' ID ;
ID : [a-z]+ ;
WS : [ \\t\\r\\n]+ -> skip ;
