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

	public var level:BitmapData;

	public function new(width:Int, height:Int, bd:BitmapData)
	{
		super();

		gridWidth = 32;
		gridHeight = 32;
		camera = new Camera(2 * gridWidth, 2 * gridHeight);
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

		var playerX:Int = Std.int(camera.x / gridWidth);
		var playerY:Int = Std.int(camera.y / gridHeight);

		// draw view point
		var thetaX:Float = Math.cos(camera.angle * RAD);
		var thetaY:Float = Math.sin(camera.angle * RAD);
		for (i in 0...10)
		{
			var x:Int = playerX + Std.int(i * thetaX);
			var y:Int = playerY + Std.int(i * thetaY);
			if (level.getPixel(x, y) == 0x000000)
				break;
			buffer.setPixel(x + mx, y + mx, 0xFF8888);
		}

		buffer.setPixel(playerX + mx, playerY + mx, 0x00FF00);
	}

	public function draw()
	{
		var hfov:Float = camera.fov / 2;
		var distToProj:Float = (_bufferWidth / 2) / Math.tan(hfov * RAD);
		var angle:Float = (camera.angle - hfov) % 360; // starting angle
		var increment:Float = camera.fov / _bufferWidth; // angle increment

		var destX:Float = 0, incX:Float, dx:Float;
		var destY:Float = 0, incY:Float, dy:Float;
		var wall:Int, distHoriz:Float = 999999999, distVert:Float = 999999999;
		var rect:Rectangle = new Rectangle(0, 0, 1, _bufferHeight);

		// wrap angle if necessary
		if (angle < 0) angle += 360;

		// loop each vertical column
		for (x in 0..._bufferWidth)
		{

			var fTan:Float = Math.tan(angle * RAD);

			destY = Math.floor(camera.y / gridHeight) * gridHeight;
			// check horizontal intersections
			if (angle > 0 && angle < 180)
			{
				// facing down
				destY += gridHeight;
				incY = gridHeight;

				destX = fTan * (destY - camera.y) + camera.x;
				incX = gridWidth / fTan;
			}
			else
			{
				// facing up
				incY = -gridHeight;

				destX = fTan * (destY - camera.y) + camera.x;
				incX = gridWidth / fTan;

				destY -= 1;
			}

			if (angle == 0 || angle == 180)
			{
				distHoriz = 999999999;
			}
			else
			{
				while (true)
				{
					var ix:Int = Math.floor(destX / gridWidth);
					var iy:Int = Math.floor(destY / gridHeight);

					if (ix >= level.width ||
						iy >= level.height ||
						ix < 0 || iy < 0)
					{
						distHoriz = 999999999;
						break;
					}

					wall = level.getPixel(ix, iy);
					if (wall == 0x000000)
					{
						distHoriz = (destX - camera.x) * Math.cos(angle * RAD);
						break;
					}

					destX += incX;
					destY += incY;
				}
			}


			// check vertical intersections
			destX = Math.floor(camera.x / gridWidth) * gridWidth;
			if (angle < 90 && angle > 270)
			{
				// facing left
				destX += gridWidth;
				incX = gridWidth;

				destY = fTan * (destX - camera.x) + camera.y;
				incY = gridHeight * fTan;
			}
			else
			{
				// facing right
				incX = -gridWidth;

				destY = fTan * (destX - camera.x) + camera.y;
				incY = gridHeight * fTan;

				destX -= 1;
			}

			if (angle == 90 || angle == 270)
			{
				distVert = 999999999;
			}
			else
			{
				while (true)
				{
					var ix:Int = Math.floor(destX / gridWidth);
					var iy:Int = Math.floor(destY / gridHeight);

					if (ix >= level.width ||
						iy >= level.height ||
						ix < 0 || iy < 0)
					{
						distHoriz = 999999999;
						break;
					}

					wall = level.getPixel(ix, iy);
					if (wall == 0x000000)
					{
						distVert = (destY - camera.y) * Math.sin(angle * RAD);
						break;
					}
					
					destX += incX;
					destY += incY;
				}
			}


			// keep whichever distance is closest (blocking wall)
			var dist:Float = (distHoriz < distVert) ? distHoriz : distVert;
			trace(dist);

			// Actually draw the wall
			rect.x = x;
			rect.height = gridHeight * distToProj / dist;
			rect.y = camera.z + (_bufferHeight - rect.height) / 2; // center on z-axis
			buffer.fillRect(rect, 0xFFFFFF);

			angle += increment;
			if (angle >= 360)
				angle -= 360;
		}

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