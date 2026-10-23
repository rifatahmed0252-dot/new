# Thai Glass Inventory V5

Mobile-friendly, local-first inventory/accounting prototype for a Thai Glass shop.

## Included and tested in this package
- Product list and stock quantity, category, unit and length fields.
- Per-product pricing mode: fixed prices or chart/base price × buy % / sell %.
- Stock-in/out movements and sales invoices.
- Daily account entries for purchase, sale, expense, receivable, payable, salary, owner deposit/withdrawal, cash in/out and other entries.
- Monthly summary based on Daily Accounts entries (not a double-entry accounting ledger).
- JSON backup export/import.
- Supabase email/password login, workspace creation, add-existing-account membership and shared JSON-state sync code.
- Service worker cache scoped to same-origin app assets; it does not intercept third-party scripts or API requests.

## Required one-time external setup (cannot be completed from this ZIP alone)
1. Create a Supabase project under your own account.
2. In Supabase SQL Editor, run the complete `supabase_schema.sql` file.
3. Enable email/password authentication. Decide whether email confirmation is required.
4. Deploy the contents of this folder to your GitHub Pages repository.
5. In the app Settings, enter the Supabase Project URL and the public anon/publishable key. Never use a `service_role` key in the browser.
6. Create/sign in to the owner account and create a workspace. Each staff member must first create an account in the same Supabase project; then the owner can add their email.
7. Test with sample data on two devices before entering real business records.

## Important limitations (do not treat as fully production-ready accounting yet)
- External Supabase project creation, credentials, and GitHub deployment are not included; these require access to your accounts.
- Workspace membership exists, but robust server-enforced employee/manager action permissions are not implemented. Do not assume employee accounts are restricted from editing shared records.
- Cloud sync stores one JSON document per shop. Simultaneous edits to the same record can conflict; it is not transaction-safe for critical accounting.
- The separate supplier purchase-invoice workflow, payment settlement/receivable aging, employee payroll records, full profit calculation with stock cost, and a true double-entry ledger are not implemented as complete workflows. Daily Accounts entries are a summary notebook.
- Offline edits are stored locally and attempt to sync when online. Always export backups and validate sync behavior before relying on it.

## Deploy
Back up the current GitHub Pages files first. Upload the contents of this folder (not the outer ZIP folder) to the repository root. Wait for Pages to build, then refresh the site. If an old version remains on iPhone, close and reopen the page after the service-worker update.


## Updated in this ZIP
- Removed owner personal deposit/withdrawal entries from Daily Accounts.
- Kept product-level Fixed Price and Percentage pricing (base price + separate buy/sell percentages). Example: base 1,000; buy 80% = 800; sell 90% = 900.
- Simplified Settings for this offline/local version; JSON export/import backup remains available.
- Supabase/cloud sync is intentionally not enabled. Data stays in the current browser on this device; it will not automatically sync to another phone or computer.
- Daily accounts include purchases, sales, expenses, salaries, receivables/payables, and other cash in/out.
