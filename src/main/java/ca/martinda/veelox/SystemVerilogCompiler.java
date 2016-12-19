package ca.martinda.veelox;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.ByteChannel;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import net.sourceforge.argparse4j.ArgumentParsers;
import net.sourceforge.argparse4j.inf.ArgumentParser;
import net.sourceforge.argparse4j.inf.ArgumentParserException;
import net.sourceforge.argparse4j.inf.Namespace;

public class SystemVerilogCompiler {

    public static void main(String[] args) {
        ArgumentParser parser = ArgumentParsers.newArgumentParser("SystemVerilogCompiler")
                .defaultHelp(true)
                .description("Compiles SystemVerilog files");
        parser.addArgument("debug");
        parser.addArgument("file").nargs("*")
                .help("Verilog files to compile");
        Namespace ns = null;
        try {
            ns = parser.parseArgs(args);
        } catch (ArgumentParserException e) {
            parser.handleError(e);
            System.exit(1);
        }
        for (String name : ns.<String> getList("file")) {
            Path path = Paths.get(name);
            SystemVerilogMainProcessor svmp = new SystemVerilogMainProcessor();
            svmp.setDebug(ns.getBoolean("debug"));
            svmp.process(name);
        }
    }

}
