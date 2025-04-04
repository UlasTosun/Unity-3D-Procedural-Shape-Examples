// RAYMARCHING_CUBESPHERECUT is defined, otherwise Shader Graph cannot compile this node.
// This definition should be unique to this function. So, it is recommended to define it similar to the function name.
#ifndef RAYMARCHING_CUBESPHERECUT

    #define RAYMARCHING_CUBESPHERECUT

    #include "Assets/Common Shaders/Shapes.hlsl"



    struct RayMarchingOptions {
        float3 rayStartPoint; // The starting point of the ray in object space. Use fragment position in object space.
        float3 rayDirection; // The direction of the ray in object space. Use the vector from the fragment position to the camera position in object space.
        float minDistance; // The minimum distance to the surface. If the distance to the surface is less than this value, the ray is considered to have hit the surface.
        float maxDistance; // The maximum distance to the surface. If the ray length exceeds this distance, it is considered to have missed the surface.
        int maxIterations; // The maximum number of iterations to perform. This is used to prevent infinite loops.
    };



    struct RayMarchingResults {
        float3 contactPoint; // The contact point of the ray with the surface.
        float rayLength; // The length of the ray at the contact point.
        float contactSide; // The side of the contact point. This is used to determine if the ray has hit the surface from the inside or outside.
    };



    struct ShapeOptions {
        float3 cubeSize; // The size of the cube.
        float3 cubePosition; // The position of the cube.
        float sphereRadius; // The radius of the sphere.
        float smoothness; // The smoothness of the blending between the two shapes.
    };

    ShapeOptions _shapeOptions;



    float Shape(float3 position) {
        float sphere = Sphere(position, _shapeOptions.sphereRadius); // calculate the distance to the sphere surface
        return sphere;
    }



    float CutShape(float3 position) {
        float sphere = Sphere(position, _shapeOptions.sphereRadius); // calculate the distance to the sphere surface
        float cube = Cube(position - _shapeOptions.cubePosition, _shapeOptions.cubeSize); // calculate the distance to the cube surface
        float intersection = max(sphere, cube); // calculate the intersection of the two shapes
        return intersection;
    }



    float CalculateLambertLighting(float3 normal, float3 lightDirection, float brightness) {
        float lambert = max(0.0, dot(normal, -lightDirection)) + brightness; // calculate the Lambertian reflectance using the dot product of the normal vector and the light direction
        return saturate(lambert); // clamp the value between 0 and 1
    }



    float3 CalculateSurfaceNormals(float3 position) {
        // The gradient of the distance function is the normal vector at that point.
        // The gradient vector is calculated by taking the partial derivatives of the distance function with respect to x, y, and z.
        // The normal vector is then normalized to have a length of 1.

        // Partial derivates of the distance function with respect to x:
        // limit as epsilon approaches to 0 of [f(x, y, z) - f(x - epsilon, y, z)] / epsilon
        // Since epsilon is the same for all three axes and the result will be normalized, we don't need to divide by epsilon.
        // We can just use the difference between the two points to calculate the gradient.

        float epsilon = 0.00001; // a small value to calculate the gradient
        float3 dx = float3(epsilon, 0, 0);
        float3 dy = float3(0, epsilon, 0);
        float3 dz = float3(0, 0, epsilon);

        float3 gradient = float3(
            Shape(position) - Shape(position - dx),
            Shape(position) - Shape(position - dy),
            Shape(position) - Shape(position - dz)
        );

        return normalize(gradient); // normalize the gradient vector to get the normal vector
    }



    void MarchRay(RayMarchingOptions options, out RayMarchingResults results, float side = 1.0) {
        float rayLength = 0.0; // initialize the ray length to zero
        float3 endPoint; // initialize the contact point to zero
        float contactSide = 1.0; // initialize the side to 1.0

        for (int i = 0; i < options.maxIterations; i++) {
            endPoint = options.rayStartPoint + rayLength * options.rayDirection; // calculate the end point of the ray
            float distanceToSurface = Shape(endPoint) * side; // get the distance to the surface from the end point
            distanceToSurface = abs(distanceToSurface); // take the absolute value of the distance to the surface, otherwise the ray goes back to the surface even if it is inside the surface
            rayLength += distanceToSurface; // increment the ray length by the distance to the surface

            // Check if the ray has hit the cut surface
            float cutDistance = CutShape(endPoint);
            if (cutDistance < options.minDistance) {
                rayLength += options.minDistance;
                contactSide = -1.0; // set the side to -1.0 if the ray has hit the cut surface
                continue;;
            }

            if (distanceToSurface < options.minDistance || rayLength > options.maxDistance) // check if the ray has hit the surface or exceeded the maximum distance
                break;
        }

        // Set the results of the ray marching
        results.contactPoint = endPoint;
        results.rayLength = rayLength;
        results.contactSide = contactSide; // set the side of the contact point
    }



    // This function does calculations in float precision.
    // It is recommended to use half precision for performance reasons. However, if you need better precision, you can use float instead.
    // Input positions and directions should be in object space.
    
    // rayStartPoint: The starting point of the ray in object space. Use fragment position in object space.
    // rayDirection: The direction of the ray in object space. Use the vector from the fragment position to the camera position in object space.
    // lightDirection: The direction of the light in object space. Main light direction in object space.
    // minDistance: The minimum distance to the surface. If the distance to the surface is less than this value, the ray is considered to have hit the surface.
    // maxDistance: The maximum distance to the surface. If the ray length exceeds this distance, it is considered to have missed the surface.
    // maxIterations: The maximum number of iterations to perform. This is used to prevent infinite loops.
    void RayMarchingCubeSphereCut_float(float3 cubeSize, float3 cubePosition, float sphereRadius, float smoothness, float3 rayStartPoint, float3 rayDirection, float minDistance, float maxDistance, int maxIterations, float3 lightDirection, half4 outerColor, half4 innerColor, float brightness, out half4 Out) {

        // Set the shape options
        _shapeOptions.cubeSize = cubeSize;
        _shapeOptions.cubePosition = cubePosition;
        _shapeOptions.sphereRadius = sphereRadius;
        _shapeOptions.smoothness = smoothness;

        rayDirection = normalize(rayDirection); // normalize the ray direction vector

        // Set the ray marching options
        RayMarchingOptions options;
        options.rayStartPoint = rayStartPoint;
        options.rayDirection = rayDirection;
        options.minDistance = minDistance;
        options.maxDistance = maxDistance;
        options.maxIterations = maxIterations;

        RayMarchingResults results;
        MarchRay(options, results); // calculate the distance to the surface

        // If the ray has missed the surface discard the fragment
        if (results.rayLength > maxDistance) 
            discard; // instead of using discard, use depth buffer to avoid depth issues and z-fighting
        
        float3 normal = CalculateSurfaceNormals(results.contactPoint); // calculate the normal vector at the end point of the ray
        half4 color = outerColor;

        // If the ray has hit the surface from the inside, render the inner surface
        if (results.contactSide < 0.0) {
            normal = -normal;
            color = innerColor;
        }

        float lambert = CalculateLambertLighting(normal, lightDirection, brightness); // calculate the Lambertian reflectance

        Out = half4(color.rgb * lambert, color.a); // set the output color to the color of the surface multiplied by the Lambertian reflectance
    }



#endif