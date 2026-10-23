# Manual acceptance checklist

Use sample data only.

- [ ] Add a fixed-price product and verify purchase/selling prices remain the entered values.
- [ ] Add a percentage-price product with base price 1000, buy 80%, sell 90%; verify buy 800 and sell 900.
- [ ] Stock in 10 units; verify stock becomes 10 and movement appears.
- [ ] Sell 2 units; verify stock becomes 8, invoice total is correct, and insufficient stock is rejected.
- [ ] Add Daily Accounts purchase/sale entries; verify stock effect occurs once and the warning is followed.
- [ ] Add expense, salary, receivable, payable, owner in/out; verify entries appear for selected date.
- [ ] Export JSON, clear only test data, import JSON and confirm products/movements/sales/daily entries return.
- [ ] Set up Supabase on two test devices; sign in and sync, then test offline entry and reconnect.
- [ ] Test two devices editing the same record; if data conflicts, do not use for live accounts yet.
- [ ] Do not create employee accounts until role permissions are server-enforced.
