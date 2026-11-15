extends Node
# Story text. Every entry is [malay, english]. Use Story.line(key) anywhere; it returns the active language.

const GF_NAME := "Aina"
const FRIEND := "Hafiz"

const LINES := {
	"ping_rnr": ["Aina: Ingat tak kita lepak R&R masa balik kampung dulu?", "Aina: Remember when we stopped at the R&R on the way to the kampung?"],
	"ping_gas": ["Aina: Kau mandi kat stesen minyak? Serius?", "Aina: You are showering at a petrol station? Seriously?"],
	"ping_lrt": ["Aina: Dulu kau bagi aku tempat duduk kat LRT.", "Aina: You used to give me your seat on the LRT."],
	"ping_mall": ["Aina: Mak aku tanya, kau masih kepam ke?", "Aina: My mum asks if you still smell."],
	"ping_lake": ["Aina: ...", "Aina: ..."],
	"ping_late": ["Aina: Aku tengah pilih baju kahwin.", "Aina: I am picking out a wedding dress."],
	"typing": ["menaip...", "typing..."],

	"news_s0": ["Lelaki dikesan berbau di sekitar bandar. Orang ramai diminta tutup hidung.", "Man with strong odour spotted downtown. Public asked to cover noses."],
	"news_s1": ["R&R dilaporkan berbau sabun. Pakar hairan.", "R&R reported to smell of soap. Experts baffled."],
	"news_s2": ["Tandas stesen minyak bersih buat pertama kali sejak 2019.", "Petrol station toilet clean for the first time since 2019."],
	"news_s3": ["Penumpang LRT: 'Bau dah kurang, tapi dia masih pelik.'", "LRT commuter: 'Smell is better, but he is still weird.'"],
	"news_s4": ["Lelaki misteri terlihat menuju Golden Lake. Ikan bersiap sedia.", "Mystery man heads for Golden Lake. Fish are ready."],
	"news_hot": ["AMARAN: Paras kepam negeri meningkat!", "WARNING: State kepam level rising!"],
	"news_tail": ["Berita Kepam 26: sentiasa wangi, kecuali hari ini.", "Berita Kepam 26: always fresh, except today."],

	"hafiz_hub": ["Hafiz: Bro, mulakan dengan R&R. Jangan tidur!", "Hafiz: Bro, start at R&R. Do not fall asleep!"],
	"hafiz_rnr": ["Hafiz: Tekan ikut rentak. Mata terbuka!", "Hafiz: Tap to the rhythm. Eyes open!"],
	"hafiz_gas": ["Hafiz: Gosok kuat kuat. Mop tu kawan kau.", "Hafiz: Scrub hard. The mop is your friend."],
	"hafiz_lrt": ["Hafiz: Jawab soalan betul betul. Bukan teka.", "Hafiz: Answer properly. No guessing."],
	"hafiz_mall": ["Hafiz: Lipas laju tapi tak pandai ikut lorong pintas.", "Hafiz: The cockroach is fast but does not know shortcuts."],
	"hafiz_joke": ["Hafiz: Aku bagi kau hint. Bukan sabun.", "Hafiz: I give you hints. Not soap."],

	"gas_attendant": ["Abang Pam: Siapa conteng tandas ni?! Nah, mop.", "Pump Attendant: Who vandalised this toilet?! Here, take a mop."],
	"gas_attendant_done": ["Abang Pam: Wah, berkilat. Kau memang tak kepam.", "Pump Attendant: Wow, it shines. You really do not smell."],
	"mall_guard": ["Pak Guard: Hati hati, ada lipas besar. Lari ke tandas hujung.", "Guard: Careful, there is a giant cockroach. Run to the toilet at the end."],
	"mall_guard_done": ["Pak Guard: Hah, lipas pun mati. Kau hebat.", "Guard: Even the cockroach is dead. You are good."],

	"comic_title": ["KENAPA DIA KEPAM?", "WHY IS HE KEPAM?"],
	"comic_1": ["Minggu exam. Tak sempat mandi.", "Exam week. No time to shower."],
	"comic_2": ["Main game sampai pagi.", "Gaming until sunrise."],
	"comic_3": ["Kerja lebih masa. Baju sama, hari ketiga.", "Overtime. Same shirt, day three."],
	"comic_4": ["Hari ini: lalat pun lari.", "Today: even flies keep away."],
	"comic_skip": ["ENTER untuk langkau", "ENTER to skip"],

	"end_forgive": ["Aku maafkan kau. Jom mula balik.", "I forgive you. Let us start over."],
	"end_conditions": ["Okay, tapi mandi tiap hari. Janji?", "Okay, but shower every day. Promise?"],
	"end_time": ["Bagi aku masa. Tapi aku bangga.", "Give me time. But I am proud."],
	"end_forgive_cap": ["Dia maafkan. Dia genggam tangan kau.", "She forgives you and takes your hand."],
	"end_conditions_cap": ["Dia bagi syarat: mandi tiap hari.", "She sets a condition: shower every day."],
	"end_time_cap": ["Dia perlukan masa. Tapi dia senyum.", "She needs time. But she smiles."],

	"secret_1": ["Hafiz: Bro... kau tak beli sabun pun?", "Hafiz: Bro... you did not even buy soap?"],
	"secret_2": ["Hafiz: Legend. Wangi asli.", "Hafiz: Legend. Naturally fresh."],
	"secret_cap": ["PENGAKHIRAN RAHSIA\nWangi Asli", "SECRET ENDING\nNatural Scent"],

	"head_viral": ["BUDAK KEPAM TULAR!", "KEPAM BOY GOES VIRAL!"],
	"sub_viral": ["Video dikejar lipas cecah sejuta tontonan", "Video of cockroach chase hits one million views"],
	"head_spread": ["NEGERI LUMPUH AKIBAT KEPAM", "STATE PARALYSED BY KEPAM"],
	"sub_spread": ["Sekolah dan pejabat ditutup", "Schools and offices closed"],
	"head_lake": ["LELAKI TERAPUNG DI TASIK MALAP", "MAN FLOATS IN DIM LAKE"],
	"sub_lake": ["Misteri: kenapa masih berbau?", "Mystery: why does he still smell?"],
	"head_gf": ["PASANGAN BAHAGIA BERNIKAH", "HAPPY COUPLE WEDS"],
	"sub_gf": ["Tetamu pelik bau kepam di luar dewan", "Guests puzzled by a smell outside the hall"],
	"lipas_viral_1": ["Lipas di mall tak lepaskan dia.", "The cockroach at the mall would not let him go."],
	"lipas_viral_news": ["LELAKI KEPAM DIKEJAR LIPAS GERGASI DI MALL, VIDEO TERSEBAR!", "KEPAM MAN CHASED BY GIANT COCKROACH AT MALL, VIDEO GOES VIRAL!"],

	"credits_title": ["ANTI-KEPAM", "ANTI-KEPAM"],
	"credits_boy": ["Si Kepam (kau)", "The Kepam Boy (you)"],
	"credits_gf": ["Aina", "Aina"],
	"credits_friend": ["Hafiz, kawan baik", "Hafiz, best friend"],
	"credits_lipas": ["Lipas (arwah)", "The Cockroach (late)"],
	"credits_thanks": ["Terima kasih sebab main!", "Thanks for playing!"],
	"hint_label": ["Hint", "Hint"],
}


func line(key: String) -> String:
	if not LINES.has(key):
		return key
	var pair: Array = LINES[key]
	return pair[0] if Loc.lang == "ms" else pair[1]


func ping(station: String) -> String:
	if GameState.gf_left < GameState.GF_TIME * 0.3 and station != "lake":
		return line("ping_late")
	return line("ping_" + station)


func hint(station: String) -> String:
	return line("hafiz_" + station) if LINES.has("hafiz_" + station) else line("hafiz_joke")


func news_text() -> String:
	var parts: Array[String] = []
	if GameState.spread > 50.0:
		parts.append(line("news_hot"))
	parts.append(line("news_s%d" % clampi(GameState.step, 0, 4)))
	parts.append(line("news_s%d" % clampi(GameState.step + 1, 0, 4)))
	parts.append(line("news_tail"))
	return "     +++     ".join(parts)


func branch() -> String:
	var avg := GameState.average_score()
	if avg >= 0.85:
		return "forgive"
	if avg >= 0.7:
		return "conditions"
	return "time"


func is_secret() -> bool:
	var bought: Variant = GameState.get("soap_bought")
	var none := (int(bought) == 0) if bought != null else (GameState.soap + GameState.tissue == 0)
	return none and GameState.average_score() >= 0.9
