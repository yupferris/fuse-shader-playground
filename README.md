# Fuse Shader Playground

This is a showcase for `ShaderControl`, a control that provides a [shadertoy](https://www.shadertoy.com/)-like workflow for playing with and displaying shader effects in UX markup.

![Demo](https://github.com/yupferris/fuse-shader-playground/blob/master/demo.gif)

## How it Works

`ShaderControl` is a basic `LayoutControl` like any other, except that it uses OpenGL calls directly to draw instead of uno's `draw` statements, has some special children called `DrawBuffer`s and `Pass`s. `DrawBuffer`s are used to represent render targets and texture sources for the shaders. `Pass`es are used to draw quads to the screen with custom GLSL shaders each frame.

### `DrawBuffer`

There are two types of `DrawBuffer`s available: `TempBuffer` and `RetainBuffer`.

- A `TempBuffer` represents not only a texture source, but also a render target that can be drawn to. The contents of a `TempBuffer` will _not_ persist between frames. This means that they should only be used as intermediate buffers to help prepare texture data for drawing to the screen or to another `DrawBuffer`.
- `RetainBuffer`s, like `TempBuffer`s, also represent render targets that can be drawn to. In contrast to a `TempBuffer`, however, a `RetainBuffer` will retain its contents between frames, so they can be used to maintain an effect's state over time.

There's also a `ClearRetainBuffer` action that can be used to clear the contents of a `RetainBuffer`, like so:

```ux
<Button Text="Bye bye buffer!">
	<Clicked>
		<ClearRetainBuffer Target="SomeRetainBuffer" />
	</Clicked>
</Button>
```

### `Pass`

A `Pass` draws a quad either to the currently-bound framebuffer or to a `DrawBuffer` using a specified GLSL shader. A `ShaderControl` can have zero or more `Pass`es that it will process in declaration order when drawing a frame. A simple `Pass` might look something like this:

```ux
<Pass Target="SomeBuffer">
	<BufferUniform Buffer="WorkBuffer" UniformName="WorkTex" />
	<FloatUniform UniformName="SomeParam" Value="0.5" />

	<Code ux:Binding="VertexCode">
		// Vertex shader code goes here
	</Code>
	<Code ux:Binding="FragmentCode">
		// Fragment shader code goes here
	</Code>
</Pass>
```

A `Pass` can draw to a `DrawBuffer` if specified as a `Target`. If no `Target` is specified, the `Pass` will draw to the currently-bound buffer.

Code is specified using `Code` nodes, which are basic containers for text. `Code` nodes are bound to `VertexCode` or `FragmentCode` via `ux:Binding`. A `Pass` needs both a vertex and fragment program specified to function properly.

Shader uniforms can be specified using several types of `Uniform` objects. These objects all have a `UniformName` property that determines the name of the underlying OpenGL uniform, so they can be referred to by the shader code. There are a few basic `Uniform` types:

- `FloatUniform` - represents a single float value determined by its `Value` property. Note that this `Value` property can be `Set`, `Change`d, or otherwise animated like any other float property in UX.
- `FrameIntervalUniform` - represents the time that has passed since the last frame was drawn in seconds.

There are also some `Uniform`s available for basic single-point capture:

- `PointerDownUniform` - represents whether or not a pointer is currently down (captured) on the control.
- `PointerXUniform` - represents the x coordinate of the currently captured pointer, if any.
- `PointerYUniform` - represents the y coordinate of the currently captured pointer, if any.

Some `Uniform` types can be used to pass texture data to the shaders:

- `BufferUniform` - used to pass a `DrawBuffer` to the shader as a 2D texture.
- `ImageUniform` - used to pass image data from one of Fuse's `ImageSource`s, i.e. a `FileImageSource` or `HttpImageSource`, to the shader as a 2D texture. This is a very convenient way to get existing image data into your shaders.

There are also a few special `Uniform` types available for more complex use cases:

- `LocalToClipMatrixUniform` - used to pass a `LocalToClipMatrix` to the shader. This is useful for determining where on the screen the `Pass`'s quad should be drawn.
- `SizeUniform` - used to pass the control's visual size to the shader. This is useful for determining where on the screen the `Pass`'s quad should be drawn.

All of these objects, in combination with Fuse's powerful live reload/preview features, makes this an ideal way to play with and develop GLSL shaders on mobile devices.

## Errors

Since GLSL shaders are compiled dynamically on changes, it's very often that shader compilation will fail. When this happens, errors are reported to the normal output log. The `ShaderControl` will never crash due to invalid shader compile (unless something super crazy goes on in the underlying GPU driver), but _will_ report compile errors each time it tries to recompile the shader, which is often each frame, so it may produce a lot of output.

## Shortcomings

For performance reasons, `ShaderControl` will render any `Pass`es that don't specify an output target directly to the currently-bound framebuffer, which is usually the backbuffer. This means that the vertex shaders for these `Pass`es need to be a bit careful, and the ones used in the effects here may not be correct in all cases, causing some strange layout/rendering issues. This may be fixed at some point, but for now be aware that things can get a little crazy sometimes :) .

## License

This code is primarily licensed under the MIT license (see LICENSE). Some of the `ShaderControl`'s internals have been forked from fuselibs, and are licensed under another MIT license (see `ShaderPlayground.Internal/LICENSE.txt`).
