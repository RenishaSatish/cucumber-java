Feature: PiPcall login and dashboard
  As a test automation
  I want to login and verify the admin dashboard

  Scenario: Positive flow - Login, validate admin dashboard and logout
    Given I open the login page
    When I login with valid credentials
    Then I should land on the admin dashboard
    Then I should see a dashboard link "Dashboard"
    When I logout
    Then I should be logged out and back on the login page

  Scenario: Negative flow - Invalid login shows error
    Given I open the login page
    When I login with invalid credentials
    Then I should see a login error and remain on the login page
