<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tabel poin peringkat Tantangan Harian.
 *
 * Juara 1 = 7 poin, Juara 2 = 5 poin, Juara 3 = 3 poin,
 * Juara 4 = 2 poin, Peringkat 5 - 20 = 1 poin.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('daily_points', function (Blueprint $table) {
            $table->id();
            $table->date('challenge_date');
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->unsignedTinyInteger('rank');
            $table->unsignedTinyInteger('points');
            $table->unsignedTinyInteger('correct');
            $table->unsignedTinyInteger('total')->default(30);
            $table->unsignedInteger('duration_ms');
            $table->timestamps();

            $table->unique(['challenge_date', 'user_id']);
            $table->unique(['challenge_date', 'rank']);
            $table->index('user_id');
            $table->index('challenge_date');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('daily_points');
    }
};
