<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChatHistory extends Model
{
    protected $table = 'chat_histories';
    
    protected $fillable = [
        'user_id', 
        'sender', 
        'message', 
        'client_created_at'
    ];
}