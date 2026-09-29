<?php
// ============================================================
//  api/index.php — Unified Colors Manager RESTful API
//
//  GET    /api/index.php?ping=1   — status ping health check
//  POST   /api/index.php?action=login (login)  — authenticate user
//  POST   /api/index.php?action=register (signup) — sign up/register

// ========ALL (ADMIN AND USERS)=============
//  GET    /api/index.php          — list all contacts for user
//  GET    /api/index.php?q=term   — partial search contacts (filtering)
//  GET    /api/index.php?id=1     — get single contact by ID
//  POST   /api/index.php (contact)  — create conctact
//  PUT    /api/index.php?id=1     — update contact
//  DELETE /api/index.php?id=1     — delete contact

// ========ADMIN ONLY============
// PUT    /api/index.php?action=changePassword&id=1    — change user passwords
// POST    /api/index.php?action=createAdmin     — create other admin accounts (add functionality to manage them like any other user)
// PUT     /api/index.php?action=disableUser&id=1    — disable any user including other Admin users
// GET     /api/index.php?action=listUsers         —  see and query all users and their entries
// ============================================================

require_once __DIR__ . '/db.php';
require_once __DIR__ . '/helpers.php';

setCORSHeaders();

$method = $_SERVER['REQUEST_METHOD'];
$db     = getDB();
$action = $_GET['action'] ?? '';

// 1. Unauthenticated Health Check (Ping)
if ($method === 'GET' && (isset($_GET['ping']) || (isset($_GET['action']) && $_GET['action'] === 'ping'))) {
    respond(200, ['status' => 'OK', 'timestamp' => time()]);
}

// 2. Unauthenticated Login (POST with login & password in body)
if ($method === 'POST' && $action === 'login') {
    $body = getRequestBody();
    if (isset($body['login']) && isset($body['password'])) {
        $login    = clean($body['login']);
        $password = $body['password'];

        if (!$login || !$password) {
            respond(400, ['error' => 'Login and password are required']);
        }

        $stmt = $db->prepare('SELECT ID, firstName, lastName, password, RoleID, IsActive FROM Users WHERE Login = :login LIMIT 1');
        $stmt->execute([':login' => $login]);
        $user = $stmt->fetch();

        if ($user && password_verify($password, $user['password'])) {
            // Check if active
            if((int)$user['IsActive'] !== 1){
                respond(403, ['error' => 'Account is disabled']);
            }

            respond(200, [
                'id'        => (int) $user['ID'],
                'firstName' => $user['firstName'],
                'lastName'  => $user['lastName'],
                'RoleId'    => (int)$user['RoleID'],
                'token'     => (string) $user['ID'],
                'error'     => ''
            ]);
        } else {
            respond(401, [
                'id'        => 0,
                'firstName' => '',
                'lastName'  => '',
                'error'     => 'No Records Found'
            ]);
        }
    }
}

// 3. Register/Sign Up new user
if($method === 'POST' && $action === 'register'){
    $body = getRequestBody();

    createUser($db, $body, 2);
}

// ==================================================
// All other routes require an authenticated user
$userId = requireAuth();
// ==================================================

// ADMIN ONLY
// ==================================================

// Changes a user password
if($method === 'PUT' && $action === 'changePassword'){
    requireAdmin($db, $userId);

    $id = isset($_GET['id']) ? (int) $_GET['id'] : null;

    if (!$id) {
        respond(400, ['error' => 'User ID is required — use ?id=']);
     }

    // Check if user exists
    $check = $db->prepare('SELECT ID FROM Users WHERE ID = :id LIMIT 1');
    $check->execute([':id' => $id]);
    if (!$check->fetch()) {
        respond(404, ['error' => 'User not found']);
    }

    $body  = getRequestBody();
    $password = $body['password'] ?? '';

    if (!$password) {
        respond(400, ['error' => 'Password is required']);
    }

    // Hash password
    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);

    $stmt = $db->prepare('UPDATE Users SET password = :password WHERE ID = :id');
    $stmt->execute([':password' => $hashedPassword,':id'  => $id]);

    respond(200, ['message' => 'Password updated', 'error' => '']);
}

// Creates another admin
if($method === 'POST' && $action === 'createAdmin'){
    requireAdmin($db, $userId);

    $body = getRequestBody();

    createUser($db, $body, 1);
}

// Lists all users
if($method === 'GET' && $action === 'listUsers'){
    requireAdmin($db, $userId);

    $stmt = $db->prepare('SELECT ID as id, FirstName as firstName, LastName as lastName, Login as login, RoleID as roleID,  DateCreated as dateCreated, DateUpdated as dateUpdated, IsActive as isActive FROM Users ORDER BY LastName, FirstName');
    $stmt->execute();
    $users = $stmt->fetchAll();
    if (empty($users)) {
        respond(200, ['users' => [], 'error' => 'No Records Found']);
    }
    respond(200, ['users' => $users, 'error' => '']);
}

// Disables user
if($method === 'PUT' && $action === 'disableUser'){
    requireAdmin($db, $userId);

    $id = isset($_GET['id']) ? (int) $_GET['id'] : null;

    if (!$id) {
        respond(400, ['error' => 'User ID is required — use ?id=']);
     }

    // Check if user exists
    $check = $db->prepare('SELECT ID FROM Users WHERE ID = :id LIMIT 1');
    $check->execute([':id' => $id]);
    if (!$check->fetch()) {
        respond(404, ['error' => 'User not found']);
    }

    $stmt = $db->prepare('UPDATE Users SET IsActive = 0 WHERE ID = :id');
    $stmt->execute([':id'  => $id]);

    respond(200, ['message' => 'User disabled', 'error' => '']);
}


// ALL (USER AND ADMIN)
// ==================================================
switch($method){
    case 'GET':
        $id     = isset($_GET['id']) ? (int) $_GET['id'] : null;
        $search = isset($_GET['q'])  ? trim($_GET['q'])  : (isset($_GET['search']) ? trim($_GET['search']) : null);

        // Single contact by ID
        if ($id) {
            $stmt = $db->prepare('SELECT ID as id, FirstName as firstName, LastName as lastName, Phone as phone, Email as email FROM Contacts WHERE ID = :id AND UserID = :uid LIMIT 1');
            $stmt->execute([':id' => $id, ':uid' => $userId]);
            $contact = $stmt->fetch();
            if (!$contact) {
                respond(404, ['error' => 'Contact not found']);
            }
            respond(200, $contact);
        }

        // Search contact (partial match)
        if ($search !== null && $search !== '') {
            $like = '%' . $search . '%';
            $stmt = $db->prepare('SELECT ID as id, FirstName as firstName, LastName as lastName, Phone as phone, Email as email FROM Contacts WHERE UserID = :uid AND ( FirstName LIKE :q1 OR LastName LIKE :q2 OR Phone LIKE :q3 OR Email LIKE :q4 ) ORDER BY LastName, FirstName');
            $stmt->execute([':uid' => $userId, ':q1' => $like, ':q2' => $like, ':q3' => $like, ':q4' => $like]);
            $contacts = $stmt->fetchAll();
            if (empty($contacts)) {
                respond(200, ['contacts' => [], 'error' => 'No Records Found']);
            }
            respond(200, ['contacts' => $contacts, 'error' => '']);
        }

        // List all contacts
        $stmt = $db->prepare('SELECT ID as id, FirstName as firstName, LastName as lastName, Phone as phone, Email as email FROM Contacts WHERE UserID = :uid ORDER BY LastName, FirstName');
        $stmt->execute([':uid' => $userId]);
        $contacts = $stmt->fetchAll();
        if (empty($contacts)) {
            respond(200, ['contacts' => [], 'error' => 'No Records Found']);
        }
        respond(200, ['contacts' => $contacts, 'error' => '']);
        break;

    // Create contact
    case 'POST':
        $body = getRequestBody();
        $firstName = clean($body['firstName'] ?? '');
        $lastName  = clean($body['lastName'] ?? '');
        $phone     = clean($body['phone'] ?? '');
        $email     = clean($body['email'] ?? '');

        if (!$firstName || !$lastName) {
            respond(400, ['error' => 'First name and last name are required' ]);
        }

        $stmt = $db->prepare('INSERT INTO Contacts (UserID, FirstName, LastName, Phone, Email) VALUES (:uid, :firstName, :lastName, :phone, :email)');
        $stmt->execute([':uid' => $userId,':firstName' => $firstName,':lastName'  => $lastName,':phone'  => $phone,':email' => $email]);
        respond(201, ['message' => 'Contact created','id' => (int) $db->lastInsertId(), 'error' => '']);

        break;

    // Update contact
    case 'PUT':
        $id = isset($_GET['id']) ? (int) $_GET['id'] : 0;
        if (!$id) {
            respond(400, ['error' => 'Contact ID is required — use ?id=']);
        }

        $check = $db->prepare('SELECT ID FROM Contacts WHERE ID = :id AND UserID = :uid LIMIT 1');
        $check->execute([':id' => $id, ':uid' => $userId]);
        if (!$check->fetch()) {
            respond(404, ['error' => 'Contact not found']);
        }

        $body  = getRequestBody();
        $firstName = clean($body['firstName'] ?? '');
        $lastName  = clean($body['lastName'] ?? '');
        $phone     = clean($body['phone'] ?? '');
        $email     = clean($body['email'] ?? '');

        if (!$firstName || !$lastName) {
            respond(400, [
                'error' => 'First name and last name are required'
            ]);
        }
        $stmt = $db->prepare('UPDATE Contacts SET FirstName = :firstName, LastName = :lastName, Phone = :phone, Email = :email WHERE ID = :id AND UserID = :uid');
        $stmt->execute([':firstName' => $firstName,':lastName' => $lastName,':phone' => $phone, ':email'  => $email,':id'  => $id,':uid'  => $userId]);

        respond(200, ['message' => 'Contact updated', 'error' => '']);
        break;

    // Delete contact
    case 'DELETE':
        $id   = isset($_GET['id']) ? (int) $_GET['id'] : 0;

        if ($id > 0) {
            $stmt = $db->prepare('DELETE FROM Contacts WHERE ID = :id AND UserID = :uid');
            $stmt->execute([':id' => $id, ':uid' => $userId]);
        } else {
            respond(400, ['error' => 'Contact ID is required — use ?id=']);
        }

        if ($stmt->rowCount() === 0) {
            respond(404, ['error' => 'Contact not found']);
        }

        respond(200, ['message' => 'Contact deleted', 'error' => '']);
        break;

    default:
        respond(405, ['error' => 'Method not allowed']);
}

