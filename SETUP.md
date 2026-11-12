# CashFlow – Setup Guide

Google Sheets is the **only** financial database. The Flutter app talks to a Google Apps Script web app (REST API) that reads/writes your sheet.

---

## 1. Google Sheet + Apps Script backend

1. Go to https://sheets.google.com → **Blank spreadsheet** → name it `CashFlow`.
2. Menu **Extensions → Apps Script**.
3. Delete the default code, paste the **entire** contents of `Code.gs`, click **Save**.
4. (Recommended) Add an API key: ⚙ **Project Settings → Script Properties → Add script property**
   - Property: `API_KEY`  Value: a long random string (e.g. 32+ characters).
5. In the editor pick function **`setup`** in the toolbar dropdown → **Run**. Approve the permissions
   (Advanced → Go to project (unsafe) → Allow). This creates the sheets
   `Transactions, Loans, LoanRepayments, Categories, Accounts, Settings` and seeds default categories, the accounts *Cash* and *Bank*, and currency `PKR`.
6. **Deploy → New deployment → ⚙ Select type: Web app**
   - Description: `CashFlow API`
   - Execute as: **Me**
   - Who has access: **Anyone**
   - **Deploy**, copy the **Web app URL** (ends with `/exec`).
7. After every later change to `Code.gs`: **Deploy → Manage deployments → ✏ Edit → Version: New version → Deploy** (the URL stays the same).

Quick test in a browser: `YOUR_URL?action=ping&key=YOUR_API_KEY` → `{"ok":true,...}`

---

## 2. Flutter project

```bash
flutter create --project-name cashflow --org com.example cashflow
cd cashflow
flutter pub add get http fl_chart intl shared_preferences
```

Replace the generated `lib/` folder with the provided one and delete the default test:

```bash
rm -rf lib test/widget_test.dart
# copy the provided lib/ folder into this project (cashflow/lib)
flutter pub get
```

(Alternatively replace `pubspec.yaml` with the provided one, then `flutter pub get`.)
All imports inside `lib/` are relative, so the project name does not matter.

**Android release builds** need internet permission. In `android/app/src/main/AndroidManifest.xml`, inside `<manifest>` and above `<application>`, add:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```
(Debug builds already include it.)

---

## 3. Run & connect

```bash
flutter run            # pick your Android/iOS device or emulator
```

On first launch the **Connect Google Sheets** screen appears:
1. Paste the Web App URL (`https://script.google.com/macros/s/.../exec`).
2. Paste the API key (if you set `API_KEY`).
3. Tap **Test & connect**.

The URL and key are stored on the device (SharedPreferences) – nothing is hardcoded. Change them later in **Settings → Google Sheets → Change**.

---

## 4. Financial rules implemented

- Available balance = Opening + Income + Deposits + Loans taken + Repayments received − Expenses − Withdrawals − Loans given − Repayments paid (plus money received/sent and ± adjustments/misc).
- Loans given are assets (receivables), loans taken are liabilities – never income/expense.
- Each repayment reduces the outstanding amount; the loan closes automatically at 0 and re-opens if a repayment is deleted.
- Transfers between accounts are balance-neutral overall and move money between account balances.
- Net financial position = Available balance + Receivables − Liabilities. Monthly savings = Income − Expenses.
- Deleting a loan removes its repayments and linked transactions. Loan-linked transactions can't be edited (delete & re-create).

---

## 5. Security limitations (please read)

- A Web App deployed with **"Anyone"** access is reachable by anyone who knows the URL. The only gate is the optional `API_KEY` shared secret.
- The API key is stored on the phone in plain SharedPreferences and sent over HTTPS with each request (in the URL for reads). Treat it as a password for *this one sheet*; rotate it by changing the Script Property and re-entering it in the app.
- There are no per-user accounts. Anyone with URL + key has full read/write access to your data. Don't share them or commit them to git.
- Apps Script quotas apply (execution time, daily calls) and each call takes ~1–2 s. A script lock serialises writes, and a `requestId` cache prevents duplicate submissions.
- For multi-user or stronger security, put a real auth layer (OAuth / your own backend) in front of the sheet.
- Keep the sheet itself private (don't share it publicly); the script runs as *you*.

## 6. Troubleshooting

| Symptom | Fix |
|---|---|
| "Unexpected response… /exec" | Re-deploy as Web app, access **Anyone**, use the `/exec` URL (not `/dev`). |
| "Unauthorized: invalid API key" | Key in app must equal the `API_KEY` script property. |
| "Missing sheet…" | Run `setup()` once in the editor. |
| Changes in `Code.gs` have no effect | Deploy a **new version** of the existing deployment. |
| Timeout | Apps Script cold start; pull to refresh / retry. |
