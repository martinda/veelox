# veelox

An experiment in preprocessing.

Hopefully it leads to a SystemVerilog compiler and simulator.

The first challenge is to create a pre-processor.

## How to build

This project is built with Gradle and Antlr.

```
./gradlew generateGrammarSource
```

# Notes

When running `./gradlew build` antlr gives this error:

```
error(160): ca/martinda/veelox/SystemVerilogPreprocessorParser.g4:6:17: cannot find tokens file /home/martin/git/veelox/build/generated-src/antlr/main/SystemVerilogPreprocessorLexer.tokens
```

The tokens file exists but not in the place where antlr is looking.
Possibly related to:
https://github.com/gradle/gradle/issues/1240



