<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;

// Registration and login do not require authentication
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/verify-2fa', [AuthController::class, 'verify2FA']);
Route::middleware('auth:sanctum')->group(function() {
    Route::post('/setup-2fa', [AuthController::class, 'setup2FA']);
    
    Route::get('/profile', [AuthController::class, 'profile']);
});

