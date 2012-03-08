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
	public inline static var RAD:Float = Math.PI / 180;

	public inline static var turnSpeed:Float = 3;
	public inline static var moveSpeed:Float = 0.18;

	private var forward:Float;
	private var strafe:Float;
	private var turn:Float;

	public function new()
	{
		super();

		forward = strafe = turn = 0;

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
		stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp, false,  2);
	}

	private function onKeyDown(e:KeyboardEvent)
	{
		switch (e.keyCode)
		{
			case Key.LEFT:
				turn = -turnSpeed;
			case Key.RIGHT:
				turn = turnSpeed;
			case Key.W:
				forward = moveSpeed;
			case Key.S:
				forward = -moveSpeed;
			case Key.A:
				strafe = -moveSpeed;
			case Key.D:
				strafe = moveSpeed;
		}
	}

	private function onKeyUp(e:KeyboardEvent)
	{
		switch (e.keyCode)
		{
			case Key.LEFT:
				turn = 0;
			case Key.RIGHT:
				turn = 0;
			case Key.W:
				forward = 0;
			case Key.S:
				forward = 0;
			case Key.A:
				strafe = 0;
			case Key.D:
				strafe = 0;
		}
	}

	private inline function checkMove(x:Float, y:Float)
	{
		if ( ! screen.isBlocking(screen.camera.x + x, screen.camera.y + y, 0.25, 0.25) )
		{
			screen.camera.x += x;
			screen.camera.y += y;
		}
	}

	private function onEnterFrame(e:Event)
	{
		var x:Float, y:Float, angle:Float;

		screen.camera.angle += turn;
		angle = screen.camera.angle;

		x = Math.cos(angle * RAD) * forward;
		y = Math.sin(angle * RAD) * forward;
		checkMove(x, y);

		angle += 90;
		x = Math.cos(angle * RAD) * strafe;
		y = Math.sin(angle * RAD) * strafe;
		checkMove(x, y);

		if (screen == null) return;
		screen.start();
		screen.draw();
		screen.end();
	}

}