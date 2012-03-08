import flash.display.BitmapData;
import raycast.Engine;
import raycast.Screen;
import nme.Assets;

class RayCast extends Engine
{

	public function new()
	{
		super();
		screen = new Screen(640, 400, Assets.getBitmapData('assets/level.png'));
		addChild(screen);
	}

	public static function main()
	{
		new RayCast();
	}

}