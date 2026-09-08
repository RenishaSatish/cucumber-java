<#
Runs the Gradle test pipeline then generates a Masterthought (net.masterthought) HTML report.

Usage examples:
  # Use existing env vars
  .\run-tests-and-generate-report.ps1

  # Provide credentials and run headful (show browser) then open report
  .\run-tests-and-generate-report.ps1 -Email 'me@example.com' -Password 's3cret' -Headful -OpenReport

Notes:
- The script sets PIPCALL_EMAIL, PIPCALL_PASSWORD and PLAYWRIGHT_HEADLESS for the duration of the run.
- It stops Gradle daemons, runs clean, installs Playwright browsers, runs the cucumber4 task (JUnit4 runner), then always runs generateCucumberMasterthoughtReport.
- Even if tests fail, the report generation task will still be invoked to publish available results.
#>

param(
    [string]$Email = $env:PIPCALL_EMAIL,
    [string]$Password = $env:PIPCALL_PASSWORD,
    [switch]$Headful,
    [switch]$OpenReport
)

function FailAndExit($msg, $code=1) {
    Write-Host $msg -ForegroundColor Red
    exit $code
}

# Ensure we run from the script's directory (project root)
Set-Location -Path (Split-Path -Parent $PSCommandPath)

Write-Host "Running test pipeline from: $(Get-Location)"

if (-not $Email -or -not $Password) {
    Write-Host "WARNING: PIPCALL_EMAIL or PIPCALL_PASSWORD not provided. Positive scenario may fail." -ForegroundColor Yellow
}

# Export environment variables for the Gradle processes
if ($Email) { $env:PIPCALL_EMAIL = $Email }
if ($Password) { $env:PIPCALL_PASSWORD = $Password }

if ($Headful) { $env:PLAYWRIGHT_HEADLESS = 'false' } else { $env:PLAYWRIGHT_HEADLESS = 'true' }

# Helper to run a Gradle task and return exit code
function Run-GradleTask {
    param(
        [string]$Task
    )
    Write-Host "\n--- Running Gradle task: $Task ---"
    & .\gradlew.bat $Task --no-daemon
    $rc = $LASTEXITCODE
    if ($rc -eq 0) { Write-Host "Task '$Task' finished successfully." -ForegroundColor Green }
    else { Write-Host "Task '$Task' failed with exit code $rc." -ForegroundColor Red }
    return $rc
}

# Stop any running Gradle daemons to avoid locked files
Write-Host "Stopping Gradle daemons..."
& .\gradlew.bat --stop

# 1) Clean (best-effort)
$rcClean = Run-GradleTask -Task 'clean'
if ($rcClean -ne 0) { Write-Host "Continuing despite clean failure..." -ForegroundColor Yellow }

# 2) Ensure Playwright browsers are installed (this can be skipped if already present)
$rcInstall = Run-GradleTask -Task 'installPlaywrightBrowsers'
if ($rcInstall -ne 0) { Write-Host "installPlaywrightBrowsers failed — continuing (tests may fail if browsers missing)." -ForegroundColor Yellow }

# 3) Run tests via the JUnit4 Cucumber runner (cucumber4 task)
$rcCucumber = Run-GradleTask -Task 'cucumber4'
if ($rcCucumber -ne 0) { Write-Host "Cucumber tests reported failures. The report generation will still run to capture results." -ForegroundColor Yellow }

# 4) Always run the Masterthought report generator task (do not skip even if tests failed)
$rcReport = Run-GradleTask -Task 'generateCucumberMasterthoughtReport'
if ($rcReport -ne 0) {
    Write-Host "Report generation task failed. Check Gradle output above for details." -ForegroundColor Red
} else {
    $reportIndex = Join-Path -Path (Join-Path -Path (Get-Location) -ChildPath 'build\cucumber-report\masterthought') -ChildPath 'index.html'
    if (Test-Path $reportIndex) {
        Write-Host "Masterthought report generated: $reportIndex" -ForegroundColor Green
        if ($OpenReport) {
            Write-Host "Opening report in default browser..."
            Start-Process $reportIndex
        }
    } else {
        Write-Host "Report task completed but index.html not found at expected path: $reportIndex" -ForegroundColor Yellow
    }
}

# Exit with non-zero code if tests failed, otherwise 0
$finalCode = 0
if ($rcCucumber -ne 0) { $finalCode = $rcCucumber }
elseif ($rcReport -ne 0) { $finalCode = $rcReport }

Write-Host "\nPipeline finished. Exit code: $finalCode"
exit $finalCode
