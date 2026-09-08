package steps;

import io.cucumber.junit.Cucumber;
import io.cucumber.junit.CucumberOptions;
import org.junit.runner.RunWith;

@RunWith(Cucumber.class)
@CucumberOptions(
    features = "src/test/resources/features",
    glue = "steps",
    plugin = {"pretty", "html:build/cucumber-report/cucumber-html-report.html", "json:build/cucumber-report/cucumber.json"}
)
public class CucumberJunit4Runner {
    // Empty: runner is configured via annotations
}
