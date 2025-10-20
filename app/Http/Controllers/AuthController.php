<?php

namespace App\Http\Controllers;

use App\Models\User;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use PragmaRX\Google2FA\Google2FA;
use BaconQrCode\Renderer\ImageRenderer;
use BaconQrCode\Renderer\RendererStyle\RendererStyle;
// Remove the next import! v2.x does NOT have `Image\Png`
use BaconQrCode\Writer;


class AuthController extends Controller
{
    // Register a new user
    public function register(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
            // Demographic fields
            'first_name' => 'nullable|string|max:255',
            'last_name' => 'nullable|string|max:255',
            'full_address' => 'nullable|string|max:255',
            'street_address' => 'nullable|string|max:255',
            'city' => 'nullable|string|max:255',
            'country' => 'nullable|string|max:255',
            'zip_code' => 'nullable|string|max:20',
            'mobile_phone_number' => 'nullable|string|max:20',
        ]);
        $data['password'] = Hash::make($data['password']);
        $user = User::create($data);
        return response()->json([
    'message' => 'User registered',
    'user' => $user,
    'user_id' => $user->id,
]);

    }

    // Login step 1 of 2FA setup
    public function login(Request $request)
    {
        $credentials = $request->only('email', 'password');
        if (!Auth::attempt($credentials)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }
        $user = Auth::user();

        // If 2FA is enabled, require the 2FA code
        if ($user->two_factor_secret) {
            return response()->json(['2fa_required' => true, 'user_id' => $user->id]);
        }

        $token = $user->createToken('auth_token')->plainTextToken;
        return response()->json(['access_token' => $token, 'token_type' => 'Bearer']);
    }

    // set up 2FA with Google Authenticator ( returns secret/QR)
    public function setup2FA(Request $request)
    {
        $user = Auth::user();
        $google2fa = new Google2FA();
        $secret = $google2fa->generateSecretKey();
        $user->two_factor_secret = $secret;
        $user->save();

        $otpAuthUrl = $google2fa->getQRCodeUrl(
            'YourAppName', // or set your own app name
            $user->email,
            $secret
        );

        // Generate QR code PNG as base64 string using BaconQrCode
        $renderer = new ImageRenderer(
            new RendererStyle(200),
            new \BaconQrCode\Renderer\Image\SvgImageBackEnd()
        );

        $writer = new Writer($renderer);
        $pngData = $writer->writeString($otpAuthUrl);
        $qr_base64 = 'data:image/svg+xml;base64,' . base64_encode($pngData);

        return response()->json([
            'secret' => $secret,
            'otpauth_url' => $otpAuthUrl,
            'qr' => $qr_base64,
            'user_id' => $user->id
        ]);
    }

    // Verify 2FA code during login ( step 2 of 2FA Login)
    public function verify2FA(Request $request)
    {
        $user = User::find($request->user_id); // Receive from login's 2fa_required step
        if (!$user) {
        return response()->json(['message' => 'User not found'], 404);
    }
        $google2fa = new Google2FA();
        $valid = $google2fa->verifyKey($user->two_factor_secret, $request->input('code'));
        if (!$valid) {
            return response()->json(['message' => 'Invalid 2FA code'], 401);
        }
        $token = $user->createToken('auth_token')->plainTextToken;
        return response()->json(['access_token' => $token, 'token_type' => 'Bearer']);
    }

    // Get demographic of the authenticated user
    public function profile(Request $request)
    {
        $user = $request->user();
        return response()->json($user);
    }
}
