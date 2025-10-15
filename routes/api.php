<?php

use App\Http\Controllers\AuthController;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::middleware('auth:sanctum')->group(function() {
    Route::post('/setup-2fa', [AuthController::class, 'setup2FA']);
    Route::post('/verify-2fa', [AuthController::class, 'verify2FA']);
    Route::get('/profile', [AuthController::class, 'profile']);
});

