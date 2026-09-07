class MbtiData {
  static final List<Map<String, dynamic>> questions = [

    // ==========================================
    // DIMENSI 1: Ekstrovert (E) vs Introvert (I)
    // Opsi A = E, Opsi B = I
    // ==========================================
    {
      "id": 1,
      "dimension": "EI",
      "question": "Setelah melalui minggu yang sangat sibuk dan melelahkan, Anda memulihkan energi dengan cara...",  // fallback (Indonesian)
      "questionId": "Setelah melalui minggu yang sangat sibuk dan melelahkan, Anda memulihkan energi dengan cara...",
      "questionEn": "After a very busy and exhausting week, you recharge your energy by...",
      "options": ["A. Berkumpul dan pergi keluar bersama teman-teman.", "B. Tinggal di rumah, menyendiri, dan bersantai dalam ketenangan."],  // fallback (Indonesian)
      "optionsId": ["A. Berkumpul dan pergi keluar bersama teman-teman.", "B. Tinggal di rumah, menyendiri, dan bersantai dalam ketenangan."],
      "optionsEn": ["A. Gathering and going out with friends.", "B. Staying at home, being alone, and relaxing in peace."]
    },
    {
      "id": 2,
      "dimension": "EI",
      "question": "Saat berada di lingkungan sosial baru (seperti pesta atau seminar), Anda biasanya...",  // fallback (Indonesian)
      "questionId": "Saat berada di lingkungan sosial baru (seperti pesta atau seminar), Anda biasanya...",
      "questionEn": "When in a new social environment (such as a party or seminar), you usually...",
      "options": ["A. Mudah berbaur dan memulai obrolan dengan banyak orang baru.", "B. Cenderung diam, mengamati, atau hanya berbicara dengan orang yang sudah dikenal."],  // fallback (Indonesian)
      "optionsId": ["A. Mudah berbaur dan memulai obrolan dengan banyak orang baru.", "B. Cenderung diam, mengamati, atau hanya berbicara dengan orang yang sudah dikenal."],
      "optionsEn": ["A. Easily mingle and start conversations with many new people.", "B. Tend to be quiet, observe, or only talk to people you already know."]
    },
    {
      "id": 3,
      "dimension": "EI",
      "question": "Saat menghadapi masalah yang mengganjal, Anda cenderung...",  // fallback (Indonesian)
      "questionId": "Saat menghadapi masalah yang mengganjal, Anda cenderung...",
      "questionEn": "When facing a lingering problem, you tend to...",
      "options": ["A. Membicarakannya dengan orang lain untuk membantu menemukan solusi.", "B. Memikirkannya dan merenungkannya sendiri terlebih dahulu sebelum bertindak."],  // fallback (Indonesian)
      "optionsId": ["A. Membicarakannya dengan orang lain untuk membantu menemukan solusi.", "B. Memikirkannya dan merenungkannya sendiri terlebih dahulu sebelum bertindak."],
      "optionsEn": ["A. Discuss it with others to help find a solution.", "B. Think and reflect on it yourself first before taking action."]
    },
    {
      "id": 4,
      "dimension": "EI",
      "question": "Lingkungan kerja atau belajar yang paling ideal bagi Anda adalah...",  // fallback (Indonesian)
      "questionId": "Lingkungan kerja atau belajar yang paling ideal bagi Anda adalah...",
      "questionEn": "Your ideal work or study environment is...",
      "options": ["A. Lingkungan yang dinamis, sibuk, dan penuh dengan interaksi.", "B. Lingkungan yang tenang, pribadi, dan minim gangguan."],  // fallback (Indonesian)
      "optionsId": ["A. Lingkungan yang dinamis, sibuk, dan penuh dengan interaksi.", "B. Lingkungan yang tenang, pribadi, dan minim gangguan."],
      "optionsEn": ["A. A dynamic, busy environment full of interactions.", "B. A quiet, private environment with minimal distractions."]
    },
    {
      "id": 5,
      "dimension": "EI",
      "question": "Orang lain di sekitar Anda (rekan kerja/teman) biasanya melihat Anda sebagai sosok yang...",  // fallback (Indonesian)
      "questionId": "Orang lain di sekitar Anda (rekan kerja/teman) biasanya melihat Anda sebagai sosok yang...",
      "questionEn": "Others around you (colleagues/friends) usually see you as someone...",
      "options": ["A. Terbuka, ramah, dan mudah ditebak jalan pikirannya.", "B. Tenang, tertutup, dan pendengar yang sangat baik."],  // fallback (Indonesian)
      "optionsId": ["A. Terbuka, ramah, dan mudah ditebak jalan pikirannya.", "B. Tenang, tertutup, dan pendengar yang sangat baik."],
      "optionsEn": ["A. Open, friendly, and easy to read.", "B. Calm, reserved, and a very good listener."]
    },
    {
      "id": 6,
      "dimension": "EI",
      "question": "Saat telepon berdering dari nomor yang tidak begitu dikenal, Anda biasanya...",  // fallback (Indonesian)
      "questionId": "Saat telepon berdering dari nomor yang tidak begitu dikenal, Anda biasanya...",
      "questionEn": "When the phone rings from an unfamiliar number, you usually...",
      "options": ["A. Langsung mengangkatnya tanpa ragu.", "B. Membiarkannya berdering atau merasa enggan untuk langsung menjawab."],  // fallback (Indonesian)
      "optionsId": ["A. Langsung mengangkatnya tanpa ragu.", "B. Membiarkannya berdering atau merasa enggan untuk langsung menjawab."],
      "optionsEn": ["A. Pick it up right away without hesitation.", "B. Let it ring or feel reluctant to answer immediately."]
    },
    {
      "id": 7,
      "dimension": "EI",
      "question": "Saya lebih mudah mengekspresikan gagasan saya melalui...",  // fallback (Indonesian)
      "questionId": "Saya lebih mudah mengekspresikan gagasan saya melalui...",
      "questionEn": "I find it easier to express my ideas through...",
      "options": ["A. Berbicara langsung secara lisan (presentasi/diskusi).", "B. Menulis atau menyampaikannya lewat teks."],  // fallback (Indonesian)
      "optionsId": ["A. Berbicara langsung secara lisan (presentasi/diskusi).", "B. Menulis atau menyampaikannya lewat teks."],
      "optionsEn": ["A. Speaking directly (presentations/discussions).", "B. Writing or conveying them through text."]
    },
    {
      "id": 8,
      "dimension": "EI",
      "question": "Gaya pertemanan yang paling menggambarkan diri Anda adalah...",  // fallback (Indonesian)
      "questionId": "Gaya pertemanan yang paling menggambarkan diri Anda adalah...",
      "questionEn": "The friendship style that best describes you is...",
      "options": ["A. Memiliki jaringan pertemanan yang sangat luas, meski tidak semuanya dekat.", "B. Memiliki lingkaran pertemanan yang sangat kecil, namun ikatannya sangat dalam."],  // fallback (Indonesian)
      "optionsId": ["A. Memiliki jaringan pertemanan yang sangat luas, meski tidak semuanya dekat.", "B. Memiliki lingkaran pertemanan yang sangat kecil, namun ikatannya sangat dalam."],
      "optionsEn": ["A. Having a very wide network of friends, even if not all are close.", "B. Having a very small circle of friends, but with very deep bonds."]
    },
    {
      "id": 9,
      "dimension": "EI",
      "question": "Dalam rapat atau diskusi kelompok, Anda biasanya...",  // fallback (Indonesian)
      "questionId": "Dalam rapat atau diskusi kelompok, Anda biasanya...",
      "questionEn": "In meetings or group discussions, you usually...",
      "options": ["A. Langsung melontarkan ide secara spontan saat itu juga.", "B. Memilih untuk mendengarkan dulu dan berbicara setelah ide matang."],  // fallback (Indonesian)
      "optionsId": ["A. Langsung melontarkan ide secara spontan saat itu juga.", "B. Memilih untuk mendengarkan dulu dan berbicara setelah ide matang."],
      "optionsEn": ["A. Spontaneously throw out ideas right away.", "B. Choose to listen first and speak after ideas are well-formed."]
    },
    {
      "id": 10,
      "dimension": "EI",
      "question": "Anda merasa jenuh atau kehilangan gairah jika...",  // fallback (Indonesian)
      "questionId": "Anda merasa jenuh atau kehilangan gairah jika...",
      "questionEn": "You feel bored or lose enthusiasm when...",
      "options": ["A. Terlalu lama menyendiri dan terisolasi dari orang lain.", "B. Terlalu lama berada di tengah keramaian dan basa-basi sosial."],  // fallback (Indonesian)
      "optionsId": ["A. Terlalu lama menyendiri dan terisolasi dari orang lain.", "B. Terlalu lama berada di tengah keramaian dan basa-basi sosial."],
      "optionsEn": ["A. Being alone and isolated from others for too long.", "B. Being in the middle of crowds and social small talk for too long."]
    },

    // ==========================================
    // DIMENSI 2: Sensing (S) vs Intuition (N)
    // Opsi A = S, Opsi B = N
    // ==========================================
    {
      "id": 11,
      "dimension": "SN",
      "question": "Saat mengerjakan proyek, pendekatan yang paling Anda sukai adalah...",  // fallback (Indonesian)
      "questionId": "Saat mengerjakan proyek, pendekatan yang paling Anda sukai adalah...",
      "questionEn": "When working on a project, your preferred approach is...",
      "options": ["A. Mengikuti langkah-langkah detail, praktis, dan terbukti berhasil.", "B. Mencoba cara baru, berinovasi, dan bereksperimen dengan ide liar."],  // fallback (Indonesian)
      "optionsId": ["A. Mengikuti langkah-langkah detail, praktis, dan terbukti berhasil.", "B. Mencoba cara baru, berinovasi, dan bereksperimen dengan ide liar."],
      "optionsEn": ["A. Following detailed, practical, and proven steps.", "B. Trying new ways, innovating, and experimenting with wild ideas."]
    },
    {
      "id": 12,
      "dimension": "SN",
      "question": "Mata dan pikiran Anda lebih mudah menangkap...",  // fallback (Indonesian)
      "questionId": "Mata dan pikiran Anda lebih mudah menangkap...",
      "questionEn": "Your eyes and mind more easily grasp...",
      "options": ["A. Fakta, angka, dan realitas yang ada tepat di depan mata.", "B. Pola tersembunyi, makna, dan kemungkinan di masa depan."],  // fallback (Indonesian)
      "optionsId": ["A. Fakta, angka, dan realitas yang ada tepat di depan mata.", "B. Pola tersembunyi, makna, dan kemungkinan di masa depan."],
      "optionsEn": ["A. Facts, figures, and reality right in front of your eyes.", "B. Hidden patterns, meanings, and future possibilities."]
    },
    {
      "id": 13,
      "dimension": "SN",
      "question": "Ketika membaca instruksi penggunaan sebuah alat baru, Anda...",  // fallback (Indonesian)
      "questionId": "Ketika membaca instruksi penggunaan sebuah alat baru, Anda...",
      "questionEn": "When reading the instructions for a new device, you...",
      "options": ["A. Membacanya secara berurutan, detail, dan langkah demi langkah.", "B. Membacanya sekilas saja untuk menangkap gambaran besarnya."],  // fallback (Indonesian)
      "optionsId": ["A. Membacanya secara berurutan, detail, dan langkah demi langkah.", "B. Membacanya sekilas saja untuk menangkap gambaran besarnya."],
      "optionsEn": ["A. Read it sequentially, in detail, step by step.", "B. Skim through it just to grasp the big picture."]
    },
    {
      "id": 14,
      "dimension": "SN",
      "question": "Anda lebih mengagumi rekan kerja atau tokoh yang...",  // fallback (Indonesian)
      "questionId": "Anda lebih mengagumi rekan kerja atau tokoh yang...",
      "questionEn": "You admire a colleague or figure who is...",
      "options": ["A. Sangat praktis, realistis, dan berpijak pada akal sehat.", "B. Sangat kreatif, visioner, dan memiliki ide-ide out of the box."],  // fallback (Indonesian)
      "optionsId": ["A. Sangat praktis, realistis, dan berpijak pada akal sehat.", "B. Sangat kreatif, visioner, dan memiliki ide-ide out of the box."],
      "optionsEn": ["A. Very practical, realistic, and grounded in common sense.", "B. Very creative, visionary, and has out-of-the-box ideas."]
    },
    {
      "id": 15,
      "dimension": "SN",
      "question": "Saat mendeskripsikan suatu kejadian kepada teman, Anda biasanya...",  // fallback (Indonesian)
      "questionId": "Saat mendeskripsikan suatu kejadian kepada teman, Anda biasanya...",
      "questionEn": "When describing an event to a friend, you usually...",
      "options": ["A. Menceritakan detail urutan kejadian dan fakta secara spesifik.", "B. Menceritakan esensi, kesimpulan, atau poin utama dari kejadian tersebut."],  // fallback (Indonesian)
      "optionsId": ["A. Menceritakan detail urutan kejadian dan fakta secara spesifik.", "B. Menceritakan esensi, kesimpulan, atau poin utama dari kejadian tersebut."],
      "optionsEn": ["A. Tell the detailed sequence of events and specific facts.", "B. Tell the essence, conclusion, or main points of the event."]
    },
    {
      "id": 16,
      "dimension": "SN",
      "question": "Topik pembicaraan yang paling menarik minat Anda adalah...",  // fallback (Indonesian)
      "questionId": "Topik pembicaraan yang paling menarik minat Anda adalah...",
      "questionEn": "The conversation topic that most interests you is...",
      "options": ["A. Hal-hal praktis, kejadian sehari-hari, pengalaman nyata, atau bisnis.", "B. Teori, filosofi, fiksi ilmiah, atau masa depan umat manusia."],  // fallback (Indonesian)
      "optionsId": ["A. Hal-hal praktis, kejadian sehari-hari, pengalaman nyata, atau bisnis.", "B. Teori, filosofi, fiksi ilmiah, atau masa depan umat manusia."],
      "optionsEn": ["A. Practical things, daily events, real experiences, or business.", "B. Theory, philosophy, science fiction, or the future of humanity."]
    },
    {
      "id": 17,
      "dimension": "SN",
      "question": "Dalam memproses informasi baru, Anda paling percaya pada...",  // fallback (Indonesian)
      "questionId": "Dalam memproses informasi baru, Anda paling percaya pada...",
      "questionEn": "When processing new information, you most trust...",
      "options": ["A. Pengalaman masa lalu dan data yang konkret.", "B. Firasat, insting, dan imajinasi Anda."],  // fallback (Indonesian)
      "optionsId": ["A. Pengalaman masa lalu dan data yang konkret.", "B. Firasat, insting, dan imajinasi Anda."],
      "optionsEn": ["A. Past experience and concrete data.", "B. Hunches, instincts, and your imagination."]
    },
    {
      "id": 18,
      "dimension": "SN",
      "question": "Menurut pandangan hidup Anda, hal yang lebih penting untuk difokuskan adalah...",  // fallback (Indonesian)
      "questionId": "Menurut pandangan hidup Anda, hal yang lebih penting untuk difokuskan adalah...",
      "questionEn": "According to your life view, the more important thing to focus on is...",
      "options": ["A. 'Apa yang sedang terjadi saat ini' (Kenyataan).", "B. 'Apa yang bisa terjadi di masa depan' (Potensi)."],  // fallback (Indonesian)
      "optionsId": ["A. 'Apa yang sedang terjadi saat ini' (Kenyataan).", "B. 'Apa yang bisa terjadi di masa depan' (Potensi)."],
      "optionsEn": ["A. 'What is happening right now' (Reality).", "B. 'What could happen in the future' (Potential)."]
    },
    {
      "id": 19,
      "dimension": "SN",
      "question": "Gaya belajar yang paling efektif bagi Anda adalah...",  // fallback (Indonesian)
      "questionId": "Gaya belajar yang paling efektif bagi Anda adalah...",
      "questionEn": "The most effective learning style for you is...",
      "options": ["A. Praktik langsung, observasi visual, dan penerapan nyata.", "B. Memahami konsep, teori, dan pemikiran abstrak."],  // fallback (Indonesian)
      "optionsId": ["A. Praktik langsung, observasi visual, dan penerapan nyata.", "B. Memahami konsep, teori, dan pemikiran abstrak."],
      "optionsEn": ["A. Hands-on practice, visual observation, and real application.", "B. Understanding concepts, theories, and abstract thinking."]
    },
    {
      "id": 20,
      "dimension": "SN",
      "question": "Pekerjaan impian Anda adalah pekerjaan yang...",  // fallback (Indonesian)
      "questionId": "Pekerjaan impian Anda adalah pekerjaan yang...",
      "questionEn": "Your dream job is one that...",
      "options": ["A. Menghasilkan produk, jasa, atau hasil yang nyata dan terukur.", "B. Melibatkan perencanaan strategis, visi masa depan, dan penciptaan hal baru."],  // fallback (Indonesian)
      "optionsId": ["A. Menghasilkan produk, jasa, atau hasil yang nyata dan terukur.", "B. Melibatkan perencanaan strategis, visi masa depan, dan penciptaan hal baru."],
      "optionsEn": ["A. Produces tangible and measurable products, services, or results.", "B. Involves strategic planning, future vision, and creating something new."]
    },

    // ==========================================
    // DIMENSI 3: Thinking (T) vs Feeling (F)
    // Opsi A = T, Opsi B = F
    // ==========================================
    {
      "id": 21,
      "dimension": "TF",
      "question": "Dalam mengambil keputusan penting dalam hidup, Anda lebih sering...",  // fallback (Indonesian)
      "questionId": "Dalam mengambil keputusan penting dalam hidup, Anda lebih sering...",
      "questionEn": "When making important life decisions, you more often...",
      "options": ["A. Mempertimbangkan logika, analisis untung-rugi, dan objektivitas.", "B. Mempertimbangkan perasaan pribadi dan dampak keputusan tersebut pada orang lain."],  // fallback (Indonesian)
      "optionsId": ["A. Mempertimbangkan logika, analisis untung-rugi, dan objektivitas.", "B. Mempertimbangkan perasaan pribadi dan dampak keputusan tersebut pada orang lain."],
      "optionsEn": ["A. Consider logic, cost-benefit analysis, and objectivity.", "B. Consider personal feelings and the impact of the decision on others."]
    },
    {
      "id": 22,
      "dimension": "TF",
      "question": "Jika terjadi perdebatan dengan rekan kerja, fokus utama Anda adalah...",  // fallback (Indonesian)
      "questionId": "Jika terjadi perdebatan dengan rekan kerja, fokus utama Anda adalah...",
      "questionEn": "If a debate arises with a colleague, your main focus is...",
      "options": ["A. Mencari siapa yang benar dan menyelesaikan masalah berdasarkan fakta.", "B. Berusaha menjaga keharmonisan dan mencegah adanya pihak yang sakit hati."],  // fallback (Indonesian)
      "optionsId": ["A. Mencari siapa yang benar dan menyelesaikan masalah berdasarkan fakta.", "B. Berusaha menjaga keharmonisan dan mencegah adanya pihak yang sakit hati."],
      "optionsEn": ["A. Finding who is right and resolving the issue based on facts.", "B. Trying to maintain harmony and prevent anyone from getting hurt."]
    },
    {
      "id": 23,
      "dimension": "TF",
      "question": "Anda akan merasa lebih dihargai jika orang lain menyebut Anda sebagai sosok yang...",  // fallback (Indonesian)
      "questionId": "Anda akan merasa lebih dihargai jika orang lain menyebut Anda sebagai sosok yang...",
      "questionEn": "You would feel more appreciated if others called you...",
      "options": ["A. Cerdas, rasional, dan kompeten.", "B. Baik hati, peduli, dan penuh empati."],  // fallback (Indonesian)
      "optionsId": ["A. Cerdas, rasional, dan kompeten.", "B. Baik hati, peduli, dan penuh empati."],
      "optionsEn": ["A. Smart, rational, and competent.", "B. Kindhearted, caring, and empathetic."]
    },
    {
      "id": 24,
      "dimension": "TF",
      "question": "Saat harus memberikan kritik kepada bawahan atau teman, Anda cenderung...",  // fallback (Indonesian)
      "questionId": "Saat harus memberikan kritik kepada bawahan atau teman, Anda cenderung...",
      "questionEn": "When having to give criticism to a subordinate or friend, you tend to...",
      "options": ["A. Langsung pada intinya (blunt) karena kejujuran adalah hal utama.", "B. Sangat berhati-hati memilih kata (sugar-coating) agar tidak menyinggung perasaannya."],  // fallback (Indonesian)
      "optionsId": ["A. Langsung pada intinya (blunt) karena kejujuran adalah hal utama.", "B. Sangat berhati-hati memilih kata (sugar-coating) agar tidak menyinggung perasaannya."],
      "optionsEn": ["A. Get straight to the point (blunt) because honesty is paramount.", "B. Be very careful with word choice (sugar-coating) to avoid hurting their feelings."]
    },
    {
      "id": 25,
      "dimension": "TF",
      "question": "Menurut Anda, sifat mana yang lebih merugikan bagi seseorang?",  // fallback (Indonesian)
      "questionId": "Menurut Anda, sifat mana yang lebih merugikan bagi seseorang?",
      "questionEn": "In your opinion, which trait is more harmful to a person?",
      "options": ["A. Terlalu emosional dan mengabaikan fakta logika.", "B. Terlalu dingin, kaku, dan tidak memiliki kepekaan sosial."],  // fallback (Indonesian)
      "optionsId": ["A. Terlalu emosional dan mengabaikan fakta logika.", "B. Terlalu dingin, kaku, dan tidak memiliki kepekaan sosial."],
      "optionsEn": ["A. Being too emotional and ignoring logical facts.", "B. Being too cold, rigid, and lacking social sensitivity."]
    },
    {
      "id": 26,
      "dimension": "TF",
      "question": "Di tempat kerja atau komunitas, aspek yang paling Anda prioritaskan adalah...",  // fallback (Indonesian)
      "questionId": "Di tempat kerja atau komunitas, aspek yang paling Anda prioritaskan adalah...",
      "questionEn": "At work or in a community, the aspect you prioritize most is...",
      "options": ["A. Efisiensi, ketegasan, dan pencapaian target.", "B. Dukungan moral, kekompakan, dan kerja sama tim yang hangat."],  // fallback (Indonesian)
      "optionsId": ["A. Efisiensi, ketegasan, dan pencapaian target.", "B. Dukungan moral, kekompakan, dan kerja sama tim yang hangat."],
      "optionsEn": ["A. Efficiency, decisiveness, and target achievement.", "B. Moral support, solidarity, and warm teamwork."]
    },
    {
      "id": 27,
      "dimension": "TF",
      "question": "Saat teman Anda curhat sambil menangis tentang masalahnya, respons spontan Anda adalah...",  // fallback (Indonesian)
      "questionId": "Saat teman Anda curhat sambil menangis tentang masalahnya, respons spontan Anda adalah...",
      "questionEn": "When a friend vents to you while crying about their problem, your spontaneous response is to...",
      "options": ["A. Menganalisa masalahnya dan memberikan solusi jalan keluar.", "B. Memberikan pelukan, dukungan emosional, dan memvalidasi perasaannya."],  // fallback (Indonesian)
      "optionsId": ["A. Menganalisa masalahnya dan memberikan solusi jalan keluar.", "B. Memberikan pelukan, dukungan emosional, dan memvalidasi perasaannya."],
      "optionsEn": ["A. Analyze their problem and provide a solution.", "B. Give them a hug, emotional support, and validate their feelings."]
    },
    {
      "id": 28,
      "dimension": "TF",
      "question": "Mengenai prinsip kebenaran dan keadilan, Anda percaya bahwa...",  // fallback (Indonesian)
      "questionId": "Mengenai prinsip kebenaran dan keadilan, Anda percaya bahwa...",
      "questionEn": "Regarding the principles of truth and justice, you believe that...",
      "options": ["A. Aturan harus berlaku sama untuk semua orang tanpa pandang bulu.", "B. Aturan harus fleksibel dan disesuaikan dengan situasi individu masing-masing."],  // fallback (Indonesian)
      "optionsId": ["A. Aturan harus berlaku sama untuk semua orang tanpa pandang bulu.", "B. Aturan harus fleksibel dan disesuaikan dengan situasi individu masing-masing."],
      "optionsEn": ["A. Rules should apply equally to everyone without exception.", "B. Rules should be flexible and adapted to each individual's situation."]
    },
    {
      "id": 29,
      "dimension": "TF",
      "question": "Anda lebih bangga pada diri sendiri ketika Anda berhasil...",  // fallback (Indonesian)
      "questionId": "Anda lebih bangga pada diri sendiri ketika Anda berhasil...",
      "questionEn": "You are proudest of yourself when you manage to...",
      "options": ["A. Menguasai emosi Anda dan tetap rasional dalam krisis.", "B. Menunjukkan belas kasih dan membantu orang lain melewati masa sulit."],  // fallback (Indonesian)
      "optionsId": ["A. Menguasai emosi Anda dan tetap rasional dalam krisis.", "B. Menunjukkan belas kasih dan membantu orang lain melewati masa sulit."],
      "optionsEn": ["A. Master your emotions and stay rational in a crisis.", "B. Show compassion and help others through difficult times."]
    },
    {
      "id": 30,
      "dimension": "TF",
      "question": "Gaya kepemimpinan ideal yang ingin Anda terapkan adalah...",  // fallback (Indonesian)
      "questionId": "Gaya kepemimpinan ideal yang ingin Anda terapkan adalah...",
      "questionEn": "The ideal leadership style you want to apply is...",
      "options": ["A. Objektif, berbasis data, profesional, dan tegas.", "B. Mengayomi, penuh pengertian, suportif, dan inspiratif."],  // fallback (Indonesian)
      "optionsId": ["A. Objektif, berbasis data, profesional, dan tegas.", "B. Mengayomi, penuh pengertian, suportif, dan inspiratif."],
      "optionsEn": ["A. Objective, data-driven, professional, and decisive.", "B. Nurturing, understanding, supportive, and inspiring."]
    },

    // ==========================================
    // DIMENSI 4: Judging (J) vs Perceiving (P)
    // Opsi A = J, Opsi B = P
    // ==========================================
    {
      "id": 31,
      "dimension": "JP",
      "question": "Saat merencanakan liburan panjang, Anda biasanya...",  // fallback (Indonesian)
      "questionId": "Saat merencanakan liburan panjang, Anda biasanya...",
      "questionEn": "When planning a long vacation, you usually...",
      "options": ["A. Membuat jadwal yang rinci (itinerary), memesan tiket, dan merencanakan jauh hari.", "B. Bersikap spontan, pergi ke mana angin membawa, dan menyesuaikan diri di lokasi."],  // fallback (Indonesian)
      "optionsId": ["A. Membuat jadwal yang rinci (itinerary), memesan tiket, dan merencanakan jauh hari.", "B. Bersikap spontan, pergi ke mana angin membawa, dan menyesuaikan diri di lokasi."],
      "optionsEn": ["A. Make a detailed itinerary, book tickets, and plan well in advance.", "B. Be spontaneous, go wherever the wind takes you, and adapt on location."]
    },
    {
      "id": 32,
      "dimension": "JP",
      "question": "Kondisi meja kerja, kamar, atau ruang tamu Anda cenderung...",  // fallback (Indonesian)
      "questionId": "Kondisi meja kerja, kamar, atau ruang tamu Anda cenderung...",
      "questionEn": "The state of your desk, room, or living room tends to be...",
      "options": ["A. Sangat rapi, terorganisir, dan semua barang kembali ke tempatnya.", "B. Cukup berantakan, namun Anda tahu persis di mana letak barang yang Anda butuhkan."],  // fallback (Indonesian)
      "optionsId": ["A. Sangat rapi, terorganisir, dan semua barang kembali ke tempatnya.", "B. Cukup berantakan, namun Anda tahu persis di mana letak barang yang Anda butuhkan."],
      "optionsEn": ["A. Very neat, organized, and everything returns to its place.", "B. Somewhat messy, but you know exactly where everything you need is."]
    },
    {
      "id": 33,
      "dimension": "JP",
      "question": "Terhadap komitmen dan tenggat waktu (deadline), kebiasaan Anda adalah...",  // fallback (Indonesian)
      "questionId": "Terhadap komitmen dan tenggat waktu (deadline), kebiasaan Anda adalah...",
      "questionEn": "Regarding commitments and deadlines, your habit is to...",
      "options": ["A. Sangat disiplin dan berusaha menyelesaikannya jauh sebelum waktu habis.", "B. Sering menunda dan baru mendapatkan motivasi tinggi saat mendekati menit terakhir."],  // fallback (Indonesian)
      "optionsId": ["A. Sangat disiplin dan berusaha menyelesaikannya jauh sebelum waktu habis.", "B. Sering menunda dan baru mendapatkan motivasi tinggi saat mendekati menit terakhir."],
      "optionsEn": ["A. Be very disciplined and try to finish well before the deadline.", "B. Often procrastinate and only get highly motivated near the last minute."]
    },
    {
      "id": 34,
      "dimension": "JP",
      "question": "Secara psikologis, Anda merasa lebih tenang dan nyaman jika...",  // fallback (Indonesian)
      "questionId": "Secara psikologis, Anda merasa lebih tenang dan nyaman jika...",
      "questionEn": "Psychologically, you feel calmer and more comfortable when...",
      "options": ["A. Semua rencana dan keputusan sudah ditetapkan dengan jelas.", "B. Segala sesuatunya masih terbuka dan Anda memiliki banyak pilihan/opsi."],  // fallback (Indonesian)
      "optionsId": ["A. Semua rencana dan keputusan sudah ditetapkan dengan jelas.", "B. Segala sesuatunya masih terbuka dan Anda memiliki banyak pilihan/opsi."],
      "optionsEn": ["A. All plans and decisions are clearly established.", "B. Everything is still open and you have many options."]
    },
    {
      "id": 35,
      "dimension": "JP",
      "question": "Gaya ritme kerja Anda lebih mengarah pada...",  // fallback (Indonesian)
      "questionId": "Gaya ritme kerja Anda lebih mengarah pada...",
      "questionEn": "Your work rhythm style leans more toward...",
      "options": ["A. Bekerja dengan langkah yang stabil, rutin, dicicil, dan terjadwal.", "B. Bekerja dengan ledakan energi yang tiba-tiba saat Anda sedang terinspirasi."],  // fallback (Indonesian)
      "optionsId": ["A. Bekerja dengan langkah yang stabil, rutin, dicicil, dan terjadwal.", "B. Bekerja dengan ledakan energi yang tiba-tiba saat Anda sedang terinspirasi."],
      "optionsEn": ["A. Working at a steady, routine, incremental, and scheduled pace.", "B. Working in sudden bursts of energy when you feel inspired."]
    },
    {
      "id": 36,
      "dimension": "JP",
      "question": "Anda lebih menyukai gaya hidup yang...",  // fallback (Indonesian)
      "questionId": "Anda lebih menyukai gaya hidup yang...",
      "questionEn": "You prefer a lifestyle that is...",
      "options": ["A. Teratur, terprediksi, dan penuh dengan kepastian.", "B. Fleksibel, adaptif, dan penuh dengan kejutan spontan."],  // fallback (Indonesian)
      "optionsId": ["A. Teratur, terprediksi, dan penuh dengan kepastian.", "B. Fleksibel, adaptif, dan penuh dengan kejutan spontan."],
      "optionsEn": ["A. Orderly, predictable, and full of certainty.", "B. Flexible, adaptive, and full of spontaneous surprises."]
    },
    {
      "id": 37,
      "dimension": "JP",
      "question": "Sebelum memulai tugas atau proyek besar, hal pertama yang Anda lakukan adalah...",  // fallback (Indonesian)
      "questionId": "Sebelum memulai tugas atau proyek besar, hal pertama yang Anda lakukan adalah...",
      "questionEn": "Before starting a big task or project, the first thing you do is...",
      "options": ["A. Membuat daftar tugas (to-do list) dan struktur rencana yang detail.", "B. Langsung terjun mengerjakannya dan mengalir menyesuaikan diri di tengah jalan."],  // fallback (Indonesian)
      "optionsId": ["A. Membuat daftar tugas (to-do list) dan struktur rencana yang detail.", "B. Langsung terjun mengerjakannya dan mengalir menyesuaikan diri di tengah jalan."],
      "optionsEn": ["A. Make a to-do list and a detailed plan structure.", "B. Dive right in and go with the flow along the way."]
    },
    {
      "id": 38,
      "dimension": "JP",
      "question": "Jika terjadi perubahan jadwal yang mendadak, Anda akan...",  // fallback (Indonesian)
      "questionId": "Jika terjadi perubahan jadwal yang mendadak, Anda akan...",
      "questionEn": "If a sudden schedule change occurs, you will...",
      "options": ["A. Merasa stres, kesal, dan terganggu karena rencana awal berantakan.", "B. Merasa biasa saja, tertantang, dan mudah beralih ke rencana cadangan."],  // fallback (Indonesian)
      "optionsId": ["A. Merasa stres, kesal, dan terganggu karena rencana awal berantakan.", "B. Merasa biasa saja, tertantang, dan mudah beralih ke rencana cadangan."],
      "optionsEn": ["A. Feel stressed, upset, and disturbed because the original plan is ruined.", "B. Feel fine about it, challenged, and easily switch to a backup plan."]
    },
    {
      "id": 39,
      "dimension": "JP",
      "question": "Dalam menjalani pekerjaan, fokus utama orientasi Anda adalah...",  // fallback (Indonesian)
      "questionId": "Dalam menjalani pekerjaan, fokus utama orientasi Anda adalah...",
      "questionEn": "In your work, your main focus of orientation is...",
      "options": ["A. Berorientasi pada HASIL (Ingin cepat selesai dengan sempurna).", "B. Berorientasi pada PROSES (Ingin menikmati perjalanan dan eksplorasi saat bekerja)."],  // fallback (Indonesian)
      "optionsId": ["A. Berorientasi pada HASIL (Ingin cepat selesai dengan sempurna).", "B. Berorientasi pada PROSES (Ingin menikmati perjalanan dan eksplorasi saat bekerja)."],
      "optionsEn": ["A. Result-oriented (Want it done quickly and perfectly).", "B. Process-oriented (Want to enjoy the journey and exploration while working)."]
    },
    {
      "id": 40,
      "dimension": "JP",
      "question": "Orang lain lebih sering menggambarkan Anda sebagai sosok yang...",  // fallback (Indonesian)
      "questionId": "Orang lain lebih sering menggambarkan Anda sebagai sosok yang...",
      "questionEn": "Others most often describe you as someone...",
      "options": ["A. Disiplin, terencana, teguh pendirian, dan bisa diandalkan.", "B. Santai, fleksibel, berpikiran terbuka, dan penuh kejutan."],  // fallback (Indonesian)
      "optionsId": ["A. Disiplin, terencana, teguh pendirian, dan bisa diandalkan.", "B. Santai, fleksibel, berpikiran terbuka, dan penuh kejutan."],
      "optionsEn": ["A. Disciplined, planned, firm, and reliable.", "B. Relaxed, flexible, open-minded, and full of surprises."]
    },

    // ==========================================
    // TAMBAHAN 50 SOAL - DIMENSI EI (Ekstrovert vs Introvert)
    // ==========================================
    {
      "id": 41,
      "dimension": "EI",
      "question": "Di akhir pekan, Anda merasa energi mental Anda lebih terisi ulang jika...",  // fallback (Indonesian)
      "questionId": "Di akhir pekan, Anda merasa energi mental Anda lebih terisi ulang jika...",
      "questionEn": "On weekends, you feel your mental energy is more recharged when...",
      "options": ["A. Jalan-jalan, nongkrong, atau pergi ke tempat ramai.", "B. Tinggal di rumah, bersantai, atau melakukan me-time dalam ketenangan."],  // fallback (Indonesian)
      "optionsId": ["A. Jalan-jalan, nongkrong, atau pergi ke tempat ramai.", "B. Tinggal di rumah, bersantai, atau melakukan me-time dalam ketenangan."],
      "optionsEn": ["A. Going out, hanging out, or going to crowded places.", "B. Staying at home, relaxing, or having me-time in peace."]
    },
    {
      "id": 42,
      "dimension": "EI",
      "question": "Dalam merespons pesan teks di grup obrolan (grup WhatsApp) yang ramai, Anda biasanya...",  // fallback (Indonesian)
      "questionId": "Dalam merespons pesan teks di grup obrolan (grup WhatsApp) yang ramai, Anda biasanya...",
      "questionEn": "When responding to messages in a busy chat group (WhatsApp group), you usually...",
      "options": ["A. Sangat aktif membalas, menanggapi, dan meramaikan suasana.", "B. Lebih sering menjadi pengamat (silent reader) dan hanya membalas sesekali."],  // fallback (Indonesian)
      "optionsId": ["A. Sangat aktif membalas, menanggapi, dan meramaikan suasana.", "B. Lebih sering menjadi pengamat (silent reader) dan hanya membalas sesekali."],
      "optionsEn": ["A. Be very active replying, responding, and livening up the atmosphere.", "B. More often be an observer (silent reader) and only reply occasionally."]
    },
    {
      "id": 43,
      "dimension": "EI",
      "question": "Saat Anda tiba-tiba mendapat ide yang brilian, insting pertama Anda adalah...",  // fallback (Indonesian)
      "questionId": "Saat Anda tiba-tiba mendapat ide yang brilian, insting pertama Anda adalah...",
      "questionEn": "When you suddenly get a brilliant idea, your first instinct is to...",
      "options": ["A. Langsung menceritakannya kepada orang lain untuk didiskusikan.", "B. Menyimpannya dulu dan mengembangkannya sendiri di dalam kepala."],  // fallback (Indonesian)
      "optionsId": ["A. Langsung menceritakannya kepada orang lain untuk didiskusikan.", "B. Menyimpannya dulu dan mengembangkannya sendiri di dalam kepala."],
      "optionsEn": ["A. Immediately share it with others to discuss.", "B. Keep it to yourself first and develop it in your head."]
    },
    {
      "id": 44,
      "dimension": "EI",
      "question": "Di sebuah acara networking atau kumpul keluarga besar, Anda cenderung...",  // fallback (Indonesian)
      "questionId": "Di sebuah acara networking atau kumpul keluarga besar, Anda cenderung...",
      "questionEn": "At a networking event or large family gathering, you tend to...",
      "options": ["A. Berkeliling mendatangi orang-orang untuk mengobrol dan berkenalan.", "B. Menunggu di satu tempat dan membiarkan orang lain yang menyapa duluan."],  // fallback (Indonesian)
      "optionsId": ["A. Berkeliling mendatangi orang-orang untuk mengobrol dan berkenalan.", "B. Menunggu di satu tempat dan membiarkan orang lain yang menyapa duluan."],
      "optionsEn": ["A. Walk around approaching people to chat and get acquainted.", "B. Wait in one spot and let others approach you first."]
    },
    {
      "id": 45,
      "dimension": "EI",
      "question": "Seberapa banyak teman yang benar-benar mengetahui rahasia dan isi hati terdalam Anda?",  // fallback (Indonesian)
      "questionId": "Seberapa banyak teman yang benar-benar mengetahui rahasia dan isi hati terdalam Anda?",
      "questionEn": "How many friends truly know your deepest secrets and inner feelings?",
      "options": ["A. Cukup banyak, saya adalah orang yang terbuka dan ekspresif.", "B. Sangat sedikit, mungkin hanya satu atau dua orang yang paling saya percayai."],  // fallback (Indonesian)
      "optionsId": ["A. Cukup banyak, saya adalah orang yang terbuka dan ekspresif.", "B. Sangat sedikit, mungkin hanya satu atau dua orang yang paling saya percayai."],
      "optionsEn": ["A. Quite many, I am an open and expressive person.", "B. Very few, maybe only one or two people I trust the most."]
    },
    {
      "id": 46,
      "dimension": "EI",
      "question": "Jika Anda diharuskan bekerja dari rumah (WFH) selama sebulan penuh tanpa bertemu rekan kerja, Anda akan merasa...",  // fallback (Indonesian)
      "questionId": "Jika Anda diharuskan bekerja dari rumah (WFH) selama sebulan penuh tanpa bertemu rekan kerja, Anda akan merasa...",
      "questionEn": "If you had to work from home (WFH) for a full month without meeting colleagues, you would feel...",
      "options": ["A. Merasa jenuh, kesepian, dan butuh interaksi tatap muka.", "B. Merasa sangat damai, fokus, dan produktivitas justru meningkat."],  // fallback (Indonesian)
      "optionsId": ["A. Merasa jenuh, kesepian, dan butuh interaksi tatap muka.", "B. Merasa sangat damai, fokus, dan produktivitas justru meningkat."],
      "optionsEn": ["A. Bored, lonely, and in need of face-to-face interaction.", "B. Very peaceful, focused, and even more productive."]
    },
    {
      "id": 47,
      "dimension": "EI",
      "question": "Ketika sedang mengalami masalah berat, hal yang paling Anda butuhkan adalah...",  // fallback (Indonesian)
      "questionId": "Ketika sedang mengalami masalah berat, hal yang paling Anda butuhkan adalah...",
      "questionEn": "When experiencing a heavy problem, what you need most is...",
      "options": ["A. Teman curhat untuk mendengarkan dan melepaskan beban perasaan.", "B. Ruang dan waktu untuk menyendiri guna menenangkan pikiran."],  // fallback (Indonesian)
      "optionsId": ["A. Teman curhat untuk mendengarkan dan melepaskan beban perasaan.", "B. Ruang dan waktu untuk menyendiri guna menenangkan pikiran."],
      "optionsEn": ["A. A friend to confide in to listen and release emotional burden.", "B. Space and time alone to calm your mind."]
    },
    {
      "id": 48,
      "dimension": "EI",
      "question": "Orang yang baru mengenal Anda biasanya mendeskripsikan Anda sebagai sosok yang...",  // fallback (Indonesian)
      "questionId": "Orang yang baru mengenal Anda biasanya mendeskripsikan Anda sebagai sosok yang...",
      "questionEn": "People who just met you usually describe you as someone...",
      "options": ["A. Cepat akrab, supel, dan mudah ditebak suasana hatinya.", "B. Membutuhkan waktu untuk 'panas' dan sulit ditebak di awal pertemuan."],  // fallback (Indonesian)
      "optionsId": ["A. Cepat akrab, supel, dan mudah ditebak suasana hatinya.", "B. Membutuhkan waktu untuk 'panas' dan sulit ditebak di awal pertemuan."],
      "optionsEn": ["A. Quick to warm up, sociable, and easy to read mood-wise.", "B. Needs time to warm up and hard to read at first meeting."]
    },
    {
      "id": 49,
      "dimension": "EI",
      "question": "Saat sedang berkonsentrasi penuh lalu ada teman yang mengajak mengobrol santai, Anda...",  // fallback (Indonesian)
      "questionId": "Saat sedang berkonsentrasi penuh lalu ada teman yang mengajak mengobrol santai, Anda...",
      "questionEn": "When fully concentrated and a friend starts a casual chat, you...",
      "options": ["A. Menyambut obrolan itu dengan senang hati sebagai jeda istirahat.", "B. Merasa fokusnya sangat terganggu dan butuh waktu lama untuk kembali konsentrasi."],  // fallback (Indonesian)
      "optionsId": ["A. Menyambut obrolan itu dengan senang hati sebagai jeda istirahat.", "B. Merasa fokusnya sangat terganggu dan butuh waktu lama untuk kembali konsentrasi."],
      "optionsEn": ["A. Welcome the conversation gladly as a break.", "B. Feel your focus is very disturbed and need a long time to regain concentration."]
    },
    {
      "id": 50,
      "dimension": "EI",
      "question": "Di waktu luang sehabis bekerja, kegiatan favorit Anda lebih mengarah pada...",  // fallback (Indonesian)
      "questionId": "Di waktu luang sehabis bekerja, kegiatan favorit Anda lebih mengarah pada...",
      "questionEn": "In your free time after work, your favorite activities lean more toward...",
      "options": ["A. Mengikuti kegiatan komunitas, olahraga bersama, atau nongkrong.", "B. Membaca buku, menonton film sendirian, atau bermain game di kamar."],  // fallback (Indonesian)
      "optionsId": ["A. Mengikuti kegiatan komunitas, olahraga bersama, atau nongkrong.", "B. Membaca buku, menonton film sendirian, atau bermain game di kamar."],
      "optionsEn": ["A. Joining community activities, exercising together, or hanging out.", "B. Reading books, watching movies alone, or playing games in your room."]
    },
    {
      "id": 51,
      "dimension": "EI",
      "question": "Ketika mendapat berita kelulusan atau promosi jabatan, respons pertama Anda adalah...",  // fallback (Indonesian)
      "questionId": "Ketika mendapat berita kelulusan atau promosi jabatan, respons pertama Anda adalah...",
      "questionEn": "When receiving news of passing an exam or job promotion, your first response is to...",
      "options": ["A. Segera menelepon atau mengabari semua orang terdekat.", "B. Tersenyum sendiri, meresapinya dalam hati sebelum memberitahu orang lain."],  // fallback (Indonesian)
      "optionsId": ["A. Segera menelepon atau mengabari semua orang terdekat.", "B. Tersenyum sendiri, meresapinya dalam hati sebelum memberitahu orang lain."],
      "optionsEn": ["A. Immediately call or notify all your closest people.", "B. Smile to yourself, absorb it internally before telling others."]
    },
    {
      "id": 52,
      "dimension": "EI",
      "question": "Secara psikologis, Anda merasa jauh lebih lelah atau terkuras energinya saat...",  // fallback (Indonesian)
      "questionId": "Secara psikologis, Anda merasa jauh lebih lelah atau terkuras energinya saat...",
      "questionEn": "Psychologically, you feel much more tired or drained when...",
      "options": ["A. Tidak ada aktivitas atau interaksi sosial sama sekali seharian.", "B. Berada di tengah acara keramaian dari pagi sampai malam."],  // fallback (Indonesian)
      "optionsId": ["A. Tidak ada aktivitas atau interaksi sosial sama sekali seharian.", "B. Berada di tengah acara keramaian dari pagi sampai malam."],
      "optionsEn": ["A. There is no activity or social interaction at all for the whole day.", "B. Being in the middle of crowded events from morning to night."]
    },

    // ==========================================
    // TAMBAHAN 50 SOAL - DIMENSI SN (Sensing vs Intuition)
    // ==========================================
    {
      "id": 53,
      "dimension": "SN",
      "question": "Saat mendengarkan sebuah presentasi proyek bisnis, Anda lebih mudah fokus pada...",  // fallback (Indonesian)
      "questionId": "Saat mendengarkan sebuah presentasi proyek bisnis, Anda lebih mudah fokus pada...",
      "questionEn": "When listening to a business project presentation, you more easily focus on...",
      "options": ["A. Data statistik, fakta nyata, dan langkah-langkah implementasinya.", "B. Konsep utama, inovasi ke depan, dan visi besar di balik proyek tersebut."],  // fallback (Indonesian)
      "optionsId": ["A. Data statistik, fakta nyata, dan langkah-langkah implementasinya.", "B. Konsep utama, inovasi ke depan, dan visi besar di balik proyek tersebut."],
      "optionsEn": ["A. Statistical data, real facts, and implementation steps.", "B. The main concept, future innovation, and big vision behind the project."]
    },
    {
      "id": 54,
      "dimension": "SN",
      "question": "Ketika dituntut mempelajari software atau keahlian baru, Anda lebih suka...",  // fallback (Indonesian)
      "questionId": "Ketika dituntut mempelajari software atau keahlian baru, Anda lebih suka...",
      "questionEn": "When required to learn a new software or skill, you prefer to...",
      "options": ["A. Diberikan contoh kasus nyata lalu mempraktikkannya setahap demi setahap.", "B. Diberikan kebebasan untuk mengutak-atik konsep dan teorinya sendiri."],  // fallback (Indonesian)
      "optionsId": ["A. Diberikan contoh kasus nyata lalu mempraktikkannya setahap demi setahap.", "B. Diberikan kebebasan untuk mengutak-atik konsep dan teorinya sendiri."],
      "optionsEn": ["A. Be given real case examples and practice step by step.", "B. Be given freedom to tinker with the concepts and theories yourself."]
    },
    {
      "id": 55,
      "dimension": "SN",
      "question": "Dalam mengingat sebuah peristiwa penting di masa lalu, Anda biasanya...",  // fallback (Indonesian)
      "questionId": "Dalam mengingat sebuah peristiwa penting di masa lalu, Anda biasanya...",
      "questionEn": "When remembering an important past event, you usually...",
      "options": ["A. Mengingat detail dengan jelas (siapa berbicara apa, baju apa yang dipakai).", "B. Mengingat esensi, kesan umum, atau atmosfer dari kejadian tersebut."],  // fallback (Indonesian)
      "optionsId": ["A. Mengingat detail dengan jelas (siapa berbicara apa, baju apa yang dipakai).", "B. Mengingat esensi, kesan umum, atau atmosfer dari kejadian tersebut."],
      "optionsEn": ["A. Remember details clearly (who said what, what clothes were worn).", "B. Remember the essence, general impression, or atmosphere of the event."]
    },
    {
      "id": 56,
      "dimension": "SN",
      "question": "Anda cenderung lebih mengagumi dan terinspirasi oleh tokoh yang...",  // fallback (Indonesian)
      "questionId": "Anda cenderung lebih mengagumi dan terinspirasi oleh tokoh yang...",
      "questionEn": "You tend to admire and be inspired by figures who are...",
      "options": ["A. Memiliki akal sehat yang kuat, realistis, dan pekerja keras.", "B. Memiliki imajinasi liar, visioner, dan selalu berpikir di luar kebiasaan."],  // fallback (Indonesian)
      "optionsId": ["A. Memiliki akal sehat yang kuat, realistis, dan pekerja keras.", "B. Memiliki imajinasi liar, visioner, dan selalu berpikir di luar kebiasaan."],
      "optionsEn": ["A. Strong in common sense, realistic, and hardworking.", "B. Wildly imaginative, visionary, and always thinking outside the box."]
    },
    {
      "id": 57,
      "dimension": "SN",
      "question": "Saat memilih atau merancang sebuah rumah, prioritas utama Anda adalah...",  // fallback (Indonesian)
      "questionId": "Saat memilih atau merancang sebuah rumah, prioritas utama Anda adalah...",
      "questionEn": "When choosing or designing a house, your main priority is...",
      "options": ["A. Fungsionalitas ruangan, tata letak barang, dan kualitas material bangunan.", "B. Tema arsitektur, makna estetika, dan potensi desain rumah tersebut ke depannya."],  // fallback (Indonesian)
      "optionsId": ["A. Fungsionalitas ruangan, tata letak barang, dan kualitas material bangunan.", "B. Tema arsitektur, makna estetika, dan potensi desain rumah tersebut ke depannya."],
      "optionsEn": ["A. Room functionality, item layout, and building material quality.", "B. Architectural theme, aesthetic meaning, and the house's future design potential."]
    },
    {
      "id": 58,
      "dimension": "SN",
      "question": "Kata-kata yang lebih tepat menggambarkan pola pikir Anda sehari-hari adalah...",  // fallback (Indonesian)
      "questionId": "Kata-kata yang lebih tepat menggambarkan pola pikir Anda sehari-hari adalah...",
      "questionEn": "The words that best describe your everyday thinking pattern are...",
      "options": ["A. Praktis, logis secara berurutan, dan mengakar pada realitas.", "B. Konseptual, abstrak, dan penuh dengan ide-ide acak yang saling terhubung."],  // fallback (Indonesian)
      "optionsId": ["A. Praktis, logis secara berurutan, dan mengakar pada realitas.", "B. Konseptual, abstrak, dan penuh dengan ide-ide acak yang saling terhubung."],
      "optionsEn": ["A. Practical, sequentially logical, and rooted in reality.", "B. Conceptual, abstract, and full of random interconnected ideas."]
    },
    {
      "id": 59,
      "dimension": "SN",
      "question": "Jika Anda menonton film fiksi ilmiah (sci-fi), Anda sering...",  // fallback (Indonesian)
      "questionId": "Jika Anda menonton film fiksi ilmiah (sci-fi), Anda sering...",
      "questionEn": "When watching a sci-fi film, you often...",
      "options": ["A. Merasa aneh jika ada adegan yang tidak masuk akal atau melanggar hukum fisika.", "B. Sangat menikmati dan tenggelam dalam konsep dunia imajinatif tersebut."],  // fallback (Indonesian)
      "optionsId": ["A. Merasa aneh jika ada adegan yang tidak masuk akal atau melanggar hukum fisika.", "B. Sangat menikmati dan tenggelam dalam konsep dunia imajinatif tersebut."],
      "optionsEn": ["A. Feel weirded out if there are scenes that don't make sense or violate physics laws.", "B. Greatly enjoy and immerse yourself in the imaginative world concept."]
    },
    {
      "id": 60,
      "dimension": "SN",
      "question": "Hal yang paling membuat Anda frustrasi dan mandek saat bekerja adalah...",  // fallback (Indonesian)
      "questionId": "Hal yang paling membuat Anda frustrasi dan mandek saat bekerja adalah...",
      "questionEn": "The thing that frustrates and stalls you most at work is...",
      "options": ["A. Tidak adanya pedoman instruksi yang jelas dan detail dari atasan.", "B. Terlalu banyak prosedur kaku yang melarang Anda berkreasi."],  // fallback (Indonesian)
      "optionsId": ["A. Tidak adanya pedoman instruksi yang jelas dan detail dari atasan.", "B. Terlalu banyak prosedur kaku yang melarang Anda berkreasi."],
      "optionsEn": ["A. Lack of clear and detailed instructions from your boss.", "B. Too many rigid procedures that prohibit your creativity."]
    },
    {
      "id": 61,
      "dimension": "SN",
      "question": "Dalam mengambil kesimpulan atas sebuah isu, Anda paling percaya pada...",  // fallback (Indonesian)
      "questionId": "Dalam mengambil kesimpulan atas sebuah isu, Anda paling percaya pada...",
      "questionEn": "When drawing a conclusion about an issue, you most trust...",
      "options": ["A. Apa yang bisa Anda lihat, dengar, dan buktikan dengan mata kepala sendiri.", "B. Firasat kuat (gut feeling) atau intuisi yang muncul begitu saja dari dalam hati."],  // fallback (Indonesian)
      "optionsId": ["A. Apa yang bisa Anda lihat, dengar, dan buktikan dengan mata kepala sendiri.", "B. Firasat kuat (gut feeling) atau intuisi yang muncul begitu saja dari dalam hati."],
      "optionsEn": ["A. What you can see, hear, and prove with your own eyes.", "B. A strong gut feeling or intuition that arises from within."]
    },
    {
      "id": 62,
      "dimension": "SN",
      "question": "Di tongkrongan, Anda lebih mendominasi obrolan jika topiknya mengenai...",  // fallback (Indonesian)
      "questionId": "Di tongkrongan, Anda lebih mendominasi obrolan jika topiknya mengenai...",
      "questionEn": "At hangouts, you dominate the conversation more if the topic is about...",
      "options": ["A. Hal-hal yang sedang terjadi sekarang, tren terbaru, atau pengalaman konkret.", "B. Konsep filosofi hidup, misteri alam semesta, atau inovasi di masa depan."],  // fallback (Indonesian)
      "optionsId": ["A. Hal-hal yang sedang terjadi sekarang, tren terbaru, atau pengalaman konkret.", "B. Konsep filosofi hidup, misteri alam semesta, atau inovasi di masa depan."],
      "optionsEn": ["A. Current events, latest trends, or concrete experiences.", "B. Life philosophy concepts, universe mysteries, or future innovations."]
    },
    {
      "id": 63,
      "dimension": "SN",
      "question": "Saat membaca berita viral, bagian yang lebih menarik minat Anda adalah...",  // fallback (Indonesian)
      "questionId": "Saat membaca berita viral, bagian yang lebih menarik minat Anda adalah...",
      "questionEn": "When reading viral news, the part that interests you more is...",
      "options": ["A. Kronologi kejadian fakta di lapangan secara runtut.", "B. Analisis tentang apa dampak panjang dari kejadian tersebut bagi masyarakat."],  // fallback (Indonesian)
      "optionsId": ["A. Kronologi kejadian fakta di lapangan secara runtut.", "B. Analisis tentang apa dampak panjang dari kejadian tersebut bagi masyarakat."],
      "optionsEn": ["A. The chronological sequence of facts on the ground.", "B. Analysis of the long-term impact of the event on society."]
    },
    {
      "id": 64,
      "dimension": "SN",
      "question": "Saat memasak makanan di dapur, Anda biasanya...",  // fallback (Indonesian)
      "questionId": "Saat memasak makanan di dapur, Anda biasanya...",
      "questionEn": "When cooking in the kitchen, you usually...",
      "options": ["A. Mengikuti resep takaran gram dan sendok teh dengan sangat patuh.", "B. Mengira-ngira bumbu (feeling) dan berani bereksperimen dengan rasa baru."],  // fallback (Indonesian)
      "optionsId": ["A. Mengikuti resep takaran gram dan sendok teh dengan sangat patuh.", "B. Mengira-ngira bumbu (feeling) dan berani bereksperimen dengan rasa baru."],
      "optionsEn": ["A. Follow the recipe's gram and teaspoon measurements very obediently.", "B. Estimate spices by feel and dare to experiment with new flavors."]
    },
    {
      "id": 65,
      "dimension": "SN",
      "question": "Anda lebih suka jika orang lain memandang Anda sebagai individu yang...",  // fallback (Indonesian)
      "questionId": "Anda lebih suka jika orang lain memandang Anda sebagai individu yang...",
      "questionEn": "You prefer if others see you as an individual who is...",
      "options": ["A. Sangat praktis, membumi, dan tahu cara menyelesaikan masalah di lapangan.", "B. Sangat kreatif, orisinal, dan memiliki pandangan yang unik tentang dunia."],  // fallback (Indonesian)
      "optionsId": ["A. Sangat praktis, membumi, dan tahu cara menyelesaikan masalah di lapangan.", "B. Sangat kreatif, orisinal, dan memiliki pandangan yang unik tentang dunia."],
      "optionsEn": ["A. Very practical, down-to-earth, and knows how to solve problems on the ground.", "B. Very creative, original, and has a unique view of the world."]
    },

    // ==========================================
    // TAMBAHAN 50 SOAL - DIMENSI TF (Thinking vs Feeling)
    // ==========================================
    {
      "id": 66,
      "dimension": "TF",
      "question": "Jika Anda seorang HRD dan harus memutuskan pemecatan karyawan, Anda mendasarkannya pada...",  // fallback (Indonesian)
      "questionId": "Jika Anda seorang HRD dan harus memutuskan pemecatan karyawan, Anda mendasarkannya pada...",
      "questionEn": "If you were an HR manager and had to decide on firing an employee, you would base it on...",
      "options": ["A. Analisis data KPI, efisiensi kerja, dan objektivitas murni.", "B. Kondisi kehidupan pribadi karyawan tersebut dan dampak psikologis bagi tim."],  // fallback (Indonesian)
      "optionsId": ["A. Analisis data KPI, efisiensi kerja, dan objektivitas murni.", "B. Kondisi kehidupan pribadi karyawan tersebut dan dampak psikologis bagi tim."],
      "optionsEn": ["A. KPI data analysis, work efficiency, and pure objectivity.", "B. The employee's personal life situation and psychological impact on the team."]
    },
    {
      "id": 67,
      "dimension": "TF",
      "question": "Saat memberikan saran, Anda lebih sering memulainya dengan kalimat...",  // fallback (Indonesian)
      "questionId": "Saat memberikan saran, Anda lebih sering memulainya dengan kalimat...",
      "questionEn": "When giving advice, you more often start with the phrase...",
      "options": ["A. 'Menurut logika saya...'", "B. 'Menurut perasaan saya...'"],  // fallback (Indonesian)
      "optionsId": ["A. 'Menurut logika saya...'", "B. 'Menurut perasaan saya...'"],
      "optionsEn": ["A. 'According to my logic...'", "B. 'According to my feelings...'"]
    },
    {
      "id": 68,
      "dimension": "TF",
      "question": "Ketika ada rekan yang menangis karena tertimpa musibah, mereka tahu Anda akan...",  // fallback (Indonesian)
      "questionId": "Ketika ada rekan yang menangis karena tertimpa musibah, mereka tahu Anda akan...",
      "questionEn": "When a colleague cries because of a misfortune, they know you will...",
      "options": ["A. Membantu mencari akar masalahnya dan memberikan solusi praktis.", "B. Memberikan pelukan, empati, dan memvalidasi perasaan sedih mereka."],  // fallback (Indonesian)
      "optionsId": ["A. Membantu mencari akar masalahnya dan memberikan solusi praktis.", "B. Memberikan pelukan, empati, dan memvalidasi perasaan sedih mereka."],
      "optionsEn": ["A. Help find the root of the problem and provide practical solutions.", "B. Give them a hug, empathy, and validate their sadness."]
    },
    {
      "id": 69,
      "dimension": "TF",
      "question": "Dalam sebuah perdebatan panas, Anda paling benci dengan argumentasi yang...",  // fallback (Indonesian)
      "questionId": "Dalam sebuah perdebatan panas, Anda paling benci dengan argumentasi yang...",
      "questionEn": "In a heated debate, you most hate arguments that are...",
      "options": ["A. Terlalu mendramatisir perasaan dan mengabaikan fakta lapangan.", "B. Terlalu dingin, kejam, dan merendahkan nilai kemanusiaan."],  // fallback (Indonesian)
      "optionsId": ["A. Terlalu mendramatisir perasaan dan mengabaikan fakta lapangan.", "B. Terlalu dingin, kejam, dan merendahkan nilai kemanusiaan."],
      "optionsEn": ["A. Too dramatized about feelings and ignoring facts on the ground.", "B. Too cold, cruel, and degrading human values."]
    },
    {
      "id": 70,
      "dimension": "TF",
      "question": "Pujian tertinggi yang paling membuat Anda tersanjung adalah ketika orang mengakui...",  // fallback (Indonesian)
      "questionId": "Pujian tertinggi yang paling membuat Anda tersanjung adalah ketika orang mengakui...",
      "questionEn": "The highest praise that flatters you most is when people acknowledge your...",
      "options": ["A. Kepintaran, ketajaman analisis, dan kompetensi Anda.", "B. Kebaikan hati, ketulusan, dan kehangatan sikap Anda."],  // fallback (Indonesian)
      "optionsId": ["A. Kepintaran, ketajaman analisis, dan kompetensi Anda.", "B. Kebaikan hati, ketulusan, dan kehangatan sikap Anda."],
      "optionsEn": ["A. Intelligence, sharp analysis, and competence.", "B. Kindness, sincerity, and warmth of attitude."]
    },
    {
      "id": 71,
      "dimension": "TF",
      "question": "Jika dihadapkan pada dua pilihan rumit, Anda cenderung memilih untuk menyampaikan...",  // fallback (Indonesian)
      "questionId": "Jika dihadapkan pada dua pilihan rumit, Anda cenderung memilih untuk menyampaikan...",
      "questionEn": "When faced with two difficult choices, you tend to choose to deliver...",
      "options": ["A. Kebenaran yang pahit dan menyakitkan (Kejujuran murni).", "B. Kebohongan putih (White lie) demi menjaga perasaan orang lain."],  // fallback (Indonesian)
      "optionsId": ["A. Kebenaran yang pahit dan menyakitkan (Kejujuran murni).", "B. Kebohongan putih (White lie) demi menjaga perasaan orang lain."],
      "optionsEn": ["A. The bitter and painful truth (Pure honesty).", "B. A white lie to protect others' feelings."]
    },
    {
      "id": 72,
      "dimension": "TF",
      "question": "Dalam kerja kelompok, fokus utama Anda adalah memastikan agar...",  // fallback (Indonesian)
      "questionId": "Dalam kerja kelompok, fokus utama Anda adalah memastikan agar...",
      "questionEn": "In group work, your main focus is to ensure that...",
      "options": ["A. Tim bekerja efisien dan mencapai target setinggi mungkin.", "B. Tim tetap harmonis dan tidak ada anggota yang merasa tersisih."],  // fallback (Indonesian)
      "optionsId": ["A. Tim bekerja efisien dan mencapai target setinggi mungkin.", "B. Tim tetap harmonis dan tidak ada anggota yang merasa tersisih."],
      "optionsEn": ["A. The team works efficiently and achieves the highest possible target.", "B. The team stays harmonious and no member feels left out."]
    },
    {
      "id": 73,
      "dimension": "TF",
      "question": "Saat Anda melakukan kesalahan fatal dalam proyek, Anda akan mengevaluasinya dengan...",  // fallback (Indonesian)
      "questionId": "Saat Anda melakukan kesalahan fatal dalam proyek, Anda akan mengevaluasinya dengan...",
      "questionEn": "When you make a fatal mistake in a project, you evaluate it by...",
      "options": ["A. Menganalisis kerusakan sistematis dan mencari strategi teknis yang baru.", "B. Merenungkan rasa bersalah dan memikirkan bagaimana cara menebusnya pada tim."],  // fallback (Indonesian)
      "optionsId": ["A. Menganalisis kerusakan sistematis dan mencari strategi teknis yang baru.", "B. Merenungkan rasa bersalah dan memikirkan bagaimana cara menebusnya pada tim."],
      "optionsEn": ["A. Analyzing the systematic damage and finding a new technical strategy.", "B. Reflecting on the guilt and thinking about how to make it up to the team."]
    },
    {
      "id": 74,
      "dimension": "TF",
      "question": "Menurut prinsip Anda, seorang pemimpin yang buruk adalah mereka yang...",  // fallback (Indonesian)
      "questionId": "Menurut prinsip Anda, seorang pemimpin yang buruk adalah mereka yang...",
      "questionEn": "According to your principles, a bad leader is one who is...",
      "options": ["A. Tidak logis, mudah goyah, dan tidak kompeten secara strategi.", "B. Otoriter, tidak punya empati, dan memperlakukan bawahan seperti mesin."],  // fallback (Indonesian)
      "optionsId": ["A. Tidak logis, mudah goyah, dan tidak kompeten secara strategi.", "B. Otoriter, tidak punya empati, dan memperlakukan bawahan seperti mesin."],
      "optionsEn": ["A. Illogical, easily swayed, and strategically incompetent.", "B. Authoritarian, lacking empathy, and treats subordinates like machines."]
    },
    {
      "id": 75,
      "dimension": "TF",
      "question": "Anda mengambil keputusan berskala besar sering kali berdasarkan...",  // fallback (Indonesian)
      "questionId": "Anda mengambil keputusan berskala besar sering kali berdasarkan...",
      "questionEn": "You make large-scale decisions often based on...",
      "options": ["A. Analisa sebab-akibat (Cause and Effect) yang masuk akal.", "B. Kesesuaian nilai moral dan kecocokan dengan hati nurani Anda."],  // fallback (Indonesian)
      "optionsId": ["A. Analisa sebab-akibat (Cause and Effect) yang masuk akal.", "B. Kesesuaian nilai moral dan kecocokan dengan hati nurani Anda."],
      "optionsEn": ["A. Logical cause-and-effect analysis.", "B. Alignment with moral values and your conscience."]
    },
    {
      "id": 76,
      "dimension": "TF",
      "question": "Saat menonton debat politik, Anda lebih tertarik mendukung kandidat yang...",  // fallback (Indonesian)
      "questionId": "Saat menonton debat politik, Anda lebih tertarik mendukung kandidat yang...",
      "questionEn": "When watching a political debate, you are more interested in supporting a candidate who...",
      "options": ["A. Memaparkan data akurat, argumen rasional, dan program yang realistis.", "B. Berpidato menyentuh hati dan tulus memperjuangkan keadilan sosial."],  // fallback (Indonesian)
      "optionsId": ["A. Memaparkan data akurat, argumen rasional, dan program yang realistis.", "B. Berpidato menyentuh hati dan tulus memperjuangkan keadilan sosial."],
      "optionsEn": ["A. Presents accurate data, rational arguments, and realistic programs.", "B. Gives moving speeches and genuinely fights for social justice."]
    },
    {
      "id": 77,
      "dimension": "TF",
      "question": "Di lingkungan perkantoran, Anda lebih mudah merasa jengkel oleh...",  // fallback (Indonesian)
      "questionId": "Di lingkungan perkantoran, Anda lebih mudah merasa jengkel oleh...",
      "questionEn": "In the office environment, you are more easily annoyed by...",
      "options": ["A. Orang yang tidak efisien, lemot, atau bekerja tanpa logika.", "B. Orang yang kasar, egois, atau tidak sopan terhadap orang lain."],  // fallback (Indonesian)
      "optionsId": ["A. Orang yang tidak efisien, lemot, atau bekerja tanpa logika.", "B. Orang yang kasar, egois, atau tidak sopan terhadap orang lain."],
      "optionsEn": ["A. Inefficient, slow people, or those who work without logic.", "B. Rude, selfish people, or those who are impolite to others."]
    },

    // ==========================================
    // TAMBAHAN 50 SOAL - DIMENSI JP (Judging vs Perceiving)
    // ==========================================
    {
      "id": 78,
      "dimension": "JP",
      "question": "Jika Anda dijadwalkan mengikuti wawancara jam 10 pagi, Anda biasanya...",  // fallback (Indonesian)
      "questionId": "Jika Anda dijadwalkan mengikuti wawancara jam 10 pagi, Anda biasanya...",
      "questionEn": "If you are scheduled for an interview at 10 AM, you usually...",
      "options": ["A. Tiba 15-30 menit lebih awal agar tenang dan siap.", "B. Tiba sangat mepet (tepat waktu) atau terlambat beberapa menit."],  // fallback (Indonesian)
      "optionsId": ["A. Tiba 15-30 menit lebih awal agar tenang dan siap.", "B. Tiba sangat mepet (tepat waktu) atau terlambat beberapa menit."],
      "optionsEn": ["A. Arrive 15-30 minutes early to be calm and ready.", "B. Arrive very close to the time (on the dot) or a few minutes late."]
    },
    {
      "id": 79,
      "dimension": "JP",
      "question": "Anda merasa potensi Anda lebih maksimal jika bekerja pada posisi yang memiliki...",  // fallback (Indonesian)
      "questionId": "Anda merasa potensi Anda lebih maksimal jika bekerja pada posisi yang memiliki...",
      "questionEn": "You feel your potential is maximized when working in a position that has...",
      "options": ["A. Target harian yang terukur, jadwal tetap, dan tenggat waktu yang tegas.", "B. Kebebasan penuh, jam kerja fleksibel, dan minim tekanan aturan kaku."],  // fallback (Indonesian)
      "optionsId": ["A. Target harian yang terukur, jadwal tetap, dan tenggat waktu yang tegas.", "B. Kebebasan penuh, jam kerja fleksibel, dan minim tekanan aturan kaku."],
      "optionsEn": ["A. Measurable daily targets, fixed schedule, and strict deadlines.", "B. Full freedom, flexible working hours, and minimal rigid rule pressure."]
    },
    {
      "id": 80,
      "dimension": "JP",
      "question": "Menjelang hari libur akhir pekan, pola pikiran Anda adalah...",  // fallback (Indonesian)
      "questionId": "Menjelang hari libur akhir pekan, pola pikiran Anda adalah...",
      "questionEn": "Approaching the weekend holiday, your mindset is...",
      "options": ["A. 'Saya harus merencanakan mau ke mana, makan apa, dan jam berapa.'", "B. 'Biarkan saja mengalir, lihat nanti mood-nya ingin melakukan apa.'"],  // fallback (Indonesian)
      "optionsId": ["A. 'Saya harus merencanakan mau ke mana, makan apa, dan jam berapa.'", "B. 'Biarkan saja mengalir, lihat nanti mood-nya ingin melakukan apa.'"],
      "optionsEn": ["A. 'I must plan where to go, what to eat, and at what time.'", "B. 'Just let it flow, see what the mood wants to do later.'"]
    },
    {
      "id": 81,
      "dimension": "JP",
      "question": "Saat sedang berada di tengah-tengah pengerjaan tugas besar, Anda...",  // fallback (Indonesian)
      "questionId": "Saat sedang berada di tengah-tengah pengerjaan tugas besar, Anda...",
      "questionEn": "When in the middle of working on a big task, you...",
      "options": ["A. Sulit bersantai; Anda ingin segera menuntaskannya secepat mungkin.", "B. Sering menyelingi tugas tersebut dengan bermain HP atau mengerjakan hal lain."],  // fallback (Indonesian)
      "optionsId": ["A. Sulit bersantai; Anda ingin segera menuntaskannya secepat mungkin.", "B. Sering menyelingi tugas tersebut dengan bermain HP atau mengerjakan hal lain."],
      "optionsEn": ["A. Find it hard to relax; you want to finish it as soon as possible.", "B. Often interleave the task with playing on your phone or doing other things."]
    },
    {
      "id": 82,
      "dimension": "JP",
      "question": "Gaya Anda dalam mengepak barang ke koper sebelum bepergian jauh adalah...",  // fallback (Indonesian)
      "questionId": "Gaya Anda dalam mengepak barang ke koper sebelum bepergian jauh adalah...",
      "questionEn": "Your style of packing items into a suitcase before traveling far is...",
      "options": ["A. Membuat daftar (checklist) dan menyusun pakaian dengan rapi dari jauh hari.", "B. Melempar pakaian ke dalam koper secara terburu-buru di pagi hari sebelum berangkat."],  // fallback (Indonesian)
      "optionsId": ["A. Membuat daftar (checklist) dan menyusun pakaian dengan rapi dari jauh hari.", "B. Melempar pakaian ke dalam koper secara terburu-buru di pagi hari sebelum berangkat."],
      "optionsEn": ["A. Make a checklist and arrange clothes neatly well in advance.", "B. Toss clothes into the suitcase in a rush on the morning of departure."]
    },
    {
      "id": 83,
      "dimension": "JP",
      "question": "Dua kata yang paling mewakili cara Anda menangani kehidupan sehari-hari adalah...",  // fallback (Indonesian)
      "questionId": "Dua kata yang paling mewakili cara Anda menangani kehidupan sehari-hari adalah...",
      "questionEn": "Two words that best represent how you handle daily life are...",
      "options": ["A. Terstruktur dan Tuntas (Closure).", "B. Adaptif dan Terbuka (Open-ended)."],  // fallback (Indonesian)
      "optionsId": ["A. Terstruktur dan Tuntas (Closure).", "B. Adaptif dan Terbuka (Open-ended)."],
      "optionsEn": ["A. Structured and Resolved (Closure).", "B. Adaptive and Open (Open-ended)."]
    },
    {
      "id": 84,
      "dimension": "JP",
      "question": "Jika jadwal acara yang sudah Anda susun rapi tiba-tiba batal karena hujan, Anda...",  // fallback (Indonesian)
      "questionId": "Jika jadwal acara yang sudah Anda susun rapi tiba-tiba batal karena hujan, Anda...",
      "questionEn": "If a neatly arranged event schedule is suddenly canceled due to rain, you...",
      "options": ["A. Merasa sangat kesal, stres, dan butuh waktu untuk merelakannya.", "B. Merasa biasa saja dan dengan cepat mencari keseruan lain sebagai penggantinya."],  // fallback (Indonesian)
      "optionsId": ["A. Merasa sangat kesal, stres, dan butuh waktu untuk merelakannya.", "B. Merasa biasa saja dan dengan cepat mencari keseruan lain sebagai penggantinya."],
      "optionsEn": ["A. Feel very upset, stressed, and need time to let it go.", "B. Feel fine about it and quickly look for other fun activities as a replacement."]
    },
    {
      "id": 85,
      "dimension": "JP",
      "question": "Saat pergi ke supermarket untuk belanja bulanan, Anda biasanya...",  // fallback (Indonesian)
      "questionId": "Saat pergi ke supermarket untuk belanja bulanan, Anda biasanya...",
      "questionEn": "When going to the supermarket for monthly shopping, you usually...",
      "options": ["A. Membawa daftar belanjaan dan hanya membeli barang yang ada di catatan.", "B. Berjalan-jalan menyusuri lorong dan secara spontan mengambil barang yang terlihat menarik."],  // fallback (Indonesian)
      "optionsId": ["A. Membawa daftar belanjaan dan hanya membeli barang yang ada di catatan.", "B. Berjalan-jalan menyusuri lorong dan secara spontan mengambil barang yang terlihat menarik."],
      "optionsEn": ["A. Bring a shopping list and only buy items on the list.", "B. Walk through the aisles and spontaneously pick up items that look appealing."]
    },
    {
      "id": 86,
      "dimension": "JP",
      "question": "Bagaimana biasanya kondisi kotak masuk (inbox) Email atau WhatsApp Anda?",  // fallback (Indonesian)
      "questionId": "Bagaimana biasanya kondisi kotak masuk (inbox) Email atau WhatsApp Anda?",
      "questionEn": "How is the condition of your Email or WhatsApp inbox usually?",
      "options": ["A. Sangat rapi, selalu dibalas, diarsipkan, atau dihapus jika tidak penting.", "B. Cukup berantakan, menumpuk, dan banyak pesan yang dibiarkan belum terbaca."],  // fallback (Indonesian)
      "optionsId": ["A. Sangat rapi, selalu dibalas, diarsipkan, atau dihapus jika tidak penting.", "B. Cukup berantakan, menumpuk, dan banyak pesan yang dibiarkan belum terbaca."],
      "optionsEn": ["A. Very neat, always replied to, archived, or deleted if unimportant.", "B. Somewhat messy, piling up, and many messages left unread."]
    },
    {
      "id": 87,
      "dimension": "JP",
      "question": "Dalam mengambil keputusan investasi atau pembelian barang mahal, Anda...",  // fallback (Indonesian)
      "questionId": "Dalam mengambil keputusan investasi atau pembelian barang mahal, Anda...",
      "questionEn": "When making investment decisions or purchasing expensive items, you...",
      "options": ["A. Ingin memutuskannya dengan cepat agar pikiran tenang dan bisa move on.", "B. Suka menundanya selama mungkin untuk berjaga-jaga jika ada diskon atau opsi lebih baik."],  // fallback (Indonesian)
      "optionsId": ["A. Ingin memutuskannya dengan cepat agar pikiran tenang dan bisa move on.", "B. Suka menundanya selama mungkin untuk berjaga-jaga jika ada diskon atau opsi lebih baik."],
      "optionsEn": ["A. Want to decide quickly so your mind is at peace and can move on.", "B. Like to delay it as long as possible in case there's a discount or better option."]
    },
    {
      "id": 88,
      "dimension": "JP",
      "question": "Anda memandang 'Aturan' di tempat kerja sebagai...",  // fallback (Indonesian)
      "questionId": "Anda memandang 'Aturan' di tempat kerja sebagai...",
      "questionEn": "You view 'Rules' at the workplace as...",
      "options": ["A. Sesuatu yang mutlak, penting, dan harus ditaati demi ketertiban bersama.", "B. Sesuatu yang sekadar panduan umum dan bisa dilanggar jika situasinya memaksa."],  // fallback (Indonesian)
      "optionsId": ["A. Sesuatu yang mutlak, penting, dan harus ditaati demi ketertiban bersama.", "B. Sesuatu yang sekadar panduan umum dan bisa dilanggar jika situasinya memaksa."],
      "optionsEn": ["A. Something absolute, important, and must be obeyed for the sake of order.", "B. Something merely a general guide that can be broken if the situation forces it."]
    },
    {
      "id": 89,
      "dimension": "JP",
      "question": "Ketika ada teman yang tiba-tiba mengajak nongkrong dalam waktu 10 menit ke depan, Anda...",  // fallback (Indonesian)
      "questionId": "Ketika ada teman yang tiba-tiba mengajak nongkrong dalam waktu 10 menit ke depan, Anda...",
      "questionEn": "When a friend suddenly invites you to hang out within the next 10 minutes, you...",
      "options": ["A. Cenderung menolak karena hal itu merusak ritme jadwal Anda hari itu.", "B. Langsung mengiyakan karena Anda sangat menyukai spontanitas dan kejutan."],  // fallback (Indonesian)
      "optionsId": ["A. Cenderung menolak karena hal itu merusak ritme jadwal Anda hari itu.", "B. Langsung mengiyakan karena Anda sangat menyukai spontanitas dan kejutan."],
      "optionsEn": ["A. Tend to decline because it disrupts your schedule's rhythm that day.", "B. Immediately agree because you really love spontaneity and surprises."]
    },
    {
      "id": 90,
      "dimension": "JP",
      "question": "Motto yang paling mendeskripsikan ritme hidup Anda adalah...",  // fallback (Indonesian)
      "questionId": "Motto yang paling mendeskripsikan ritme hidup Anda adalah...",
      "questionEn": "The motto that best describes the rhythm of your life is...",
      "options": ["A. 'Selesaikan pekerjaanmu dahulu, baru kamu bisa bermain sepuasnya.'", "B. 'Campurkan pekerjaan dengan bermain agar hidup tidak membosankan.'"],  // fallback (Indonesian)
      "optionsId": ["A. 'Selesaikan pekerjaanmu dahulu, baru kamu bisa bermain sepuasnya.'", "B. 'Campurkan pekerjaan dengan bermain agar hidup tidak membosankan.'"],
      "optionsEn": ["A. 'Finish your work first, then you can play as much as you want.'", "B. 'Mix work with play so life isn't boring.'"]
    },

  ];
}
