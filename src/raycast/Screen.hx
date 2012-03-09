package raycast;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.PixelSnapping;
import flash.display.Sprite;
import flash.display.BlendMode;
import flash.geom.Matrix;
import flash.geom.Rectangle;

class Screen extends Sprite
{

	// Used for rad-to-deg and deg-to-rad conversion.
	public static inline var DEG:Float = 180 / Math.PI;
	public static inline var RAD:Float = Math.PI / 180;

	public var wallImage:Bitmap;
	public var camera:Camera;
	public var entities:Array<Entity>;

	public var stripWidth:Int;

	private static var mapData:Array<Array<Int>> = [
		[1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
		[1, 0, 0, 0, 1, 1, 0, 0, 0, 1],
		[2, 0, 0, 0, 0, 0, 0, 0, 0, 1],
		[1, 0, 0, 0, 1, 1, 0, 0, 0, 1],
		[2, 0, 0, 0, 1, 1, 4, 4, 4, 1],
		[1, 0, 0, 0, 1, 1, 0, 0, 0, 1],
		[2, 0, 0, 0, 0, 0, 0, 0, 0, 1],
		[1, 0, 0, 0, 1, 1, 0, 0, 0, 1],
		[1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	];

	private static var mapWidth:Int = mapData[0].length;
	private static var mapHeight:Int = mapData.length;

	public function new(width:Int, height:Int)
	{
		super();

		wallImage = new Bitmap(nme.Assets.getBitmapData("assets/walls.png"));

		clipRect = new Rectangle();
		matrix = new Matrix();

		stripWidth = 3;

		camera = new Camera(3, 3); // set initial start position
		entities = new Array<Entity>();

		_bufferWidth = width;
		_bufferHeight = height;
		_buffer = new BitmapData(_bufferWidth, _bufferHeight, false, 0);
		addChild(new Bitmap(_buffer, PixelSnapping.NEVER));
	}

	public function isBlocking(x:Float, y:Float, w:Float, h:Float)
	{
		if (y < 0 || y >= mapHeight || x < 0 || x >= mapWidth) {
			return true;
		}

		var l:Int = Math.floor(x - w);
		var r:Int = Math.floor(x + w);
		var u:Int = Math.floor(y - h);
		var d:Int = Math.floor(y + h);

		return (mapData[u][l] != 0 || mapData[u][r] != 0 ||
			mapData[d][l] != 0 || mapData[d][r] != 0);
	}

	public inline function drawMiniMap()
	{
		var mx:Int = 20, my: Int = 20;
		var rect = new Rectangle(0, 0, 3, 3);
		for (y in 0...mapHeight)
		{
			for (x in 0...mapWidth)
			{
				var wall:Int = mapData[y][x];
				rect.x = x * rect.width + mx;
				rect.y = y * rect.height + my;
				if (wall != 0)
				{
					_buffer.fillRect(rect, 0x555555);
				}
				else
				{
					_buffer.fillRect(rect, 0x888888);
				}
			}
		}

		// draw view point
		/*
		var thetaX:Float = Math.cos(camera.angle * RAD);
		var thetaY:Float = Math.sin(camera.angle * RAD);
		for (i in 0...10)
		{
			var x:Int = Std.int(camera.x + (i * thetaX) + 1);
			var y:Int = Std.int(camera.y + (i * thetaY) + 1);
			if (mapData[y][x] != 0)
				break;
			rect.x = x * rect.width + mx;
			rect.y = y * rect.height + my;
			buffer.fillRect(rect, 0xFF8888);
		}
		*/

		rect.x = camera.x * rect.width + mx;
		rect.y = camera.y * rect.height + my;
		_buffer.fillRect(rect, 0x00FF00);
	}

	private inline function distance(x1:Float, y1:Float, x2:Float, y2:Float):Float
	{
		var dx:Float = x1 - x2;
		var dy:Float = y1 - y2;
		return dx * dx + dy * dy;
	}

	public inline function doRayCast(angle:Float)
	{
		var dist:Float = 0, textureX:Float = 0;
		var wallX:Int, wallY:Int, wallType:Int = 0;
		var color:Int = 0xFFFFFFFF;
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

		while (x >= 0 && x < mapWidth && y >= 0 && y < mapHeight)
		{
			wallX = Math.floor(x + (left ? -1 : 0));
			wallY = Math.floor(y);
			var tile:Int = mapData[wallY][wallX];
			if (tile != 0)
			{
				textureX = y % 1;
				if ( left )
				{
					textureX = 1 - textureX; // flip texture
					color = 0xFFBBBBBB;
				}
				else
				{
					color = 0xFFCCCCCC;
				}

				wallType = tile;
				dist = distance(x, y, camera.x, camera.y);
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

		while (x >= 0 && x < mapWidth && y >= 0 && y < mapHeight)
		{
			wallX = Math.floor(x);
			wallY = Math.floor(y + (up ? -1 : 0));
			var tile:Int = mapData[wallY][wallX];
			if (tile != 0)
			{
				var newDist = distance(x, y, camera.x, camera.y);
				if (dist <= 0 || dist > newDist)
				{
					textureX = x % 1;
					if ( up )
					{
						color = 0xFFAAAAAA;
					}
					else
					{
						color = 0xFFFFFFFF;
						textureX = 1 - textureX; // flip texture
					}
					dist = newDist;
					wallType = tile;
				}
				break;
			}
			x += dx;
			y += dy;
		}

		if (dist >= 0)
		{
			var numTextures:Int = 4;
			var tileHeight:Int = 64;

			// fix fisheye
			dist = Math.sqrt(dist) * Math.cos((camera.angle - angle) * RAD);
			dist = viewDist / dist;

			clipRect.y = (_bufferHeight + camera.z - dist) / 2;
			clipRect.height = dist;

			// prevent gaps in the wall
			var texX:Float = textureX * dist;
			if (texX > dist - stripWidth)
				texX = dist - stripWidth;

//			buffer.fillRect(clipRect, color); // colored wall
			var sy:Float = dist / wallImage.height * numTextures;

			matrix.identity();
			matrix.scale(dist / wallImage.width, sy);
			matrix.translate(clipRect.x - texX, clipRect.y - sy * (wallType - 1) * tileHeight);
#if flash
			_buffer.draw(wallImage, matrix, null, BlendMode.NORMAL, clipRect);
#else
			_buffer.draw(wallImage, matrix, null, "Normal", clipRect);
#end
		}
	}

	public inline function drawRays()
	{
		var numRays:Int = Math.ceil(_bufferWidth / stripWidth);
		var angle:Float = camera.angle - camera.fov / 2;
		var deltaAngle:Float = camera.fov / numRays;

		// keep angle in 0-360 range
		if (angle < 0)
		{
			angle += 360;
		}

		viewDist = (_bufferWidth / 2) / Math.tan((camera.fov * RAD) / 2);
		clipRect.width = stripWidth;
		for (i in 0...numRays)
		{
			clipRect.x = i * stripWidth;

			doRayCast(angle);

			// keep angle in 0-360 range
			angle += deltaAngle;
			if (angle >= 360)
			{
				angle %= 360;
			}
		}
	}

	public function draw()
	{
		// clear background
		var rect:Rectangle = _buffer.rect;
		// ceiling
		rect.height = (rect.height + camera.z) / 2;
		_buffer.fillRect(rect, 0x555353);
		// floor
		rect.y += rect.height;
		rect.height = _bufferHeight - rect.y;
		_buffer.fillRect(rect, 0x333030);

		drawRays();
		drawMiniMap();
	}

	private var clipRect:Rectangle;
	private var matrix:Matrix;
	private var viewDist:Float;

	private var _bufferWidth:Int;
	private var _bufferHeight:Int;
	private var _buffer:BitmapData;

}