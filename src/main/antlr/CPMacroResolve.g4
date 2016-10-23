grammar CPMacroResolve;
//import CPreprocessorLexerRule;


options {
  tokenVocab = CPreprocessorLexerRule;
}
// Assumptions for the input statement:
// 1. No block/line comment exists.
// 2. No '#' character exists.
// 3. No preprocessor keywords exists except "defined"

statement : sToken+ ;

sToken : stDefined
       | stFunctionCall
       | stVariable
       | stOther
       ;

stDefined : DEFINED    WS+ stdId ;
stdId     : PAREN_OPEN WS* stdId WS* PAREN_CLOSE
          | stdiId
          ;
stdiId    : ID ;

stVariable : ID ;

stFunctionCall : ID WS* PAREN_OPEN stfcArguments PAREN_CLOSE ;
stfcArguments  : stfcaArgument ( COMMA stfcaArgument )* ;
stfcaArgument  : ( PAREN_OPEN stfcaArgument PAREN_CLOSE | STRING | WS | ID | CHAR )*    ;

stOther        :    ( STRING | WS | COMMA | PAREN_OPEN | PAREN_CLOSE | CHAR )    ;
