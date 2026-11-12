/**
 * CashFlow — Google Apps Script REST API (single file)
 * ---------------------------------------------------------------
 * Bind this script to your Google Sheet (Extensions → Apps Script)
 * and deploy it as a Web App. See SETUP.md.
 *
 * GET  ?action=ping|getAll&key=API_KEY
 * POST {action, key, requestId, payload}  (Content-Type: text/plain)
 *   addTransaction, updateTransaction, deleteTransaction,
 *   deleteLoan, deleteRepayment,
 *   saveCategory, deleteCategory, saveAccount, deleteAccount, saveSettings
 *
 * Every response: {ok:true, data:{...}} or {ok:false, error:"message"}.
 * Every write returns the complete fresh snapshot (same shape as getAll).
 *
 * Secrets: nothing is hardcoded. Optional Script Properties:
 *   API_KEY         shared secret the app must send
 *   SPREADSHEET_ID  only if the script is NOT bound to the spreadsheet
 */

// ───────────────────────── schema ─────────────────────────
var SHEETS = {
  Transactions: ['id', 'date', 'type', 'amount', 'direction', 'accountId', 'toAccountId', 'categoryId', 'category',
                 'title', 'note', 'person', 'loanId', 'repaymentId', 'createdAt', 'updatedAt'],
  Loans: ['id', 'type', 'person', 'amount', 'date', 'dueDate', 'note', 'accountId', 'status', 'transactionId', 'createdAt', 'updatedAt'],
  LoanRepayments: ['id', 'loanId', 'amount', 'date', 'note', 'accountId', 'transactionId', 'createdAt'],
  Categories: ['id', 'name', 'type', 'icon', 'color', 'createdAt'],
  Accounts: ['id', 'name', 'type', 'icon', 'color', 'createdAt'],
  Settings: ['key', 'value']
};

var TYPES = ['income', 'expense', 'deposit', 'withdrawal', 'openingBalance', 'adjustment', 'loanGiven', 'loanTaken',
             'repaymentReceived', 'repaymentPaid', 'moneyReceived', 'moneySent', 'transfer', 'misc'];

// informational direction column (adjustment/misc take it from the user)
var DIRECTION = {
  income: 'in', expense: 'out', deposit: 'in', withdrawal: 'out', openingBalance: 'in', loanGiven: 'out', loanTaken: 'in',
  repaymentReceived: 'in', repaymentPaid: 'out', moneyReceived: 'in', moneySent: 'out', transfer: ''
};

var DATE_COLS = ['date', 'dueDate'];
var NUMBER_COLS = ['amount'];
var ACCOUNT_TYPES = ['cash', 'bank', 'wallet', 'card', 'savings'];
var SETTING_KEYS = ['currency', 'defaultAccountId'];

var DEFAULT_CATEGORIES = [
  ['Salary', 'income', 'work', '#10B981'], ['Business', 'income', 'storefront', '#0EA5E9'],
  ['Freelancing', 'income', 'laptop', '#8B5CF6'], ['Gifts', 'income', 'card_giftcard', '#EC4899'],
  ['Refunds', 'income', 'replay', '#F59E0B'], ['Investments', 'income', 'trending_up', '#14B8A6'],
  ['Rental Income', 'income', 'home_work', '#6366F1'], ['Other Income', 'income', 'payments', '#64748B'],
  ['Food', 'expense', 'restaurant', '#F97316'], ['Groceries', 'expense', 'shopping_cart', '#84CC16'],
  ['Shopping', 'expense', 'shopping_bag', '#EC4899'], ['Rent', 'expense', 'house', '#6366F1'],
  ['Bills', 'expense', 'receipt_long', '#EAB308'], ['Fuel', 'expense', 'local_gas_station', '#EF4444'],
  ['Transport', 'expense', 'directions_car', '#0EA5E9'], ['Healthcare', 'expense', 'local_hospital', '#F43F5E'],
  ['Education', 'expense', 'school', '#8B5CF6'], ['Entertainment', 'expense', 'movie', '#D946EF'],
  ['Subscriptions', 'expense', 'subscriptions', '#06B6D4'], ['Travel', 'expense', 'flight', '#14B8A6'],
  ['Family', 'expense', 'family_restroom', '#F59E0B'], ['Other Expenses', 'expense', 'category', '#64748B']
];

var DEFAULT_ACCOUNTS = [
  ['Cash', 'cash', 'payments', '#10B981'],
  ['Bank', 'bank', 'account_balance', '#0EA5E9']
];

var WRITE_ACTIONS = ['addTransaction', 'updateTransaction', 'deleteTransaction', 'deleteLoan', 'deleteRepayment',
                     'saveCategory', 'deleteCategory', 'saveAccount', 'deleteAccount', 'saveSettings'];
var READ_ACTIONS = ['ping', 'getAll'];

// ───────────────────────── entry points ─────────────────────────
/** Run once from the editor to authorize the script and create all sheets. */
function setup() {
  ensureSetup_();
  return 'CashFlow sheets are ready.';
}

function doGet(e) {
  return handle_('GET', (e && e.parameter) || {});
}

function doPost(e) {
  var req;
  try {
    req = JSON.parse((e && e.postData && e.postData.contents) || '{}');
  } catch (err) {
    return out_({ ok: false, error: 'Invalid JSON body.' });
  }
  return handle_('POST', req || {});
}

function handle_(method, req) {
  var lock = LockService.getScriptLock();
  var locked = false;
  try {
    authorize_(req.key);
    var action = String(req.action || '');
    var isWrite = WRITE_ACTIONS.indexOf(action) >= 0;
    var isRead = READ_ACTIONS.indexOf(action) >= 0;
    if (!isWrite && !isRead) throw new ApiError_('Unknown action: ' + action);
    if (isWrite && method !== 'POST') throw new ApiError_('Write actions must use POST.');

    lock.waitLock(25000); // serialises writes → no race conditions / double rows
    locked = true;
    ensureSetup_();

    // duplicate-submission protection
    var cache = CacheService.getScriptCache();
    var rid = isWrite && req.requestId ? 'req_' + String(req.requestId).substring(0, 80) : null;
    if (rid && cache.get(rid)) {
      return out_({ ok: true, data: getAll_(), duplicate: true });
    }

    var data;
    if (action === 'ping') {
      data = { pong: true, time: new Date().toISOString() };
    } else if (action === 'getAll') {
      data = getAll_();
    } else {
      HANDLERS[action](req.payload || {});
      data = getAll_();
      if (rid) cache.put(rid, '1', 21600); // remember for 6 hours
    }
    return out_({ ok: true, data: data });
  } catch (err) {
    if (err instanceof ApiError_) return out_({ ok: false, error: err.message });
    console.error(err);
    return out_({ ok: false, error: 'Server error: ' + (err && err.message ? err.message : err) });
  } finally {
    if (locked) lock.releaseLock();
  }
}

var HANDLERS = {
  addTransaction: addTransaction_,
  updateTransaction: updateTransaction_,
  deleteTransaction: deleteTransaction_,
  deleteLoan: deleteLoan_,
  deleteRepayment: deleteRepayment_,
  saveCategory: saveCategory_,
  deleteCategory: deleteCategory_,
  saveAccount: saveAccount_,
  deleteAccount: deleteAccount_,
  saveSettings: saveSettings_
};

// ───────────────────────── infrastructure ─────────────────────────
function ApiError_(message) {
  this.message = message;
  this.name = 'ApiError';
}
ApiError_.prototype = Object.create(Error.prototype);

function out_(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}

function authorize_(key) {
  var expected = PropertiesService.getScriptProperties().getProperty('API_KEY');
  if (expected && String(key || '') !== expected) throw new ApiError_('Unauthorized: invalid API key.');
}

function ss_() {
  var id = PropertiesService.getScriptProperties().getProperty('SPREADSHEET_ID');
  return id ? SpreadsheetApp.openById(id) : SpreadsheetApp.getActiveSpreadsheet();
}

function sheet_(name) {
  var sh = ss_().getSheetByName(name);
  if (!sh) throw new ApiError_('Missing sheet: ' + name + '. Run setup() once.');
  return sh;
}

function ensureSetup_() {
  var ss = ss_();
  Object.keys(SHEETS).forEach(function (name) {
    var cols = SHEETS[name];
    var sh = ss.getSheetByName(name);
    var fresh = false;
    if (!sh) { sh = ss.insertSheet(name); fresh = true; }
    else if (sh.getLastRow() === 0) { fresh = true; }
    if (fresh) {
      sh.getRange(1, 1, 1, cols.length).setValues([cols])
        .setFontWeight('bold').setBackground('#047857').setFontColor('#ffffff');
      sh.setFrozenRows(1);
      cols.forEach(function (c, i) {
        // plain-text format stops Sheets from turning dates/ids into other types
        if (NUMBER_COLS.indexOf(c) < 0) {
          sh.getRange(2, i + 1, Math.max(sh.getMaxRows() - 1, 1), 1).setNumberFormat('@');
        }
      });
      seed_(name);
    }
  });
  var def = ss.getSheetByName('Sheet1');
  if (def && def.getLastRow() === 0 && ss.getSheets().length > 1) ss.deleteSheet(def);
}

function seed_(name) {
  var now = now_();
  if (name === 'Categories') {
    appendMany_('Categories', DEFAULT_CATEGORIES.map(function (c) {
      return { id: uid_('cat'), name: c[0], type: c[1], icon: c[2], color: c[3], createdAt: now };
    }));
  } else if (name === 'Accounts') {
    appendMany_('Accounts', DEFAULT_ACCOUNTS.map(function (a) {
      return { id: uid_('acc'), name: a[0], type: a[1], icon: a[2], color: a[3], createdAt: now };
    }));
  } else if (name === 'Settings') {
    var accs = readAll_('Accounts');
    appendMany_('Settings', [
      { key: 'currency', value: 'PKR' },
      { key: 'defaultAccountId', value: accs.length ? accs[0].id : '' }
    ]);
  }
}

// ───────────────────────── generic sheet helpers ─────────────────────────
function now_() { return new Date().toISOString(); }

function uid_(prefix) { return prefix + '_' + Utilities.getUuid().replace(/-/g, '').substring(0, 12); }

function isDate_(v) { return Object.prototype.toString.call(v) === '[object Date]'; }

function readAll_(name) {
  var cols = SHEETS[name];
  var sh = sheet_(name);
  var last = sh.getLastRow();
  if (last < 2) return [];
  var tz = Session.getScriptTimeZone();
  var values = sh.getRange(2, 1, last - 1, cols.length).getValues();
  var rows = [];
  values.forEach(function (r) {
    if (r[0] === '' || r[0] === null) return;
    var o = {};
    cols.forEach(function (c, i) {
      var v = r[i];
      if (isDate_(v)) {
        v = Utilities.formatDate(v, tz, DATE_COLS.indexOf(c) >= 0 ? 'yyyy-MM-dd' : "yyyy-MM-dd'T'HH:mm:ss");
      }
      o[c] = v;
    });
    rows.push(o);
  });
  return rows;
}

function rowFromObj_(name, obj) {
  return SHEETS[name].map(function (c) {
    var v = obj[c];
    return v === undefined || v === null ? '' : v;
  });
}

function append_(name, obj) {
  sheet_(name).appendRow(rowFromObj_(name, obj));
}

function appendMany_(name, objs) {
  if (!objs.length) return;
  var sh = sheet_(name);
  var rows = objs.map(function (o) { return rowFromObj_(name, o); });
  sh.getRange(sh.getLastRow() + 1, 1, rows.length, SHEETS[name].length).setValues(rows);
}

function findById_(name, id) {
  var rows = readAll_(name);
  for (var i = 0; i < rows.length; i++) if (String(rows[i].id) === String(id)) return rows[i];
  return null;
}

function findRow_(name, id) {
  var sh = sheet_(name);
  var last = sh.getLastRow();
  if (last < 2) return -1;
  var ids = sh.getRange(2, 1, last - 1, 1).getValues();
  for (var i = 0; i < ids.length; i++) if (String(ids[i][0]) === String(id)) return i + 2;
  return -1;
}

function replaceRow_(name, id, obj) {
  var row = findRow_(name, id);
  if (row < 0) throw new ApiError_('Record not found.');
  sheet_(name).getRange(row, 1, 1, SHEETS[name].length).setValues([rowFromObj_(name, obj)]);
}

function deleteRow_(name, id) {
  var row = findRow_(name, id);
  if (row > 0) sheet_(name).deleteRow(row);
}

/** Delete every row whose column `col` equals `value` (bottom-up so indexes stay valid). */
function deleteWhere_(name, col, value) {
  var idx = SHEETS[name].indexOf(col);
  var sh = sheet_(name);
  var last = sh.getLastRow();
  if (last < 2) return;
  var vals = sh.getRange(2, idx + 1, last - 1, 1).getValues();
  for (var i = vals.length - 1; i >= 0; i--) {
    if (String(vals[i][0]) === String(value)) sh.deleteRow(i + 2);
  }
}

function extend_(a, b) {
  var o = {};
  Object.keys(a).forEach(function (k) { o[k] = a[k]; });
  Object.keys(b).forEach(function (k) { o[k] = b[k]; });
  return o;
}

// ───────────────────────── validation ─────────────────────────
function text_(v, max) {
  return String(v === undefined || v === null ? '' : v).replace(/[\u0000-\u001f]/g, ' ').trim().substring(0, max);
}

function amount_(v) {
  var n = Number(v);
  if (!isFinite(n) || n <= 0) throw new ApiError_('Amount must be greater than zero.');
  if (n > 1e12) throw new ApiError_('Amount is too large.');
  return Math.round(n * 100) / 100;
}

function date_(v, label) {
  var s = String(v || '');
  if (!/^\d{4}-\d{2}-\d{2}$/.test(s)) throw new ApiError_('Invalid ' + label + '. Use yyyy-MM-dd.');
  var d = new Date(s + 'T00:00:00Z');
  if (isNaN(d.getTime()) || d.toISOString().substring(0, 10) !== s) throw new ApiError_('Invalid ' + label + '.');
  return s;
}

function color_(v, fallback) {
  return /^#[0-9A-Fa-f]{6}$/.test(String(v || '')) ? String(v).toUpperCase() : fallback;
}

function requireAccount_(id) {
  var acc = findById_('Accounts', id);
  if (!acc) throw new ApiError_('Account not found.');
  return acc;
}

function validateBase_(p) {
  var type = String(p.type || '');
  if (TYPES.indexOf(type) < 0) throw new ApiError_('Unknown transaction type.');
  var t = {
    type: type,
    amount: amount_(p.amount),
    date: date_(p.date, 'date'),
    direction: DIRECTION[type] || '',
    accountId: requireAccount_(p.accountId).id,
    toAccountId: '', categoryId: '', category: '',
    title: text_(p.title, 120), note: text_(p.note, 500), person: text_(p.person, 80)
  };
  if (type === 'transfer') {
    var to = requireAccount_(p.toAccountId);
    if (to.id === t.accountId) throw new ApiError_('Transfer accounts must be different.');
    t.toAccountId = to.id;
  }
  if (type === 'adjustment' || type === 'misc') {
    var d = String(p.direction || '');
    if (d !== 'in' && d !== 'out') throw new ApiError_('Direction must be "in" or "out".');
    t.direction = d;
  }
  if (type === 'income' || type === 'expense') {
    var cat = findById_('Categories', p.categoryId);
    if (!cat) throw new ApiError_('Category not found.');
    if (cat.type !== type) throw new ApiError_('Category type does not match the transaction type.');
    t.categoryId = cat.id;
    t.category = cat.name;
  }
  return t;
}

function newTx_(fields) {
  return extend_({
    id: uid_('tx'), date: '', type: '', amount: 0, direction: '', accountId: '', toAccountId: '', categoryId: '',
    category: '', title: '', note: '', person: '', loanId: '', repaymentId: '', createdAt: now_(), updatedAt: now_()
  }, fields);
}

// ───────────────────────── loans ─────────────────────────
function repaidAmount_(loanId) {
  return readAll_('LoanRepayments').reduce(function (s, r) {
    return String(r.loanId) === String(loanId) ? s + Number(r.amount) : s;
  }, 0);
}

function loanOutstanding_(loan) {
  return Math.round((Number(loan.amount) - repaidAmount_(loan.id)) * 100) / 100;
}

function refreshLoanStatus_(loanId) {
  var loan = findById_('Loans', loanId);
  if (!loan) return;
  loan.status = loanOutstanding_(loan) <= 0.005 ? 'closed' : 'open';
  loan.updatedAt = now_();
  replaceRow_('Loans', loan.id, loan);
}

// ───────────────────────── transactions ─────────────────────────
function addTransaction_(p) {
  var t = validateBase_(p);
  var tx = newTx_(t);
  var type = t.type;

  if (type === 'loanGiven' || type === 'loanTaken') {
    if (!t.person) throw new ApiError_('Person name is required for loans.');
    var due = p.dueDate ? date_(p.dueDate, 'due date') : '';
    if (due && due < t.date) throw new ApiError_('Due date cannot be before the loan date.');
    var given = type === 'loanGiven';
    var loan = {
      id: uid_('loan'), type: given ? 'given' : 'taken', person: t.person, amount: t.amount, date: t.date,
      dueDate: due, note: t.note, accountId: t.accountId, status: 'open', transactionId: tx.id,
      createdAt: now_(), updatedAt: now_()
    };
    tx.loanId = loan.id;
    tx.title = tx.title || ((given ? 'Loan to ' : 'Loan from ') + t.person);
    append_('Loans', loan);
  }

  if (type === 'repaymentReceived' || type === 'repaymentPaid') {
    var target = findById_('Loans', p.loanId);
    if (!target) throw new ApiError_('Loan not found.');
    var wantGiven = type === 'repaymentReceived';
    if ((target.type === 'given') !== wantGiven) {
      throw new ApiError_(wantGiven ? 'Repayments received apply to loans you gave.' : 'Repayments paid apply to loans you took.');
    }
    var outstanding = loanOutstanding_(target);
    if (t.amount > outstanding + 0.005) throw new ApiError_('Repayment exceeds the outstanding balance (' + outstanding + ').');
    var rep = {
      id: uid_('rep'), loanId: target.id, amount: t.amount, date: t.date, note: t.note,
      accountId: t.accountId, transactionId: tx.id, createdAt: now_()
    };
    tx.loanId = target.id;
    tx.repaymentId = rep.id;
    tx.person = target.person;
    tx.title = tx.title || ('Repayment ' + (wantGiven ? 'from ' : 'to ') + target.person);
    append_('LoanRepayments', rep);
    append_('Transactions', tx);
    refreshLoanStatus_(target.id);
    return;
  }
  append_('Transactions', tx);
}

function updateTransaction_(p) {
  var existing = findById_('Transactions', p.id);
  if (!existing) throw new ApiError_('Transaction not found.');
  if (existing.loanId) throw new ApiError_('Loan transactions cannot be edited. Delete and re-create them instead.');
  var wanted = String(p.type || '');
  if (wanted === 'loanGiven' || wanted === 'loanTaken' || wanted === 'repaymentReceived' || wanted === 'repaymentPaid') {
    throw new ApiError_('A transaction cannot be converted into a loan transaction.');
  }
  var t = validateBase_(p);
  t.updatedAt = now_();
  replaceRow_('Transactions', existing.id, extend_(existing, t));
}

function deleteTransaction_(p) {
  var tx = findById_('Transactions', p.id);
  if (!tx) throw new ApiError_('Transaction not found.');
  if (tx.type === 'loanGiven' || tx.type === 'loanTaken') return deleteLoan_({ id: tx.loanId });
  if (tx.type === 'repaymentReceived' || tx.type === 'repaymentPaid') return deleteRepayment_({ id: tx.repaymentId });
  deleteRow_('Transactions', tx.id);
}

function deleteLoan_(p) {
  var loan = findById_('Loans', p.id);
  if (!loan) throw new ApiError_('Loan not found.');
  deleteWhere_('Transactions', 'loanId', loan.id); // loan + repayment transactions
  deleteWhere_('LoanRepayments', 'loanId', loan.id);
  deleteRow_('Loans', loan.id);
}

function deleteRepayment_(p) {
  var rep = findById_('LoanRepayments', p.id);
  if (!rep) throw new ApiError_('Repayment not found.');
  deleteWhere_('Transactions', 'repaymentId', rep.id);
  deleteRow_('LoanRepayments', rep.id);
  refreshLoanStatus_(rep.loanId);
}

// ───────────────────────── categories ─────────────────────────
function saveCategory_(p) {
  var name = text_(p.name, 60);
  if (!name) throw new ApiError_('Category name is required.');
  var icon = text_(p.icon, 40) || 'category';
  var color = color_(p.color, '#64748B');
  var all = readAll_('Categories');

  if (p.id) {
    var existing = findById_('Categories', p.id);
    if (!existing) throw new ApiError_('Category not found.');
    var clash = all.some(function (c) { return c.id !== existing.id && c.type === existing.type && c.name.toLowerCase() === name.toLowerCase(); });
    if (clash) throw new ApiError_('A category with this name already exists.');
    replaceRow_('Categories', existing.id, extend_(existing, { name: name, icon: icon, color: color }));
    if (existing.name !== name) relabelTransactions_(existing.id, name);
    return;
  }
  var type = String(p.type || '');
  if (type !== 'income' && type !== 'expense') throw new ApiError_('Category type must be income or expense.');
  var dup = all.some(function (c) { return c.type === type && c.name.toLowerCase() === name.toLowerCase(); });
  if (dup) throw new ApiError_('A category with this name already exists.');
  append_('Categories', { id: uid_('cat'), name: name, type: type, icon: icon, color: color, createdAt: now_() });
}

function relabelTransactions_(categoryId, newName) {
  var sh = sheet_('Transactions');
  var last = sh.getLastRow();
  if (last < 2) return;
  var idCol = SHEETS.Transactions.indexOf('categoryId') + 1;
  var nameCol = SHEETS.Transactions.indexOf('category') + 1;
  var ids = sh.getRange(2, idCol, last - 1, 1).getValues();
  var names = sh.getRange(2, nameCol, last - 1, 1).getValues();
  var changed = false;
  for (var i = 0; i < ids.length; i++) {
    if (String(ids[i][0]) === String(categoryId)) { names[i][0] = newName; changed = true; }
  }
  if (changed) sh.getRange(2, nameCol, last - 1, 1).setValues(names);
}

function deleteCategory_(p) {
  var cat = findById_('Categories', p.id);
  if (!cat) throw new ApiError_('Category not found.');
  var sameType = readAll_('Categories').filter(function (c) { return c.type === cat.type; });
  if (sameType.length <= 1) throw new ApiError_('Keep at least one ' + cat.type + ' category.');
  deleteRow_('Categories', cat.id); // transactions keep their denormalised category name
}

// ───────────────────────── accounts ─────────────────────────
function saveAccount_(p) {
  var name = text_(p.name, 60);
  if (!name) throw new ApiError_('Account name is required.');
  var type = ACCOUNT_TYPES.indexOf(p.type) >= 0 ? p.type : 'cash';
  var icon = text_(p.icon, 40) || 'account_balance_wallet';
  var color = color_(p.color, '#10B981');
  var all = readAll_('Accounts');
  var id = p.id ? String(p.id) : null;
  var clash = all.some(function (a) { return a.id !== id && a.name.toLowerCase() === name.toLowerCase(); });
  if (clash) throw new ApiError_('An account with this name already exists.');

  if (id) {
    var existing = findById_('Accounts', id);
    if (!existing) throw new ApiError_('Account not found.');
    replaceRow_('Accounts', id, extend_(existing, { name: name, type: type, icon: icon, color: color }));
    return;
  }
  var acc = { id: uid_('acc'), name: name, type: type, icon: icon, color: color, createdAt: now_() };
  append_('Accounts', acc);
  var opening = Number(p.openingBalance || 0);
  if (isFinite(opening) && opening > 0) {
    var today = Utilities.formatDate(new Date(), Session.getScriptTimeZone(), 'yyyy-MM-dd');
    append_('Transactions', newTx_({
      type: 'openingBalance', direction: 'in', amount: Math.round(opening * 100) / 100,
      date: today, accountId: acc.id, title: 'Opening balance'
    }));
  }
}

function deleteAccount_(p) {
  var acc = findById_('Accounts', p.id);
  if (!acc) throw new ApiError_('Account not found.');
  if (readAll_('Accounts').length <= 1) throw new ApiError_('Keep at least one account.');
  var used = readAll_('Transactions').some(function (t) { return t.accountId === acc.id || t.toAccountId === acc.id; });
  if (used) throw new ApiError_('This account has transactions and cannot be deleted.');
  deleteRow_('Accounts', acc.id);
  var def = settingsMap_().defaultAccountId;
  if (def === acc.id) upsertSetting_('defaultAccountId', readAll_('Accounts')[0].id);
}

// ───────────────────────── settings ─────────────────────────
function settingsMap_() {
  var m = {};
  readAll_Settings_().forEach(function (r) { m[r.key] = String(r.value); });
  return m;
}

// Settings uses "key" (not "id") as its first column.
function readAll_Settings_() {
  var sh = sheet_('Settings');
  var last = sh.getLastRow();
  if (last < 2) return [];
  return sh.getRange(2, 1, last - 1, 2).getValues()
    .filter(function (r) { return r[0] !== ''; })
    .map(function (r) { return { key: String(r[0]), value: r[1] }; });
}

function upsertSetting_(key, value) {
  var sh = sheet_('Settings');
  var last = sh.getLastRow();
  if (last >= 2) {
    var keys = sh.getRange(2, 1, last - 1, 1).getValues();
    for (var i = 0; i < keys.length; i++) {
      if (String(keys[i][0]) === key) { sh.getRange(i + 2, 2).setValue(String(value)); return; }
    }
  }
  appendMany_('Settings', [{ key: key, value: String(value) }]);
}

function saveSettings_(p) {
  var values = p.values || {};
  Object.keys(values).forEach(function (k) {
    if (SETTING_KEYS.indexOf(k) < 0) throw new ApiError_('Unknown setting: ' + k);
    var v = text_(values[k], 100);
    if (k === 'currency' && !/^[A-Z]{3}$/.test(v)) throw new ApiError_('Currency must be a 3-letter code.');
    if (k === 'defaultAccountId') requireAccount_(v);
    upsertSetting_(k, v);
  });
}

// ───────────────────────── snapshot ─────────────────────────
function getAll_() {
  var tx = readAll_('Transactions');
  tx.sort(function (a, b) {
    if (a.date !== b.date) return a.date < b.date ? 1 : -1;
    return String(a.createdAt) < String(b.createdAt) ? 1 : -1;
  });
  return {
    transactions: tx,
    loans: readAll_('Loans'),
    repayments: readAll_('LoanRepayments'),
    categories: readAll_('Categories'),
    accounts: readAll_('Accounts'),
    settings: settingsMap_()
  };
}
