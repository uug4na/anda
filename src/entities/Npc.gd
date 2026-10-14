class_name Npc
extends StaticBody2D
## A talkable character. Hoelun for now.

const SHEETS := {"hoelun": "companions/comp_hoelun_idle_3dir.png", "sorkanshira": "npcs/npc_sorkanshira_idle_3dir.png",
	"boorchu": "companions/comp_boorchu_mounted_idle_3dir.png", "boorchu_foot": "companions/comp_boorchu_idle_3dir.png"}
const CELLS := {"boorchu": 144}
const PORTRAITS := {"hoelun": "portraits/portrait_hoelun_neutral.png", "sorkanshira": "portraits/portrait_sorkanshira_neutral.png",
	"boorchu": "portraits/portrait_boorchu_neutral.png", "boorchu_foot": "portraits/portrait_boorchu_neutral.png"}
const NAMES := {"hoelun": "Hoelun", "sorkanshira": "Sorkan-Shira", "boorchu": "Bo'orchu", "boorchu_foot": "Bo'orchu",
	"borte": "Börte", "ongkhan": "Ong Khan", "jamukha": "Jamukha", "qasar": "Qasar", "shigi": "Shigi Qutuqu", "jelme": "Jelme", "jebe": "Jebe", "subutai": "Subutai"}
const EXTRA_SHEETS := {"borte": "companions/comp_borte_idle_3dir.png", "ongkhan": "companions/comp_ongkhan_idle_3dir.png", "jamukha": "companions/comp_jamukha_idle_3dir.png",
	"qasar": "companions/comp_qasar_idle_3dir.png", "shigi": "companions/comp_shigi_idle_3dir.png", "jelme": "companions/comp_jelme_idle_3dir.png",
	"jebe": "companions/comp_jebe_idle_3dir.png", "subutai": "companions/comp_subutai_idle_3dir.png"}
const EXTRA_PORTRAITS := {"borte": "portraits/portrait_borte_neutral.png", "ongkhan": "portraits/portrait_ongkhan_neutral.png", "jamukha": "portraits/portrait_jamukha_young_neutral.png",
	"qasar": "portraits/portrait_qasar_neutral.png", "shigi": "portraits/portrait_shigi_neutral.png", "jelme": "portraits/portrait_jelme_neutral.png",
	"jebe": "portraits/portrait_jebe_neutral.png", "subutai": "portraits/portrait_subutai_neutral.png"}

var who := "hoelun"
var t := 0.0
var body: Sprite2D


static func spawn(parent: Node, pos: Vector2, who_name: String) -> Npc:
	var n := Npc.new()
	n.who = who_name
	n.position = pos
	n.add_to_group("npc")
	n.collision_layer = 1
	n.collision_mask = 0
	n.body = Sprite2D.new()
	var sheet: String = SHEETS.get(who_name, EXTRA_SHEETS.get(who_name, SHEETS["hoelun"]))
	var cell: int = CELLS.get(who_name, 96)
	if not ResourceLoader.exists(Sheets.ROOT + sheet):
		sheet = SHEETS["boorchu_foot"] if who_name == "boorchu" else SHEETS["hoelun"]
		cell = 96
	n.body.texture = Sheets.dir3(sheet, cell)["down"]
	n.body.offset = Vector2(0, -cell / 2.0)
	n.add_child(n.body)
	var shape := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(20, 10)
	shape.shape = r
	shape.position = Vector2(0, -5)
	n.add_child(shape)
	var reach := Area2D.new()
	reach.collision_layer = 1 << 8
	reach.collision_mask = 0
	var rs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 22.0
	rs.shape = circle
	rs.position = Vector2(0, -20)
	reach.add_child(rs)
	n.add_child(reach)
	parent.add_child(n)
	return n


func _process(delta: float) -> void:
	t += delta
	body.scale = Vector2(1.0 + 0.01 * sin(t * 2.0), 1.0 - 0.01 * sin(t * 2.0))


const CHAPTER_END_IMAGE := "cutscenes/cutscene_04_nine_days_forest.png"
const CHAPTER_END_LINES := [
	"Targhutai went home with nothing. For nine days the Tayichiud searched the forest, and the forest kept its boy.",
	"The Onon fed the family through the winter. Two white tails on the banner, and a name that began to travel.",
	"Targhutai does not forget. Next summer the Tayichiud will come again, and this time they will bring a cangue.",
	"End of Chapter One.",
]

var after_dialog := Callable()


## Sets a story flag when the dialog closes rather than when it opens, so the objective line
## does not jump ahead while the speaker is still talking. Keeps any callback already queued.
func _flag_after(flag: String) -> void:
	var then := after_dialog
	after_dialog = func() -> void:
		Game.set_flag(flag)
		Game.autosave()
		if then.is_valid():
			then.call()


func interact(_hero: Node) -> void:
	var box := get_tree().get_first_node_in_group("dialog")
	if box == null:
		return
	var lines := _lines()
	if after_dialog.is_valid():
		var cb := after_dialog
		after_dialog = Callable()
		box.finished.connect(cb, CONNECT_ONE_SHOT)
	box.show_lines(lines)


func _sorkan_lines() -> Array:
	if not Game.flags.get("cangue_off", false):
		after_dialog = _wool_cart
		return [
			"You. The boy from the river. Keep your voice down; my sons will see to that board.",
			"Into the wool, quickly. If they find you here we all die together.",
		]
	if not Game.flags.get("captain", false):
		return ["The captain is here. I cannot hide you from him. You will have to settle it."]
	return ["Go east along the river and do not stop until the Onon. We never met, you and I."]


func _borte_lines() -> Array:
	if Game.flags.get("borte_taken", false) and not Game.flags.get("borte_back", false):
		# In the burning Merkit camp. Finding her is the end of the raid.
		if not Game.flags.get("chilger", false):
			return ["He is still here. Do not let him see you. Go, and come back when it is done."]
		after_dialog = _found
		return [
			"I heard you calling in the dark. I climbed down from the cart and came toward the voice.",
			"Take me home, Temüjin. Whatever they say about the child, take me home.",
		]
	if not Game.flags.get("sable", false):
		after_dialog = _give_sable
		return [
			"My mother sent a sable coat as my dowry. It is worth more than everything else we own together.",
			"Your father had an anda, Toghrul, the Ong Khan of the Kereyit. A gift like this makes a khan remember an old oath.",
			"Take it to him. The road runs south across the steppe.",
		]
	return ["Go carefully. I will keep the fire."]


func _give_sable() -> void:
	Game.set_flag("sable")
	Game.autosave()


func _found() -> void:
	Game.run_cutscene("borte_found")


func _ongkhan_lines() -> Array:
	if not Game.flags.get("ongkhan_met", false):
		after_dialog = _meet_ongkhan
		return [
			"A sable coat. Your father's son, and he knows how to ask. I will not forget this.",
			"Go home to your bride, Temüjin. If the Merkits come for an old debt, send to me.",
		]
	if Game.flags.get("borte_taken", false) and not Game.flags.get("allies_pledged", false):
		return ["Twenty thousand Kereyit will ride. Jamukha will bring as many. Speak to him; he is outside."]
	return ["The coat hangs in my tent. The oath hangs with it."]


func _meet_ongkhan() -> void:
	Game.set_flag("ongkhan_met")
	Game.autosave()


func _jamukha_lines() -> Array:
	if Game.flags.get("borte_taken", false) and not Game.flags.get("allies_pledged", false):
		after_dialog = _pledge
		return [
			"Temüjin. We swore anda as boys on the ice of the Onon, with knucklebones. I have not forgotten.",
			"We ride at the new moon and take the Merkit camp in the dark. Stay close to me, and we will find her.",
		]
	return ["Anda. Stay close in the dark."]


func _pledge() -> void:
	Game.set_flag("allies_pledged")
	Game.autosave()


func _recruit_lines(c: String) -> Array:
	if Game.flags.get(c, false):
		match c:
			"qasar": return ["Point me at them, brother."]
			"shigi": return ["Hoelun says I am to learn letters. What are letters?"]
			"jelme": return ["Keep still when I bind it, or it will not hold."]
			"jebe": return ["Your horse, your arrow, your khan. I pay my debts."]
			"subutai": return ["Give me a river and a winter and I will give you a kingdom."]
		return ["..."]
	after_dialog = func() -> void:
		Game.set_flag(c)
		Game.autosave()
	match c:
		"qasar":
			return [
				"Jamukha boiled seventy men alive and you came home with the banner. Good. Now we go to the Tatars.",
				"Give me a clear line and I will loose three for your one. Press Q when the line is clear.",
			]
		"shigi":
			after_dialog = func() -> void:
				Game.set_flag("shigi")
				Game.run_cutscene("tatar_end")
			return ["Are you going to cut me too? I am taller than the cart axle. I measured."]
		"jelme":
			return [
				"Nineteen of us, a muddy lake and the Kereyit behind. I was a smith's boy. I know how to stop a bleed.",
				"Press Q when you are hurt and I will bind it. Once a fight, it is all the cloth I have.",
			]
		"jebe":
			return [
				"At Koyiten it was my arrow that killed your horse. You asked who shot it. I said: I did.",
				"Kill me, or give me a horse and I will be your arrow. Press Q and I will put one through three men.",
			]
		"subutai":
			return [
				"I am Subutai of the Uriankhai. My father made your arrows. I would rather make your traps.",
				"Press Q and I will set a snare at your feet. The first fool to step in it will stop and think.",
			]
	return ["..."]


func _wedding() -> void:
	Game.run_cutscene("wedding")


func _chapter2_end() -> void:
	Game.set_flag("chapter2")
	Game.autosave()


func _boorchu_lines() -> Array:
	if not Game.flags.get("boorchu", false):
		after_dialog = _recruit_boorchu
		return [
			"Those your horses? I saw eight geldings go past at dawn with three riders.",
			"Take my dun and I will ride with you. A man who rides alone after thieves is a fool, and you are not a fool.",
			"Press Q on open ground and I will whistle up your horse.",
		]
	return ["They cannot outrun us. Shoot from the saddle, I will keep the geldings together."]


func _recruit_boorchu() -> void:
	Game.set_flag("boorchu")
	Game.autosave()


func _wool_cart() -> void:
	Game.run_cutscene("wool_cart")


func _chapter_end() -> void:
	Game.set_flag("chapter1")
	Game.autosave()
	Game.play_cutscene(CHAPTER_END_IMAGE, CHAPTER_END_LINES, "camp")


func _lines() -> Array:
	var name_: String = NAMES.get(who, who)
	var portrait: String = PORTRAITS.get(who, EXTRA_PORTRAITS.get(who, ""))
	if not ResourceLoader.exists(Sheets.ROOT + portrait):
		portrait = ""
	var out := []
	var texts: Array
	if who == "sorkanshira":
		texts = _sorkan_lines()
	elif who == "boorchu" or who == "boorchu_foot":
		texts = _boorchu_lines()
	elif who == "borte":
		texts = _borte_lines()
	elif who == "ongkhan":
		texts = _ongkhan_lines()
	elif who == "jamukha":
		texts = _jamukha_lines()
	elif who in ["qasar", "shigi", "jelme", "jebe", "subutai"]:
		texts = _recruit_lines(who)
	elif Game.flags.get("kurultai", false):
		texts = ["Chinggis Khan. I carried you on a horse with one too few. Go and be what they named you."]
	elif Game.flags.get("tatar_done", false) and not Game.flags.get("thanked6", false):
		_flag_after("thanked6")
		texts = [
			"Shigi Qutuqu sleeps by my fire. Your father's killers are ash. That is enough of that.",
			"Another tail. But Ong Khan's son whispers that you grow too tall. The old man listens to his son now.",
			"Keep nineteen men you trust close. You may need every one of them at short notice.",
		]
	elif Game.flags.get("senggum", false) and not Game.flags.get("thanked7", false):
		_flag_after("thanked7")
		texts = [
			"The Kereyit are broken and Ong Khan is dead on the road, killed by Naiman who did not know his face.",
			"Another tail. Eight. Only the Naiman are left, and Jamukha is with them.",
			"Subutai has come from the Uriankhai with his hammer. Speak to him. Then finish it.",
		]
	elif Game.flags.get("balzhut", false) and not Game.flags.get("qasar", false):
		texts = ["You lost a battle and kept your people. Qasar is back from the hunt and angry about it. Talk to him."]
	elif Game.flags.get("thanked5", false) and not Game.flags.get("balzhut", false):
		texts = ["You and Jamukha share one camp now, anda and anda. It will not hold. Two suns cannot share one sky."]
	elif Game.flags.get("borte_back", false) and not Game.flags.get("thanked5", false):
		after_dialog = _chapter2_end
		_flag_after("thanked5")
		texts = [
			"She is home. Say nothing about the child, now or ever. That is how a khan behaves.",
			"Another tail. Jamukha called you anda tonight, sworn brother. Hold that word carefully. It cuts both ways.",
		]
	elif Game.flags.get("thanked4", false) and not Game.flags.get("wedded", false):
		after_dialog = _wedding
		texts = [
			"Dei the Wise of the Onggirat keeps his word even to the dead. Börte is waiting. Go and bring her home.",
		]
	elif Game.flags.get("thieves", false) and not Game.flags.get("thanked4", false):
		_flag_after("thanked4")
		texts = [
			"Eight geldings home, and a ninth rider with them. Bo'orchu of the Arulat, you are welcome at this fire.",
			"Another tail on the banner. We are becoming a people again, Temüjin.",
			"There is a girl of the Onggirat your father chose for you. Börte. It is time you rode to her.",
		]
	elif Game.flags.get("captain", false) and not Game.flags.get("thanked3", false):
		_flag_after("thanked3")
		texts = [
			"You came back with the mark of the board on your neck and your life. That is more than most.",
			"Sorkan-Shira will be remembered. When you are khan, remember him first.",
			"Another tail. Now the horses: eight geldings went in the night, and the thieves rode east. Belgütei followed the tracks.",
		]
	elif Game.flags.get("thanked2", false) and not Game.flags.get("captured", false):
		texts = ["The Tayichiud camp lies north-east, past the forest. Scout it, and do not get caught."]
	elif not Game.flags.get("begter", false):
		texts = [
			"They took the herds and left us the river. So the river will feed us.",
			"Take your bow, Temüjin. Dig roots on the bank and take fish from the shallows. The way is east, then north.",
			"And watch your brother Begter. He takes what is ours and calls it his.",
		]
	elif not Game.flags.get("thanked", false):
		_flag_after("thanked")
		texts = [
			"It is done, then. I will not weep for Begter.",
			"Another white tail on the banner. There will be more, and brothers worth the name to find.",
			"The Tayichiud hunt in the forest east of the steppe. Targhutai wants you in a cangue. Do not give him the chance.",
		]
	elif Game.flags.get("targhutai", false) and not Game.flags.get("thanked2", false):
		after_dialog = _chapter_end
		_flag_after("thanked2")
		texts = [
			"Targhutai Kiriltugh, run off by a boy with a bow. They will tell that one at every fire on the Onon.",
			"We can raise another ger now. The clan is small, but it is a clan.",
		]
	else:
		texts = ["Go on. The steppe is wide, and it is all still ours."]
	for tx in texts:
		out.append({"name": name_, "portrait": portrait, "text": tx})
	return out
