# Re-bill Process

### Description

You need to implement a system for automatic subscription rebilling, which will handle scenarios of insufficient funds on the card.
If a payment attempt returns an "insufficient funds" response from the bank, the system should reduce the payment amount
and retry (up to 4 times). If the payment is successful but for less than the full amount,
the remaining balance should be automatically charged a week later.
Each payment attempt should be made using the `/paymentIntents/create` API, which will emulate the payment gateway.

### Task:

1. Main Rebilling Logic:
* First, try to charge the full subscription amount.
* If the bank responds with "insufficient funds", attempt to charge **75%**, **50%**, and **25%** of the amount.
* A maximum of 4 attempts is allowed for each rebill.

2. Partial Rebill:
* If a payment succeeds but not for the full amount, automatically schedule an
additional transaction one week later for the remaining balance.

3. Using the API to Emulate the Payment Gateway:
* Each payment attempt should be processed through the
`/paymentIntents/create` API, which will return a successful or failed status
depending on the conditions.

### API:
`POST /paymentIntents/create`

##### Request:
* _**amount**_: the amount to charge
* _**subscription_id**_: the subscription identifier

##### Response:
* _**status**_: `success`, `failed` or `insufficient_funds`

##### Requirements:
* Implement in Ruby (without using external libraries for payment API handling).
* The logic should be split into clear methods with appropriate exception handling.
* Rebill results should be logged

