using Fuse;
using Uno;

public class PrintFrameInterval : Node
{
	protected override void OnRooted()
	{
		base.OnRooted();

		UpdateManager.AddAction(Update);
	}

	protected override void OnUnrooted()
	{
		UpdateManager.RemoveAction(Update);

		base.OnUnrooted();
	}

	void Update()
	{
		debug_log "Frame interval: " + (Time.FrameInterval * 1000.0) + "ms";
	}
}