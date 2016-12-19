package ca.martinda.veelox;

import org.junit.Rule
import org.junit.rules.TemporaryFolder
import spock.lang.Specification

class GrammerTest extends Specification {
    @Rule final TemporaryFolder testProjectDir = new TemporaryFolder()
    File svFile;

    def setup() {
        svFile = testProjectDir.newFile('file.sv')
    }

    def "hello world task prints hello world"() {
        given:
        svFile << """

        """

        when:
        String[] args = {"${svFile}"}
        SystemVerilogCompiler.main(args)

        then:
        assert(true);
    }
}
