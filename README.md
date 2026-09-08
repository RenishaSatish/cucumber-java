Cucumber + Playwright (Java) sample

This small project shows how to run a Cucumber feature that uses Playwright for Java.

Requirements
- Gradle (or use your system Gradle)
- Java 11+
- Network access to download dependencies

Quick run
1. Set environment variables (Git Bash):
   export PIPCALL_EMAIL="you@example.com"
   export PIPCALL_PASSWORD='your_password'

2. Change directory:
   cd playwright-test-repo/cucumber-java

3. Run using the Gradle wrapper (added in this repo):
   On Git Bash / macOS / Linux: ./gradlew cucumber
   On Windows (PowerShell / CMD): .\gradlew.bat cucumber

Reports
- Cucumber will emit JSON and HTML into build/cucumber-report/ by the plugin configured in the runner.
- After the run you should see build/cucumber-report/cucumber-html-report.html

Notes
- Playwright for Java will download browser binaries the first time an instance is launched. The project provides a Gradle task `installPlaywrightBrowsers` to pre-download browsers before running tests.
- This setup uses JUnit 5 + cucumber-junit-platform-engine. The `cucumber` Gradle task depends on the browser install task and uses the JUnit Platform to run Cucumber features.
- Step definitions save screenshots to `build/cucumber-report/screenshots/` and attach them to the Cucumber report when supported.
- This is a minimal example: expand features and step definitions as needed.
