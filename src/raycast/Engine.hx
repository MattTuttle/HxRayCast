package raycast;

import flash.display.Sprite;
import flash.display.Stage;
import flash.display.StageAlign;
import flash.display.StageDisplayState;
import flash.display.StageQuality;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.Lib;

class Engine extends Sprite
{

	public var screen:Screen;

	public function new()
	{
		super();
		if (Lib.current.stage != null) onStage();
		else Lib.current.addEventListener(Event.ADDED_TO_STAGE, onStage);
	}

	private function onStage(?e:Event)
	{
		if (e != null)
			Lib.current.removeEventListener(Event.ADDED_TO_STAGE, onStage);

		var stage = Lib.current.stage;
		stage.align = StageAlign.TOP_LEFT;
		stage.quality = StageQuality.HIGH;
		stage.scaleMode = StageScaleMode.EXACT_FIT;
		stage.displayState = StageDisplayState.NORMAL;
		stage.addChild(this);

		addEventListener(Event.ENTER_FRAME, onEnterFrame);
		stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false,  2);
	}

	private function onKeyDown(e:KeyboardEvent)
	{
		switch (e.keyCode)
		{
			case Key.LEFT:
				screen.camera.angle -= 1;
			case Key.RIGHT:
				screen.camera.angle += 1;
			case Key.W:
				screen.camera.y -= 1;
			case Key.S:
				screen.camera.y += 1;
			case Key.A:
				screen.camera.x -= 1;
			case Key.D:
				screen.camera.x += 1;
		}
	}

	private function onEnterFrame(e:Event)
	{
		if (screen == null) return;
		screen.start();
		screen.draw();
		screen.end();
	}

}