<?php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function googleLogin(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'name' => 'required'
        ]);

        // Cek atau Buat User Baru
        $user = User::updateOrCreate(
            ['email' => $request->email],
            [
                'name' => $request->name,
                'google_id' => $request->google_id,
                'password' => bcrypt(Str::random(16)) // Password acak karena login Google
            ]
        );

        // Buat Token Sanctum
        $token = $user->createToken('api_token')->plainTextToken;

        return response()->json([
            'access_token' => $token,
            'user' => $user
        ], 200);
    }
}