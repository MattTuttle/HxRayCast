package raycast;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.PixelSnapping;
import flash.display.Sprite;
import flash.geom.Matrix;
import flash.geom.Rectangle;

class Screen extends Sprite
{

	// Used for rad-to-deg and deg-to-rad conversion.
	public static inline var DEG:Float = 180 / Math.PI;
	public static inline var RAD:Float = Math.PI / 180;

	public var buffer:BitmapData;
	public var camera:Camera;

	public var gridWidth:Int;
	public var gridHeight:Int;

	public var stripWidth:Int;

	public var level:BitmapData;

	public function new(width:Int, height:Int, bd:BitmapData)
	{
		super();

		gridWidth = 32;
		gridHeight = 32;

		stripWidth = 1;

		camera = new Camera(30, 30);
		level = bd;

		_current = 0;
		_color = 0x202020;
		_bounds = new Rectangle(0, 0, width, height);

		_buffers = new Array<Bitmap>();
		_buffers[0] = new Bitmap(new BitmapData(width, height, false, 0), PixelSnapping.NEVER);
		_buffers[1] = new Bitmap(new BitmapData(width, height, false, 0), PixelSnapping.NEVER);

		_bufferWidth = width;
		_bufferHeight = height;

		addChild(_buffers[0]).visible = true;
		addChild(_buffers[1]).visible = false;
		buffer = _buffers[0].bitmapData;
	}

	public function isBlocking(x:Float, y:Float, w:Float, h:Float)
	{
		if (y < 0 || y >= level.height || x < 0 || x >= level.width) {
			return true;
		}

//		trace(x + ", " + y);

		var l:Int = Math.floor(x - w);
		var r:Int = Math.floor(x + w);
		var u:Int = Math.floor(y - h);
		var d:Int = Math.floor(y - h);

//		trace(l + ", " + r + ", " + u + ", " + d);

		return (level.getPixel(l, u) == 0x000000 ||
			level.getPixel(r, u) == 0x000000 ||
			level.getPixel(l, d) == 0x000000 ||
			level.getPixel(r, d) == 0x000000);
	}

	public function start()
	{
		_current = 1 - _current;
		buffer = _buffers[_current].bitmapData;
		buffer.fillRect(_bounds, color);
	}

	public function end()
	{
		_buffers[_current].visible = true;
		_buffers[1 - _current].visible = false;
	}

	public function line(x1:Int, y1:Int, x2:Int, y2:Int, color:Int = 0xFFFFFF)
	{
		if (color < 0xFF000000) color = 0xFF000000 | color;

		// get the drawing difference
		var X:Float = Math.abs(x2 - x1),
			Y:Float = Math.abs(y2 - y1),
			xx:Int,
			yy:Int;

		// draw a single pixel
		if (X == 0)
		{
			if (Y == 0)
			{
				buffer.setPixel32(x1, y1, color);
				return;
			}
			// draw a straight vertical line
			yy = y2 > y1 ? 1 : -1;
			while (y1 != y2)
			{
				buffer.setPixel32(x1, y1, color);
				y1 += yy;
			}
			buffer.setPixel32(x2, y2, color);
			return;
		}

		if (Y == 0)
		{
			// draw a straight horizontal line
			xx = x2 > x1 ? 1 : -1;
			while (x1 != x2)
			{
				buffer.setPixel32(x1, y1, color);
				x1 += xx;
			}
			buffer.setPixel32(x2, y2, color);
			return;
		}

		xx = x2 > x1 ? 1 : -1;
		yy = y2 > y1 ? 1 : -1;
		var c:Float = 0,
			slope:Float;

		if (X > Y)
		{
			slope = Y / X;
			c = .5;
			while (x1 != x2)
			{
				buffer.setPixel32(x1, y1, color);
				x1 += xx;
				c += slope;
				if (c >= 1)
				{
					y1 += yy;
					c -= 1;
				}
			}
			buffer.setPixel32(x2, y2, color);
		}
		else
		{
			slope = X / Y;
			c = .5;
			while (y1 != y2)
			{
				buffer.setPixel32(x1, y1, color);
				y1 += yy;
				c += slope;
				if (c >= 1)
				{
					x1 += xx;
					c -= 1;
				}
			}
			buffer.setPixel32(x2, y2, color);
		}
	}

	public function drawMiniMap()
	{
		var mx:Int = 6, my: Int = 6;
		for (y in 0...level.height)
		{
			for (x in 0...level.width)
			{
				var wall:Int = level.getPixel(x, y);
				if (wall != 0x000000)
				{
					buffer.setPixel(x + mx, y + my, 0x555555);
				}
			}
		}

		// draw view point
		var thetaX:Float = Math.cos(camera.angle * RAD);
		var thetaY:Float = Math.sin(camera.angle * RAD);
		for (i in 0...10)
		{
			var x:Int = Std.int(camera.x + i * thetaX);
			var y:Int = Std.int(camera.y + i * thetaY);
			if (level.getPixel(x, y) == 0x000000)
				break;
			buffer.setPixel(x + mx, y + my, 0xFF8888);
		}

		buffer.setPixel(Std.int(camera.x + mx), Std.int(camera.y + my), 0x00FF00);
	}

	private inline function distance(x1:Float, y1:Float, x2:Float, y2:Float):Float
	{
		var dx:Float = x1 - x2;
		var dy:Float = y1 - y2;
		return dx * dx + dy * dy;
	}

	public function doRayCast(angle:Float, index:Int)
	{
		var dist:Float = 0, distX:Float, distY:Float;
		var wallX:Int, wallY:Int, color:Int = 0xFFFFFFFF;
		var x:Float, y:Float, dx:Float, dy:Float, slope:Float;

		var fCos:Float = Math.cos(angle * RAD);
		var fSin:Float = Math.sin(angle * RAD);

		var left:Bool = (angle > 90 && angle < 270);
		var up:Bool = (angle > 180 && angle < 360);


		// horizontal
		slope = fSin / fCos;

		x = left ? Math.floor(camera.x) : Math.ceil(camera.x);
		y = camera.y + (x - camera.x) * slope;

		dx = left ? -1 : 1;
		dy = dx * slope;

		while (x >= 0 && x < level.width && y >= 0 && y < level.height)
		{
			wallX = Math.floor(x + (left ? -1 : 0));
			wallY = Math.floor(y);
			var tile:Int = level.getPixel(wallX, wallY);
			if (tile == 0x000000)
			{
				if (left)
					color = 0xFFBBBBBB;
				else
					color = 0xFFCCCCCC;
				dist = distance(x, y, camera.x, camera.y);
//				trace("(" + x + ", " +  y + ") (" + camera.x + ", " + camera.y + "): " + dist);
				break;
			}
			x += dx;
			y += dy;
		}


		// vertical
		slope = fCos / fSin;

		y = up ? Math.floor(camera.y) : Math.ceil(camera.y);
		x = camera.x + (y - camera.y) * slope;

		dy = up ? -1 : 1;
		dx = dy * slope;

		while (x >= 0 && x < level.width && y >= 0 && y < level.height)
		{
			wallX = Math.floor(x);
			wallY = Math.floor(y + (up ? -1 : 0));
			var tile:Int = level.getPixel(wallX, wallY);
			if (tile == 0x000000)
			{
				var newDist = distance(x, y, camera.x, camera.y);
				if (dist == 0 || dist > newDist)
				{
					if (up)
						color = 0xFFAAAAAA;
					else
						color = 0xFFFFFFFF;
					dist = newDist;
				}
				break;
			}
			x += dx;
			y += dy;
		}

		if (dist != 0)
		{
			var viewDist = (_bufferWidth / 2) / Math.tan(camera.fov * RAD / 2);
			dist = Math.sqrt(dist) * Math.cos(camera.angle * RAD - angle * RAD);
			var height:Float = viewDist / dist;
			var rect = new Rectangle(index * stripWidth, _bufferHeight / 2 - height / 2, stripWidth, height);
			buffer.fillRect(rect, color);
		}
	}

	public function drawRays()
	{
		var numRays:Int = Math.floor(_bufferWidth / stripWidth);
		var angle:Float = camera.angle - camera.fov / 2;
		var deltaAngle:Float = camera.fov / numRays;

		if (angle < 0)
			angle += 360;

		for (i in 0...numRays)
		{
			doRayCast(angle, i);
			angle += deltaAngle;
			if (angle > 360)
				angle %= 360;
		}
	}

	public function draw()
	{
		drawRays();
		drawMiniMap();
	}

	public var color(getColor, setColor):Int;
	private function getColor():Int { return _color; }
	private function setColor(value:Int):Int { _color = 0xFF000000 | value; return _color; }

	private var _buffers:Array<Bitmap>;
	private var _bufferWidth:Int;
	private var _bufferHeight:Int;
	private var _current:Int;
	private var _color:Int;
	private var _bounds:Rectangle;

}