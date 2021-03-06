-- Plugin to change the startup partition
-- (c) Markus Volk, Sven Hoefer, Don de Deckelwech
-- distributed under BSD-2-Clause License

caption = "STB-Startup"
version = 0.04

n = neutrino()
fh = filehelpers.new()

locale = {}
locale["deutsch"] = {
	current_boot_partition = "Die aktuelle Startpartition ist: ",
	choose_partition = "\n\nBitte wählen Sie die neue Startpartition aus",
	start_partition = "Rebooten und die gewählte Partition starten?"
}
locale["english"] = {
	current_boot_partition = "The current start partition is: ",
	choose_partition = "\n\nPlease choose the new start partition",
	start_partition = "Reboot and start the chosen partition?"
}

neutrino_conf = configfile.new()
neutrino_conf:loadConfig("/var/tuxbox/config/neutrino.conf")
lang = neutrino_conf:getString("language", "english")
if locale[lang] == nil then
	lang = "english"
end
timing_menu = neutrino_conf:getString("timing.menu", "0")

for line in io.lines("/boot/STARTUP") do
	akt_boot_partition = string.sub(line,23,24)
	print(akt_boot_partition)
end

chooser_dx = n:scale2Res(600)
chooser_dy = n:scale2Res(200)
chooser_x = SCREEN.OFF_X + (((SCREEN.END_X - SCREEN.OFF_X) - chooser_dx) / 2)
chooser_y = SCREEN.OFF_Y + (((SCREEN.END_Y - SCREEN.OFF_Y) - chooser_dy) / 2)

chooser = cwindow.new {
	x = chooser_x,
	y = chooser_y,
	dx = chooser_dx,
	dy = chooser_dy,
	title = caption, --.." v" .. version,
	icon = "settings",
	has_shadow = true,
	btnRed = "Partition 1",
	btnGreen = "Partition 2",
	btnYellow = "Partition 3",
	btnBlue = "Partition 4"
}
chooser_text = ctext.new {
	parent = chooser,
	x = OFFSET.INNER_MID,
	y = OFFSET.INNER_SMALL,
	dx = chooser_dx - 2*OFFSET.INNER_MID,
	dy = chooser_dy - chooser:headerHeight() - chooser:footerHeight() - 2*OFFSET.INNER_SMALL,
	text = locale[lang].current_boot_partition .. akt_boot_partition .. locale[lang].choose_partition,
	font_text = FONT.MENU,
	mode = "ALIGN_CENTER"
}
chooser:paint()

i = 0
d = 500 -- ms
t = (timing_menu * 1000) / d
if t == 0 then
	t = -1 -- no timeout
end

colorkey = nil
repeat
	i = i + 1
	msg, data = n:GetInput(d)
	if (msg == RC['red']) then
		fh:cp("/boot/STARTUP_1", "/boot/STARTUP", "f")
		colorkey = true
	elseif (msg == RC['green']) then
		fh:cp("/boot/STARTUP_2", "/boot/STARTUP", "f")
		colorkey = true
	elseif (msg == RC['yellow']) then
		fh:cp("/boot/STARTUP_3", "/boot/STARTUP", "f")
		colorkey = true
	elseif (msg == RC['blue']) then
		fh:cp("/boot/STARTUP_4", "/boot/STARTUP", "f")
		colorkey = true
	end
until msg == RC['home'] or colorkey or i == t

chooser:hide()

if colorkey then
	res = messagebox.exec {
		title = caption .. " v" .. version,
		icon = "settings",
		text = locale[lang].start_partition,
		timeout = 0,
		buttons={ "yes", "no" }
	}
	if res == "yes" then
		os.execute("init 6")
	end
end
