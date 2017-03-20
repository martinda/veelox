# Antlr grammar for C/C++ Preprocessor.

I made a Lexer/Parser/Application of C-preprocessor with Antlr and C#. I
like to share my work with anybody who may have interest in doing it by
himself or herself.

Of course, there will be many or better ways to do the same thing than
the way I did. Here is a summary of how I did.

* Lexer A and Parser A take a C/C++ source text string and parse macro keywords such as #include, #define, #if, #ifdef, #ifndef and so on.

* Application A stores #define keywords parsed from Parser A; there are two types of macro defines: one that takes arguments and another that doesn't take arguments.

* Whenever #if or #elif are encountered, the macro keywords in the condition statement are resolved with the stored define macros. This process is done by Lexer A, Parser B; Lexer A is reused. This step is repeated until there is nothing to be replaced. Once all of macro keywords are resolved, arithmetic calculation is performed with Lexer B, Parser C and Application B.


Let me show you an example of `#define` and `#if` statements.

```
    line1: #define VariableType 4
    line2: #define FunctionType( a, b )     a - VariableType * b
    line3:
    line4: #if FunctionType( (2*3), 2 ) + 1 * 2
    line5: #error "This should not be processed"
    line6: #else
    line7: #undef VariableType
    line8: #endif
```

In the line1, a new macro keyword, "VariableType", will be stored by
ApplicationA.

In the line2, a new macro keyword, "FunctionType", will be stored by
input argument information.

In the line4, the macro, "FunctionType( (2*3), 2 )", is replaced by the
definition and it will result in a new string, "(2*3) - VariableType *
2". The replacing step must be done after proper parser and that's why I
needed a second Parser B for the macro resolving. For example, without
Parser B, simple string replacement will cause errors in cases like
"FunctionType( FunctionType( 1, 3 ), 3 )".

Since a macro definition can include another macro define keywords,
one time macro resolving is not enough so the step had to be repeated
until there is no macro keyword left.

Once all of macro keywords are resolved, the calculation must be performed
based on operator precedence. That's where I needed 3rd Parser C and
second Lexer B. For the example, the parser will parse a statement,
"(2*3) - 4 * 2 + 1 * 2". This is a relatively simple calculator, which
is Application B.

Based on the calculation result, one of statement blocks, which is line 5
or line 7, are ignored and another statement is processed. In the example,
the calculation result is 0 and line7 will be processed.

I can share the Antlr grammars here but application source codes are
too long to be posted; I wrote C# applications.

Parser A, which I call CPreprocessor, is here:

```

    grammar CPreprocessor;
    import CPreprocessorLexerRule;
    // parser rules must start with lower case.

    @parser::members
    {
        protected const int EOF = Eof;
    }

    program        :    statement*    EOF    ;

    statement    :    preprocess
                |    ( COMMENT_BLOCK | COMMENT_LINE )
                |    STRING                        // ignore
                |    ( ppChars | NEWLINE )        // ignore
                ;

    // pp means preprocess
    preprocess    :    ppInclude
                |    ppDefineFunc    // this must be before ppDefineVar: eg. #define AAA  ( a ) 
                |    ppDefineVar
                |    ppUndef
                |    ppPragma
                |    ppError
                |    ppIfStatement
                ;

    ppChars        :    ( STRING | WS | PREPROCESS_BEGIN | DEFINED | ID | COMMA | PAREN_OPEN | PAREN_CLOSE | CHAR )+    ;

    ppInclude    :    PREPROCESS_BEGIN    WS*    PREPROCESS_INCLUDE    WS*    ppChars    WS*    ( NEWLINE | EOF )    ;
    ppPragma    :    PREPROCESS_BEGIN    WS*    PREPROCESS_PRAGMA    WS*    ppChars    WS*    ( NEWLINE | EOF )    ;
    ppError        :    PREPROCESS_BEGIN    WS*    PREPROCESS_ERROR    WS*    ppChars    WS*    ( NEWLINE | EOF )    ;

    ppUndef            :    PREPROCESS_BEGIN    WS*    PREPROCESS_UNDEF    WS+    ID                            WS*    ( NEWLINE | EOF )    ;
    ppDefineVar        :    PREPROCESS_BEGIN    WS*    PREPROCESS_DEFINE    WS+    ID        ( WS+    ppChars )?    WS*    ( NEWLINE | EOF )    ;
    ppDefineFunc    :    PREPROCESS_BEGIN    WS*    PREPROCESS_DEFINE    WS+    ppdfId    WS*    ppdfChars        WS*    ( NEWLINE | EOF )    ;

    // ppdfi means preprocess define function ID
    ppdfId            :    ID    PAREN_OPEN    WS*    ppdfiArguments    WS*    PAREN_CLOSE    ;    // WS between ID and '(' is not allowed.
    ppdfiArguments    :    ppdfiArgument    ( WS*    COMMA    WS*    ppdfiArgument    )*    ;    // at least 1 argument is required.
    ppdfiArgument    :    ID    ;

    // ppdfc means preprocess define function characters
    ppdfChars    :    ( ppdfcId | ppdfcNotId )+    ;
    ppdfcId        :    ID    ;
    ppdfcNotId    :    ( STRING | WS | PREPROCESS_BEGIN | DEFINED | COMMA | PAREN_OPEN | PAREN_CLOSE | CHAR )    ;


    ppIfStatement    :    ( ppisIF | ppisIfDef | ppisIfNdef )    ;

    ppisIF            :    PREPROCESS_BEGIN    WS*    PREPROCESS_IF        WS+    ppChars    WS*    NEWLINE            ppisStatement    ppisElifElseEndif    ;
    ppisElif        :    PREPROCESS_BEGIN    WS*    PREPROCESS_ELIF        WS+    ppChars    WS*    NEWLINE            ppisStatement    ppisElifElseEndif    ;
    ppisElse        :    PREPROCESS_BEGIN    WS*    PREPROCESS_ELSE                    WS*    NEWLINE            ppisStatement    ppisEndif    ;
    ppisEndif        :    PREPROCESS_BEGIN    WS*    PREPROCESS_ENDIF                WS*    (NEWLINE|EOF)    ;
    ppisIfDef        :    PREPROCESS_BEGIN    WS*    PREPROCESS_IFDEF    WS+    ID        WS*    NEWLINE            ppisStatement    ppisElseEndif    ;
    ppisIfNdef        :    PREPROCESS_BEGIN    WS*    PREPROCESS_IFNDEF    WS+    ID        WS*    NEWLINE            ppisStatement    ppisElseEndif    ;

    ppisStatement        :    statement*    ;
    ppisElifElseEndif    :    ppisElif
                        |    ppisElseEndif
                        ;
    ppisElseEndif        :    ppisElse
                        |    ppisEndif
                        ;
```

Lexer A, which I call "CPreprocessorLexerRule", is here:

```
    lexer grammar CPreprocessorLexerRule;
    // lexer rules must start with upper case.

    @lexer::members {
        public const int CHANNEL_COMMENT_BLOCK = 1;
        public const int CHANNEL_COMMENT_LINE = 2;
        protected const int EOF = Eof;
        protected const int HIDDEN = Hidden;
    }

    //=======================================================================
    COMMENT_BLOCK        :    '/*'    .*?        '*/'            -> channel(CHANNEL_COMMENT_BLOCK) ;
    COMMENT_LINE        :    '//'    NOT_NL*                    -> channel(CHANNEL_COMMENT_LINE) ;
    NL_ESC                :    '\\'    NL                        -> skip ;
    STRING                :    '"'    (STRING_ESC|.)*?    '"'        ;
    WS                    :    ' '    |    '\t'                    ;    // preprocessor cannot "skip" white space, because wb matters in several cases.
    NEWLINE                :    NL                                ;    // preprocessor cannot "skip" new line, because wb matters in several cases.
    PREPROCESS_BEGIN    :    '#'                                ;

    //=======================================================================
    // nmode doesn't seem to work for C#
    // mode preprocessMode;
    //=======================================================================
    PREPROCESS_INCLUDE    :    'include'    ;
    PREPROCESS_DEFINE    :    'define'    ;
    PREPROCESS_UNDEF    :    'undef'        ;
    PREPROCESS_IFDEF    :    'ifdef'        ;    // this must appear before 'if'
    PREPROCESS_IFNDEF    :    'ifndef'    ;    // this must appear before 'if'
    PREPROCESS_IF        :    'if'        ;
    PREPROCESS_ELSE        :    'else'        ;
    PREPROCESS_ELIF        :    'elif'        ;
    PREPROCESS_ENDIF    :    'endif'        ;
    PREPROCESS_PRAGMA    :    'pragma'    ;
    PREPROCESS_ERROR    :    'error'        ;

    //=======================================================================
    // These must be below reserved keywords
    //=======================================================================
    DEFINED        :    'defined'    ;
    ID            :    ID_LETTER    (ID_LETTER|DIGIT)*    ;
    COMMA        :    ','                                ;
    PAREN_OPEN    :    '('                                ;
    PAREN_CLOSE    :    ')'                                ;
    CHAR        :    '\''    .    '\''
                |    .                                // the rest of all
                ;

    //=======================================================================
    // fragment can be referenced only by lexer.
    // fragment itself is not lexer rule so that it cannot be used by parser.
    //=======================================================================
    fragment ID_LETTER    :    [a-zA-Z_]            ;
    fragment DIGIT        :    [0-9]                ;
    fragment STRING_ESC    :    '\\'    [btnr0"\\]    ; // \b, \t, \n etc...
    fragment NL            :    '\r'?    '\n'        ;
    fragment NOT_NL        :    ~[\r\n]                ;

```

Parser B, which I call "CPMacroResolve", is here:

```
    grammar CPMacroResolve;
    import CPreprocessorLexerRule;

    // Asttumptions for the input statement:
    // 1. No block/line comment exists.
    // 2. No '#' character exists.
    // 3. No preprocessor keywords exists except "defined"

    statement    :    sToken+    ;

    sToken        :    stDefined
                |    stFunctionCall
                |    stVariable
                |    stOther
                ;

    stDefined    :    DEFINED    WS+    stdId    ;
    stdId        :    PAREN_OPEN    WS*    stdId    WS*    PAREN_CLOSE
                |    stdiId
                ;
    stdiId        :    ID    ;

    stVariable    :    ID    ;

    stFunctionCall    :    ID    WS*    PAREN_OPEN    stfcArguments    PAREN_CLOSE    ;
    stfcArguments    :    stfcaArgument    ( COMMA    stfcaArgument )*    ;
    stfcaArgument    :    ( PAREN_OPEN    stfcaArgument    PAREN_CLOSE | STRING | WS | ID | CHAR )*    ;

    stOther        :    ( STRING | WS | COMMA | PAREN_OPEN | PAREN_CLOSE | CHAR )    ;
```


Parser C, which I call "CPCondition", is here:

```
    grammar CPCondition;
    import CPConditionLexerRule;

    // Assumptions:
    // 1. Lexer will remove white spaces.

    condition    : expression ;

    // Indirect left-recursion for binary/ternary expressions is solved by "direct" left-recursion
    expression    :    PAREN_OPEN    expression    PAREN_CLOSE                                                    # ceParen
                |    unaryExpression                                                                        # ceUnary
                |    expression    op=(AOP_MUL|AOP_DIV|AOP_MOD)        expression                            # ceMulDivMod
                |    expression    op=(AOP_ADD|AOP_SUB)                expression                            # ceAddSub
                |    expression    op=(BOP_SHL|BOP_SHR)                expression                            # ceShlShr
                |    expression    op=(CMP_LE|CMP_LT|CMP_GE|CMP_GT)    expression                            # ceCmpLeLtGeGt
                |    expression    op=(CMP_EQ|CMP_NE)                    expression                            # ceCmpEqNe
                |    expression    BOP_AND                                expression                            # ceBitAnd
                |    expression    BOP_XOR                                expression                            # ceBitXor
                |    expression    BOP_OR                                expression                            # ceBitOr
                |    expression    LOP_AND                                expression                            # ceLogicAnd
                |    expression    LOP_OR                                expression                            # ceLogicOr
                |    expression    TER_IF                                expression    TER_ELS    expression        # ceTerIf
                |    value                                                                                # ceValue
                ;

    unaryExpression    :    op=(AOP_ADD|AOP_SUB|BOP_NOT|LOP_NOT)    expression    ;

    value    :    val=FLOAT
            |    val=INT
            |    val=HEX
            |    val=OCT
            |    val=TRUE
            |    val=FALSE
            |    val=ID    // error
            ;

```

Lexer B, which I call "CPConditionLexerRule", is here:

```
    lexer grammar CPConditionLexerRule;

    // Logic operator
    LOP_AND    :    '&&'    ;
    LOP_OR    :    '||'    ;
    LOP_NOT    :    '!'    ;

    // Bit operator
    BOP_NOT    :    '~'    ;
    BOP_XOR    :    '^'    ;
    BOP_AND    :    '&'    ;
    BOP_OR    :    '|'    ;
    BOP_SHL    :    '<<'    ;
    BOP_SHR    :    '>>'    ;

    // Arithmatic operator
    AOP_ADD    :    '+'    ;
    AOP_SUB    :    '-'    ;
    AOP_MUL    :    '*'    ;
    AOP_DIV    :    '/'    ;
    AOP_MOD    :    '%'    ;

    // Comparison operator
    CMP_EQ    :    '=='    ;
    CMP_NE    :    '!='    ;
    CMP_LE    :    '<='    ;
    CMP_LT    :    '<'    ;
    CMP_GE    :    '>='    ;
    CMP_GT    :    '>'    ;

    // Ternary conditional
    TER_IF    :    '?'    ;
    TER_ELS    :    ':'    ;

    // Parentheses
    PAREN_OPEN    :    '('    ;
    PAREN_CLOSE    :    ')'    ;

    // Reserved keyword
    DEFINED    :    'defined'    ;
    TRUE    :    'true'    ;
    FALSE    :    'false'    ;

    // typed values
    FLOAT    :    DIGIT+    '.'    DIGIT*    'f'?            // match 1. 39. 3.14159 etc...
            |            '.'    DIGIT+    'f'?            // match .1 .14159
            ;
    INT        :    [1-9]    DIGIT*
            |    '0'
            ;
    HEX        :    '0x'    DIGIT+    ;    // 0x000
    OCT        :    '0'        DIGIT+    ;    // 0123
    ID        :    ID_LETTER    (ID_LETTER|DIGIT)*    ;

    // skip
    NL_ESC    :    '\\'    '\r'?    '\n'    -> skip ;
    WS        :    [ \t]+                    -> skip ;


    // fragments
    fragment ID_LETTER    :    [a-zA-Z_]    ;
    fragment DIGIT        :    [0-9]    ;

```
I am hoping that this information can be helpful for anybody who is planning to make their own version of C preprocessor or any kind of preprocessors.

I read one IBM guy suggested that all of C preprocessing should be done by Lexer only. I don't see if it is a better way or not because as I described, C preprocessor also need parsing steps several times.
