// This file contains the definitions of various 3D shapes and their distance functions.
// The distance functions are used to calculate the distance from a point in 3D space to the surface of the shape.

float Cube(float3 position, float3 size) {
    float3 d = abs(position) - size; // calculate the distance to the cube
    return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0); // return the distance to the surface of the cube
}



float Capsule(float3 position, float height, float radius) {
    float3 startPoint = float3(0, -height / 2, 0); // starting point of the capsule
    float3 endPoint = float3(0, height / 2, 0); // ending point of the capsule
    float3 ab = endPoint - startPoint; // vector from start to end
    float3 ap = position - startPoint; // vector from start to position
    float t = clamp(dot(ap, ab) / dot(ab, ab), 0.0, 1.0); // clamp the projection of ap onto ab to the range [0, 1]
    float3 closestPoint = startPoint + t * ab; // calculate the closest point on the capsule
    return length(position - closestPoint) - radius; // return the distance to the surface of the capsule
}



float Sphere(float3 position, float radius) {
    return length(position) - radius; // calculate the distance to the sphere
}
