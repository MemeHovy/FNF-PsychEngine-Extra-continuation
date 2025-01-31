package options;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;

using StringTools;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = ['Note Colors', 'Controls', 'Adjust Delay and Combo', 'Graphics', 'Visuals and UI', 'Gameplay', 'Save Data'];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	static var goToPlayState:Bool = false;

	public function new(?goToPlayState:Bool)
	{
		super();
		if (goToPlayState != null)
			OptionsState.goToPlayState = goToPlayState;
	}

	function openSelectedSubState(label:String) {
		switch(label) {
			case 'Note Colors':
				openSubState(new options.NotesSubState.NotesChooseSubState());
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals and UI':
				openSubState(new options.VisualsUISubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				LoadingState.loadAndSwitchState(new options.NoteOffsetState());
			case 'Save Data':
				openSubState(new options.SaveDataSubState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create() {
		super.create();
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		if (MainMenuState.inPvP) {
			var gamepad = FlxG.gamepads.getByID(0);
			if (gamepad != null)
				controls.addDefaultGamepad(0);
		}

		FlxG.mouse.visible = true;

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true, false);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true, false);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true, false);
		add(selectorRight);

		changeSelection();
		ClientPrefs.saveSettings();
	}

	override function closeSubState() {
		super.closeSubState();
		ClientPrefs.saveSettings();
		for (sprite in members)
		{
			var sprite:Dynamic = sprite; //Make it check for FlxSprite instead of FlxBasic
			var sprite:FlxSprite = sprite; //Don't judge me ok
			if (sprite != null && (sprite is FlxSprite) && !(sprite is FlxText)) {
				sprite.antialiasing = ClientPrefs.globalAntialiasing;
			}
		}
	}

	var holdTime:Float = 0;
	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.UI_UP_P || FlxG.mouse.wheel > 0) {
			changeSelection(-1);
			holdTime = 0;
		}
		if (controls.UI_DOWN_P || FlxG.mouse.wheel < 0) {
			changeSelection(1);
			holdTime = 0;
		}
		var down = controls.UI_DOWN;
		var up = controls.UI_UP;
		if (down || up)
		{
			var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
			holdTime += elapsed;
			var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

			if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
			{
				changeSelection((checkNewHold - checkLastHold) * (up ? -1 : 1));
			}
		}

		if (controls.BACK) {
			FlxG.mouse.visible = false;
			CoolUtil.playCancelSound();
			if (goToPlayState) {
				StageData.loadDirectory(PlayState.SONG);
				goToPlayState = false;
				if (MainMenuState.inPvP) {
					controls.removeGamepad(0);
					LoadingState.loadAndSwitchState(new pvp.PvPPlayState(), true);
				} else
					LoadingState.loadAndSwitchState(new PlayState(), true);
			} else {
				MusicBeatState.switchState(new MainMenuState());
			}
		}

		if (controls.ACCEPT || FlxG.mouse.justPressed) {
			openSelectedSubState(options[curSelected]);
		}
	}
	
	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		CoolUtil.playScrollSound();
	}
}