class_name Lang
## Translation for static code (core scripts, static UI helpers), where Object.tr() isn't available.
## Node scripts use tr(); Labels and Buttons translate their own text (auto translate).


## `s` in the player's language (as a String, so `Lang.t("%d left") % n` types cleanly).
static func t(s: String) -> String:
	return String(TranslationServer.translate(s))
