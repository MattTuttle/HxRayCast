package raycast;

/**
 * ...
 * @author Matt Tuttle
 */

class Camera
{

	public var x:Float;
	public var y:Float;
	public var z:Float;
	public var fov:Float;

	public function new(x:Float, y:Float, z:Float = 0, angle:Float = 0, fov:Float = 60)
	{
		this.x = x;
		this.y = y;
		this.z = z;
		this.angle = angle;
		this.fov = fov;
	}

	public var angle(getAngle, setAngle):Float;
	private function getAngle():Float { return _angle; }
	private function setAngle(value:Float):Float
	{
		_angle = value % 360;
		return _angle;
	}

	private var _angle:Float;

}