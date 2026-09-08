<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\TestResult;
use App\Models\UserIqScore;
use App\Models\ChatHistory;
use Illuminate\Support\Facades\Log;

class SyncController extends Controller
{
    // MENERIMA DATA DARI HP FLUTTER
    public function syncData(Request $request)
    {
        try {
            $user = $request->user();

            // --- TAMBAHAN LOGIKA KOIN HIBRIDA ---
            // Bandingkan koin di HP dengan koin di DB. Ambil nilai yang paling tinggi (max).
            if ($request->has('wartegg_credits')) {
                $user->wartegg_credits = max($user->wartegg_credits, $request->wartegg_credits);
            }
            if ($request->has('eq_sq_credits')) {
                $user->eq_sq_credits = max($user->eq_sq_credits, $request->eq_sq_credits);
            }
            if ($request->has('kredit_iq_pro')) {
                $user->kredit_iq_pro = max($user->kredit_iq_pro, $request->kredit_iq_pro);
            }
            $user->save();
            // ------------------------------------

            // 1. Simpan Data Tes
            if ($request->has('tests')) {
                foreach ($request->tests as $test) {
                    $name  = trim((string) ($test['test_name'] ?? ''));
                    $score = (int) ($test['score'] ?? -1);
                    $total = (int) ($test['total_questions'] ?? 0);

                    // Lewati baris yang mustahil. Tanpa ini, siapa pun bisa
                    // mengirim score 9999 dan menguasai papan peringkat.
                    //
                    // Sengaja 'continue', BUKAN throw/validate(): kalau satu
                    // baris rusak menggagalkan seluruh request, user kehilangan
                    // cadangan SELURUH riwayatnya, bukan cuma baris itu.
                    //
                    // Sengaja TANPA whitelist nama tes: kalau jenis tes baru
                    // ditambahkan di APK dan lupa didaftarkan di sini, hasilnya
                    // akan hilang diam-diam. Validasi angka sudah cukup.
                    if ($name === '' || mb_strlen($name) > 100) {
                        continue;
                    }
                    if ($score < 0 || $total < 1 || $total > 200 || $score > $total) {
                        continue;
                    }

                    $user->testResults()->updateOrCreate(
                        ['client_created_at' => $test['created_at'] ?? (string) time()],
                        [
                            'test_name' => $name,
                            'score' => $score,
                            'total_questions' => $total,
                            'ai_analysis' => $test['ai_analysis'] ?? null,
                        ]
                    );
                }
            }

            // Perbarui skor IQ terhitung untuk papan peringkat.
            // HANYA MEMBACA test_results dan menulis ke user_iq_scores --
            // tidak ada baris hasil tes yang tersentuh. Dibungkus try/catch
            // supaya kegagalan di sini tidak pernah menggagalkan backup data
            // user, yang jauh lebih penting daripada papan peringkat.
            try {
                UserIqScore::recomputeFor($user->id);
            } catch (\Throwable $e) {
                Log::warning('Gagal hitung ulang skor IQ: ' . $e->getMessage());
            }

            // 2. Simpan Data Chat
            if ($request->has('chats')) {
                foreach ($request->chats as $chat) {
                    $user->chatHistories()->updateOrCreate(
                        ['client_created_at' => $chat['timestamp'] ?? $chat['created_at'] ?? (string) time()],
                        [
                            'sender' => $chat['sender'],
                            'message' => $chat['message'],
                        ]
                    );
                }
            }

            return response()->json(['message' => 'Backup Data Sukses!'], 200);

        } catch (\Exception $e) {
            Log::error("Error Sinkronisasi Flutter: " . $e->getMessage());
            return response()->json(['error' => 'Gagal menyimpan: ' . $e->getMessage()], 500);
        }
    }

    // MENGIRIM DATA KE HP BARU SAAT LOGIN
    public function getUserData(Request $request)
    {
        $user = $request->user();

        $tests = $user->testResults()->orderBy('id', 'asc')->get()->map(function($t) {
            return [
                'test_name' => $t->test_name,
                'score' => $t->score,
                'total_questions' => $t->total_questions,
                'ai_analysis' => $t->ai_analysis,
            ];
        });

        $chats = $user->chatHistories()->orderBy('id', 'asc')->get()->map(function($c) {
            return [
                'sender' => $c->sender,
                'message' => $c->message,
            ];
        });

        return response()->json([
            'tests' => $tests,
            'chats' => $chats,
            // --- TAMBAHAN PENGIRIMAN KOIN KE HP ---
            'wartegg_credits' => $user->wartegg_credits,
            'eq_sq_credits' => $user->eq_sq_credits,
            'kredit_iq_pro' => $user->kredit_iq_pro,
        ], 200);
    }
    
    // FUNGSI BARU: MENGHAPUS CHAT DARI DATABASE SERVER
    public function clearChats(Request $request)
    {
        try {
            $user = $request->user();
            $user->chatHistories()->delete(); // Menghapus semua chat milik user ini
            return response()->json(['message' => 'Riwayat chat server berhasil dibersihkan!'], 200);
        } catch (\Exception $e) {
            return response()->json(['error' => 'Gagal menghapus: ' . $e->getMessage()], 500);
        }
    }
}