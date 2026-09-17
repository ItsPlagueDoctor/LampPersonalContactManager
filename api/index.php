<?php
// ============================================================
//  api/index.php — Unified Colors Manager RESTful API
//
//  GET    /api/index.php?ping=1   — status ping health check
//  POST   /api/index.php?action=login (login)  — authenticate user
//  POST   /api/index.php?action=register (signup) — sign up/register
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

    // Needed variables
    $firstName = clean($body['firstName']);
    $lastName = clean($body['lastName']);
    $login = clean($body['login']);
    $password = clean($body['password']);

    // Check if all are there
    if (!$firstName || !$lastName || !$login || !$password) {
            respond(400, ['error' => 'First name, last name, login and password are all required']);
    }

    // Hash password
    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);

    // Add new user fields into the database
    $sql = "INSERT INTO Users(firstName, lastName, login, password, RoleID) VALUES (:firstName, :lastName, :login, :password, :RoleID)";
    $stmt = $db->prepare($sql);
    $stmt->execute([
        ':firstName' => $firstName,
        ':lastName' => $lastName,
        ':login' => $login,
        ':password' => $hashedPassword,
        ':RoleID' => 2
    ]);

    // Get the ID since db is auto increment
    $userId = $db->lastInsertId();

    // Status codes
    if ($userId) {
            respond(201, [
                'id'        => (int) $userId,
                'firstName' => $firstName,
                'lastName'  => $lastName,
                'token'     => (string) $userId,
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