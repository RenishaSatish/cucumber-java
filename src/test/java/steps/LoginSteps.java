package steps;

import com.microsoft.playwright.*;
import io.cucumber.java.After;
import io.cucumber.java.Before;
import io.cucumber.java.Scenario;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

import static org.junit.jupiter.api.Assertions.*;

public class LoginSteps {
    private Playwright playwright;
    private Browser browser;
    private BrowserContext context;
    private Page page;

    @Before
    public void setUp() {
        boolean headless = true;
        String headlessEnv = System.getenv("PLAYWRIGHT_HEADLESS");
        if (headlessEnv != null && headlessEnv.equalsIgnoreCase("false")) {
            headless = false;
        }
        playwright = Playwright.create();
        browser = playwright.chromium().launch(new BrowserType.LaunchOptions().setHeadless(headless));
        context = browser.newContext();
        page = context.newPage();
    }

    @After
    public void tearDown(Scenario scenario) {
        try {
            // always save a screenshot into build/cucumber-report/screenshots
            Path screenshotsDir = Paths.get("build", "cucumber-report", "screenshots");
            Files.createDirectories(screenshotsDir);
            String name = scenario.getName().replaceAll("[^a-zA-Z0-9._-]", "_") + "_" + System.currentTimeMillis() + ".png";
            Path shotPath = screenshotsDir.resolve(name);
            byte[] bytes = page.screenshot(new Page.ScreenshotOptions().setFullPage(true));
            Files.write(shotPath, bytes);
            // attach to cucumber report (if supported by the engine)
            try {
                scenario.attach(bytes, "image/png", name);
            } catch (Exception ignored) {
            }
        } catch (IOException | PlaywrightException ignored) {
        } finally {
            if (context != null) context.close();
            if (browser != null) browser.close();
            if (playwright != null) playwright.close();
        }
    }

    @Given("I open the login page")
    public void openLogin() {
        page.navigate("https://voxspan-ts01-uks-portal-sa.azurewebsites.net/login");
        assertTrue(page.url().contains("/login"));
    }

    @When("I login with valid credentials")
    public void loginWithValid() {
        String email = System.getenv("PIPCALL_EMAIL");
        String password = System.getenv("PIPCALL_PASSWORD");
        if (email == null || password == null) {
            fail("Set PIPCALL_EMAIL and PIPCALL_PASSWORD environment variables before running the cucumber tests.");
        }
        performLogin(email, password);
    }

    @When("I login with invalid credentials")
    public void loginWithInvalid() {
        // use an explicit invalid pair so the negative flow is deterministic
        performLogin("invalid_user@example.com", "bad_password");
    }

    private void performLogin(String email, String password) {
        Locator emailLocator = page.locator("input[name=\"email\"], input[type=\"email\"], input[placeholder=\"Email\"]").first();
        Locator passwordLocator = page.locator("input[name=\"password\"], input[type=\"password\"], input[placeholder=\"Password\"]").first();
        emailLocator.fill(email);
        passwordLocator.fill(password);
        page.locator("button:has-text(\"Sign In\"), button[type=\"submit\"], button#submitForm").first().click();
            // Wait for navigation to dashboard (allow slight delay). Prefer waiting for a URL pattern,
            // fall back to a short sleep if the wait fails.
            try {
                // wait up to 8s for known dashboard path segments to appear in the URL
                page.waitForURL("**/admin/**", new Page.WaitForURLOptions().setTimeout(8000));
            } catch (PlaywrightException ignored) {
                try {
                    page.waitForTimeout(2000);
                } catch (PlaywrightException ignored2) {
                }
            }
        }

    @Then("I should land on the admin dashboard")
    public void validateDashboard() {
        String url = page.url();
        assertTrue(url.contains("/admin/dashboard") || url.contains("/dashboard") || url.contains("/account"), "Expected to be on admin dashboard but was on: " + url);
    }

    @Then("I should see a login error and remain on the login page")
    public void validateLoginError() {
        String url = page.url();
        // Expect to remain on /login or not be navigated to dashboard
        assertTrue(url.contains("/login") || !url.contains("/admin/dashboard"), "Expected to remain on login page but was on: " + url);

        // Try to detect common error messages or alert elements
        Locator alert = page.locator(".error, .alert, [role=alert], text=Invalid, text=invalid, text=Incorrect, text=incorrect, text=wrong, text=Wrong").first();
        boolean found = false;
        try {
            found = alert.isVisible();
        } catch (PlaywrightException ignored) {
        }
        assertTrue(found || url.contains("/login"), "Expected to see a login error message or stay on the login page");
    }

    @Then("I should see a dashboard link {string}")
    public void validateDashboardLink(String linkText) {
            String selector = "a:has-text(\"" + linkText + "\")";
        boolean visible = false;
        try {
                // wait up to 5s for the link to appear/be visible on the page
                page.waitForSelector(selector, new Page.WaitForSelectorOptions().setTimeout(5000));
                visible = page.locator(selector).first().isVisible();
            } catch (PlaywrightException ignored) {
            }
            assertTrue(visible, "Expected to see link '" + linkText + "' on the dashboard");
        }

    @When("I logout")
    public void logout() {
        Locator logout = page.locator("button:has-text(\"Logout\"), a:has-text(\"Logout\"), button:has-text(\"Sign out\"), a:has-text(\"Sign out\"), button[aria-label=\"logout\"], [data-test=logout]").first();
        try {
            if (logout != null) {
                logout.click();
                // wait briefly for navigation to take effect
                try { page.waitForTimeout(2000); } catch (PlaywrightException ignored) {}
            }
        } catch (PlaywrightException e) {
            // swallow for the test to validate the logout outcome below
        }
    }

    @Then("I should be logged out and back on the login page")
    public void validateLoggedOut() {
        String url = page.url();
        boolean onLogin = url.contains("/login") || url.contains("/signin") || url.contains("/logout");
        if (!onLogin) {
            try {
                boolean loginForm = page.locator("input[name=\"email\"], input[type=\"email\"], input[placeholder=\"Email\"]").first().isVisible();
                onLogin = loginForm;
            } catch (PlaywrightException ignored) {
            }
        }
        assertTrue(onLogin, "Expected to be logged out and on login page but was on: " + url);
    }
}
