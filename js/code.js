// ============================================================
// js/code.js — Contact Manager client logic
//
// NOTE ON API CONTRACT:
// action=login and action=register are the REAL, implemented
// endpoints (see api/index.php). Everything under "CONTACTS API"
// and "ADMIN API" below is written against a PROPOSED contract
// that mirrors that same style (?action=..., JSON body,
// Authorization: Bearer <userId>). If the backend implements
// these with different routes/field names, only the fetch calls
// in this file need to change — update urlBase usages below.
// ============================================================

const urlBase = (typeof window !== 'undefined' && window.location &&
  (window.location.hostname === 'localhost' ||
   window.location.hostname === '127.0.0.1' ||
   window.location.origin.includes('plague.quest')))
  ? '/api/index.php'
  : 'https://plague.quest/api/index.php';

let userId = 0;
let firstName = "";
let lastName = "";
let roleId = 0; // 1 = Admin, 2 = User

// ------------------------------------------------------------
// Shared helpers
// ------------------------------------------------------------

function escapeHtml(str) {
  if (str === null || str === undefined) return "";
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function authXHR(method, url) {
  let xhr = new XMLHttpRequest();
  xhr.open(method, url, true);
  xhr.setRequestHeader("Authorization", "Bearer " + userId);
  xhr.setRequestHeader("X-User-Id", userId);
  return xhr;
}

function saveCookie() {
  let minutes = 20;
  let date = new Date();
  date.setTime(date.getTime() + minutes * 60 * 1000);
  let payload = encodeURIComponent(JSON.stringify({ firstName, lastName, userId, roleId }));
  document.cookie = "session=" + payload + ";expires=" + date.toUTCString() + ";path=/";
}

function readCookie() {
  userId = -1;
  roleId = 0;
  let match = document.cookie.split(";").map(s => s.trim()).find(s => s.startsWith("session="));
  if (!match) return false;
  try {
    let data = JSON.parse(decodeURIComponent(match.split("=").slice(1).join("=")));
    firstName = data.firstName || "";
    lastName = data.lastName || "";
    userId = parseInt(data.userId);
    roleId = parseInt(data.roleId);
  } catch (e) {
    return false;
  }
  return !(userId < 0 || isNaN(userId));
}

function doLogout() {
  userId = 0; firstName = ""; lastName = ""; roleId = 0;
  document.cookie = "session=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/";
  window.location.href = "index.html";
}

function renderUserBar() {
  let el = document.getElementById("userName");
  if (el) {
    el.innerHTML = `<i class="bi bi-person-circle me-1 text-primary"></i> <span>Logged in as <strong class="text-white">${escapeHtml(firstName)} ${escapeHtml(lastName)}</strong></span>`;
  }
}

// Called on index.html load — bounce already-logged-in users straight in
function redirectIfLoggedIn() {
  if (readCookie()) {
    window.location.href = "contacts.html";
  }
}

// Called on contacts.html load — any logged-in user (Admin or User) may view
function requireLogin() {
  if (!readCookie()) {
    window.location.href = "index.html";
    return;
  }
  renderUserBar();
  if (roleId === 1) {
    let adminLink = document.getElementById("adminLink");
    if (adminLink) adminLink.classList.remove("d-none");
  }
  searchContacts();
}

// Called on admin.html load — Admin role only
function requireAdmin() {
  if (!readCookie()) {
    window.location.href = "index.html";
    return;
  }
  if (roleId !== 1) {
    window.location.href = "contacts.html";
    return;
  }
  renderUserBar();
  searchUsers();
}

// ------------------------------------------------------------
// Auth: login / register (index.html)
// ------------------------------------------------------------

function setAuthMode(mode) {
  let loginForm = document.getElementById("loginForm");
  let registerForm = document.getElementById("registerForm");
  let loginTab = document.getElementById("showLoginTab");
  let registerTab = document.getElementById("showRegisterTab");
  if (mode === "register") {
    loginForm.classList.add("d-none");
    registerForm.classList.remove("d-none");
    loginTab.classList.remove("active");
    registerTab.classList.add("active");
  } else {
    registerForm.classList.add("d-none");
    loginForm.classList.remove("d-none");
    registerTab.classList.remove("active");
    loginTab.classList.add("active");
  }
}

function doLogin() {
  userId = 0; firstName = ""; lastName = ""; roleId = 0;

  let login = document.getElementById("loginName").value.trim();
  let password = document.getElementById("loginPassword").value.trim();
  let resultEl = document.getElementById("loginResult");
  resultEl.innerHTML = "";

  let xhr = new XMLHttpRequest();
  xhr.open("POST", urlBase + "?action=login", true);
  xhr.setRequestHeader("Content-type", "application/json; charset=UTF-8");
  xhr.onreadystatechange = function () {
    if (this.readyState === 4) {
      if (this.status === 200) {
        let res = JSON.parse(xhr.responseText);
        if (!res.id || res.id < 1) {
          resultEl.innerHTML = "<i class='bi bi-exclamation-circle-fill me-1'></i> User/Password combination incorrect";
          return;
        }
        userId = res.id;
        firstName = res.firstName;
        lastName = res.lastName;
        roleId = res.RoleId || 2;
        saveCookie();
        window.location.href = "contacts.html";
      } else if (this.status === 403) {
        resultEl.innerHTML = "<i class='bi bi-slash-circle-fill me-1'></i> This account has been disabled";
      } else {
        resultEl.innerHTML = "<i class='bi bi-exclamation-circle-fill me-1'></i> User/Password combination incorrect";
      }
    }
  };
  xhr.send(JSON.stringify({ login: login, password: password }));
}

function doRegister() {
  let payload = {
    firstName: document.getElementById("registerFirstName").value.trim(),
    lastName: document.getElementById("registerLastName").value.trim(),
    login: document.getElementById("registerLogin").value.trim(),
    password: document.getElementById("registerPassword").value.trim()
  };
  let resultEl = document.getElementById("registerResult");
  resultEl.innerHTML = "";

  if (!payload.firstName || !payload.lastName || !payload.login || !payload.password) {
    resultEl.className = "small fw-semibold text-danger-wcag";
    resultEl.innerHTML = "All fields are required";
    return;
  }

  let xhr = new XMLHttpRequest();
  xhr.open("POST", urlBase + "?action=register", true);
  xhr.setRequestHeader("Content-type", "application/json; charset=UTF-8");
  xhr.onreadystatechange = function () {
    if (this.readyState === 4) {
      if (this.status === 201 && xhr.responseText) {
        let res = JSON.parse(xhr.responseText);
        userId = res.id; firstName = res.firstName; lastName = res.lastName; roleId = 2;
        saveCookie();
        window.location.href = "contacts.html";
      } else {
        resultEl.className = "small fw-semibold text-danger-wcag";
        try {
          resultEl.innerHTML = JSON.parse(xhr.responseText).error || "That username may already be taken";
        } catch (e) {
          resultEl.innerHTML = "Registration failed";
        }
      }
    }
  };
  xhr.send(JSON.stringify(payload));
}

// ------------------------------------------------------------
// CONTACTS API (contacts.html) — proposed contract
// ------------------------------------------------------------

function renderContactRow(c) {
  let details = [];
  if (c.phone) details.push(`<i class="bi bi-telephone me-1"></i>${escapeHtml(c.phone)}`);
  if (c.email) details.push(`<i class="bi bi-envelope me-1"></i>${escapeHtml(c.email)}`);
  let detailHtml = details.length
    ? `<div class="contact-detail">${details.join('&nbsp;&nbsp;')}</div>`
    : `<div class="contact-detail">No phone or email on file</div>`;

  return `<div class="contact-row d-flex align-items-center justify-content-between">
    <div>
      <div class="contact-name">${escapeHtml(c.firstName)} ${escapeHtml(c.lastName)}</div>
      ${detailHtml}
    </div>
    <div class="d-flex gap-2">
      <button type="button" class="btn btn-outline-secondary btn-sm" data-contact='${escapeHtml(JSON.stringify(c))}' onclick="openEditContact(JSON.parse(this.dataset.contact))" title="Edit"><i class="bi bi-pencil"></i></button>
      <button type="button" class="btn btn-outline-danger btn-sm" onclick="deleteContact(${Number(c.id)});" title="Delete"><i class="bi bi-trash"></i></button>
    </div>
  </div>`;
}

function searchContacts() {
  let q = document.getElementById("searchText").value.trim();
  let resultEl = document.getElementById("contactSearchResult");
  let listEl = document.getElementById("contactList");
  resultEl.innerHTML = "";

  let url = urlBase + "?action=contacts" + (q ? ("&q=" + encodeURIComponent(q)) : "");
  let xhr = authXHR("GET", url);
  xhr.onreadystatechange = function () {
    if (this.readyState === 4) {
      if (this.status === 200) {
        let res = JSON.parse(xhr.responseText);
        let contacts = res.contacts || [];
        if (contacts.length === 0) {
          listEl.innerHTML = `<div class="list-empty-state"><i class="bi bi-info-circle me-1"></i> No matching contacts found.</div>`;
          resultEl.innerHTML = "";
          return;
        }
        resultEl.innerHTML = "<i class='bi bi-check-circle me-1'></i> Results updated";
        listEl.innerHTML = contacts.map(renderContactRow).join("");
      } else {
        listEl.innerHTML = `<div class="list-empty-state">Unable to load contacts right now.</div>`;
      }
    }
  };
  xhr.send();
}

function addContact() {
  let payload = {
    firstName: document.getElementById("newFirstName").value.trim(),
    lastName: document.getElementById("newLastName").value.trim(),
    phone: document.getElementById("newPhone").value.trim(),
    email: document.getElementById("newEmail").value.trim()
  };
  let resultEl = document.getElementById("contactAddResult");
  resultEl.innerHTML = "";

  if (!payload.firstName || !payload.lastName) {
    resultEl.className = "small fw-semibold text-danger-wcag";
    resultEl.innerHTML = "First and last name are required";
    return;
  }

  let xhr = authXHR("POST", urlBase + "?action=addContact");
  xhr.setRequestHeader("Content-type", "application/json; charset=UTF-8");
  xhr.onreadystatechange = function () {
    if (this.readyState === 4) {
      if (this.status === 201 || this.status === 200) {
        resultEl.className = "small fw-semibold text-success-wcag";
        resultEl.innerHTML = "<i class='bi bi-check-circle-fill me-1'></i> Contact added!";
        ["newFirstName", "newLastName", "newPhone", "newEmail"].forEach(id => document.getElementById(id).value = "");
        searchContacts();
      } else {
        resultEl.className = "small fw-semibold text-danger-wcag";
        resultEl.innerHTML = "Failed to add contact";
      }
    }
  };
  xhr.send(JSON.stringify(payload));
}

function openEditContact(c) {
  document.getElementById("editId").value = c.id;
  document.getElementById("editFirstName").value = c.firstName || "";
  document.getElementById("editLastName").value = c.lastName || "";
  document.getElementById("editPhone").value = c.phone || "";
  document.getElementById("editEmail").value = c.email || "";
  document.getElementById("editContactResult").innerHTML = "";
  new bootstrap.Modal(document.getElementById("editContactModal")).show();
}

function saveContactEdit() {
  let payload = {
    id: parseInt(document.getElementById("editId").value),
    firstName: document.getElementById("editFirstName").value.trim(),
    lastName: document.getElementById("editLastName").value.trim(),
    phone: document.getElementById("editPhone").value.trim(),
    email: document.getElementById("editEmail").value.trim()
  };
  let resultEl = document.getElementById("editContactResult");

  let xhr = authXHR("PUT", urlBase + "?action=editContact");
  xhr.setRequestHeader("Content-type", "application/json; charset=UTF-8");
  xhr.onreadystatechange = function () {
    if (this.readyState === 4) {
      if (this.status === 200) {
        bootstrap.Modal.getInstance(document.getElementById("editContactModal")).hide();
        searchContacts();
      } else {
        resultEl.className = "small fw-semibold text-danger-wcag";
        resultEl.innerHTML = "Failed to save changes";
      }
    }
  };
  xhr.send(JSON.stringify(payload));
}

function deleteContact(id) {
  if (!confirm("Delete this contact? This cannot be undone.")) return;
  let xhr = authXHR("DELETE", urlBase + "?action=deleteContact&id=" + id);
  xhr.onreadystatechange = function () {
    if (this.readyState === 4 && this.status === 200) {
      searchContacts();
    }
  };
  xhr.send();
}

// ------------------------------------------------------------
// ADMIN API (admin.html) — proposed contract
// ------------------------------------------------------------

function renderUserRow(u) {
  let roleBadge = u.roleId === 1
    ? `<span class="badge rounded-pill badge-role-admin px-3 py-2">Admin</span>`
    : `<span class="badge rounded-pill badge-role-user px-3 py-2">User</span>`;
  let statusBadge = u.isActive
    ? `<span class="badge rounded-pill badge-status-active px-3 py-2">Active</span>`
    : `<span class="badge rounded-pill badge-status-disabled px-3 py-2">Disabled</span>`;
  let toggleLabel = u.isActive ? "Disable" : "Enable";
  let toggleClass = u.isActive ? "btn-outline-danger" : "btn-outline-success";
  let fullName = `${u.firstName} ${u.lastName}`;

  return `<tr>
    <td>${escapeHtml(u.firstName)} ${escapeHtml(u.lastName)}</td>
    <td class="text-secondary-contrast">${escapeHtml(u.login)}</td>
    <td>${roleBadge}</td>
    <td>${statusBadge}</td>
    <td class="text-end">
      <button type="button" class="btn btn-outline-secondary btn-sm me-1" data-uid="${Number(u.id)}" data-label="${escapeHtml(fullName)}" onclick="openResetPassword(this.dataset.uid, this.dataset.label)">Reset Password</button>
      <button type="button" class="btn ${toggleClass} btn-sm" onclick="toggleUserActive(${Number(u.id)}, ${u.isActive ? 'true' : 'false'});">${toggleLabel}</button>
    </td>
  </tr>`;
}

function searchUsers() {
  let q = document.getElementById("userSearchText").value.trim();
  let resultEl = document.getElementById("userSearchResult");
  let bodyEl = document.getElementById("userTableBody");
  resultEl.innerHTML = "";

  let url = urlBase + "?action=users" + (q ? ("&q=" + encodeURIComponent(q)) : "");
  let xhr = authXHR("GET", url);
  xhr.onreadystatechange = function () {
    if (this.readyState === 4) {
      if (this.status === 200) {
        let res = JSON.parse(xhr.responseText);
        let users = res.users || [];
        if (users.length === 0) {
          bodyEl.innerHTML = `<tr><td colspan="5" class="list-empty-state">No matching users found.</td></tr>`;
          return;
        }
        resultEl.innerHTML = "<i class='bi bi-check-circle me-1'></i> Results updated";
        bodyEl.innerHTML = users.map(renderUserRow).join("");
      } else if (this.status === 403) {
        bodyEl.innerHTML = `<tr><td colspan="5" class="list-empty-state">Admin access required.</td></tr>`;
      } else {
        bodyEl.innerHTML = `<tr><td colspan="5" class="list-empty-state">Unable to load users right now.</td></tr>`;
      }
    }
  };
  xhr.send();
}

function toggleUserActive(targetUserId, currentlyActive) {
  if (!confirm(`Are you sure you want to ${currentlyActive ? "disable" : "enable"} this user?`)) return;

  let xhr = authXHR("POST", urlBase + "?action=setUserActive");
  xhr.setRequestHeader("Content-type", "application/json; charset=UTF-8");
  xhr.onreadystatechange = function () {
    if (this.readyState === 4 && this.status === 200) {
      searchUsers();
    }
  };
  xhr.send(JSON.stringify({ userId: targetUserId, isActive: !currentlyActive }));
}

function openResetPassword(targetUserId, label) {
  document.getElementById("resetUserId").value = targetUserId;
  document.getElementById("resetUserLabel").innerText = label;
  document.getElementById("resetNewPassword").value = "";
  document.getElementById("resetPasswordResult").innerHTML = "";
  new bootstrap.Modal(document.getElementById("resetPasswordModal")).show();
}

function saveResetPassword() {
  let targetUserId = parseInt(document.getElementById("resetUserId").value);
  let newPassword = document.getElementById("resetNewPassword").value.trim();
  let resultEl = document.getElementById("resetPasswordResult");

  if (!newPassword || newPassword.length < 6) {
    resultEl.className = "small fw-semibold text-danger-wcag d-block mt-2";
    resultEl.innerHTML = "Password must be at least 6 characters";
    return;
  }

  let xhr = authXHR("POST", urlBase + "?action=resetPassword");
  xhr.setRequestHeader("Content-type", "application/json; charset=UTF-8");
  xhr.onreadystatechange = function () {
    if (this.readyState === 4) {
      if (this.status === 200) {
        bootstrap.Modal.getInstance(document.getElementById("resetPasswordModal")).hide();
      } else {
        resultEl.className = "small fw-semibold text-danger-wcag d-block mt-2";
        resultEl.innerHTML = "Failed to reset password";
      }
    }
  };
  xhr.send(JSON.stringify({ userId: targetUserId, newPassword: newPassword }));
}

function createAdmin() {
  let payload = {
    firstName: document.getElementById("newAdminFirstName").value.trim(),
    lastName: document.getElementById("newAdminLastName").value.trim(),
    login: document.getElementById("newAdminLogin").value.trim(),
    password: document.getElementById("newAdminPassword").value.trim(),
    roleId: 1
  };
  let resultEl = document.getElementById("createAdminResult");
  resultEl.innerHTML = "";

  if (!payload.firstName || !payload.lastName || !payload.login || !payload.password) {
    resultEl.className = "small fw-semibold text-danger-wcag";
    resultEl.innerHTML = "All fields are required";
    return;
  }

  let xhr = authXHR("POST", urlBase + "?action=adminCreateUser");
  xhr.setRequestHeader("Content-type", "application/json; charset=UTF-8");
  xhr.onreadystatechange = function () {
    if (this.readyState === 4) {
      if (this.status === 201) {
        resultEl.className = "small fw-semibold text-success-wcag";
        resultEl.innerHTML = "<i class='bi bi-check-circle-fill me-1'></i> Admin account created!";
        ["newAdminFirstName", "newAdminLastName", "newAdminLogin", "newAdminPassword"].forEach(id => document.getElementById(id).value = "");
        searchUsers();
      } else {
        resultEl.className = "small fw-semibold text-danger-wcag";
        resultEl.innerHTML = "Failed to create admin account";
      }
    }
  };
  xhr.send(JSON.stringify(payload));
}