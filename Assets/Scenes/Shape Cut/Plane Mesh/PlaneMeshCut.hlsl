// PLANEMESHCUT is defined, otherwise Shader Graph cannot compile this node.
// This definition should be unique to this function. So, it is recommended to define it similar to the function name.
#ifndef PLANEMESHCUT

    #define PLANEMESHCUT

    #include "Assets/Common Shaders/Shapes.hlsl"


    struct ShapeOptions {
        float3 planeNormal; // The normal vector of the plane.
        float planeOffset; // The offset of the plane from the origin.
    };

    ShapeOptions _shapeOptions;



    float Shape(float3 position) {
        float plane = Plane(position, _shapeOptions.planeNormal, _shapeOptions.planeOffset); // calculate the distance to the plane surface
        return plane;
    }



    // This function does calculations in float precision.
    // It is recommended to use half precision for performance reasons. However, if you need better precision, you can use float instead.

    // Position should be in object space.
    void PlaneMeshCut_float(float3 planeNormal, float planeOffset, float3 position, half4 baseColor, half4 textureColor, out half4 Out) {
        // Set the shape options
        _shapeOptions.planeNormal = planeNormal;
        _shapeOptions.planeOffset = planeOffset;

        float side = Shape(position); // calculate the side of the surface

        if (side <= 0.0) // check if the ray start point is inside the surface
            discard; // discard the fragment if it is inside the surface
        
        Out = baseColor * textureColor; // calculate the output color
    }



#endif