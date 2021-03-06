# Writing Unity Shaders using Metal Shading Language


## Description

This is a sample of using Metal Shading Language in Unity Shaders.


##Prerequisites

Unity: 2019


## How does it work

Pretty much like GLSL snippets, Metal snippets should be surrounded with `METALPROGRAM`/`ENDMETAL`.
Please note that you specify entry points for vertex program and fragment shader like for "normal" unity shaders:

	#pragma vertex vert
	#pragma fragment frag

To connect your shaders with Unity you need to mark vertex inputs, uniforms and textures. Please note that for uniforms only one (shared between vertex program and fragment shaders) uniform buffer is supported.

Use `METAL_VERTEX_INPUT` to mark vertex data. Arguments are: 0 for position, 1 - normal, 2 - tangent, 3 - color, 4-7 - uvs

	struct InputVP
	{
		float4 pos METAL_VERTEX_INPUT(0);
		float2 uv  METAL_VERTEX_INPUT(3);
	};

Use `METAL_TEX_INPUT` to mark used textures. Arguments are: first is metal type to use, second is the bind point and third is the property name.

	METAL_TEX_INPUT(texture2d<half, access::sample>, 0, _MainTex)

Use `METAL_BUFFER_INPUT` to mark used buffers. HLSL analogue is StructuredBuffer<T>, but unlike HLSL you need to pass element count yourself. Arguments are: first is the type of element, second is the bind point and third is the property name.

	METAL_BUFFER_INPUT(ColorInput, 1, _ColorBuffer)

As metal do not have implicit UAV counters, unity is forced to allocate extra space in all Compute Buffers, so you also need `METAL_BUFFER_INPUT_DATA` to extract data pointer. Arguments are: first is the type of element, second is the property name.

	METAL_BUFFER_INPUT_DATA(ColorInput, _ColorBuffer)


Use `METAL_CONST_MATRIX` and `METAL_CONST_VECTOR` to mark uniform declarations. Arguments are: `METAL_CONST_VECTOR(type, dim, name)` and `METAL_CONST_MATRIX(type, rows, cols, name)`

	struct Globals
	{
		METAL_CONST_MATRIX(float, 4,4, unity_ObjectToWorld);
		METAL_CONST_MATRIX(float, 4,4, unity_MatrixVP);
		METAL_CONST_VECTOR(half, 4, _Color);
	};

