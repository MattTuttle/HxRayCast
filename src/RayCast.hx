import flash.display.BitmapData;
import raycast.Engine;
import raycast.Screen;
import nme.Assets;

class RayCast extends Engine
{

	public function new()
	{
		super();
		var bmp = Assets.getBitmapData('assets/level.png');

		screen = new Screen(640, 400);
		addChild(screen);
	}

	public static function main()
	{
		new RayCast();
	}

}