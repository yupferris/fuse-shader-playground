using Fuse;
using Fuse.Controls;
using Fuse.Drawing;
using Fuse.Elements;
using Fuse.Input;
using Fuse.Resources;
using Fuse.Triggers.Actions;
using OpenGL;
using ShaderPlayground.Internal;
using Uno;
using Uno.Collections;
using Uno.Graphics;
using Uno.UX;

public class Code : Node
{
	static Selector _valueName = "Value";

	string _value;
	[UXContent, UXVerbatim]
	public string Value
	{
		get { return _value; }
		set
		{
			if (value == _value)
				return;

			_value = value;

			OnPropertyChanged(_valueName);
		}
	}
}

public abstract class DrawBuffer : Node
{
	static Selector _widthSelector = "Width";
	static Selector _heightSelector = "Height";

	int _width;
	public int Width
	{
		get { return _width; }
		set
		{
			if (value == _width)
				return;

			_width = value;

			OnPropertyChanged(_widthSelector);
		}
	}

	int _height;
	public int Height
	{
		get { return _height; }
		set
		{
			if (value == _height)
				return;

			_height = value;

			OnPropertyChanged(_heightSelector);
		}
	}

	public abstract framebuffer GetFramebuffer();

	public abstract void Lock(DrawContext dc);
	public abstract void Release();
}

public class TempBuffer : DrawBuffer
{
	framebuffer _fb;

	public override framebuffer GetFramebuffer()
	{
		if (_fb == null)
			throw new InvalidOperationException("Attempted to call GetFramebuffer on non-locked buffer");

		return _fb;
	}

	public override void Lock(DrawContext dc)
	{
		_fb = FramebufferPool.Lock(int2(Width, Height), Format.RGBA8888, false);
	}

	public override void Release()
	{
		FramebufferPool.Release(_fb);
	}
}

public class RetainBuffer : DrawBuffer
{
	static Selector _clearColorName = "ClearColor";

	float4 _clearColor;
	public float4 ClearColor
	{
		get { return _clearColor; }
		set
		{
			if (value == _clearColor)
				return;

			_clearColor = value;

			_shouldClear = true;

			OnPropertyChanged(_clearColorName);
		}
	}

	framebuffer _fb;
	int2 _fbSize;
	bool _shouldClear = true;

	bool _isLocked;

	public override framebuffer GetFramebuffer()
	{
		if (!_isLocked)
			throw new InvalidOperationException("Attempted to call GetFramebuffer on non-locked buffer");

		return _fb;
	}

	public override void Lock(DrawContext dc)
	{
		var currentSize = int2(Width, Height);
		if (_fb == null || currentSize != _fbSize)
		{
			if (_fb != null)
				FramebufferPool.Release(_fb);

			_fbSize = currentSize;
			_fb = FramebufferPool.Lock(_fbSize, Format.RGBA8888, false);
		}

		if (_shouldClear)
		{
			dc.PushRenderTarget(_fb);

			dc.Clear(ClearColor);

			dc.PopRenderTarget();

			_shouldClear = false;
		}

		_isLocked = true;
	}

	public override void Release()
	{
		_isLocked = false;
	}

	public void Clear()
	{
		_shouldClear = true;
	}

	protected override void OnUnrooted()
	{
		if (_fb != null)
		{
			FramebufferPool.Release(_fb);
			_fb = null;
		}

		base.OnUnrooted();
	}
}

public class ClearRetainBuffer : TriggerAction
{
	public RetainBuffer Target { get; set; }

	protected override void Perform(Node target)
	{
		if (Target == null)
			return;

		Target.Clear();
	}
}

public abstract class Uniform : Node
{
	static Selector _uniformNameName = "UniformName";

	string _uniformName;
	public string UniformName
	{
		get { return _uniformName; }
		set
		{
			if (value == _uniformName)
				return;

			_uniformName = value;

			OnPropertyChanged(_uniformNameName);
		}
	}
}

public class FloatUniform : Uniform
{
	static Selector _valueName = "Value";

	float _value;
	public float Value
	{
		get { return _value; }
		set
		{
			if (value == _value)
				return;

			_value = value;

			OnPropertyChanged(_valueName);
		}
	}
}

public class LocalToClipMatrixUniform : Uniform
{
}

public class SizeUniform : Uniform
{
}

public class FrameIntervalUniform : Uniform
{
}

public class PointerXUniform : Uniform
{
}

public class PointerYUniform : Uniform
{
}

public class PointerDownUniform : Uniform
{
}

public class BufferUniform : Uniform
{
	static Selector _bufferName = "Buffer";

	DrawBuffer _buffer;
	public DrawBuffer Buffer
	{
		get { return _buffer; }
		set
		{
			if (value == _buffer)
				return;

			_buffer = value;

			OnPropertyChanged(_bufferName);
		}
	}
}

public class ImageUniform : Uniform, IImageContainerOwner
{
	public Texture2D Texture { get { return _container.GetTexture(); } }

	public ImageUniform()
	{
		_container = new ImageContainer(this);
	}

	protected override void OnRooted()
	{
		base.OnRooted();
		_container.IsRooted = true;
	}

	protected override void OnUnrooted()
	{
		_container.IsRooted = false;
		base.OnUnrooted();
	}

	static Selector _sourceName = "Source";
	void IImageContainerOwner.OnSourceChanged()
	{
		OnPropertyChanged(_sourceName);
	}

	///////////////////////////////////////////
	// ImageContainer proxying
	readonly ImageContainer _container;
	[UXContent]
	public FileSource File
	{
		get { return _container.File; }
		set { _container.File = value; }
	}

	internal SizingContainer SizingContainer
	{
		get { return _container.Sizing; }
	}

	public string Url
	{
		get { return _container.Url; }
		set { _container.Url = value; }
	}

	public float Density
	{
		get { return _container.Density; }
		set { _container.Density = value; }
	}

	public MemoryPolicy MemoryPolicy
	{
		get { return _container.MemoryPolicy; }
		set { _container.MemoryPolicy = value; }
	}

	[UXContent]
	public Fuse.Resources.ImageSource Source
	{
		get { return _container.Source; }
		set { _container.Source = value; }
	}

	public ResampleMode ResampleMode
	{
		get { return _container.ResampleMode; }
		set { _container.ResampleMode = value; }
	}

	static Selector _wrapModeName = "WrapMode";
	WrapMode _wrapMode = WrapMode.Repeat;
	public WrapMode WrapMode
	{
		get { return _wrapMode; }
		set
		{
			if (_wrapMode != value)
			{
				_wrapMode = value;
				OnPropertyChanged(_wrapModeName);
			}
		}
	}

	static Selector _paramName = "Param";
	void IImageContainerOwner.OnParamChanged()
	{
		OnPropertyChanged(_paramName);
	}

	public StretchMode StretchMode
	{
		get { return _container.StretchMode; }
		set { _container.StretchMode = value; }
	}

	static Selector _sizingName = "Sizing";
	void IImageContainerOwner.OnSizingChanged()
	{
		OnPropertyChanged(_sizingName);
	}

	public StretchDirection StretchDirection
	{
		get { return _container.StretchDirection; }
		set { _container.StretchDirection = value; }
	}

	public Fuse.Elements.Alignment ContentAlignment
	{
		get { return _container.ContentAlignment; }
		set { _container.ContentAlignment = value; }
	}
}

public class Pass : Node, IPropertyListener
{
	static Selector _targetName = "Target";

	static Selector _vertexCodeName = "VertexCode";
	static Selector _fragmentCodeName = "FragmentCode";

	static Selector _uniformsName = "Uniforms";

	DrawBuffer _target;
	public DrawBuffer Target
	{
		get { return _target; }
		set
		{
			if (value == _target)
				return;

			if (_target != null)
				_target.RemovePropertyListener(this);

			_target = value;

			if (_target != null)
				_target.AddPropertyListener(this);

			OnPropertyChanged(_targetName);
		}
	}

	Code _vertexCode;
	public Code VertexCode
	{
		get { return _vertexCode; }
		set
		{
			if (value == _vertexCode)
				return;

			if (_vertexCode != null)
				_vertexCode.RemovePropertyListener(this);

			_vertexCode = value;

			if (_vertexCode != null)
				_vertexCode.AddPropertyListener(this);

			_isProgramInvalid = true;

			OnPropertyChanged(_vertexCodeName);
		}
	}

	Code _fragmentCode;
	public Code FragmentCode
	{
		get { return _fragmentCode; }
		set
		{
			if (value == _fragmentCode)
				return;

			if (_fragmentCode != null)
				_fragmentCode.RemovePropertyListener(this);

			_fragmentCode = value;

			if (_fragmentCode != null)
				_fragmentCode.AddPropertyListener(this);

			_isProgramInvalid = true;

			OnPropertyChanged(_fragmentCodeName);
		}
	}

	bool _isProgramInvalid = true;

	extern(OPENGL) Program _program;
	extern(OPENGL) internal Program Program
	{
		get { return _program; }
		set
		{
			if (value == _program)
				return;

			if (_program != null)
				((IDisposable)_program).Dispose();

			_program = value;
		}
	}

	readonly RootableList<Uniform> _uniforms = new RootableList<Uniform>();
	[UXContent]
	public IList<Uniform> Uniforms { get { return _uniforms; } }

	extern(OPENGL) public void PrepareResolve()
	{
		if (!_isProgramInvalid)
			return;

		Program = null;

		if (string.IsNullOrEmpty(VertexCode.Value) || string.IsNullOrEmpty(FragmentCode.Value))
			return;

		try
		{
			Program = new Program(VertexCode.Value, FragmentCode.Value);
		}
		catch (ShaderCompileException e)
		{
			debug_log e.Message;
		}
		catch (ProgramLinkException e)
		{
			debug_log e.Message;
		}

		_isProgramInvalid = false;
	}

	protected override void OnRooted()
	{
		base.OnRooted();

		_uniforms.RootSubscribe(OnUniformAdded, OnUniformRemoved);
	}

	protected override void OnUnrooted()
	{
		_uniforms.RootUnsubscribe();

		Program = null;

		_isProgramInvalid = true;

		base.OnUnrooted();
	}

	public void OnUniformAdded(Uniform uniform)
	{
		uniform.AddPropertyListener(this);

		uniform.OnRooted();

		OnPropertyChanged(_uniformsName);
	}

	public void OnUniformRemoved(Uniform uniform)
	{
		uniform.RemovePropertyListener(this);

		uniform.OnUnrooted();

		OnPropertyChanged(_uniformsName);
	}

	void IPropertyListener.OnPropertyChanged(PropertyObject sender, Selector property)
	{
		if (sender == Target)
		{
			OnPropertyChanged(_targetName);
		}
		else if (sender == VertexCode)
		{
			OnPropertyChanged(_vertexCodeName);

			_isProgramInvalid = true;
		}
		else if (sender == FragmentCode)
		{
			OnPropertyChanged(_fragmentCodeName);

			_isProgramInvalid = true;
		}
		else if (sender is Uniform && _uniforms.Contains((Uniform)sender))
		{
			OnPropertyChanged(_uniformsName);
		}
	}
}

public class ShaderControl : LayoutControl
{
	float2 _resolveBufferSize;

	extern(OPENGL) StaticVertexBuffer _vertexBuffer;

	protected override void OnRooted()
	{
		base.OnRooted();

		UpdateManager.AddAction(Update);

		Pointer.Pressed.AddHandler(this, OnPointerPressed);
		Pointer.Moved.AddHandler(this, OnPointerMoved);
		Pointer.Released.AddHandler(this, OnPointerReleased);
	}

	protected override void OnUnrooted()
	{
		UpdateManager.RemoveAction(Update);

		Pointer.Pressed.RemoveHandler(this, OnPointerPressed);
		Pointer.Moved.RemoveHandler(this, OnPointerMoved);
		Pointer.Released.RemoveHandler(this, OnPointerReleased);

		if (_vertexBuffer != null)
		{
			((IDisposable)_vertexBuffer).Dispose();
			_vertexBuffer = null;
		}

		base.OnUnrooted();
	}

	void Update()
	{
		InvalidateVisual();
	}

	int _pointerDown = -1;
	float2 _pointerPos;

	void OnPointerPressed(object sender, PointerPressedArgs c)
	{
		if (_pointerDown != -1)
			return;

		_pointerDown = c.PointIndex;
		_pointerPos = WindowToLocal(c.WindowPoint);

		c.TryHardCapture(this, OnLostCapture);
	}

	void OnPointerMoved(object sender, PointerMovedArgs c)
	{
		if (_pointerDown != c.PointIndex)
			return;

		_pointerPos = WindowToLocal(c.WindowPoint);

		if (c.IsHardCapturedTo(this))
			c.IsHandled = true;
	}

	void OnPointerReleased(object sender, PointerReleasedArgs c)
	{
		if (_pointerDown != c.PointIndex)
			return;

		_pointerDown = -1;
		_pointerPos = WindowToLocal(c.WindowPoint);

		if (c.IsHardCapturedTo(this))
		{
			c.ReleaseCapture(this);
			c.IsHandled = true;
		}
	}

	void OnLostCapture()
	{
		_pointerDown = -1;
	}

	extern(OPENGL) public override void Draw(DrawContext dc)
	{
		// Ensure vertex buffer
		if (_vertexBuffer == null)
		{
			var verts = new float2[]
			{
				float2(0, 0),
				float2(1, 0),
				float2(1, 1),
				float2(1, 1),
				float2(0, 1),
				float2(0, 0),
			};

			var vb = new Buffer(verts.Length * sizeof(float2));
			for (int i = 0; i < verts.Length; i++)
				vb.Set(i * sizeof(float2), verts[i]);

			_vertexBuffer = new StaticVertexBuffer(vb);
		}

		// Prepare draw state
		GL.Disable(GLEnableCap.Blend);
		GL.Disable(GLEnableCap.DepthTest);
		GL.Disable(GLEnableCap.CullFace);

		GL.DepthMask(true);
		GL.ColorMask(true, true, true, true);

		// Lock buffers
		foreach (var child in Children)
		{
			var buffer = child as DrawBuffer;
			if (buffer == null)
				continue;

			buffer.Lock(dc);
		}

		// Render each pass
		foreach (var child in Children)
		{
			var pass = child as Pass;
			if (pass == null)
				continue;

			// Setup
			pass.PrepareResolve();
			if (pass.Program == null)
				continue;

			if (pass.Target != null)
				dc.PushRenderTarget(pass.Target.GetFramebuffer());

			GL.UseProgram(pass.Program.Handle);

			// Set attribs
			var vertexPosName = "VertexPosition";
			int vertexPosLocation = GL.GetAttribLocation(pass.Program.Handle, vertexPosName); // Hardcoded attrib name for now
			if (vertexPosLocation < 0)
				debug_log "WARNING: unable to get attribute location: " + vertexPosName + "\n  Program: " + pass.Program;
			GL.EnableVertexAttribArray(vertexPosLocation);
			GL.BindBuffer(GLBufferTarget.ArrayBuffer, _vertexBuffer.Handle);
			GL.VertexAttribPointer(vertexPosLocation, 2, GLDataType.Float, false, sizeof(float2), 0);
			GL.BindBuffer(GLBufferTarget.ArrayBuffer, GLBufferHandle.Zero);

			// Set uniforms
			int activeTextureUnit = 0;
			foreach (var uniform in pass.Uniforms)
			{
				if (string.IsNullOrEmpty(uniform.UniformName))
					continue;

				int location = GL.GetUniformLocation(pass.Program.Handle, uniform.UniformName);
				if (location < 0)
					debug_log "WARNING: unable to get uniform location: " + uniform.UniformName + "\n  Program: " + pass.Program;

				var floatUniform = uniform as FloatUniform;
				if (floatUniform != null)
					GL.Uniform1(location, floatUniform.Value);

				var localToClipMatrixUniform = uniform as LocalToClipMatrixUniform;
				if (localToClipMatrixUniform != null)
					GL.UniformMatrix4(location, false, dc.GetLocalToClipTransform(this));

				var sizeUniform = uniform as SizeUniform;
				if (sizeUniform != null)
					GL.Uniform2(location, ActualSize);

				var frameIntervalUniform = uniform as FrameIntervalUniform;
				if (frameIntervalUniform != null)
					GL.Uniform1(location, (float)Time.FrameInterval);

				var pointerXUniform = uniform as PointerXUniform;
				if (pointerXUniform != null)
					GL.Uniform1(location, (float)((double)_pointerPos.X / ActualSize.X));

				var pointerYUniform = uniform as PointerYUniform;
				if (pointerYUniform != null)
					GL.Uniform1(location, (float)((double)_pointerPos.Y / ActualSize.Y));

				var pointerDownUniform = uniform as PointerDownUniform;
				if (pointerDownUniform != null)
					GL.Uniform1(location, _pointerDown != -1 ? 1.0f : 0.0f);

				var bufferUniform = uniform as BufferUniform;
				if (bufferUniform != null)
				{
					if (bufferUniform.Buffer == null)
						continue;

					GL.ActiveTexture((GLTextureUnit)((int)GLTextureUnit.Texture0 + activeTextureUnit));
					GL.BindTexture(GLTextureTarget.Texture2D, bufferUniform.Buffer.GetFramebuffer().ColorBuffer.GLTextureHandle);
					GL.TexParameter(GLTextureTarget.Texture2D, GLTextureParameterName.MinFilter, GLTextureParameterValue.Linear);
					GL.TexParameter(GLTextureTarget.Texture2D, GLTextureParameterName.MagFilter, GLTextureParameterValue.Linear);
					GL.TexParameter(GLTextureTarget.Texture2D, GLTextureParameterName.WrapS, GLTextureParameterValue.ClampToEdge);
					GL.TexParameter(GLTextureTarget.Texture2D, GLTextureParameterName.WrapT, GLTextureParameterValue.ClampToEdge);

					GL.Uniform1(location, activeTextureUnit);

					activeTextureUnit++;
				}

				var imageUniform = uniform as ImageUniform;
				if (imageUniform != null)
				{
					if (imageUniform.Texture == null)
						continue;

					// TODO: Unify with above code path
					GL.ActiveTexture((GLTextureUnit)((int)GLTextureUnit.Texture0 + activeTextureUnit));
					GL.BindTexture(GLTextureTarget.Texture2D, imageUniform.Texture.GLTextureHandle);
					GL.TexParameter(GLTextureTarget.Texture2D, GLTextureParameterName.MinFilter, GLTextureParameterValue.Linear);
					GL.TexParameter(GLTextureTarget.Texture2D, GLTextureParameterName.MagFilter, GLTextureParameterValue.Linear);
					GL.TexParameter(GLTextureTarget.Texture2D, GLTextureParameterName.WrapS, GLTextureParameterValue.ClampToEdge);
					GL.TexParameter(GLTextureTarget.Texture2D, GLTextureParameterName.WrapT, GLTextureParameterValue.ClampToEdge);

					GL.Uniform1(location, activeTextureUnit);

					activeTextureUnit++;
				}
			}

			// Draw
			GL.DrawArrays(GLPrimitiveType.Triangles, 0, 6);

			// Cleanup
			for (int i = 0; i < activeTextureUnit; i++)
			{
				GL.ActiveTexture((GLTextureUnit)((int)GLTextureUnit.Texture0 + i));
				GL.BindTexture(GLTextureTarget.Texture2D, GLTextureHandle.Zero);
			}

			GL.DisableVertexAttribArray(vertexPosLocation);

			GL.UseProgram(GLProgramHandle.Zero);

			if (pass.Target != null)
				dc.PopRenderTarget();
		}

		// Release buffers
		foreach (var child in Children)
		{
			var buffer = child as DrawBuffer;
			if (buffer == null)
				continue;

			buffer.Release();
		}
	}
}

extern(OPENGL) public class ShaderCompileException : Exception
{
	public ShaderCompileException(string log)
		: base(log)
	{
	}
}

extern(OPENGL) public class Shader : IDisposable
{
	readonly string _source;
	public string Source { get { return _source; } }

	readonly GLShaderHandle _handle;
	public GLShaderHandle Handle { get { return _handle; } }

	bool _isDisposed;

	public Shader(string source, GLShaderType type)
	{
		_source = source;

		_handle = GL.CreateShader(type);
		GL.ShaderSource(_handle, _source);

		GL.CompileShader(_handle);
		if (GL.GetShaderParameter(_handle, GLShaderParameter.CompileStatus) != 1) // GL_TRUE
		{
			var log = GL.GetShaderInfoLog(_handle);

			((IDisposable)this).Dispose();

			throw new ShaderCompileException(log);
		}
	}

	public void IDisposable.Dispose()
	{
		if (_isDisposed)
			return;

		GL.DeleteShader(_handle);

		_isDisposed = true;
	}

	public override string ToString()
	{
		return Source;
	}
}

extern(OPENGL) public class ProgramLinkException : Exception
{
	public ProgramLinkException(string log)
		: base(log)
	{
	}
}

extern(OPENGL) public class Program : IDisposable
{
	readonly Shader _vert, _frag;

	readonly GLProgramHandle _handle;
	public GLProgramHandle Handle { get { return _handle; } }

	bool _isDisposed;

	public Program(string vertSource, string fragSource)
	{
		var vertPrefix = "#ifdef GL_ES\nprecision highp float;\n#endif\n";
		var fragPrefix = "#ifdef GL_ES\n#extension GL_OES_standard_derivatives : enable\n";

		if defined(ANDROID)
			fragPrefix += "#extension GL_OES_EGL_image_external : enable\n"; // extension directive must occur before precision specifier

		fragPrefix += "# ifdef GL_FRAGMENT_PRECISION_HIGH\nprecision highp float;\n# else\nprecision mediump float;\n# endif\n#endif\n";

		vertSource = vertPrefix + vertSource;
		fragSource = fragPrefix + fragSource;

		//debug_log "Starting shader (re)compilation";
		//debug_log "  vert shader: " + vertSource;
		//debug_log "  frag shader: " + fragSource;

		_vert = new Shader(vertSource, GLShaderType.VertexShader);
		_frag = new Shader(fragSource, GLShaderType.FragmentShader);

		_handle = GL.CreateProgram();
		GL.AttachShader(_handle, _vert.Handle);
		GL.AttachShader(_handle, _frag.Handle);

		GL.LinkProgram(_handle);
		if (GL.GetProgramParameter(_handle, GLProgramParameter.LinkStatus) != 1) // GL_TRUE
		{
			var log = GL.GetProgramInfoLog(_handle);

			((IDisposable)this).Dispose();

			throw new ProgramLinkException(log);
		}

		debug_log "Shader (re)compilation successful";
	}

	public void IDisposable.Dispose()
	{
		if (_isDisposed)
			return;

		GL.UseProgram(GLProgramHandle.Zero);

		GL.DetachShader(_handle, _vert.Handle);
		GL.DetachShader(_handle, _frag.Handle);
		GL.DeleteProgram(_handle);

		((IDisposable)_vert).Dispose();
		((IDisposable)_frag).Dispose();

		_isDisposed = true;
	}

	public override string ToString()
	{
		return "vert: " + _vert.Source + "\nfrag: " + _frag.Source;
	}
}

extern(OPENGL) public class StaticVertexBuffer : IDisposable
{
	readonly GLBufferHandle _handle;
	public GLBufferHandle Handle { get { return _handle; } }

	bool _isDisposed;

	public StaticVertexBuffer(Buffer data)
	{
		_handle = GL.CreateBuffer();
		GL.BindBuffer(GLBufferTarget.ArrayBuffer, _handle);
		GL.BufferData(GLBufferTarget.ArrayBuffer, data, GLBufferUsage.StaticDraw);
		GL.BindBuffer(GLBufferTarget.ArrayBuffer, GLBufferHandle.Zero);
	}

	public void IDisposable.Dispose()
	{
		if (_isDisposed)
			return;

		GL.DeleteBuffer(_handle);

		_isDisposed = true;
	}
}