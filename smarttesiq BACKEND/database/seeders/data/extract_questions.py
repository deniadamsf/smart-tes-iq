# Mengekstrak bank soal berskor dari lib/data/*.dart menjadi JSON.
# Dipakai sekali untuk mengisi tabel question_bank di backend.
import io, json, os, re, sys

DATA = sys.argv[1]
OUT = sys.argv[2]

# file -> (pool, category)
SOURCES = [
    ("verbal_data.dart",                "free", "verbal"),
    ("verbal_pro_data.dart",            "pro",  "verbal"),
    ("deret_angka_data.dart",           "free", "deret"),
    ("deret_angka_pro_data.dart",       "pro",  "deret"),
    ("penalaran_logis_data.dart",       "free", "logika"),
    ("penalaran_logis_pro_data.dart",   "pro",  "logika"),
    ("spasial_data.dart",               "free", "spasial"),
    ("spasial_pro_data.dart",           "pro",  "spasial"),
    ("klasifikasi_data.dart",           "free", "klasifikasi"),
    ("klasifikasi_gambar_pro_data.dart","pro",  "klasifikasi"),
]


def strip_comments(s):
    """Buang komentar // dan /* */ tanpa merusak isi string."""
    out = []
    i, n = 0, len(s)
    while i < n:
        c = s[i]
        if c in "\"'":
            q = c
            out.append(c); i += 1
            while i < n:
                if s[i] == "\\":
                    out.append(s[i:i+2]); i += 2; continue
                out.append(s[i])
                if s[i] == q:
                    i += 1; break
                i += 1
            continue
        if c == "/" and i + 1 < n:
            if s[i+1] == "/":
                while i < n and s[i] != "\n": i += 1
                continue
            if s[i+1] == "*":
                i += 2
                while i + 1 < n and not (s[i] == "*" and s[i+1] == "/"): i += 1
                i += 2; continue
        out.append(c); i += 1
    return "".join(out)


def extract_list(s):
    """Ambil literal list setelah 'questions' = [ ... ] dengan brace matching."""
    m = re.search(r"questions\s*=\s*\[", s)
    if not m:
        raise ValueError("tidak menemukan 'questions = ['")
    start = m.end() - 1
    depth, i, n = 0, start, len(s)
    while i < n:
        c = s[i]
        if c in "\"'":
            q = c; i += 1
            while i < n:
                if s[i] == "\\": i += 2; continue
                if s[i] == q: break
                i += 1
        elif c == "[":
            depth += 1
        elif c == "]":
            depth -= 1
            if depth == 0:
                return s[start:i+1]
        i += 1
    raise ValueError("kurung list tidak tertutup")


def to_json(lit):
    lit = re.sub(r",(\s*[\]\}])", r"\1", lit)   # buang trailing comma
    return json.loads(lit)


rows, report = [], []
for fname, pool, cat in SOURCES:
    path = os.path.join(DATA, fname)
    raw = io.open(path, encoding="utf-8").read()
    try:
        items = to_json(extract_list(strip_comments(raw)))
    except Exception as e:
        report.append((fname, 0, "GAGAL: %s" % e))
        continue

    kept, skipped = 0, 0
    for it in items:
        ans = it.get("answer")
        img = it.get("image") or it.get("imagePath") or it.get("image_path")
        opts = it.get("options") or it.get("optionsId")

        # Soal PRO bergambar tidak menyimpan pilihan di data: layarnya
        # merender ['A','B','C','D','E'] secara hardcode
        # (spasial_pro_test_screen.dart:372, klasifikasi_gambar_pro:328).
        # Samakan di sini supaya server mengirim pilihan yang identik.
        if not opts and img:
            opts = ["A", "B", "C", "D", "E"]

        if not ans or not opts:
            skipped += 1
            continue

        q_id = it.get("questionId") or it.get("question")
        q_en = it.get("questionEn") or it.get("question")
        o_id = it.get("optionsId") or opts
        o_en = it.get("optionsEn") or opts

        # soal wajib punya teks ATAU gambar
        if not q_id and not img:
            skipped += 1
            continue

        rows.append({
            "pool": pool,
            "category": cat,
            "question_id": q_id,
            "question_en": q_en,
            "image_path": img,
            "options_id": o_id,
            "options_en": o_en,
            # Kunci dinormalkan jadi SATU HURUF.
            # Sumbernya tidak konsisten: verbal/deret/logika PRO menyimpan teks
            # opsi lengkap ("C. Bulan"), sisanya huruf saja ("C"). Sudah
            # diverifikasi untuk 530 soal: teks penuh selalu cocok persis dengan
            # salah satu opsi, dan huruf depannya selalu sesuai posisi opsi
            # (A=indeks 0, B=1, ...). Jadi huruf pertama aman untuk keduanya.
            "answer": str(ans).strip()[0].upper(),
        })
        kept += 1
    report.append((fname, kept, "dilewati %d" % skipped if skipped else "ok"))

io.open(OUT, "w", encoding="utf-8").write(json.dumps(rows, ensure_ascii=False, indent=1))

print("%-34s %6s  %s" % ("FILE", "SOAL", "CATATAN"))
for f, k, note in report:
    print("%-34s %6d  %s" % (f, k, note))
print("-" * 60)
print("%-34s %6d" % ("TOTAL", len(rows)))

free = sum(1 for r in rows if r["pool"] == "free")
print("%-34s %6d" % ("  gratis", free))
print("%-34s %6d" % ("  pro", len(rows) - free))
img = sum(1 for r in rows if r["image_path"])
print("%-34s %6d" % ("  bergambar", img))
