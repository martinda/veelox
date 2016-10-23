grammar CPreprocessor;
//import CPreprocessorLexerRule;
// parser rules must start with lower case.

options {
  tokenVocab = CPreprocessorLexerRule;
}

@parser::members
{
    protected const int EOF = Eof;
}

program : statement*    EOF    ;

statement : preprocess
          | ( COMMENT_BLOCK | COMMENT_LINE )
          | STRING                        // ignore
          | ( ppChars | NEWLINE )        // ignore
          ;

// pp means preprocess
preprocess : ppInclude
           | ppDefineFunc    // this must be before ppDefineVar: eg. #define AAA  ( a ) 
           | ppDefineVar
           | ppUndef
           | ppPragma
           | ppError
           | ppIfStatement
           ;

ppChars : ( STRING | WS | PREPROCESS_BEGIN | DEFINED | ID | COMMA | PAREN_OPEN | PAREN_CLOSE | CHAR )+    ;

ppInclude    : PREPROCESS_BEGIN WS* PREPROCESS_INCLUDE WS* ppChars WS* ( NEWLINE | EOF ) ;
ppPragma     : PREPROCESS_BEGIN WS* PREPROCESS_PRAGMA  WS* ppChars WS* ( NEWLINE | EOF ) ;
ppError      : PREPROCESS_BEGIN WS* PREPROCESS_ERROR   WS* ppChars WS* ( NEWLINE | EOF ) ;

ppUndef      : PREPROCESS_BEGIN WS* PREPROCESS_UNDEF   WS+ ID                     WS* ( NEWLINE | EOF ) ;
ppDefineVar  : PREPROCESS_BEGIN WS* PREPROCESS_DEFINE  WS+ ID ( WS+    ppChars )? WS* ( NEWLINE | EOF ) ;
ppDefineFunc : PREPROCESS_BEGIN WS* PREPROCESS_DEFINE  WS+ ppdfId  WS* ppdfChars  WS* ( NEWLINE | EOF ) ;

// ppdfi means preprocess define function ID
ppdfId         : ID    PAREN_OPEN    WS*    ppdfiArguments    WS*    PAREN_CLOSE    ;    // WS between ID and '(' is not allowed.
ppdfiArguments : ppdfiArgument    ( WS*    COMMA    WS*    ppdfiArgument    )*    ;    // at least 1 argument is required.
ppdfiArgument  : ID    ;

// ppdfc means preprocess define function characters
ppdfChars    : ( ppdfcId | ppdfcNotId )+    ;
ppdfcId      : ID    ;
ppdfcNotId   : ( STRING | WS | PREPROCESS_BEGIN | DEFINED | COMMA | PAREN_OPEN | PAREN_CLOSE | CHAR )    ;


ppIfStatement : ( ppisIF | ppisIfDef | ppisIfNdef )    ;

ppisIF     : PREPROCESS_BEGIN  WS* PREPROCESS_IF     WS+ ppChars WS* NEWLINE  ppisStatement ppisElifElseEndif ;
ppisElif   : PREPROCESS_BEGIN  WS* PREPROCESS_ELIF   WS+ ppChars WS* NEWLINE  ppisStatement ppisElifElseEndif ;
ppisElse   : PREPROCESS_BEGIN  WS* PREPROCESS_ELSE               WS* NEWLINE  ppisStatement ppisEndif    ;
ppisEndif  : PREPROCESS_BEGIN  WS* PREPROCESS_ENDIF              WS* (NEWLINE|EOF)  ;
ppisIfDef  : PREPROCESS_BEGIN  WS* PREPROCESS_IFDEF  WS+ ID      WS* NEWLINE  ppisStatement ppisElseEndif ;
ppisIfNdef : PREPROCESS_BEGIN  WS* PREPROCESS_IFNDEF WS+ ID      WS* NEWLINE  ppisStatement ppisElseEndif ;

ppisStatement     : statement*    ;

ppisElifElseEndif : ppisElif
                  | ppisElseEndif
                  ;
ppisElseEndif : ppisElse
              | ppisEndif
              ;
