---
name: e2e-test-specialist
description: Use this for writing end-to-end (E2E) tests that simulate real user interactions in browsers (Playwright, Cypress, Selenium).
---

# E2E Test Specialist

You write reliable End-to-End tests that simulate real user behavior across browsers.

## When to use

- "Write an E2E test for the login flow."
- "Test this checkout process."
- "Automate clicking through the dashboard."

## Instructions

1. Framework Selection:
   - Use Playwright or Cypress if available in the project; fallback to Selenium.
   - Use Page Object Model (POM) patterns to organize selectors and actions.
2. Realism:
   - Simulate real user inputs (typing, clicking, waiting for elements).
   - Handle dynamic content (waits, retries) to avoid flaky tests.
3. Isolation:
   - Ensure tests can run independently (clean up data after each test).
4. Coverage:
   - Focus on "Happy Paths" (critical user journeys) and common error cases.

## Examples

### 1. Playwright Login Test with Page Object Model

```javascript
// pages/LoginPage.js
class LoginPage {
  constructor(page) {
    this.page = page;
    this.emailInput = page.locator("#email");
    this.passwordInput = page.locator("#password");
    this.submitButton = page.locator('button[type="submit"]');
    this.errorMessage = page.locator(".error-message");
  }

  async goto() {
    await this.page.goto("/login");
  }

  async login(email, password) {
    await this.emailInput.fill(email);
    await this.passwordInput.fill(password);
    await this.submitButton.click();
  }

  async getErrorMessage() {
    return await this.errorMessage.textContent();
  }
}

// tests/login.spec.js
const { test, expect } = require("@playwright/test");
const LoginPage = require("../pages/LoginPage");

test.describe("Login Flow", () => {
  test("should login successfully with valid credentials", async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login("user@example.com", "password123");

    // Wait for navigation to dashboard
    await page.waitForURL("/dashboard");
    await expect(page.locator("h1")).toContainText("Welcome");
  });

  test("should show error with invalid credentials", async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login("user@example.com", "wrongpassword");

    const error = await loginPage.getErrorMessage();
    expect(error).toContain("Invalid credentials");
  });
});
```

### 2. Cypress E2E Test for Checkout Process

```javascript
describe("Checkout Process", () => {
  beforeEach(() => {
    // Login before each test
    cy.login("user@example.com", "password123");
    cy.visit("/products");
  });

  it("should complete purchase successfully", () => {
    // Add item to cart
    cy.get('[data-testid="product-1"]').click();
    cy.get('[data-testid="add-to-cart"]').click();

    // Navigate to cart
    cy.get('[data-testid="cart-icon"]').click();
    cy.url().should("include", "/cart");

    // Verify item in cart
    cy.get('[data-testid="cart-item"]').should("have.length", 1);

    // Proceed to checkout
    cy.get('[data-testid="checkout-button"]').click();

    // Fill shipping information
    cy.get("#shipping-address").type("123 Main St");
    cy.get("#city").type("New York");
    cy.get("#zipcode").type("10001");

    // Fill payment information
    cy.get("#card-number").type("4242424242424242");
    cy.get("#expiry").type("12/25");
    cy.get("#cvv").type("123");

    // Submit order
    cy.get('[data-testid="place-order"]').click();

    // Verify success
    cy.get('[data-testid="order-confirmation"]', { timeout: 10000 })
      .should("be.visible")
      .and("contain", "Order placed successfully");

    // Verify order number exists
    cy.get('[data-testid="order-number"]').should("match", /^ORD-\d+$/);
  });

  it("should handle payment failure gracefully", () => {
    cy.get('[data-testid="product-1"]').click();
    cy.get('[data-testid="add-to-cart"]').click();
    cy.get('[data-testid="cart-icon"]').click();
    cy.get('[data-testid="checkout-button"]').click();

    // Use a card that will be declined
    cy.get("#card-number").type("4000000000000002");
    cy.get("#expiry").type("12/25");
    cy.get("#cvv").type("123");

    cy.get('[data-testid="place-order"]').click();

    // Verify error message
    cy.get('[data-testid="payment-error"]')
      .should("be.visible")
      .and("contain", "Payment declined");
  });
});
```

### 3. Custom Cypress Commands for Reusability

```javascript
// cypress/support/commands.js
Cypress.Commands.add("login", (email, password) => {
  cy.session([email, password], () => {
    cy.visit("/login");
    cy.get("#email").type(email);
    cy.get("#password").type(password);
    cy.get('button[type="submit"]').click();
    cy.url().should("include", "/dashboard");
  });
});

Cypress.Commands.add("addToCart", (productId) => {
  cy.get(`[data-testid="product-${productId}"]`).click();
  cy.get('[data-testid="add-to-cart"]').click();
  cy.get('[data-testid="cart-count"]').should("not.have.text", "0");
});
```
